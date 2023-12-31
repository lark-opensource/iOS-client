//
//  BTCardDateValueView.swift
//  SKBitable
//
//  Created by X-MAN on 2023/10/31.
//

import Foundation
import UniverseDesignFont
import UniverseDesignColor
import UniverseDesignIcon

final class BTCardDateValueView: UIView {
    
    struct Const {
        static let itemSpcing: CGFloat = 8.0
        static let iconSize: CGFloat = 16.0
        static let font: UIFont = UDFont.body2
        static let iconTintColor = UDColor.primaryContentDefault
        static let noRemindTextColor = UDColor.textTitle
    }
    
    private lazy var textLable: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.numberOfLines = 1
        label.font = Const.font
        return label
    }()
    
    private lazy var iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UDIcon.alarmClockFilled.ud.withTintColor(Const.iconTintColor)
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    // nolint: duplicated_code
    private func setup() {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = Const.itemSpcing
        stackView.alignment = .center
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }
        stackView.addArrangedSubview(textLable)
        stackView.addArrangedSubview(iconView)
        textLable.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
        }
        iconView.snp.makeConstraints { make in
            make.width.equalTo(Const.iconSize)
            make.height.equalTo(Const.iconSize)
            make.centerY.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }
        iconView.isHidden = true
    }
    
    private func setInternal(_ model: BTCardFieldCellModel, 
                             font: UIFont = Const.font, numberOfLines: Int = 1) {
        if let data = model.getFieldData(type: BTDateData.self).first {
            textLable.text = data.text
            textLable.font = font
            textLable.numberOfLines = numberOfLines
            textLable.textColor = data.remind ? Const.iconTintColor : Const.noRemindTextColor
            iconView.isHidden = !data.remind
        } else {
            iconView.isHidden = true
            textLable.text = nil
        }
    }
}

extension BTCardDateValueView: BTTextCellValueViewProtocol {
    
    func setData(_ model: BTCardFieldCellModel, containerWidth: CGFloat) {
        setInternal(model)
    }
    
    func set(_ model: BTCardFieldCellModel, with font: UIFont, numberOfLines: Int) {
        setInternal(model, font: font, numberOfLines: numberOfLines)
    }
}
