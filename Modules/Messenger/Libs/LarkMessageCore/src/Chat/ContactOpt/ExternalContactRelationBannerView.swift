//
//  ExternalContactRelationBannerView.swift
//  LarkChat
//
//  Created by bytedance on 2020/7/20.
//

import UIKit
import Foundation
import LKCommonsLogging
import RxSwift
import LarkAlertController
import EENavigator
import LarkSDKInterface
import LarkMessengerInterface
import LarkModel
import RxCocoa
import LarkContainer
import Homeric
import LKCommonsTracker
import LarkActionSheet
import UniverseDesignToast
import UniverseDesignActionPanel
import UniverseDesignColor

// prd: https://bytedance.feishu.cn/docs/doccnFxZBdLZuFQmca5XuRCoVod?from=from_parent_docs&source_type=message#utEMOq
// zegma: https://www.figma.com/file/DLpWiOgKjUBKbLlUpEq4ub/%E5%8D%95%E5%90%91-%E2%86%92-%E5%8F%8C%E5%90%91?node-id=92%3A11345
// 外部联系人关系banner： 屏蔽联系人 & 添加联系人
final class ExternalContactRelationBannerView: UIView {
    private static let logger = Logger.log(ExternalContactRelationBannerView.self, category: "Module.IM.ContactBannerView")

    private let disposeBag = DisposeBag()

    private weak var targetVC: UIViewController?
    var removeFromSuperViewCallBack: (() -> Void)?
    // 屏蔽item
    private var leftItem: ContactBannerItem = {
        let item = ContactBannerItem()
        item.configUI(icon: Resources.ban_contact,
                      title: BundleI18n.LarkMessageCore.Lark_NewContacts_BlockUserInChat)
        return item
    }()

    // 屏蔽 按钮
    private var leftButton: UIButton = {
        let button = UIButton()
        return button
    }()

