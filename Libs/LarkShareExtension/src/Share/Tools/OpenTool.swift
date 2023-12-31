//
//  OpenTool.swift
//  ShareExtension
//
//  Created by kongkaikai on 2019/01/09.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation

final class OpenTool {
    @discardableResult
    static func open(url: URL?) -> Bool {
        let decode: (String) -> String? = {
            guard let data = Data(base64Encoded: $0, options: .ignoreUnknownCharacters) else { return nil }
            return String(data: data, encoding: .utf8)
        }

        guard let url = url,
            let className = decode("VUlBcHBsaWNhdGlvbg=="),
            let shareInstanceMethodName = decode("c2hhcmVkQXBwbGljYXRpb24="),
            let iOS10AboveMethod = decode("b3BlblVSTDpvcHRpb25zOmNvbXBsZXRpb25IYW5kbGVyOg=="),
            let app = (NSClassFromString(className) as? NSObject.Type)?
                .perform(NSSelectorFromString(shareInstanceMethodName), with: nil)?
                .retain().takeRetainedValue() as? NSObject else { return false }

        _ = app.perform(NSSelectorFromString(iOS10AboveMethod), with: url, with: [:], with: nil)

        return true
    }
}

extension NSObject {
    fileprivate func perform(_ aSelector: Selector!, with object1: Any!, with object2: Any!, with object3: Any!) -> Unmanaged<AnyObject>! {
        let method = class_getMethodImplementation(type(of: self), aSelector)
        return unsafeBitCast(method, to: (@convention(c)(Any?, Selector?, Any?, Any?, Any?) -> Unmanaged<AnyObject>?).self)(self, aSelector, object1, object2, object3)
    }
}
