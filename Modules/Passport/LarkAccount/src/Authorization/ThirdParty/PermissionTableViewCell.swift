//
//  PermissionTableViewCell.swift
//  LarkQRCode
//
//  Created by Miaoqi Wang on 2020/3/13.
//

import UIKit
import SnapKit
import UniverseDesignCheckBox

struct DisplayScope {
    let key: String
    let text: String
    let required: Bool
    var selected: Bool
}

class PermissionTableViewCell: UITableViewCell {

    private let contentLabel: UILabel
    private let iconView: UIView = UIView()

    private var dotView: UIView?
    private var checkBox: UDCheckBox?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 14.0)
        self.contentLabel = label

        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        contentView.addSubview(iconView)
        contentView.addSubview(contentLabel)

        iconView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }

        contentLabel.snp.makeConstraints { (make) in
            make.left.equalTo(iconView.snp.right).offset(Layout.iconRight)
            make.top.greaterThanOrEqualToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
            make.centerY.equalToSuperview()
            make.right.equalToSuperview()
        }

        setCell(scope: DisplayScope(key: "", text: "", required: false, selected: false), needCheck: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setCell(scope: DisplayScope, needCheck: Bool) {
        self.contentLabel.text = scope.text
        if needCheck {
            addCheckBoxIfNeed()
            if scope.required {
                checkBox?.isSelected = true
                checkBox?.isEnabled = false
            } else {
                checkBox?.isEnabled = true
                checkBox?.isSelected = scope.selected
            }
        } else {
            addDotIfNeed()
        }
    }

    func addCheckBoxIfNeed() {
        dotView?.removeFromSuperview()
        dotView = nil
        if checkBox == nil {
            let cBox = UDCheckBox(boxType: .multiple)
            cBox.isUserInteractionEnabled = false
            iconView.addSubview(cBox)
            cBox.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
                make.size.equalTo(Layout.checkBoxSize)
            }
            checkBox = cBox
        }
    }

    func addDotIfNeed() {
        checkBox?.removeFromSuperview()
        checkBox = nil
        if dotView == nil {
            let dot = UIView()
            dot.backgroundColor = UIColor.ud.textCaption
            dot.layer.cornerRadius = Layout.dotSize.width / 2
            iconView.addSubview(dot)
            dot.snp.makeConstraints { (make) in
                make.size.equalTo(Layout.dotSize)
                make.centerY.equalToSuperview()
                make.left.equalToSuperview().offset(Layout.dotLeft)
                make.right.equalToSuperview()
            }
            dotView = dot
        }
    }
}

extension PermissionTableViewCell {
    private enum Layout {
        static let dotSize: CGSize = CGSize(width: 4.0, height: 4.0)
        static let dotLeft: CGFloat = 8
        static let iconRight: CGFloat = 12
        static let checkBoxSize: CGSize = CGSize(width: 18, height: 18)
    }
}
