//
//  DayAllDayInstanceView.swift
//  Calendar
//
//  Created by 张威 on 2020/8/10.
//

import UIKit
import LarkExtensions
import LarkInteraction
import LarkContainer

/// DayScene - AllDay - InstanceView

protocol DayAllDayInstanceViewDataType {
    // 日程块唯一标识符
    var uniqueId: String { get }
    // 日程 title
    var layoutedTitle: DayScene.LayoutedText { get }
    // 日程 subtitle
    var layoutedSubtitle: DayScene.LayoutedText? { get }
    var tapIcon: (isSelected: Bool,
                  image: UIImage,
                  canTap: Bool,
                  expandTapInset: UIEdgeInsets,
                  frame: CGRect)? { get }
    // 日程 type icon（google/exchange/local）
    var typeIcon: (image: UIImage, tintColor: UIColor)? { get }
    var backgroundColor: UIColor { get }
    var indicatorInfo: (color: UIColor, isStripe: Bool)? { get }
    var dashedBorderColor: UIColor? { get }
    var stripColors: (background: UIColor, foreground: UIColor)? { get }
    var maskOpacity: Float? { get }
    
    mutating func updateWithViewSetting(_ viewSetting: EventViewSetting)
    mutating func updateMaskOpacity(with viewSetting: EventViewSetting, outOfDay: Bool)
}

final class DayAllDayInstanceView: UIView, ViewDataConvertible, UIGestureRecognizerDelegate {
    enum TapLocation {
        case icon(_ isSelected: Bool)
        case view
    }

