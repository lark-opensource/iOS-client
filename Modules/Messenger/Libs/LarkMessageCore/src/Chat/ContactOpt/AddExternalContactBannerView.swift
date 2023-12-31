//
//  AddExternalContactBannerView.swift
//  LarkMessageCore
//
//  Created by JackZhao on 2020/9/21.
//

import UIKit
import Foundation
import EENavigator
import LarkSDKInterface
import LKCommonsLogging
import RxSwift
import RxRelay
import LarkModel
import Homeric
import LarkContainer
import LKCommonsTracker
import LarkMessengerInterface
import UniverseDesignToast
import UniverseDesignColor
import UniverseDesignNotice
import UniverseDesignIcon
import ByteWebImage
import LarkBizAvatar

struct AddExternalContactBannerModel {
    var description: String
    var buttonType: ExternalContactBannerButtonType
}

enum ExternalContactBannerButtonType {
    // 添加好友
    case add
    // 收到好友申请
    case recieve
}

// prd: https://bytedance.feishu.cn/docs/doccnFxZBdLZuFQmca5XuRCoVod?from=from_parent_docs&source_type=message#utEMOq
// zegma: https://www.figma.com/file/DLpWiOgKjUBKbLlUpEq4ub/%E5%8D%95%E5%90%91-%E2%86%92-%E5%8F%8C%E5%90%91?node-id=92%3A11345
// 添加外部联系人banner
final class AddExternalContactBannerView: UDNotice, UserResolverWrapper {
    private static let logger = Logger.log(AddExternalContactBannerView.self, category: "Module.IM.ContactBannerView")

    private let disposeBag = DisposeBag()

    private weak var targetVC: UIViewController?

    private let userId: String

    private let chatId: String

    private let displayName: String

    // 用户点击关闭按钮事件的behaviorRelay
    private weak var behaviorRelay: BehaviorRelay<UserRelationModel>?

    var removeFromSuperViewCallBack: (() -> Void)?

    public let userResolver: UserResolver

    private var model: AddExternalContactBannerModel

    @ScopedInjectedLazy var externalContactsAPI: ExternalContactsAPI?
    @ScopedInjectedLazy var chatApplicationAPI: ChatApplicationAPI?

