//
//  EventBasicCellLikeView.swift
//  Calendar
//
//  Created by 张威 on 2020/2/5.
//

import UniverseDesignIcon
import UniverseDesignColor
import UIKit
import RxSwift
import RxCocoa
import LarkExtensions
import CalendarFoundation
import RichLabel

/// 类似于 UITableViewCell Basic 风格的 View，基本结构如下：
///
///     +--------------------------------------------------------------+
///     |          |                                   |               |
///     |-- Icon --|------------- Content -------------|-- Accessory --|
///     |          |                                   |               |
///     +--------------------------------------------------------------+
///

class EventBasicCellLikeView: UIView {

    typealias Handler = () -> Void
    typealias BackgroundColors = (normal: UIColor, highlight: UIColor)

    public var icon: Icon = .none {
        didSet {
            iconView.image = icon.image
            if case .none = icon {
                iconView.isHidden = true
            } else {
                iconView.isHidden = false
            }
            adjustContentLayout()
            setNeedsLayout()
            layoutIfNeeded()
        }
    }

    public var iconSize: CGSize? {
        didSet {
            if let size = iconSize {
                iconView.snp.updateConstraints { make in
                    make.size.equalTo(size)
                }
            }
        }
    }

    /// 指定 icon 对齐方式
    public var iconAlignment: IconAlignment = .centerVertically {
        didSet {
            iconView.snp.remakeConstraints {
                $0.left.equalToSuperview().inset(iconLeftOffset)
                $0.size.equalTo(iconSize ?? Style.iconSize)
                switch iconAlignment {
                case .centerVertically:
                    $0.centerY.equalToSuperview()
                case .centerYEqualTo(let refView):
                    $0.centerY.equalTo(refView)
                case .topEqualTo(let refView, let offset):
                    $0.top.equalTo(refView).offset(offset)
                case .topByOffset(let offset):
                    $0.top.equalTo(offset)
                }
            }
        }
    }
    
    // 左边icon的偏移
    public var iconLeftOffset: CGFloat = Style.leftInset {
        didSet {
            iconView.snp.updateConstraints { make in
                make.left.equalToSuperview().inset(iconLeftOffset)
            }
        }
    }

    public var accessoryAlignment: AccessoryAlignment = .centerVertically {
        didSet {
            accessoryView.snp.remakeConstraints {
                $0.right.equalToSuperview().inset(Style.rightInset)
                $0.size.equalTo(self.rightIconSize)
                switch accessoryAlignment {
                case .centerVertically:
                    $0.centerY.equalToSuperview()
                case .centerYEqualTo(let refView):
                    $0.centerY.equalTo(refView)
                case .topEqualTo(let refView, let offset):
                    $0.top.equalTo(refView).offset(offset)
                case .topByOffset(let offset):
                    $0.top.equalTo(offset)
                }
            }
        }
    }

