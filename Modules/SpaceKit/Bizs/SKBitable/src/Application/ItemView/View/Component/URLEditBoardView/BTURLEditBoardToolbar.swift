//
//  BTURLEditBoardToolbar.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/4/18.
//  


import SKCommon
import SKUIKit
import SKResource
import UniverseDesignColor
import UniverseDesignIcon


final class BTURLEditBoardToolBar: UIView {

    var didPressClose: (() -> Void)?
    
    var didPressComplete: (() -> Void)?

    private lazy var completeBtn: UIButton = {
        let btn = UIButton()
        btn.setTitle(BundleI18n.SKResource.Bitable_BTModule_Done, for: .normal)
        btn.setTitleColor(UDColor.primaryContentDefault, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        btn.addTarget(self, action: #selector(completeBtnPressed), for: .touchUpInside)
        return btn
    }()

    private lazy var closeBtn: UIButton = {
        let btn = UIButton()
        btn.setImage(UDIcon.closeSmallOutlined.ud.resized(to: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysTemplate), for: .normal)
        btn.tintColor = UDColor.iconN1
        btn.addTarget(self, action: #selector(closeBtnPressed), for: .touchUpInside)
        return btn
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.SKResource.Bitable_Field_Hyperlink
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayouts()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    private func completeBtnPressed() {
        didPressComplete?()
    }

    @objc
    private func closeBtnPressed() {
        didPressClose?()
    }

    private func setupViews() {
        titleLabel.textAlignment = .center
        self.addSubview(closeBtn)
        self.addSubview(completeBtn)
        self.addSubview(titleLabel)
    }

    private func setupLayouts() {
        closeBtn.snp.makeConstraints {
            $0.left.equalToSuperview()
            $0.width.equalTo(56)
            $0.height.equalTo(24)
            $0.top.equalToSuperview().inset(14)
        }

        completeBtn.snp.makeConstraints {
            $0.right.equalToSuperview()
            $0.width.equalTo(56)
            $0.height.equalTo(24)
            $0.top.equalToSuperview().inset(14)
        }

        titleLabel.snp.makeConstraints {
            $0.left.equalTo(closeBtn)
            $0.right.equalTo(completeBtn)
            $0.centerY.equalTo(closeBtn)
        }
    }
}
