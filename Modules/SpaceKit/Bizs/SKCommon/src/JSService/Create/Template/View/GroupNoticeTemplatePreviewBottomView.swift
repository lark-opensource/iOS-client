//
//  GroupNoticeTemplatePreviewBottomView.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2021/6/19.
//  


import SKUIKit
import UniverseDesignColor
import SKResource
import UniverseDesignIcon
import UIKit
import SnapKit

class GroupNoticeTemplatePreviewBottomView: UIView {
    private lazy var previousIconView: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.leftOutlined.withRenderingMode(.alwaysTemplate)
        view.contentMode = .scaleAspectFit
        view.tintColor = UDColor.iconN1
        return view
    }()

    private lazy var previousLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = UDColor.textTitle
        return label
    }()

    private(set) lazy var previousControl: UIControl = {
        let control = UIControl()
        control.backgroundColor = .clear
        return control
    }()

    var previousEnabled: Bool = true {
        didSet {
            let imageColor = previousEnabled ? UDColor.iconN1 : UDColor.iconDisabled
            let textColor = previousEnabled ? UDColor.textTitle : UDColor.textDisabled
            previousIconView.tintColor = imageColor
            previousLabel.textColor = textColor
            previousControl.isEnabled = previousEnabled
        }
    }

    private lazy var nextIconView: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.rightOutlined.withRenderingMode(.alwaysTemplate)
        view.contentMode = .scaleAspectFit
        view.tintColor = UDColor.iconN1
        return view
    }()

    private lazy var nextLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = UDColor.textTitle
        return label
    }()

    private(set) lazy var nextControl: UIControl = {
        let control = UIControl()
        control.backgroundColor = .clear
        return control
    }()

    var nextEnabled: Bool = true {
        didSet {
            let imageColor = nextEnabled ? UDColor.iconN1 : UDColor.iconDisabled
            let textColor = nextEnabled ? UDColor.textTitle : UDColor.textDisabled
            nextIconView.tintColor = imageColor
            nextLabel.textColor = textColor
            nextControl.isEnabled = nextEnabled
        }
    }

    let iconImageView: UIImageView = UIImageView()
    let titleLabel: UILabel = UILabel().construct { it in
        it.textColor = UDColor.textTitle
        it.font = .docs.pfsc(16)
    }
    private lazy var titleContainerView: UIView = UIView().construct { it in
        it.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.leading.centerY.equalToSuperview()
        }
        it.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing)
            make.trailing.centerY.equalToSuperview()
        }
    }
    let useButton: UIButton = UIButton(type: .custom).construct { it in
        it.backgroundColor = UDColor.primaryContentDefault
        it.layer.cornerRadius = 6
        it.setTitle(BundleI18n.SKResource.CreationMobile_Operation_UseThisTemplate, for: .normal)
        it.setTitleColor(UDColor.primaryOnPrimaryFill, for: .normal)
        it.titleLabel?.font = .docs.pfsc(17)
    }
    let needButtonTitle: Bool
    
    init(needButtonTitle: Bool = false) {
        self.needButtonTitle = needButtonTitle
        super.init(frame: .zero)
        setupSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubviews() {
        backgroundColor = UDColor.bgBody
        layer.ud.setShadowColor(UDColor.shadowDefaultSm)
        layer.shadowOffset = CGSize(width: 0, height: -2)
        layer.shadowOpacity = 1
        layer.shadowRadius = 6
        
        if needButtonTitle {
            previousLabel.text = BundleI18n.SKResource.CreationMobile_Template_Previous
            nextLabel.text = BundleI18n.SKResource.CreationMobile_Template_Next
        }

        addSubview(previousControl)
        previousControl.addSubview(previousIconView)
        previousControl.addSubview(previousLabel)
        previousIconView.snp.makeConstraints { make in
            make.width.height.equalTo(22)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
        }
        previousLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(previousIconView.snp.right).offset(4)
            make.right.equalToSuperview()
        }
        previousControl.snp.makeConstraints { make in
            make.top.left.equalToSuperview()
            make.height.equalTo(55)
        }

        addSubview(nextControl)
        nextControl.addSubview(nextIconView)
        nextControl.addSubview(nextLabel)
        nextIconView.snp.makeConstraints { make in
            make.width.height.equalTo(22)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
        }
        nextLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalTo(nextIconView.snp.left).offset(-4)
            make.left.equalToSuperview()
        }
        nextControl.snp.makeConstraints { make in
            make.top.right.equalToSuperview()
            make.height.equalTo(55)
        }

        addSubview(titleContainerView)
        titleContainerView.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.height.equalTo(previousControl)
            make.left.greaterThanOrEqualTo(previousControl.snp.right)
            make.right.lessThanOrEqualTo(nextControl.snp.left)
        }
        
        let line = UIView()
        line.backgroundColor = UDColor.lineDividerDefault
        addSubview(line)
        line.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(0.5)
            make.top.equalTo(previousControl.snp.bottom)
        }
        
        addSubview(useButton)
        useButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalTo(line.snp.bottom).offset(16)
            make.height.equalTo(46)
        }
    }
}
