//
//  LarkEditorJS.swift
//  LarkEditorJS
//
//  Created by tefeng liu on 2020/5/28.
//

import Foundation

public extension Notification.Name {
    public struct LarkEditorJS {
        /// when resouce has unzip and copy
        public static let BUNDLE_RESOUCE_HAS_BEEN_UNZIP = Notification.Name(rawValue: "BUNDLE_RESOUCE_HAS_BEEN_UNZIP")
    }
}

public class LarkEditorJS {
    public static let shared = LarkEditorJS()
    @ThreadSafe var isReady = false

    init() {
       // TODO: do somthing if needed
    }
}

extension LarkEditorJS {
    public func isResourceReady() -> Bool {
        return isReady
    }
}

