//
//  ApproveCellItem.swift
//  LarkChat
//
//  Created by kongkaikai on 2019/3/29.
//

import Foundation
import UIKit
import LarkCore
import RichLabel
import LarkButton
import SnapKit
import RxSwift
import RxCocoa
import EENavigator
import LarkUIKit
import LarkModel
import LarkMessengerInterface
import LarkBizAvatar
import RustPB

struct ApproveItem {
    var id: String
    var name: String
    var avatarKey: String
    var inviterName: String
    var inviterId: String
    var way: RustPB.Basic_V1_AddChatChatterApply.Ways
    var postscript: String
    var isShowBorderLine: Bool

    init?(pb: RustPB.Basic_V1_AddChatChatterApply, invitee: Chatter?, inviter: Chatter?) {
        guard let invitee = invitee, let inviter = inviter else { return nil }

        self.id = pb.inviteeID
        self.name = invitee.displayName
        self.avatarKey = invitee.avatarKey
        self.inviterName = inviter.displayName
        self.inviterId = pb.inviterID
        self.way = pb.way

        // 通过团队进入的群，需要增加渠道来源
        var chanel: String = ""
        if pb.hasTeamName && !pb.teamName.isEmpty {
            chanel = BundleI18n.LarkChatSetting.Lark_IM_GroupJoinLeaveRecord_JoinGroupViaTeam_Text(pb.teamName)
        }
        var postscript: String = ""
        if !pb.reason.isEmpty {
            let reason = BundleI18n.LarkChatSetting.Lark_Group_MembershipRequestAdditionalComments(pb.reason)
            if !chanel.isEmpty {
                postscript = "\(chanel)\n\(reason)"
            } else {
                postscript = reason
            }
        }
        self.postscript = postscript
        self.isShowBorderLine = true
    }
}

final class ApproveCell: UITableViewCell {
    typealias OnButtonTap = (_ cell: UITableViewCell) -> Void

    private let disposeBag = DisposeBag()
    private let avatar = BizAvatar()
    private let avatarSize: CGFloat = 48
    private let nameButton = UIButton()
    private let joinWayLabel = LKLabel(frame: .zero)
    private let postscriptLabel = UILabel()
    private let rejectButton = IconButton()
    private let acceptButton = IconButton()
    var onReject: OnButtonTap?
    var onAccept: OnButtonTap?
    var navi: Navigatable?
    private var borderLine = UIView()

    var item: ApproveItem? {
        didSet { updateUI() }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(avatar)
        contentView.addSubview(nameButton)
        contentView.addSubview(joinWayLabel)
        contentView.addSubview(postscriptLabel)
        contentView.addSubview(rejectButton)
        contentView.addSubview(acceptButton)
        contentView.backgroundColor = UIColor.ud.bgFloat

        let tap = UITapGestureRecognizer(target: self, action: #selector(showPerson(_:)))
        tap.numberOfTapsRequired = 1
        avatar.addGestureRecognizer(tap)
        avatar.isUserInteractionEnabled = true
        avatar.snp.makeConstraints { (maker) in
            maker.top.equalTo(10)
            maker.left.equalTo(16)
            maker.width.height.equalTo(avatarSize)
        }

        nameButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        nameButton.setTitleColor(UIColor.ud.N900, for: .normal)
        nameButton.snp.makeConstraints { (maker) in
            maker.centerY.equalTo(avatar)
            maker.left.equalTo(avatar.snp.right).offset(12)
            maker.right.lessThanOrEqualTo(rejectButton.snp.left).inset(12)
        }

        joinWayLabel.font = UIFont.systemFont(ofSize: 14)
        joinWayLabel.backgroundColor = UIColor.clear
        joinWayLabel.textColor = UIColor.ud.N500
        joinWayLabel.numberOfLines = 2
        joinWayLabel.linkAttributes = [NSAttributedString.Key(rawValue: kCTForegroundColorAttributeName as String): UIColor.ud.colorfulBlue]
        joinWayLabel.activeLinkAttributes = joinWayLabel.linkAttributes
        joinWayLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(avatar.snp.bottom).offset(4)
            maker.left.right.equalToSuperview().inset(16)
        }

        postscriptLabel.numberOfLines = 0
        postscriptLabel.font = UIFont.systemFont(ofSize: 14)
        postscriptLabel.textColor = UIColor.ud.N500
        postscriptLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(joinWayLabel.snp.bottom).offset(2)
            maker.left.right.equalToSuperview().inset(16)
            maker.bottom.equalToSuperview().inset(12)
        }

        rejectButton.layer.masksToBounds = true
        rejectButton.layer.cornerRadius = 16
        rejectButton.icon = Resources.approve_reject
        rejectButton.snp.makeConstraints { (maker) in
            maker.top.equalTo(18)
            maker.right.equalToSuperview().inset(62)
            maker.width.height.equalTo(32)
        }

        acceptButton.layer.masksToBounds = true
        acceptButton.layer.cornerRadius = 16
        acceptButton.icon = Resources.approve_accept
        acceptButton.snp.makeConstraints { (maker) in
            maker.top.equalTo(18)
            maker.right.equalToSuperview().inset(16)
            maker.width.height.equalTo(32)
        }

        borderLine = contentView.lu.addBottomBorder(leading: 16, color: UIColor.ud.commonTableSeparatorColor)

