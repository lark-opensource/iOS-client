//
//  ShareImageAlertProvider.swift
//  LarkForward
//
//  Created by 姚启灏 on 2019/4/2.
//

import UIKit
import Foundation
import LarkModel
import LarkUIKit
import UniverseDesignToast
import RxSwift
import LarkSDKInterface
import LarkMessengerInterface
import LarkAlertController
import EENavigator
import LarkSetting
import LKCommonsLogging

struct ShareImageAlertContent: ForwardAlertContent {
    let image: UIImage
    let type: ShareImageType
    let needFilterExternal: Bool
    var getForwardContentCallback: GetForwardContentCallback {
        let param = SendImageForwardParam(sourceImage: self.image)
        let forwardContent = ForwardContentParam.sendImageMessage(param: param)
        let callback = {
            let observable = Observable.just(forwardContent)
            return observable
        }
        return callback
    }

    init(image: UIImage, type: ShareImageType, needFilterExternal: Bool = true) {
        self.image = image
        self.type = type
        self.needFilterExternal = needFilterExternal
    }
}

// nolint: duplicated_code -- v2转发代码，v3转发全业务GA后可删除
final class ShareImageAlertProvider: ForwardAlertProvider {
    /// 转发内容一级预览FG开关
    private lazy var forwardDialogContentFG: Bool = {
        return userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "core.forward.dialog_content_new"))
    }()
    private static let logger = Logger.log(MessageForwardAlertProvider.self, category: "ShareImageAlertProvider")
    let disposeBag = DisposeBag()
    override class func canHandle(content: ForwardAlertContent) -> Bool {
        if content as? ShareImageAlertContent != nil {
            return true
        }
        return false
    }

    override var isSupportMention: Bool {
        return true
    }

    override func getForwardItemsIncludeConfigsForEnabled() -> IncludeConfigs? {
        //业务需要置灰帖子
        return [ForwardUserEnabledEntityConfig(),
                ForwardGroupChatEnabledEntityConfig(),
                ForwardBotEnabledEntityConfig(),
                ForwardMyAiEnabledEntityConfig()]
    }

    override func getForwardItemsIncludeConfigs() -> IncludeConfigs? {
        return [ForwardUserEntityConfig(),
                ForwardGroupChatEntityConfig(),
                ForwardBotEntityConfig(),
                ForwardThreadEntityConfig(),
                ForwardMyAiEntityConfig()]
    }

    override func getFilter() -> ForwardDataFilter? {
        guard let messageContent = content as? ShareImageAlertContent else { return { return !$0.isCrossTenant } }
        if messageContent.needFilterExternal {
            return { return !$0.isCrossTenant }
        }

        return nil
    }

    override func getContentView(by items: [ForwardItem]) -> UIView? {
        guard let imageContent = self.content as? ShareImageAlertContent else { return nil }
        if !forwardDialogContentFG {
            Self.logger.info("getContentView old \(imageContent.type) \(forwardDialogContentFG)")
            if imageContent.type == .forward {
                return ShareImageConfirmFooter(image: imageContent.image)
            }
            return nil
        }

        var view: UIView?
        Self.logger.info("getContentView new \(imageContent.type) \(forwardDialogContentFG)")
        switch imageContent.type {
        case .forward:
            /// forward类型需要添加footer
            view = ShareImageConfirmFooter(image: imageContent.image)
        case .forwardPreview:
            view = ShareNewImageConfirmFooter(image: imageContent.image)
        case .normal:
            //无footer
            return nil
        @unknown default:
            assert(false, "new value")
            return nil
        }
        return view
    }

    override func sureAction(items: [ForwardItem], input: String?, from: UIViewController) -> Observable<[String]> {
        guard let imageContent = content as? ShareImageAlertContent,
              let forwardService = try? self.userResolver.resolve(assert: ForwardService.self),
              let window = from.view.window else { return .just([]) }
        let ids = self.itemsToIds(items)
        let hud = UDToast.showLoading(on: window)
        return forwardService
            .share(image: imageContent.image, message: input, to: ids.chatIds, userIds: ids.userIds)
            .observeOn(MainScheduler.instance)
            .do(onNext: { (_) in
                hud.remove()
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                shareErrorHandler(userResolver: self.userResolver, hud: hud, on: from, error: error)
            })
    }

    override func sureAction(items: [ForwardItem], attributeInput: NSAttributedString?, from: UIViewController) -> Observable<[String]> {
        guard let imageContent = content as? ShareImageAlertContent,
              let forwardService = try? self.userResolver.resolve(assert: ForwardService.self),
              let window = from.view.window else { return .just([]) }
        let ids = self.itemsToIds(items)
        let hud = UDToast.showLoading(on: window)
        return forwardService
            .share(image: imageContent.image, attributeMessage: attributeInput, to: ids.chatIds, userIds: ids.userIds)
            .observeOn(MainScheduler.instance)
            .do(onNext: { (_) in
                hud.remove()
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                shareErrorHandler(userResolver: self.userResolver, hud: hud, on: from, error: error)
            })
    }

    override func shareSureAction(items: [ForwardItem], attributeInput: NSAttributedString?, from: UIViewController) -> Observable<ForwardResult> {
        guard let imageContent = content as? ShareImageAlertContent,
              let forwardService = try? self.userResolver.resolve(assert: ForwardService.self),
              let window = from.view.window else {
            return .just(ForwardResult.success(ForwardParam(forwardItems: [])))
        }
        let ids = self.itemsToIds(items)
        let hud = UDToast.showLoading(on: window)
        return forwardService
            .shareWithResults(image: imageContent.image, attributeMessage: attributeInput, to: ids.chatIds, userIds: ids.userIds)
            .observeOn(MainScheduler.instance)
            .do(onNext: { (_) in
                hud.remove()
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                shareErrorHandler(userResolver: self.userResolver, hud: hud, on: from, error: error)
            })
            .map { res in
                var forwardItems: [ForwardItemParam] = []
                res.forEach {
                    var forwardItemParam = ForwardItemParam(isSuccess: $0.1, type: "", name: "", chatID: $0.0, isCrossTenant: false)
                    forwardItems.append(forwardItemParam)
                }
                var forwardResult = ForwardResult.success(ForwardParam(forwardItems: forwardItems))
                return forwardResult
            }
    }

    override func shareSureAction(items: [ForwardItem], input: String?, from: UIViewController) -> Observable<ForwardResult> {
        guard let imageContent = content as? ShareImageAlertContent,
              let forwardService = try? self.userResolver.resolve(assert: ForwardService.self),
              let window = from.view.window else {
            return .just(ForwardResult.success(ForwardParam(forwardItems: [])))
        }
        let ids = self.itemsToIds(items)
        let hud = UDToast.showLoading(on: window)
        return forwardService
            .shareWithResults(image: imageContent.image, message: input, to: ids.chatIds, userIds: ids.userIds)
            .observeOn(MainScheduler.instance)
            .do(onNext: { (_) in
                hud.remove()
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                shareErrorHandler(userResolver: self.userResolver, hud: hud, on: from, error: error)
            })
            .map { res in
                var forwardItems: [ForwardItemParam] = []
                res.forEach {
                    var forwardItemParam = ForwardItemParam(isSuccess: $0.1, type: "", name: "", chatID: $0.0, isCrossTenant: false)
                    forwardItems.append(forwardItemParam)
                }
                var forwardResult = ForwardResult.success(ForwardParam(forwardItems: forwardItems))
                return forwardResult
            }
    }
}
