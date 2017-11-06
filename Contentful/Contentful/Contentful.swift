//
//  Contentful.swift
//  DeviceManagement
//
//  Created by Sam Woolf on 17/10/2017.
//  Copyright © 2017 Nice Agency. All rights reserved.
//

import Foundation

private typealias StringDict = [String:String]
private typealias IntDict = [String:Int]
private typealias DoubleDict = [String:Double]
private typealias BoolDict = [String:Bool]
private typealias RefDict = [String: [String:StringDict]]


public struct PageRequest {
    
    public static func prepareRequest(forContent contentType: String, fromSpace spaceId: String,  page: Page) -> (endpoint: String, query: [URLQueryItem]) {
        let endpoint = "/spaces/\(spaceId)/entries"
        
        let contentQuery =  URLQueryItem(name: "content_type", value: contentType)
        let selectQuery = URLQueryItem(name: "select", value: "sys.id,sys.version,fields")
        let limitQuery = URLQueryItem(name: "limit", value: "\(page.itemsPerPage)")
        let skipQuery = URLQueryItem(name: "skip", value: "\(page.itemsPerPage * page.currentPage)")
        let queries = [contentQuery, selectQuery, limitQuery,skipQuery]
        
        return (endpoint, queries)
    }
}
    
public struct PageUnboxing {

    public static func unboxResponse<T>(data: Data, locale: Locale?, with fieldUnboxer: @escaping ((String) -> (UnboxedType,Bool)?), via creator: @escaping ((UnboxedFields) -> T?)) -> Result<PagedResult<T>>  {
        let decoder = JSONDecoder()
        
        decoder.userInfo = [CodingUserInfoKey(rawValue: "fieldUnboxer")!: fieldUnboxer, CodingUserInfoKey(rawValue: "creator")!: creator]
        
        if let locale = locale {
            decoder.userInfo.updateValue(locale, forKey: CodingUserInfoKey(rawValue: "locale")!)
        }
        
        do {
            let response = try decoder.decode(Response<T>.self, from: data)
            let entries = response.entries
            let page = Page(itemsPerPage: response.limit, currentPage: response.skip/response.limit, totalItemsAvailable: response.total)
            return .success(PagedResult(results: entries, page: page))
        } catch {
            switch error {
            case Swift.DecodingError.dataCorrupted(_):
                return .error(.invalidData)
            case Swift.DecodingError.typeMismatch(let type, _):
                return .error(.typeMismatch(type))
            case Swift.DecodingError.keyNotFound(let key, _):
                return .error(.requiredKeyMissing(key))
            default:
                return .error(.invalidData)
            }
        }
    }
}

public struct ObjectEncoding {
    
    public static func encode<T: Encodable>(object: T, locale: LocaleCode) -> (data: Data, sysData: SysData)? {
        
        let encoder = JSONEncoder()
        
        guard let jsonData = try? encoder.encode(object),
            let jsonObject = try? JSONSerialization.jsonObject(with: jsonData,options: []),
            let jsonDict = jsonObject as? [String: Any] else { return nil }
        
        let sysData = SysData(id: object.contentful_id, version: object.contentful_version)
        
        var contentfulFieldsDict: [String:Any] = [:]
        
        for key in jsonDict.keys {
            
            if key != "contentful_id" && key != "contentful_version" {
                let nestedDict = [locale.rawValue: jsonDict[key] ?? ""]
                contentfulFieldsDict.updateValue(nestedDict, forKey: key)
            }
        }
        
        let contentfulDict: [String: Any] = ["fields": contentfulFieldsDict]
        
        if let data = try? JSONSerialization.data(withJSONObject: contentfulDict, options: []) {
            return (data: data, sysData: sysData)
        }
        
        return nil
    }
}

//MARK: JSON decoding keys

private struct Response<T> : Decodable {
    
    let total: Int
    let skip: Int
    let limit: Int
    private let unboxables: [Unboxable<T>]
    
    var entries: [T] {
        return unboxables.flatMap({ $0.object })
    }
    
    enum CodingKeys: String, CodingKey {
        case total
        case skip
        case limit
        case entries = "items"
    }
    
    init (from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        total = try container.decode(Int.self, forKey: .total)
        skip = try container.decode(Int.self, forKey: .skip)
        limit = try container.decode(Int.self, forKey: .limit)
        unboxables = try container.decode([Unboxable<T>].self, forKey: .entries)
    }
}

