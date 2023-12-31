//
//  EventEditNotiCheckBoxListView.swift
//  Calendar
//
//  Created by pluto on 2022/12/30.
//

import UIKit
import Foundation
import UniverseDesignCheckBox
import UniverseDesignDialog

final class EventEditNotiCheckBoxListView: UIView {

    var trackInvitedGroupCheckStatus: ((Bool) -> Void)?
    var trackMinutesCheckStatus: ((Bool) -> Void)?

    private let groupInveitedLabel: UILabel = {
        let label = UILabel.cd.subTitleLabel(fontSize: 16)
        label.textColor = UIColor.ud.textTitle
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .left
        return label
    }()

    private let minutesTitleLabel: UILabel = {
        let label = UILabel.cd.subTitleLabel(fontSize: 16)
        label.textColor = UIColor.ud.textTitle
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .left
        return label
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

    private let multiCheckBoxStackView: UIStackView = {
        let view = UIStackView()
        view.backgroundColor = .clear
        view.axis = .vertical
        view.spacing = 12.0
        return view
    }()

    private let groupInvitedContainer = UIView()
    private let groupInvitedSubContainer = UIView()

    private let minutesContainer = UIView()
    private let minutesSubContainer = UIView()

    private let checkBoxTitleList: [String]
    private var checkBoxListType: EventEdit.NotiOptionCheckBoxType

    init(checkBoxTitleList: [String], checkBoxType: EventEdit.NotiOptionCheckBoxType) {
        self.checkBoxTitleList = checkBoxTitleList
        self.checkBoxListType = checkBoxType
        super.init(frame: .zero)
        layoutStackView()
        layoutGroupInviteCheckBox()
        layoutMinutesCheckBox()
        layoutCheckBoxList(checkBoxTitleList: checkBoxTitleList, checkBoxType: checkBoxType)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutStackView() {
        addSubview(multiCheckBoxStackView)
        multiCheckBoxStackView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalToSuperview()
        }
    }

    private func layoutCheckBoxList(checkBoxTitleList: [String], checkBoxType: EventEdit.NotiOptionCheckBoxType) {
        switch checkBoxType {
        case .all:
            if let titleText = checkBoxTitleList.first {
                groupInvitedContainer.isHidden = false
                groupInveitedLabel.text = titleText
                layoutGroupContainer()
            }

            if let titleText = checkBoxTitleList.last {
                minutesContainer.isHidden = false
                minutesTitleLabel.text = titleText
                layoutMinutesContainer()
            }
        case .doc:
            groupInvitedContainer.isHidden = true
            if let titleText = checkBoxTitleList.first {
                minutesContainer.isHidden = false
                minutesTitleLabel.text = titleText
                minutesTitleLabel.textAlignment = .left
                if preCheckIsMultiLine(minutesTitleLabel) {
                    layoutMinutesContainer()
                }
            }

        case .group:
            minutesContainer.isHidden = true
            if let titleText = checkBoxTitleList.first {
                groupInvitedContainer.isHidden = false
                groupInveitedLabel.text = titleText
                groupInveitedLabel.textAlignment = .left
                if preCheckIsMultiLine(groupInveitedLabel) {
                    layoutGroupContainer()
                }
            }
        default: break
        }
    }

    private func layoutGroupInviteCheckBox() {
        groupInvitedSubContainer.addSubview(checkButton)
        groupInvitedSubContainer.addSubview(groupInveitedLabel)
        groupInvitedContainer.addSubview(groupInvitedSubContainer)
        multiCheckBoxStackView.addArrangedSubview(groupInvitedContainer)

        groupInvitedSubContainer.snp.makeConstraints { make in
            make.top.bottom.centerX.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }

        checkButton.snp.makeConstraints {(make) in
            make.width.equalTo(20)
            make.height.equalTo(20)
            make.left.top.equalToSuperview()
        }

        groupInveitedLabel.snp.makeConstraints {(make) in
            make.left.equalTo(checkButton.snp.right).offset(12)
            make.top.equalToSuperview().offset(0.5)
            make.right.bottom.equalToSuperview()
        }
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(buttonClick))
        tapGesture.numberOfTapsRequired = 1
        groupInvitedContainer.addGestureRecognizer(tapGesture)
        groupInvitedContainer.isUserInteractionEnabled = true
    }

    private func layoutMinutesCheckBox() {
        minutesSubContainer.addSubview(secondCheckButton)
        minutesSubContainer.addSubview(minutesTitleLabel)
        minutesContainer.addSubview(minutesSubContainer)
        multiCheckBoxStackView.addArrangedSubview(minutesContainer)

        minutesSubContainer.snp.makeConstraints { make in
            make.top.bottom.centerX.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }

        secondCheckButton.snp.makeConstraints {(make) in
            make.width.equalTo(20)
            make.height.equalTo(20)
            make.left.top.equalToSuperview()
        }

        minutesTitleLabel.snp.makeConstraints {(make) in
            make.left.equalTo(checkButton.snp.right).offset(12)
            make.top.equalToSuperview().offset(0.5)
            make.right.bottom.equalToSuperview()
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(secondButtonClick))
        tapGesture.numberOfTapsRequired = 1
        minutesContainer.addGestureRecognizer(tapGesture)
        minutesContainer.isUserInteractionEnabled = true
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

    func getCheckBoxListVals() -> ([Bool], EventEdit.NotiOptionCheckBoxType) {
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
        return (checkListVal, checkBoxListType)
    }

    private func layoutGroupContainer() {
        groupInvitedSubContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func layoutMinutesContainer() {
        minutesSubContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func preCheckIsMultiLine(_ label: UILabel) -> Bool {
        let textWidth = label.text?.getWidth(font: UIFont.systemFont(ofSize: 16)) ?? 0
        // Dialog宽度 - view 边距 - checkBox边距 - checkboxSize
        let containerWidth = UDDialog.Layout.dialogWidth - 40 - 12 - 20
        return textWidth > containerWidth
    }
}
