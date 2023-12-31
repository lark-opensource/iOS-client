//
//  BVPositionedButton.swift
//  ByteView
//
//  Created by 刘建龙 on 2020/5/25.
//

import UIKit

class BVPositionedButton: UIButton {
    enum ImagePosition {
        case top
        case left
        case right
    }

    var imagePosition: ImagePosition = .left {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    var spacing: CGFloat = 0.0

    private var recursiveGuard: Bool = false
    private var titleSize: CGSize {
        super.titleRect(forContentRect: CGRect(origin: .zero, size: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))).size
    }

    private var imageSize: CGSize {
        super.imageRect(forContentRect: CGRect(origin: .zero, size: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))).size
    }

    override var intrinsicContentSize: CGSize {
        let width: CGFloat
        let height: CGFloat

        switch imagePosition {
        case .left, .right:
            width = titleSize.width + imageSize.width + spacing
            height = max(titleSize.height, imageSize.height)
        case .top:
            width = max(titleSize.width, imageSize.width)
            height = titleSize.height + imageSize.height + spacing
        }

        return CGSize(width: width, height: height)
    }

    override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        guard !recursiveGuard else {
                return super.imageRect(forContentRect: contentRect)
        }
        recursiveGuard = true
        defer {
            recursiveGuard = false
        }

        let imageSize = self.imageSize
        let titleSize = self.titleSize
        let x: CGFloat
        let y: CGFloat

        switch imagePosition {
        case .left:
            let remains = contentRect.width - imageSize.width - titleSize.width - spacing
            x = remains * 0.5
            y = (contentRect.height - imageSize.height) * 0.5

        case .right:
            let remains = contentRect.width - imageSize.width - titleSize.width - spacing
            x = remains * 0.5 + titleSize.width + spacing
            y = (contentRect.height - imageSize.height) * 0.5

        case .top:
            let remains = contentRect.height - imageSize.height - titleSize.height - spacing
            x = (contentRect.width - imageSize.width) * 0.5
            y = remains * 0.5
        }
        return CGRect(x: x, y: y, width: imageSize.width, height: imageSize.height)
    }

    override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        guard !recursiveGuard else {
                return super.titleRect(forContentRect: contentRect)
        }
        recursiveGuard = true
        defer {
            recursiveGuard = false
        }

        let imageSize = self.imageSize
        let titleSize = self.titleSize
        let x: CGFloat
        let y: CGFloat

        switch imagePosition {
        case .left:
            let remains = contentRect.width - imageSize.width - titleSize.width - spacing
            x = remains * 0.5 + imageSize.width + spacing
            y = (contentRect.height - titleSize.height) * 0.5

        case .right:
            let remains = contentRect.width - imageSize.width - titleSize.width - spacing
            x = remains * 0.5
            y = (contentRect.height - titleSize.height) * 0.5

        case .top:
            let remains = contentRect.height - imageSize.height - titleSize.height - spacing
            x = (contentRect.width - titleSize.width) * 0.5
            y = remains * 0.5 + imageSize.height + spacing
        }
        return CGRect(x: x, y: y, width: titleSize.width, height: titleSize.height)
    }
}
