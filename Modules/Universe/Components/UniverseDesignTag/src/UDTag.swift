
import Foundation
import UIKit
import SnapKit
import UniverseDesignIcon
import UniverseDesignFont

/// 显示Tag的View
open class UDTag: UIView {

    // MARK: Public API

    /// 文本
    public var text: String? {
        get { return textLabel.text }
        set {
            guard configuration.icon != nil || newValue != nil else {
                assertionFailure("[icon] and [text] can not be both 'nil'")
                return
            }
            if configuration.text != newValue {
                var newConfig = configuration
                newConfig.text = newValue
                updateConfiguration(newConfig)
            }
        }
    }

    /// 图标
    public var icon: UIImage? {
        get { return iconView.image }
        set {
            guard configuration.text != nil || newValue != nil else {
                assertionFailure("[icon] and [text] can not be both 'nil'")
                return
            }
            if configuration.icon != newValue {
                var newConfig = configuration
                newConfig.icon = newValue
                updateConfiguration(newConfig)
            }
        }
    }

    public var colorScheme: Configuration.ColorScheme = .normal {
        didSet {
            if oldValue != colorScheme {
                updateColor()
            }
        }
    }
    
    /// 是否使用半透明背景色
    public var isBgOpaque: Bool = false {
        didSet {
            if oldValue != isBgOpaque {
                updateColor()
            }
        }
    }

    public var sizeClass: Configuration.Size = .medium {
        didSet {
            if oldValue != sizeClass {
                updateSizeClass()
            }
        }
    }

    public func updateConfiguration(_ newConfiguration: Configuration) {
        if newConfiguration != self.configuration {
            var hasLayoutChange = false
            if newConfiguration.tagType != configuration.tagType {
                hasLayoutChange = true
            } else if newConfiguration.horizontalMargin != configuration.horizontalMargin {
                hasLayoutChange = true
            } else if newConfiguration.iconSize != configuration.iconSize {
                hasLayoutChange = true
            } else if newConfiguration.iconTextSpacing != configuration.iconTextSpacing {
                hasLayoutChange = true
            } else if newConfiguration.height != configuration.height {
                hasLayoutChange = true
            }
            self.configuration = newConfiguration
            updateUIWithConfiguration(refreshLayout: hasLayoutChange)
        }
    }
    
    // MARK: Private Definitions
    
    /// 配置
    public internal(set) var configuration: Configuration

