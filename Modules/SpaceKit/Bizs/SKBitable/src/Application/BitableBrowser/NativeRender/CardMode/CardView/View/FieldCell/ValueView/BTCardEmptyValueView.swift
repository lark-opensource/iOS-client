//
//  BTCardEmptyValueView.swift
//  SKBitable
//
//  Created by X-MAN on 2023/10/30.
//

import Foundation
import UniverseDesignColor

final class BTCardEmptyValueView: UIView {
    struct Const {
        static let emptyWidth: CGFloat = 12.0
        static let emptyHeight: CGFloat = 2.0
        static let emptyRadius: CGFloat = 1.0
        static let emptyColor: UIColor = UDColor.lineBorderCard
    }
    
    let emptyLine = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        emptyLine.layer.cornerRadius = Const.emptyRadius
        emptyLine.backgroundColor = Const.emptyColor
        addSubview(emptyLine)
        emptyLine.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.width.equalTo(Const.emptyWidth)
            make.height.equalTo(Const.emptyHeight)
            make.left.equalToSuperview()
        }
    }
}

extension BTCardEmptyValueView: BTCellValueViewProtocol {
    func setData(_ model: BTCardFieldCellModel, containerWidth: CGFloat) {
        
    }
}
