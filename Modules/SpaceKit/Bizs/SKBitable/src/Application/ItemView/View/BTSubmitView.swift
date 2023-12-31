//
//  BTSubmitView.swift
//  SKBitable
//
//  Created by yinyuan on 2023/10/24.
//

import UIKit
import UniverseDesignColor
import UniverseDesignIcon
import SKResource

enum BTSubmitIconType {
    case initial
    case loading
    case done
}

private extension BTSubmitIconType {
    var backgroundColor: UIColor {
        switch self {
        case .initial, .loading:
            return UDColor.primaryContentDefault
        case .done:
            return UIColor.dynamic(light: UDColor.G600, dark: UDColor.G500)
        }
    }
    
    var pressBackgroundColor: UIColor {
        switch self {
        case .initial, .loading:
            return UDColor.primaryContentPressed
        case .done:
            return UIColor.dynamic(light: UDColor.G700, dark: UDColor.G600)
        }
    }
    
    var btnTitle: String {
        switch self {
        case .initial, .loading:
            return BundleI18n.SKResource.Bitable_QuickAdd_Submit_Button
        case .done:
            return BundleI18n.SKResource.Bitable_QuickAdd_SubmitSuccess_Toast
        }
    }
}

class WrapperView: UIView {
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if self.isHidden || self.alpha <= 0 || !isUserInteractionEnabled {
            return nil
        }
        for subview in subviews.reversed() {
            let convertedPoint = subview.convert(point, from: self)
            if let hitView = subview.hitTest(convertedPoint, with: event) {
                return hitView
            }
        }
        return nil  // 自己不响应，全部由子 view 响应
    }
}

final class BTSubmitView: WrapperView {
    
    var clickCallback: ((_ view: BTSubmitView) -> Void)?
    
    private lazy var wrapperView: UIView = {
        let view = WrapperView()
        
        view.addSubview(mainView)
        mainView.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.height.equalToSuperview()
        }
        
        return view
    }()
    
    private lazy var mainView: UIControl = {
        let view = UIControl()
        
        view.layer.cornerRadius = 24
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 8
        view.layer.shadowOpacity = 1
        
        view.addSubview(mainStackView)
        mainStackView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(24)
            make.height.equalToSuperview()
        }
        
        view.addTarget(self, action: #selector(tap), for: .touchUpInside)
        view.addTarget(self, action: #selector(touchDown), for: .touchDown)
        view.addTarget(self, action: #selector(touchUp), for: [.touchCancel, .touchUpInside, .touchUpOutside])
        
        return view
    }()
    
    private lazy var mainStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [leftImageView, titleLabel])
        view.axis = .horizontal
        view.alignment = .center
        view.spacing = 8
        view.isUserInteractionEnabled = false
        
        leftImageView.snp.makeConstraints { make in
            make.width.height.equalTo(20)
        }
        return view
    }()
    
    private lazy var leftImageView: UIImageView = {
        let view = UIImageView()
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.textColor = UDColor.staticWhite
        view.numberOfLines = 1
        view.font = .systemFont(ofSize: 16)
        return view
    }()
    
    private var iconType: BTSubmitIconType = .initial
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        addSubview(wrapperView)
        wrapperView.snp.makeConstraints { make in
            make.width.equalTo(300)
            make.height.equalTo(46)
            make.edges.equalToSuperview()
        }
    }
    
    @objc
    private func touchDown() {
        if frame.width > 0 {
            mainView.backgroundColor = iconType.pressBackgroundColor
            mainView.layer.shadowColor = iconType.pressBackgroundColor.withAlphaComponent(0.18).cgColor
            let scale: CGFloat = 0.95
            UIView.animate(withDuration: 0.1) {
                self.mainView.transform = CGAffineTransform(scaleX: scale, y: scale)
            }
        }
    }
    
    @objc
    private func touchUp() {
        mainView.backgroundColor = iconType.backgroundColor
        mainView.layer.shadowColor = iconType.backgroundColor.withAlphaComponent(0.18).cgColor
        UIView.animate(withDuration: 0.1) {
            self.mainView.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
    }
    
    @objc
    private func tap() {
        clickCallback?(self)
    }
    
    func update(iconType: BTSubmitIconType, animated: Bool = true) {
        if animated {
            UIView.animate(withDuration: 0.25) { [weak self] in
                self?._update(iconType: iconType)
            }
        } else {
            _update(iconType: iconType)
        }
    }
    
    private func _update(iconType: BTSubmitIconType) {
        self.iconType = iconType
        switch iconType {
        case .initial:
            isUserInteractionEnabled = true
            leftImageView.image = UDIcon.doneOutlined.ud.withTintColor(UDColor.staticWhite)
            leftImageView.layer.removeAllAnimations()
        case .done:
            isUserInteractionEnabled = false
            leftImageView.image = UDIcon.doneOutlined.ud.withTintColor(UDColor.staticWhite)
            leftImageView.layer.removeAllAnimations()
        case .loading:
            isUserInteractionEnabled = false
            leftImageView.image = UDIcon.loadingOutlined.ud.withTintColor(UDColor.staticWhite)
            leftImageView.layer.removeAllAnimations()
            // 创建旋转动画
            let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
            rotationAnimation.toValue = NSNumber(value: Double.pi * 2)  // 旋转一周
            rotationAnimation.duration = 1.0  // 完成一次旋转所需时间
            rotationAnimation.repeatCount = .infinity  // 无限循环
            // 将动画添加到视图的图层
            leftImageView.layer.add(rotationAnimation, forKey: "rotationAnimation")
        }
        titleLabel.text = iconType.btnTitle
        
        if mainView.isTouchInside {
            mainView.backgroundColor = iconType.pressBackgroundColor
            mainView.layer.shadowColor = iconType.pressBackgroundColor.withAlphaComponent(0.18).cgColor
        } else {
            mainView.backgroundColor = iconType.backgroundColor
            mainView.layer.shadowColor = iconType.backgroundColor.withAlphaComponent(0.18).cgColor
        }
        
        
        self.layoutIfNeeded()
    }
}
