//
//  ParticipantSectionHeaderView.swift
//  ByteView
//
//  Created by huangshun on 2019/7/31.
//

import Foundation
import SnapKit
import RxDataSources
import RxCocoa
import UIKit

class ParticipantSectionHeaderView: ParticipantSectionTipHeaderView {

    lazy var collaspeIconView: ParticipantImageView = {
        let imageView = ParticipantImageView()
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        return imageView
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.numberOfLines = 1
        label.textColor = UIColor.ud.textCaption
        label.lineBreakMode = .byTruncatingMiddle
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    lazy var descLabel: UILabel = {
        let label = UILabel()
        label.text = I18n.View_G_LobbyTip
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.numberOfLines = 1
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    lazy var actionButton: UIButton = {
        let button = UIButton(type: .custom)
        button.vc.setBackgroundColor(UIColor.clear, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.udtokenBtnTextBgPriPressed, for: .highlighted)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 6
        button.addTarget(self, action: #selector(actionButtonAction(_:)), for: .touchUpInside)
        return button
    }()

    let buttonSubStackView: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 4
        s.alignment = .center
        s.clipsToBounds = true
        s.isUserInteractionEnabled = false
        return s
    }()

    let buttonSubTitle: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 14)
        l.clipsToBounds = true
        l.numberOfLines = 1
        l.setContentHuggingPriority(.required, for: .horizontal)
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        return l
    }()

    let buttonSubLoading: LoadingView = {
        let l = LoadingView(frame: CGRect(x: 0, y: 0, width: 14, height: 14), style: .blue)
        l.clipsToBounds = true
        return l
    }()

    var tapActionButton: (() -> Void)?

    private var titleBottom: Constraint?
    private var descBottom: Constraint?
    private var tipBottom: Constraint?
    var isBreakoutRoomRelay: BehaviorRelay<Bool>?

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        self.contentView.addSubview(collaspeIconView)
        self.contentView.addSubview(titleLabel)
        self.contentView.addSubview(descLabel)
        self.contentView.addSubview(actionButton)

        backgroundView = UIView()

        collaspeIconView.snp.makeConstraints { (make) in
            make.size.equalTo(12)
            make.centerY.equalTo(titleLabel)
            make.left.equalTo(safeAreaLayoutGuide).inset(16)
        }

        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(8)
            titleBottom = make.bottom.equalToSuperview().inset(10).constraint
            make.left.equalTo(collaspeIconView.snp.right).offset(8)
            make.right.lessThanOrEqualTo(actionButton.snp.left).offset(-16)
            make.height.equalTo(20)
        }

        descLabel.snp.makeConstraints { (make) in
            make.left.equalTo(titleLabel)
            make.right.equalTo(safeAreaLayoutGuide).inset(16)
            make.top.equalTo(titleLabel.snp.bottom)
            make.height.equalTo(18)
            descBottom = make.bottom.equalToSuperview().inset(10).constraint
        }

        actionButton.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.right.equalTo(safeAreaLayoutGuide).inset(12)
        }

        actionButton.addSubview(buttonSubStackView)
        buttonSubStackView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(2)
            $0.left.right.equalToSuperview().inset(4)
        }

        buttonSubStackView.addArrangedSubview(buttonSubLoading)
        buttonSubLoading.snp.makeConstraints {
            $0.size.equalTo(CGSize(width: 20, height: 20))
        }
        buttonSubLoading.isHiddenInStackView = true

        buttonSubStackView.addArrangedSubview(buttonSubTitle)
        buttonSubTitle.snp.makeConstraints {
            $0.top.bottom.right.equalToSuperview()
        }

        tipLabel.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(12)
            make.top.equalToSuperview().inset(8)
            make.height.equalTo(20)
            make.right.lessThanOrEqualTo(downHandsButton.snp.left)
        }

        downHandsButton.snp.remakeConstraints { make in
            make.right.equalToSuperview().inset(12)
            make.height.equalTo(24)
            make.centerY.equalToSuperview()
        }

        containerView.snp.remakeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.left.right.equalToSuperview().inset(14)
            make.height.equalTo(36)
            tipBottom = make.bottom.equalToSuperview().inset(4).constraint
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func actionButtonAction(_ b: Any) {
        tapActionButton?()
    }
}

extension ParticipantSectionHeaderView {
    func headerViewFontSize(_ dataSource: [ParticipantsSectionModel], viewForHeaderInSection section: Int) {
        guard section < dataSource.count else {
            return
        }
        let sectionModel = dataSource[section]
        collaspeIconView.key = sectionModel.headerIcon
        titleLabel.text = sectionModel.header
        actionButton.isHidden = sectionModel.actionName.isEmpty
        buttonSubTitle.text = sectionModel.actionName
        actionButtonEnabled(sectionModel.actionEnabled)
        updateButtonLoading(!sectionModel.actionEnabled)
    }

    func setAttachedView(isBreakoutRoom: Bool, isHandsUp: Bool) {
        descLabel.isHidden = true
        containerView.isHidden = true
        if isBreakoutRoom {
            descLabel.isHidden = false
            descBottom?.activate()
            titleBottom?.deactivate()
            tipBottom?.deactivate()
        } else {
            if isHandsUp {
                containerView.isHidden = false
                tipBottom?.activate()
                descBottom?.deactivate()
                titleBottom?.deactivate()
            } else {
                titleBottom?.activate()
                descBottom?.deactivate()
                tipBottom?.deactivate()
            }
        }
    }

    func actionButtonEnabled(_ e: Bool) {
        actionButton.isEnabled = e
        buttonSubTitle.textColor = e ? .ud.primaryContentDefault : .ud.textDisabled
    }

    func updateButtonLoading(_ show: Bool) {
        buttonSubLoading.isHidden = !show
        if show {
            buttonSubLoading.play()
        } else {
            buttonSubLoading.stop()
        }
    }
}

class ParticipantSectionHeaderTapGesture: UITapGestureRecognizer {
    var participantState: ParticipantState = .idle
}

class ParticipantSectionTipHeaderView: UITableViewHeaderFooterView {
    lazy var tipLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        return label
    }()

    lazy var downHandsButton: UIButton = {
        let btn = UIButton()
        btn.setTitle(I18n.View_G_DownAllHands, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        btn.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        btn.addTarget(self, action: #selector(tap(_:)), for: .touchUpInside)
        return btn
    }()

    lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.05)
        view.layer.cornerRadius = 6
        view.addSubview(tipLabel)
        view.addSubview(downHandsButton)
        return view
    }()

    var tapDownAllHands: (() -> Void)?
    var showButton: Bool = false {
        didSet {
            downHandsButton.isHidden = !showButton
        }
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        backgroundColor = UIColor.ud.bgFloat
        self.contentView.backgroundColor = UIColor.ud.bgFloat
        self.contentView.addSubview(containerView)

        tipLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(12)
            make.top.equalToSuperview().inset(8)
            make.height.equalTo(20)
            make.right.lessThanOrEqualTo(downHandsButton.snp.left)
        }
        downHandsButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.height.equalTo(20)
        }
        containerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12 - 8) // baseTableView 的top insert为8
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(36)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func tap(_ b: Any) {
        tapDownAllHands?()
    }

    func setIsHost(_ isHost: Bool) {
        downHandsButton.isHidden = !isHost
    }
}
