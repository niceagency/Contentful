//
//  ContentfulTypes.swift
//  DeviceManagement
//
//  Created by Sam Woolf on 24/10/2017.
//  Copyright © 2017 Nice Agency. All rights reserved.
//

import Foundation

public typealias UnboxedFields = [String:Any]

public protocol Readable {
    static func contentfulEntryType() -> String
    static func unboxer(ofField field: String) -> (UnboxedType,Bool)?
    static func creator(withFields fields: UnboxedFields) -> Self
}

public protocol Writeable {
    var contentful_id: String { get }
    var contentful_version: Int { get}
}

public typealias Encodable = Swift.Encodable & Writeable

public enum DecodingError: Error {
    case typeMismatch(Any.Type)
    case requiredKeyMissing(CodingKey)
    case fieldFormatError
    case invalidData
    
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
        }
    }
}

public enum Result<T> {
    case success(T)
    case error(DecodingError)
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
