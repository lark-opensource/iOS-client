//
//  QRCodeUrlAnalysisModule.swift
//  LarkWeb
//
//  Created by zc09v on 2018/10/11.
//

import UIKit
import Foundation
import EENavigator
import LarkAppLinkSDK
import LarkUIKit
import Homeric
import LKCommonsTracker
import LarkContainer
import LarkNavigator

final class QRCodeUrlAnalysisModule: QRCodeAnalysis {

    private let userResolver: UserResolver
    init(userResolver: UserResolver) { self.userResolver = userResolver }

    func handle(code: String, status: QRCodeAnalysisCallBack, from: QRCodeFromType, fromVC: UIViewController) -> Bool {
        let topMostFrom = WindowTopMostFrom(vc: fromVC)
        //下面一行为了解决URL末尾有\t,\n,\r以及空格而不能跳转的问题
        let codeString: String = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: codeString) ??
            URL(string: codeString.addingPercentEncoding(
                withAllowedCharacters: .urlQueryAllowed) ?? codeString),
              userResolver.navigator.contains(url, context: [:]) else {
            return false
        }
        let navigator = userResolver.navigator
        status?(.preFinish, { [weak self] in
            guard let self = self, let fromVC = topMostFrom.fromViewController else {
                assertionFailure()
                return
            }
            if forcePresentURLs.contains(where: { url.absoluteString.hasPrefix($0) }) {
                navigator.present(
                    url,
                    context: self.getFromContext(from: from),
                    from: topMostFrom,
                    prepare: {
                        if Display.pad {
                            $0.modalPresentationStyle = .formSheet
                        } else {
                            $0.modalPresentationStyle = .fullScreen
                        }
                    })
            } else {
                var context = self.getFromContext(from: from)
                if QRCodeAnalysisManager.jumpWayisPush(from: fromVC) {
                    if let scheme = url.scheme, !scheme.contains("http") {
                        Tracker.post(TeaEvent(Homeric.APPLINK_FEISHU_OPEN_OTHERAPP,
                                              params: ["schema": scheme, "type": "scan"]))
                    }
                    var params = NaviParams()
                    if Display.pad {
                        params.forcePush = true
                    }
                    context = context.merging(naviParams: params)
                    navigator.push(
                        url,
                        context: context,
                        from: topMostFrom
                    )
                } else {
                    var params = NaviParams()
                    params.switchTab = feedURL
                    context = context.merging(naviParams: params)
                    navigator.showDetail(
                        url,
                        context: context,
                        wrap: LkNavigationController.self,
                        from: topMostFrom)
                }
            }
        })
        return true
    }

    func getFromContext(from: QRCodeFromType) -> [String: Any] {
        var array = [String: Any]()
        switch from {
        case .camera:
            array[FromSceneKey.key] = FromScene.camera_qrcode.rawValue
        case .pressImage:
            array[FromSceneKey.key] = FromScene.press_image_qrcode.rawValue
        case .album:
            array[FromSceneKey.key] = FromScene.album_qrcode.rawValue
        }
        array["scene"] = "messenger"
        array["location"] = "messenger_qr"
        return array
    }
}
