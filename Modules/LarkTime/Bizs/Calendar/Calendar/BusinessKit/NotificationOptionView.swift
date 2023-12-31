//
//  NotificationOptionView.swift
//  Calendar
//
//  Created by zhouyuan on 2019/1/15.
//  Copyright © 2019 EE. All rights reserved.
//

import UIKit
import UniverseDesignIcon
import Foundation
import CalendarFoundation
import UniverseDesignCheckBox
import UniverseDesignDialog
import SnapKit
import RxSwift

typealias Disappear = (_ completion: @escaping() -> Void) -> Void

final class ActionButton {
    let handler: (Bool?, @escaping Disappear) -> Void
    let button = UIButton(type: .system)

    init(title: String,
         titleColor: UIColor = UIColor.ud.N800,
         handler: @escaping (Bool?, @escaping Disappear) -> Void) {
        self.handler = handler
        button.setTitle(title, for: .normal)
        button.setTitleColor(titleColor, for: .normal)
        button.titleLabel?.font = UIFont.cd.regularFont(ofSize: 17)
    }
}

final class NotificationOptionView: UIView {
    private let disposeBag = DisposeBag()
    var checkBoxListCallBack: (([Bool], EventEdit.NotiOptionCheckBoxType) -> Void)?
    var checkBoxListType: EventEdit.NotiOptionCheckBoxType = .unknown
    var trackInvitedGroupCheckStatus: ((Bool) -> Void)?
    var trackMinutesCheckStatus: ((Bool) -> Void)?

    private let titleLabel: UILabel = {
        let label = UILabel.cd.titleLabel(fontSize: 17)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    private let subTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .left
        return label
    }()

