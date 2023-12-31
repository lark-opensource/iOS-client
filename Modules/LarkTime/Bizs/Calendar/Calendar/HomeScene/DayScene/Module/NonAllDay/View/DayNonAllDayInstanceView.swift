//
//  DayNonAllDayInstanceView.swift
//  Calendar
//
//  Created by 张威 on 2020/8/16.
//

import UIKit
import RichLabel
import Foundation
import LarkContainer
import LarkInteraction

/// DayScene - NonAllDay - InstanceView

// MARK: ViewData

protocol DayNonAllDayInstanceViewDataType {
    // 日程块唯一标识符
    var uniqueId: String { get }
    // 日程 title
    var layoutedTitle: DayScene.LayoutedText { get set }
    // 日程 subtitle
    var layoutedSubtitle: DayScene.LayoutedText? { get }
    // icon的点击热区
    var iconTapRect: CGRect? { get }
    var isSelectedTapIcon: Bool { get }
    // 日程 type icon（google/exchange/local）
    var typeIcon: (image: UIImage, tintColor: UIColor)? { get }
    var backgroundColor: UIColor { get }
    var indicatorInfo: (color: UIColor, isStripe: Bool)? { get }
    var dashedBorderColor: UIColor? { get }
    var stripColors: (background: UIColor, foreground: UIColor)? { get }
    var maskOpacity: Float? { get }
    var borderColor: UIColor? { get }
    mutating func updateUI()
}

// MARK: Delegate

protocol DayNonAllDayInstanceViewDelegate: AnyObject {
    func respondsToTap(from sender: DayNonAllDayInstanceView)
    func tapIconRespondsToTap(from sender: DayNonAllDayInstanceView, isSelected: Bool)
}

// MARK: View

final class DayNonAllDayInstanceView: UIView, ViewDataConvertible, UIGestureRecognizerDelegate {
    struct Config {
        static let borderWidth: CGFloat = 1
    }

    let tapGesture = UITapGestureRecognizer()
    var calendarSelectTracer: CalendarSelectTracer?

    var viewData: DayNonAllDayInstanceViewDataType? {
        didSet {
            guard let viewData = viewData else {
                isHidden = true
                return
            }
            isHidden = false
            updateView(with: viewData)
        }
    }

    weak var delegate: DayNonAllDayInstanceViewDelegate?

    // MARK: 基本元素

    private let contentView = UIView() // title、subtitle、tyepImage 的容器
    private let titleLabel = LKLabel()
    private let subtitleLabel = UILabel()
    private let typeImageView = UIImageView()

    // MARK: 装饰元素
    // 背景
    private var backgroundLayer = CALayer()

    // 条纹
    private var stripLayers = (background: CAReplicatorLayer(), line: CALayer())
    // 日程块区分-外边框
    private let borderLayer = CALayer()
    // 虚线-内边框
    private let dashedBorder = DashedBorder()
    // 蒙层
    private let maskLayer = CALayer()
    // indicator
    private let indicator = Indicator()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.clear

        layer.masksToBounds = true
        backgroundLayer.masksToBounds = true
        backgroundLayer.cornerRadius = 4
        layer.addSublayer(backgroundLayer)

        stripLayers.background.instanceTransform = CATransform3DMakeTranslation(15, 0, 0)
        stripLayers.line.anchorPoint = CGPoint(x: 1, y: 0)
        stripLayers.line.frame = CGRect(x: 1, y: 0, width: 5, height: 1200 * 1.5)
        stripLayers.line.setAffineTransform(CGAffineTransform(rotationAngle: .pi / 4))
        stripLayers.background.addSublayer(stripLayers.line)
        backgroundLayer.addSublayer(stripLayers.background)

        borderLayer.borderWidth = Config.borderWidth
        borderLayer.cornerRadius = 5
        dashedBorder.lineDashPattern = [3, 1.5]

        contentView.isUserInteractionEnabled = false
        addSubview(contentView)
        
        titleLabel.numberOfLines = 0
        titleLabel.backgroundColor = .clear
        contentView.addSubview(titleLabel)

        subtitleLabel.numberOfLines = 0
        contentView.addSubview(subtitleLabel)

