//
//  DaysInstanceView.swift
//  Calendar
//
//  Created by zhouyuan on 2018/9/5.
//  Copyright © 2018年 EE. All rights reserved.
//

import UniverseDesignIcon
import UIKit
import AudioToolbox
import CalendarFoundation
import RxSwift
import RustPB
import LarkInteraction

protocol DaysInstanceViewContent: InstanceBaseInfo {
    var uniqueId: String { get }
    var instanceId: String { get }
    var locationText: String? { get }
    var typeIconTintColor: UIColor? { get }
    var startMinute: Int32 { get set }
    var endMinute: Int32 { get set }
    /// instance 的frame
    var frame: CGRect? { get set }
    /// frame的比例
    var instancelayout: InstanceLayout? { get set }
    var index: Int { get set }
    /// title 的 frame 和 attribute
    var titleStyle: LabelStyle? { get set }
    /// subTitle 的 frame 和 attribute
    var subTitleStyle: LabelStyle? { get set }
    /// 忙闲日程块圆角，会议室视图无圆角
    var cornerRadius: CGFloat? { get set }
    /// 层级
    var zIndex: Int? { get set }
    var isEditable: Bool { get }
    var isGoogleSource: Bool { get }
    var isExchangeSource: Bool { get }
    var isCrossDay: Bool { get }
    var isNewEvent: Bool { get }
    var userInfo: [String: Any] { get set }
    var isCoverPassEvent: Bool { get }
    var maskOpacity: Float { get }
    /// 是否应该隐藏自身
    var shouldHideSelf: Bool { get }
    /// 是否通过拖动日程块上下边缘做到改变自身view的时间
    var isDragBorderToChangeTime: Bool { get set }
    var selfAttendeeStatus: Calendar_V1_CalendarEventAttendee.Status { get }
    /// 会议室类型，用于会议室忙闲不可新建日程 toast 精细化（protocol 原因，其他场景勿用）
    var meetingRoomCategory: Calendar_V1_CalendarEvent.Category { get }
}

final class DaysInstanceView: UIControl, Poolable {

    var didClicked: ((DaysInstanceViewContent?) -> Void)?

    private(set) var content: DaysInstanceViewContent?

    private lazy var lineView: UIView = {
        let lineView = UIView()
        lineView.backgroundColor = UIColor.ud.N500
        lineView.isHidden = true
        return lineView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor.clear
        label.isUserInteractionEnabled = false
        label.clipsToBounds = true
        label.isHidden = true
        label.numberOfLines = 0
        label.lineBreakMode = .byTruncatingTail
        self.layer.insertSublayer(coverLayer, above: label.layer)
        return label
    }()

