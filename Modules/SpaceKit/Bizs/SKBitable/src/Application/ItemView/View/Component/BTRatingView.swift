//
//  BTRatingView.swift
//  SKBitable
//
//  Created by yinyuan on 2023/2/17.
//

import UIKit
import SnapKit
import SKFoundation
import UniverseDesignIcon
import UniverseDesignColor

public protocol BTRatingViewDelegate: AnyObject {
    func ratingValueChanged(rateView: BTRatingView, value: Int?)
}

public final class BTRatingView: UIView {
    
    public struct Icon {
        let background: IconLayer
        let foreground: IconLayer?
        
        init(background: IconLayer, foreground: IconLayer? = nil) {
            self.background = background
            self.foreground = foreground
        }
        
        init(_ icon: UIImage) {
            self.background = IconLayer(selectImage: icon, unselectImage:icon.withRenderingMode(.alwaysTemplate), unselectTint: UDColor.N300)
            self.foreground = nil
        }
    }
    
    public struct IconLayer {
        let selectImage: UIImage
        let unselectImage: UIImage
        let selectTint: UIColor?
        let unselectTint: UIColor?
        
        init(selectImage: UIImage, unselectImage: UIImage, selectTint: UIColor? = nil, unselectTint: UIColor? = nil) {
            self.selectImage = selectImage
            self.unselectImage = unselectImage
            self.selectTint = selectTint
            self.unselectTint = unselectTint
        }
    }
    
    public struct Config {
        public enum Style {
            case adjust // icon 动态大小
            case stable // 固定大小
        }
        
        public enum Alignment {
            case left
            case right
            case center
        }
        public let minValue: Int
        public let maxValue: Int
        public let iconWidth: CGFloat
        public let iconTitleSpacing: CGFloat
        public let iconSpacing: CGFloat
        public let iconPadding: CGFloat
        public let maxWidth: CGFloat?   // 设置最大宽度，如果显示不下会自动缩小
        public let titleFontSize: CGFloat
        public let alignment: Alignment
        public let syncLock: Bool       // 是否设置同步锁，即在每一次点击操作后，都会进入锁状态，期间再点击设置无效，必须等待下一次 update 调用后才解锁，方能继续点击。主要解决快速连续点击情况下，协同刷新延迟导致的状态错乱问题。
        public let iconBuilder: ((_ value: Int) -> BTRatingView.Icon?)?
        public let titleBuilder: ((_ value: Int) -> String?)?
        public let style: Style
        
        init(minValue: Int = 1,
             maxValue: Int = 5,
             iconWidth: CGFloat = 43,
             iconTitleSpacing: CGFloat = 18,
             iconSpacing: CGFloat = 16,
             iconPadding: CGFloat = 0,
             alignment: Alignment = .center,
             style: Style = .adjust,
             maxWidth: CGFloat? = nil,
             titleFontSize: CGFloat = 14,
             syncLock: Bool = false,
             iconBuilder: ( (_: Int) -> BTRatingView.Icon?)? = nil,
             titleBuilder: ( (_: Int) -> String?)? = nil) {
            self.minValue = minValue
            self.maxValue = maxValue
            self.iconWidth = iconWidth
            self.iconTitleSpacing = iconTitleSpacing
            self.iconSpacing = iconSpacing
            self.iconPadding = iconPadding
            self.maxWidth = maxWidth
            self.titleFontSize = titleFontSize
            self.syncLock = syncLock
            self.iconBuilder = iconBuilder
            self.titleBuilder = titleBuilder
            self.alignment = alignment
            self.style = style
        }
    }
    
    public weak var delegate: BTRatingViewDelegate?
    
    public private(set) var ratingConfig: Config = Config()
    
    public private(set) var value: Int?
    
    public func update(_ config: BTRatingView.Config, _ value: Int?) {
        if self.ratingConfig.alignment != config.alignment, config.style == .stable {
            updateAlignment(alignment: config.alignment)
        }
        self.ratingConfig = config
        self.value = value
        reloadData()
        syncLocked = false
    }
    
    private var iconSpacingOfsset: CGFloat = 0  // 由于宽度不够，对 iconSpacing 进行调整的量
    private var syncLocked: Bool = false
    
