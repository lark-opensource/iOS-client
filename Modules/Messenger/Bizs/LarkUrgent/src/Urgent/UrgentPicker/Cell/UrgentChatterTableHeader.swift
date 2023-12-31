//
//  UrgentChatterTableHeader.swift
//  LarkUrgent
//
//  Created by bytedance on 2020/6/19.
//

import UIKit
import Foundation
import LarkUIKit
import UniverseDesignCheckBox

public protocol UrgentChatterTableHeaderDelegate: AnyObject {
    // 选中全部未读用户
    func onAllUnreadChattersSelected()
    // 取消选中全部未读用户
    func onAllUnreadChattersDeselected()
}

extension UrgentChatterTableHeaderDelegate {
    public func onAllUnreadChattersSelected() { }
    public func onAllUnreadChattersDeselected() { }
}

final class UrgentChatterTableHeader: UIView {
    weak var delegate: UrgentChatterTableHeaderDelegate?

    /// 选择未读用户 CheckBox
    private lazy var checkBox: UDCheckBox = {
        let checkBox = UDCheckBox(boxType: .multiple)
        checkBox.isUserInteractionEnabled = false
        return checkBox
    }()

    /// 选择未读用户 Label
    private lazy var selectUnreadLabel: UILabel = {
        let selectUnreadLabel = UILabel()
        selectUnreadLabel.textColor = UIColor.ud.N900
        selectUnreadLabel.font = UIFont.systemFont(ofSize: 16)
        selectUnreadLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        selectUnreadLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        selectUnreadLabel.text = BundleI18n.LarkUrgent.Lark_buzz_SelectUnreadMembers
        return selectUnreadLabel
    }()

    var isCheckboxSelected: Bool {
        get { return self.checkBox.isSelected }
        set { self.checkBox.isSelected = newValue }
    }

    var isEnabled: Bool {
        get {
            return self.checkBox.isEnabled
        }
        set {
            self.checkBox.isEnabled = newValue
            self.selectUnreadLabel.textColor = newValue ? UIColor.ud.N900 : UIColor.ud.N400
        }
    }

    init() {
        super.init(frame: .zero)

        self.backgroundColor = UIColor.ud.N50
        self.lu.addTopBorder()
        self.lu.addBottomBorder()
        self.lu.addTapGestureRecognizer(action: #selector(didTapView), target: self, touchNumber: 1)

        let header = UIView()
        header.backgroundColor = UIColor.ud.bgBody
        header.lu.addTopBorder()
        header.lu.addBottomBorder()

        self.addSubview(header)
        header.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(50)
        }

        header.addSubview(self.checkBox)
        self.checkBox.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(18)
            make.left.equalTo(10)
        }

        header.addSubview(self.selectUnreadLabel)
        selectUnreadLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(self.checkBox.snp.right).offset(16)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func didTapView() {
        if isCheckboxSelected {
            self.delegate?.onAllUnreadChattersDeselected()
        } else {
            self.delegate?.onAllUnreadChattersSelected()
        }
    }
}
