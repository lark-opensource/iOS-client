//
//  InviteCollaboratorsPanel.swift
//  SKBrowser
//
//  Created by liweiye on 2020/10/27.
//

import UIKit
import Foundation
import SnapKit
import SKResource
import SKUIKit
import UniverseDesignIcon
import UniverseDesignColor

protocol InviteCollaboratorsPanelDelegate: AnyObject {
    func didTapSearchTextFiled(panel: InviteCollaboratorsPanel)
}

class InviteCollaboratorsPanel: UIControl {

    weak var delegate: InviteCollaboratorsPanelDelegate?

    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.tintColor = UDColor.iconN1
        view.image = UDIcon.memberAddOutlined.withRenderingMode(.alwaysTemplate)
        return view
    }()

    private(set) lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .left
        label.textColor = UDColor.textTitle
        return label
    }()

    private(set) lazy var moreIconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.image = UDIcon.rightOutlined.withRenderingMode(.alwaysTemplate)
        view.tintColor = UDColor.textPlaceholder
        return view
    }()

    private lazy var bottomSeperatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()

    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                backgroundColor = UDColor.fillPressed
            } else {
                backgroundColor = UDColor.bgFloat
            }
        }
    }

    // 邀请协作者数据是否 ready, 与自带的 isEnabled 作区分
    var panelEnabled: Bool = false {
        didSet {
            isEnabled = true
            updateUI()
        }
    }

//    // 仅在关闭表单分享时，忽略协作者数据状态强制禁用处理
//    override var isEnabled: Bool {
//        didSet {
//            panelEnabled = false
//        }
//    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isEnabled = false
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        isEnabled = false
        setupUI()
    }

    private func setupUI() {
        backgroundColor = UDColor.bgFloat
        addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview().inset(16)
            make.width.height.equalTo(20)
            make.top.bottom.equalTo(16)
        }
        addSubview(titleLabel)
        addSubview(moreIconView)

        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(iconView.snp.right).offset(12)
            make.centerY.equalTo(iconView)
            make.right.lessThanOrEqualTo(moreIconView.snp.left).offset(-12)
        }

        moreIconView.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(16)
            make.width.height.equalTo(20)
            make.centerY.equalToSuperview()
        }

        addSubview(bottomSeperatorView)
        bottomSeperatorView.snp.makeConstraints { (make) in
            make.left.equalTo(iconView)
            make.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
        updateUI()
        addTarget(self, action: #selector(handleClickEvent), for: .touchUpInside)
    }

    @objc
    private func handleClickEvent() {
        delegate?.didTapSearchTextFiled(panel: self)
    }

    private func updateUI() {
        if panelEnabled {
            iconView.tintColor = UDColor.iconN1
            titleLabel.textColor = UDColor.textTitle
            moreIconView.tintColor = UDColor.textPlaceholder
        } else {
            iconView.tintColor = UDColor.iconDisabled
            titleLabel.textColor = UDColor.textDisabled
            moreIconView.tintColor = UDColor.iconDisabled
        }
    }
}
