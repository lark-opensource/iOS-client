//
//  EventBasicCellLikeView.swift
//  Calendar
//
//  Created by 张威 on 2020/2/5.
//

import UniverseDesignIcon
import UIKit
import RxSwift
import RxCocoa
import LarkExtensions

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
                $0.left.equalToSuperview().inset(Style.leftInset)
                $0.size.equalTo(iconSize ?? Style.iconSize)
                switch iconAlignment {
                case .centerVertically:
                    $0.centerY.equalToSuperview()
                case .centerYEqualTo(let refView):
                    $0.centerY.equalTo(refView)
                case .topEqualTo(let refView):
                    $0.top.equalTo(refView)
                case .topByOffset(let offset):
                    $0.top.equalTo(offset)
                }
            }
        }
    }

    public var accessoryAlignment: AccessoryAlignment = .centerVertically {
        didSet {
            accessoryView.snp.remakeConstraints {
                $0.right.equalToSuperview().inset(Style.rightInset)
                $0.size.equalTo(Style.iconSize)
                switch accessoryAlignment {
                case .centerVertically:
                    $0.centerY.equalToSuperview()
                case .centerYEqualTo(let refView):
                    $0.centerY.equalTo(refView)
                case .topEqualTo(let refView):
                    $0.top.equalTo(refView)
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
                // 当前 Cell copy 自日历编辑页，目前仅 RRule 页面使用，这里为了让 cell 自适应高度，做了一些更改，不会影响其他页面
                view.snp.remakeConstraints {
                    $0.left.right.equalToSuperview()
                    $0.top.equalToSuperview().offset(14)
                    $0.bottom.equalToSuperview().offset(-14)
                }
            }
        }
    }

    private func adjustContentLayout() {
        contentContainerView.snp.updateConstraints {
            var leftOffset = Style.leftInset
            if !iconView.isHidden {
                leftOffset += (Style.iconSize.width + Style.spacingAfterIcon)
            }
            $0.left.equalTo(self).offset(leftOffset)

            var rightOffset = 0 - Style.rightInset
            if !accessoryClickableExpandView.isHidden {
                rightOffset -= (Style.accessorySize.width + Style.spacingBeforeAccessory)
            }
            $0.right.equalTo(self).offset(rightOffset)
        }
    }

    public var accessory: Accessory = .none {
        didSet {
            accessoryView.image = accessory.image
            accessoryView.image?.ud.withTintColor(UIColor.ud.iconN2, renderingMode: .automatic)
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

    private var backgroundView: BackgroundView = BackgroundView()
    private var iconView: UIImageView = UIImageView()
    private(set) var contentContainerView: UIView = UIView()
    private var accessoryView: UIImageView = UIImageView()
    // 扩大 accesoryView 的可点击范围
    private var accessoryClickableExpandView: UIView = UIView()
    private let disposeBag = DisposeBag()

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
            $0.left.equalToSuperview().inset(Style.leftInset)
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
            $0.right.equalToSuperview().inset(Style.rightInset)
        }

        backgroundView.addSubview(contentContainerView)
        contentContainerView.snp.makeConstraints {
            let leftOffset = Style.leftInset
            $0.left.equalTo(self).offset(leftOffset)
            let rightOffset = 0 - Style.rightInset
            $0.right.equalTo(self).offset(rightOffset)
            $0.height.centerY.equalTo(self)
        }
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
}

extension EventBasicCellLikeView {

    enum Style {
        static let iconSize = CGSize(width: 16, height: 16)
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
        // 指定 view 进行 top 对齐
        case topEqualTo(refView: UIView)
        // 指定 top 偏移值
        case topByOffset(CGFloat)
    }

    typealias AccessoryAlignment = IconAlignment

    enum AccessoryType {
        case next
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
            label.numberOfLines = 0
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
            case .next: image = UDIcon.getIconByKey(.rightOutlined, size: EventBasicCellLikeView.Style.iconSize).renderColor(with: .n3)
            case .close: image = UDIcon.getIconByKey(.closeOutlined, size: EventBasicCellLikeView.Style.iconSize).renderColor(with: .n3)
            case .fold: image = UDIcon.getIconByKey(.downOutlined, size: EventBasicCellLikeView.Style.iconSize).renderColor(with: .n3)
            case .unfold: image = UDIcon.getIconByKey(.upOutlined, size: EventBasicCellLikeView.Style.iconSize).renderColor(with: .n3)
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

    final class BackgroundView: UIView {

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
