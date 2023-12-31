//
//  MinutesHomeFiletrPanel.swift
//  Minutes
//
//  Created by sihuahao on 2021/7/13.
//

import Foundation
import UniverseDesignIcon

public protocol FilterPanelDelegate: AnyObject {
    func dismissSelector()
    func resetFilterPanel()
    func confirmAction()
}

class MinutesHomeFiletrPanel: UIView {

    weak var delegate: FilterPanelDelegate?

    private lazy var selectorTitleLabel: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.text = BundleI18n.Minutes.MMWeb_M_Filter_Dropdown
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        return label
    }()

    private lazy var closeIcon: UIImageView = {
        let imageView: UIImageView = UIImageView(frame: CGRect.zero)
        imageView.image = UDIcon.getIconByKey(.closeSmallOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 20, height: 20))
        imageView.contentMode = .center
        imageView.isUserInteractionEnabled = true
        return imageView
    }()

    private lazy var selectConfirm: UIButton = {
        let button = UIButton()
        button.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        button.backgroundColor = UIColor.ud.primaryContentDefault
        button.titleLabel?.font = .systemFont(ofSize: 17)
        button.layer.cornerRadius = 6
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.ud.primaryContentDefault.cgColor
        button.setTitle(BundleI18n.Minutes.MMWeb_M_Filter_ConfirmButton, for: .normal)
        button.adjustsImageWhenHighlighted = true
        return button
    }()

    private lazy var selectReset: UIButton = {
        let button = UIButton()
        button.setTitleColor(UIColor.ud.textDisabled, for: .normal)
        button.backgroundColor = UIColor.ud.bgBody
        button.titleLabel?.font = .systemFont(ofSize: 17)
        button.setTitle(BundleI18n.Minutes.MMWeb_M_Filter_ResetButton, for: .normal)
        button.layer.cornerRadius = 6
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.ud.lineBorderComponent.cgColor
        return button
    }()

    private lazy var tapCloseGestureRecognizer: UITapGestureRecognizer = {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleCloseTapGesture))
        return tapGestureRecognizer
    }()

    private lazy var tapResetGestureRecognizer: UITapGestureRecognizer = {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleResetTapGesture))
        return tapGestureRecognizer
    }()

    private lazy var tapConfirmGestureRecognizer: UITapGestureRecognizer = {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleConfirmTapGesture))
        return tapGestureRecognizer
    }()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(isRegular: Bool) {
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.bgBody
        self.layer.cornerRadius = 12
        closeIcon.addGestureRecognizer(tapCloseGestureRecognizer)
        selectReset.addGestureRecognizer(tapResetGestureRecognizer)
        selectConfirm.addGestureRecognizer(tapConfirmGestureRecognizer)
        addSubview(selectorTitleLabel)
        addSubview(selectReset)
        addSubview(selectConfirm)
        if isRegular {
            selectorTitleLabel.snp.makeConstraints { maker in
                maker.top.equalToSuperview().offset(16)
                maker.left.equalToSuperview().offset(16)
                maker.height.equalTo(22)
            }

            selectReset.snp.makeConstraints { maker in
                maker.left.equalToSuperview().offset(16)
                maker.width.equalTo(164)
                maker.bottom.equalToSuperview().inset(16)
                maker.right.equalTo(selectorTitleLabel.snp.centerX).inset(8)
                maker.height.equalTo(50)
            }

            selectConfirm.snp.makeConstraints { maker in
                maker.right.equalToSuperview().inset(16)
                maker.width.equalTo(164)
                maker.bottom.equalToSuperview().inset(16)
                maker.left.equalTo(selectorTitleLabel.snp.centerX).offset(8)
                maker.height.equalTo(50)
            }
        } else {
            addSubview(closeIcon)
            selectorTitleLabel.snp.makeConstraints { maker in
                maker.top.equalToSuperview().offset(14)
                maker.centerX.equalToSuperview()
                maker.height.equalTo(24)
            }

            closeIcon.snp.makeConstraints { maker in
                maker.centerY.equalTo(selectorTitleLabel.snp.centerY)
                maker.left.equalToSuperview().inset(6)
                maker.width.height.equalTo(40)
            }

            let sep1 = UIView()
            sep1.backgroundColor = UIColor.ud.lineDividerDefault
            addSubview(sep1)
            sep1.snp.makeConstraints { (maker) in
                maker.left.right.equalToSuperview()
                maker.top.equalTo(selectorTitleLabel.snp.bottom).offset(10)
                maker.height.equalTo(0.5)
            }

            selectReset.snp.makeConstraints { maker in
                maker.left.equalToSuperview().offset(16)
                maker.bottom.equalToSuperview().inset(42)
                maker.right.equalTo(selectorTitleLabel.snp.centerX).inset(8)
                maker.height.equalTo(48)
            }

            selectConfirm.snp.makeConstraints { maker in
                maker.right.equalToSuperview().inset(16)
                maker.bottom.equalToSuperview().inset(42)
                maker.left.equalTo(selectorTitleLabel.snp.centerX).offset(8)
                maker.height.equalTo(48)
            }
        }
    }

    func setResetBtnStyle(resetStatus: Bool) {
        if resetStatus {
            selectReset.setTitleColor(UIColor.ud.textDisabled, for: .normal)
            selectReset.layer.borderColor = UIColor.ud.textDisabled.cgColor
        } else {
            selectReset.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
            selectReset.layer.borderColor = UIColor.ud.primaryContentDefault.cgColor
        }
    }

    @objc
    private func handleCloseTapGesture() {
        self.delegate?.dismissSelector()
    }

    @objc
    private func handleResetTapGesture() {
        self.setResetBtnStyle(resetStatus: true)
        self.delegate?.resetFilterPanel()
    }

    @objc
    private func handleConfirmTapGesture() {
        self.delegate?.confirmAction()
    }

}
