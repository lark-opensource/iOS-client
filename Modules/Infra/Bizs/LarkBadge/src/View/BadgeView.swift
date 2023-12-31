//
//  BadgeView.swift
//  LarkBadge
//
//  Created by 康涛 on 2019/4/4.
//

import Foundation
import UIKit
import SnapKit
import ByteWebImage
import UniverseDesignColor

/// Update UI Style
public extension BadgeView {
    /// 中心点便宜
    /// - Parameters:
    ///   - offsetX: iOS坐标 x
    ///   - offsetY: iOS坐标 y
    func updateOffset(offsetX: CGFloat? = nil, offsetY: CGFloat? = nil) {
        // update Positon
        self.snp.updateConstraints {
            guard let superView = self.superview else { return }
            if let offX = offsetX {
                $0.centerX.equalTo(superView.snp.right).offset(offX)
            }
            if let offY = offsetY {
                $0.centerY.equalTo(superView.snp.top).offset(offY)
            }
        }
    }

    func updateOffset(offsetToRight: CGFloat, offsetToTop: CGFloat) {
        let size = BadgeView.computeSize(for: self.type, style: self.style, maxNumber: nil)
        let offsetX = offsetToRight - size.width / 2
        let offsetY = offsetToTop + size.height / 2
        updateOffset(offsetX: offsetX, offsetY: offsetY)
    }

    /// 更新Badge Size
    /// - Parameter size: CGSize
    func updateSize(to size: CGSize) {
        self.snp.updateConstraints {
            $0.size.equalTo(size)
        }
    }

    /// Label更新Count
    /// - Parameter number: Int
    func updateNumber(to number: Int) {
        self.updateNumber(number: number)
    }

    /// 设置n最大值，超过显示 “...”
    /// - Parameter maxNumber: max
    func setMaxNumber(to maxNumber: Int) {
        self.maxNumber = maxNumber
    }

    /// 设置n最大值，超过显示 “...” 或者仍使用最大数字
    /// - Parameter maxNumber: max
    /// - Parameter forceUseMaxNumber: 有些场景下当超过最大数字后需要强制使用最大数字显示, 用此值可配置
    func setMaxNumber(to maxNumber: Int, forceUseMaxNumber: Bool) {
        self.forceUseMaxNumber = forceUseMaxNumber
        self.maxNumber = maxNumber
    }

    /// 更新Border，需要在setType后调用，因为Type有默认初始化属性
    /// - Parameter width: CGFloat
    func updateBorderWidth(_ width: CGFloat) {
        self.setupBorder(color: UIColor.ud.bgBody, width: width)
    }
}

// 统一Badge样式
public final class BadgeView: UIView {

    public var isZoomable: Bool = false

    private func getCornerRadius(forType type: BadgeType) -> CGFloat {
        return isZoomable ? type.autoCornerRadius : type.cornerRadius
    }

    private func getSize(forType type: BadgeType) -> CGSize {
        return isZoomable ? type.autoSize : type.size
    }

    private func getTextSize(forType type: BadgeType) -> CGFloat {
        return isZoomable ? type.autoTextSize : type.textSize
    }

    public var type: BadgeType = .none {
        didSet {
            self.shouldSetupContentView(newType: type, oldType: oldValue)
            self.updateContent()
        }
    }

    /// 更新样式： Strong/Weak
    public var style: BadgeStyle = .strong {
        didSet {
            guard oldValue != style else { return }
            self.updateStyle()
        }
    }

    // content
    public var contentView: UIView?

    // return contentView as Label
    public var label: UILabel? {
        return contentView as? UILabel
    }

