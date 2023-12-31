//
//  Utils.swift
//
//
//  Created by kef on 2022/2/14.
//

import Foundation

extension String {
    public static func fromCValue(_ cString: UnsafePointer<Int8>?) -> String? {
        if let cStrUnwrapped = cString {
            return String(cString: cStrUnwrapped)
        } else {
            return nil
        }
    }
    
    func unsafeMutablePointerRetained() -> UnsafeMutablePointer<Int8>! {
        return strdup(self)
    }
}

extension UnsafePointer where Pointee == Int8 {
    public func freeUnsafeMemory() {
        free(UnsafeMutableRawPointer(mutating: UnsafeRawPointer(self)))
    }
}

extension UnsafeMutablePointer where Pointee == Int8 {
    public func freeUnsafeMemory() {
        free(UnsafeMutableRawPointer(mutating: UnsafeRawPointer(self)))
    }
}

public func getClassPtr<T: AnyObject>(_ obj: T) -> UnsafeMutableRawPointer {
    return UnsafeMutableRawPointer(Unmanaged.passUnretained(obj).toOpaque())
}
