//
//  BTCellValueViewProtocol.swift
//  SKBitable
//
//  Created by X-MAN on 2023/11/17.
//

import Foundation

protocol BTCellValueViewProtocol: UIView {
    func setData(_ model: BTCardFieldCellModel, containerWidth: CGFloat)
}

protocol BTTextCellValueViewProtocol: BTCellValueViewProtocol {
    func set(_ model: BTCardFieldCellModel, with font: UIFont, numberOfLines: Int)
}
