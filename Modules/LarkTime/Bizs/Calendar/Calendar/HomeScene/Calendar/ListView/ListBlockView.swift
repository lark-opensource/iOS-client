//
//  EventInstanceView.swift
//  Calendar
//
//  Created by zhouyuan on 2018/8/7.
//  Copyright © 2018年 EE. All rights reserved.
//
import UIKit
import Foundation
import LarkInteraction
import CalendarFoundation
import UniverseDesignIcon
import UniverseDesignDialog

protocol ListBlockViewContent: InstanceBaseInfo {
    var dotColor: UIColor { get }
    var timeDes: String { get }
    var timeText: String { get }
    var icon: (image: UIImage, isSelected: Bool, expandTapInset: UIEdgeInsets)? { get }
    var locationText: String { get }
    var cornerImageColor: UIColor? { get }
    var strikethroughColor: UIColor { get }
    var sourceIcon: UIImage? { get }
    var isAllDay: Bool { get }
    var isCoverPassEvent: Bool { get }
    var maskOpacity: Float { get }
}

final class ListBlockView: UIView {
    struct Config {
        static let iconSize: CGSize = .init(width: 14, height: 14)
        static let contentLeftPadding: CGFloat = 8
        static let contentLeftPaddingWithIcon: CGFloat = 4
    }

    private var content: ListBlockViewContent?
    private let titleLabel = UILabel.cd.titleLabel(fontSize: 14)
    private let timeDesLabel = UILabel.cd.titleLabel(fontSize: 14)
    private let subTitleLabel = UILabel.cd.subTitleLabel(fontSize: 12)
    private let coverLayer: InstanceCoverLayer = InstanceCoverLayer()
    private let backgroundLayer = CAReplicatorLayer()
    private let scripLayer = CALayer()
    // 虚线-内边框
    private let dashedBorder = DashedBorder()
    // 竖条
    private let indicator = Indicator()