    private lazy var stackView: UIStackView = {
       let view = UIStackView()
        view.axis = .horizontal
        view.alignment = .center
        view.distribution = .fillEqually
        return view
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.height.lessThanOrEqualToSuperview()
            make.width.lessThanOrEqualToSuperview()
            make.center.equalToSuperview()
        }
    }
    
    private func updateAlignment(alignment: Config.Alignment) {
        guard UserScopeNoChangeFG.XM.nativeCardViewEnable else { return }
        stackView.snp.makeConstraints { make in
            make.height.lessThanOrEqualToSuperview()
            make.width.lessThanOrEqualToSuperview()
            switch alignment {
            case .left:
                make.left.equalToSuperview()
            case .right:
                make.right.equalToSuperview()
            case .center:
                make.center.equalToSuperview()
            }
        }
    }
    
    /// 星星数量
    private var count: Int {
        ratingConfig.maxValue - ratingConfig.minValue + 1
    }
        
    private func reloadData() {
        var scale: CGFloat = 1.0
        let requiredWidth: CGFloat
        if UserScopeNoChangeFG.XM.nativeCardViewEnable, ratingConfig.style == .stable {
            let count = CGFloat(count)
            requiredWidth = ratingConfig.iconSpacing * (count - 1) + ratingConfig.iconWidth * count
        } else {
            requiredWidth = ratingConfig.iconSpacing * 10 + ratingConfig.iconWidth * 11
        }
        if let maxWidth = ratingConfig.maxWidth, maxWidth > 0, requiredWidth > maxWidth {
            scale = maxWidth / requiredWidth
        }
        let targetSpacing = ratingConfig.iconSpacing * scale
        if targetSpacing != stackView.spacing {
            stackView.spacing = targetSpacing
        }
        
        let count = self.count
        if stackView.arrangedSubviews.count < count {
            for _ in stackView.arrangedSubviews.count..<count {
                let rateCell = RatingCell()
                stackView.addArrangedSubview(rateCell)
                rateCell.setContentCompressionResistancePriority(.required, for: .horizontal)
            }
        }
        stackView.arrangedSubviews.enumerated().forEach { (index, view) in
            guard let rateCell = view as? RatingCell else {
                return
            }
            guard index < count else {
                rateCell.isHidden = true
                return
            }
            let value = index + ratingConfig.minValue
            let icon = ratingConfig.iconBuilder?(value)
            rateCell.update(
                value: value,
                showTitle: ratingConfig.titleBuilder != nil,
                icon: icon ?? BTRatingView.Icon(UDIcon.ratingStarColorful),
                titleText: ratingConfig.titleBuilder?(value),
                selected: self.value != nil ? value <= (self.value ?? 0) : false,
                iconWidth: ratingConfig.iconWidth * scale,
                iconTitleSpacing: ratingConfig.iconTitleSpacing,
                iconPadding: ratingConfig.iconPadding,
                titleFontSize: ratingConfig.titleFontSize
            )
            let halfSpacing = targetSpacing / 2
            rateCell.icon.hitTestEdgeInsets = UIEdgeInsets(top: -halfSpacing, left: -halfSpacing, bottom: -halfSpacing, right: -halfSpacing)    // 扩大点击热区，增加点击灵明度
            rateCell.delegate = self
            rateCell.isHidden = false
        }
    }
}

fileprivate final class Constaints {
    static let titleHeight: CGFloat = 20
    static let minSpacing: CGFloat = 2
}

extension BTRatingView {
    static func ratingConfig(with minValue: Int, maxValue: Int, maxWidth: CGFloat, formEditStyle: Bool, symbol: String) -> BTRatingView.Config {
        let length = max(maxValue - minValue, 0) + 1
        let showTitle = formEditStyle && symbol != "number"
        let iconWidth: CGFloat
        let iconTitleSpacing: CGFloat
        let iconSpacing: CGFloat
        let iconPadding: CGFloat
        let titleFontSize: CGFloat
        if !formEditStyle {
            iconWidth = 20
            iconTitleSpacing = 0
            iconSpacing = 2
            iconPadding = 0.91
            titleFontSize = 14
        } else if length <= 5 {
            iconWidth = 25.45
            iconTitleSpacing = 6
            iconSpacing = 12
            iconPadding = 1.27
            titleFontSize = 10
        } else if length <= 8 {
            iconWidth = 25.45
            iconTitleSpacing = 6
            iconSpacing = 12
            iconPadding = 1.27
            titleFontSize = 10
        } else {
            iconWidth = 23.64
            iconTitleSpacing = 7
            iconSpacing = 3
            iconPadding = 1.18
            titleFontSize = 10
        }
        
        let config = BTRatingView.Config(
            minValue: minValue,
            maxValue: maxValue,
            iconWidth: iconWidth,
            iconTitleSpacing: iconTitleSpacing,
            iconSpacing: iconSpacing,
            iconPadding: iconPadding,
            maxWidth: maxWidth,
            titleFontSize: titleFontSize,
            iconBuilder: { value in
                return BitableCacheProvider.current.ratingIcon(symbol: symbol, value: value)
            },
            titleBuilder: showTitle ? { value in
                return String(value)
            } : nil
        )
        return config
    }
    
