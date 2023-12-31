//
//  URLTemplateChatPinService.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/5/31.
//

import Foundation
import RustPB
import TangramService
import LarkContainer
import LKCommonsLogging

public protocol URLTemplateChatPinService {
    var templateService: URLTemplateService? { get }
    func getTemplate(id: String) -> Basic_V1_URLPreviewTemplate?
    func update(templates: [String: Basic_V1_URLPreviewTemplate])
}

final class URLTemplateChatPinServiceImp: URLTemplateChatPinService {
    private static let logger = Logger.log(URLTemplateChatPinServiceImp.self, category: "Module.IM.ChatPin")

    let templateService: URLTemplateService?
    private let chatId: String
    init(chatId: String, pushCenter: PushNotificationCenter, updateHandler: @escaping ([String]) -> Void, urlAPI: URLPreviewAPI?) {
        self.templateService = URLTemplateService(
            pushCenter: pushCenter,
            updateHandler: { _, missingTemplateIDs in
                updateHandler(missingTemplateIDs)
            },
            sourceType: .pinCard,
            urlAPI: urlAPI
        )
        self.templateService?.observe()
        self.chatId = chatId
    }

    func getTemplate(id: String) -> Basic_V1_URLPreviewTemplate? {
        return self.templateService?.getTemplate(id: id)
    }

    func update(templates: [String: Basic_V1_URLPreviewTemplate]) {
        Self.logger.info("chatPinCardTrace previewService \(chatId) handle templateIDs \(Array(templates.keys))")
        self.templateService?.update(templates: templates)
    }

}

final class DefaultURLTemplateChatPinServiceImp: URLTemplateChatPinService {
    var templateService: URLTemplateService? { return nil }
    func getTemplate(id: String) -> Basic_V1_URLPreviewTemplate? { return nil }
    func update(templates: [String: Basic_V1_URLPreviewTemplate]) {}
}