    public var content: Content = .none {
        didSet {
            contentContainerView.subviews.forEach { $0.removeFromSuperview() }
            if let view = content.view(in: self) {
                contentContainerView.addSubview(view)
                switch content {
                case .customView, .leftRightTitles, .title, .topBottomTitles:
                    view.snp.remakeConstraints {
                        $0.edges.equalToSuperview().inset(contentInset)
                    }
                // richTitle场景需要保证上下各留13的padding
                case .richTitle:
                    view.snp.remakeConstraints {
                        $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 13, left: 0, bottom: 13, right: 0))
                    }
                case .none:
                    assertionFailure("It`s a error")
                }
            }
        }
    }
    
    // 内容边距
    public var contentInset: UIEdgeInsets = .zero {
        didSet {
            for view in contentContainerView.subviews {
                view.snp.remakeConstraints {
                    $0.edges.equalToSuperview().inset(contentInset)
                }
            }
        }
    }
    
    var spacingAfterIcon: CGFloat {
        Style.spacingAfterIcon
    }
    
    var rightIconSize: CGSize {
        Style.rightIconSize
    }

    private func adjustContentLayout() {
        contentContainerView.snp.updateConstraints {
            var leftOffset = Style.leftInset
            if !iconView.isHidden {
                leftOffset += ((self.iconSize?.width ?? Style.iconSize.width) + spacingAfterIcon)
            }
            $0.left.equalTo(self).offset(leftOffset)

            var rightOffset = 0 - Style.rightInset
            if !accessoryClickableExpandView.isHidden {
                rightOffset -= (Style.accessorySize.width + Style.spacingBeforeAccessory)
            }
            $0.right.equalTo(self).offset(rightOffset)
        }
    }

    public var accessoryRenderType: CalendarFoundation.DarkMode.IconColor = .n2

    public var accessory: Accessory = .none {
        didSet {
            accessoryView.image = accessory.image
            accessoryView.image?.renderColor(with: accessoryRenderType)
            if case .none = accessory {
                accessoryClickableExpandView.isHidden = true
            } else {
                accessoryClickableExpandView.isHidden = false
            }

            adjustContentLayout()
            setNeedsLayout()
        }
    }

    public var onClick: Handler? {
        didSet {
            backgroundView.isUserInteractionEnabled = onClick != nil
        }
    }

    public var onAccessoryClick: Handler? {
        didSet {
            accessoryClickableExpandView.isUserInteractionEnabled = onAccessoryClick != nil
        }
    }

    var backgroundColors: BackgroundColors = (UIColor.ud.bgBody, UIColor.ud.N200) {
        didSet {
            backgroundView.backgroundColors = backgroundColors
        }
    }

    public var onHighLightedChanged: ((Bool) -> Void)? {
        didSet {
            backgroundView.onHighLightedChanged = onHighLightedChanged
        }
    }

    private(set) var backgroundView: BackgroundView = BackgroundView()
    private var iconView: UIImageView = UIImageView()
    private(set) var contentContainerView: UIView = UIView()
    private(set) var aiContentContainerView: UIView = UIView()
    private(set) var accessoryView: UIImageView = UIImageView()
    // 扩大 accesoryView 的可点击范围
    private(set) var accessoryClickableExpandView: UIView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundView.isUserInteractionEnabled = false
        backgroundView.backgroundColors = backgroundColors
        addSubview(backgroundView)
        backgroundView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didViewClick))
        backgroundView.addGestureRecognizer(tapGesture)

        iconView.contentMode = .scaleToFill
        iconView.isUserInteractionEnabled = false
        addSubview(iconView)
        iconView.snp.makeConstraints {
            $0.size.equalTo(Style.iconSize)
            $0.centerY.equalToSuperview()
            $0.left.equalToSuperview().inset(iconLeftOffset)
        }
        iconView.isHidden = true

        accessoryClickableExpandView.isHidden = true
        accessoryClickableExpandView.isUserInteractionEnabled = false
        let accessoryTapGesture = UITapGestureRecognizer(target: self, action: #selector(didAccessoryClick))
        accessoryClickableExpandView.addGestureRecognizer(accessoryTapGesture)
        addSubview(accessoryClickableExpandView)
        accessoryClickableExpandView.snp.makeConstraints {
            $0.width.equalTo(44)
            $0.centerY.right.height.equalToSuperview()
        }

        accessoryView.contentMode = .scaleToFill
        accessoryView.isUserInteractionEnabled = false
        accessoryClickableExpandView.addSubview(accessoryView)
        accessoryView.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.size.equalTo(self.rightIconSize)
            $0.right.equalToSuperview().inset(Style.rightInset)
        }
        
        backgroundView.addSubview(aiContentContainerView)
        backgroundView.addSubview(contentContainerView)
        
        contentContainerView.snp.makeConstraints {
            let leftOffset = Style.leftInset
            $0.left.equalTo(self).offset(leftOffset)
            let rightOffset = 0 - Style.rightInset
            $0.right.equalTo(self).offset(rightOffset)
            $0.height.centerY.equalTo(self)
        }
        
        aiContentContainerView.snp.makeConstraints {
            $0.left.equalTo(contentContainerView.snp.left).offset(-6)
            $0.centerY.equalTo(contentContainerView)
            $0.height.equalTo(44)
            $0.right.equalToSuperview().inset(0)
        }
        aiContentContainerView.layer.cornerRadius = 7
        aiContentContainerView.backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func didViewClick() {
        onClick?()
    }

    @objc
    private func didAccessoryClick() {
        onAccessoryClick?()
    }
    
    func layoutAIBackGround(shouldShowAIBg: Bool, customHeight: CGFloat? = nil, customRight: CGFloat? = nil, customLeftByContentContainer: CGFloat? = nil) {
        if shouldShowAIBg {
            if let customHeight = customHeight{
                aiContentContainerView.snp.updateConstraints {
                    $0.height.equalTo(customHeight)
                }
            }
            
            if let customRight = customRight {
                aiContentContainerView.snp.updateConstraints {
                    $0.right.equalToSuperview().inset(customRight)
                }
            }

            if let customLeft = customLeftByContentContainer {
                aiContentContainerView.snp.updateConstraints {
                    $0.left.equalTo(contentContainerView.snp.left).offset(-customLeft)
                }
            }

            aiContentContainerView.backgroundColor = UDColor.AIPrimaryFillTransparent01(ofSize: aiContentContainerView.bounds.size)
        } else {
            aiContentContainerView.backgroundColor = .clear
        }
    }
}

