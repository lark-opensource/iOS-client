//
//  BTCardStageValueView.swift
//  SKBitable
//
//  Created by X-MAN on 2023/11/1.
//

import Foundation
import UniverseDesignFont

final class BTCardStageValueView: UIView {
    
    private struct Const {
        static let itemHeight: CGFloat = 20.0
        static let titleFont: UIFont = UDFont.caption0
        static let cornerRadius: CGFloat = 6.0
        static let itemInset: CGFloat = 6.0
    }
    
    private lazy var stageItem: BTStageItemView = {
        let item = BTStageItemView(with: .cardView)
        return item
    }()
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = Const.cornerRadius
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
        addSubview(containerView)
        containerView.addSubview(stageItem)
        stageItem.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(containerView.snp.left).offset(Const.itemInset)
            make.height.lessThanOrEqualTo(Const.itemHeight)
            make.right.lessThanOrEqualToSuperview().inset(Const.itemInset)
            make.centerX.equalToSuperview()
        }
        containerView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
            make.height.equalTo(Const.itemHeight)
            make.centerY.equalToSuperview()
        }
    }
}

extension BTCardStageValueView: BTCellValueViewProtocol {
    
    func setData(_ model: BTCardFieldCellModel, containerWidth: CGFloat) {
        if let data = model.getFieldData(type: BTStageData.self).first {
            stageItem.configInField(name: data.text, type: data.type, font: Const.titleFont)
            containerView.backgroundColor = UIColor.docs.rgb(data.capsuleColor)
        }
    }
}
