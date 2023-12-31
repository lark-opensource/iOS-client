//
//  BottomConfirmPanel.swift
//  Lark
//
//  Created by ChalrieSu on 18/12/2017.
//  Copyright © 2017 Bytedance.Inc. All rights reserved.
//
//  目前用于发送附件界面，底部显示选中附件数目

import Foundation
import UIKit

final class BottomConfirmPanel: UIView {
    var leftTitle: String = BundleI18n.LarkFile.Lark_Legacy_SendAttachedFileHasSelected {
        didSet {
            updateTitle()
        }
    }
    var sendTitle: String = BundleI18n.LarkFile.Lark_Legacy_Send {
        didSet {
            updateTitle()
        }
    }
    var selectedCount: Int = 0 {
        didSet {
            updateTitle()
        }
    }
    var selectedTotalSize: Int64 = 0
    var selectedTotalSizeString: String {
        let gigaByte = 1024 * 1024 * 1024
        if selectedTotalSize < gigaByte {
            let sizeInMB = Double(selectedTotalSize) / (1024.0 * 1024.0)
            return String(format: "%.2fMB", sizeInMB)
        } else {
            let sizeInGB = Double(selectedTotalSize) / Double(gigaByte)
            return String(format: "%.2fGB", sizeInGB)
        }
    }

    var leftButtonClickedBlock: ((BottomConfirmPanel) -> Void)?
    var rightButtonClickedBlock: ((BottomConfirmPanel) -> Void)?

    private let contentView = UIView()
    private let leftButton = UIButton()
    private let rightButton = UIButton()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.ud.bgBody

        addSubview(contentView)
        contentView.lu.addTopBorder(leading: 0, trailing: 0, color: UIColor.ud.lineDividerDefault)
        contentView.snp.makeConstraints { (make) in
            make.left.top.right.equalToSuperview()
            make.height.equalTo(48)
        }

        contentView.addSubview(leftButton)
        leftButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        leftButton.setTitleColor(UIColor.ud.colorfulBlue, for: .normal)
        leftButton.titleLabel?.textAlignment = .left
        leftButton.addTarget(self, action: #selector(leftButtonClicked), for: .touchUpInside)
        leftButton.snp.makeConstraints { (make) in
            make.left.equalTo(15)
            make.centerY.equalToSuperview()
        }

        contentView.addSubview(rightButton)
        rightButton.setBackgroundImage(UIImage.ud.fromPureColor(UIColor.ud.primaryContentDefault), for: .normal)
        rightButton.setBackgroundImage(UIImage.ud.fromPureColor(UIColor.ud.fillDisabled), for: .disabled)
        rightButton.layer.cornerRadius = 6
        rightButton.layer.masksToBounds = true
        rightButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        rightButton.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        rightButton.isEnabled = false
        rightButton.addTarget(self, action: #selector(rightButtonClicked), for: .touchUpInside)
        rightButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.greaterThanOrEqualTo(75)
            make.height.equalTo(28)
        }
        if let titleLabel = rightButton.titleLabel,
           rightButton.frame.size.width > 75 || rightButton.frame.size.width - titleLabel.frame.size.width < 16 {
            titleLabel.minimumScaleFactor = 0.9
            titleLabel.numberOfLines = 1
            titleLabel.adjustsFontSizeToFitWidth = true
            rightButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
            rightButton.layoutIfNeeded()
        }

        updateTitle()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func leftLabelTitle() -> String {
        let countString = String(format: leftTitle, "\(selectedCount)")
        return String(format: "%@ - %@", countString, selectedTotalSizeString)
    }

    private func rightButtonTitle() -> String {
        if selectedCount > 0 {
            return sendTitle + "(\(selectedCount))"
        } else {
            return sendTitle
        }
    }

    private func updateTitle() {
        leftButton.setTitle(leftLabelTitle(), for: .normal)
        rightButton.setTitle(rightButtonTitle(), for: .normal)
        if selectedCount > 0 {
            rightButton.isEnabled = true
        } else {
            rightButton.isEnabled = false
        }
        setNeedsLayout()
    }

    @objc
    private func leftButtonClicked() {
        if selectedCount > 0 {
            leftButtonClickedBlock?(self)
        }
    }

    @objc
    private func rightButtonClicked() {
        rightButtonClickedBlock?(self)
    }
}
