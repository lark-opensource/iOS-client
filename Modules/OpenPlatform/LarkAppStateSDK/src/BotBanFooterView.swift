//
//  BotBanFooterView.swift
//  LarkAppStateSDK
//
//  Created by 武嘉晟 on 2019/4/15.
//  Copyright © 2019 Bytedance.Inc. All rights reserved.
//

import EENavigator
import LKCommonsTracker
import LarkAppConfig
import LarkMessageCore
import LarkMessengerInterface
import LarkModel
import RichLabel
import SnapKit
import SwiftyJSON
import UIKit
import EEMicroAppSDK
import LarkEnv
import LarkOpenChat
import RxSwift
import LarkOPInterface

class BotBanFooterView: UIView {
    private let padding: CGFloat = 16
    private lazy var contentView: UIView = UIView()
    private lazy var msgLabel: LKLabel = {
        let label = LKLabel(frame: .zero)
        label.backgroundColor = UIColor.clear
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    private let footerModel: FooterModel
    let openApp: OpenApp

    init(openApp: OpenApp, bot: Chatter) {
        footerModel = FooterModel(adminID: openApp.botTips.adminID, bot: bot)
        self.openApp = openApp
        super.init(frame: .zero)
        backgroundColor = UIColor.ud.N00
        isUserInteractionEnabled = true
        snp.makeConstraints { (make) in
            make.top.equalTo(safeAreaLayoutGuide.snp.bottom)
                .offset(-55)
        }
        addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            make.height.equalTo(55)
            make.width.equalToSuperview()
            make.center.equalToSuperview()
        }
        contentView.addSubview(msgLabel)
        msgLabel.snp.makeConstraints { (make) in
            make.centerY.height.equalToSuperview()
            make.leading.equalToSuperview().offset(padding)
            make.trailing.equalToSuperview().offset(-padding)
        }

        switch openApp.state {
        case .userInvisible:
            updateContentForInvisibleState()
        case .tenantForbidden, .developerForbidden, .platformForbidden, .unknownState:
            updateContentForUnusableState()
        case .appDeleted:
            updateContentForDeleteState()
        case .offline:
            updateContentForOfflineState()
        case .usable:
            break
        case .appNeedPayUse:
            break
        @unknown default:
            break
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // 原始逻辑,在msgLabel的懒加载里设置msgLabel.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 2 * padding
    // 适配iPad，需要刷新msgLabel.preferredMaxLayoutWidth且解除对屏幕宽度的依赖；所以在layoutSubviews中设置
    override func layoutSubviews() {
        super.layoutSubviews()
        msgLabel.preferredMaxLayoutWidth = frame.width - 2 * padding
    }

    private func updateContentForInvisibleState() {
        /// 埋点 展示申请使用文案
        var message = ""
        if JSON(parseJSON: openApp.extraConfig)["can_apply_visibility"].bool ?? true {
            message = "\(BundleI18n.LarkAppStateSDK.AppDetail_Application_Mechanism_NoAccessWords)\(BundleI18n.LarkAppStateSDK.AppDetail_Application_Mechanism_NoAccessBtn)"
            Tracker.post(TeaEvent("app_states_unavailable_show"))
        } else {
            let tips = BundleI18n.LarkAppStateSDK.AppDetail_Application_Mechanism_NoAccessWords
            message = (tips.hasSuffix(",") || tips.hasSuffix("，")) ? String(tips.dropLast()) : tips
        }
        let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.ud.N500,
                                                         .font: UIFont.systemFont(ofSize: 12)]
        let attributedString = NSMutableAttributedString(string: message, attributes: attributes)
        let range = (attributedString.string as NSString).range(of: BundleI18n.LarkAppStateSDK.AppDetail_Application_Mechanism_NoAccessBtn)
        if range.location != NSNotFound {
            var link = LKTextLink(
                range: range,
                type: .link,
                attributes: [.foregroundColor: UIColor.ud.colorfulBlue],
                activeAttributes: [.foregroundColor: UIColor.ud.colorfulBlue]
            )
            link.linkTapBlock = { [weak self] (_, _) in
                self?.footerModel.openApplyPage()
            }
            msgLabel.addLKTextLink(link: link)
        }
        msgLabel.attributedText = attributedString
    }

    private func updateContentForUnusableState() {
        var userName = openApp.botTips.i18NAdminName
        let hasAtChar = userName.hasPrefix("@")
        userName = hasAtChar ? userName : "@\(userName)"
        let message = BundleI18n.LarkAppStateSDK.AppDetail_Application_Mechanism_AppDeactivatedWord(userName)
        let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.ud.N500,
                                                         .font: UIFont.systemFont(ofSize: 12)]
        let attributedString = NSMutableAttributedString(string: message, attributes: attributes)
        let range = (attributedString.string as NSString).range(of: userName)
        if range.location != NSNotFound {
            var link = LKTextLink(
                range: range,
                type: .link,
                attributes: [.foregroundColor: UIColor.ud.colorfulBlue],
                activeAttributes: [.foregroundColor: UIColor.ud.colorfulBlue])
            link.linkTapBlock = { [weak self] (_, _) in
                self?.footerModel.openAdminChatPage()
            }
            msgLabel.addLKTextLink(link: link)
        }
        msgLabel.attributedText = attributedString
    }

