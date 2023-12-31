//
//  CommentSendStatisticService.swift
//  SKCommon
//
//  Created by ByteDance on 2023/5/17.
//

import Foundation
import SKInfra
import SpaceInterface

/// 用户视角发送成功率埋点
public final class CommentSendStatisticService: BaseJSService, DocsJSServiceHandler {

    public var reporter: CommentSendResultReporterType? { sendResultReporter }

    private lazy var sendResultReporter: CommentSendResultReporterType? = {
        var instance = DocsContainer.shared.resolve(CommentSendResultReporterType.self)
        instance?.commentDocsInfoBlock = { [weak self] in
            let info = self?.model?.browserInfo.docsInfo
            return info
        }
        return instance
    }()

    public override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        model.browserViewLifeCycleEvent.addObserver(self)
    }

    public var handleServices: [DocsJSService] {
        [.commentSendResult]
    }

    public func handle(params: [String: Any], serviceName: String) {
        switch serviceName {
        case DocsJSService.commentSendResult.rawValue:
            let res = params["res"] as? String
            let result: CommentBusinessConfig.SendResult
            if res == "success" {
                result = .success
            } else {
                let failReason = params["fail_reason"] as? String
                result = .failure(reason: failReason ?? "")
            }

            if let uuid = params["comment_uuid"] as? String { // 大图浏览时发送首条评论
                sendResultReporter?.markEventEndBy(uuid: uuid, result: result)
            }
            else if let uuid = params["reply_uuid"] as? String {
                sendResultReporter?.markEventEndBy(uuid: uuid, result: result)
            }
        default:
            break
        }
    }
}

extension CommentSendStatisticService: BrowserViewLifeCycleEvent {

    public func browserWillClear() {
        sendResultReporter?.markDocExit()
    }
}

private extension DocsJSService {
    // 回复/编辑评论后，关闭评论卡片，此场景下前端通过这个bridge通知过来
    static let commentSendResult = DocsJSService("biz.comment.sendResult")
}
