//
//  SNSShareHelper.swift
//  LarkMicroApp
//
//  Created by yi on 2021/3/27.
//

import Foundation
import LarkSnsShare
import LarkContainer
import RxSwift
import LarkSDKInterface
import EENavigator
import LarkMessengerInterface
import LarkUIKit
import LarkModel
import LKCommonsLogging
import LarkReleaseConfig
import LarkMicroApp

// 分享的渠道类型
public enum SNSShareChannelType : String {
    case in_app // 分享到到会话
    case wx // 分享到wx
    case wx_timeline // 分享到wx朋友圈
    case system // 系统分享
}

// 分享的内容类型
public enum SNSShareContentType : String {
    case text
    case url
    case image
}

class SNSShareHelperImpl: SNSShareHelper {
    private let snsShareService: LarkShareService
    private let imageAPI: ImageAPI
    static let logger = Logger.log(SNSShareHelperImpl.self, category: "LarkMicroApp")
    private let disposeBag = DisposeBag()
    private let resolver: UserResolver
    
    init(resolver: UserResolver) throws {
        self.resolver = resolver
        snsShareService = try resolver.resolve(assert: LarkShareService.self)
        imageAPI = try resolver.resolve(assert: ImageAPI.self)
    }

    func snsShare(_ controller: UIViewController, appID: String, channel: String, contentType: String, traceId: String, title: String, url: String, desc: String, imageData: Data, successHandler: (() -> Void)?, failedHandler: ((Error?) -> Void)?) {
        Self.logger.info("SNSShareHelperImpl handle share ,channel:\(channel), contentType:\(contentType)")

        if channel == SNSShareChannelType.in_app.rawValue {
            if contentType == SNSShareContentType.url.rawValue { // 目前只支持url类型分享
                Self.logger.info("SNSShareHelperImpl handle share in app")
                shareChat(appId: appID, title: title, desc: desc, url: url, controller: controller, imageData: imageData, successHandler: successHandler, errorHandler: failedHandler)
            } else {
                let error = NSError(domain: "SNSShareHelper", code: -1, userInfo: [NSLocalizedDescriptionKey : "in_app not support"])
                Self.logger.error("SNSShareHelperImpl snsShare error \(error)")
                failedHandler?(error)
            }
            return
        }

        var content: ShareContentContext?

        var downgradePanelMeterial: DowngradeTipPanelMaterial?
        if let shareContentType = SNSShareContentType(rawValue: contentType) {
            switch shareContentType {
            case .text:
                let prepare = TextPrepare(content: desc)
                content = .text(prepare)
                downgradePanelMeterial = DowngradeTipPanelMaterial.text(panelTitle: nil, content: nil)
            case .image:
                guard let image = UIImage(data: imageData) else {
                    Self.logger.error("SNSShareHelperImpl image is nil when contentType is image")
                    let error = NSError(domain: "SNSShareHelper", code: -1, userInfo: [NSLocalizedDescriptionKey : "share image is nil"])
                    failedHandler?(error)
                    return
                }

                let prepare = ImagePrepare(title: title, image: image)
                content = .image(prepare)
                downgradePanelMeterial = DowngradeTipPanelMaterial.image(panelTitle: nil)

            case .url:
                let thumbnailImage = UIImage(data: imageData)
                let prepare = WebUrlPrepare(title: title,
                                            webpageURL: url,
                                            thumbnailImage: thumbnailImage,
                                            description: desc)
                content = .webUrl(prepare)
                downgradePanelMeterial = DowngradeTipPanelMaterial.text(panelTitle: nil, content: nil)
            }
        } else {
            let error = NSError(domain: "SNSShareHelper", code: -1, userInfo: [NSLocalizedDescriptionKey : "content type not support"])
            Self.logger.error("SNSShareHelperImpl snsShare error \(error)")
            failedHandler?(error)
            return
        }
        if channel == SNSShareChannelType.system.rawValue {
            Self.logger.info("SNSShareHelperImpl share inApp need not downgrade")
            downgradePanelMeterial = nil // 系统分享不传入降级物料，使用系统分享样式
        }
        
        if let content = content {
            let hasDowngrade = (downgradePanelMeterial != nil) ? true : false
            Self.logger.info("SNSShareHelperImpl invoke snsShareService,has downgrade:\(hasDowngrade)")
            snsShareService.present(by: traceId,
                            contentContext: content ,
                            baseViewController: controller,
                            downgradeTipPanelMaterial: downgradePanelMeterial,
                            customShareContextMapping: nil,
                            defaultItemTypes: [],
                            popoverMaterial: nil,
                            pasteConfig: .scPasteImmunity) { result, _ in
                switch result {
                case .success:
                    Self.logger.info("SNSShareHelperImpl LarkShareService success")
                    successHandler?()
                case .failure(let errorCode, let debugMsg):
                    let error = NSError(domain: "SNSShareHelper", code: errorCode.rawValue, userInfo: [NSLocalizedDescriptionKey : debugMsg])
                    Self.logger.error("SNSShareHelperImpl LarkShareService error \(error)")
                    failedHandler?(error)
                }
            }
        } else {
            let error = NSError(domain: "SNSShareHelper", code: -1, userInfo: [NSLocalizedDescriptionKey : "share content is nil"])
            Self.logger.error("SNSShareHelperImpl snsShare content error \(error)")
            failedHandler?(error)
        }
    }

    // 分享到会话
    private func shareChat(
        appId: String?,
        title: String,
        desc: String,
        url: String,
        controller: UIViewController,
        imageData: Data,
        successHandler: (() -> Void)?,
        errorHandler: ((Error?) -> Void)?
    ) {
        self.imageAPI.uploadSecureImage(data: imageData, type: .normal, imageCompressedSizeKb: 300)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (token) in
                Self.logger.info("SNSShareHelperImpl upload image token success")
                self.shareH5Card(appId: appId, title: title, desc: desc, url: url, iconToken: token, controller: controller, shareCallback: nil)
                successHandler?()
            }, onError: { (err) in
                self.shareH5Card(appId: appId, title: title, desc: desc, url: url, iconToken: nil, controller: controller, shareCallback: nil)
                Self.logger.error("SNSShareHelperImpl upload image token error \(err)")
                errorHandler?(err)
            })
            .disposed(by: disposeBag)
    }

    /// 新版的H5分享，不区分分享类型（H5应用/H5页面）
    private func shareH5Card(
        appId: String?,
        title: String,
        desc: String,
        url: String,
        iconToken: String?,
        controller: UIViewController,
        shareCallback: (([String: Any]?, Bool) -> Void)?
    ) {
        let shareType: ShareAppCardType = .h5(appID: appId, title: title, iconToken: iconToken, desc: desc, url: url)
        Self.logger.info("SNSShareHelperImpl push card share body")
        let body = AppCardShareBody(shareType: shareType, appUrl: url, callback: shareCallback)
        self.resolver.navigator.present(
            body: body,
            from: controller,
            prepare: { $0.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen }
        )
    }

}
