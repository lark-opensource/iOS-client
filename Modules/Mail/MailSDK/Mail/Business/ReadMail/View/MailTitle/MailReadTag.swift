//
//  MailReadTag.swift
//  MailSDK
//
//  Created by zhaoxiongbin on 2021/8/17.
//

import Foundation
import UniverseDesignTag
import SnapKit

class MailReadTag: UIButton {
    private let udTag: UDTag
    private let tagBackgroundColor: UIColor

    var text: String? {
        return udTag.text
    }

    override var isHighlighted: Bool {
        didSet {
            let config = udTag.config
            var newTextConfig: UDTagConfig.TextConfig?
            switch config {
            case .text(var textConfig):
                let newAlpha = tagBackgroundColor.cgColor.alpha * 0.6
                textConfig.backgroundColor = isHighlighted ? tagBackgroundColor.withAlphaComponent(newAlpha) : tagBackgroundColor
                newTextConfig = textConfig
            default:
                break
            }
            if let newTextConfig = newTextConfig {
                udTag.updateUI(textConfig: newTextConfig)
            }
        }
    }

    init(text: String, isLTR: Bool, textColor: UIColor, backgroundColor: UIColor) {
        let udTagConfig = MailReadTag.tagConfig(text: text, isLTR: isLTR, textColor: textColor, bgColor: backgroundColor)
        self.udTag = UDTag(text: text, textConfig: udTagConfig)
        self.tagBackgroundColor = backgroundColor
        super.init(frame: .zero)

        udTag.isUserInteractionEnabled = false
        addSubview(udTag)
        udTag.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        addTarget(self, action: #selector(self.btnTapped(_:)), for: .touchUpInside)
//        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.btnTapped(_:))))
    }

    @objc
    private func btnTapped(_ target: UIControl) {
            print(" k mail tag btn tapped")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var desiredSize: CGSize {
        let maxSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        return UDTag.sizeToFit(config: udTag.config, title: udTag.text, containerSize: maxSize)
    }

    static func tagConfig(text: String, isLTR: Bool, textColor: UIColor, bgColor: UIColor) -> UDTagConfig.TextConfig {
        return UDTagConfig.TextConfig(cornerRadius: 4,
                                      textAlignment: isLTR ? .left : .right,
                                      textColor: textColor,
                                      backgroundColor: bgColor,
                                      maxLenth: nil)
    }

    static func sizeThatFit(text: String, isLTR: Bool) -> CGSize {
        let maxSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        let tagConfig = tagConfig(text: text, isLTR: isLTR, textColor: .black, bgColor: .black)
        return UDTag.sizeToFit(config: .text(tagConfig), title: text, containerSize: maxSize)
    }
}