    init(targetVC: UIViewController?,
         model: AddExternalContactBannerModel,
         userId: String,
         chatId: String,
         displayName: String,
         addContactSuccessPush: Observable<PushAddContactSuccessMessage>,
         behaviorRelay: BehaviorRelay<UserRelationModel>? = nil,
         userResolver: UserResolver) {
        self.targetVC = targetVC
        self.userId = userId
        self.chatId = chatId
        self.model = model
        self.displayName = displayName
        self.behaviorRelay = behaviorRelay
        self.userResolver = userResolver

        var config = UDNoticeUIConfig(type: .info, attributedText: NSAttributedString(string: ""))
        config.leadingIcon = UDIcon.getIconByKey(.infoColorful, size: CGSize(width: 16, height: 16))
        super.init(config: config)
        self.delegate = self
        self.configUI(model: model)
        // 监听添加好友成功
        addContactSuccessPush.observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (res) in
                Self.logger.info("addContactSuccessPush recieved")
                if res.userId == userId {
                    Self.logger.info("addContactSuccessPush removeFromSuperview")
                    self?.customRemoveSelfFromSuperview()
                }
            }, onError: { (error) in
                Self.logger.error("addContactSuccessPush error, error = \(error)")
            }).disposed(by: self.disposeBag)
    }

    deinit {
        print("AddExternalContactBannerView delloc")
    }

    private func configUI(model: AddExternalContactBannerModel) {
        var config = self.config
        config.attributedText = NSAttributedString(string: model.description)
        switch model.buttonType {
        case .add:
            // 配置申请外部联系人为好友的弹窗UI
            config.trailingButtonIcon = nil
            config.leadingButtonText = BundleI18n.LarkMessageCore.Lark_Legacy_Add
        case .recieve:
            config.trailingButtonIcon = UDIcon.getIconByKey(.closeOutlined, iconColor: UIColor.ud.iconN2, size: CGSize(width: 16, height: 16))
            config.leadingButtonText = BundleI18n.LarkMessageCore.Lark_IM_ThisUserSentYouAcontactRequest_Accept_Button
        }
        self.updateConfigAndRefreshUI(config)
    }

    // 更新UI/数据
    func updateFromViewModel(_ newModel: AddExternalContactBannerModel) {
        self.model = newModel
        self.configUI(model: newModel)
    }

    private func onClickButton() {
        switch model.buttonType {
        case .add:
            // 打点： IM顶部引导banner点击添加联系人
            Tracker.post(
                TeaEvent(Homeric.IM_CONTACTS_BANNER_ADD, params: ["type": "apply_initiator"])
            )
            // 点击添加跳转到好友申请页面
            var source = Source()
            source.sourceType = .chat
            source.sourceID = self.chatId
            let body = AddContactRelationBody(userId: self.userId,
                                              chatId: self.chatId,
                                              token: nil,
                                              source: source,
                                              addContactBlock: nil,
                                              userName: self.displayName,
                                              businessType: .bannerConfirm)
            if let targetVC = self.targetVC {
                self.navigator.push(body: body, from: targetVC)
            } else {
                assertionFailure("缺少 From VC")
            }
        case .recieve:
            // 打点： IM顶部引导banner点击添加联系人
            Tracker.post(
                TeaEvent(Homeric.IM_CONTACTS_BANNER_ADD, params: ["type": "accept_recipient"])
            )
            // 打点： 同意好友申请
            Tracker.post(TeaEvent(Homeric.AUTHORIZE_CARD_AGREE))
            let userId = self.userId
            // 防止多次点击
            leadingButton?.isEnabled = false
            // 点击同意好友申请按钮，发送请求
            self.chatApplicationAPI?
                .processChatApplication(userId: self.userId, result: .agreed)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (_) in
                    self?.leadingButton?.isEnabled = true
                    Self.logger.info("processChatApplication success")
                }, onError: { [weak self] (error) in
                    self?.leadingButton?.isEnabled = true
                    var alertMessage = BundleI18n.LarkMessageCore.Lark_Legacy_ErrorMessageTip
                    if let error = error.underlyingError as? APIError {
                        switch error.type {
                        case .targetExternalCoordinateCtl, .externalCoordinateCtl:
                            alertMessage = BundleI18n
                                .LarkMessageCore
                                .Lark_Contacts_CantCompleteOperationNoExternalCommunicationPermission
                        default:
                            break
                        }
                    }
                    if let window = self?.window {
                        UDToast.showFailure(with: alertMessage, on: window, error: error)
                    }
                    Self.logger.error("processChatApplication error, error = \(error), userId = \(userId)")
                }).disposed(by: self.disposeBag)
        }
    }

    @objc
    private func onExitButton() {
        // 打点： IM顶部引导banner点击添加联系人
        Tracker.post(
            TeaEvent(Homeric.IM_CONTACTS_BANNER_ADD, params: ["type": "close_recipient"])
        )
        let userId = self.userId
        self.externalContactsAPI?.ignoreContactApplyRequest(userId: self.userId)
            .subscribe(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                // 当用户点击关闭，显示引导的banner
                guard var value = self.behaviorRelay?.value else { return }
                value.isRecieveApply = false
                self.behaviorRelay?.accept(value)
                Self.logger.info("ignoreContactApplyRequest success")
            }, onError: { (error) in
                Self.logger.error("ignoreContactApplyRequest error, error = \(error), userId = \(userId)")
            }).disposed(by: self.disposeBag)
        self.customRemoveSelfFromSuperview()
    }

    private func customRemoveSelfFromSuperview() {
        self.removeFromSuperview()
        self.removeFromSuperViewCallBack?()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AddExternalContactBannerView: UDNoticeDelegate {
    func handleLeadingButtonEvent(_ button: UIButton) {
        self.onClickButton()
    }

    func handleTrailingButtonEvent(_ button: UIButton) {
        self.onExitButton()
    }

    func handleTextButtonEvent(URL: URL, characterRange: NSRange) {}
}
