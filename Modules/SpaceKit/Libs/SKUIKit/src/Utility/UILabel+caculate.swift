//
//  UILabel+caculate.swift
//  SpaceKit
//
//  Created by litao_dev on 2019/8/11.
//  

import Foundation

extension UILabel {
    public func calculateLabelHeight(textWidth: CGFloat) -> CGFloat {
        var frame = self.frame
        frame.size.width = textWidth
        self.frame = frame
        self.sizeToFit()

        return self.frame.height
    }
}
