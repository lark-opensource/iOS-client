//
//  BTCardProgressValueView.swift
//  SKBitable
//
//  Created by X-MAN on 2023/11/2.
//

import Foundation

final class BTCardProgressValueView: UIView {
    
    fileprivate struct Const {
        static let progressHeight: CGFloat = 8.0
    }
    
    let valueView = BTProgressView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        addSubview(valueView)
        valueView.snp.makeConstraints { make in
            make.left.right.centerY.equalToSuperview()
            make.height.equalTo(Const.progressHeight)
        }
    }
}

extension BTCardProgressValueView: BTCellValueViewProtocol {
    
    func setData(_ model: BTCardFieldCellModel, containerWidth: CGFloat) {
        if let data = model.getFieldData(type: BTProgressData.self).first {
            valueView.progressColor = BTColor(color: [data.color])
            valueView.value = data.progress
        }
    }
}
