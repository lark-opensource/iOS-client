//
//  ReplayActionBar.swift
//  Calendar
//
//  Created by heng zhu on 2019/7/23.
//

import UIKit
import UniverseDesignIcon
import Foundation
import CalendarFoundation
import UniverseDesignTheme

protocol ActionBarDelegate: AnyObject {
    func actionBarDidTapAccept()
    func actionBarDidTapDecline()
    func actionBarDidTapTentative()
    func actionBarDidTapJoin()
    func actionBarDidTapReply()
}

final class ReplyActionBar: UIView {

    private var tentativeSelectImage: UIImage {
        UIImage.cd.image(named: "maybe_filled_legacy")
    }

    private var declineSelectImage: UIImage {
        UIImage.cd.image(named: "decline_filled")
    }

    private var acceptSelectImage: UIImage {
        UIImage.cd.image(named: "yes_filled")
    }

    lazy var tentativeBtn: ActionBarButton = {
        let tentativeBtn = ActionBarButton(selectedTitle: BundleI18n.Calendar.Calendar_Detail_Maybe,
                                            normalTitle: BundleI18n.Calendar.Calendar_Detail_Maybe,
                                            selectedImage: tentativeSelectImage,
                                            normalImage: UDIcon.getIconByKeyNoLimitSize(.maybeOutlined).renderColor(with: .n2),
                                            selectedColor: self.tentativeColor,
                                            normalColor: UIColor.ud.textTitle)
        tentativeBtn.addTarget(self, action: #selector(tentativeAction(sender:)), for: .touchUpInside)
        tentativeBtn.addRightBorder(inset: UIEdgeInsets(top: 14, left: 0, bottom: 13.5, right: 0), lineWidth: 1)
        return tentativeBtn
    }()
    lazy var declineBtn: ActionBarButton = {
        let declineBtn = ActionBarButton(selectedTitle: BundleI18n.Calendar.Calendar_Detail_Refused,
                                         normalTitle: BundleI18n.Calendar.Calendar_Detail_Refuse,
                                         selectedImage: declineSelectImage,
                                         normalImage: UDIcon.getIconByKeyNoLimitSize(.noOutlined).renderColor(with: .n2),
                                         selectedColor: self.declineColor,
                                         normalColor: UIColor.ud.textTitle)
        declineBtn.addTarget(self, action: #selector(declineAction(sender:)), for: .touchUpInside)
        return declineBtn
    }()
    lazy var acceptBtn: ActionBarButton = {
        let acceptBtn = ActionBarButton(selectedTitle: BundleI18n.Calendar.Calendar_Detail_Accepted,
                                        normalTitle: BundleI18n.Calendar.Calendar_Detail_Accept,
                                        selectedImage: acceptSelectImage,
                                        normalImage: UDIcon.getIconByKeyNoLimitSize(.yesOutlined).renderColor(with: .n2),
                                        selectedColor: self.acceptColor,
                                        normalColor: UIColor.ud.textTitle)
        acceptBtn.addTarget(self, action: #selector(acceptAction(sender:)), for: .touchUpInside)
        return acceptBtn
    }()

    private lazy var replyBtn: UIButton = {
        let button = UIButton.cd.button()
        button.setImage(UIImage.cd.image(named: "iconReply").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(actionBarDidTapReply), for: .touchUpInside)
        return button
    }()
    let defaultHeight: CGFloat = 44.0
    weak var delegate: ActionBarDelegate?

    private func layoutAcceptBtn(in view: UIView) {
        view.addSubview(acceptBtn)
        acceptBtn.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        acceptBtn.snp.makeConstraints { (make) in
            make.left.top.bottom.equalToSuperview()
            make.width.equalTo(declineBtn)
        }
    }

    private func layoutDeclineBtn(in view: UIView) {
        view.addSubview(declineBtn)
        declineBtn.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        declineBtn.snp.makeConstraints { (make) in
            make.left.equalTo(acceptBtn.snp.right)
            make.top.bottom.equalToSuperview()
            make.width.equalTo(tentativeBtn)
        }
    }

    private func layoutTentativeBtn(in view: UIView, isLastBtn: Bool) {
        view.addSubview(tentativeBtn)
        tentativeBtn.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        tentativeBtn.snp.makeConstraints { (make) in
            make.left.equalTo(declineBtn.snp.right)
            if isLastBtn {
                make.right.equalToSuperview()
            }
            make.top.bottom.equalToSuperview()
        }
    }

    private func layoutReplyBtn(in view: UIView) {
        view.addSubview(replyBtn)
        replyBtn.snp.makeConstraints { (make) in
            make.left.equalTo(tentativeBtn.snp.right)
            make.width.equalTo(48)
            make.top.bottom.right.equalToSuperview()
        }
    }

    public init(isPackUpStyle: Bool,
                showReplyEntrance: Bool) {
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.bgFloat
        self.layer.shadowRadius = 2.0
        self.layer.ud.setShadowColor(UIColor.black)
        self.layer.shadowOpacity = 0.03
        self.layer.cornerRadius = 13
        self.layer.shadowOffset = CGSize(width: 0, height: -2)
        let warpper = UIView()
        self.addSubview(warpper)
        warpper.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.height.equalTo(self.defaultHeight)
            make.top.equalToSuperview()
        }
        warpper.addSubview(acceptBtn)
        warpper.addSubview(declineBtn)
        warpper.addSubview(tentativeBtn)
        warpper.addSubview(replyBtn)
        layoutAcceptBtn(in: warpper)
        layoutDeclineBtn(in: warpper)
        layoutTentativeBtn(in: warpper, isLastBtn: !showReplyEntrance)
        if showReplyEntrance {
            layoutReplyBtn(in: warpper)
        }

        self.setNeedAction()

        if isPackUpStyle {
            self.changeToPackUpStyle()
        }
    }

    private let acceptColor = UIColor.ud.functionSuccessContentDefault
    private let declineColor: UIColor = UIColor.ud.functionDangerContentDefault
    private let tentativeColor: UIColor = UIColor.ud.textCaption

    private func unselectAll() {
        acceptBtn.isSelected = false
        declineBtn.isSelected = false
        tentativeBtn.isSelected = false
    }

    private func allSetFinalStatus(animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.2) {
                self.acceptBtn.setFinalStatus()
                self.declineBtn.setFinalStatus()
                self.tentativeBtn.setFinalStatus()
            }
        } else {
            acceptBtn.setFinalStatus()
            declineBtn.setFinalStatus()
            tentativeBtn.setFinalStatus()
        }
    }

