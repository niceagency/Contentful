//
//  ContentfulTypes.swift
//  DeviceManagement
//
//  Created by Sam Woolf on 24/10/2017.
//  Copyright © 2017 Nice Agency. All rights reserved.
//

import Foundation

public typealias UnboxedFields = [String:Any?]
public typealias FieldMapping = [String:(UnboxedType,Bool)]
public typealias WriteRequest  = (data: Data, endpoint: String, headers:  [(String,String)], method: HttpMethod)

public protocol Readable {
    static func contentfulEntryType() -> String
    static func unboxer() -> (FieldMapping)
    static func creator(withFields fields: UnboxedFields) -> Self
}

public protocol Writeable {
    var contentful_id: String { get }
    var contentful_version: Int { get}
}

public typealias Encodable = Swift.Encodable & Writeable

public enum HttpMethod {
    case put
    case post
}

public enum ReferenceType : String {
    case entry = "Entry"
}

public struct Reference : Codable {
    
    private struct Sys: Codable {
        let type: String = "Link"
        let linkType : String
        let id : String
    }
    private let sys: Sys
    
    public var id: String {
        return sys.id
    }
    
    public func getObjectWithId<T: Writeable> (fromCandidates candidates: [T]) -> T? {
        return candidates.first(where: { $0.contentful_id == self.id })
    }
    
    public init (forObject object: Writeable, type: ReferenceType = .entry ) {
        self.sys = Sys(linkType: type.rawValue, id: object.contentful_id)
    }
    
    init (withId id: String, type: String) {
        self.sys = Sys(linkType: type, id: id )
    }
}

public enum DecodingError: Error {
    case typeMismatch(String, UnboxedType)
    case requiredKeyMissing(String)
    case fieldFormatError(String)
    case missingRequiredFields([String])
    
    public func errorMessage() -> String {
        switch self {
        case .typeMismatch(let type):
            return ("wrong type: \(String(describing: type))")
        case .requiredKeyMissing(let string):
            return ("missing required field \(string)")
        case .fieldFormatError:
            return ("field format error")
        case .missingRequiredFields(let fields ):
            return ("missing required fields \(fields)")
        }
    }
}

public enum Result<T> {
    case success(T)
    case error(Swift.DecodingError)
}

public struct SysData {
    public let id: String
    public let version: Int
}

public struct PagedResult<T> {
    public let validItems: [T]
    public let failedItems: [(Int, DecodingError)]
    public let page: Page
}

public enum ItemResult<T> {
    case success(T)
    case error (DecodingError)
}

public enum UnboxedType {
    case string
    case int
    case date
    case decimal
    case bool
    case oneToOneRef
    case oneToManyRef
}