    // 应用下线
    private func updateContentForOfflineState() {
        var message = BundleI18n.LarkAppStateSDK.OpenPlatform_AppCenter_AppOfflineDesc
        if !EnvManager.env.isChinaMainlandGeo {
            message = BundleI18n.LarkAppStateSDK.OpenPlatform_AppCenter_AppOfflineLarkDesc
        }
        let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.ud.N500,
                                                         .font: UIFont.systemFont(ofSize: 12)]
        let attributedString = NSMutableAttributedString(string: message, attributes: attributes)
        msgLabel.attributedText = attributedString
    }

    // 应用被开发者删除
    private func updateContentForDeleteState() {
        var userName = openApp.botTips.i18NAdminName
        let hasAtChar = userName.hasPrefix("@")
        userName = hasAtChar ? userName : "@\(userName)"
        let message = BundleI18n.LarkAppStateSDK.OpenPlatform_AppCenter_AppDeletedDesc(userName)
        let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.ud.N500,
                                                         .font: UIFont.systemFont(ofSize: 12)]
        let attributedString = NSMutableAttributedString(string: message, attributes: attributes)
        let range = (attributedString.string as NSString).range(of: userName)
        if range.location != NSNotFound {
            var link = LKTextLink(
                range: range,
                type: .link,
                attributes: [.foregroundColor: UIColor.ud.colorfulBlue],
                activeAttributes: [.foregroundColor: UIColor.ud.colorfulBlue])
            link.linkTapBlock = { [weak self] (_, _) in
                self?.footerModel.openAdminChatPage()
            }
            msgLabel.addLKTextLink(link: link)
        }
        msgLabel.attributedText = attributedString
    }

}

private class FooterModel {
    private let adminID: String
    private let bot: Chatter

    init(adminID: String, bot: Chatter) {
        self.adminID = adminID
        self.bot = bot
    }

    fileprivate func openAdminChatPage() {
        if adminID.isEmpty { return }
        let body = ChatControllerByChatterIdBody(
            chatterId: adminID,
            isCrypto: false
        )
        if let fromVC = Navigator.shared.mainSceneWindow?.fromViewController {
            Navigator.shared.push(body: body, from: fromVC)
        } else {
            AppStateSDK.logger.error("AppState SDK openAdminChatPage can not push vc because no fromViewController")
        }
    }

    fileprivate func openApplyPage() {
        let body = ApplyForUseBody(botId: bot.id, appName: bot.name)
        if let fromVC = Navigator.shared.mainSceneWindow?.fromViewController {
            Navigator.shared.push(body: body, from: fromVC)
        } else {
            AppStateSDK.logger.error("AppState SDK openApplyPage can not push vc because no fromViewController")
        }
    }
}

public final class BotBanFooterModule: ChatFooterSubModule {
    public override class var name: String { "ApplyToJoinGroupFooterModule" }
    public override var type: ChatFooterType {
        return .botBan
    }
    private var botBanView: UIView?
    public override func contentView() -> UIView? {
        return botBanView
    }
    public override class func canInitialize(context: ChatFooterContext) -> Bool {
        return true
    }
    public override func canHandle(model: ChatFooterMetaModel) -> Bool {
        guard model.chat.isSingleBot,
            let chatter = model.chat.chatter,
            let openApp = chatter.openApp,
            openApp.state != .usable else {
                AppStateSDK.logger.info("AppStateSDK: bot can chat")
                return false
        }
        AppStateSDK.logger.info("AppStateSDK: bot can not chat")
        return true
    }

    public override func handler(model: ChatFooterMetaModel) -> [Module<ChatFooterContext, ChatFooterMetaModel>] {
        return [self]
    }

    public override func createViews(model: ChatFooterMetaModel) {
        super.createViews(model: model)
        self.display = true
        guard let chatter = model.chat.chatter, let openApp = chatter.openApp else {
            AppStateSDK.logger.info("chatter.openApp is nil! Unwrap Failed.")
            self.botBanView = nil
            return
        }
        self.botBanView = BotBanFooterView(
            openApp: openApp,
            bot: chatter
        )
    }
}
