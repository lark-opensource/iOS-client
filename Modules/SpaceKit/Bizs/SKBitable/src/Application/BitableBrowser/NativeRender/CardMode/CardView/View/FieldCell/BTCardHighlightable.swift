//
//  BTCardCellHilightable.swift
//  SKBitable
//
//  Created by X-MAN on 2023/10/30.
//

import Foundation

protocol BTCardCellHighlightable: UIView {
    
    var highlightColor: UIColor? { get }
    var highlightBoardColor: UIColor? { get }
    
    func changeHighlight()
    func changeBoader()
}

extension BTCardCellHighlightable {
    
    func changeHighlight() {
        self.backgroundColor = highlightColor
    }
    func changeBoader() {
        if let highlightBoardColor = self.highlightBoardColor {
            self.layer.borderColor = highlightBoardColor.cgColor
            self.layer.borderWidth = 1.0
        } else {
            self.layer.borderColor = nil
            self.layer.borderWidth = 0
        }
    }
}

protocol BTCardHighlightable: UIView {
    
    var highlightColor: UIColor? { get }
        
    func changeHighlight()
}

extension BTCardHighlightable {
    
    func changeHighlight() {
        self.backgroundColor = self.highlightColor
    }
}
