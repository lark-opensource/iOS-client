//
//  WheeledCollectionCell.swift
//  LarkAI
//
//  Created by Hayden on 2023/5/28.
//

import UIKit

public protocol WheeledCollectionCell: AnyObject {
    associatedtype Item
    var item: Item? { get set }
}

public struct WheeledCollectionCellSize {
    let normalWidth: CGFloat
    let centerWidth: CGFloat
    let normalHeight: CGFloat
    let centerHeight: CGFloat

    public init(normalWidth: CGFloat,
                centerWidth: CGFloat,
                normalHeight: CGFloat? = nil,
                centerHeight: CGFloat? = nil) {
        self.normalWidth = normalWidth
        self.centerWidth = centerWidth
        self.normalHeight = normalHeight ?? normalWidth
        self.centerHeight = centerHeight ?? centerWidth
    }
}