    private let tirdTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .left
        return label
    }()

    private let subTitleLabelNoIcon: UILabel = {
        let label = UILabel.cd.subTitleLabel(fontSize: 16)
        label.textColor = UIColor.ud.textTitle
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .center
        return label
    }()

    private let subTitleMailLabel: UILabel = {
        let label = UILabel.cd.subTitleLabel(fontSize: 16)
        label.textColor = UIColor.ud.textTitle
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    private let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        return stackView
    }()

    private let checkButton: UDCheckBox = {
        let checkbox = UDCheckBox(boxType: .multiple)
        checkbox.isSelected = false
        checkbox.isUserInteractionEnabled = false
        return checkbox
    }()

    private let secondCheckButton: UDCheckBox = {
        let checkbox = UDCheckBox(boxType: .multiple)
        checkbox.isSelected = false
        checkbox.isUserInteractionEnabled = false
        return checkbox
    }()

    private lazy var multiCheckBoxStackView: UIStackView = {
        let view = UIStackView()
        view.backgroundColor = .clear
        view.axis = .vertical
        view.spacing = 12.0
        return view
    }()

    let titleStackView = UIStackView()

    private let subtitleContainer = UIView()
    private let subtitleSubContainer = UIView()

    private let tirdtitleContainer = UIView()
    private let tirdtitleSubContainer = UIView()

    init() {
        super.init(frame: .zero)
        layoutTitleStackView(titleStackView)
        layoutButtonStackView(buttonStackView, topView: titleStackView)
        layoutTitleLabels()
    }

    private func layoutTitleStackView(_ stackView: UIStackView) {
        stackView.axis = .vertical
        stackView.spacing = 12.0
        stackView.alignment = .center
        stackView.distribution = .fill
        self.addSubview(stackView)
        stackView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(24)
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
        }
    }

    private func layoutButtonStackView(_ stackView: UIStackView, topView: UIView) {
        self.addSubview(stackView)
        stackView.snp.makeConstraints { (make) in
            make.top.equalTo(topView.snp.bottom).offset(24)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    func setTitles(titleText: String, subTitleText: String? = nil, showSubtitleCheckButton: Bool = false, subTitleMailText: String? = nil) {
        titleLabel.text = titleText
        subTitleLabel.text = subTitleText
        subTitleLabelNoIcon.text = subTitleText
        subTitleMailLabel.text = subTitleMailText

        if subTitleText == nil {
            updateSubtitleStatus(isHidden: true, noIconIsHidden: true)
        } else {
            if showSubtitleCheckButton {
                updateSubtitleStatus(isHidden: false, noIconIsHidden: true)
            } else {
                updateSubtitleStatus(isHidden: true, noIconIsHidden: false)
            }
        }

        subTitleMailLabel.isHidden = subTitleMailText == nil
    }

    func setCheckBoxTitleList(titleText: String, checkBoxTitleList: [String], checkBoxType: EventEdit.NotiOptionCheckBoxType) {
        titleLabel.text = titleText
        subTitleLabel.text = checkBoxTitleList.first
        checkBoxListType = checkBoxType

        switch checkBoxType {
        case .all:
            layoutExtraCheckBoxTitle()
            tirdTitleLabel.text = checkBoxTitleList.last
            setupMultiLineLeftAlignLayout()
        case .doc, .group:
            subTitleLabel.textAlignment = .left
            if preCheckIsMultiLine(subTitleLabel) {
                layoutSubContainer()
            }
        default: break
        }

        updateSubtitleStatus(isHidden: false, noIconIsHidden: true)
    }

    func addAction(actionButton: ActionButton, callBack: @escaping Disappear) {
        self.buttonStackView.addArrangedSubview(actionButton.button)
        actionButton.button.addTopBorder()
        actionButton.button.snp.makeConstraints { (make) in
            make.height.equalTo(50)
        }

        actionButton.button.rx.tap
            .subscribe(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                let checkListVal = self.getCheckBoxListVals()
                let isCheck: Bool?
                if self.checkButton.isHidden {
                    isCheck = nil
                } else {
                    isCheck = self.checkButton.isSelected
                }

                self.checkBoxListCallBack?(checkListVal, self.checkBoxListType)
                actionButton.handler(isCheck, callBack)

        }).disposed(by: disposeBag)
    }

    private func layoutTitleLabels() {
        titleStackView.addArrangedSubview(titleLabel)
        titleLabel.widthAnchor
            .constraint(equalTo: titleStackView.widthAnchor, constant: -20).isActive = true
        titleStackView.addArrangedSubview(subTitleLabelNoIcon)
        subTitleLabelNoIcon.widthAnchor
            .constraint(equalTo: titleStackView.widthAnchor, constant: -40).isActive = true

        titleStackView.addArrangedSubview(subTitleMailLabel)
        subTitleMailLabel.widthAnchor
            .constraint(equalTo: titleStackView.widthAnchor, constant: -40).isActive = true
        titleStackView.addArrangedSubview(multiCheckBoxStackView)
        multiCheckBoxStackView.widthAnchor
            .constraint(equalTo: titleStackView.widthAnchor, constant: -20).isActive = true

        subtitleSubContainer.addSubview(checkButton)
        subtitleSubContainer.addSubview(subTitleLabel)
        subtitleContainer.addSubview(subtitleSubContainer)
        multiCheckBoxStackView.addArrangedSubview(subtitleContainer)

        subtitleSubContainer.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        subtitleSubContainer.snp.makeConstraints { make in
            make.top.bottom.centerX.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }

        checkButton.snp.makeConstraints {(make) in
            make.width.equalTo(20)
            make.height.equalTo(20)
            make.left.top.equalToSuperview()
        }

        subTitleLabel.snp.makeConstraints {(make) in
            make.left.equalTo(checkButton.snp.right).offset(12)
            make.right.lessThanOrEqualToSuperview()
            make.bottom.equalToSuperview()
            make.top.equalToSuperview().offset(0.5)
        }

        subtitleContainer.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(buttonClick))
        tapGesture.numberOfTapsRequired = 1
        subtitleContainer.addGestureRecognizer(tapGesture)
    }

    private func layoutExtraCheckBoxTitle() {
        tirdtitleSubContainer.addSubview(secondCheckButton)
        tirdtitleSubContainer.addSubview(tirdTitleLabel)
        tirdtitleContainer.addSubview(tirdtitleSubContainer)
        multiCheckBoxStackView.addArrangedSubview(tirdtitleContainer)

        tirdtitleSubContainer.snp.makeConstraints { make in
            make.top.bottom.centerX.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }

        secondCheckButton.snp.makeConstraints {(make) in
            make.width.equalTo(20)
            make.height.equalTo(20)
            make.top.left.equalToSuperview()
        }

        tirdTitleLabel.snp.makeConstraints {(make) in
            make.left.equalTo(checkButton.snp.right).offset(12)
            make.top.equalToSuperview().offset(0.5)
            make.right.lessThanOrEqualToSuperview()
            make.bottom.equalToSuperview()
        }

        tirdtitleContainer.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(secondButtonClick))
        tapGesture.numberOfTapsRequired = 1
        tirdtitleContainer.addGestureRecognizer(tapGesture)
    }

    @objc
    private func buttonClick() {
        checkButton.isSelected = !checkButton.isSelected
        self.trackInvitedGroupCheckStatus?(checkButton.isSelected)
    }

    @objc
    private func secondButtonClick() {
        secondCheckButton.isSelected = !secondCheckButton.isSelected
        self.trackMinutesCheckStatus?(secondCheckButton.isSelected)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateSubtitleStatus(isHidden: Bool, noIconIsHidden: Bool) {
        subTitleLabelNoIcon.isHidden = noIconIsHidden
        subtitleContainer.isHidden = isHidden
        subTitleLabel.isHidden = isHidden
        checkButton.isHidden = isHidden
    }

    private func getCheckBoxListVals() -> [Bool] {
        // 默认存放顺序，0.群组 1.纪要
        var checkListVal: [Bool] = []
        var hasSetOnce: Bool = false
        checkBoxListType = .unknown

        if !checkButton.isHidden {
            checkListVal.append(checkButton.isSelected)
            if checkButton.isSelected {
                checkBoxListType = .group
                hasSetOnce = true
            }
        }

        if !secondCheckButton.isHidden {
            checkListVal.append(secondCheckButton.isSelected)
            if secondCheckButton.isSelected {
                checkBoxListType = hasSetOnce ? .all : .doc
            }
        }
        return checkListVal
    }

    private func setupMultiLineLeftAlignLayout() {
        titleLabel.textAlignment = .left
        layoutSubContainer()
        layoutTirdContainer()
    }

    private func layoutSubContainer() {
        subtitleSubContainer.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func layoutTirdContainer() {
        tirdtitleSubContainer.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func preCheckIsMultiLine(_ label: UILabel) -> Bool {
        let textWidth = label.text?.getWidth(font: UIFont.systemFont(ofSize: 16)) ?? 0
        let containerWidth = UDDialog.Layout.dialogWidth - 40 - 12 - 20
        return textWidth > containerWidth
    }
}