    // return contentView as ImageView
    public var imageView: UIImageView? {
        return contentView as? UIImageView
    }

    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        self.superview?.lkBadgeView = self
    }

    private var borderWidth: CGFloat?
    private var maxNumber: Int?

    public override func removeFromSuperview() {
        self.superview?.lkBadgeView = nil
        super.removeFromSuperview()
    }

    public convenience init(with type: BadgeType) {
        self.init()
        self.type = type
        self.setupUI()
    }

    public convenience init(with type: BadgeType, in superView: UIView) {
        self.init()
        self.type = type
        // superView生命周期只会有一个BadgeView，后面拿这个做Update
        guard superView.lkBadgeView == nil else { return }
        // 默认约束右上角
        superView.addSubview(self)
        self.snp.makeConstraints {
            $0.centerX.equalTo(superView.snp.right)
            $0.centerY.equalTo(superView.snp.top)
            $0.size.equalTo(getSize(forType: type))
        }
        self.setupUI()
    }

    // 当超过最大数字后仍使用最大数字显示, 用此值可配置
    public var forceUseMaxNumber = false

    private func setupUI() {
        self.setupContentView(with: type)
        self.setupLabel(textSize: getTextSize(forType: type))
        self.updateContent()
    }

    private init() {
        super.init(frame: .zero)
        self.isUserInteractionEnabled = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // 相同type，只设置一次
    private func setupBaseUIStyle(type: BadgeType) {
        self.setupBackColor(backgroundColor: type.backgroundColor, cornerRadius: getCornerRadius(forType: type))
        self.setupBorder(color: type.borderColor, width: type.borderWidth)
        self.updateSize(to: getSize(forType: type))
        self.updateStyle()
    }

    private func updateStyle() {
        guard self.type.enableBadgeStyle else { return }
        // Label More图片 update
        if moreIconIsShown {
            self.moreIcon?.image = self.style.moreImage.source
        }

        self.contentView?.backgroundColor = self.style.backgroundColor
        self.label?.textColor = self.style.textColor
    }

    private func updateContent() {
        switch self.type {
        case let .label(.number(count)), let .label(.plusNumber(count)):
            self.updateNumber(number: count)
        case let .label(.text(text)):
            self.updateText(text: text)
        case .image:
            self.setupImageView(with: self.type)
        case .icon:
            self.setupImageView(with: self.type)
        default: break
        }
    }

    private func shouldSetupContentView(newType: BadgeType, oldType: BadgeType) {
        // type不一致才重新设置Cotent
        guard newType != oldType else { return }
        self.lastText = nil
        self.contentView?.removeFromSuperview()
        self.contentView = nil
        if self.moreIconIsShown { self.moreIcon?.isHidden = true }
        self.setupUI()
    }

    private func setupContentView(with type: BadgeType) {
        self.isHidden = false
        guard let view = type.view else {
            self.isHidden = true
            return
        }

        self.contentView = view
        self.addBadgeSubview(view)
        self.setupBaseUIStyle(type: type)
    }

    private func addBadgeSubview(_ view: UIView) {
        self.addSubview(view)
        // content默认吸附容器四边
        view.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    // 上一次的，减少不必要的刷新
    private var lastText: String?

    // Label超过999显示Icon
    private var moreIconIsShown = false
    private lazy var moreIcon: UIImageView? = {
        let moreIcon: BadgeType = .image(.default(self.style.moreImage))
        let imgView = moreIcon.view as? UIImageView ?? UIImageView()
        self.addBadgeSubview(imgView)
        return imgView
    }()

    public override func layoutSubviews() {
        if self.layer.cornerRadius > 0 {
            self.contentView?.layer.cornerRadius
                = (self.frame.size.height - 2*(self.borderWidth ?? 0)) / 2.0
        }
    }

    /// 计算Badge的大小
    /// - Parameters:
    ///   - type: badge的类型
    ///   - style: badge的风格
    ///   - maxNumber: 数字badge最大值
    /// - Returns: 实际BadgeView的大小
    /// - Note: 如果修改这里的代码，那么也要同步修改`updateText`的代码，因为Badge的代码已经没有人能很清楚的解释过程，所以没有替换那个方法中的代码，以免发生意想不到的情况，这里的计算
    public static func computeSize(for type: BadgeType, style: BadgeStyle, maxNumber: Int?) -> CGSize {
        let autoZoom: Bool = false
        if case .label(let badgeLabel) = type {
            var displayText: String
            var newLabel = UILabel()
            let font = UIFont.systemFont(ofSize: autoZoom ? type.autoTextSize : type.textSize, weight: .medium)
            newLabel.font = font
            switch badgeLabel {
            case .number(let number):
                displayText = String(number)
                if number > maxNumber ?? BadgeType.maxNumber {
                    return BadgeType.image(.default(style.moreImage)).size
                }
                newLabel.text = displayText
            case .plusNumber(let number):
                displayText = "\(BadgeLabel.plus)\(String(number))"
                if number > maxNumber ?? BadgeType.maxNumber {
                    return BadgeType.image(.default(style.moreImage)).size
                }
                let str: NSMutableAttributedString = NSMutableAttributedString(string: displayText)
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .center
                paragraphStyle.maximumLineHeight = font.lineHeight + 3
                str.setAttributes([.paragraphStyle: paragraphStyle], range: NSRange(location: 0, length: 1))
                str.addAttributes([.baselineOffset: 1], range: NSRange(location: 0, length: 1))
                newLabel.text = displayText
                newLabel.attributedText = str
            case .text(let string):
                displayText = string
                newLabel.text = displayText
            }
            let textSize = newLabel.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude,
                                                        height: (autoZoom ? type.autoSize : type.size).height))
            var width = textSize.width + type.horizontalMargin + 2 * type.borderWidth
            // 不能小于半径
            width = max(width, (autoZoom ? type.autoCornerRadius : type.cornerRadius) * 2)
            // 外界指定size优先
            width = max(width, (autoZoom ? type.autoSize : type.size).width)
            return CGSize(width: width, height: (autoZoom ? type.autoSize : type.size).height)
        } else if type == .clear {
            return .zero
        } else {
            return autoZoom ? type.autoSize : type.size
        }
    }
}

