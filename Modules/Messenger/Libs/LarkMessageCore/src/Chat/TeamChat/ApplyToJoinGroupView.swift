//
//  ApplyToJoinGroupView.swift
//  LarkChat
//
//  Created by 夏汝震 on 2022/3/14.
//

import UIKit
import Foundation
import LarkModel
import LarkMessengerInterface
import EENavigator
import LarkUIKit
import LarkOpenChat
import LarkOpenIM
import RxSwift
import RxCocoa

public final class ApplyToJoinGroupView: UIView {
    private static let resignLabelHeight: CGFloat = 55
    private let chat: LarkModel.Chat
    private weak var targetVC: UIViewController?
    private var teamID: Int64?
    private let nav: Navigatable

    public init(chat: Chat, targetVC: UIViewController?, teamID: Int64?, nav: Navigatable) {
        self.chat = chat
        self.targetVC = targetVC
        self.teamID = teamID
        self.nav = nav
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.N00
        self.snp.makeConstraints { (make) in
            make.top.equalTo(self.safeAreaLayoutGuide.snp.bottom)
                .offset(-ApplyToJoinGroupView.resignLabelHeight)
        }
        let line = UIView()
        self.addSubview(line)
        line.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(1)
        }
        line.backgroundColor = UIColor.ud.lineDividerDefault

        let button = UIButton(type: .custom)
        button.setTitle(BundleI18n.LarkMessageCore.Project_T_JoinThisGroup_Button, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        self.addSubview(button)
        button.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(ApplyToJoinGroupView.resignLabelHeight)
        }
        button.addTarget(self, action: #selector(applyJoinGroup), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func applyJoinGroup() {
        guard let targetVC = self.targetVC, let teamID = self.teamID else { return }
        // 加人入群
        let chatId = chat.id
        let teamId = teamID
        let body = JoinGroupApplyBody(
            chatId: chatId,
            way: .viaTeamOpenChat(teamId: teamId))
        self.nav.open(body: body, from: targetVC)
        LarkMessageCoreTracker.joinOpenGroupClick(chat: chat)
    }
}

public final class ApplyToJoinGroupFooterModule: ChatFooterSubModule {
    public override class var name: String { "ApplyToJoinGroupFooterModule" }
    public override var type: ChatFooterType {
        return .applyToJoinGroup
    }
    public static let teamID = "teamID"
    private var disposeBag = DisposeBag()
    private var applyView: UIView?
    public override func contentView() -> UIView? {
        return applyView
    }
    public override class func canInitialize(context: ChatFooterContext) -> Bool {
        return true
    }
    public override func canHandle(model: ChatFooterMetaModel) -> Bool {
        return model.chat.isTeamVisitorMode
    }
    public override func handler(model: ChatFooterMetaModel) -> [Module<ChatFooterContext, ChatFooterMetaModel>] {
        return [self]
    }
    public override func createViews(model: ChatFooterMetaModel) {
        super.createViews(model: model)
        self.display = true
        if let targetVC = try? self.context.resolver.resolve(assert: ChatOpenService.self).chatVC() {
            self.applyView = ApplyToJoinGroupView(chat: model.chat,
                                                  targetVC: targetVC,
                                                  teamID: self.context.store.getValue(for: ApplyToJoinGroupFooterModule.teamID),
                                                  nav: self.context.nav)
        }
    }
}
