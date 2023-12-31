//
//  WebDriveDownloadService.swift
//  LarkOpenPlatform
//
//  Created by Ding Xu on 2022/7/18.
//

import Foundation
import Swinject
import LarkContainer
import SpaceInterface
import WebBrowser
import EENavigator
import UIKit
import CloudKit
import LarkMessengerInterface
import LarkModel
import LarkUIKit
import UniverseDesignToast
import LarkCore
import ECOProbe
import RxSwift
import UniverseDesignToast
import LarkFeatureGating
import LarkEMM
import OPFoundation

class OPWebDriveMoreForwardProvider: DriveSDKCustomMoreActionProvider {
    private weak var from: WebBrowser?

    var actionId: String {
        return OPWebBrowserDriveAppID
    }
    var text: String {
        return BundleI18n.LarkOpenPlatform.CreationDriveSDK_common_forward

    }
    lazy var handler: (UIViewController, DKAttachmentInfo) -> Void = { [weak self] vc, info in
        guard let self = self else {
            WebBrowser.logger.info("OPWDownload DriveSDKLocalFileV2 share fail, self is nil")
            return
        }
        guard let fileURL = info.localPath?.path else {
            WebBrowser.logger.info("OPWDownload DriveSDKLocalFileV2 share fail, fileURL is nil")
            return
        }
        let forwardBody = ForwardFileBody(fileName: info.name, fileURL:fileURL, fileSize: Int64(info.size)) { resultArr in
            guard let resultArr = resultArr else {
                WebBrowser.logger.info("OPWDownload DriveSDKLocalFileV2 share callback resultArr is nil")
                return
            }
            guard let result = resultArr.first else {
                WebBrowser.logger.info("OPWDownload DriveSDKLocalFileV2 share callback resultTuple is nil")
                return
            }
            guard result.1 == true else {
                let config = UDToastConfig(toastType: .error, text: BundleI18n.LarkOpenPlatform.OpenPlatform_Legacy_ChatViewForwardingFailed, operation: nil)
                UDToast.showToast(with: config, on: vc.view)
                WebBrowser.logger.info("OPWDownload DriveSDKLocalFileV2 share callback chatID: \(result.0), fail")
                return
            }
            WebBrowser.logger.info("OPWDownload DriveSDKLocalFileV2 share callback chatID: \(result.0), success")
        }
        Navigator.shared.present(body: forwardBody, from: vc)// user:global
        
        WebBrowser.logger.info("OPWDownload DriveSDKLocalFileV2 share success")
        OPMonitor("wb_preview_action_start")
            .addCategoryValue("download_url", self.from?.browserURL?.safeURLString)
            .addCategoryValue("action", "share")
            .addCategoryValue("filetype", info.type)
            .tracing(self.from?.webview.trace)
            .setPlatform([.tea, .slardar])
            .flush()
    }

    init(from: WebBrowser?) {
        self.from = from
    }
}

class OPWebDriveMoreCopyLinkProvider: DriveSDKCustomMoreActionProvider {
    private weak var from: WebBrowser?
    
    var actionId: String {
        return OPWebBrowserDriveAppID
    }
    var text: String {
        return BundleI18n.LarkOpenPlatform.CreationDriveSDK_common_copylink
    }
    lazy var handler: (UIViewController, DKAttachmentInfo) -> Void = { [weak self] vc, info in
        guard let self = self else {
            WebBrowser.logger.info("OPWDownload DriveSDKLocalFileV2 copy_link fail, self is nil")
            return
        }
        guard let url = self.from?.browserURL?.absoluteString else {
            WebBrowser.logger.info("OPWDownload DriveSDKLocalFileV2 copy_link fail, url is nil")
            return
        }
        let pasteboardConfig = PasteboardConfig(token:OPSensitivityEntryToken.OPWebDriveMoreCopyLinkProviderCopyLink.psdaToken)
        SCPasteboard.general(pasteboardConfig).string = url
        UDToast.showSuccess(with: BundleI18n.LarkOpenPlatform.Lark_Legacy_JssdkCopySuccess, on: vc.view)
        
        WebBrowser.logger.info("OPWDownload DriveSDKLocalFileV2 copy_link url: \(url.safeURLString)")
        OPMonitor("wb_preview_action_start")
            .addCategoryValue("download_url", self.from?.browserURL?.safeURLString)
            .addCategoryValue("action", "copy_link")
            .addCategoryValue("filetype", info.type)
            .tracing(self.from?.webview.trace)
            .setPlatform([.tea, .slardar])
            .flush()
    }
    
