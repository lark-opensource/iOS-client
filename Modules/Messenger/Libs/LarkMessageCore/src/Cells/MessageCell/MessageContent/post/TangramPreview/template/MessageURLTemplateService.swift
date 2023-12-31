//
//  MessageURLTemplateService.swift
//  LarkCore
//
//  Created by 袁平 on 2022/3/3.
//

import Foundation
import RustPB
import LarkModel
import LarkContainer
import TangramService
import LarkMessageBase
import DynamicURLComponent

public final class MessageURLTemplateService: PageService {

    public let templateService: URLTemplateService

    public init(context: PageContext?, pushCenter: PushNotificationCenter) {
        self.templateService = URLTemplateService(
            pushCenter: pushCenter,
            updateHandler: { [weak context] messageIDs, _ in
                // 更新本地缓存之后，触发一下CellVM的刷新
                context?.reloadRows(by: messageIDs, doUpdate: { data in
                    return data.message
                })
            },
            sourceType: .message,
            urlAPI: try? context?.resolver.resolve(assert: URLPreviewAPI.self)
        )
    }

    public func beforeFetchFirstScreenMessages() {
        self.templateService.observe()
    }

    public func getTemplate(id: String) -> Basic_V1_URLPreviewTemplate? {
        return self.templateService.getTemplate(id: id)
    }
}
