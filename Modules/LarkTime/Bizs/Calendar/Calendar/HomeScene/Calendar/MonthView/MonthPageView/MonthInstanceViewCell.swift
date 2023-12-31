//
//  MonthBlockViewCell.swift
//  Calendar
//
//  Created by zhouyuan on 2018/10/23.
//  Copyright © 2018 EE. All rights reserved.
//

import UIKit
import Foundation
import CalendarFoundation
import LarkUIKit
import LarkContainer

protocol MonthBlockViewCellProtocol: InstanceBaseInfo, AnyObject {
    var icon: UIImage? { get }
    var id: String { get }
    var startTime: Int64 { get }
    var endTime: Int64 { get }
    var strikethroughColor: UIColor { get }
    var range: AllDayEventRange { get }
    var isAllDay: Bool { get }
}

final class MonthBlockViewCell: UIView, Poolable {
    struct Config {
        static let iconSize: CGSize = Display.pad ? .init(width: 14, height: 14) : .init(width: 11, height: 11)
        static let iconLeftMarigin: CGFloat = Display.pad ? 4 : 3
        static let iconRightMargin: CGFloat = 4
        static let labelLeftMarigin: CGFloat = Display.pad ? 6.5 : 4
        static let fontSize: CGFloat = Display.pad ? 14 : 11
        static let titleFont = UIFont(name: "PingFangSC-Regular", size: Config.fontSize) ?? UIFont.cd.regularFont(ofSize: Config.fontSize)
    }
    private let titleLabel: CalendarInstanceLabel = {
        let label = InstanceLabelOld()
        label.backgroundColor = UIColor.clear
        return label
    }()
    private let stripeView = StripeView()
    private let cover: InstanceCoverView = {
        let view = InstanceCoverView()
        view.layer.cornerRadius = 2
        return view
    }()
    // 虚线-内边框
    private let dashedBorder = DashedBorder()
    // 竖条
    private var indicator = Indicator()
    private let iconView = UIImageView()

    required init() {
        super.init(frame: .zero)
        self.layer.cornerRadius = Display.pad ? 4 : 2
        layer.masksToBounds = true
        self.addSubview(iconView)
        self.addSubview(stripeView)
        self.addSubview(titleLabel)
        cover.backgroundColor = UIColor.ud.bgBody
        indicator.lineDashPattern = [1.5, 1.5]
        dashedBorder.lineDashPattern = [3, 1]
        layer.addSublayer(indicator)
        layer.addSublayer(dashedBorder)
        self.addSubview(cover)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        // CALayer改变frame会有一个隐式动画，需要去掉
        CATransaction.setDisableActions(true)
        stripeView.frame = self.bounds
        let labelLeftMarigin: CGFloat
        if iconView.isHidden {
            iconView.frame = .zero
            labelLeftMarigin = Config.labelLeftMarigin
        } else {
            iconView.frame = .init(origin: .init(x: Config.iconLeftMarigin, y: (self.bounds.height - Config.iconSize.height) / 2), size: Config.iconSize)
            labelLeftMarigin = Config.iconLeftMarigin + Config.iconSize.width + Config.iconRightMargin
        }
        titleLabel.frame = CGRect(x: labelLeftMarigin,
                                  y: 0,
                                  width: self.bounds.width - 4,
                                  height: self.bounds.height)
        cover.frame = self.bounds

        dashedBorder.updateWith(rect: bounds.insetBy(dx: 1, dy: 1), cornerWidth: 2)
        indicator.updateWith(iWidth: 2.5, iHeight: bounds.height)
        CATransaction.commit()
    }

    func updateContent(model: MonthBlockViewCellProtocol) {
        defer { CATransaction.commit() }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.setupLabel(model: model)
        cover.update(with: model.endDate, isCoverPassEvent: model.isCoverPassEvent, maskOpacity: CGFloat(model.maskOpacity))
        if let stripLineColor = model.stripLineColor {
            self.backgroundColor = UIColor.ud.bgBody
            self.stripeView.isHidden = false
            self.stripeView.drawStrip(backgroundColor: .ud.bgBody,
                                      stripeColor: stripLineColor)
        } else {
            self.backgroundColor = model.backgroundColor
            self.stripeView.isHidden = true
        }
        iconView.isHidden = model.icon == nil
        iconView.image = model.icon
        if let (indicatorColor, isStripe) = model.indicatorInfo {
            if isStripe {
                indicator.ud.setStrokeColor(indicatorColor)
                indicator.ud.setBackgroundColor(.ud.bgFloat)
            } else {
                indicator.ud.setStrokeColor(.clear)
                indicator.ud.setBackgroundColor(indicatorColor)
            }
            indicator.isHidden = false
        } else {
            indicator.isHidden = true
        }

        // dashedBorder
        if let dashedColor = model.dashedBorderColor {
            dashedBorder.ud.setStrokeColor(dashedColor, bindTo: self)
            dashedBorder.isHidden = false
        } else {
            dashedBorder.isHidden = true
        }
        setNeedsLayout()
        layoutIfNeeded()
    }

    private func setupLabel(model: MonthBlockViewCellProtocol) {
        titleLabel.attributedText = model.titleText.attributedText(
            with: MonthBlockViewCell.Config.titleFont,
            color: model.foregroundColor,
            hasStrikethrough: model.hasStrikethrough,
            strikethroughColor: model.strikethroughColor,
            lineBreakMode: .byWordWrapping
        )
    }
}

final class StripeView: UIView {
    private let backgroundLayer = CAReplicatorLayer()
    private let stripeLayer = CALayer()

    init() {
        super.init(frame: .zero)
        self.layer.masksToBounds = true
        self.layoutStrip(replicatorLayer: backgroundLayer, instanceLayer: stripeLayer)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        defer { CATransaction.commit() }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        backgroundLayer.frame = self.bounds
        backgroundLayer.instanceCount = Int(self.bounds.width + self.bounds.height) / 15 + 1
    }

    func drawStrip(backgroundColor: UIColor, stripeColor: UIColor) {
        backgroundLayer.ud.setBackgroundColor(backgroundColor, bindTo: self)
        stripeLayer.ud.setBackgroundColor(stripeColor, bindTo: self)
    }

    private func layoutStrip(replicatorLayer: CAReplicatorLayer, instanceLayer: CALayer) {
        defer { CATransaction.commit() }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        replicatorLayer.instanceTransform = CATransform3DMakeTranslation(15, 0, 0)
        self.layer.addSublayer(replicatorLayer)

        instanceLayer.anchorPoint = CGPoint(x: 1, y: 0)
        instanceLayer.frame = CGRect(x: 1, y: 0, width: 5, height: 1200 * 1.5)
        let transform = CGAffineTransform(rotationAngle: .pi / 4)
        instanceLayer.setAffineTransform(transform)
        replicatorLayer.addSublayer(instanceLayer)
    }
}
