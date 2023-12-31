//
//  BTCardSimpleTextValueView.swift
//  SKBitable
//
//  Created by X-MAN on 2023/11/1.
//

import Foundation
import UniverseDesignFont
import SKFoundation

final class BTCardSimpleTextValueView: UIView {
    
    private struct Const {
        static let itemSpacing: CGFloat = 4.0
        static let iconSize: CGFloat = 16.0
        static let textDefaultFont = UDFont.body2
    }
    
    private lazy var textLabel: UILabel = {
        let label = UILabel()
        label.font = Const.textDefaultFont
        return label
    }()
    
    private lazy var rightIconView: UIImageView = {
        let icon = UIImageView()
        return icon
    }()
    
    private lazy var leftIconView: UIImageView = {
        let icon = UIImageView()
        return icon
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        let stackView = UIStackView()
        stackView.spacing = Const.itemSpacing
        stackView.axis = .horizontal
        stackView.alignment = .center
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }
        stackView.addArrangedSubview(leftIconView)
        stackView.addArrangedSubview(textLabel)
        stackView.addArrangedSubview(rightIconView)
        leftIconView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(Const.iconSize)
        }
        textLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
        }
        rightIconView.snp.makeConstraints { make in
            make.right.lessThanOrEqualToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(Const.iconSize)
        }
    }
    
    private func setInternal(_ model: BTCardFieldCellModel,
                             font: UIFont = Const.textDefaultFont, numberOfLines: Int = 1) {
        if let data = model.getFieldData(type: BTSimpleTextData.self).first {
            if let leftIcon = data.leftIcon {
                leftIconView.isHidden = false
                var tintColor: UIColor? = nil
                if let colorString = leftIcon.iconTintColor {
                    tintColor = UIColor.docs.rgb(colorString)
                }
                leftIcon.apply(to: leftIconView, tintColor: tintColor)
            } else {
                leftIconView.isHidden = true
            }
            if let rightIcon = data.rightIcon {
                rightIconView.isHidden = false
                var tintColor: UIColor? = nil
                if let colorString = rightIcon.iconTintColor {
                    tintColor = UIColor.docs.rgb(colorString)
                }
                rightIcon.apply(to: rightIconView, tintColor: tintColor)
            } else {
                rightIconView.isHidden = true
            }
            textLabel.text = data.text
            textLabel.font = font
            textLabel.textColor = UIColor.docs.rgb(data.textColor)
            textLabel.numberOfLines = numberOfLines
        } else {
            textLabel.text = nil
        }
    }
}

extension BTCardSimpleTextValueView: BTTextCellValueViewProtocol {
    func setData(_ model: BTCardFieldCellModel, containerWidth: CGFloat) {
        setInternal(model)
    }
    
    func set(_ model: BTCardFieldCellModel, 
             with font: UIFont,
             numberOfLines: Int) {
        setInternal(model,
                    font: font,
                    numberOfLines: numberOfLines)
    }
}