private enum EntryCodingKeys: String, CodingKey {
    case sys
    case fields
}

private enum EntrySysCodingKeys: String, CodingKey {
    case id 
    case version
}

private struct GenericCodingKeys: CodingKey {
    var intValue: Int?
    var stringValue: String
    
    init?(intValue: Int) { self.intValue = intValue; self.stringValue = "\(intValue)" }
    init?(stringValue: String) { self.stringValue = stringValue }
    
    static func makeKey(name: String) -> GenericCodingKeys {
        return GenericCodingKeys(stringValue: name)!
    }
}

//MARK: Decoding container

private struct Unboxable<T>: Decodable {
    let object: T?
    
    init(from decoder: Decoder) throws {
        let unboxing = decoder.userInfo[CodingUserInfoKey(rawValue: "fieldUnboxer")!] as! ((String) -> (UnboxedType,Bool)?)
        let creator = decoder.userInfo[CodingUserInfoKey(rawValue: "creator")!] as! ((UnboxedFields) -> T?)
        
        let fields = try Unboxable.unboxableFields(fromDecoder: decoder, withUnboxing: unboxing)
        
        object = creator(fields)
    }
    
  
    static func unboxableFields(fromDecoder decoder: Decoder, withUnboxing unboxing: ((String) -> (UnboxedType,Bool)?)) throws -> UnboxedFields {
       
        func getValueFromDict<T>(dict: [String:T], locale: Locale?) -> T? {
            if let locale = locale {
                return dict[locale.favouredLocale.rawValue] ?? dict[locale.fallbackLocale.rawValue]
            } else {
                return dict[dict.keys.first!]
            }
        }
        
        var unboxedFields: UnboxedFields = [:]
        
        let container = try decoder.container(keyedBy: EntryCodingKeys.self)
        
        let sys = try container.nestedContainer(keyedBy: EntrySysCodingKeys.self, forKey: .sys)
        
        unboxedFields["id"] = try sys.decode(String.self, forKey: .id)
        unboxedFields["version"] = try sys.decode(Int.self, forKey: .version)
        
        let locale = decoder.userInfo[CodingUserInfoKey(rawValue: "locale")!] as? Locale
        
        let fields = try container.nestedContainer(keyedBy: GenericCodingKeys.self, forKey: .fields)
        
        for key in fields.allKeys {
            let field = key.stringValue
         
            if let (type, required) = unboxing(field) {
                do {
                    
                    print ("debug: decoding field: \(field) as \(type) required \(required)")
                    
                    switch type {
                    case .string:
                        let stringDict = try fields.decode(StringDict.self, forKey: key)
                        unboxedFields[field] = getValueFromDict(dict: stringDict, locale: locale)
                    case .int:
                        let intDict = try fields.decode(IntDict.self, forKey: key)
                        unboxedFields[field] = getValueFromDict(dict: intDict, locale: locale)
                    case .bool:
                        let boolDict = try fields.decode(BoolDict.self, forKey: key)
                       unboxedFields[field] = getValueFromDict(dict: boolDict, locale: locale)
                    case .decimal:
                        let doubleDict = try fields.decode(DoubleDict.self, forKey: key)
                        unboxedFields[field] = getValueFromDict(dict: doubleDict, locale: locale)
                    case .date:
                        let stringDict = try fields.decode(StringDict.self, forKey: key)
                        let dateString = getValueFromDict(dict: stringDict, locale: locale)
                        let formatter = ISO8601DateFormatter()
                        guard let ds = dateString, let date = formatter.date(from: ds) else { throw DecodingError.fieldFormatError }
                        unboxedFields[field] = date
                    case .reference:
                        let refDict = try fields.decode(RefDict.self, forKey: key)
                        guard let sysDict  = getValueFromDict(dict: refDict, locale: locale),
                            let idDict = sysDict["sys"],
                            let id = idDict["id"] else { throw DecodingError.invalidData }
                        unboxedFields[field] = id

                    }
                    
                    print ("field: \(field) required: \(required), set \(unboxedFields[field])" )
                    
                    if required && unboxedFields[field] == nil {
                        
                        print("debug: field \(field) is required and not set so should throw here")
                        throw DecodingError.requiredKeyMissing(key)
                    }
                    
                } catch {
      
                    throw DecodingError.typeMismatch(String.self)
                }
            }
        }
        return unboxedFields
    }
}