    init(from: WebBrowser?) {
        self.from = from
    }
}

// 定义更多面板配置
struct OPWebDriveMoreDependencyImpl: DriveSDKMoreDependency {
    private let visable: Bool
    private let action: ((UIViewController) -> Void)?
    private weak var from: WebBrowser?
    
    var moreMenuVisable: Observable<Bool> {
        return .just(visable)
    }
    var moreMenuEnable: Observable<Bool> {
        return .just(visable)
    }
    var actions: [DriveSDKMoreAction] {
        var moreActionArr: [DriveSDKMoreAction] = []
        if !LarkFeatureGating.shared.getFeatureBoolValue(for: "openplatform.downloadpreview.forward.disable") {// user:global
            moreActionArr.append(.customUserDefine(provider: OPWebDriveMoreForwardProvider(from: from)))
        }
        moreActionArr.append(.customUserDefine(provider: OPWebDriveMoreCopyLinkProvider(from: from)))
        moreActionArr.append(.customOpenWithOtherApp(customAction: action, callback: nil))
        return moreActionArr
    }
    
    init(visable: Bool, action: ((UIViewController) -> Void)?, from: WebBrowser?) {
        self.visable = visable
        self.action = action
        self.from = from
    }
}

// 协同动作
struct OPWebDriveActionDependencyImpl: DriveSDKActionDependency {
    private let closeSubject = PublishSubject<Void>()
    private let stopSubject = PublishSubject<Reason>()
    
    var closePreviewSignal: Observable<Void> {
        return closeSubject.asObserver()
    }
    var stopPreviewSignal: Observable<Reason> {
        return stopSubject.asObserver()
    }
}

struct OPWebDriveLocalDependencyImpl: DriveSDKDependency {
    private let more: OPWebDriveMoreDependencyImpl
    private let action: OPWebDriveActionDependencyImpl
    
    var moreDependency: DriveSDKMoreDependency {
        return more
    }
    var actionDependency: DriveSDKActionDependency {
        return action
    }
    
    init(moreVisable: Bool, moreAction: ((UIViewController) -> Void)?, from: WebBrowser?) {
        self.more = OPWebDriveMoreDependencyImpl(visable: moreVisable, action: moreAction, from: from)
        self.action = OPWebDriveActionDependencyImpl()
    }
}

final class WebDriveDownloadService: DriveDownloadServiceProtocol {
    private let resolver: Resolver
    
    init(resolver: Resolver) {
        self.resolver = resolver
    }
    
    func canOpen(fileName: String, fileSize: UInt64?, appID: String) -> Bool {
        guard let driveSDK = try? resolver.resolve(assert: DriveSDK.self) else {
            return false
        }
        return driveSDK.canOpen(fileName: fileName, fileSize: fileSize, appID: appID).isSupport
    }
    
    func showDrivePreview(_ filename: String, fileURL: URL, filetype: String?, fileId: String?, thirdPartyAppID: String?, appID: String, from: WebBrowser) {
        let file = DriveSDKLocalFileV2(fileName: filename, fileType: filetype, fileURL: fileURL, fileId: fileId ?? "", dependency: OPWebDriveLocalDependencyImpl(moreVisable: true, moreAction: nil, from: from))
        let config = DriveSDKNaviBarConfig(titleAlignment: .leading, fullScreenItemEnable: true)
        let body = DriveSDKLocalFileBody(files: [file], index: 0, appID: appID, thirdPartyAppID: thirdPartyAppID, naviBarConfig: config)
        Navigator.shared.push(body: body, from: from)// user:global
    }
}