extension EventBasicCellLikeView {
    enum Style {
        static let iconSize = CGSize(width: 16, height: 16)
        static let rightIconSize = CGSize(width: 16, height: 16)
        static let accessorySize = CGSize(width: 13, height: 13)
        static let leftInset: CGFloat = 16
        static let rightInset: CGFloat = 16
        static let componentSpacing: CGFloat = 16
        static let spacingAfterIcon: CGFloat = 16
        static let spacingBeforeAccessory: CGFloat = 8
    }

    enum Icon {
        // 没有 Icon
        case none
        // 空 Icon，起占位效果
        case empty
        // 自定义 image （带iconN3染色）
        case customImage(UIImage)
        // 自定义 image (不带iconN3染色）
        case customImageWithoutN3(UIImage)
    }

    enum IconAlignment {
        // 垂直居中
        case centerVertically
        // 指定 view 进行 centerY 对齐
        case centerYEqualTo(refView: UIView)
        // 指定 view 进行 top 对齐，加 offset
        case topEqualTo(refView: UIView, _ offset: CGFloat = 0)
        // 指定 top 偏移值
        case topByOffset(CGFloat)
    }

    typealias AccessoryAlignment = IconAlignment

    enum AccessoryType {
        case next(_ iconColor: DarkMode.IconColor = .n3)
        case close
        case fold
        case unfold
        case checkmark
    }

    enum Accessory {
        case none
        case type(AccessoryType)
        case customImage(UIImage)
    }

    struct RichContentTitle {
        var text: String
        var color: UIColor
        var font: UIFont
        var numberOfLines: Int
        var outOfRangeText: String
        var preferMaxWidth: CGFloat
        init(
            text: String,
            color: UIColor = UIColor.ud.N800,
            font: UIFont = UIFont.cd.regularFont(ofSize: 16),
            numberOfLines: Int = 0,
            outOfRangeText: String,
            preferMaxWidth: CGFloat
        ) {
            self.text = text
            self.color = color
            self.font = font
            self.numberOfLines = numberOfLines
            self.outOfRangeText = outOfRangeText
            self.preferMaxWidth = preferMaxWidth
        }
    }

    struct ContentTitle {
        var text: String
        var color: UIColor
        var font: UIFont
        init(
            text: String,
            color: UIColor = UIColor.ud.N800,
            font: UIFont = UIFont.cd.regularFont(ofSize: 16)
        ) {
            self.text = text
            self.color = color
            self.font = font
        }
    }

    enum Content {
        case none
        case title(ContentTitle)
        // 使用LKLabel实现，为了兼容两行文本超长时显示"..., 提醒我"
        case richTitle(RichContentTitle)
        case leftRightTitles(ContentTitle, ContentTitle)
        case topBottomTitles(ContentTitle, ContentTitle)
        case customView(UIView)
    }
}

extension EventBasicCellLikeView.Icon {

    fileprivate var image: UIImage? {
        switch self {
        case .none, .empty: return nil
        case .customImage(let image):
            return image.renderColor(with: .n3)
        case .customImageWithoutN3(let image):
            return image
        }
    }

}

extension EventBasicCellLikeView.Content {

