//
//  FontImageView.swift
//  IconfontGen
//
//  Created by yangyao on 2019/10/4.
//

import UIKit

open class FontImageView: UIImageView {

    private var iconColor: UIColor = UIColor.ud.N00 {
        didSet {
            updateIconImage()
        }
    }

    public var iconDrawable: IconDrawable? {
        didSet {
            updateIconImage()
        }
    }

    open override var frame: CGRect {
        didSet {
            updateIconImage()
        }
    }

    open override var contentMode: UIView.ContentMode {
        didSet {
            setNeedsLayout()
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        Iconfont.setup()
    }

    public convenience init(frame: CGRect,
                            iconDrawable: IconDrawable,
                            iconColor: UIColor = UIColor.ud.primaryOnPrimaryFill) {
        self.init(frame: frame)
        self.iconDrawable = iconDrawable
        self.iconColor = iconColor
        Iconfont.setup()
        updateIconImage()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        Iconfont.setup()
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        updateIconImage()
    }

    fileprivate func updateIconImage() {
        if frame.isEmpty {
            return
        }

        guard let iconDrawable = iconDrawable else {
            self.image = nil
            return
        }

        let image = iconDrawable.fontImage(of: frame.size.width,
                                           color: iconColor)
        self.image = image
    }
}
