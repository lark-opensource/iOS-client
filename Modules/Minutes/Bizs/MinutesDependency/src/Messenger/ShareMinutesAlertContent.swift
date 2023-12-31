//
//  ShareMinutesAlertContent.swift
//  MinutesMod
//
//  Created by Todd Cheng on 2021/2/3.
//

#if MessengerMod

import Foundation
import LarkModel
import LarkUIKit
import UniverseDesignToast
import EENavigator
import RxSwift
import LKCommonsLogging
import LarkAlertController
import LarkSDKInterface
import LarkMessengerInterface
import LarkForward

public struct ShareMinutesAlertContent: ForwardAlertContent {
    public let minutesURLString: String  // 飞书妙计链接

    public init(minutesURLString: String) {
        self.minutesURLString = minutesURLString
    }
}

public final class ShareMinutesAlertProvider: ForwardAlertProvider {
    static let logger = Logger.log(ShareMinutesAlertProvider.self, category: "Module.Minutes.Share")

    override public class func canHandle(content: ForwardAlertContent) -> Bool {
        if content as? ShareMinutesAlertContent != nil {
            return true
        }
        return false
    }

    /// 是否需要展示输入框
    override public func isShowInputView(by items: [ForwardItem]) -> Bool {
        return false
    }

    override public func getContentView(by items: [ForwardItem]) -> UIView? {
        guard let content = content as? ShareMinutesAlertContent else { return nil }

        let container = UIView()
        container.layer.cornerRadius = 5
        container.backgroundColor = UIColor.ud.bgFloatOverlay

        let label: UILabel = UILabel(frame: CGRect.zero)
        label.text = content.minutesURLString
        label.numberOfLines = 4
        label.textAlignment = .left
        label.lineBreakMode = .byTruncatingTail
        label.textColor = UIColor.ud.iconN1
        label.font = UIFont.systemFont(ofSize: 14)
        label.sizeToFit()

        container.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
        }

        return container
    }

    override public func sureAction(items: [ForwardItem], input: String?, from: UIViewController) -> Observable<[String]> {
        guard let messageContent = content as? ShareMinutesAlertContent,
              let window = from.view.window else { return .just([]) }
        _ = WindowTopMostFrom(vc: from)
        let hud = UDToast.showLoading(on: window)
        let ids = self.itemsToIds(items)

        if let service = try? resolver.resolve(assert: ForwardService.self) {
            return service.forward(content: messageContent.minutesURLString, to: ids.chatIds, userIds: ids.userIds, extraText: "")
                .observeOn(MainScheduler.instance)
                .do(onNext: { _ in
                    hud.remove()
                }, onError: { [weak self] (error) in
                    guard let self = self else { return }
                    LarkForward.shareErrorHandler(userResolver: self.userResolver, hud: hud, on: from, error: error)
                    ShareMinutesAlertProvider.logger.error("content share failed", error: error)
                })
        }
        return .empty()
    }
}

#endif
