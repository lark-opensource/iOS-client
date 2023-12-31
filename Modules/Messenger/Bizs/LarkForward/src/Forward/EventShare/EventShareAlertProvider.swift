//
//  EventShareAlertProvider.swift
//  LarkForward
//
//  Created by 姚启灏 on 2019/4/2.
//

import UIKit
import Foundation
import LarkModel
import LarkUIKit
import LarkCore
import EENavigator
import UniverseDesignToast
import RxSwift
import LarkAlertController
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface

struct EventShareAlertContent: ForwardAlertContent {
    let shouldShowExternalUser: Bool
    let shouldShowHint: Bool
    let shareMessage: String
    let subMessage: String
    let shareImage: UIImage
    let pickerCallBack: ([String], String?, Error?, Bool) -> Void

    public init(shareMessage: String,
                subMessage: String,
                shareImage: UIImage,
                shouldShowExternalUser: Bool,
                shouldShowHint: Bool,
                callBack: @escaping ([String], String?, Error?, Bool) -> Void) {
        self.pickerCallBack = callBack
        self.shouldShowHint = shouldShowHint
        self.shareMessage = shareMessage
        self.shareImage = shareImage
        self.shouldShowExternalUser = shouldShowExternalUser
        self.subMessage = subMessage
    }
}

// nolint: duplicated_code -- v2转发代码，v3转发全业务GA后可删除
final class EventShareAlertProvider: ForwardAlertProvider {

    // 关闭日历mention能力
    override var isSupportMention: Bool {
        return false
    }

    override class func canHandle(content: ForwardAlertContent) -> Bool {
        if content as? EventShareAlertContent != nil {
            return true
        }
        return false
    }

    override func isShowInputView(by items: [ForwardItem]) -> Bool {
        return true
    }

    override func getContentView(by items: [ForwardItem]) -> UIView? {
        guard let eventShareAlertContent = content as? EventShareAlertContent else { return nil }

        let wrapperView = UIView()
        wrapperView.backgroundColor = UIColor.ud.bgFloatOverlay
        wrapperView.layer.cornerRadius = 5
        let imgView = UIImageView()
        imgView.image = eventShareAlertContent.shareImage
        wrapperView.addSubview(imgView)
        imgView.snp.makeConstraints { (make) in
            make.width.height.equalTo(64)
            make.left.top.equalTo(10)
            make.bottom.equalToSuperview().offset(-10)
        }
        let nameLabel = UILabel()
        nameLabel.numberOfLines = 1
        nameLabel.lineBreakMode = .byTruncatingMiddle
        nameLabel.textColor = UIColor.ud.iconN1
        nameLabel.font = UIFont.systemFont(ofSize: 14)
        wrapperView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (make) in
            make.top.equalTo(imgView.snp.top).offset(4)
            make.left.equalTo(imgView.snp.right).offset(10)
            make.right.equalToSuperview().offset(-10)
        }
        nameLabel.text = eventShareAlertContent.shareMessage
        let subLabel = UILabel()
        wrapperView.addSubview(subLabel)
        subLabel.numberOfLines = 2
        subLabel.textColor = UIColor.ud.textPlaceholder
        subLabel.font = UIFont.systemFont(ofSize: 14)
        wrapperView.addSubview(subLabel)
        subLabel.snp.makeConstraints { (make) in
            make.bottom.equalTo(imgView.snp.bottom).offset(-4)
            make.left.equalTo(imgView.snp.right).offset(10)
            make.right.equalToSuperview().offset(-10)
        }
        subLabel.text = eventShareAlertContent.subMessage

        return wrapperView
    }

    override func getFilter() -> ForwardDataFilter? {
        guard let eventShareAlertContent = content as? EventShareAlertContent else { return nil }

        let filter: ForwardDataFilter? = { (item) in
            if item.isCrossTenant {
                if eventShareAlertContent.shouldShowExternalUser {
                    return true
                } else {
                    return false
                }
            }
            return true
        }
        return filter
    }

    override func getForwardItemsIncludeConfigsForEnabled() -> IncludeConfigs? {
        guard let eventShareAlertContent = content as? EventShareAlertContent else { return nil }
        let includeConfigs: IncludeConfigs = [
            //置灰话题，不传ForwardThreadEnableEntityConfig
            ForwardUserEnabledEntityConfig(tenant: eventShareAlertContent.shouldShowExternalUser ? .all : .inner),
            ForwardGroupChatEnabledEntityConfig(tenant: eventShareAlertContent.shouldShowExternalUser ? .all : .inner),
            ForwardBotEnabledEntityConfig()
        ]
        return includeConfigs
    }

    override func sureAction(items: [ForwardItem], input: String?, from: UIViewController) -> Observable<[String]> {
        guard let eventShareAlertContent = content as? EventShareAlertContent else { return .just([]) }
        Tracer.trackMergeForwardConfirm()
        let ids = self.itemsToIds(items)
        var containsExternalUser = false
        if items.first(where: { $0.isCrossTenant }) != nil {
            containsExternalUser = true
        }
        return self.checkAndCreateChats(chatIds: ids.chatIds, userIds: ids.userIds)
            .observeOn(MainScheduler.instance)
            .catchError({ [weak self] (error) -> Observable<[Chat]> in
                guard let self = self else { return .empty() }
                shareErrorHandler(userResolver: self.userResolver, hud: UDToast(), on: from, error: error)
                eventShareAlertContent.pickerCallBack([], nil, error, containsExternalUser)
                return .empty()
            })
            .flatMap({ (chats) -> Observable<[String]> in
                let chatIds = chats.map({ $0.id })
                let secondConfirmSubject = BehaviorSubject<[String]>(value: [])
                eventShareAlertContent.pickerCallBack(chatIds, input, nil, containsExternalUser)
                secondConfirmSubject.onNext(chatIds)
                secondConfirmSubject.onCompleted()
                return secondConfirmSubject
            })
    }

    override func sureAction(items: [ForwardItem], attributeInput: NSAttributedString?, from: UIViewController) -> Observable<[String]> {
        guard let eventShareAlertContent = content as? EventShareAlertContent else { return .just([]) }
        Tracer.trackMergeForwardConfirm()
        let ids = self.itemsToIds(items)
        var containsExternalUser = false
        if items.first(where: { $0.isCrossTenant }) != nil {
            containsExternalUser = true
        }
        return self.checkAndCreateChats(chatIds: ids.chatIds, userIds: ids.userIds)
            .observeOn(MainScheduler.instance)
            .catchError({ [weak self] (error) -> Observable<[Chat]> in
                guard let self = self else { return .empty() }
                shareErrorHandler(userResolver: self.userResolver, hud: UDToast(), on: from, error: error)
                eventShareAlertContent.pickerCallBack([], nil, error, containsExternalUser)
                return .empty()
            })
            .flatMap({ (chats) -> Observable<[String]> in
                let chatIds = chats.map({ $0.id })
                let secondConfirmSubject = BehaviorSubject<[String]>(value: [])
                eventShareAlertContent.pickerCallBack(chatIds, attributeInput?.string, nil, containsExternalUser)
                secondConfirmSubject.onNext(chatIds)
                secondConfirmSubject.onCompleted()
                return secondConfirmSubject
            })
    }
}
