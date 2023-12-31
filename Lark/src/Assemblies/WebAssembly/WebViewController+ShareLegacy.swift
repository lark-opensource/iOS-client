//
//  WebBrowser+ShareLegacy.swift
//  LarkWebViewController
//
//  Created by Meng on 2020/12/7.
//
// swiftlint:disable all
import Foundation
import WebKit
import ECOProbe
/// 用于兼容分享逻辑的协议，LarkWeb，LarkOPWeb废弃后应当删除
protocol ShareH5InfoTarget {
    var targetVC: UIViewController { get }
    var shareWebView: WKWebView { get }
    var isWebApp: Bool { get }
    var appID: String? { get }
    // for OPMonitor(LarkOPWeb, LarkWebViewController)
    var commonMonitorInfo: [String: AnyHashable] { get }
    var monitorURLInfo: String { get }

    /// LarkWeb, LarkOPWeb继承于BaseUIViewController，LarkWebViewController自己实现了
    func showAlert(title: String, message: String, handler: ((UIAlertAction) -> Void)?)
}

/// 用于LarkOPWeb，LarkWeb使用，兼容老逻辑，分享逻辑收敛
/// 先使用static 持有 shareContainer
/// 所有迁移完成，可以在 LarkWebViewController 持有 shareContainer
final class ShareLegacy {
    static let shareContainer = ShareH5Container()

    static func shareH5(target: ShareH5InfoTarget) {
        OPMonitor(LarkShareConfig.mini_sharecard_chat_send)
            .addMetricValue("app_id", target.appID ?? "")
            .addMetricValue("share_type", "url")
            .setPlatform([.tea, .slardar])
            .flush()
        shareContainer.shareH5(target: target)
    }
}

extension ShareH5InfoTarget {
    // 老分享逻辑（ShareAppPage）取网页截图, LarkWeb完全废弃后应当删除
    func screenShot(aspectRatio: CGFloat? = 211 / 132 /* 历史参数，无法追溯 */) -> UIImage? {
        var bounds = shareWebView.bounds
        if let aspectRatio = aspectRatio, aspectRatio > 0 {
            bounds.size.height = bounds.width / aspectRatio
        }
        UIGraphicsBeginImageContextWithOptions(bounds.size, true, UIScreen.main.scale)
        if shareWebView.drawHierarchy(in: shareWebView.bounds, afterScreenUpdates: true),
            let snapshotImage = UIGraphicsGetImageFromCurrentImageContext() {
            bounds.origin.x *= snapshotImage.scale
            bounds.origin.y *= snapshotImage.scale
            bounds.size.width *= snapshotImage.scale
            bounds.size.height *= snapshotImage.scale
            if let imageRef = snapshotImage.cgImage?.cropping(to: bounds) {
                UIGraphicsEndImageContext()
                return UIImage(
                    cgImage: imageRef,
                    scale: snapshotImage.scale,
                    orientation: snapshotImage.imageOrientation
                )
            }
        }
        UIGraphicsEndImageContext()
        return nil
    }
}
// swiftlint:enable all
