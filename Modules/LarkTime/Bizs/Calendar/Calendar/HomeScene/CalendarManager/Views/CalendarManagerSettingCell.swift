//
//  CalendarManagerViewSettingCell.swift
//  Calendar
//
//  Created by harry zou on 2019/3/22.
//

import UIKit
import Foundation
import CalendarFoundation
import SnapKit
import UniverseDesignIcon

final class CalendarManagerSettingCell: UIControl, AddBottomLineAble {
    private var icon: UIImageView
    private let contextLabel = UILabel.cd.textLabel()
    private var tailIcon = UIImageView()
    private let placeHolder: String?

    init(iconImage: UIImage?, title: String, placeHolder: String? = nil) {
        self.icon = UIImageView(image: iconImage)
        self.tailIcon = UIImageView(image: UDIcon.getIconByKeyNoLimitSize(.rightOutlined).renderColor(with: .n3))
        self.placeHolder = placeHolder
        super.init(frame: .zero)
        backgroundColor = UIColor.ud.bgBody
        contextLabel.numberOfLines = 3
        contextLabel.text = title
        layout(icon: icon)
        layout(tail: tailIcon)
        layout(label: contextLabel, leftItem: icon.snp.right, rightItem: tailIcon.snp.left, offset: -4)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layout(icon: UIView) {
        addSubview(icon)
        icon.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(18)
            make.width.height.equalTo(16)
        }
    }

    private func layout(label: UIView, leftItem: ConstraintItem, rightItem: ConstraintItem, offset: ConstraintOffsetTarget) {
        addSubview(label)
        label.snp.remakeConstraints { (make) in
            make.top.equalToSuperview().offset(15)
            make.bottom.equalToSuperview().offset(-15)
            make.left.equalTo(leftItem).offset(18)
            make.right.lessThanOrEqualTo(rightItem).offset(offset)
        }
    }

    private func layout(tail: UIView) {
        addSubview(tail)
        tail.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-16)
            make.width.height.equalTo(12)
        }
    }

    func updateTitle(with context: String, showDisabledColor: Bool = false) {
        if context.isEmpty, let holder = placeHolder {
            contextLabel.text = holder
            contextLabel.textColor = UIColor.ud.textPlaceholder
        } else {
            contextLabel.text = context
            if showDisabledColor {
                contextLabel.textColor = UIColor.ud.textDisable
            } else {
                contextLabel.textColor = UIColor.ud.N800
            }
        }
        if !isEnabled {
            contextLabel.textColor = UIColor.ud.textDisable
        }
    }

    func isTitleTruncated() -> Bool {
        return self.contextLabel.isTruncated
    }

    func updateTail(isHidden: Bool) {
        tailIcon.isHidden = isHidden
    }

    func update(isHidden: Bool) {
        tailIcon.isHidden = isHidden
    }

    override var isEnabled: Bool {
        didSet {
            contextLabel.textColor = isEnabled ? UIColor.ud.N800 : UIColor.ud.textDisable
        }
    }

    func updateIcon(with color: UIColor) {
        self.icon.layer.cornerRadius = 8
        self.icon.backgroundColor = color
    }
}
