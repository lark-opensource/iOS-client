//
//  NSType+Export.swift
//  LarkStorage
//
//  Created by 7Up on 2023/9/7.
//

import Foundation

/// Export NSData/NSString/NSDictionary Apis defined in LarkStorageCore

extension NSData {
    @objc(lss_dataWithContentsOfURL:options:error:)
    public class func lssSmartRead(from url: URL, options: NSData.ReadingOptions) throws -> NSData {
        return try lscSmartRead(from: url, options: options)
    }

    @objc(lss_dataWithContentsOfURL:error:)
    public class func lssSmartRead(from url: URL) throws -> NSData {
        return try lscSmartRead(from: url)
    }

    @objc(lss_dataWithContentsOfFile:options:error:)
    public class func lssSmartRead(from path: String, options: NSData.ReadingOptions) throws -> NSData {
        return try lscSmartRead(from: path, options: options)
    }

    @objc(lss_dataWithContentsOfFile:error:)
    public class func lssSmartRead(from path: String) throws -> NSData {
        return try lscSmartRead(from: path)
    }
}

extension NSString {
    @objc(lss_stringWithContentsOfURL:encoding:error:)
    public class func lssSmartRead(from url: URL, encoding: UInt) throws -> NSString {
        return try lscSmartRead(from: url, encoding: encoding)
    }

    @objc(lss_stringWithContentsOfFile:encoding:error:)
    public class func lssSmartRead(from path: String, encoding: UInt) throws -> NSString {
        return try lscSmartRead(from: path, encoding: encoding)
    }
}

extension NSDictionary {
    @objc(lss_dictionaryWithContentsOfURL:error:)
    public class func lssSmartRead(from url: URL) throws -> NSDictionary {
        return try lscSmartRead(from: url)
    }
}
