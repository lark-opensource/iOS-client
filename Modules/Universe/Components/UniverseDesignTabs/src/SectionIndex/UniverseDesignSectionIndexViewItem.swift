//
//  UniverseDesignSectionIndexViewItem.swift
//  UniverseDesignTabs
//
//  Created by Yaoguoguo on 2023/2/7.
//

import Foundation
import UIKit

// MARK: - ZLSectionIndexViewItem
final public class UDSectionIndexViewItem: UIView {

    public var isSeleted = false
    public var image: UIImage? {
        didSet {
            imageView.image = image
        }
    }
    public var selectedImage: UIImage? {
        didSet {
            imageView.highlightedImage = selectedImage
        }
    }
    public var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
    public var titleFont: UIFont? {
        didSet {
            titleLabel.font = titleFont
        }
    }
    public var titleColor: UIColor? {
        didSet {
            titleLabel.textColor = titleColor
        }
    }
    public var titleSelectedColor: UIColor? {
        didSet {
            titleLabel.highlightedTextColor = titleSelectedColor
        }
    }

    public var selectedColor = UIColor.red {
        didSet {
            selectedView.backgroundColor = selectedColor
        }
    }

    public var selectedMargin: CGFloat = 0

    private var titleLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontSizeToFitWidth = true
        label.numberOfLines = 0
        label.backgroundColor = .clear
        label.textColor = .black
        label.highlightedTextColor = .white
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()

    private lazy var imageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .center
        return v
    }()

    private var selectedView: UIView

    override public init(frame: CGRect) {
        selectedView = UIView()
        selectedView.backgroundColor = selectedColor
        selectedView.alpha = 0

        super.init(frame: frame)
        addSubview(imageView)
        addSubview(titleLabel)
        insertSubview(selectedView, at: 0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        titleLabel.frame = bounds
        imageView.frame = bounds

        let width = min(bounds.width - selectedMargin, bounds.height - selectedMargin)
        let height = width
        let center = CGPoint(x: bounds.width * 0.5, y: bounds.height * 0.5)
        selectedView.frame = CGRect(x: 0, y: 0, width: width, height: height)
        selectedView.center = center
        selectedView.layer.cornerRadius = selectedView.bounds.width * 0.5
    }

    public func select() {
        isSeleted = true
        titleLabel.isHighlighted = true
        imageView.isHighlighted = true
        selectedView.alpha = 1
    }

    public func deselect() {
        selectedView.alpha = 0
        isSeleted = false
        titleLabel.isHighlighted = false
        imageView.isHighlighted = false
    }
}

