//
//  SKBarButton.swift
//  SKNavigationBar
//
//  Created by 边俊林 on 2019/11/25.
//

import UIKit
import UniverseDesignColor

public protocol SKBarButtonCustomInsetable where Self: UIView {
    var offset: CGPoint { get }
}

final public class SKBarButton: UIButton {
    
    struct ContentMode: OptionSet {
        let rawValue: Int
        static let title = ContentMode(rawValue: 1 << 0)
        static let image = ContentMode(rawValue: 1 << 1)
        static let imageAndTitle: ContentMode = [.image, .title]
    }
    
    private var contentType: ContentMode?
    
    public var item: SKBarButtonItem?
    
    private var backgroundLayer: CALayer?

    public init() {
        super.init(frame: .zero)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    public func commonInit() {
        imageView?.contentMode = .center
    }
    
    public override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        
        if let backgroundLayer = backgroundLayer {
            // backgroundLayer 居中
            backgroundLayer.frame = CGRect(x: (layer.frame.width - backgroundLayer.frame.width) / 2, y: (layer.frame.height - backgroundLayer.frame.height) / 2, width: backgroundLayer.frame.width, height: backgroundLayer.frame.height)
        }
    }

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        // Tips: If imageView exists (button is using image), system will always calculate the button size with
        //      the image.size exactly. So you must modify imageView size before calculating this bar button's size.
        if let imageView = imageView, imageView.image != nil {
            let infSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            let imageViewOriginSize = imageView.sizeThatFits(infSize)
            var buttonSize = size
            if size.height != CGFloat.greatestFiniteMagnitude {
                let iconWidth = imageViewOriginSize.width * size.height / imageViewOriginSize.height
                buttonSize.width = iconWidth
                if contentType == .imageAndTitle {
                    //计算按钮中同时有icon和文字时的布局
                    let textWidth = titleLabel?.sizeThatFits(size).width ?? .zero
                    self.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
                    buttonSize = CGSize(width: iconWidth + textWidth + 4, height: size.height)
                }
            } else if size.width != CGFloat.greatestFiniteMagnitude {
                buttonSize = CGSize(width: size.width, height: imageViewOriginSize.height * size.width / imageViewOriginSize.width)
            }
            return buttonSize
        }
        return super.sizeThatFits(size)
    }

    public func apply(with item: SKBarButtonItem, layout: SKButtonBar.LayoutAttributes) {
        /* Current supporting properties:
         * - tag
         * - accessibilityHint
         * - accessibilityValue
         * - accessibilityLabel
         * - accessibilityValue
         * - accessibilityElements
         * - accessibilityLanguage
         * - accessibilityIdentifier
         * - isEnabled
         * - isSelected
         * - action
         * - title
         * - image
         * - backgroundImage
         */
        // PS: Some properties of origin bar item are also using KVO, see it in `SKButtonBar`.

        tag = item.tag
        accessibilityHint = item.accessibilityHint
        accessibilityValue = item.accessibilityValue
        accessibilityLabel = item.accessibilityLabel
        accessibilityElements = item.accessibilityElements
        accessibilityLanguage = item.accessibilityLanguage
        accessibilityIdentifier = item.accessibilityIdentifier
        isEnabled = item.isEnabled
        if let isInSelection = item.isInSelection {
            isSelected = isInSelection
        }

        self.item = item

        if let action = item.action {
            addTarget(item.target, action: action, for: .touchUpInside)
        }

        let colorMapping: [UIControl.State: UIColor] = item.foregroundColorMapping ?? layout.itemForegroundColorMapping

        if let title = item.title {
            contentType = .title
            for (state, color) in colorMapping {
                setTitle(title, for: state)
                setTitleColor(color, for: state)
            }
            titleLabel?.font = layout.titleFont
        }

        if let image = item.image {
            contentType = contentType?.union(.image) ?? .image
            titleLabel?.font = layout.imageWithTitleFont
            if item.useOriginRenderedImage {
                configOriginalImage(image)
            } else {
                for (state, color) in colorMapping {
                    setImage(image.ud.withTintColor(color), for: state)
                }
            }
        }
        
        if let cornerRadius = layout.cornerRadius {
            let backgroundLayer = backgroundLayer ?? CALayer()
            if backgroundLayer.superlayer == nil {
                self.layer.insertSublayer(backgroundLayer, at: 0)
            }
            self.backgroundLayer = backgroundLayer
            backgroundLayer.isHidden = false
            backgroundLayer.ud.setBackgroundColor(UDColor.N900.withAlphaComponent(0.05))
            backgroundLayer.cornerRadius = cornerRadius
            backgroundLayer.masksToBounds = true
            let width =  cornerRadius * 2
            backgroundLayer.frame = CGRect(x: (self.frame.width - width) / 2, y: (self.frame.height - width) / 2, width: width, height: width)
        } else {
            self.backgroundLayer?.isHidden = true
        }
        
        if let iconHeight = layout.iconHeight {
            // 图标尺寸缩放（按 UX 要求整体缩放处理）
            let scale: CGFloat = iconHeight / (layout.itemHeight ?? 24.0)   // 目前的实际的图标尺寸是 24
            imageView?.transform = CGAffineTransform(scaleX: scale, y: scale)
        }

        // background image 的设置不写在 apply 方法里，而是写在外面，见 SKButtonBar.viewFromItem(_:)
    }

    public func refreshColorMapping(_ newColorMapping: [UIControl.State: UIColor]?) {
        let colorMapping: [UIControl.State: UIColor] = newColorMapping ?? Self.defaultIconColorMapping

        for (state, color) in colorMapping {
            setTitleColor(color, for: state)
        }

        if self.item?.useOriginRenderedImage == true {
            configOriginalImage(imageView?.image)
        } else {
            for (state, color) in colorMapping {
                setImage(imageView?.image?.ud.withTintColor(color), for: state)
            }
        }
    }

    public func update(image: UIImage?) {
        guard let image = image else { return }
        let colorMapping: [UIControl.State: UIColor] = item?.foregroundColorMapping ?? Self.defaultIconColorMapping
        if self.item?.useOriginRenderedImage == true {
            configOriginalImage(image)
        } else {
            for (state, color) in colorMapping {
                setImage(image.withColor(color), for: state)
            }
        }
    }
}