    private lazy var subTitleLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor.clear
        label.isUserInteractionEnabled = false
        label.isHidden = true
        label.numberOfLines = 0
        self.layer.insertSublayer(coverLayer, above: label.layer)
        return label
    }()

    private let coverLayer: InstanceCoverLayer = InstanceCoverLayer()

    private lazy var dashLineLayer: CAShapeLayer = {
        var layer = CAShapeLayer()
        layer.lineDashPattern = [2, 2]
        layer.fillColor = nil
        return layer
    }()

    private let backgroundLayer = CAReplicatorLayer()
    private let scripLayer = CALayer()

    private lazy var borderLayer: CALayer = {
        let layer = CALayer()
        layer.borderWidth = 1
        return layer
    }()

    private static let googleImage = UIImage.cd.image(named: "googleFlagShape_highlighted") // 透明图暂时不换
        .withRenderingMode(.alwaysTemplate)
    private static let exchangeImage = UIImage.cd.image(named: "exchangeFlagShape")
        .withRenderingMode(.alwaysTemplate) // 透明图暂时不换
    private static let localImage = UIImage.cd.image(named: "localFlagShape")
        .withRenderingMode(.alwaysTemplate) // 透明图暂时不换

    private lazy var cornerImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    private lazy var newEventLabel: UILabel = {
        let label = UILabel.cd.titleLabel(fontSize: 14)
        label.textAlignment = .center
        self.addSubview(label)
        label.isHidden = true
        return label
    }()

    private lazy var bottomBorder: CALayer = {
        let layer = CALayer()
        layer.ud.setBackgroundColor(UIColor.ud.bgBody, bindTo: self)
        layer.isHidden = true
        return layer
    }()

    /// 手势
    private(set) var tapGesture = UITapGestureRecognizer()
    private var canLongPress: Bool

    // 虚线-内边框
    private let dashedBorder = DashedBorder()

    // indicator
    private let indicator = Indicator()

    required init() {
        canLongPress = true
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.bgBody
        self.layer.masksToBounds = true

        self.layoutStrip(replicatorLayer: backgroundLayer,
                         instanceLayer: scripLayer)
        indicator.lineDashPattern = [2.5, 2.5]
        self.layer.addSublayer(indicator)
        self.layer.addSublayer(borderLayer)
        self.layer.addSublayer(bottomBorder)
        dashedBorder.lineDashPattern = [3, 1.5]
        self.layer.addSublayer(dashedBorder)
        self.layer.addSublayer(coverLayer)
        self.addSubview(cornerImageView)

        self.setupGesture(tapGesture: tapGesture)

        // iPad instance hover效果
        if #available(iOS 13.4, *) {
            let pointer = PointerInteraction(
                style: .init(effect: .hover(prefersScaledContent: false))
            )
            self.addLKInteraction(pointer)
        }

        self.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.left.equalToSuperview().offset(6)
            $0.top.equalToSuperview().offset(3)
            $0.right.lessThanOrEqualToSuperview()
            $0.bottom.lessThanOrEqualToSuperview()
        }


        titleLabel.addSubview(lineView)
        lineView.snp.makeConstraints {
            $0.left.equalToSuperview().offset(6)
            $0.centerY.equalToSuperview()
            $0.height.equalTo(2)
            $0.width.equalToSuperview().offset(-12)
        }

        self.addSubview(subTitleLabel)

    }

    func cleanGuestrue() {
        self.canLongPress = false
        self.tapGesture.isEnabled = false
    }

    private func setupGesture(tapGesture: UITapGestureRecognizer) {
        tapGesture.addTarget(self, action: #selector(onPress(_:)))
        self.addGestureRecognizer(tapGesture)
    }

    let throttler = Throttler(delay: 1)
    @objc
    private func onPress(_ gesture: UITapGestureRecognizer) {
        let content = self.content
        throttler.call { [weak self] in
            self?.didClicked?(content)
            operationLog(optType: CalendarOperationType.threeDetail.rawValue)
        }
    }

    private func layoutStrip(replicatorLayer: CAReplicatorLayer, instanceLayer: CALayer) {
        replicatorLayer.instanceTransform = CATransform3DMakeTranslation(15, 0, 0)
        self.layer.addSublayer(replicatorLayer)

        instanceLayer.anchorPoint = CGPoint(x: 1, y: 0)
        instanceLayer.frame = CGRect(x: 1, y: 0, width: 5, height: 1200 * 1.5)
        let transform = CGAffineTransform(rotationAngle: .pi / 4)
        instanceLayer.setAffineTransform(transform)
        replicatorLayer.addSublayer(instanceLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        // CALayer改变frame会有一个隐式动画，需要去掉
        CATransaction.setDisableActions(true)

        borderLayer.frame = self.bounds.insetBy(dx: -0.3, dy: -0.3)
        bottomBorder.frame = CGRect(x: 0,
                                    y: self.bounds.height - 1,
                                    width: self.bounds.width,
                                    height: 1)

        backgroundLayer.frame = self.bounds
        backgroundLayer.instanceCount = Int(self.bounds.width + self.bounds.height) / 15 + 1
        let cornerImageViewFrame = CGRect(x: self.bounds.width - 16, y: 3, width: 13, height: 13)
        cornerImageView.frame = cornerImageViewFrame

        dashLineLayer.frame = layer.bounds
        dashLineLayer.path = UIBezierPath(rect: layer.bounds).cgPath

        indicator.updateWith(iWidth: 3.0, iHeight: bounds.height)
        dashedBorder.updateWith(rect: bounds.insetBy(dx: 1.5, dy: 1.5), cornerWidth: 3)

        coverLayer.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height)
        CATransaction.commit()
        guard let content = content else {
            return
        }

        /// 支持拖拽
        setupLabels(content: content)
        CalendarMonitorUtil.endTrackHomePageLoad()
    }

    func updateContent(content: DaysInstanceViewContent) {
        CATransaction.begin()
        // CALayer改变frame会有一个隐式动画，需要去掉
        CATransaction.setDisableActions(true)
        self.content = content
        if let cornerRadius = content.cornerRadius {
            layer.cornerRadius = cornerRadius
            borderLayer.cornerRadius = cornerRadius
        } else {
            layer.cornerRadius = 0
            borderLayer.cornerRadius = 0
        }
        borderLayer.ud.setBorderColor(.ud.bgBody, bindTo: self)

        coverLayer.update(with: content.endDate, isCoverPassEvent: content.isCoverPassEvent, maskOpacity: content.maskOpacity)
        coverLayer.ud.setBackgroundColor(UIColor.ud.bgBody, bindTo: self)

        if let (indicatorColor, isStripe) = content.indicatorInfo {
            if isStripe {
                indicator.ud.setStrokeColor(indicatorColor)
                indicator.ud.setBackgroundColor(.ud.bgFloat)
            } else {
                indicator.ud.setStrokeColor(.clear)
                indicator.ud.setBackgroundColor(indicatorColor, bindTo: self)
            }
            indicator.isHidden = false
        } else {
            indicator.isHidden = true
        }

        // dashedBorder
        if let dashedColor = content.dashedBorderColor {
            dashedBorder.ud.setStrokeColor(dashedColor, bindTo: self)
            dashedBorder.isHidden = false
        } else {
            dashedBorder.isHidden = true
        }

        if let stripLineColor = content.stripLineColor {
            self.backgroundColor = UIColor.ud.bgBody
            self.backgroundLayer.isHidden = false
            self.drawStrip(backgroundColor: .ud.bgBody,
                           scripColor: stripLineColor)
        } else {
            self.backgroundLayer.isHidden = true
            backgroundColor = content.backgroundColor
        }

        if let strokeColor = content.strokeDashLineColor {
            layer.addSublayer(dashLineLayer)
            dashLineLayer.ud.setStrokeColor(strokeColor, bindTo: self)
        } else {
            dashLineLayer.removeFromSuperlayer()
        }

        setupCornerImageView(color: content.typeIconTintColor, isGoogleSource: content.isGoogleSource, isExchangeSource: content.isExchangeSource)
        guard let frame = content.frame else {
            assertionFailureLog()
            self.frame = .zero
            return
        }
        self.frame = frame
        self.setupLabels(content: content)
        CATransaction.commit()
    }

    private func setupLabels(content: DaysInstanceViewContent) {
        // 设置删除线
        lineView.isHidden = !content.hasStrikethrough
        guard !content.isNewEvent else {
            newEventLabel.text = content.titleText
            newEventLabel.textColor = content.foregroundColor
            newEventLabel.frame = self.bounds
            newEventLabel.isHidden = false
            return
        }
        if let attributedText = content.titleStyle?.attributedText {
            self.titleLabel.textColor = content.hasStrikethrough ? UIColor.ud.textPlaceholder : content.foregroundColor
            self.titleLabel.attributedText = attributedText
            self.titleLabel.isHidden = false
        } else {
            self.titleLabel.isHidden = true
        }
        if let attributedText = content.subTitleStyle?.attributedText {
            self.subTitleLabel.textColor = content.hasStrikethrough ? UIColor.ud.textPlaceholder : content.foregroundColor
            self.subTitleLabel.attributedText = attributedText
            self.subTitleLabel.frame = content.subTitleStyle?.frame ?? .zero
            self.subTitleLabel.isHidden = false
        } else {
            self.subTitleLabel.isHidden = true
        }

        self.accessibilityIdentifier = "Calendar.DaysInstanceView.title_\(content.titleText)"
    }

    private func setupCornerImageView(color: UIColor?, isGoogleSource: Bool, isExchangeSource: Bool) {
        if color != nil {
            if isGoogleSource {
                cornerImageView.image = DaysInstanceView.googleImage
            } else if isExchangeSource {
                cornerImageView.image = DaysInstanceView.exchangeImage
            } else {
                cornerImageView.image = DaysInstanceView.localImage
            }
            cornerImageView.isHidden = false
            cornerImageView.tintColor = color
        } else {
            cornerImageView.isHidden = true
        }
    }

    func setupBorder(color: UIColor?, zIndex: Int?) {
        bottomBorder.isHidden = true
        if let borderColor = color {
            borderLayer.isHidden = false
            borderLayer.ud.setBorderColor(borderColor, bindTo: self)
        } else {
            guard let zIndex = zIndex, zIndex != 0 else {
                borderLayer.isHidden = true
                bottomBorder.isHidden = false
                return
            }
            // 有日程重叠，故加日程背景色区分
            borderLayer.isHidden = false
            borderLayer.ud.setBorderColor(UIColor.ud.calEventViewBg, bindTo: self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func drawStrip(backgroundColor: UIColor, scripColor: UIColor) {
        backgroundLayer.ud.setBackgroundColor(backgroundColor, bindTo: self)
        scripLayer.ud.setBackgroundColor(scripColor, bindTo: self)
    }

    // 拖拽相关
    var isInEditing: Bool = false
    private lazy var eventMaskView: UIView = {
        let eventMaskView = UIView()
        eventMaskView.backgroundColor = UIColor.ud.bgBody
        eventMaskView.alpha = 0.5
        return eventMaskView
    }()

}
