//
//  BasicCellLikeView.swift
//  Calendar
//
//  Created by 张威 on 2020/2/5.
//

import UIKit
import RxSwift
import RxCocoa
import UniverseDesignIcon
import UniverseDesignFont

/// 类似于 UITableViewCell Basic 风格的 View，基本结构如下：
///
///     +--------------------------------------------------------------+
///     |          |                                   |               |
///     |-- Icon --|------------- Content -------------|-- Accessory --|
///     |          |                                   |               |
///     +--------------------------------------------------------------+
///

class BasicCellLikeView: UIView {

    typealias Handler = () -> Void
    typealias BackgroundColors = (normal: UIColor, highlight: UIColor)

    var preferMaxLayoutWidth: CGFloat {
        // 减去right space
        return contentContainerView.frame.width - Style.rightInset
    }

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
        }
    }

    /// 指定 icon 对齐方式
    public var iconAlignment: IconAlignment = .centerVertically {
        didSet {
            iconView.snp.remakeConstraints {
                $0.left.equalToSuperview().inset(Style.leftInset)
                $0.size.equalTo(Style.iconSize)
                switch iconAlignment {
                case .centerVertically:
                    $0.centerY.equalToSuperview()
                case .centerYEqualTo(let refView):
                    $0.centerY.equalTo(refView)
                case .topEqualTo(let refView):
                    $0.top.equalTo(refView)
                case .topByOffset(let offset):
                    $0.top.equalTo(offset)
                case .bottomByOffset(let offset):
                    $0.bottom.equalTo(-offset)
                }
            }
        }
    }

    public var content: Content = .none {
        didSet {
            contentContainerView.subviews.forEach { $0.removeFromSuperview() }
            if let view = content.view(in: self) {
                contentContainerView.addSubview(view)
                view.snp.remakeConstraints {
                    $0.edges.equalToSuperview()
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
            $0.left.equalToSuperview().offset(leftOffset)

            var rightOffset: CGFloat = 0
            if !accessoryClickableExpandView.isHidden {
                rightOffset -= (Style.accessorySize.width + Style.spacingBeforeAccessory) + Style.rightInset
            }
            $0.right.equalToSuperview().offset(rightOffset)
        }
    }

    public var accessory: Accessory = .none {
        didSet {
            accessoryView.image = accessory.image
            if case .none = accessory {
                accessoryClickableExpandView.isHidden = true
            } else {
                accessoryClickableExpandView.isHidden = false
            }

            adjustContentLayout()
            setNeedsLayout()
        }
    }

    /// 指定 accessory 对齐方式
    public var accessoryAlignment: IconAlignment = .centerVertically {
        didSet {
            accessoryView.snp.remakeConstraints {
                $0.right.equalToSuperview().inset(Style.rightInset)
                switch accessoryAlignment {
                case .centerVertically:
                    $0.centerY.equalToSuperview()
                case .centerYEqualTo(let refView):
                    $0.centerY.equalTo(refView)
                case .topEqualTo(let refView):
                    $0.top.equalTo(refView)
                case .topByOffset(let offset):
                    $0.top.equalTo(offset)
                case .bottomByOffset(let offset):
                    $0.bottom.equalTo(-offset)
                }
            }
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

    public var backgroundColors: BackgroundColors = (UIColor.ud.bgBody, UIColor.ud.fillPressed) {
        didSet {
            backgroundView.backgroundColors = backgroundColors
        }
    }

    private var backgroundView: BackgroundView!
    private var iconView: UIImageView = .init(image: nil)
    private var contentContainerView: UIView = .init()
    private var accessoryView: UIImageView = .init(image: nil)
    // 扩大 accesoryView 的可点击范围
    private var accessoryClickableExpandView: UIView = .init()
    private let disposeBag = DisposeBag()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundView = BackgroundView()
        backgroundView.isUserInteractionEnabled = false
        backgroundView.backgroundColors = backgroundColors
        addSubview(backgroundView)
        backgroundView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didViewClick))
        backgroundView.addGestureRecognizer(tapGesture)

        iconView = UIImageView()
        iconView.isHidden = true
        iconView.isUserInteractionEnabled = false
        addSubview(iconView)
        iconView.snp.makeConstraints {
            $0.size.equalTo(Style.iconSize)
            $0.centerY.equalToSuperview()
            $0.left.equalToSuperview().inset(Style.leftInset)
        }

        accessoryClickableExpandView = UIView()
        accessoryClickableExpandView.isHidden = true
        accessoryClickableExpandView.isUserInteractionEnabled = false
        let accessoryTapGesture = UITapGestureRecognizer(target: self, action: #selector(didAccessoryClick))
        accessoryClickableExpandView.addGestureRecognizer(accessoryTapGesture)
        addSubview(accessoryClickableExpandView)
        accessoryClickableExpandView.snp.makeConstraints {
            $0.width.equalTo(44)
            $0.centerY.right.height.equalToSuperview()
        }

        accessoryView = UIImageView()
        accessoryView.contentMode = .right
        accessoryView.isUserInteractionEnabled = false
        accessoryClickableExpandView.addSubview(accessoryView)
        accessoryView.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.right.equalToSuperview().inset(Style.rightInset)
        }

        contentContainerView = UIView()
        addSubview(contentContainerView)
        contentContainerView.snp.makeConstraints {
            let leftOffset = Style.leftInset
            $0.left.equalToSuperview().offset(leftOffset)
            let rightOffset = 0 - Style.rightInset
            $0.right.equalToSuperview().offset(rightOffset)
            $0.height.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        // contentContainerView 不受理 event
        if view == contentContainerView {
            return onClick != nil ? backgroundView : nil
        }
        return view
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

extension BasicCellLikeView {

    enum Style {
        static let iconSize = CGSize(width: 16, height: 16)
        static let accessorySize = CGSize(width: 16, height: 16)
        static let leftInset: CGFloat = 16
        static let rightInset: CGFloat = 16
        static let spacingAfterIcon: CGFloat = 12
        static let spacingBeforeAccessory: CGFloat = 4
    }

    enum Icon {
        // 没有 Icon
        case none
        // 空 Icon，起占位效果
        case empty
        // 自定义 image
        case customImage(UIImage)
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
        // 指定 bottom 偏移值
        case bottomByOffset(CGFloat)
    }

    enum AccessoryType {
        case next
        case close
        case disableClose
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
            color: UIColor = UIColor.ud.textTitle,
            font: UIFont = UDFont.systemFont(ofSize: 16)// UIFont.cd.regularFont(ofSize: 16)
        ) {
            self.text = text
            self.color = color
            self.font = font
        }
    }

    enum Content {
        case none
        case title(ContentTitle)
        case customView(UIView)
    }
}

extension BasicCellLikeView.Icon {

    fileprivate var image: UIImage? {
        switch self {
        case .none, .empty: return nil
        case .customImage(let image): return image
        }
    }

}

extension BasicCellLikeView.Content {

    fileprivate func view(in superView: BasicCellLikeView) -> UIView? {
        switch self {
        case .none: return nil
        case .customView(let view): return view
        case .title(let title):
            let label = UILabel()
            label.text = title.text
            label.font = title.font
            label.textColor = title.color
            return label
        }
    }

}

extension BasicCellLikeView.Accessory {

    fileprivate var image: UIImage? {
        switch self {
        case .none:
            return nil
        case .type(let type):
            let image: UIImage
            switch type {
            case .next: image = UDIcon.rightOutlined.ud.resized(to: CGSize(width: 20, height: 20))
            case .close: image = UDIcon.closeOutlined.ud.resized(to: CGSize(width: 20, height: 20))
            case .disableClose: image = UDIcon.getIconByKey(
                .closeOutlined,
                renderingMode: .automatic,
                iconColor: UIColor.ud.iconDisabled,
                size: CGSize(width: 20, height: 20)
            )
            case .checkmark: image = UDIcon.doneOutlined.ud.resized(to: CGSize(width: 20, height: 20))
            }
            return image.withRenderingMode(.alwaysOriginal)
        case .customImage(let image):
            return image
        }
        return nil
    }

}

extension BasicCellLikeView {

    class BackgroundView: UIView {

        private var isHighlighted = false {
            didSet {
                backgroundColor = isHighlighted ? backgroundColors.highlight : backgroundColors.normal
            }
        }

        var backgroundColors: BackgroundColors = (UIColor.ud.bgBody, UIColor.ud.fillPressed) {
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
