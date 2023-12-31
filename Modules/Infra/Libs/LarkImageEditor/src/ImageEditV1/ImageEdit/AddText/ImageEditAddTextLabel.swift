//
//  ImageEditAddTextLabel.swift
//  LarkUIKit
//
//  Created by ChalrieSu on 2018/7/31.
//  Copyright © 2018 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import LarkExtensions

struct ImageEditText: Equatable {

    var text: String?
    var color: ColorPanelType
    static var `default`: ImageEditText {
        return ImageEditText(text: nil,
                             color: ColorPanelType.default)
    }

    init(text: String?, color: ColorPanelType) {
        self.text = text
        self.color = color
    }

    static func == (lhs: ImageEditText, rhs: ImageEditText) -> Bool {
        guard lhs.color == rhs.color else { return false }
        var lText = lhs.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        var rText = rhs.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        lText = (lText?.isEmpty ?? true) ? nil : lText
        rText = (rText?.isEmpty ?? true) ? nil : rText
        return lText == rText
    }
}

final class ImageEditAddTextLabel: UIView {
    var editText: ImageEditText {
        didSet {
            label.text = ((editText.text?.count ?? 0) > 0)
                ? editText.text : BundleI18n.LarkImageEditor.Lark_Legacy_ClickToEnter
            label.textColor = editText.color.color()
        }
    }

    var highlighted: Bool = true {
        didSet {
            closeImageView.isHidden = !highlighted
            resizeImageView.isHidden = !highlighted
            labelBgView.isHidden = !highlighted
        }
    }

    private let label = UILabel()
    private let labelBgView = UIView()
    private let labelBgLayer = CAShapeLayer()
    private let closeImageView = UIImageView(image: Resources.edit_text_close)
    private let resizeImageView = UIImageView(image: Resources.edit_resize)

    let tapGesture = UITapGestureRecognizer()
    let panGesture = UIPanGestureRecognizer()
    let closeTapGesture = UITapGestureRecognizer()
    let resizePanGesture = UIPanGestureRecognizer()

    private var labelSizeCache: [String: CGSize] = [:]
    private var originLabelSize: CGSize {
        if let size = labelSizeCache[label.text ?? ""] {
            return size
        }
        let tempLabel = UILabel()
        tempLabel.font = UIFont.systemFont(ofSize: 21)
        tempLabel.numberOfLines = 0
        tempLabel.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 48
        tempLabel.frame.size = CGSize(width: UIScreen.main.bounds.width - 48, height: CGFloat.greatestFiniteMagnitude)
        tempLabel.text = label.text
        tempLabel.sizeToFit()
        labelSizeCache[label.text ?? ""] = tempLabel.bounds.size
        return tempLabel.bounds.size
    }

    private var originViewSize: CGSize {
        return CGSize(width: 10 + 9 + originLabelSize.width + 9 + 10,
                      height: 10 + 5 + originLabelSize.height + 5 + 10)
    }

    var scale: CGFloat = 1 {
        didSet {
            self.bounds.size = originViewSize * scale
        }
    }

    init(editText: ImageEditText) {
        self.editText = editText
        super.init(frame: CGRect.zero)

        addSubview(labelBgView)
        labelBgLayer.backgroundColor = UIColor.clear.cgColor
        labelBgLayer.lineWidth = 0.5
        labelBgLayer.fillColor = UIColor.clear.cgColor
        labelBgLayer.strokeColor = UIColor.white.cgColor
        labelBgLayer.lineDashPattern = [NSNumber(value: 4), NSNumber(value: 3)]
        labelBgView.layer.addSublayer(labelBgLayer)

        label.text = ((editText.text?.count ?? 0) > 0)
            ? editText.text : BundleI18n.LarkImageEditor.Lark_Legacy_ClickToEnter
        label.textColor = editText.color.color()
        label.font = UIFont.systemFont(ofSize: 21)
        label.numberOfLines = 0
        label.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 48
        addSubview(label)

        closeImageView.addGestureRecognizer(closeTapGesture)
        closeImageView.isUserInteractionEnabled = true
        addSubview(closeImageView)

        resizeImageView.addGestureRecognizer(resizePanGesture)
        resizeImageView.isUserInteractionEnabled = true
        addSubview(resizeImageView)

        addGestureRecognizer(tapGesture)
        addGestureRecognizer(panGesture)
        tapGesture.require(toFail: closeTapGesture)
        tapGesture.require(toFail: resizePanGesture)
        panGesture.require(toFail: closeTapGesture)
        panGesture.require(toFail: resizePanGesture)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let currentScale = self.scale
        self.scale = currentScale
        return bounds.size
    }

    override func layoutSubviews() {
        closeImageView.bounds.size = CGSize(width: 20, height: 20) * scale
        closeImageView.frame.origin = .zero

        resizeImageView.bounds.size = CGSize(width: 20, height: 20) * scale
        resizeImageView.frame.right = bounds.right
        resizeImageView.frame.bottom = bounds.bottom

        labelBgView.frame.origin = CGPoint(x: closeImageView.frame.width / 2, y: closeImageView.frame.height / 2)
        labelBgView.frame.size = CGSize(width: bounds.width - closeImageView.frame.width / 2
                                            - resizeImageView.frame.width / 2,
                                        height: bounds.height - closeImageView.frame.height / 2
                                            - resizeImageView.frame.height / 2)
        labelBgLayer.frame = labelBgView.bounds
        let path = UIBezierPath(roundedRect: labelBgView.bounds, cornerRadius: 3 * scale)
        labelBgLayer.path = path.cgPath
        labelBgLayer.lineWidth = 0.5 * scale
        labelBgLayer.lineDashPattern = [NSNumber(value: 4 * Float(scale)), NSNumber(value: 3 * Float(scale))]

        label.font = UIFont.systemFont(ofSize: 21 * scale)
        label.bounds.size = CGSize(width: ceil(originLabelSize.width * scale) + 3,
                                   height: ceil(originLabelSize.height * scale) + 3)
        label.center = bounds.center
    }
}
