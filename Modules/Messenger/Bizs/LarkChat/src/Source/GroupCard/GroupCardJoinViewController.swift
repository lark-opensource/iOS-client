//
//  GroupCardJoinViewController.swift
//  Lark
//
//  Created by Yuguo on 2017/10/26.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit
import RxSwift
import RxRelay
import LarkModel
import LarkCore
import LarkFoundation
import EENavigator
import LarkButton
import LarkMessengerInterface
import LarkContainer
import UniverseDesignIcon

protocol GroupCardJoinRouter: AnyObject, UserResolverWrapper {
    var rootVCBlock: (() -> UIViewController?)? { get set }

    func pushPersonCard(chatter: Chatter, chatId: String)
    func pushChatController(chatId: String)
    func presentPreviewImageController(asset: LKDisplayAsset, shouldDetectFile: Bool)
}

final class GroupCardJoinViewController: BaseUIViewController, InformationDetailsProtocol, UITableViewDelegate, UITableViewDataSource, UserResolverWrapper {
    let userResolver: UserResolver
    var backgroundImageView: UIImageView?
    var containerBackgoundView: UIView?
    var tableView: UITableView?
    // 底部的[加入群组]按钮上部增加一个描述
    private lazy var bottomLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14.0)
        label.textAlignment = .center
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()
    var mutilBy: CGFloat = 0.3
    var thresholdOffset: CGFloat {
        let offset: CGFloat = 180
        // iPad 最大偏移不使用高度计算
        if Display.pad {
            return min(offset, 375)
        }
        return offset
    }

    private let viewModel: GroupCardJoinViewModelProtocol
    lazy var groupAvatar: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    private lazy var joinGroupButton: LarkButton.TypeButton = {
        let joinGroupButton = LarkButton.TypeButton(style: .textA)
        joinGroupButton.lu.addTopBorder()
        joinGroupButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        joinGroupButton.setTitle(viewModel.joinButtonTitleRelay.value, for: .normal)
        joinGroupButton.setTitle(BundleI18n.LarkChat.Lark_Legacy_GroupShareExpired, for: .disabled)
        joinGroupButton.isEnabled = viewModel.joinButtonEnable
        joinGroupButton.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        joinGroupButton.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .highlighted)
        joinGroupButton.setTitleColor(UIColor.ud.udtokenBtnPriTextDisabled, for: .disabled)
        joinGroupButton.setBackgroundImage(UIImage.lu.fromColor(UIColor.ud.primaryContentDefault), for: .normal)
        joinGroupButton.setBackgroundImage(UIImage.lu.fromColor(UIColor.ud.primaryContentDefault), for: .highlighted)
        joinGroupButton.setBackgroundImage(UIImage.lu.fromColor(UIColor.ud.fillDisabled), for: .disabled)

        return joinGroupButton
    }()

    fileprivate let disposeBag = DisposeBag()

    init(userResolver: UserResolver, viewModel: GroupCardJoinViewModelProtocol) {
        self.userResolver = userResolver
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)

        GroupCardTracker.sdkLocalStart()
        self.viewModel.reloadData.drive(onNext: { [weak self] _ in
            self?.tableView?.reloadData()
            GroupCardTracker.sdkLocalEnd()
            GroupCardTracker.reloadDataEnd()
        }).disposed(by: disposeBag)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .none
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupSubviews(isAddGradientView: false)
        // 重新设置背景颜色
        backgroundImageView?.backgroundColor = UIColor.ud.bgBody
        backgroundImageView?.ud.setMaskView()
        self.commonInit()
        businessTrack()
        GroupCardTracker.firstRenderEnd()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView?.contentOffset = CGPoint(x: 0, y: -self.thresholdOffset)
    }

    func commonInit() {
        self.isNavigationBarHidden = true
        if !self.hasBackPage, self.presentingViewController != nil {
            let dismissIcon = UDIcon.getIconByKey(.closeOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 20, height: 20))
            self.setNavigationItem(
                image: dismissIcon,
                highlightImage: dismissIcon,
                style: .left,
                selector: #selector(closeBtnTapped),
                target: self
            )
        } else {
            self.setNavigationItem(
                image: Resources.back_dark,
                highlightImage: Resources.back_dark,
                style: .left,
                selector: #selector(navigationBarLeftItemTapped),
                target: self
            )
        }

        self.tableView?.backgroundColor = UIColor.ud.bgBody
        if !viewModel.isJoinButtonHidden {
            joinGroupButton.addTarget(self, action: #selector(joinGroupButtonTapped), for: .touchUpInside)

            self.view.addSubview(joinGroupButton)
            joinGroupButton.snp.makeConstraints { (make) in
                make.left.equalTo(16)
                make.right.equalTo(-16)
                make.bottom.equalTo(self.view.safeAreaLayoutGuide).offset(-12)
                make.height.equalTo(48)
            }

            if let bottomDesc = viewModel.bottomDesc, !bottomDesc.isEmpty {
                self.view.addSubview(bottomLabel)
                bottomLabel.snp.makeConstraints { (make) in
                    make.left.equalTo(16)
                    make.right.equalTo(-16)
                    make.bottom.equalTo(joinGroupButton.snp.top).offset(-16)
                }
                bottomLabel.text = viewModel.bottomDesc
            }

            viewModel.joinButtonTitleRelay.asDriver().drive(onNext: { [weak self] title in
                guard let self = self else { return }
                self.joinGroupButton.setTitle(title, for: .normal)
                self.joinGroupButton.setTitle(title, for: .disabled)
                self.joinGroupButton.isEnabled = self.viewModel.joinButtonEnable
            }).disposed(by: disposeBag)
        }

        self.view.addSubview(groupAvatar)
        groupAvatar.layer.cornerRadius = 48
        groupAvatar.layer.masksToBounds = true
        groupAvatar.snp.makeConstraints { maker in
            maker.left.equalTo(20)
            maker.size.equalTo(96)
            if let backgroundImageView = self.backgroundImageView {
                maker.top.equalTo(backgroundImageView.snp.bottom).offset(-60)
            } else {
                maker.top.equalTo(120)
            }
        }

        GroupCardTracker.loadAvatarStart()
        self.setGroupAvatar(entityId: self.viewModel.chatId, avatarKey: self.viewModel.avatarKey, completion: { (_, _) in
            GroupCardTracker.loadAvatarEnd()
        })

        self.backgroundImageView?.image = Resources.group_card_backgroud_image
        self.groupAvatar.lu.addTapGestureRecognizer(
            action: #selector(backgroundImageViewTapped(_:)),
            target: self)
    }

    private func businessTrack() {
        ChatTracker.trackImChatGroupCardView(chat: self.viewModel.chat, extraInfo: viewModel.trackInfo)
    }

    @objc
    fileprivate func backgroundImageViewTapped(_ gesture: UIGestureRecognizer) {
        guard gesture.state == .ended else {
            return
        }
        self.viewModel.previewAvatar(with: groupAvatar)
    }

    // MARK: - UITableViewDelegate, UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.viewModel.items[indexPath.row]
        switch item {
        case .title(let chatName):
            let cell = GroupCardTitleCell()
            cell.set(groupName: chatName)
            return cell
        case .count(let membersCount):
            let cell = GroupCardBaseCell()
            cell.selectionStyle = .none
            let descText: String
            if let membersCount = membersCount {
                descText = "\(membersCount)\(BundleI18n.LarkChat.Lark_Legacy_People)"
            } else {
                descText = BundleI18n.LarkChat.Lark_IM_GroupCard_MemberHiden_Text
            }
            let attr = NSAttributedString(string: descText,
                                          attributes: [.foregroundColor: UIColor.ud.N500,
                                                       .font: UIFont.systemFont(ofSize: 14)])
            cell.set(titleLabelText: BundleI18n.LarkChat.Lark_Group_GroupMembersTotal, subTitleAttributedText: attr)
            return cell
        case .description(let description):
            let cell = GroupCardBaseCell()
            cell.selectionStyle = .none
            let attr = NSAttributedString(string: description,
                                          attributes: [.foregroundColor: UIColor.ud.N500,
                                                       .font: UIFont.systemFont(ofSize: 14)])
            cell.set(titleLabelText: BundleI18n.LarkChat.Lark_Legacy_GroupDescription, subTitleAttributedText: attr)
            return cell
        case .owner(let owner, let chatId):
            let cell = GroupCardBaseCell()
            cell.selectionStyle = .none
            let attr = NSAttributedString(string: owner.displayName,
                                          attributes: [.foregroundColor: UIColor.ud.primaryContentDefault,
                                                       .font: UIFont.systemFont(ofSize: 14)])
            cell.set(titleLabelText: BundleI18n.LarkChat.Lark_Legacy_ChatGroupOwner,
                     subTitleAttributedText: attr,
                     subLabelHandler: { [weak self] in
                        guard let self = self else { return }
                        self.openUserProfile(chatterId: owner.id, chatId: chatId)
                     })
            return cell
        case .joinOrganizationTips(let tips):
            let cell = GroupCardOuterCell()
            cell.setTips(tips)
            return cell
        }
    }

    private func openUserProfile(chatterId: String, chatId: String) {
        let body = PersonCardBody(chatterId: chatterId,
                                  chatId: chatId,
                                  source: .chat)
        if Display.phone {
            navigator.push(body: body, from: self)
        } else {
            navigator.present(
                body: body,
                wrap: LkNavigationController.self,
                from: self,
                prepare: { vc in
                    vc.modalPresentationStyle = .formSheet
                })
        }
    }

    // MARK: - UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        self.updateBackgoundImageViewBouncesZoom(offsetY)
    }

    @objc
    func navigationBarLeftItemTapped() {
        self.navigationController?.popViewController(animated: true)
    }

    @objc
    func joinGroupButtonTapped() {
        self.viewModel.joinGroupButtonTapped(from: self)
    }
}
