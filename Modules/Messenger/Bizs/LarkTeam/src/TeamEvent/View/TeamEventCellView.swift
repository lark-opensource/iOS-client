//
//  TeamEventCell.swift
//  LarkTeam
//
//  Created by chaishenghua on 2022/9/2.
//

import Foundation
import UIKit
import EENavigator
import LarkMessengerInterface
import LarkUIKit
import UniverseDesignToast
import RichLabel
import LarkSDKInterface
import ServerPB
import LarkModel
import LarkContainer

final class TeamEventCellView: UITableViewCell {
    static let identifier = "TeamEventCellView"
    private weak var targetVC: UIViewController?

    private var model: TeamEventCellModel?
    lazy var circleView: UIView = {
        let circle = UIView()
        circle.layer.cornerRadius = 6
        circle.backgroundColor = UIColor.ud.primaryContentDefault
        return circle
    }()

    lazy var eventLabel: LKLabel = {
        let eventLabel = LKLabel()
        eventLabel.textAlignment = .left
        eventLabel.numberOfLines = 0
        eventLabel.lineBreakMode = .byWordWrapping
        eventLabel.backgroundColor = UIColor.ud.bgBody
        eventLabel.textColor = UIColor.ud.textTitle
        return eventLabel
    }()

    lazy var datelabel: UILabel = {
        let datelabel = UILabel()
        datelabel.textAlignment = .left
        datelabel.numberOfLines = 1
        datelabel.sizeToFit()
        datelabel.font = UIFont.systemFont(ofSize: 14)
        datelabel.textColor = UIColor.ud.textCaption
        return datelabel
    }()

    lazy var upLine: UILabel = {
        let line = UILabel()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        return line
    }()

    lazy var downLine: UILabel = {
        let line = UILabel()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        return line
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        eventLabel.textColor = .white
    }

    private func setupView() {
        self.selectionStyle = .none
        eventLabel.delegate = self
        self.contentView.backgroundColor = UIColor.ud.bgBody
        contentView.addSubview(circleView)
        contentView.addSubview(eventLabel)
        contentView.addSubview(datelabel)
        contentView.addSubview(upLine)
        contentView.addSubview(downLine)
        circleView.snp.makeConstraints { (make) in
            make.width.equalTo(12)
            make.height.equalTo(12)
            make.leading.equalToSuperview().offset(24)
            make.top.equalToSuperview().offset(5)
        }
        eventLabel.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(52)
            make.trailing.equalToSuperview().inset(16)
            make.top.equalToSuperview()
        }
        datelabel.snp.makeConstraints { (make) in
            make.leading.equalTo(eventLabel.snp.leading)
            make.trailing.equalTo(eventLabel.snp.trailing)
            make.top.equalTo(eventLabel.snp.bottom).offset(4)
            make.bottom.equalToSuperview().offset(-24)
        }
        upLine.snp.makeConstraints { (make) in
            make.centerX.equalTo(circleView.snp.centerX)
            make.bottom.equalTo(circleView.snp.top)
            make.top.equalToSuperview()
            make.width.equalTo(1)
        }
        downLine.snp.makeConstraints { (make) in
            make.centerX.equalTo(circleView.snp.centerX)
            make.top.equalTo(circleView.snp.bottom)
            make.bottom.equalToSuperview().priority(.low)
            make.width.equalTo(1)
        }
    }

    func setModel(model: TeamEventCellModel, isHideUpLine: Bool, isHideDownLine: Bool, vc: UIViewController?, width: CGFloat) {
        self.model = model
        eventLabel.linkParser.textLinkList = model.links
        eventLabel.preferredMaxLayoutWidth = width - 52 - 16
        eventLabel.attributedText = model.event
        datelabel.text = model.time
        upLine.isHidden = isHideUpLine
        downLine.isHidden = isHideDownLine
        targetVC = vc
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        eventLabel.preferredMaxLayoutWidth = self.contentView.bounds.size.width - 52 - 16
    }
}

extension TeamEventCellView: LKLabelDelegate {
    func attributedLabel(_ label: RichLabel.LKLabel, didSelectLink url: URL) {
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return }
        guard let vc = targetVC else { return }
        let params = url.queryParameters
        if urlComponents.path == "/userProfile" {
            guard let userID = params["userid"] else { return }
            let body = PersonCardBody(chatterId: userID,
                                      chatId: "",
                                      source: .chat)
            model?.userResolver.navigator.presentOrPush(
                body: body,
                wrap: LkNavigationController.self,
                from: vc,
                prepareForPresent: { vc in
                    vc.modalPresentationStyle = .formSheet
                })
        } else if urlComponents.path == "/group" {
            guard let chatID = params["chatid"],
                  let mode = Int(params["chatMode"] ?? "1"),
                  let isCrypto = Bool(params["isCrypto"] ?? "false"),
                  let isMyAI = Bool(params["isMyAI"] ?? "false"),
                  let teamID = Int64(params["teamID"] ?? "0") else { return }
            let body = ChatControllerByBasicInfoBody(chatId: chatID,
                                                     fromWhere: .team(teamID: teamID),
                                                     isCrypto: isCrypto,
                                                     isMyAI: isMyAI,
                                                     chatMode: Chat.ChatMode(rawValue: mode) ?? .default)
            model?.userResolver.navigator.showDetailOrPush(body: body, wrap: LkNavigationController.self, from: vc)

        } else if urlComponents.path == "/operatorNotInChat" {
            UDToast.showFailure(with: BundleI18n.LarkTeam.Project_T_CannotJoinGroup_Hover, on: vc.view)
        }
    }

    func attributedLabel(_ label: RichLabel.LKLabel, didSelectPhoneNumber phoneNumber: String) {

    }

    func attributedLabel(_ label: RichLabel.LKLabel, didSelectText text: String, didSelectRange range: NSRange) -> Bool {
        return true
    }

    func shouldShowMore(_ label: RichLabel.LKLabel, isShowMore: Bool) {

    }

    func tapShowMore(_ label: RichLabel.LKLabel) {

    }

    func showFirstAtRect(_ rect: CGRect) {

    }
}
