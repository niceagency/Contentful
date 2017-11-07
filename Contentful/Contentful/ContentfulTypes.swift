//
//  ContentfulTypes.swift
//  DeviceManagement
//
//  Created by Sam Woolf on 24/10/2017.
//  Copyright © 2017 Nice Agency. All rights reserved.
//

import Foundation

public typealias UnboxedFields = [String:Any]
public typealias FieldMapping = [String:(UnboxedType,Bool)]

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

public protocol ResultError {
    func underlyingError() -> Error
    func errorMessage() -> String
}

public enum DecodingError: Error, ResultError {
    case typeMismatch(Any.Type)
    case requiredKeyMissing(CodingKey)
    case fieldFormatError
    case invalidData
    case missingRequiredFields([String])
    
    public func underlyingError() -> Error {
        return self
    }
    
    public func errorMessage() -> String {
        switch self {
        case .typeMismatch(let type):
            return ("wrong type: \(String(describing: type))")
        case .requiredKeyMissing(let key):
            return ("missing required field \(key.stringValue)")
        case .fieldFormatError:
            return ("field format error")
        case .invalidData:
            return ("data corrupt")
        case .missingRequiredFields(let fields ):
             return ("missing required fields \(fields)")
        }
    }
}

extension Swift.DecodingError: ResultError {
    public func underlyingError() -> Error {
        return self
    }
    
    public func errorMessage() -> String {
        switch self {
        case .typeMismatch(let type):
            return ("wrong type: \(String(describing: type))")
        case .valueNotFound(_, _):
            return ("value not found")
        case .keyNotFound(_, _):
            return ("key not found")
        case .dataCorrupted(_):
            return ("data corrupted")
        }
    }
}

public enum Result<T> {
    case success(T)
    case error(ResultError)
}

public struct SysData {
    public let id: String
    public let version: Int
}

public struct PagedResult<T> {
    public let results: [T]
    public let page: Page
}

public enum UnboxedType {
    case string
    case int
    case date
    case decimal
    case bool
    case reference
}