    private let cornerImageView = UIImageView()
    private let iconView = BlockTapIcon()
    private lazy var titleStackView = UIStackView(arrangedSubviews: [iconView, titleLabel, timeDesLabel])
    weak var delegate: EventInstanceViewDelegate?

    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 313, height: 50))
        self.backgroundColor = UIColor.ud.bgBody
        self.layer.masksToBounds = true
        layer.cornerRadius = 4
        dashedBorder.lineDashPattern = [3, 1.5]
        indicator.lineDashPattern = [2.5, 2.5]
        layer.addSublayer(indicator)
        self.layoutStrip(replicatorLayer: backgroundLayer, instanceLayer: scripLayer)
        layer.addSublayer(dashedBorder)
        self.layoutTitleLabel(titleLabel, timeDescLabel: timeDesLabel, iconView: iconView)

        self.layoutSubTitleText(subTitleLabel)
        self.addSubview(cornerImageView)
        self.setCornerImageViewFrame()

        self.layer.addSublayer(coverLayer)
        if #available(iOS 13.4, *) {
            let pointer = PointerInteraction(
                style: .init(effect: .hover(prefersScaledContent: false))
            )
            self.addLKInteraction(pointer)
        }
        // 添加debug工具
        #if !LARK_NO_DEBUG
        if FG.canDebug {
            self.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(longPressed)))
        }
        #endif
    }
    
    @objc
    func longPressed() {
        if let timeBlock = self.content?.userInfo["timeBlock"] as? TimeBlockModel {
            let alert = UDDialog()
            alert.setContent(text: "timeBlock id = \(timeBlock.id)")
            alert.addCancelButton()
            alert.addPrimaryButton(text: I18n.Calendar_Common_Copy, dismissCompletion: {
                UIPasteboard.general.string = timeBlock.id
            })
            self.delegate?.showVC(alert)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        coverLayer.frame = self.bounds
        backgroundLayer.frame = self.bounds
        backgroundLayer.instanceCount = Int(self.bounds.width + self.bounds.height) / 15 + 1
        setCornerImageViewFrame()
        dashedBorder.updateWith(rect: bounds.insetBy(dx: 0.5, dy: 0.5), cornerWidth: 4)
        indicator.updateWith(iWidth: 3.0, iHeight: bounds.height)
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let content = self.content else {
            return
        }
        self.updateContent(content: content)
    }

    func updateContent(content: ListBlockViewContent) {
        defer { CATransaction.commit() }
        CATransaction.begin()
        // CALayer改变frame、颜色等会有一个隐式动画在reload时会导致闪烁，需要去掉
        CATransaction.setDisableActions(true)
        self.content = content

        // dashedBorder
        if let dashedColor = content.dashedBorderColor {
            dashedBorder.ud.setStrokeColor(dashedColor, bindTo: self)
            dashedBorder.isHidden = false
        } else {
            dashedBorder.isHidden = true
        }

        if let (indicatorColor, isStripe) = content.indicatorInfo {
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
        if let icon = content.icon {
            iconView.image = icon.image
            iconView.expandTapInset = icon.expandTapInset
            iconView.isHidden = false
            titleStackView.snp.updateConstraints { (make) in
                make.left.equalToSuperview().offset(Config.contentLeftPaddingWithIcon)
            }
            subTitleLabel.snp.updateConstraints { (make) in
                make.left.equalToSuperview().offset(Config.contentLeftPaddingWithIcon)
            }
        } else {
            iconView.isHidden = true
            titleStackView.snp.updateConstraints { (make) in
                make.left.equalToSuperview().offset(Config.contentLeftPadding)
            }
            subTitleLabel.snp.updateConstraints { (make) in
                make.left.equalToSuperview().offset(Config.contentLeftPadding)
            }
        }

        setupLabels(content: content)

        coverLayer.update(with: content.endDate, isCoverPassEvent: content.isCoverPassEvent, maskOpacity: content.maskOpacity)

        if let stripLineColor = content.stripLineColor {
            self.backgroundColor = UIColor.ud.bgBody
            self.backgroundLayer.isHidden = false
            self.drawStrip(backgroundColor: .ud.calEventViewBg,
                           scripColor: stripLineColor)
        } else {
            self.backgroundLayer.isHidden = true
            backgroundColor = content.backgroundColor
        }
        setupCornerImageView(color: content.cornerImageColor, image: content.sourceIcon)
        coverLayer.backgroundColor = UIColor.ud.bgBody.cgColor
    }

    private func setupLabels(content: ListBlockViewContent) {
        let textColor = content.hasStrikethrough
        ? content.strikethroughColor : content.foregroundColor

        titleLabel.attributedText = content.titleText.attributedText(
            with: titleLabel.font,
            color: textColor,
            hasStrikethrough: content.hasStrikethrough,
            strikethroughColor: content.strikethroughColor,
            lineBreakMode: .byCharWrapping
        )

        if !content.timeDes.isEmpty {
            timeDesLabel.isHidden = false
            timeDesLabel.attributedText = content.timeDes.attributedText(
                with: timeDesLabel.font,
                color: textColor,
                hasStrikethrough: content.hasStrikethrough,
                strikethroughColor: content.strikethroughColor,
                lineBreakMode: .byWordWrapping
            )
        } else {
            timeDesLabel.isHidden = true
        }

        let subTitleTest = content.timeText + " " + content.locationText
        subTitleLabel.attributedText = subTitleTest.attributedText(
            with: subTitleLabel.font,
            color: textColor,
            hasStrikethrough: content.hasStrikethrough,
            strikethroughColor: content.strikethroughColor,
            lineBreakMode: .byWordWrapping
        )
    }

    private func setupCornerImageView(color: UIColor?, image: UIImage?) {
        if color != nil {
            cornerImageView.isHidden = false
            cornerImageView.tintColor = color
        } else {
            cornerImageView.isHidden = true
        }
        cornerImageView.image = image
    }

    private func setCornerImageViewFrame() {
        let cornerViewFrame = CGRect(x: self.bounds.width - 16, y: 3, width: 13, height: 13)
        cornerImageView.frame = cornerViewFrame
    }
    
    private func layoutTitleLabel(_ label: UILabel, timeDescLabel: UILabel, iconView: UIImageView) {
        label.numberOfLines = 1
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        timeDescLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleStackView.axis = .horizontal
        titleStackView.spacing = 8
        titleStackView.setCustomSpacing(4, after: iconView)
        titleStackView.alignment = .center
        self.addSubview(titleStackView)
        titleStackView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(8)
            make.right.lessThanOrEqualToSuperview()
            make.top.equalToSuperview().offset(4)
        }
        iconView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(iconTapped)))
        iconView.snp.makeConstraints { make in
            make.size.equalTo(Config.iconSize)
        }
    }
    
    @objc
    func iconTapped() {
        guard let content, let icon = content.icon else { return }
        self.delegate?.iconTapped(content.userInfo, isSelected: !icon.isSelected)
    }

    private func layoutSubTitleText(_ label: UILabel) {
        label.numberOfLines = 1
        self.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(Config.contentLeftPadding)
            make.right.equalToSuperview().offset(0)
            make.top.equalToSuperview().offset(26)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutStrip(replicatorLayer: CAReplicatorLayer, instanceLayer: CALayer) {
        replicatorLayer.instanceTransform = CATransform3DMakeTranslation(15, 0, 0)
        self.layer.addSublayer(replicatorLayer)

        instanceLayer.anchorPoint = CGPoint(x: 1, y: 0)
        instanceLayer.frame = CGRect(x: 1, y: 0, width: 5, height: self.frame.height * 1.5)
        let transform = CGAffineTransform(rotationAngle: .pi / 4)
        instanceLayer.setAffineTransform(transform)
        backgroundLayer.addSublayer(instanceLayer)
    }

    private func drawStrip(backgroundColor: UIColor, scripColor: UIColor) {
        backgroundLayer.ud.setBackgroundColor(backgroundColor, bindTo: self)
        scripLayer.ud.setBackgroundColor(scripColor, bindTo: self)
    }
}

class BlockTapIcon: UIImageView {
    var expandTapInset: UIEdgeInsets = .zero
    
    init() {
        super.init(frame: .zero)
        self.isUserInteractionEnabled = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let extendedBounds = bounds.inset(by: expandTapInset)
        return extendedBounds.contains(point)
    }
}
