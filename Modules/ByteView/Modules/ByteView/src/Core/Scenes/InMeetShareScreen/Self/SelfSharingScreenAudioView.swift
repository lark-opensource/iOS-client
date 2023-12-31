//
//  SelfSharingScreenAudioView.swift
//  ByteView
//
//  Created by liujianlong on 2023/5/17.
//

import UIKit

class SelfSharingScreenAudioView: UIView {
    let label: UILabel = UILabel()
    let widget: UISwitch = UISwitch()
    var spacing: CGFloat = 12.0 {
        didSet {
            guard self.spacing != oldValue else {
                return
            }
            invalidateIntrinsicContentSize()
        }
    }
    private var maxWidth: CGFloat? {
        didSet {
            guard self.maxWidth != oldValue else {
                return
            }
            invalidateIntrinsicContentSize()
        }
    }
    var attributedText: NSAttributedString? {
        get {
            label.attributedText
        }
        set {
            label.attributedText = newValue
            self.setNeedsLayout()
            self.invalidateIntrinsicContentSize()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(label)
        self.addSubview(widget)
    }
    required init?(coder: NSCoder) {
        return nil
    }

    private func computeLayout(_ size: CGSize) -> (switchSize: CGSize, textSize: CGSize, textOverflow: Bool) {
        let switchSize = widget.sizeThatFits(size)
        let maxTextWidth = size.width - spacing - switchSize.width
        let maxTextHeight = size.height
        var textSize = label.sizeThatFits(CGSize(width: CGFLOAT_MAX, height: maxTextHeight))
        let textOverflow = textSize.width > maxTextWidth
        if textOverflow {
            textSize = label.sizeThatFits(CGSize(width: maxTextWidth, height: CGFLOAT_MAX))
        }
        textSize.width = min(maxTextWidth, textSize.width)
        textSize.height = min(maxTextHeight, textSize.height)
        return (switchSize, textSize, textOverflow)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let (switchSize, textSize, _) = computeLayout(size)
        let ret = CGSize(width: textSize.width + spacing + switchSize.width,
                         height: max(textSize.height, switchSize.height))
        return ret
    }

    override func layoutSubviews() {
        let size = self.bounds.size
        let (switchSize, textSize, textOverflow) = computeLayout(size)
        self.maxWidth = textOverflow ? size.width : nil
        self.label.frame = CGRect(x: (self.bounds.width - textSize.width - switchSize.width - spacing) * 0.5,
                                  y: (self.bounds.height - textSize.height) * 0.5,
                                  width: textSize.width,
                                  height: textSize.height)
        self.widget.frame = CGRect(x: self.label.frame.maxX + spacing, y: (self.bounds.height - switchSize.height) * 0.5, width: switchSize.width, height: switchSize.height)
        super.layoutSubviews()
    }

    override var intrinsicContentSize: CGSize {
        let size = sizeThatFits(CGSize(width: self.maxWidth ?? CGFLOAT_MAX, height: CGFLOAT_MAX))
        return size
    }

}
