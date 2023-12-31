//
//  QRCodeAnalysisManager.swift
//  LarkCore
//
//  Created by zc09v on 2018/10/11.
//

import UIKit
import Foundation
import LarkContainer
import LarkUIKit
import EENavigator
import QRCode
import LarkSplitViewController

protocol QRCodeAnalysis {
    func handle(code: String, status: QRCodeAnalysisCallBack, from: QRCodeFromType, fromVC: UIViewController) -> Bool
}

public protocol LKKAQRCodeApiProtocol {
    /// 飞书扫码逻辑之前调用
    /// - Parameter result: 扫码结果
    /// - Returns: 是否承载本次扫码结果
    func interceptHandle(result: String) -> Bool
    /// 飞书扫码逻辑处理之后调用
    /// - Parameter result: 扫码结果
    /// - Returns: 是否承载本次扫码结果
    func handle(result: String) -> Bool
}

public final class QRCodeAnalysisManager: QRCodeAnalysisService {
    private var modules: [QRCodeAnalysis]
    private var handle: LKKAQRCodeApiProtocol? { try? userResolver.resolve(type: LKKAQRCodeApiProtocol.self) }

    private let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        modules = [
            QRCodeJoinTeamAnalysisModule(userResolver: userResolver),
            QRCodeLogAuthAnalysisModule(userResolver: userResolver),
            QRCodeUrlAnalysisModule(userResolver: userResolver)
        ]
    }

    public func handle(code: String, status: QRCodeAnalysisCallBack, from: QRCodeFromType, fromVC: UIViewController) {
        if handle?.interceptHandle(result: code) == true {
            return
        }
        for module in modules {
            if module.handle(code: code, status: status, from: from, fromVC: fromVC) {
                return
            }
        }
        if handle?.handle(result: code) == true {
            return
        }

        let navifrom = WindowTopMostFrom(vc: fromVC)

        let navigator = self.userResolver.navigator
        status?(.preFinish, {
            let body = QRCodeDetectLinkBody(code: code)

            if QRCodeAnalysisManager.jumpWayisPush(from: fromVC) {
                var params = NaviParams()
                if Display.pad {
                    params.forcePush = true
                }
                navigator.push(
                    body: body,
                    naviParams: params,
                    from: navifrom
                )
            } else {
                var params = NaviParams()
                params.switchTab = feedURL
                navigator.showDetail(
                    body: body,
                    naviParams: params,
                    wrap: LkNavigationController.self,
                    from: navifrom
                )
            }
        })
    }

    public class func jumpWayisPush(from: UIViewController) -> Bool {
        if Display.phone {
            return true
        }
        guard let detail = from.larkSplitViewController?.secondaryViewController else {
            return false
        }
        if isDefaultDetailController(vc: detail) {
            return false
        }
        return true
    }
    // 工具方法，判断detail是否为默认空页面
    private class func isDefaultDetailController(vc: UIViewController) -> Bool {
        if vc is UIViewController.DefaultDetailController {
            return true
        }
        if let nav = vc as? UINavigationController, let controller = nav.topViewController, controller is UIViewController.DefaultDetailController {
            return true
        }
        return false
    }
}
