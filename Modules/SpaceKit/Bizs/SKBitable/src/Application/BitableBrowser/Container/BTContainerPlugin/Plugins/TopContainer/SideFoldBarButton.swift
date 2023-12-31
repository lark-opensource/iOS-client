//
//  SideFoldBarButton.swift
//  SKBitable
//
//  Created by yinyuan on 2023/9/10.
//

import UIKit
import SKUIKit
import UniverseDesignIcon
import UniverseDesignColor

class SideFoldBarButton: UIView {
    
    private class Constaints {
        static let spacing: CGFloat = 8
        static let leftInset: CGFloat = 4
        static var rightInset: CGFloat = 4
    }
    
    private lazy var tableNameLable: UILabel = {
        let view = UILabel()
        view.font = .systemFont(ofSize: 14)
        view.numberOfLines = 1
        view.textColor = UDColor.textTitle
        return view
    }()
    
    lazy var control: UIControl = {
        let view = UIControl()
        view.addTarget(self, action: #selector(touchDown), for: .touchDown)
        view.addTarget(self, action: #selector(touchUp), for: [.touchCancel, .touchUpInside, .touchUpOutside])
        return view
    }()
    
    private lazy var sideFoldBarStackView: UIView = {
        let iconWidth = BTContainer.Constaints.navBarIconHeight
        let spacing: CGFloat = Constaints.spacing
        
        let leftSpacingView = UIView()
        
        let iconView = UIImageView()
        iconView.image = UDIcon.slideOutlined.ud.withTintColor(UDColor.iconN1)
        
        let rightSpacingView = UIView()
        
        let view = UIStackView(arrangedSubviews: [leftSpacingView, iconView, tableNameLable, rightSpacingView])
        view.axis = .horizontal
        view.alignment = .center
        view.distribution = .fill
        view.spacing = spacing
        view.isUserInteractionEnabled = false
        view.backgroundColor = BTContainer.Constaints.navBarButtonBackgroundColor
        view.layer.cornerRadius = BTContainer.Constaints.navBarButtonBackgroundCornerRadius
        view.clipsToBounds = true
        // fix UIStackView iOS 14 以下不支持背景色和圆角
        view.fixBackgroundColor(
            backgroundColor: BTContainer.Constaints.navBarButtonBackgroundColor,
            cornerRadius: BTContainer.Constaints.navBarButtonBackgroundCornerRadius
        )
        
        leftSpacingView.setContentCompressionResistancePriority(.required, for: .horizontal)
        leftSpacingView.snp.makeConstraints { make in
            make.width.equalTo(Constaints.leftInset)
        }
        
        rightSpacingView.setContentCompressionResistancePriority(.required, for: .horizontal)
        rightSpacingView.snp.makeConstraints { make in
            make.width.equalTo(Constaints.rightInset)
        }
        
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(iconWidth)
        }
        let scale: CGFloat =  BTContainer.Constaints.navBarIconHeight / iconWidth
        iconView.transform = CGAffineTransform(scaleX: scale, y: scale)
        
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
        self.addSubview(sideFoldBarStackView)
        self.addSubview(control)
        sideFoldBarStackView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.height.equalTo(BTContainer.Constaints.navBarButtonBackgroundSize.height)
            make.centerY.equalToSuperview()
            make.right.lessThanOrEqualToSuperview().offset(-16)
        }
        
        control.snp.makeConstraints { make in
            make.edges.equalTo(sideFoldBarStackView)
        }
        
        hide(animated: false)   // 默认隐藏
    }
    
    @objc
    private func touchDown() {
        sideFoldBarStackView.alpha = 0.5
    }
    
    @objc
    private func touchUp() {
        sideFoldBarStackView.alpha = 1
    }
    
    func updateTitle(title: String?) {
        tableNameLable.text = title
        if title == nil || title?.isEmpty == true {
            tableNameLable.isHidden = true
        } else {
            tableNameLable.isHidden = false
        }
    }
    
    private var firstShow: Bool = true
    
    var isShow: Bool {
        get {
            return self.control.isUserInteractionEnabled
        }
    }
    
    func show(animated: Bool = true) {
        self.control.isUserInteractionEnabled = true
        if animated {
            if firstShow {
                // 首次显示先设置一下默认状态从底部滑出
                self.sideFoldBarStackView.transform.ty = self.frame.height
            }
            UIView.animate(withDuration: BTContainer.Constaints.animationDuration) {
                self.sideFoldBarStackView.alpha = 1
                self.sideFoldBarStackView.transform.ty = 0
            }
        } else {
            self.sideFoldBarStackView.alpha = 1
            self.sideFoldBarStackView.transform.ty = 0
        }
        firstShow = false
    }
    
    func hide(animated: Bool = true) {
        self.control.isUserInteractionEnabled = false
        if animated {
            UIView.animate(withDuration: BTContainer.Constaints.animationDuration) {
                self.sideFoldBarStackView.alpha = 0
                self.sideFoldBarStackView.transform.ty = self.frame.height
            }
        } else {
            self.sideFoldBarStackView.alpha = 0
            self.sideFoldBarStackView.transform.ty = self.frame.height
        }
    }
}
