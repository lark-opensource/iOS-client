//
//  ForwardTextAlertProvider.swift
//  LarkForward
//
//  Created by Miaoqi Wang on 2020/4/21.
//

import UIKit
import Foundation
import RxSwift
import UniverseDesignToast
import LarkMessengerInterface
import LarkSDKInterface
import LarkAlertController
import EENavigator
import LarkModel

struct ForwardTextAlertContent: ForwardAlertContent {
    let text: String
    let sentHandler: ForwardTextBody.SentHandler?
    var getForwardContentCallback: GetForwardContentCallback {
        let param = SendTextForwardParam(textContent: self.text)
        let forwardContent = ForwardContentParam.sendTextMessage(param: param)
        let callback = {
            let observable = Observable.just(forwardContent)
            return observable
        }
        return callback
    }
}

// nolint: duplicated_code -- v2转发代码，v3转发全业务GA后可删除
final class ForwardTextAlertProvider: ForwardAlertProvider {

    let disposeBag = DisposeBag()

    override var isSupportMention: Bool {
        return true
    }

    override class func canHandle(content: ForwardAlertContent) -> Bool {
        if content as? ForwardTextAlertContent != nil {
            return true
        }
        return false
    }

    override func getForwardItemsIncludeConfigsForEnabled() -> IncludeConfigs? {
        // text的转发接口暂不支持转发至帖子，需置灰
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

    override func getContentView(by items: [ForwardItem]) -> UIView? {
        guard let textContent = content as? ForwardTextAlertContent  else {
            return nil
        }
        let wrapperView = UIView()
        wrapperView.backgroundColor = UIColor.ud.bgFloatOverlay
        wrapperView.layer.cornerRadius = 5
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 4
        label.lineBreakMode = .byTruncatingTail
        label.textColor = UIColor.ud.iconN1
        wrapperView.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
        }
        label.text = textContent.text
        return wrapperView
    }

    override func sureAction(items: [ForwardItem], input: String?, from: UIViewController) -> Observable<[String]> {
        guard let messageContent = content as? ForwardTextAlertContent,
              let forwardService = try? self.resolver.resolve(assert: ForwardService.self),
              let window = from.view.window else { return .just([]) }
        let ids = self.itemsToIds(items)
        let hud = UDToast.showLoading(on: window)
        let secondConfirmSubject = BehaviorSubject<[String]>(value: [])
        forwardService
            .forward(content: messageContent.text, to: ids.chatIds, userIds: ids.userIds, extraText: input ?? "")
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (chatIds) in
                hud.remove()
                messageContent.sentHandler?(ids.userIds, ids.chatIds)
                secondConfirmSubject.onNext(chatIds)
                secondConfirmSubject.onCompleted()
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                forwardErrorHandler(userResolver: self.userResolver, hud: hud, on: from, error: error)
            }).disposed(by: disposeBag)
        return secondConfirmSubject
    }

    override func sureAction(items: [ForwardItem], attributeInput: NSAttributedString?, from: UIViewController) -> Observable<[String]> {
        guard let messageContent = content as? ForwardTextAlertContent,
              let forwardService = try? self.resolver.resolve(assert: ForwardService.self),
              let window = from.view.window else { return .just([]) }
        let ids = self.itemsToIds(items)
        let hud = UDToast.showLoading(on: window)
        let secondConfirmSubject = BehaviorSubject<[String]>(value: [])
        forwardService
            .forward(content: messageContent.text, to: ids.chatIds, userIds: ids.userIds, attributeExtraText: attributeInput ?? NSAttributedString(string: ""))
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (chatIds) in
                hud.remove()
                messageContent.sentHandler?(ids.userIds, ids.chatIds)
                secondConfirmSubject.onNext(chatIds)
                secondConfirmSubject.onCompleted()
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                forwardErrorHandler(userResolver: self.userResolver, hud: hud, on: from, error: error)
            }).disposed(by: disposeBag)
        return secondConfirmSubject
    }

    override func shareSureAction(items: [ForwardItem], attributeInput: NSAttributedString?, from: UIViewController) -> Observable<ForwardResult> {
        guard let messageContent = content as? ForwardTextAlertContent,
              let forwardService = try? self.resolver.resolve(assert: ForwardService.self),
              let window = from.view.window
        else {
            return .just(ForwardResult.success(ForwardParam(forwardItems: [])))
        }
        let ids = self.itemsToIds(items)
        let hud = UDToast.showLoading(on: window)
        let secondConfirmSubject = BehaviorSubject<ForwardResult>(value: ForwardResult.success(ForwardParam(forwardItems: [])))
        forwardService
            .forwardWithResults(content: messageContent.text, to: ids.chatIds, userIds: ids.userIds, attributeExtraText: attributeInput ?? NSAttributedString(string: ""))
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (chatIdsWithResults) in
                hud.remove()
                messageContent.sentHandler?(ids.userIds, ids.chatIds)
                var forwardItems: [ForwardItemParam] = []
                chatIdsWithResults.forEach {
                    var forwardItemParam = ForwardItemParam(isSuccess: $0.1, type: "", name: "", chatID: $0.0, isCrossTenant: false)
                    forwardItems.append(forwardItemParam)
                }
                var forwardResult = ForwardResult.success(ForwardParam(forwardItems: forwardItems))
                secondConfirmSubject.onNext(forwardResult)
                secondConfirmSubject.onCompleted()
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                forwardErrorHandler(userResolver: self.userResolver, hud: hud, on: from, error: error)
            }).disposed(by: disposeBag)
        return secondConfirmSubject
    }

    override func shareSureAction(items: [ForwardItem], input: String?, from: UIViewController) -> Observable<ForwardResult> {
        guard let messageContent = content as? ForwardTextAlertContent,
              let forwardService = try? self.resolver.resolve(assert: ForwardService.self),
              let window = from.view.window
        else {
            return .just(ForwardResult.success(ForwardParam(forwardItems: [])))
        }
        let ids = self.itemsToIds(items)
        let hud = UDToast.showLoading(on: window)
        let secondConfirmSubject = BehaviorSubject<ForwardResult>(value: ForwardResult.success(ForwardParam(forwardItems: [])))
        forwardService
            .forwardWithResults(content: messageContent.text, to: ids.chatIds, userIds: ids.userIds, extraText: input ?? "")
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (chatIdsWithResults) in
                hud.remove()
                messageContent.sentHandler?(ids.userIds, ids.chatIds)
                var forwardItems: [ForwardItemParam] = []
                chatIdsWithResults.forEach {
                    var forwardItemParam = ForwardItemParam(isSuccess: $0.1, type: "", name: "", chatID: $0.0, isCrossTenant: false)
                    forwardItems.append(forwardItemParam)
                }
                var forwardResult = ForwardResult.success(ForwardParam(forwardItems: forwardItems))
                secondConfirmSubject.onNext(forwardResult)
                secondConfirmSubject.onCompleted()
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                forwardErrorHandler(userResolver: self.userResolver, hud: hud, on: from, error: error)
            }).disposed(by: disposeBag)
        return secondConfirmSubject
    }
}