extension SKBarButton {
    // 蓝色
    public static var primaryColorMapping: [UIControl.State: UIColor] {
        return [
            .normal: UDColor.primaryContentDefault,
            .highlighted: UDColor.primaryContentLoading,
            .selected: UDColor.primaryContentDefault,
            [.selected, .highlighted]: UDColor.primaryContentLoading,
            .disabled: UDColor.iconDisabled
        ]
    }
    // 默认图标
    public static var defaultIconColorMapping: [UIControl.State: UIColor] {
        return [
            .normal: UDColor.iconN1,
            .highlighted: UDColor.iconN3,
            .selected: UDColor.primaryContentDefault,
            [.selected, .highlighted]: UDColor.primaryContentLoading,
            .disabled: UDColor.iconDisabled
        ]
    }
    // 默认文字
    public static var defaultTitleColorMapping: [UIControl.State: UIColor] {
        return [
            .normal: UDColor.textTitle,
            .highlighted: UDColor.textPlaceholder,
            .selected: UDColor.textTitle,
            [.selected, .highlighted]: UDColor.textPlaceholder,
            .disabled: UDColor.textDisabled
        ]
    }
}

extension SKBarButton {
    
    private func configOriginalImage(_ image: UIImage?) {
        setImage(image, for: .normal)
        setImage(image?.change(alpha: 0.5), for: .highlighted) // 目前使用原始图片的只有ai icon,后续有其他样式需要再改
    }
}
