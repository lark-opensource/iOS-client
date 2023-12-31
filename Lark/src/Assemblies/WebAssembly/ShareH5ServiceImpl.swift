//
//  ShareH5ServiceImpl.swift
//  LarkWebViewController
//
//  Created by Meng on 2020/12/7.
//

import Foundation
import RoundedHUD
import RxSwift
import EENavigator
import LarkContainer
import LarkSDKInterface
import LarkMessengerInterface
import LKCommonsLogging
import LKCommonsTracker
import LarkFeatureGating
import Homeric
import LarkOPInterface
import WebBrowser
import LarkOpenPlatform
import JsSDK
import LarkUIKit
import ByteWebImage
import RustPB
import LarkSetting
import UIKit

extension ShareH5ServiceImpl {
    enum Constant {
        /// 默认的分享图片上传压缩参数，与其他应用分享逻辑保持一致
        static public let imageCompressedSize: Int64 = 300
    }
}

/// ShareH5ServiceImpl
final class ShareH5ServiceImpl: ShareH5Service {
    static let logger = Logger.log(ShareH5Service.self, category: "Web.ShareH5Service")

    private let disposeBag = DisposeBag()
    @Provider private static var imageAPI: ImageAPI

    public init() {}

    public func share(
        with context: ShareH5Context,
        successHandler: @escaping () -> Void,
        errorHandler: @escaping (Error?) -> Void
    ) {
        Self.logger.info("[ShareH5]: start share")

        let eventParams: [AnyHashable: Any] = [
            "appid": context.appId ?? "",
            "type": context.type.eventTypeString
        ]
        // 开始分享埋点
        let startEvent = TeaEvent(Homeric.OP_H5_SHARE_VIEW, params: eventParams)
        Tracker.post(startEvent)

        let hud = RoundedHUD.showLoading(on: context.targetVC.view)
        Observable<Void>.just(())
            .subscribeOn(SerialDispatchQueueScheduler(qos: .userInitiated))
            .flatMap({ () -> Observable<String?> in
                // 异步加载 image 数据并上传转换为 imageToken
                return try context.icon
                    .flatMap({ wrapped -> Data? in
                        switch wrapped {
                        case let .url(iconURL):
                            return try URL(string: iconURL)
                                .map({ try Data(contentsOf: $0) })
                                .flatMap({ UIImage(data: $0)?.pngData() })
                        case let .data(iconData):
                            return iconData
                        @unknown default:
                            assertionFailure()
                            return nil
                        }
                    }).flatMap({ imageData in
                        return Self.imageAPI.uploadSecureImage(
                            data: imageData,
                            type: .normal,
                            imageCompressedSizeKb: Constant.imageCompressedSize
                        )
                    })?.do(onNext: { _ in
                        OPMonitor(OPShareMonitorCodeH5.share_upload_image_success)
                            .addCategoryValue("app_id", context.appId)
                            .addCategoryValue("op_tracking", context.type.opTracking)
                            .flush()
                    }, onError: { error in
                        OPMonitor(OPShareMonitorCodeH5.share_upload_image_failed)
                            .addCategoryValue("app_id", context.appId)
                            .addCategoryValue("op_tracking", context.type.opTracking)
                            .setError(error)
                            .flush()
                    }).map({ $0 }) ?? .just(nil)
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (token) in
                Self.logger.info("[ShareH5]: start share card")
                Self.shareCard(with: context, iconToken: token)
                // 分享成功埋点
                let successEvent = TeaEvent(Homeric.OP_H5_SHARE_SUCCESS, params: eventParams)
                Tracker.post(successEvent)
                successHandler()
            }, onError: { (error) in
                Self.logger.error("[ShareH5]: handle image token error", error: error)
                hud.remove()
                // 图片处理失败仍然可以分享，image在服务端使用默认兜底图
                Self.shareCard(with: context, iconToken: nil)
                errorHandler(error)
            }, onCompleted: {
                hud.remove()
            })
            .disposed(by: disposeBag)
    }

    private static func shareCard(with context: ShareH5Context, iconToken: String?) {
        let monitorMap: [String: Any] = [
            "app_id": context.appId ?? "",
            "op_tracking": context.type.opTracking,
            "hasToken": "\(!(iconToken?.isEmpty ?? true))"
        ]
        OPMonitor(OPShareMonitorCodeH5.share_container_start).addMap(monitorMap).flush()

        let shareCallback = { (data: [String: Any]?, isCancel: Bool) in
            OPMonitor(OPShareMonitorCodeH5.share_container_close).addMap(monitorMap).flush()
            if !isCancel {
                if data == nil {
                    OPMonitor(OPShareMonitorCodeH5.share_card_failed).addMap(monitorMap).flush()
                } else {
                    OPMonitor(OPShareMonitorCodeH5.share_card_success).addMap(monitorMap).flush()
                }
            }
        }
        shareH5Card(with: context, iconToken: iconToken, shareCallback: shareCallback)
    }

    /// 新版的H5分享，不区分分享类型（H5应用/H5页面）
    private static func shareH5Card(
        with context: ShareH5Context,
        iconToken: String?,
        shareCallback: (([String: Any]?, Bool) -> Void)?
    ) {
        let shareType = context.shareH5Type(with: iconToken)
        var body = AppCardShareBody(shareType: shareType, appUrl: context.url, callback: shareCallback)
        body.multiSelect = true
        Self.logger.info("share to chat preview,has title:\(!context.title.isEmpty), has desc\(!context.desc.isEmpty), has iconToken\(!iconToken.isEmpty)")
        let customView = H5SharePreviewView(title: context.title, description: context.desc ?? "", imageKey: iconToken ?? "")
        body.customView = customView
        Navigator.shared.present(
            body: body,
            from: context.targetVC,
            prepare: { $0.modalPresentationStyle = .formSheet }
        )
    }
}