    fileprivate func view(in superView: EventBasicCellLikeView) -> UIView? {
        switch self {
        case .none: return nil
        case .customView(let view): return view
        case .title(let title):
            let label = UILabel()

            label.text = title.text
            label.font = title.font
            label.textColor = title.color
            return label
        case .richTitle(let title):
            let label = LKLabel()

            let attributes: [NSAttributedString.Key: Any] = [.font: title.font, .foregroundColor: title.color]
            label.attributedText = NSAttributedString(string: title.text, attributes: attributes)
            label.backgroundColor = UIColor.ud.bgFloat
            label.preferredMaxLayoutWidth = title.preferMaxWidth
            label.numberOfLines = title.numberOfLines
            label.outOfRangeText = NSAttributedString(string: title.outOfRangeText, attributes: attributes)
            return label
        case .leftRightTitles(let left, let right):
            let leftLabel = UILabel()
            leftLabel.text = left.text
            leftLabel.font = left.font
            leftLabel.textColor = left.color
            leftLabel.textAlignment = .left
            let rightLabel = UILabel()
            rightLabel.text = right.text
            rightLabel.font = right.font
            rightLabel.textColor = right.color
            rightLabel.textAlignment = .right

            let containerView = UIView()
            containerView.addSubview(leftLabel)
            containerView.addSubview(rightLabel)

            leftLabel.snp.makeConstraints { make in
                make.left.centerY.equalToSuperview()
                make.right.equalTo(rightLabel.snp.left)
                make.width.equalTo(rightLabel).multipliedBy(3)
            }

            rightLabel.snp.makeConstraints { make in
                make.right.centerY.equalToSuperview()
            }
            containerView.isUserInteractionEnabled = false
            return containerView
        case .topBottomTitles(let top, let bottom):
            let topLabel = UILabel()
            topLabel.text = top.text
            topLabel.font = top.font
            topLabel.textColor = top.color
            topLabel.textAlignment = .left
            let bottomLabel = UILabel()
            bottomLabel.text = bottom.text
            bottomLabel.font = bottom.font
            bottomLabel.textColor = bottom.color
            bottomLabel.textAlignment = .left

            let containerView = UIView()
            containerView.addSubview(topLabel)
            containerView.addSubview(bottomLabel)

            topLabel.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalToSuperview().offset(12)
                make.height.equalTo(topLabel.font.pointSize + 6)
            }

            bottomLabel.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalTo(topLabel.snp.bottom).offset(4)
                make.height.equalTo(topLabel.font.pointSize + 6)
                make.bottom.equalToSuperview().offset(-12)
            }
            containerView.isUserInteractionEnabled = false
            return containerView
        }
    }

}

extension EventBasicCellLikeView.Accessory {

    fileprivate var image: UIImage? {
        switch self {
        case .none:
            return nil
        case .type(let type):
            let image: UIImage
            switch type {
            case .next(let color): image = UDIcon.getIconByKey(.rightBoldOutlined, size: EventBasicCellLikeView.Style.rightIconSize).renderColor(with: color)
            case .close: image = UDIcon.getIconByKey(.closeBoldOutlined, size: EventBasicCellLikeView.Style.rightIconSize).renderColor(with: .n3)
            case .fold: image = UDIcon.getIconByKey(.downOutlined, size: EventBasicCellLikeView.Style.rightIconSize).renderColor(with: .n2)
            case .unfold: image = UDIcon.getIconByKey(.upOutlined, size: EventBasicCellLikeView.Style.rightIconSize).renderColor(with: .n2)
            case .checkmark: image = UDIcon.getIconByKey(.doneOutlined,
                                                         iconColor: UIColor.ud.primaryContentDefault,
                                                         size: CGSize(width: 20, height: 20))
            }
            return image.withRenderingMode(.alwaysOriginal)
        case .customImage(let image):
            return image
        }
    }

}

extension EventBasicCellLikeView {

    class BackgroundView: UIView {

        private var isHighlighted = false {
            didSet {
                backgroundColor = isHighlighted ? backgroundColors.highlight : backgroundColors.normal
                onHighLightedChanged?(isHighlighted)
            }
        }

        var onHighLightedChanged: ((Bool) -> Void)?

        var backgroundColors: BackgroundColors = (UIColor.ud.bgBody, UIColor.ud.N200) {
            didSet {
                backgroundColor = isHighlighted ? backgroundColors.highlight : backgroundColors.normal
            }
        }

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            isHighlighted = true
            super.touchesBegan(touches, with: event)
        }

        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            isHighlighted = true
            super.touchesMoved(touches, with: event)
        }

        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            isHighlighted = false
            super.touchesEnded(touches, with: event)
        }

        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
            isHighlighted = false
            super.touchesCancelled(touches, with: event)
        }

    }

}

// 编译页特化的cellView
class EventEditCellLikeView: EventBasicCellLikeView {
    override var spacingAfterIcon: CGFloat {
        12
    }
    
    override var rightIconSize: CGSize {
        CGSize(width: 12, height: 12)
    }
}
