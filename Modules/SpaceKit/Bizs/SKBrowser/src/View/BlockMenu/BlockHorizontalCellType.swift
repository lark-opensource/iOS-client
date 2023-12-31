//
//  BlockHorizontalCellType.swift
//  SKBrowser
//
//  Created by huayufan on 2021/9/24.
//  


import UIKit

enum BlockHorizontalCellPosition {
    
    case head
    case middle
    case tail
    case single
    
    static func converToPisition(rows: Int, indexPath: IndexPath) -> BlockHorizontalCellPosition {
        if indexPath.row == 0, rows == 1 {
            return .single
        } else if indexPath.row == 0 {
            return .head
        } else if indexPath.row == rows - 1 {
            return .tail
        } else {
            return .middle
        }
    }
}

protocol BlockHorizontalCellType {}

extension BlockHorizontalCellType where Self: UICollectionViewCell {
    func update(_ position: BlockHorizontalCellPosition) {
        switch position {
        case .head:
            layer.cornerRadius = 8
            layer.maskedCorners = .left
        case .middle:
            layer.cornerRadius = 0
            layer.maskedCorners = []
        case .tail:
            layer.cornerRadius = 8
            layer.maskedCorners = .right
        case .single:
            layer.cornerRadius = 8
            layer.maskedCorners = .all
        }
    }
}
