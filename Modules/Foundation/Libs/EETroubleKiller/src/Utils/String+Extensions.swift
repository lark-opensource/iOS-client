//
//  String+Extensions.swift
//  EETroubleKiller
//
//  Created by Meng on 2019/11/20.
//

import Foundation

extension String {
    static func tkName(_ instance: Any) -> String {
        if let routerResource = instance as? RouterResourceProtocol {
            return routerResource.tkName
        }
        if let objcObj = instance as? NSObject {
            return objcObj.tkClassName
        }
        return ""
        // TBD: Meng
        // return _typeName(type(of: instance))
    }

    static func tkId(_ instance: Any) -> String {
        return withUnsafePointer(to: instance, { $0.debugDescription })
    }
}
