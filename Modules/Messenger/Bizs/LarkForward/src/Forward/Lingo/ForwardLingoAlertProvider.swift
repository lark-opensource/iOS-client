//
//  ForwardLingoAlertProvider.swift
//  LarkForward
//
//  Created by Patrick on 7/12/2022.
//

import UIKit
import Foundation
import RxSwift
import UniverseDesignToast
import LarkMessengerInterface
import LarkSDKInterface
import LarkAlertController
import EENavigator

struct ForwardLingoAlertContent: ForwardAlertContent {
    let content: String
    let title: String
    let sentCompletion: ForwardLingoBody.SentCompletion
    var getForwardContentCallback: GetForwardContentCallback {
        let param = SendTextForwardParam(textContent: self.content)
        let forwardContent = ForwardContentParam.sendTextMessage(param: param)
        let callback = {
            let observable = Observable.just(forwardContent)
            return observable
        }
        return callback
    }
}

// nolint: duplicated_code -- v2转发代码，v3转发全业务GA后可删除
final class ForwardLingoAlertProvider: ForwardAlertProvider {

    let disposeBag = DisposeBag()

    override var isSupportMention: Bool {
        return true
    }

    override class func canHandle(content: ForwardAlertContent) -> Bool {
        if content as? ForwardLingoAlertContent != nil {
            return true
        }
        return false
    }

    override func getContentView(by items: [ForwardItem]) -> UIView? {
        guard let textContent = content as? ForwardLingoAlertContent  else {
            return nil
        }
        let wrapperView = UIView()
        wrapperView.backgroundColor = UIColor.ud.bgFloatOverlay
        wrapperView.layer.cornerRadius = 5
        let titleLabel = UILabel()
        let contentLabel = UILabel()
        contentLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        contentLabel.numberOfLines = 4
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        contentLabel.lineBreakMode = .byTruncatingTail
        titleLabel.textColor = UIColor.ud.textTitle
        contentLabel.textColor = UIColor.ud.iconN1
        wrapperView.addSubview(titleLabel)
        wrapperView.addSubview(contentLabel)
        if textContent.title.isEmpty {
            contentLabel.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(10)
            }
            contentLabel.text = textContent.content
        } else {
            titleLabel.snp.makeConstraints { make in
                make.left.right.top.equalToSuperview().inset(10)
            }
            contentLabel.snp.makeConstraints { (make) in
                make.left.right.bottom.equalToSuperview().inset(10)
                make.top.equalTo(titleLabel.snp.bottom).offset(4)
            }
            titleLabel.text = textContent.title
            contentLabel.text = textContent.content
        }
        return wrapperView
    }

    override func sureAction(items: [ForwardItem], input: String?, from: UIViewController) -> Observable<[String]> {
        guard let messageContent = content as? ForwardLingoAlertContent,
              let forwardService = try? self.resolver.resolve(assert: ForwardService.self),
              let window = from.view.window else { return .just([]) }
        let ids = self.itemsToIds(items)
        let hud = UDToast.showLoading(on: window)
        let secondConfirmSubject = BehaviorSubject<[String]>(value: [])
        forwardService
            .forward(content: messageContent.content, to: ids.chatIds, userIds: ids.userIds, extraText: input ?? "")
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (chatIds) in
                hud.remove()
                messageContent.sentCompletion(ids.userIds, ids.chatIds)
                secondConfirmSubject.onNext(chatIds)
                secondConfirmSubject.onCompleted()
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                forwardErrorHandler(userResolver: self.userResolver, hud: hud, on: from, error: error)
            }).disposed(by: disposeBag)
        return secondConfirmSubject
    }

    override func sureAction(items: [ForwardItem], attributeInput: NSAttributedString?, from: UIViewController) -> Observable<[String]> {
        guard let messageContent = content as? ForwardLingoAlertContent,
              let forwardService = try? self.resolver.resolve(assert: ForwardService.self),
              let window = from.view.window else { return .just([]) }
        let ids = self.itemsToIds(items)
        let hud = UDToast.showLoading(on: window)
        let secondConfirmSubject = BehaviorSubject<[String]>(value: [])
        forwardService
            .forward(content: messageContent.content, to: ids.chatIds, userIds: ids.userIds, attributeExtraText: attributeInput ?? NSAttributedString(string: ""))
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (chatIds) in
                hud.remove()
                messageContent.sentCompletion(ids.userIds, ids.chatIds)
                secondConfirmSubject.onNext(chatIds)
                secondConfirmSubject.onCompleted()
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                forwardErrorHandler(userResolver: self.userResolver, hud: hud, on: from, error: error)
            }).disposed(by: disposeBag)
        return secondConfirmSubject
    }

    override func shareSureAction(items: [ForwardItem], attributeInput: NSAttributedString?, from: UIViewController) -> Observable<ForwardResult> {
        guard let messageContent = content as? ForwardLingoAlertContent,
              let forwardService = try? self.resolver.resolve(assert: ForwardService.self),
              let window = from.view.window else {
            return .just(ForwardResult.success(ForwardParam(forwardItems: [])))
        }
        let ids = self.itemsToIds(items)
        let hud = UDToast.showLoading(on: window)
        let secondConfirmSubject = BehaviorSubject<ForwardResult>(value: ForwardResult.success(ForwardParam(forwardItems: [])))
        forwardService
            .forwardWithResults(content: messageContent.content, to: ids.chatIds, userIds: ids.userIds, attributeExtraText: attributeInput ?? NSAttributedString(string: ""))
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (chatIdsWithResults) in
                hud.remove()
                messageContent.sentCompletion(ids.userIds, ids.chatIds)
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
        guard let messageContent = content as? ForwardLingoAlertContent,
              let forwardService = try? self.resolver.resolve(assert: ForwardService.self),
              let window = from.view.window else {
            return .just(ForwardResult.success(ForwardParam(forwardItems: [])))
        }
        let ids = self.itemsToIds(items)
        let hud = UDToast.showLoading(on: window)
        let secondConfirmSubject = BehaviorSubject<ForwardResult>(value: ForwardResult.success(ForwardParam(forwardItems: [])))
        forwardService
            .forwardWithResults(content: messageContent.content, to: ids.chatIds, userIds: ids.userIds, extraText: input ?? "")
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (chatIdsWithResults) in
                hud.remove()
                messageContent.sentCompletion(ids.userIds, ids.chatIds)
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
