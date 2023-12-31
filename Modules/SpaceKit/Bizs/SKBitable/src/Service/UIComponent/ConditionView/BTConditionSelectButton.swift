//
//  BTConditionSelectButton.swift
//  SKBitable
//
//  Created by zoujie on 2022/6/13.
//  


import Foundation
import UIKit
import SKUIKit
import SnapKit
import UniverseDesignColor
import UniverseDesignIcon
import SKFoundation

public final class BTConditionSelectButton: UIButton {

    private lazy var icon = BTLightingIconView()

    private lazy var label = UILabel().construct { it in
        it.font = .systemFont(ofSize: 16)
        it.setContentCompressionResistancePriority(.required, for: .horizontal)
        it.textColor = UDColor.textPlaceholder
    }

    private lazy var selectedIcon = UIImageView().construct { it in
        it.image = UDIcon.getIconByKey(.downBoldOutlined, size: CGSize(width: 14, height: 14)).ud.withTintColor(UDColor.iconN3)
    }
    lazy var lockIcon = UIImageView().construct { it in // 入口做好FG，降低内部复杂度
        it.image = UDIcon.getIconByKey(.lockFilled, size: CGSize(width: 14, height: 14)).ud.withTintColor(UDColor.iconN3)
    }

    public override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? UDColor.fillPressed : UDColor.bgFiller
        }
    }

    private var hasLeftIcon = false
    private var hasRightIcon = false

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        addSubview(icon)
        addSubview(label)
        addSubview(lockIcon)
        addSubview(selectedIcon)
        
        self.layer.cornerRadius = 8
        self.clipsToBounds = true
        backgroundColor = UDColor.bgFiller

        icon.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(0)
            make.left.equalToSuperview().offset(4)
        }

        label.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.height.equalTo(22)
            make.left.equalTo(icon.snp.right).offset(4)
        }
        lockIcon.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.width.equalTo(0)
            make.height.equalTo(14)
            make.left.equalTo(label.snp.right).offset(4)
        }
        selectedIcon.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(14)
            make.left.equalTo(lockIcon.snp.right).offset(0)
            make.right.equalToSuperview().offset(-8)
        }
            lockIcon.isHidden = true // 默认不显示，需要调用update并且showLockIcon true才可以显示出来
    }

    /// 设置按钮文字，图标以及文字颜色，默认textPlaceholder
    public func update(model: BTConditionSelectButtonModel) {
        label.text = model.text
        label.textColor = model.enable ? model.textColor : UDColor.textDisabled
        if model.showLockIcon {
            lockIcon.isHidden = false
        } else {
            lockIcon.isHidden = true
        }
        
        lockIcon.snp.updateConstraints { make in
            make.width.equalTo(model.showLockIcon ? 14 : 0)
        }

        if let image = model.icon {
            hasLeftIcon = true
            icon.isHidden = false
            icon.update(image, showLighting: model.showIconLighting, tintColor: model.enable ? UDColor.iconN1 : UDColor.iconDisabled)
            icon.snp.updateConstraints { make in
                make.width.height.equalTo(18)
                make.left.equalToSuperview().offset(8)
            }
        } else {
            hasLeftIcon = false
            icon.isHidden = true
            icon.image = nil
            icon.snp.updateConstraints { make in
                make.width.height.equalTo(0)
                make.left.equalToSuperview().offset(4)
            }
        }
        
        hasRightIcon = model.hasRightIcon
        selectedIcon.isHidden = !hasRightIcon
        selectedIcon.snp.updateConstraints { make in
            make.width.height.equalTo(hasRightIcon ? 14 : 0)
            make.right.equalToSuperview().offset(hasRightIcon ? -8 : 0)
            make.left.equalTo(lockIcon.snp.right).offset(model.showLockIcon ? 8 : 0)
        }
        
    }

    public func update(text: String, textColor: UIColor) {
        label.text = text
        label.textColor = textColor
    }

    /// 获取当前button的宽度
    /// - Parameter height: 按钮高度
    /// - Returns: 宽度
    public func getButtonWidth(height: CGFloat) -> CGFloat {
        let textWidth = label.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: height)).width

        //文字左边距+文字宽度+文字右边距+下拉图标宽度+图标右边距
        var buttonWidth = 8 + textWidth + 8
        buttonWidth += hasLeftIcon ? 22 : 0
        buttonWidth += hasRightIcon ? 22 : 0
        buttonWidth += lockIcon.isHidden ? 0 : 18
        return buttonWidth
    }
}

public final class BTConditionSelectButtonCell: UICollectionViewCell {
    
    var didTapItem: (() -> Void)?
    
    private lazy var button: BTConditionSelectButton = BTConditionSelectButton(frame: .zero)

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpView()
        button.addTarget(self, action: #selector(didTapSelf), for: .touchUpInside)
    }

    private func setUpView() {
        contentView.addSubview(button)
        self.backgroundColor = .clear
//        button.isUserInteractionEnabled = false
        button.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    public func update(model: BTConditionSelectButtonModel) {
        button.update(model: model)
    }

    public func getCellWidth(height: CGFloat) -> CGFloat {
        return button.getButtonWidth(height: height)
    }
    
    @objc
    private func didTapSelf() {
        self.didTapItem?()
    }
}
