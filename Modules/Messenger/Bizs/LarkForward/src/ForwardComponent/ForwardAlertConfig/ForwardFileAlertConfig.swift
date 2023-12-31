//
//  ForwardFileAlertConfig.swift
//  LarkForward
//
//  Created by ByteDance on 2023/5/25.
//

import LarkCore
import LarkFileKit
import LKCommonsLogging
import LarkMessengerInterface

final class ForwardFileAlertConfig: ForwardAlertConfig {
    static let logger = Logger.log(ForwardFileAlertConfig.self, category: "ForwardFile.provider")
    override class func canHandle(content: ForwardAlertContent) -> Bool {
        if content as? ForwardFileAlertContent != nil {
            return true
        }
        return false
    }

    override func getContentView() -> UIView? {
        guard let fileContent = content as? ForwardFileAlertContent else { return nil }
        let wrapperView = ForwardFileConfirmFooter(content: fileContent)
        return wrapperView
    }
}
