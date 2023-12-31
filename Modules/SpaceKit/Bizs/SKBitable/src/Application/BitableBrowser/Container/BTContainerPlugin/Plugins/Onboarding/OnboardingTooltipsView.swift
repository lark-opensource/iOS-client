//
//  OnboardingTooltipsView.swift
//  SKBitable
//
//  Created by yinyuan on 2023/9/8.
//

import UIKit
import SKResource
import UniverseDesignShadow
import UniverseDesignColor
import UniverseDesignIcon
import LarkUIKit

class OnboardingTooltipsView: UIView {
    
    private lazy var caretImageView: UIImageView = {
        let view = UIImageView()
        view.image = BundleResources.SKResource.Bitable.tooltip_caret
        view.contentMode = .scaleToFill
        return view
    }()
    
    private lazy var mainView: UIStackView = {
        let leftSpacing = UIView()
        let rightSpacing = UIView()
        
        let view = UIStackView(arrangedSubviews: [leftSpacing, lable, closeButton, rightSpacing])
        view.axis = .horizontal
        view.alignment = .center
        view.distribution = .fill
        view.spacing = 4
        
        leftSpacing.snp.makeConstraints { make in
            make.width.equalTo(12)
        }
        
        rightSpacing.snp.makeConstraints { make in
            make.width.equalTo(12)
        }
        
        closeButton.snp.makeConstraints { make in
            make.width.height.equalTo(12)
        }
        
        lable.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(20)
        }
        
        return view
    }()
    
    lazy var lable: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 12)
        view.textColor = UDColor.staticWhite
        return view
    }()
    
    lazy var closeButton: UIButton = {
        let view = UIButton()
        view.setImage(UDIcon.closeOutlined.ud.withTintColor(UDColor.staticWhite), for: .normal)
        // 扩大点击范围
        view.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        self.layer.ud.setShadow(type: .s4Down)
        
        addSubview(caretImageView)
        caretImageView.snp.makeConstraints { make in
            make.width.equalTo(24)
            make.height.equalTo(6)
            make.left.equalToSuperview().offset(20)
            make.top.equalToSuperview()
        }
        
        addSubview(mainView)
        mainView.snp.makeConstraints { make in
            make.top.equalTo(caretImageView.snp.bottom)
            make.height.equalTo(lable.snp.height).offset(16)
        }
        
        self.snp.makeConstraints { make in
            make.top.equalTo(caretImageView.snp.top)
            make.bottom.equalTo(mainView.snp.bottom)
            make.left.equalTo(mainView.snp.left)
            make.right.equalTo(mainView.snp.right)
        }
        
        let cornerRadius: CGFloat = 8
        mainView.backgroundColor = BTContainer.Constaints.onboardingTipsBackground
        mainView.layer.cornerRadius = cornerRadius
        mainView.clipsToBounds = true
        mainView.fixBackgroundColor(
            backgroundColor: BTContainer.Constaints.onboardingTipsBackground,
            cornerRadius: cornerRadius
        )
    }
}
