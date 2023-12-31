//
//  Thread+LogInfo.swift
//  LarkExtensionServices
//
//  Created by lvdaqian on 2019/12/15.
//

import Foundation

extension Thread {
    static var logInfo: String {

        if let name = current.name, !name.isEmpty {
            return name
        }

        if isMainThread {
            return "Main"
        }

        return "T:\(current.hash)"
    }
}
