//
//  FeedUpgradeTeamGuideView.swift
//  LarkGuide
//
//  Created by mochangxing on 2020/4/14.
//

import UIKit
import Foundation
// import LarkUIKit
import UniverseDesignColor

public final class FeedUpgradeTeamGuideViewArrow: UIView {

    public init() {
        super.init(frame: CGRect(x: 0,
                                 y: 0,
                                 width: 20,
                                 height: 10))
        self.backgroundColor = UIColor.clear
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding.")
    }

    public override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.ud.primaryFillHover.cgColor)
        context?.move(to: CGPoint(x: 0,
                                  y: self.bounds.size.height))
        context?.addLine(to: CGPoint(x: self.bounds.size.width / 2 - CGFloat(sqrtf(8) / 2),
                                     y: CGFloat(sqrtf(8) / 2)))
        context?.addArc(tangent1End: CGPoint(x: self.bounds.size.width / 2,
                                             y: 0),
                        tangent2End: CGPoint(x: self.bounds.size.width / 2 + CGFloat(sqrtf(8) / 2),
                                             y: CGFloat(sqrtf(8) / 2)),
                        radius: 2)
        context?.addLine(to: CGPoint(x: self.bounds.size.width, y: self.bounds.size.height))
        context?.closePath()
        context?.drawPath(using: .fill)
    }
}

public final class FeedUpgradeTeamGuideView: UIView {
    var arrowView: FeedUpgradeTeamGuideViewArrow!
    private let titleText: String
    private let contentText: String
    private lazy var titleTextSize: CGSize = {
        var attributes = [NSAttributedString.Key.font: UIFont(name: "PingFangSC-Medium", size: 16)]
        return calculateTextSize(text: self.titleText, attributes: attributes)
    }()

    private lazy var contentTextSize: CGSize = {
        var attributes = [NSAttributedString.Key.font: UIFont(name: "PingFangSC-Regular", size: 14)]
        return calculateTextSize(text: self.contentText, attributes: attributes)
    }()

    init(titleText: String, contentText: String) {
        self.titleText = titleText
        self.contentText = contentText
        super.init(frame: .zero)
        self.backgroundColor = .clear
        setupUI()
    }

    private func setupUI() {
        arrowView = FeedUpgradeTeamGuideViewArrow()

        let titleLabel = UILabel()
        titleLabel.text = titleText
        titleLabel.font = UIFont(name: "PingFangSC-Medium", size: 16)
        titleLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = 0
        titleLabel.preferredMaxLayoutWidth = 240
        titleLabel.sizeToFit()

        let contentLabel = UILabel()
        contentLabel.text = contentText
        contentLabel.font = UIFont(name: "PingFangSC-Regular", size: 14)
        contentLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        contentLabel.textAlignment = .left
        contentLabel.numberOfLines = 0
        contentLabel.preferredMaxLayoutWidth = 240
        contentLabel.sizeToFit()

        let bgView = UIView()
        bgView.layer.cornerRadius = 2
        bgView.backgroundColor = UIColor.ud.primaryFillHover
        bgView.layer.ud.setShadowColor(UIColor.ud.colorfulBlue)
        bgView.layer.shadowOpacity = 0.3
        bgView.layer.shadowOffset = CGSize(width: 0, height: 5)

        self.addSubview(bgView)
        bgView.frame = CGRect(x: 0,
                              y: 10,
                              width: 280,
                              height: titleTextSize.height + 8 + contentTextSize.height + 30)

        titleLabel.frame = CGRect(x: 20,
                                    y: 16,
                                    width: titleTextSize.width,
                                    height: titleTextSize.height)

        bgView.addSubview(titleLabel)

        contentLabel.frame = CGRect(x: 20,
                                    y: titleLabel.frame.bottom + 8,
                                    width: contentTextSize.width,
                                    height: contentTextSize.height)
        bgView.addSubview(contentLabel)

        arrowView.frame = CGRect(x: (bgView.frame.width - arrowView.frame.width) / 2,
                                 y: 0,
                                 width: arrowView.frame.width,
                                 height: arrowView.frame.height)
        self.addSubview(arrowView!)
        self.bounds = CGRect(x: 0, y: 0, width: arrowView.frame.width + bgView.frame.width, height: bgView.frame.height)
    }

    func show(focus area: CGRect, toView parentView: UIView) {
        self.frame = CGRect(x: area.minX, y: area.minY + area.height + 2, width: self.frame.width, height: self.frame.height)
        if arrowView.center.x > area.width / 2 {
            arrowView.center = CGPoint(x: area.width / 2, y: arrowView.center.y)
        }
        parentView.addSubview(self)
    }

    func calculateTextSize(text: String, attributes: [NSAttributedString.Key: Any]?) -> CGSize {
        var textSize = text.boundingRect(
            with: CGSize(
                width: 240,
                height: CGFloat.greatestFiniteMagnitude),
            options: NSStringDrawingOptions.usesLineFragmentOrigin,
            attributes: attributes,
            context: nil).size

        textSize.width = ceil(textSize.width)
        textSize.height = ceil(textSize.height)
        return textSize
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
