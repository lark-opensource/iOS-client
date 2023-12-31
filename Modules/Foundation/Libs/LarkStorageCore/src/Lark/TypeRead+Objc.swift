//
//  TypeRead+Objc.swift
//  LarkStorage
//
//  Created by 7Up on 2023/3/15.
//

import Foundation

private func _decrypted(path: String, type: String) -> String {
    var decryptedPath = path
    if let cipher = SBCipherManager.shared.cipher(for: .default) {
        do {
            decryptedPath = try cipher.decryptPath(path)
        } catch {
            let message = "decrypt failed. type: \(type), path: \(path), err: \(error)"
            sandboxLogger.error(message)
            SBUtils.assert(false, message, event: AbsPath(path).exists ? .decryptPath : .decryptNotExistsPath)
        }
    }
    return decryptedPath
}

extension NSData {
    public class func lscSmartRead(from url: URL, options: NSData.ReadingOptions) throws -> NSData {
        if LarkStorageFG.decryptRead {
            return try _lsc_DecryptRead(from: url.path, options: options)
        } else {
            return try NSData(contentsOf: url, options: options)
        }
    }

    public class func lscSmartRead(from url: URL) throws -> NSData {
        if LarkStorageFG.decryptRead {
            return try _lsc_DecryptRead(from: url.path)
        } else {
            return try NSData(contentsOf: url)
        }
    }

    public class func lscSmartRead(from path: String, options: NSData.ReadingOptions) throws -> NSData {
        if LarkStorageFG.decryptRead {
            return try _lsc_DecryptRead(from: path, options: options)
        } else {
            return try NSData(contentsOfFile: path, options: options)
        }
    }

    public class func lscSmartRead(from path: String) throws -> NSData {
        if LarkStorageFG.decryptRead {
            return try _lsc_DecryptRead(from: path)
        } else {
            return try NSData(contentsOfFile: path)
        }
    }

    private class func _lsc_DecryptRead(from path: String, options: NSData.ReadingOptions? = nil) throws -> NSData {
        let decryptedPath = _decrypted(path: path, type: "NSData")
        if let opt = options {
            return try NSData(contentsOfFile: decryptedPath, options: opt)
        } else {
            return try NSData(contentsOfFile: decryptedPath)
        }
    }
}

extension NSString {
    public class func lscSmartRead(from url: URL, encoding: UInt) throws -> NSString {
        if LarkStorageFG.decryptRead {
            return try _lsc_DecryptRead(from: url.path, encoding: encoding)
        } else {
            return try NSString(contentsOf: url, encoding: encoding)
        }
    }

    public class func lscSmartRead(from path: String, encoding: UInt) throws -> NSString {
        if LarkStorageFG.decryptRead {
            return try _lsc_DecryptRead(from: path, encoding: encoding)
        } else {
            return try NSString(contentsOfFile: path, encoding: encoding)
        }
    }

    private class func _lsc_DecryptRead(from path: String, encoding: UInt) throws -> NSString {
        let decryptedPath = _decrypted(path: path, type: "NSString")
        return try NSString(contentsOfFile: decryptedPath, encoding: encoding)
    }
}

extension NSDictionary {
    public class func lscSmartRead(from url: URL) throws -> NSDictionary {
        if LarkStorageFG.decryptRead {
            return try _lsc_DecryptRead(from: url.path)
        } else {
            return try NSDictionary(contentsOf: url, error: ())
        }
    }

    private class func _lsc_DecryptRead(from path: String) throws -> NSDictionary {
        let decryptedPath = _decrypted(path: path, type: "NSDictionary")
        return try NSDictionary(contentsOf: URL(fileURLWithPath: decryptedPath), error: ())
    }
}
