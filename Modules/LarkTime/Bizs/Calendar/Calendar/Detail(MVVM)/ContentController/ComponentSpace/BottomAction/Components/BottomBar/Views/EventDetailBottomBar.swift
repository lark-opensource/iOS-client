//
//  EventDetailBottomBar.swift
//  Calendar
//
//  Created by LiangHongbin on 2021/9/14.
//

import UIKit
import UniverseDesignIcon
import Foundation
import CalendarFoundation
import UniverseDesignTheme
import UniverseDesignShadow
import UniverseDesignColor

protocol EventDetailBottomBarDelegate: AnyObject {
    func actionBarDidTapAccept(_ bottomBar: EventDetailBottomBar)
    func actionBarDidTapDecline(_ bottomBar: EventDetailBottomBar)
    func actionBarDidTapTentative(_ bottomBar: EventDetailBottomBar)
    func actionBarDidReTap(_ bottomBar: EventDetailBottomBar)
    func actionBarDidTapJoin(_ bottomBar: EventDetailBottomBar)
    func actionBarDidTapReply(_ bottomBar: EventDetailBottomBar, handle: (() -> Void)?)
}

final class EventDetailBottomBar: UIView {

    weak var delegate: EventDetailBottomBarDelegate?

    private var btnContainer = UIStackView()

    private var topLine: UIView?
    private var replyedButton = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        btnContainer.spacing = 12
        btnContainer.distribution = .fillEqually
        addSubview(btnContainer)
        btnContainer.snp.makeConstraints {
            $0.height.equalTo(36)
            $0.left.equalToSuperview().offset(16)
            $0.right.equalToSuperview().offset(-16)
            $0.top.equalToSuperview().offset(13)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupButtons(with buttons: [ActionBarButtonForIG.ButtonType]) {
        btnContainer.subviews.forEach { $0.removeFromSuperview() }
        buttons.forEach { buttonType in
            switch buttonType {
            case .join:
                btnContainer.addArrangedSubview(joinBtn)
            case .accept:
                btnContainer.addArrangedSubview(acceptBtn)
            case .reject:
                btnContainer.addArrangedSubview(declineBtn)
            case .tentative:
                btnContainer.addArrangedSubview(tentativeBtn)
            case .hasAccepted:
                btnContainer.addArrangedSubview(hasAcceptedBtn)
            case .hasRejected:
                btnContainer.addArrangedSubview(hasDeclinedBtn)
            case .hasBeenTentative:
                btnContainer.addArrangedSubview(hasBeenTentativeBtn)
            case .reply: break
            }
        }
    }

    func appendReplyBtn() {
        addSubview(replyBtn)
        replyBtn.snp.makeConstraints {
            $0.right.equalToSuperview().offset(-16)
            $0.size.equalTo(CGSize(width: 36, height: 36))
            $0.centerY.equalTo(btnContainer.snp.centerY)
        }
        btnContainer.snp.updateConstraints {
            // 右边距-左边距-btn width
            $0.right.equalToSuperview().offset(-16 - 12 - 36)
        }
    }

    func showCantJoinLabel() {
        btnContainer.isHidden = true
        self.bringSubviewToFront(cantJoinLabel)
        showUpBorderShadow()
    }

    func showRSVPStatusString(tips: String) {
        btnContainer.isHidden = true
        self.bringSubviewToFront(rsvpStatusLable)
        showUpBorderShadow()
        rsvpStatusLable.text = tips
    }

    func showUpBorderShadow() {
        self.layer.ud.setShadow(type: .s1Up)
    }

    // MARK: label

    private lazy var cantJoinLabel: UILabel = {
        let label = UILabel.cd.subTitleLabel(fontSize: 16)
        label.backgroundColor = UIColor.ud.bgBody
        label.text = BundleI18n.Calendar.Calendar_Share_UnableToJoinEvent
        label.textAlignment = .left
        label.numberOfLines = 0
        label.textColor = UIColor.ud.textPlaceholder
        addSubview(label)
        label.snp.makeConstraints({ (make) in
            make.top.equalToSuperview().offset(16)
            make.bottom.equalTo(safeAreaLayoutGuide)
            make.left.equalToSuperview().offset(15)
            make.right.equalToSuperview().offset(-15)
        })
        return label
    }()

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

    // MARK: buttons

    private(set) lazy var joinBtn: UIButton = {
        let button = ActionBarButtonForIG()
        button.setupButton(with: .join)
        button.addTarget(self, action: #selector(joinAction(sender:)), for: .touchUpInside)
        return button
    }()

    private(set) lazy var acceptBtn: UIButton = {
        let button = ActionBarButtonForIG()
        button.setupButton(with: .accept)
        button.addTarget(self, action: #selector(acceptAction(sender:)), for: .touchUpInside)
        return button
    }()

    private(set) lazy var declineBtn: UIButton = {
        let button = ActionBarButtonForIG()
        button.setupButton(with: .reject)
        button.addTarget(self, action: #selector(declineAction(sender:)), for: .touchUpInside)
        return button
    }()

    private(set) lazy var tentativeBtn: UIButton = {
        let button = ActionBarButtonForIG()
        button.setupButton(with: .tentative)
        button.addTarget(self, action: #selector(tentativeAction(sender:)), for: .touchUpInside)
        return button
    }()

    private(set) lazy var hasAcceptedBtn: UIButton = {
        let button = ActionBarButtonForIG()
        button.setupButton(with: .hasAccepted)
        button.addTarget(self, action: #selector(actionBarDidReTap(sender:)), for: .touchUpInside)
        return button
    }()

    private(set) lazy var hasDeclinedBtn: UIButton = {
        let button = ActionBarButtonForIG()
        button.setupButton(with: .hasRejected)
        button.addTarget(self, action: #selector(actionBarDidReTap(sender:)), for: .touchUpInside)
        return button
    }()

    private(set) lazy var hasBeenTentativeBtn: UIButton = {
        let button = ActionBarButtonForIG()
        button.setupButton(with: .hasBeenTentative)
        button.addTarget(self, action: #selector(actionBarDidReTap(sender:)), for: .touchUpInside)
        return button
    }()

    private(set) lazy var replyBtn: ActionBarButtonForIG = {
        let button = ActionBarButtonForIG()
        button.setupButton(with: .reply)
        button.addTarget(self, action: #selector(actionBarDidTapReply(sender:)), for: .touchUpInside)
        return button
    }()

    @objc
    private func joinAction(sender: UIButton) {
        self.delegate?.actionBarDidTapJoin(self)
    }

    @objc
    private func acceptAction(sender: Any) {
        if self.acceptBtn.isSelected { return }
        self.delegate?.actionBarDidTapAccept(self)
    }

    @objc
    private func declineAction(sender: Any) {
        if self.declineBtn.isSelected { return }
        self.delegate?.actionBarDidTapDecline(self)
    }

    @objc
    private func tentativeAction(sender: Any) {
        if self.tentativeBtn.isSelected { return }
        self.delegate?.actionBarDidTapTentative(self)
    }

    @objc
    private func actionBarDidReTap(sender: Any) {
        self.delegate?.actionBarDidReTap(self)
    }

    @objc
    private func actionBarDidTapReply(sender: Any) {
        replyBtn.startAnimation()
        self.delegate?.actionBarDidTapReply(self) {
            self.replyBtn.stopAnimation()
        }
    }
}
