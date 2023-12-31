//
//  ChatWidgetURLTemplateService.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/1/10.
//

import Foundation
import RustPB
import TangramService
import LarkContainer
import LarkCore
import LKCommonsLogging

public protocol ChatWidgetURLTemplateService {
    var templateService: URLTemplateService? { get }
    func getTemplate(id: String) -> Basic_V1_URLPreviewTemplate?
    func update(templates: [String: Basic_V1_URLPreviewTemplate])
}

public final class ChatWidgetURLTemplateServiceImp: ChatWidgetURLTemplateService {
    static let logger = Logger.log(ChatWidgetURLTemplateServiceImp.self, category: "ChatWidgetURLTemplateServiceImp")

    public let templateService: URLTemplateService?
    private let chatId: String
    public init(chatId: String, pushCenter: PushNotificationCenter, updateHandler: @escaping ([String]) -> Void, urlAPI: URLPreviewAPI?) {
        self.templateService = URLTemplateService(
            pushCenter: pushCenter,
            updateHandler: { _, missingTemplateIDs in
                updateHandler(missingTemplateIDs)
            },
            sourceType: .widget,
            urlAPI: urlAPI
        )
        self.templateService?.observe()
        self.chatId = chatId
    }

    public func getTemplate(id: String) -> Basic_V1_URLPreviewTemplate? {
        return self.templateService?.getTemplate(id: id)
    }

    public func update(templates: [String: Basic_V1_URLPreviewTemplate]) {
        Self.logger.info("widgetsTrace previewService \(chatId) handle templateIDs \(Array(templates.keys))")
        self.templateService?.update(templates: templates)
    }

}

final class DefaultChatWidgetURLTemplateServiceImp: ChatWidgetURLTemplateService {
    var templateService: URLTemplateService? { return nil }
    func getTemplate(id: String) -> Basic_V1_URLPreviewTemplate? { return nil }
    func update(templates: [String: Basic_V1_URLPreviewTemplate]) {}
}