    static func ratingSizeForSingleLine(with minValue: Int, maxValue: Int, maxWidth: CGFloat) -> CGSize {
        if maxValue < minValue { return .zero }
        let config = ratingConfig(with: minValue, maxValue: maxValue, maxWidth: maxWidth, formEditStyle: false, symbol: "")
        let count = CGFloat(max(maxValue - minValue, 0) + 1)
        let width: CGFloat = (count * config.iconWidth) + (config.iconSpacing * (count - 1))
        return CGSize(width: width, height: BTFieldLayout.Const.ratingItemHeight)
    }
}

extension BTRatingView: RatingCellDelegate {
    func cellDidClick(value: Int) {
        if ratingConfig.syncLock {
            if syncLocked {
                DocsLogger.warning("syncLocked")
                return
            }
            syncLocked = true
        }
        if value != self.value {
            self.value = value
        } else {
            self.value = nil
        }
        reloadData()
        delegate?.ratingValueChanged(rateView: self, value: self.value)
    }
}

fileprivate protocol RatingCellDelegate: AnyObject {
    func cellDidClick(value: Int)
}

fileprivate final class RatingCell: UIStackView {
    
    private var value: Int?
    fileprivate weak var delegate: RatingCellDelegate?
    
    private lazy var backgroundImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    private lazy var foregroundImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    lazy var icon: UIControl = {
        let view = UIControl()
        
        view.addSubview(backgroundImageView)
        view.addSubview(foregroundImageView)
        
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(0)
        }
        
        foregroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(0)
        }
        
        return view
    }()
    
    private lazy var title: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        view.textAlignment = .center
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        self.axis = .vertical
        self.alignment = .center
                
        addArrangedSubview(icon)
        addArrangedSubview(title)
        
        title.snp.makeConstraints { make in
            make.width.lessThanOrEqualToSuperview()
            make.height.equalTo(Constaints.titleHeight)
        }
        
        icon.addTarget(self, action: #selector(rateCellTaped), for: .touchUpInside)
    }
    
    @objc
    private func rateCellTaped() {
        guard let value = self.value else {
            return
        }
        delegate?.cellDidClick(value: value)
    }
    
    fileprivate func update(
        value: Int,
        showTitle: Bool,
        icon: BTRatingView.Icon,
        titleText: String?,
        selected: Bool,
        iconWidth: CGFloat,
        iconTitleSpacing: CGFloat,
        iconPadding: CGFloat,
        titleFontSize: CGFloat
    ) {
        self.value = value
        
        func applyIconLayer(imageView: UIImageView, iconLayer: BTRatingView.IconLayer) {
            if selected {
                if iconLayer.selectImage != imageView.image {
                    imageView.image = iconLayer.selectImage
                }
                if iconLayer.selectTint != imageView.tintColor {
                    imageView.tintColor = iconLayer.selectTint
                }
            } else {
                if iconLayer.unselectImage != imageView.image {
                    imageView.image = iconLayer.unselectImage
                }
                if iconLayer.unselectTint != imageView.tintColor {
                    imageView.tintColor = iconLayer.unselectTint
                }
            }
        }
        applyIconLayer(imageView: backgroundImageView, iconLayer: icon.background)
        
        if let foreground = icon.foreground {
            foregroundImageView.isHidden = false
            applyIconLayer(imageView: foregroundImageView, iconLayer: foreground)
        } else {
            foregroundImageView.isHidden = true
        }
        
        title.isHidden = !showTitle
        if titleText != title.text {
            title.text = titleText
        }
        if showTitle {
            title.textColor = selected ? UDColor.textTitle : UDColor.textPlaceholder
        }
        if self.icon.frame.width != iconWidth && self.icon.frame.height != iconWidth {
            self.icon.snp.remakeConstraints { make in
                make.width.height.equalTo(iconWidth)
            }
            self.backgroundImageView.snp.remakeConstraints { make in
                make.edges.equalToSuperview().inset(iconPadding)
            }
            self.foregroundImageView.snp.remakeConstraints { make in
                make.edges.equalToSuperview().inset(iconPadding)
            }
        }
        if iconTitleSpacing != self.spacing {
            self.spacing = iconTitleSpacing
        }
        title.font = UIFont.systemFont(ofSize: titleFontSize, weight: .medium)
    }
}
