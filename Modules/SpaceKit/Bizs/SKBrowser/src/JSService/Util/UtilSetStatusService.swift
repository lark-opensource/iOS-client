//
//  UtilSetStatus.swift
//  SpaceKit
//
//  Created by nine on 2019/8/21.
//

import Foundation
import SKCommon
import SKUIKit

enum UtilSetStatusType: Int {
    case contentVerifed = 1
}

public final class UtilSetStatusService: BaseJSService {
    func handSetStatus(params: [String: Any]) {
        guard let typeIntValue = params["type"] as? Int, let type = UtilSetStatusType(rawValue: typeIntValue), let data = params["data"] as? [String: Any] else { return }
        switch type {
        case .contentVerifed:
            if let verified = data["verified"] as? Bool {
                setAnnouncementStatus(with: verified)
            }
        }
    }

    /// 设置群公告是否合规可发布
    ///
    /// - Parameter canAnnounce: 是否可发布
    private func setAnnouncementStatus(with canAnnounce: Bool) {
        if let openBrowerVC = navigator?.currentBrowserVC as? AnnouncementViewControllerBase {
            openBrowerVC.setAnnouncementStatus(canAnnounce)
        }
        let tipsView = NetInterruptTipView.defaultView()
        tipsView.setTip(.announcementEditingIllegal)
        if canAnnounce {
            ui?.bannerAgent.requestHideItem(tipsView)
        } else {
            ui?.bannerAgent.requestShowItem(tipsView)
        }
    }
}

extension UtilSetStatusService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.setStatus]
    }

    public func handle(params: [String: Any], serviceName: String) {
        switch serviceName {
        case DocsJSService.setStatus.rawValue:
            handSetStatus(params: params)
        default: ()
        }
    }
}