    func changeToPackUpStyle() {
        replyBtn.setImage(UDIcon.getIconByKeyNoLimitSize(.pullDownOutlined).scaleInfoSize().renderColor(with: .n2), for: .normal)
    }

    func getActionBar() -> UIView {
        return self
    }

    func setAccepted(animated: Bool = true) {
        self.unselectAll()
        acceptBtn.isSelected = true
        allSetFinalStatus(animated: animated)
    }

    func setDeclined(animated: Bool = true) {
        self.unselectAll()
        self.declineBtn.isSelected = true
        allSetFinalStatus(animated: animated)
    }

    func setTentatived(animated: Bool = true) {
        self.unselectAll()
        self.tentativeBtn.isSelected = true
        allSetFinalStatus(animated: animated)
    }

    func setNeedAction() {
        acceptBtn.isSelected = false
        declineBtn.isSelected = false
        tentativeBtn.isSelected = false
    }

    func hide() {
        self.isHidden = true
        self.setContentHuggingPriority(.required, for: .vertical)
        self.invalidateIntrinsicContentSize()
    }

    @objc
    private func tentativeAction(sender: Any) {
        if self.tentativeBtn.isSelected { return }
        self.delegate?.actionBarDidTapTentative()
    }

    @objc
    private func joinAction(sender: UIButton) {
        self.delegate?.actionBarDidTapJoin()
    }

    @objc
    private func declineAction(sender: Any) {
        if self.declineBtn.isSelected { return }
        self.delegate?.actionBarDidTapDecline()
    }

    @objc
    private func acceptAction(sender: Any) {
        if self.acceptBtn.isSelected { return }
        self.delegate?.actionBarDidTapAccept()
    }

    @objc
    private func actionBarDidTapReply(sender: Any) {
        self.delegate?.actionBarDidTapReply()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height = self.isHidden ? 0.0 : self.defaultHeight
        return size
    }

    lazy var joinButton: UIButton = {
        let button = UIButton.cd.button(type: .system)
        button.backgroundColor = UIColor.ud.bgBody
        button.tintColor = UIColor.ud.textTitle
        button.setTitle(BundleI18n.Calendar.Calendar_Share_Join, for: .normal)
        self.addSubview(button)
        button.snp.makeConstraints({ (make) in
            make.edges.equalToSuperview()
        })
        button.addTarget(self, action: #selector(joinAction(sender:)), for: .touchUpInside)
        return button
    }()

    lazy var cantJoinLabel: UILabel = {
        let label = UILabel.cd.subTitleLabel(fontSize: 16)
        label.backgroundColor = UIColor.ud.bgBody
        label.text = BundleI18n.Calendar.Calendar_Share_UnableToJoinEvent
        label.textAlignment = .center
        addSubview(label)
        label.snp.makeConstraints({ (make) in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(15)
            make.right.equalToSuperview().offset(-15)
        })
        return label
    }()

    func showJoinButton() {
        self.bringSubviewToFront(self.joinButton)
    }

    func showCantJoinLabel() {
        self.bringSubviewToFront(cantJoinLabel)
    }

    private lazy var rsvpStatusLable: UILabel = {
        // 用于遮盖文字后面的 RSVP 按钮视图
        let view = UIView()
        view.backgroundColor = backgroundColor
        self.addSubview(view)
        view.snp.makeConstraints({ (make) in
            make.edges.equalToSuperview()
        })

        let label = UILabel()
        label.font = UIFont.cd.regularFont(ofSize: 16)
        label.textColor = UIColor.ud.textPlaceholder
        label.textAlignment = .center
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        label.backgroundColor = .clear
        label.isUserInteractionEnabled = true
        view.addSubview(label)
        label.snp.makeConstraints({ (make) in
            make.left.top.right.equalToSuperview().inset(16)
            make.bottom.equalTo(self.safeAreaLayoutGuide.snp.bottom).inset(16)
        })
        return label
    }()

    func showReplyRsvp(rsvpStatusString: String?) {
        self.bringSubviewToFront(self.rsvpStatusLable)
        rsvpStatusLable.text = rsvpStatusString
    }
}