    /// iOS14 的 UIStackView 在搜索栏列表中，subview 会有上下漂移的情况，所以改用 AutoLayout 实现
    private lazy var useCustomLayoutInsteadOfStackView: Bool = {
        // 只在 iOS14 上启用
        // iOS 15 也发现类似问题，暂时全部启用 AutoLayout 实现
        if #available(iOS 15.0, *) {
            return true
        }
        if #available(iOS 14.0, *) {
            return true
        }
        return true
    }()

    private var tagType: Configuration.TagType {
        configuration.tagType
    }

    // MARK: UI Elements

    /// 使用 AutoLayout 布局时，作为最外层容器
    private lazy var wrapperView = UIView()

    /// 使用 UIStackView 布局时，作为最外层容器
    private lazy var wrapperStack: UIStackView = {
        let wrapperStack = UIStackView()
        wrapperStack.axis = .horizontal
        wrapperStack.alignment = .center
        wrapperStack.distribution = .fill
        wrapperStack.spacing = 5
        wrapperStack.isLayoutMarginsRelativeArrangement = true
        return wrapperStack
    }()

    ///UILabel，支持padding
    private lazy var textLabel: UILabel = {
        let label = UILabel()
        label.layer.masksToBounds = true
        label.setContentHuggingPriority(UILayoutPriority(751), for: .horizontal)
        label.setContentCompressionResistancePriority(UILayoutPriority(751), for: .horizontal)
        isTextLabelInitialized = true
        return label
    }()
    
    /// 标记 textLabel 是否已被初始化，用于懒加载优化
    private lazy var isTextLabelInitialized: Bool = false

    ///存放icon的imageView，尺寸默认为12*12
    private lazy var iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        isIconViewInitialized = true
        return imageView
    }()
    
    /// 标记 textLabel 是否已被初始化，用于懒加载优化
    private lazy var isIconViewInitialized: Bool = false

    // MARK: Initializers
    
    public override init(frame: CGRect) {
        self.configuration = .text("")
        super.init(frame: frame)
        setup()
    }

    public init(configuration: Configuration) {
        self.configuration = configuration
        super.init(frame: .zero)
        setup()
    }

    public convenience init(withText text: String) {
        self.init(configuration: .text(text))
    }

    public convenience init(withIcon icon: UIImage) {
        self.init(configuration: .icon(icon))
    }

    public convenience init(withIcon icon: UIImage, text: String) {
        self.init(configuration: .iconText(icon, text: text))
    }
    
    required public init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        if useCustomLayoutInsteadOfStackView {
            // 使用 AutoLayout 布局
            addSubview(wrapperView)
            wrapperView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
                make.height.equalTo(configuration.height)
            }
        } else {
            // 使用 UIStackView 布局
            addSubview(wrapperStack)
            wrapperStack.snp.makeConstraints { make in
                make.edges.equalToSuperview()
                make.height.equalTo(configuration.height)
            }
        }
        updateUIWithConfiguration(refreshLayout: true)
    }

    // MARK: Internal functions

    ///私有方法，更新UI属性
    private func updateUIWithConfiguration(refreshLayout hasLayoutChange: Bool) {
        updateCommonAppearance()
        switch tagType {
        case .icon:
            updateIconViewAppearance()
        case .text:
            updateTextLabelAppearance()
        case .iconText:
            updateIconViewAppearance()
            updateTextLabelAppearance()
        }
        guard hasLayoutChange else { return }
        if useCustomLayoutInsteadOfStackView {
            wrapperView.snp.updateConstraints { make in
                make.height.equalTo(configuration.height)
            }
            wrapperView.subviews.forEach { $0.removeFromSuperview() }
            switch tagType {
            case .icon:
                wrapperView.addSubview(iconView)
                iconView.snp.remakeConstraints { make in
                    make.centerY.equalToSuperview()
                    make.leading.equalToSuperview().offset(configuration.horizontalMargin)
                    make.trailing.equalToSuperview().offset(-configuration.horizontalMargin)
                    make.size.equalTo(configuration.iconSize)
                }
            case .text:
                wrapperView.addSubview(textLabel)
                textLabel.snp.remakeConstraints { make in
                    make.centerY.equalToSuperview()
                    make.leading.equalToSuperview().offset(configuration.horizontalMargin)
                    make.trailing.equalToSuperview().offset(-configuration.horizontalMargin)
                }
            case .iconText:
                wrapperView.addSubview(iconView)
                wrapperView.addSubview(textLabel)
                iconView.snp.remakeConstraints { make in
                    make.centerY.equalToSuperview()
                    make.size.equalTo(configuration.iconSize)
                    make.leading.equalToSuperview().offset(configuration.horizontalMargin)
                }
                textLabel.snp.remakeConstraints { make in
                    make.centerY.equalToSuperview()
                    make.leading.equalTo(iconView.snp.trailing).offset(configuration.iconTextSpacing)
                    make.trailing.equalToSuperview().offset(-configuration.horizontalMargin)
                }
            }
        } else {
            wrapperStack.snp.updateConstraints { make in
                make.height.equalTo(configuration.height)
            }
            wrapperStack.subviews.forEach { $0.removeFromSuperview() }
            wrapperStack.layoutMargins = UIEdgeInsets(top: 0, left: configuration.horizontalMargin, bottom: 0, right: configuration.horizontalMargin)
            switch tagType {
            case .icon:
                wrapperStack.addArrangedSubview(iconView)
                iconView.snp.remakeConstraints { make in
                    make.size.equalTo(configuration.iconSize)
                }
            case .text:
                wrapperStack.addArrangedSubview(textLabel)
            case .iconText:
                wrapperStack.addArrangedSubview(iconView)
                wrapperStack.addArrangedSubview(textLabel)
                iconView.snp.remakeConstraints { make in
                    make.size.equalTo(configuration.iconSize)
                }
                wrapperStack.spacing = configuration.iconTextSpacing
            }
        }
    }
    
    private func updateTextLabelAppearance() {
        textLabel.text = configuration.text
        textLabel.font = configuration.font
        textLabel.textColor = configuration.textColor
        textLabel.textAlignment = configuration.textAlignment
    }
    
    private func updateIconViewAppearance() {
        iconView.image = configuration.icon
        if let iconColor = configuration.iconColor {
            iconView.ud.withTintColor(iconColor)
        }
    }
    
    private func updateCommonAppearance() {
        self.backgroundColor = configuration.backgroundColor
        self.layer.cornerRadius = configuration.cornerRadius
    }

    private func updateColor() {
        var newConfig = configuration
        if isBgOpaque {
            newConfig.backgroundColor =  colorScheme.opaqueBgColor
            self.backgroundColor = colorScheme.opaqueBgColor
        } else {
            newConfig.backgroundColor = colorScheme.transparentBgColor
        }
        newConfig.textColor = colorScheme.textColor
        newConfig.iconColor = colorScheme.iconColor
        updateConfiguration(newConfig)
    }

    private func updateSizeClass() {
        var newConfig = configuration
        newConfig.iconTextSpacing = sizeClass.iconTextSpacing
        newConfig.iconSize = sizeClass.iconSize
        newConfig.font = sizeClass.font
        newConfig.height = sizeClass.height
        if tagType == .icon {
            newConfig.horizontalMargin = sizeClass.horizontalMarginIconOnly
        } else {
            newConfig.horizontalMargin = sizeClass.horizontalMarginNormal
        }
        updateConfiguration(newConfig)
    }

    public override var intrinsicContentSize: CGSize {
        return UDTag.sizeToFit(configuration: configuration)
    }
    
    /// 根据 configuration 计算 tag 大小
    public static func sizeToFit(configuration: UDTag.Configuration, containerSize: CGSize? = nil) -> CGSize {
        let containerSize = containerSize ?? CGSize(width: CGFloat.greatestFiniteMagnitude, height: configuration.height)
        let height = configuration.height
        let iconWidth = configuration.iconSize.width
        let textWidth = configuration.text?.boundingRect(
            with: containerSize,
            options: .usesLineFragmentOrigin,
            attributes: [NSAttributedString.Key.font: configuration.font],
            context: nil).width ?? 0
        var width: CGFloat = configuration.horizontalMargin * 2
        switch configuration.tagType {
        case .icon:     width += iconWidth
        case .text:     width += textWidth
        case .iconText: width += iconWidth + configuration.iconTextSpacing + textWidth
        }
        width = ceil(max(height, width))
        return CGSize(width: width, height: height)
    }

    // MARK: - Deprecations
    
    ///配置
    @available(*, deprecated, message:"use 'configuration' instead")
    public private(set) var config: UDTagConfig = .icon(.init())
    
    /// 初始化方法，接受text和config，并更新UI属性
    @available(*, deprecated, message:"Use init(withText:) instead.")
    public convenience init(text: String, textConfig: UDTagConfig.TextConfig) {
        let oldConfig = UDTagConfig.text(textConfig)
        self.init(configuration: oldConfig.toNewConfiguration(text: text))
        self.config = oldConfig
    }

    /// 初始化方法，接受image和config，并更新UI属性
    @available(*, deprecated, message:"Use init(withIcon:) instead.")
    public convenience init(icon: UIImage, iconConfig: UDTagConfig.IconConfig) {
        let oldConfig = UDTagConfig.icon(iconConfig)
        self.init(configuration: oldConfig.toNewConfiguration(icon: icon))
        self.config = oldConfig
    }

    /// 更新文本tag的UI，若当前为图片，则更新为文本tag
    @available(*, deprecated, message:"Use updateConfiguration(withConfig:) instead.")
    public func updateUI(textConfig: UDTagConfig.TextConfig) {
        let oldConfig = UDTagConfig.text(textConfig)
        self.config = oldConfig
        updateConfiguration(oldConfig.toNewConfiguration(text: text))
    }

    /// 更新image tag的UI，若当前为文本，则更新为图片
    @available(*, deprecated, message:"Use updateConfiguration(withConfig:) instead.")
    public func updateUI(iconConfig: UDTagConfig.IconConfig) {
        let oldConfig = UDTagConfig.icon(iconConfig)
        self.config = oldConfig
        updateConfiguration(oldConfig.toNewConfiguration(icon: icon))
    }
    
    @available(*, deprecated, message:"Use sizeToFit(configuration:containerSize:) instead.")
    public static func sizeToFit(config: UDTagConfig, title: String?, containerSize: CGSize) -> CGSize {
        let configuration = config.toNewConfiguration(text: title)
        return sizeToFit(configuration: configuration, containerSize: containerSize)
    }
}

