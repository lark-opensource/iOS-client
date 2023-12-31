//
//  EnterpriseNoticeAPI.swift
//  LarkEnterpriseNotice
//
//  Created by ByteDance on 2023/4/18.
//

import Foundation
import RxSwift
import ServerPB
import LarkRustClient

public typealias EnterpriseNoticeCard = ServerPB.ServerPB_Entities_SubscriptionsDialog
public typealias CardConfirmType = ServerPB.ServerPB_Subscriptions_dialog_ConfirmSubscriptionsDialogRequest.SubscriptionsDialogConfirmType

final class EnterpriseNoticeAPI {

    var rustService: RustService

    init(rustService: RustService) {
        self.rustService = rustService
    }

    // 拉取通知卡片数据
    func pullEnterpriseNoticeCardInfo() -> Observable<[EnterpriseNoticeCard]> {
        let request = ServerPB.ServerPB_Subscriptions_dialog_PullSubscriptionsDialogRequest()
        return rustService.sendPassThroughAsyncRequest(request, serCommand: .pullSubscriptionsDialog).map({ (resp: ServerPB_Subscriptions_dialog_PullSubscriptionsDialogResponse) in
            resp.dialogs
        })
    }

    // 上报已确认状态
    func uploadEnterpriseNoticeCardAckStatus(id: Int64, confirmType: CardConfirmType) -> Observable<Void> {
        var request = ServerPB.ServerPB_Subscriptions_dialog_ConfirmSubscriptionsDialogRequest()
        request.confirmType = confirmType
        request.dialogID = id
        return rustService.sendPassThroughAsyncRequest(request, serCommand: .confirmSubscriptionsDialog).retry(2)
    }

    // 上报曝光事件
    func uploadEnterpriseNoticeCardExposeEvent(ids: [Int64]) -> Observable<Void> {
        var request = ServerPB.ServerPB_Subscriptions_dialog_UploadSubscriptionsDialogExposureEventRequest()
        request.dialogIds = ids
        return rustService.sendPassThroughAsyncRequest(request, serCommand: .uploadSubscriptionsDialogExposureEvent)
    }
}
