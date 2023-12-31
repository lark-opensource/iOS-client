//
//  BTCardButtonValueView.swift
//  SKBitable
//
//  Created by X-MAN on 2023/11/1.
//

import Foundation
import UniverseDesignFont
import UniverseDesignColor

final class BTCardButtonValueView: UIView {
    
    private struct Const {
        static let cornerRadius: CGFloat = 6.0
        static let font: UIFont = UDFont.caption0
        static let buttonHeight: CGFloat = 20.0
        static let titlePadding: CGFloat = 8.0
    }
    
    private lazy var button: UIButton = {
        let button =  UIButton()
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: Const.titlePadding, bottom: 0, right: Const.titlePadding)
        button.titleLabel?.font = Const.font
        button.layer.cornerRadius = Const.cornerRadius
        button.setTitleColor(UDColor.textTitle, for: .normal)
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        addSubview(button)
        button.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
            make.height.equalTo(Const.buttonHeight)
        }
    }
}

extension BTCardButtonValueView: BTCellValueViewProtocol {
    
    func setData(_ model: BTCardFieldCellModel, containerWidth: CGFloat) {
        if let data = model.getFieldData(type: BTButtonData.self).first {
            button.setTitle(data.text, for: .normal)
            button.backgroundColor = UIColor.docs.rgb(data.background)
            button.setTitleColor(UIColor.docs.rgb(data.textColor), for: .normal)
        }
    }
}
