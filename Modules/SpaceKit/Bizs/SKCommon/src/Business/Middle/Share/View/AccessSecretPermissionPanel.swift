//
//  AccessSecretPermissionPanel.swift
//  SKCommon
//
//  Created by tanyunpeng on 2023/4/19.
//  


import UIKit
import Foundation
import SnapKit
import SKResource
import SKUIKit
import UniverseDesignIcon
import UniverseDesignColor


class AccessSecretPermissionPanel: UIControl {

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
        backgroundColor = UDColor.bgBody
        addSubview(titleLabel)
        addSubview(moreIconView)

        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview().inset(13)

            make.height.equalTo(22)
            make.centerY.equalToSuperview()
        }

        moreIconView.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(16)
            make.width.height.equalTo(12)
            make.centerY.equalToSuperview()
        }

        updateUI()
    }

    private func updateUI() {
        if true {
            backgroundColor = UDColor.bgBody
        } else {
            backgroundColor = UDColor.fillHover
        }
    }
}

