//
//  URL+Ext.swift
//  DocsSDK
//
//  Created by huahuahu on 2018/11/15.
//

import Foundation
import LarkAppLinkSDK
import EENavigator

extension URL: MailExtensionCompatible {}

extension MailExtension where BaseType == URL {
    var queryParams: [String: String]? {
        guard let query = base.query else { return nil }
        var queryStrings = [String: String]()
        for pair in query.components(separatedBy: "&") {
            let kvMapping = pair.components(separatedBy: "=")
            if kvMapping.count < 2 {
                continue
            }
            let key = kvMapping[0]
            let value = kvMapping[1].replacingOccurrences(of: "+", with: " ").removingPercentEncoding ?? ""
            queryStrings[key] = value
        }
        return queryStrings
    }

    func canOpen(navigator: Navigatable) -> Bool {
        let param = navigator.response(for: base, context: [:], test: true).parameters
        if param[AppLinkAssembly.KEY_CAN_OPEN_APP_LINK] as? Bool == true {
            return true
        }
        return false
    }

    // 返回去掉extension的文件名，如: blah/hello.gif，返回 hello
    var fileName: String? {
        var fileName = ""
        if !self.base.lastPathComponent.isEmpty {
            fileName = self.base.lastPathComponent
            // 去掉extension
            if !self.base.pathExtension.isEmpty && fileName.count > (self.base.pathExtension.count + 1) {
                fileName.removeLast(self.base.pathExtension.count + 1)
            }
        }
        return fileName.isEmpty ? nil : fileName
    }
}