    // 分割线
    private var verticalLine: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        return line
    }()

    // 添加联系人 item
    private var rightItem: ContactBannerItem = {
        let item = ContactBannerItem()
        item.configUI(icon: Resources.icon_member,
                      title: BundleI18n.LarkMessageCore.Lark_NewContacts_AddContactFromChat)
        return item
    }()

    // 添加联系人 按钮
    private var rightButton: UIButton = {
        let button = UIButton()
        return button
    }()

    private let userId: String
    private let chatId: String
    private var externalContactsAPI: ExternalContactsAPI?
    // 添加联系人页面要显示的默认备注
    private let displayName: String
    private let nav: Navigatable

    init(targetVC: UIViewController?,
         userId: String,
         chatId: String,
         displayName: String,
         addContactSuccessPush: Observable<PushAddContactSuccessMessage>,
         externalContactsAPI: ExternalContactsAPI?,
         nav: Navigatable) {
        self.targetVC = targetVC
        self.userId = userId
        self.displayName = displayName
        self.chatId = chatId
        self.externalContactsAPI = externalContactsAPI
        self.nav = nav
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.functionInfoFillSolid02
        addSubview(leftItem)
        addSubview(verticalLine)
        addSubview(rightItem)
        addSubview(leftButton)
        addSubview(rightButton)

        self.snp.makeConstraints { (make) in
            make.height.equalTo(44)
        }

        leftItem.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview().multipliedBy(0.5)
            make.centerY.equalToSuperview()
        }

        verticalLine.snp.makeConstraints { (make) in
            make.left.equalTo(leftItem.snp.right)
            make.right.equalTo(rightItem.snp.left)
            make.centerX.centerY.equalToSuperview()
            make.width.equalTo(1)
            make.height.equalTo(16)
        }

        rightItem.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview().multipliedBy(1.5)
            make.centerY.equalToSuperview()
        }

        leftButton.snp.makeConstraints { (make) in
            make.top.left.right.bottom.equalTo(leftItem)
        }

        rightButton.snp.makeConstraints { (make) in
            make.top.left.right.bottom.equalTo(rightItem)
        }

        leftButton.addTarget(self, action: #selector(onTapLeftButton), for: .touchUpInside)
        rightButton.addTarget(self, action: #selector(onTapRightButton), for: .touchUpInside)

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
        print("ExternalContactRelationBannerView delloc")
    }

    @objc
    private func onTapLeftButton() {
        Tracker.post(
            TeaEvent(Homeric.IM_CONTACTS_BANNER_BLOCK)
        )
        let actionSheet = UDActionSheet(
            config: UDActionSheetUIConfig(
                isShowTitle: true,
                popSource: UDActionSheetSource(
                    sourceView: leftItem,
                    sourceRect: CGRect(x: leftItem.bounds.width / 2, y: leftItem.bounds.height, width: 0, height: 0),
                    arrowDirection: .up)))
        actionSheet.setTitle(BundleI18n.LarkMessageCore.Lark_NewContacts_BlockDesc)
        // 屏蔽对方的item
        actionSheet.addDefaultItem(text: BundleI18n.LarkMessageCore.Lark_NewContacts_BlockUser) { [weak self] in
            guard let `self` = self else { return }
            LarkMessageCoreTracker.trackTapBlock(userID: self.userId)
            self.externalContactsAPI?
                .setupUserBlockUserRequest(
                    blockUserId: self.userId,
                    blockStatus: true)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    if let window = self?.window {
                        UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_NewContacts_BlockedLabel, on: window)
                    }
                    self?.customRemoveSelfFromSuperview()
                    Self.logger.info("setupUserBlockUserRequest block success")
                }, onError: { [weak self] (error) in
                    guard let window = self?.window else { return }
                    UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_Setting_PrivacySetupFailed, on: window)
                    Self.logger.error("setupUserBlockUserRequest block failed", error: error)
                }).disposed(by: self.disposeBag)
        }
        actionSheet.setCancelItem(text: BundleI18n.LarkMessageCore.Lark_Legacy_Cancel)
        if let targetVC = self.targetVC {
            self.nav.present(actionSheet, from: targetVC)
        } else {
            assertionFailure("缺少 From VC")
        }
    }

    @objc
    private func onTapRightButton() {
        // 打点： IM顶部引导banner点击添加联系人
        Tracker.post(
            TeaEvent(Homeric.IM_CONTACTS_BANNER_ADD, params: ["type": "apply_recipient"])
        )
        var source = Source()
        source.sourceType = .chat
        source.sourceID = self.chatId
        //TODO:赵冬 待完善businessType
        let body = AddContactRelationBody(userId: self.userId,
                                          chatId: self.chatId,
                                          token: nil,
                                          source: source,
                                          addContactBlock: nil,
                                          userName: self.displayName,
                                          businessType: .bannerConfirm)
        if let targetVC = self.targetVC {
            self.nav.push(body: body, from: targetVC)
        } else {
            assertionFailure("缺少 From VC")
        }
    }

    private func customRemoveSelfFromSuperview() {
        self.removeFromSuperview()
        self.removeFromSuperViewCallBack?()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class ContactBannerItem: UIView {

   private var container: UIView = {
       let view = UIView()
       return view
   }()

   private var icon: UIImageView = {
       let icon = UIImageView()

       return icon
   }()

   private var label: UILabel = {
       let label = UILabel()
       label.numberOfLines = 1
       label.font = UIFont.systemFont(ofSize: 14)
       label.textColor = UIColor.ud.primaryContentDefault

       return label
   }()

    fileprivate init() {
       super.init(frame: .zero)
       addSubview(container)
       container.addSubview(icon)
       container.addSubview(label)

       container.snp.makeConstraints { (make) in
           make.centerX.centerY.equalToSuperview()
       }

       icon.snp.makeConstraints { (make) in
           make.top.left.bottom.equalToSuperview()
           make.width.height.equalTo(16)
       }

       label.snp.makeConstraints { (make) in
           make.top.right.bottom.equalToSuperview()
           make.left.equalTo(icon.snp.right).offset(5)
       }
   }

    fileprivate func configUI(icon: UIImage, title: String) {
       self.icon.image = icon
       self.label.text = title
   }

   required init?(coder: NSCoder) {
       fatalError("init(coder:) has not been implemented")
   }
}