        selectedBackgroundView = BaseCellSelectView()

        bindingEvent()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func bindingEvent() {
        nameButton.rx.tap.asDriver().drive(onNext: { [weak self] _ in
            guard let id = self?.item?.id, !id.isEmpty else { return }
            guard let windows = self?.window else {
                assertionFailure("缺少 From VC")
                return
            }
            let body = PersonCardBody(chatterId: id)
            if Display.phone {
                self?.navi?.push(body: body, from: windows)
            } else {
                self?.navi?.present(
                    body: body,
                    wrap: LkNavigationController.self,
                    from: windows,
                    prepare: { vc in
                        vc.modalPresentationStyle = .formSheet
                    })
            }
        }).disposed(by: self.disposeBag)

        rejectButton.rx.tap.asDriver().drive(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.onReject?(self)
        }).disposed(by: self.disposeBag)

        acceptButton.rx.tap.asDriver().drive(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.onAccept?(self)
        }).disposed(by: self.disposeBag)
    }

    @objc
    private func showPerson(_ gesture: UITapGestureRecognizer) {
        guard let id = item?.id, !id.isEmpty else { return }
        guard let windows = self.window else {
            assertionFailure("缺少 From VC")
            return
        }

        let body = PersonCardBody(chatterId: id)
        if Display.phone {
            self.navi?.push(body: body, from: windows)
        } else {
            self.navi?.present(
                body: body,
                wrap: LkNavigationController.self,
                from: windows,
                prepare: { vc in
                    vc.modalPresentationStyle = .formSheet
                })
        }
    }

    private func updateUI() {
        guard let item = self.item else { return }
        avatar.setAvatarByIdentifier(item.id,
                                     avatarKey: item.avatarKey,
                                     scene: .Setting,
                                     avatarViewParams: .init(sizeType: .size(avatarSize)))
        nameButton.setTitle(item.name, for: .normal)
        formatJoinWay()
        postscriptLabel.text = item.postscript

        if item.postscript.isEmpty {
            postscriptLabel.snp.updateConstraints { $0.top.equalTo(joinWayLabel.snp.bottom).offset(-2) }
            postscriptLabel.isHidden = true
        } else {
            postscriptLabel.snp.updateConstraints { $0.top.equalTo(joinWayLabel.snp.bottom).offset(2) }
            postscriptLabel.isHidden = false
        }
        borderLine.isHidden = !item.isShowBorderLine
    }

    private func formatJoinWay() {
        guard let item = self.item else { return }

        let inviter = "{{Inviter}}"

        let sourceString: String?

        switch item.way {
        case .viaShare, .viaQrCode:
            sourceString = BundleI18n.LarkChatSetting.Lark_Group_ApplyToJoinGroupDescription(inviter)
        case .viaInvitation:
            sourceString = BundleI18n.LarkChatSetting.Lark_Group_InviteMembersRequestDescription(inviter)
        case .viaSearch:
            sourceString = BundleI18n.LarkChatSetting.Lark_Group_JoinPublicGroupBySearch
        case .viaDepartmentStructure:
            sourceString = BundleI18n.LarkChatSetting.Lark_Group_ApplyToJoinGroupGeneral
        case .viaLink:
            sourceString = BundleI18n.LarkChatSetting.Lark_Chat_JoinApplicationThroughLink(inviter)
        case .viaCalendar:
            sourceString = BundleI18n.LarkChatSetting.Lark_Group_JoinGroupByEvent
        case .viaChatLinkedPage:
            sourceString = BundleI18n.LarkChatSetting.Lark_GroupLinkPage_JoinViaLinkedPage_Text
        case .viaTeamOpenChat, .viaTeamPrivateDiscoverable:
            sourceString = nil
        case .unknownWay:
            sourceString = nil
        @unknown default:
            assert(false, "new value")
            sourceString = nil
        }

        guard let string = sourceString as NSString? else { return }

        let inviterRange = string.range(of: inviter)

        // 被邀请人、邀请人都找不到，直接设置`sourceString`返回
        guard inviterRange.location != NSNotFound else {
            joinWayLabel.text = sourceString
            return
        }

        let result = string.replacingOccurrences(of: inviter, with: item.inviterName)

        let datas: [(range: NSRange, name: String, id: String)] = [(inviterRange, item.inviterName, item.inviterId)]

        var offset = 0
        for data in datas {
            let length = (data.name as NSString).length

            var range = data.range
            range.location += offset
            range.length = length

            offset += length - data.range.length

            var textLink = LKTextLink(range: range, type: .link)
            textLink.linkTapBlock = { [weak self] (_, _) in
                guard let windows = self?.window else {
                    assertionFailure("缺少 From VC")
                    return
                }
                let body = PersonCardBody(chatterId: data.id)
                if Display.phone {
                    self?.navi?.push(body: body, from: windows)
                } else {
                    self?.navi?.present(
                        body: body,
                        wrap: LkNavigationController.self,
                        from: windows,
                        prepare: { vc in
                            vc.modalPresentationStyle = .formSheet
                        })
                }
            }
            joinWayLabel.addLKTextLink(link: textLink)
        }

        joinWayLabel.text = result
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        avatar.setAvatarByIdentifier("", avatarKey: "")
        joinWayLabel.removeLKTextLink()
    }
}