        layer.addSublayer(dashedBorder)
        layer.addSublayer(borderLayer)

        indicator.lineDashPattern = [2.5, 2.5]
        backgroundLayer.addSublayer(indicator)

        typeImageView.isUserInteractionEnabled = false
        contentView.addSubview(typeImageView)

        maskLayer.cornerRadius = 4
        layer.addSublayer(maskLayer)

        addGestureRecognizer(tapGesture)
        tapGesture.addTarget(self, action: #selector(handleClick))
        tapGesture.delegate = self
        if #available(iOS 13.4, *) {
            let pointer = PointerInteraction(
                style: .init(effect: .hover(prefersScaledContent: false))
            )
            self.addLKInteraction(pointer)
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
        typeImageView.frame = CGRect(x: bounds.size.width - 16, y: 3, width: 13, height: 13)
        borderLayer.frame = bounds
        backgroundLayer.frame = bounds.insetBy(dx: 1, dy: 1)
        maskLayer.frame = bounds
        dashedBorder.updateWith(rect: bounds.insetBy(dx: 1.5, dy: 1.5), cornerWidth: 4)
        indicator.updateWith(iWidth: 3.0, iHeight: bounds.height)
        stripLayers.background.frame = CGRect(x: 0, y: 0, width: backgroundLayer.frame.width, height: backgroundLayer.frame.height)
        stripLayers.background.instanceCount = Int(bounds.width + bounds.height) / 15 + 1
    }

    @objc
    private func handleClick() {
        delegate?.respondsToTap(from: self)
    }
    
    private func tapIconTapped() {
        guard let isSelectedTapIcon = viewData?.isSelectedTapIcon else { return }
        delegate?.tapIconRespondsToTap(from: self, isSelected: !isSelectedTapIcon)
    }

    private func updateView(with data: ViewDataType) {
        // contentView
        contentView.frame = bounds
        contentView.clipsToBounds = true
        // title and subtitle
        titleLabel.attributedText = data.layoutedTitle.text
        titleLabel.frame = data.layoutedTitle.frame
        titleLabel.preferredMaxLayoutWidth = data.layoutedTitle.frame.size.width
        titleLabel.invalidateIntrinsicContentSize()
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

        updateLayerTask {
            updateLayers()
        }
        func updateLayers() {
            // background
            backgroundLayer.ud.setBackgroundColor(data.backgroundColor, bindTo: self)
            // dashedBorder
            if let dashedColor = data.dashedBorderColor {
                dashedBorder.ud.setStrokeColor(dashedColor, bindTo: self)
                dashedBorder.isHidden = false
            } else {
                dashedBorder.isHidden = true
            }
            borderLayer.ud.setBorderColor(data.borderColor ?? .ud.calEventViewBg, bindTo: self)
            maskLayer.ud.setBackgroundColor(UIColor.ud.bgBody)
            
            // indicator
            if let (indicatorColor, isStripe) = data.indicatorInfo {
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
                stripLayers.background.ud.setBackgroundColor(.ud.calEventViewBg)
                stripLayers.line.ud.setBackgroundColor(stripColors.foreground)
            } else {
                stripLayers.background.isHidden = true
                stripLayers.line.isHidden = true
            }
        }
        calendarSelectTracer?.end()
    }
    
    // shouldBegin时判断是否点在icon热区里，在的话则让icon响应点击事件
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let location = gestureRecognizer.location(in: self)
        if gestureRecognizer is UITapGestureRecognizer, gestureRecognizer != tapGesture {
            return false
        }
        if gestureRecognizer == tapGesture, let iconTapRect = self.viewData?.iconTapRect, iconTapRect.contains(location) {
            tapIconTapped()
            return false
        }
        return true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        /// 重新刷新一下， 否则Light/Dark模式切换会不立即刷新
        guard let viewData = viewData else { return }
        updateView(with: viewData)
    }
}

extension DayNonAllDayInstanceView: Poolable { }

extension UIView {
    // 消除 layers 的隐式动画, 预期所有对layer颜色、frame等操作都需要通过此方法wrapper
    func updateLayerTask(_ task: () -> Void) {
        defer { CATransaction.commit() }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        task()
    }
}
