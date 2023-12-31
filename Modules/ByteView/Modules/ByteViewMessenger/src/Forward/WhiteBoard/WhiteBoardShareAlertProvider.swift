//
//  WhiteBoardShareAlertProvider.swift
//  ByteViewMod
//
//  Created by helijian on 2022/4/27.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import EENavigator
import UniverseDesignToast
import ByteViewCommon
import RxSwift
import LarkMessengerInterface
import LarkSDKInterface
import UIKit

public struct WhiteBoardShareContent: ForwardAlertContent {
    public let imagePaths: [String]
    public let nav: UINavigationController?
    public init(imagePaths: [String], nav: UINavigationController? = nil) {
        self.imagePaths = imagePaths
        self.nav = nav
    }
    public var getForwardContentCallback: GetForwardContentCallback {
        let param = SendMultiImageForwardParam(imagePaths: self.imagePaths.map{ URL.init(fileURLWithPath: $0) })
        let forwardContent = ForwardContentParam.sendMultipleImageMessage(param: param)
        let callback = {
            let observable = Observable.just(forwardContent)
            return observable
        }
        return callback
    }
}

public final class WhiteBoardShareAlertProvider: ForwardAlertProvider {
    static let logger = Logger.getLogger("WhiteBoardShare", prefix: "ByteViewMessenger")
    public override class func canHandle(content: ForwardAlertContent) -> Bool {
        if content as? WhiteBoardShareContent != nil {
            return true
        }
        return false
    }

    public override var isSupportMultiSelectMode: Bool {
        return false
    }

    public override var shouldCreateGroup: Bool {
        return false
    }

    public override func sureAction(items: [LarkMessengerInterface.ForwardItem], input: String?, from: UIViewController) -> Observable<[String]> {
        guard let whiteBoardShareContent = content as? WhiteBoardShareContent,
              let forwardService = try? resolver.resolve(assert: ForwardService.self) else { return .just([]) }
        let ids = self.itemsToIds(items)
        let urls = whiteBoardShareContent.imagePaths.map{ URL.init(fileURLWithPath: $0) }
        return forwardService.share(imageUrls: urls, extraText: input, to: ids.chatIds, userIds: ids.userIds)
            .observeOn(MainScheduler.instance)
            .do(onNext: { [weak self] _ in
                Self.logger.info("send images success")
                _ = try? self?.userResolver.resolve(assert: ByteViewMessengerDependency.self).showRvcImageSentToast()
                if let nav = whiteBoardShareContent.nav {
                    nav.popViewController(animated: false)
                }
            }, onError: { (error) in
                Self.logger.error("send images fail", error: error)
                if let nav = whiteBoardShareContent.nav {
                    nav.popViewController(animated: false)
                }
            })
    }
}
