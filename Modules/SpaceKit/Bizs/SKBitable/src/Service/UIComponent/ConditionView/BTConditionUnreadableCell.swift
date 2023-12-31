//
//  BTConditionUnreadableCell.swift
//  SKBitable
//
//  Created by X-MAN on 2022/11/1.
//

import Foundation

public final class BTConditionUnreadableCell: UICollectionViewCell {
    
    private lazy var button: BTConditionSelectButton = BTConditionSelectButton(frame: .zero)

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpView()
    }

    private func setUpView() {
        contentView.addSubview(button)
        button.isEnabled = false
        self.backgroundColor = .clear
//        button.isUserInteractionEnabled = false
        button.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    public func update(model: BTConditionSelectButtonModel) {
        var model = model
        model.hasRightIcon = true
        model.icon = nil
        model.enable = false
        button.update(model: model)
    }

    public func getCellWidth(height: CGFloat) -> CGFloat {
        return button.getButtonWidth(height: height)
    }
    
}
