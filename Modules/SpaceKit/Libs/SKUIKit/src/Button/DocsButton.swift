//
//  DocsButton.swift
//  SpaceKit
//
//  Created by huahuahu on 2019/2/15.
//https://www.jianshu.com/p/43c22fa3b42c

import Foundation

open class DocsButton: UIButton {
    public var widthInset: CGFloat = 0
    public var heightInset: CGFloat = 0

    override public func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let realBounds = self.bounds.insetBy(dx: widthInset, dy: heightInset)
        return realBounds.contains(point)
    }
}

open class DocsClickView: UIView {
    public var leftInset: CGFloat = 0
    public var rightInset: CGFloat = 0
    public var topInset: CGFloat = 0
    public var bottomInset: CGFloat = 0

    // swiftlint:disable line_length
    override public func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let realBounds = CGRect(x: self.bounds.minX + leftInset, y: self.bounds.minY + topInset, width: self.bounds.size.width - (leftInset + rightInset), height: self.bounds.size.height - (topInset + bottomInset))
        return realBounds.contains(point)
    }
}
