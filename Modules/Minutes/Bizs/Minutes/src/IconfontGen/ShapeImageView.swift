//
//  ShapeImageView.swift
//  IconfontGen
//
//  Created by yangyao on 2019/10/10.
//

import UIKit

public protocol ShapeImageGetter {
    var image: UIImage? { get }
    var shapeImage: UIImage? { get }
}

open class ShapeImageView: UIView, ShapeImageGetter {
    private var shapeLayer: ShapeLayer {
        // swiftlint:disable force_cast
        return layer as! ShapeLayer
        // swiftlint:enable force_cast
    }

    public convenience init(iconDrawable: IconDrawable, tintColor: UIColor? = .white) {
        self.init(frame: .zero)

        self.setIconDrawable(iconDrawable)
        self.tintColor = tintColor
    }

    private func setIconDrawable(_ iconDrawable: IconDrawable) {
        self.iconDrawable = iconDrawable
    }

    public var iconDrawable: IconDrawable? {
        didSet {
            shapeLayer.iconDrawable = iconDrawable
        }
    }

    override open class var layerClass: AnyClass {
        return ShapeLayer.self
    }

    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        return shapeLayer.preferredFrameSize()
    }

    override open var intrinsicContentSize: CGSize {
        return shapeLayer.preferredFrameSize()
    }

    override open func tintColorDidChange() {
        super.tintColorDidChange()
        shapeLayer.fillColor = tintColor.cgColor
    }

    public var image: UIImage? {
        guard let iconDrawable = iconDrawable else { return nil }
        let image = iconDrawable.shapeImage(of: tintColor)
        return image
    }

    public var shapeImage: UIImage? {
        guard let iconDrawable = iconDrawable else { return nil }
        guard let path = iconDrawable.path else { return nil }

        var image: UIImage?
        var newSize: CGSize = .zero
        let pathBounds = path.boundingBoxOfPath.size

        if contentMode == .scaleAspectFill {
            if bounds.size.width > bounds.size.height {
                newSize = CGSize(width: bounds.size.width,
                                 height: pathBounds.height / pathBounds.width * bounds.size.width)
            } else {
                newSize = CGSize(width: pathBounds.width / pathBounds.height * bounds.size.height,
                                 height: bounds.size.height)
            }
            image = iconDrawable.shapeImage(of: newSize, color: tintColor, contentsGravity: .resizeAspectFill)
        } else if contentMode == .scaleAspectFit {
            if bounds.size.width > bounds.size.height {
                newSize = CGSize(width: pathBounds.width / pathBounds.height * bounds.size.height,
                                 height: bounds.size.height)
            } else {
                newSize = CGSize(width: bounds.size.width,
                                 height: pathBounds.height / pathBounds.width * bounds.size.width)
            }
            image = iconDrawable.shapeImage(of: newSize, color: tintColor, contentsGravity: .resizeAspect)
        } else if contentMode == .scaleToFill {
            image = iconDrawable.shapeImage(of: bounds.size, color: tintColor, contentsGravity: .resize)
        } else {
            newSize = pathBounds
            image = iconDrawable.shapeImage(of: newSize, color: tintColor, contentsGravity: layer.contentsGravity)
        }
        return image
    }
}