// Base Config
internal extension BadgeView {
    func setupBorder(color: UIColor, width: CGFloat) {
        // border
        self.backgroundColor = color
        self.borderWidth = width
        self.contentView?.snp.updateConstraints({ (make) in
            make.edges.equalToSuperview().inset(width)
        })
    }

    func setupBackColor(backgroundColor: UIColor, cornerRadius: CGFloat) {
        self.contentView?.backgroundColor = backgroundColor
        self.contentView?.layer.masksToBounds = true
        self.layer.masksToBounds = true
        self.layer.cornerRadius = cornerRadius
        self.layer.allowsEdgeAntialiasing = true
    }
}

// Label
internal extension BadgeView {
    // update Label Props
    func setupLabel(textSize: CGFloat, textColor: UIColor? = nil) {
        guard let label = self.label else { return }
        // props
        label.textColor = textColor ?? .white
        label.font = UIFont.systemFont(ofSize: textSize, weight: .medium)
    }

    func updateText(text: String) {
        self.isHidden = text.isEmpty
        self.updateText(
            text: text,
            size: getSize(forType: type),
            cornerRadius: getCornerRadius(forType: type),
            horizontalMargin: type.horizontalMargin,
            borderWidth: type.borderWidth
        )
    }

    func updateNumber(number: Int) {
        self.updateText(
            number: number,
            size: getSize(forType: type),
            cornerRadius: getCornerRadius(forType: type),
            horizontalMargin: type.horizontalMargin,
            borderWidth: type.borderWidth
        )
    }

    // 更新Label Size
    /// ⚠️如果修改这里的计算大小方法，那么一定要去同步修改`computeSize`这个方法，让两个方法的计算大小的结果一致，否则会发生意想不到的情况
    func updateText(
        text: String? = nil,
        number: Int? = nil,
        size: CGSize,
        cornerRadius: CGFloat,
        horizontalMargin: CGFloat,
        borderWidth: CGFloat,
        forceLayout: Bool = false
    ) {
        // resize Label
        guard let label = self.label else { return }

        var displayText = text ?? ""
        if let number = number {
            displayText = String(number)
            let maxNumber = self.maxNumber ?? BadgeType.maxNumber
            if case .label(.plusNumber) = self.type {
                let displayNumber = self.forceUseMaxNumber && number > maxNumber ? maxNumber : number
                displayText = "\(BadgeLabel.plus)\(String(displayNumber))"
            }
            self.isHidden = number <= 0

            if number > maxNumber, !self.forceUseMaxNumber {
                self.label?.isHidden = true
                self.moreIcon?.isHidden = false
                self.lastText = nil
                self.moreIcon?.image = self.style.moreImage.source
                self.setupBaseUIStyle(type: .image(.default(self.style.moreImage)))
                self.moreIconIsShown = true
                return
            } else if self.moreIconIsShown {
                self.moreIcon?.isHidden = true
                self.label?.isHidden = false
                self.lastText = nil
                self.setupBaseUIStyle(type: self.type)
            }
        }

        // 一致不刷新
        guard self.lastText != displayText || forceLayout else { return }
        self.lastText = displayText

        label.text = displayText
        if case .label(.plusNumber) = self.type, displayText.contains(BadgeLabel.plus) {
            let str: NSMutableAttributedString = NSMutableAttributedString(string: displayText)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            paragraphStyle.maximumLineHeight = label.font.lineHeight + 3
            str.setAttributes([.paragraphStyle: paragraphStyle], range: NSRange(location: 0, length: 1))
            str.addAttributes([.baselineOffset: 1], range: NSRange(location: 0, length: 1))
            label.attributedText = str
        }

        let textSize = label.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude,
                                                 height: size.height))
        var width = textSize.width + horizontalMargin + 2 * borderWidth
        // 不能小于半径
        width = max(width, cornerRadius * 2)
        // 外界指定size优先
        width = max(width, size.width)

        self.snp.updateConstraints {
            $0.width.equalTo(width)
        }
    }
}

// ImageView
internal extension BadgeView {
    // update UIImageView Props
    func setupImageView(with type: BadgeType) {
        guard let imageView = self.imageView else { return }
        contentView?.backgroundColor = .clear

        // 设置图片资源
        switch type {
        case .image(.default(let defaultImage)): imageView.image = defaultImage.source
        case .image(.locol(let name)): imageView.image = UIImage(named: name)
        case .image(.web(let url)): imageView.bt.setLarkImage(with: .default(key: url.absoluteString))
        case .image(.image(let img)): imageView.image = img
        case .image(.key(let key)): imageView.bt.setLarkImage(with: .default(key: key),
                                                              cacheName: LarkImageService.shared.thumbCache.name)
        case .icon(let img, let color):
            imageView.image = img
            imageView.contentMode = .center
            self.contentView?.backgroundColor = color
        default: return
        }
    }
}
