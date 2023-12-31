//
//  DocsPermissionTableViewCell.swift
//  Lark-Rust
//
//  Created by qihongye on 2018/2/27.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkUIKit
import SnapKit
import RustPB
import LarkMessageCore

public protocol DocPermissionCellProps {
    var messageIds: [String] { get }
    var docUrl: String { get }
    var title: String { get }
    var icon: UIImage? { get }
    var ownerName: String { get }
    var permissionStates: [DocPermissionState] { get }
    var selectedPermisionStateIndex: Int32 { get set }
    var selected: Bool { get set }
    var allowEdit: Bool { get }
}

/// 使用是直接用DocsPermissionCellModel就可以了
final class DocsPermissionTableViewCell: UITableViewCell {
    lazy private var checkbox: Checkbox = {
        let checkbox = Checkbox()
        checkbox.isUserInteractionEnabled = false
        checkbox.lineWidth = 1.5
        checkbox.onCheckColor = UIColor.ud.primaryOnPrimaryFill
        checkbox.offFillColor = UIColor.ud.N300
        checkbox.strokeColor = UIColor.ud.N300
        checkbox.onCheckColor = UIColor.ud.primaryOnPrimaryFill
        checkbox.onTintColor = UIColor.ud.colorfulBlue
        checkbox.onFillColor = UIColor.ud.colorfulBlue
        return checkbox
    }()

    lazy private var icon: UIImageView = {
        let iconView = UIImageView()
        return iconView
    }()

    lazy private var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.N900
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.textAlignment = .left
        return label
    }()

    lazy private var ownerLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.N500
        label.font = UIFont.systemFont(ofSize: 12)
        label.textAlignment = .left
        return label
    }()

    lazy private var switchView: SwitchView = {
        let switchView = SwitchView()
        switchView.backgroundColor = UIColor.ud.N300.withAlphaComponent(0.3)
        switchView.delegate = self
        return switchView
    }()

    lazy private var lineView: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.N300
        return line
    }()

    var props: DocPermissionCellProps? {
        didSet {
            self.checkbox.setOn(on: self.props?.selected ?? false, animated: false)
            self.icon.image = self.props?.icon
            self.titleLabel.text = props?.title
            self.ownerLabel.text = BundleI18n.LarkChat.Lark_Legacy_AuthorizeDocOwner(props?.ownerName ?? "")
            self.switchView.setItems(items: (props?.permissionStates ?? []).map({ ($0.displayNameWithPermissionType(.thirdPerson), UIColor.ud.colorfulBlue) }),
                                     defaultSelectIndex: Int(props?.selectedPermisionStateIndex ?? 0))
            self.switchView.changeEnable = self.props?.allowEdit ?? true
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        self.contentView.addSubview(checkbox)
        self.contentView.addSubview(icon)
        self.contentView.addSubview(titleLabel)
        self.contentView.addSubview(ownerLabel)
        self.contentView.addSubview(switchView)
        self.contentView.addSubview(lineView)

        checkbox.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(10)
            make.width.height.equalTo(24)
            make.centerY.equalToSuperview()
        }
        icon.snp.makeConstraints { (make) in
            make.left.equalTo(checkbox.snp.right).offset(10)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }
        switchView.snp.makeConstraints { (make) in
            make.width.equalTo(114)
            make.height.equalTo(33)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-10)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(icon.snp.right).offset(10)
            make.right.equalTo(switchView.snp.left).offset(5)
            make.height.equalTo(21)
            make.top.equalTo(icon.snp.top)
        }
        ownerLabel.snp.makeConstraints { (make) in
            make.left.equalTo(titleLabel)
            make.height.equalTo(16)
            make.right.equalTo(titleLabel)
            make.bottom.equalTo(icon)
        }
        lineView.snp.makeConstraints { (make) in
            make.bottom.right.equalToSuperview()
            make.left.equalTo(titleLabel)
            make.height.equalTo(1.0 / UIScreen.main.scale)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension DocsPermissionTableViewCell: SwitchViewDelegate {
    func didTap(index: Int) {
        self.props?.selectedPermisionStateIndex = Int32(index)
    }
}

public protocol SwitchViewDelegate: AnyObject {
    func didTap(index: Int)
}

open class SwitchView: UIView {
    private var items: [(title: String, selectedColor: UIColor)] = []

    private let defaultTitleColor = UIColor.ud.N500
    private var lastTappedButton: UIButton?
    private var buttonCoverView: UIView = .init()
    private var buttons: [UIButton] = []

    public var isEnabled: Bool = true {
        didSet {
            buttons.forEach { (button) in
                button.isEnabled = isEnabled
            }
        }
    }

    public var changeEnable: Bool = true
    public weak var delegate: SwitchViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.N300
        self.layer.cornerRadius = 3
        self.layer.masksToBounds = true

        buttonCoverView = UIView()
        buttonCoverView.backgroundColor = UIColor.ud.N00
        buttonCoverView.layer.cornerRadius = 2
        buttonCoverView.layer.masksToBounds = true
        self.addSubview(buttonCoverView)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setItems(items: [(title: String, selectedColor: UIColor)], defaultSelectIndex: Int = 0) {
        assert(defaultSelectIndex >= 0 && defaultSelectIndex < items.count)
        getButtonsInView().forEach { $0.removeFromSuperview() }
        if items.isEmpty {
            return
        }
        self.buttons = []
        self.items = items
        var lastButton: UIButton?
        for (index, item) in items.enumerated() {
            let button = buildButtonItem(title: item.title)
            button.tag = index
            self.addSubview(button)
            buttons.append(button)
            button.snp.makeConstraints({ (make) in
                make.top.equalToSuperview().offset(4)
                make.bottom.equalToSuperview().offset(-4)
                make.left.equalTo(lastButton?.snp.right ?? 4)
                make.width.equalTo(53)
                if index == items.count - 1 {
                    make.right.equalTo(-4)
                }
            })
            lastButton = button
            if defaultSelectIndex == index {
                lastTappedButton = button
                button.setTitleColor(item.selectedColor, for: .normal)
                buttonCoverView.snp.remakeConstraints({ (make) in
                    make.width.equalTo(53)
                    make.height.equalTo(25.5)
                    make.center.equalTo(button)
                })
            }
        }
    }

    private func getButtonsInView() -> [UIButton] {
        var buttons: [UIButton] = []
        self.subviews.forEach { (buttonView) in
            if let button = buttonView as? UIButton {
                buttons.append(button)
            }
        }
        return buttons
    }

    @objc
    private func didTapButton(_ button: UIButton) {
        guard button.tag != lastTappedButton?.tag, changeEnable else {
            return
        }
        lastTappedButton?.setTitleColor(defaultTitleColor, for: .normal)
        button.setTitleColor(items[button.tag].selectedColor, for: .normal)
        lastTappedButton = button
        buttonCoverView.snp.remakeConstraints { (make) in
            make.width.equalTo(53)
            make.height.equalTo(25.5)
            make.center.equalTo(button)
        }
        UIView.animate(withDuration: 0.25) {
            self.layoutIfNeeded()
        }
        delegate?.didTap(index: button.tag)
    }

    private func buildButtonItem(title: String) -> UIButton {
        let button = UIButton(type: .custom)
        button.setTitle(title, for: .normal)
        button.setTitleColor(defaultTitleColor, for: .normal)
        button.setTitleColor(defaultTitleColor, for: .disabled)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        button.addTarget(self, action: #selector(didTapButton(_:)), for: .touchUpInside)
        return button
    }
}