    static let padding = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)
    var calendarSelectTracer: CalendarSelectTracer?
    var onClick: ((_ uniqueId: String, _ location: TapLocation) -> Void)?

    var contentOffsetX: CGFloat = 0 {
        didSet {
            guard oldValue != contentOffsetX else { return }
            updateContentOffset()
        }
    }

    var viewData: DayAllDayInstanceViewDataType? {
        didSet {
            guard let viewData = viewData else { return }
            updateView(with: viewData)
        }
    }

    // MARK: 基本元素
    private let containerView = UIView()
    private let tapIcon = BlockTapIcon()
    private let textContainerView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let typeImageView = UIImageView()

    // MARK: 装饰元素

    // 条纹
    private var stripLayers = (background: CAReplicatorLayer(), line: CALayer())
    // 虚线-内边框
    private let dashedBorder = DashedBorder()
    // 蒙层
    private let maskLayer = CALayer()
    // indicator
    private let indicator = Indicator()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.clear

        addSubview(containerView)
        containerView.layer.cornerRadius = 5
        containerView.clipsToBounds = true

        stripLayers.background.instanceTransform = CATransform3DMakeTranslation(15, 0, 0)
        stripLayers.line.anchorPoint = CGPoint(x: 1, y: 0)
        stripLayers.line.frame = CGRect(x: 1, y: 0, width: 5, height: 40 * 1.5)
        stripLayers.line.setAffineTransform(CGAffineTransform(rotationAngle: .pi / 4))
        stripLayers.background.addSublayer(stripLayers.line)
        containerView.layer.addSublayer(stripLayers.background)

        containerView.addSubview(textContainerView)
        textContainerView.addSubview(tapIcon)

        textContainerView.addSubview(titleLabel)

        textContainerView.addSubview(subtitleLabel)

        indicator.lineDashPattern = [2.5, 2.5]
        containerView.layer.addSublayer(indicator)

        dashedBorder.lineDashPattern = [3, 1.5]
        layer.addSublayer(dashedBorder)

        typeImageView.isUserInteractionEnabled = false
        containerView.addSubview(typeImageView)

        maskLayer.ud.setBackgroundColor(UIColor.ud.bgBody, bindTo: self)
        containerView.layer.addSublayer(maskLayer)

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleClick)))
        tapIcon.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(iconHandleClick)))

        if #available(iOS 13.4, *) {
            let pointer = PointerInteraction(
                style: .init(effect: .hover(prefersScaledContent: false))
            )
            self.textContainerView.addLKInteraction(pointer)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var lastBounds: CGRect?
    override var frame: CGRect {
        didSet {
            guard lastBounds != bounds else { return }
            lastBounds = bounds
            updateLayerTask {
                layoutLayers()
            }
        }
    }

    override var bounds: CGRect {
        didSet {
            guard lastBounds != bounds else { return }
            lastBounds = bounds
            updateLayerTask {
                layoutLayers()
            }
        }
    }

    private func layoutLayers() {
        containerView.frame = bounds.inset(by: Self.padding)
        let containerBounds = containerView.bounds

        var textContainerFrame = containerBounds
        textContainerFrame.left = contentOffsetX
        textContainerView.frame = textContainerFrame

        typeImageView.frame = CGRect(
            x: containerBounds.width - 16,
            y: (containerBounds.height - 13) / 2,
            width: 13,
            height: 13
        )

        dashedBorder.updateWith(rect: containerBounds.insetBy(dx: 1.5, dy: 1.5), cornerWidth: 4)
        maskLayer.frame = containerBounds
        indicator.updateWith(iWidth: 3.0, iHeight: containerBounds.height)
        stripLayers.background.frame = containerBounds
        stripLayers.background.instanceCount = Int(containerBounds.width + containerBounds.height) / 15 + 1
    }

    private func updateView(with data: ViewDataType) {
        // title and subtitle
        titleLabel.attributedText = data.layoutedTitle.text
        titleLabel.frame = data.layoutedTitle.frame
        if let tapIconData = data.tapIcon {
            tapIcon.frame = tapIconData.frame
            tapIcon.image = tapIconData.image
            tapIcon.expandTapInset = tapIconData.expandTapInset
            tapIcon.isUserInteractionEnabled = tapIconData.canTap
            tapIcon.isHidden = false
        } else {
            tapIcon.isHidden = true
        }
        if let layoutedSubtitle = data.layoutedSubtitle {
            subtitleLabel.isHidden = false
            subtitleLabel.attributedText = layoutedSubtitle.text
            subtitleLabel.frame = layoutedSubtitle.frame
        } else {
            subtitleLabel.isHidden = true
        }

        // typeIcon
        if let typeIcon = data.typeIcon {
            typeImageView.image = typeIcon.image
            typeImageView.tintColor = typeIcon.tintColor
            typeImageView.isHidden = false
        } else {
            typeImageView.isHidden = true
        }

        // background
        containerView.backgroundColor = data.backgroundColor

        updateLayerTask {
            updateLayers()
        }
        func updateLayers() {
            // dashedBorder
            if let dashedColor = data.dashedBorderColor {
                dashedBorder.ud.setStrokeColor(dashedColor, bindTo: self)
                dashedBorder.isHidden = false
            } else {
                dashedBorder.isHidden = true
            }
            // indicator
            if let (indicatorColor, isStripe) = data.indicatorInfo {
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
            // mask
            if let maskOpacity = data.maskOpacity {
                maskLayer.isHidden = false
                maskLayer.opacity = maskOpacity
            } else {
                maskLayer.isHidden = true
            }
            // strip
            if let stripColors = data.stripColors {
                stripLayers.background.isHidden = false
                stripLayers.line.isHidden = false
                stripLayers.background.ud.setBackgroundColor(.ud.bgBody, bindTo: self)
                stripLayers.line.ud.setBackgroundColor(stripColors.foreground, bindTo: self)
            } else {
                stripLayers.background.isHidden = true
                stripLayers.line.isHidden = true
            }
        }
        calendarSelectTracer?.end()
    }

    private func updateContentOffset() {
        var textContainerFrame = textContainerView.frame
        textContainerFrame.left = contentOffsetX
        textContainerView.frame = textContainerFrame
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let viewData = viewData else { return }
        updateView(with: viewData)
    }
    
    @objc
    private func handleClick() {
        guard let viewData = viewData else {
            assertionFailure()
            return
        }
        onClick?(viewData.uniqueId, .view)
    }

    @objc private func iconHandleClick() {
        guard let viewData = viewData else {
            assertionFailure()
            return
        }
        let isSelected = !(viewData.tapIcon?.isSelected ?? false)
        onClick?(viewData.uniqueId, .icon(isSelected))
    }
}
