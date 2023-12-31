//
//  NewGuideView.swift
//  LarkGuide
//
//  Created by sniperj on 2020/3/2.
//

import UIKit
import Foundation
import UniverseDesignColor

public final class SwitchUserGuideViewArrow: UIView {

    public init() {
        super.init(frame: CGRect(x: 0,
                                 y: 0,
                                 width: 10,
                                 height: 20))
        self.backgroundColor = UIColor.clear
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding.")
    }

    public override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.ud.primaryContentDefault.cgColor)

        context?.move(to: CGPoint(x: CGFloat(sqrtf(8) / 2),
                                  y: self.bounds.size.height / 2 - CGFloat(sqrtf(8) / 2)))
        context?.addArc(tangent1End: CGPoint(x: 0,
                                             y: self.bounds.height / 2),
                        tangent2End: CGPoint(x: CGFloat(sqrtf(8) / 2),
                                             y: self.bounds.size.height / 2 + CGFloat(sqrtf(8) / 2)), radius: 2)
        context?.addLine(to: CGPoint(x: self.bounds.size.width, y: self.bounds.size.height))
        context?.addLine(to: CGPoint(x: self.bounds.size.width, y: 0))
        context?.closePath()
        context?.drawPath(using: .fill)
    }
}

public final class SwitchUserGuideView: UIView {
    var arrowView: SwitchUserGuideViewArrow!
    var clickBlock: (() -> Void)?
    private let buttonText: String
    private let contentText: String
    private lazy var textSize: CGSize = {
        var attributes = [NSAttributedString.Key.font: UIFont(name: "PingFangSC-Medium", size: 16)]

        var textSize = self.contentText.boundingRect(
            with: CGSize(
                width: 240,
                height: CGFloat.greatestFiniteMagnitude),
            options: NSStringDrawingOptions.usesLineFragmentOrigin,
            attributes: attributes,
            context: nil).size

        textSize.width = ceil(textSize.width)
        textSize.height = ceil(textSize.height)
        return textSize
    }()

    init(contentText: String, buttonText: String) {
        self.buttonText = buttonText
        self.contentText = contentText
        super.init(frame: .zero)
        self.backgroundColor = .clear
        setupUI()
    }

    private func setupUI() {
        arrowView = SwitchUserGuideViewArrow()

        let contentLabel = UILabel()
        contentLabel.text = contentText
        contentLabel.font = UIFont(name: "PingFangSC-Medium", size: 16)
        contentLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        contentLabel.textAlignment = .left
        contentLabel.numberOfLines = 0
        contentLabel.preferredMaxLayoutWidth = 240
        contentLabel.sizeToFit()

        let button = UIButton(type: .custom)
        button.setTitle(buttonText, for: .normal)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.titleLabel?.font = UIFont(name: "PingFangSC-Medium", size: 14)
        button.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        button.layer.cornerRadius = 4
        let size = button.sizeThatFits(.zero)
        button.bounds = CGRect(x: 0,
                               y: 0,
                               width: size.width + 16,
                               height: size.height + 5)
        button.addTarget(self, action: #selector(clickButton), for: .touchUpInside)

        let bgView = UIView()
        bgView.layer.cornerRadius = 2
        bgView.backgroundColor = UIColor.ud.primaryContentDefault
        self.addSubview(bgView)
        bgView.frame = CGRect(x: 10,
                              y: 0,
                              width: textSize.width + 40,
                              height: textSize.height + 16 + button.frame.height + 30)

        contentLabel.frame = CGRect(x: 20,
                                    y: 16,
                                    width: textSize.width,
                                    height: textSize.height)

        button.frame = CGRect(x: bgView.frame.width - button.frame.width - 20,
                              y: contentLabel.frame.minY + contentLabel.frame.height + 10,
                              width: button.frame.width,
                              height: button.frame.height)
        bgView.addSubview(button)
        bgView.addSubview(contentLabel)

        arrowView.frame = CGRect(x: 0,
                                 y: (bgView.frame.height - arrowView.frame.height) / 2,
                                 width: arrowView.frame.width,
                                 height: arrowView.frame.height)
        self.addSubview(arrowView!)
        self.bounds = CGRect(x: 0, y: 0, width: arrowView.frame.width + bgView.frame.width, height: bgView.frame.height)
    }

    func show(focus area: CGRect, toView parentView: UIView) {
        self.frame = CGRect(x: area.minX + area.width + 2, y: area.minY, width: self.frame.width, height: self.frame.height)
        if arrowView.center.y > area.height {
            arrowView.center = CGPoint(x: arrowView.center.x, y: area.height / 2)
        }
        parentView.addSubview(self)
    }

    @objc
    private func clickButton() {
        clickBlock?()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
