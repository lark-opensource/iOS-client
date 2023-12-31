//
//  LarkQRCode+Component.swift
//  LarkQRCode
//
//  Created by CharlieSu on 12/12/19.
//

import UIKit
import Foundation
import EENavigator
import Swinject
import QRCode
import LarkUIKit
import AppReciableSDK
import LarkFeatureGating
import LarkNavigator
import LarkContainer
import UniverseDesignDialog

final class QRCodeLifeCircleDelegate: QRCodeViewControllerLifeCircle {
    struct TrackerInfo {
        var startTime: CFTimeInterval = CACurrentMediaTime()
        var initViewCost: CFTimeInterval = 0
        var firstScreenCost: CFTimeInterval = 0
        var onCameraReadyCost: CFTimeInterval = 0
    }
    private var trackerInfo = TrackerInfo()
    private let pageName = "QRCodeViewController"

    func onInit(state: QRCodeLifeCircleState) {
        switch state {
        case .start:
            trackerInfo.initViewCost = CACurrentMediaTime()
        case .end:
            trackerInfo.initViewCost = CACurrentMediaTime() - trackerInfo.initViewCost
        }
    }

    func onViewDidLoad(state: QRCodeLifeCircleState) {
        if state == .end {
            trackerInfo.firstScreenCost = CACurrentMediaTime() - trackerInfo.startTime
        }
    }

    func onCameraReady(state: QRCodeLifeCircleState) {
        AppReciableSDK.shared.timeCost(params: TimeCostParams(
            biz: .Messenger, scene: .Chat, event: .scanerReady,
            cost: Int((CACurrentMediaTime() - trackerInfo.startTime) * 1000), page: pageName,
            extra: Extra(
                isNeedNet: false,
                latencyDetail: [
                    "init_view_cost": Int(trackerInfo.initViewCost * 1000),
                    "camera_ready_cost": Int(trackerInfo.onCameraReadyCost * 1000),
                    "first_render": Int(trackerInfo.firstScreenCost * 1000)
                ],
                metric: nil, category: nil
            )
        ))
    }

    func onError(_ error: Error) {
        let error = error as NSError
        AppReciableSDK.shared.error(params: ErrorParams(
            biz: .Messenger, scene: .Chat, event: .scanerReady, errorType: .Other,
            errorLevel: .Fatal, errorCode: error.code, userAction: nil, page: pageName,
            errorMessage: error.localizedDescription,
            extra: nil
        ))
    }
}

final class QRCodeControllerHandler: UserTypedRouterHandler {
    private var resolver: UserResolver { self.userResolver }

    private lazy var veScanEnable: Bool = resolver.fg.staticFeatureGatingValue(with: "core.scan_qrcode.ve")
    private lazy var avScanEnable: Bool = resolver.fg.staticFeatureGatingValue(with: "core.scan_qrcode.av")

    private func isFullScreen(vc: UIViewController) -> Bool {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return true }
        var isFullScreen = true
        if let window = vc.view.window {
            isFullScreen = window.bounds == UIScreen.main.bounds
        }
        return isFullScreen
    }

    func handle(_ body: QRCodeControllerBody, req: EENavigator.Request, res: Response) throws {
        guard let vc = req.from.fromViewController else {
            assertionFailure()
            return
        }
        let topmostFrom = WindowTopMostFrom(vc: vc)
        let isFullScreen = isFullScreen(vc: vc)
        let controller: ScanCodeViewControllerType = (veScanEnable || avScanEnable) ? ScanCodeViewController(isFullScreen: isFullScreen) : QRCodeViewController()
        if let firstText = body.firstDescribeText,
            let secondText = body.secondDescribeText {
            controller.firstDescribelText = firstText
            controller.secondDescribelText = secondText
        }
        controller.lifeCircle = QRCodeLifeCircleDelegate()
        let block = getQRcodeBlock(resolver: resolver, controller: controller, topmostFrom: topmostFrom,
            stopSessionBlock: { [weak controller] in
                controller?.stopScanning()
            },
            startSessionBlock: { [weak controller] in
            controller?.startScanning()
        })
        controller.didScanQRCodeBlock = block
        res.end(resource: controller)
    }

    func getQRcodeBlock(resolver: UserResolver,
                        controller: BaseUIViewController,
                        topmostFrom: WindowTopMostFrom,
                        stopSessionBlock: @escaping (() -> Void),
                        startSessionBlock: @escaping (() -> Void)) -> ((String, VEQRCodeFromType) -> Void) {
        guard let qrCodeAnalysis = try? resolver.resolve(assert: QRCodeAnalysisService.self) else { return { _, _ in } }
        let block: ((String, VEQRCodeFromType) -> Void) = { [weak controller] (result, from) in
            var retFrom: QRCodeFromType = .camera
            if from == .camera {
                retFrom = .camera
            } else if from == .album {
                retFrom = .album
            }
            guard let controller = controller, let fromVC = topmostFrom.fromViewController else { return }
            qrCodeAnalysis.handle(code: result, status: { status, callBack in
                switch status {
                case .preFinish:
                    // 扫一扫页面扫描完成之后，需要先销毁，再跳转到扫描结果页
                    // 如果controller是当前nav的rootVC，pop回去，否则dismiss
                    if let navigationController = controller.navigationController,
                        navigationController.viewControllers.first != controller {
                        navigationController.popViewController(animated: false)
                        callBack?()
                    } else {
                        controller.dismiss(animated: false, completion: {
                            callBack?()
                        })
                    }
                case .fail(errorInfo: let errorInfo):
                    stopSessionBlock()
                    if let errorInfo = errorInfo {
                        let alert = UDDialog()
                        alert.setTitle(text: BundleI18n.LarkQRCode.Lark_Legacy_Hint)
                        alert.setContent(text: errorInfo, numberOfLines: 0)
                        alert.addPrimaryButton(text: BundleI18n.LarkQRCode.Lark_Legacy_Sure, dismissCompletion: {
                            startSessionBlock()
                        })
                        controller.present(alert, animated: true)
                    } else {
                        startSessionBlock()
                    }
                    callBack?()
                }
            }, from: retFrom, fromVC: fromVC)
        }
        return block
    }
}

final class QRCodeDetectLinkHandler: UserTypedRouterHandler {
    func handle(_ body: QRCodeDetectLinkBody, req: EENavigator.Request, res: Response) throws {
        let vc = CodeDetectLinkViewController(code: body.code)
        res.end(resource: vc)
    }
}
