//
//  URLEntryPushHandler.swift
//  TangramService
//
//  Created by 袁平 on 2021/7/28.
//

import Foundation
import LarkRustClient
import RustPB
import LarkContainer
import LKCommonsLogging

extension InlinePreviewEntriesBody: PushMessage {}
extension URLPreviewEntriesBody: PushMessage {}

// https://bytedance.feishu.cn/docs/doccnpSrc2yA2rSuQ8dKvySIWfd
public final class URLEntryPushHandler: UserPushHandler {
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }
    static let logger = Logger.log(URLEntryPushHandler.self, category: "TangramService.URLEntryPushHandler")

    public func process(push message: Url_V1_PushUrlPreviews) {
        let inlines = InlinePreviewEntriesBody.transform(from: message)
        let previews = URLPreviewEntriesBody.transform(from: message)
        pushCenter?.post(inlines)
        pushCenter?.post(previews)
        Self.logger.info("[URLPreview] pushURLPreviews: inlinesInfo = \(inlines.tcDescription) -> previewsInfo = \(previews.tcDescription)")
    }
}
