//
//  BaseHeaderTitleView.swift
//  SKBitable
//
//  Created by yinyuan on 2023/8/28.
//

import UIKit
import UniverseDesignColor
import UniverseDesignIcon
import SKUIKit
import SKCommon
import LarkContainer
import LarkDocsIcon
import SkeletonView
import UniverseDesignTheme
import SKResource
import SKFoundation

class AutoFontLableTag {
    let text: String
    let backgroundColor: UIColor
    let textColor: UIColor
    
    init(text: String, backgroundColor: UIColor, textColor: UIColor) {
        self.text = text
        self.backgroundColor = backgroundColor
        self.textColor = textColor
    }
    
    private var tagImageCache: UIImage?
    private var tagImageCacheForDarkMode: Bool = false
    var tagImage: UIImage? {
        get {
            let isDarkMode = isDarkMode()
            if let tagImageCache = tagImageCache, tagImageCacheForDarkMode == isDarkMode {
                return tagImageCache
            }
            let tagHeight: CGFloat = 18.0
            let tagLable = UILabel()
            let tagPadding: CGFloat = 4.0
            tagLable.text = self.text
            tagLable.textColor = self.textColor
            tagLable.backgroundColor = self.backgroundColor
            tagLable.font = .systemFont(ofSize: 12, weight: .medium)
            tagLable.numberOfLines = 1
            tagLable.layer.cornerRadius = 4
            tagLable.clipsToBounds = true
            tagLable.textAlignment = .center
            tagLable.sizeToFit()
            tagLable.frame = CGRect(x: 0, y: 0, width: tagLable.frame.width + tagPadding * 2, height: tagHeight)
            
            tagImageCache = imageFromView(tagLable)
            tagImageCacheForDarkMode = isDarkMode
            return tagImageCache
        }
    }
    
    private func isDarkMode() -> Bool {
        if #available(iOS 13.0, *), UDThemeManager.getRealUserInterfaceStyle() == .dark {
            return true
        } else {
            return false
        }
    }
    
    private func imageFromView(_ view: UIView) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: view.bounds.size)
        let image = renderer.image { _ in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
        return image
    }
}

class AutoFontLable: UILabel {
    
    var layoutSubviewsCallback: ((_ frame: CGRect) -> Void)?
    var currentAttributesIndexCallback: ((_ index: Int) -> Void)?
    var skeletonHeight: CGFloat = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var lastViewWidth: CGFloat = 0
    override func layoutSubviews() {
        super.layoutSubviews()
        let titleViewWidth = frame.width
        if titleViewWidth > 0, titleViewWidth != lastViewWidth {
            updateStyle()
        }
        lastViewWidth = titleViewWidth
        
        layoutSubviewsCallback?(frame)
    }
    
    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        if self.isSkeletonable {
            _ = layer.sublayers?.map({
                if $0.isKind(of: CAGradientLayer.self) {
                    let percent = self.lastLineFillPercent
                    let height = (self.skeletonHeight <= 0) ? bounds.height : self.skeletonHeight
                    $0.frame = CGRect(origin: .zero, size: CGSize(width: bounds.width * CGFloat(percent) / 100.0, height: height))
                    $0.frame.centerY = bounds.centerY
                    $0.cornerRadius = CGFloat(self.linesCornerRadius)
                    $0.sublayers?.forEach({ subLayer in
                        subLayer.frame = CGRect(origin: .zero, size: CGSize(width: bounds.width * CGFloat(percent) / 100.0, height: height))
                        subLayer.frame.centerY = bounds.centerY
                        subLayer.cornerRadius = CGFloat(self.linesCornerRadius)
                    })
                }
            })
        }
    }
    
    func updateStyle() {
        if !UserScopeNoChangeFG.YY.bitableHeaderFixDisable, self.window?.frame.height ?? 0 < 300 {
            // window height 特别小，说明进入了一种悬浮窗的状态，这种状态下设置 attributedText 会有问题，这里直接 return
            return
        }
        let beginTime = Int(Date().timeIntervalSince1970 * 1000)
        let titleViewWidth = frame.width
        var targetAttributedString: NSAttributedString?
        var targetAttributes: [NSAttributedString.Key: Any] = currentAttributes
        if titleViewWidth > 0, availableAttributes.count > 0 {
            var text = self.originText ?? ""
            var index: Int = -1
            for attributes in availableAttributes {
                index += 1
                let attributedString = attributedStringWithTags(string: text, attributes: attributes)
                let targetSize = attributedString.size()
                if targetAttributedString == nil {
                    targetAttributedString = attributedString
                }
                targetAttributedString = attributedString
                targetAttributes = attributes
                if titleViewWidth >= targetSize.width {
                    break
                }
            }
            
            self.currentAttributes = targetAttributes
            if self.currentAttributesIndex != index {
                self.currentAttributesIndex = index
            }
            if let attributedString = targetAttributedString {
                self.attributedText = attributedString
                while self.sizeThatFits(CGSize(width: titleViewWidth, height: 1000)).height > 55 {
                    // 超出两行了，要缩小
                    text = String(text.dropLast(1))
                    self.attributedText = attributedStringWithTags(string: text + "…", attributes: targetAttributes)
                }
            }
        }
        let endTime = Int(Date().timeIntervalSince1970 * 1000)
        DocsLogger.debug("AutoFontLable.updateStyle cost:\(endTime - beginTime)ms")
    }
    
    func imageFromView(_ view: UIView) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: view.bounds.size)
        let image = renderer.image { _ in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
        return image
    }
    
    var tags: [AutoFontLableTag]? {
        didSet {
            updateStyle()
        }
    }
    
    func attributedStringWithTags(string: String, attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        let mutableAttributedString = NSMutableAttributedString(string: string, attributes: attributes)
        
        // 文本不为空时开始渲染 Tag
        if !string.isEmpty, let tags = tags, !tags.isEmpty {
            for tag in tags {
                if let tagImage = tag.tagImage {
                    let spacing = NSTextAttachment()
                    spacing.image = UIImage()
                    spacing.bounds = CGRect(x: 0, y: 0, width: 4, height: 4)
                    let spacingAttributedString = NSMutableAttributedString(attachment: spacing)
                    mutableAttributedString.append(spacingAttributedString)
                    
                    let yOffset: CGFloat = -3
                    let attach = NSTextAttachment()
                    attach.image = tagImage
                    attach.bounds = CGRect(x: 0, y: yOffset, width: tagImage.size.width, height: tagImage.size.height)
                    let tagAttributedString = NSMutableAttributedString(attachment: attach)
                    
                    mutableAttributedString.append(tagAttributedString)
                }
            }
        }
        
        return mutableAttributedString
    }
    
    var currentAttributes: [NSAttributedString.Key: Any] = [:]
    var currentAttributesIndex: Int = -1 {
        didSet {
            currentAttributesIndexCallback?(currentAttributesIndex)
        }
    }
    var availableAttributes: [[NSAttributedString.Key: Any]] = []
    
    private var originText: String? {
        didSet {
            updateStyle()
        }
    }
    func updateText(text: String?) {
        self.originText = text
    }
}

protocol BaseHeaderTitleViewDelegate: AnyObject {
    func baseHeaderTitleFrameDidChanged()
}

class BaseHeaderTitleView: UIControl {
    
    weak var delegate: BaseHeaderTitleViewDelegate?
    
    private var enableLoading: Bool = false
    
    private class MyStackView: UIStackView {
        override var isUserInteractionEnabled: Bool {
            get {
                super.isUserInteractionEnabled
            }
            set {
                super.isUserInteractionEnabled = false  // 不允许 Skeletonable 随意修改这个值
            }
        }
    }
    
    private lazy var mainStackView: UIStackView = {
        let view = MyStackView(arrangedSubviews: [iconView, titleStackView])
        view.axis = .horizontal
        view.spacing = 12
        view.alignment = .top
        view.distribution = .fill
        view.isUserInteractionEnabled = false  // 必须设置这个，否则自身 addTarget 不响应事件
        view.isSkeletonable = enableLoading
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(40)
        }
        
        
        return view
    }()
    
    private lazy var titleStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [titleView, subtTitleStackView])
        view.axis = .vertical
        view.alignment = .fill
        view.isSkeletonable = enableLoading
        
        titleView.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(24)
        }

        subtTitleStackView.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(22)
        }
        
        return view
    }()
    
    private lazy var subTitleIconView: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.slideOutlined.ud.withTintColor(UDColor.iconN2)
        return view
    }()
    
    private lazy var subtTitleStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [subTitleIconView, subTitleView])
        view.axis = .horizontal
        view.spacing = 4
        view.alignment = .top
        view.distribution = .fill
        view.isSkeletonable = enableLoading
        subTitleIconView.isHidden = true
        subTitleIconView.snp.makeConstraints { make in
            make.width.height.equalTo(16)
        }
        
        return view
    }()
    
    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.isSkeletonable = enableLoading
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        view.backgroundColor = UDColor.bgBody.withAlphaComponent(0.2)
        view.contentMode = .scaleToFill
        return view
    }()
    
    func genAttributed(font: UIFont, lineHeight: CGFloat, textColor: UIColor) -> [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        paragraphStyle.lineBreakMode = .byTruncatingTail
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }
    
    private lazy var titleView: AutoFontLable = {
        let view = AutoFontLable()
        view.numberOfLines = 3
        view.skeletonHeight = 18.0
        let textColor = UDColor.textTitle
        view.availableAttributes = [
            genAttributed(font: UIFont.systemFont(ofSize: 17.0, weight: .medium), lineHeight: 24.0, textColor: textColor),
            genAttributed(font: UIFont.systemFont(ofSize: 16.0, weight: .medium), lineHeight: 24.0, textColor: textColor),
            genAttributed(font: UIFont.systemFont(ofSize: 15.0, weight: .medium), lineHeight: 24.0, textColor: textColor),
            genAttributed(font: UIFont.systemFont(ofSize: 14.0, weight: .medium), lineHeight: 22.0, textColor: textColor),
        ]
        view.currentAttributesIndexCallback = { [weak self] index in
            guard let self = self else {
                return
            }
            self.updateIconOffset()
        }
        view.isSkeletonable = enableLoading
        view.linesCornerRadius = 9
        view.lastLineFillPercent = 100
        view.layoutSubviewsCallback = { [weak self] frame in
            guard let self = self else {
                return
            }
            self.updateIconOffset()
            if frame.height > 30 {
                // 超过 1 行了
                self.titleStackView.spacing = 4
            } else {
                self.titleStackView.spacing = 0
            }
        }
        return view
    }()
    
    private lazy var subTitleView: AutoFontLable = {
        let view = AutoFontLable()
        view.numberOfLines = 2
        let textColor = UDColor.textCaption
        view.availableAttributes = [
            genAttributed(font: UIFont.systemFont(ofSize: 14.0), lineHeight: 22.0, textColor: textColor),
            genAttributed(font: UIFont.systemFont(ofSize: 13.0), lineHeight: 22.0, textColor: textColor),
            genAttributed(font: UIFont.systemFont(ofSize: 12.0), lineHeight: 18.0, textColor: textColor),
        ]
        view.isSkeletonable = enableLoading
        view.lastLineFillPercent = 30
        view.linesCornerRadius = 9
        view.skeletonHeight = 15.0
        view.layoutSubviewsCallback = { [weak self] frame in
            guard let self = self else {
                return
            }
            if frame.height > 30 {
                // 超过 1 行了
                self.subtTitleStackView.alignment = .top
            } else {
                self.subtTitleStackView.alignment = .center
            }
        }
        return view
    }()
    
    init(_ enableLoading: Bool) {
        self.enableLoading = enableLoading
        super.init(frame: .zero)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        addSubview(mainStackView)
        
        remakeConstraints()
        
        addTarget(self, action: #selector(touchDown), for: .touchDown)
        addTarget(self, action: #selector(touchUp), for: [.touchCancel, .touchUpInside, .touchUpOutside])
    }
    
    private func updateIconOffset() {
        // 为了保持图标顶部和文字顶部对齐在一条线上，而文字一般以 BaseLine 作为对齐方式不适合修改，因此这里对不同字号的文字的大小的变化，对图标做一点偏移进行适配
        let index = self.titleView.currentAttributesIndex
        if index == 0 {
            self.iconView.transform = CGAffineTransform(translationX: 0, y: 3)
        } else if index == 1 {
            self.iconView.transform = CGAffineTransform(translationX: 0, y: 3.5)
        } else if index == 2 {
            self.iconView.transform = CGAffineTransform(translationX: 0, y: 4.5)
        } else if index >= 3 {
            let titleViewHeight = self.titleView.frame.height
            if titleViewHeight > 30 {
                // 超过 1 行了
                self.iconView.transform = CGAffineTransform(translationX: 0, y: 0.5)
            } else {
                self.iconView.transform = CGAffineTransform(translationX: 0, y: 5)
            }
        } else {
            self.iconView.transform = CGAffineTransform(translationX: 0, y: 3)
        }
    }
    
    func remakeConstraints(paddingRightEx: CGFloat = 0) {
        guard mainStackView.superview == self else {
            return
        }
        mainStackView.snp.remakeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.right.equalToSuperview().inset(16 + paddingRightEx)
            make.top.equalToSuperview().inset(10)
            make.bottom.equalToSuperview().inset(20)
        }
    }
    
    @objc
    private func touchDown() {
        if frame.width > 0 {
            let scale = (mainStackView.frame.width - 10.0) / mainStackView.frame.width
            UIView.animate(withDuration: 0.1) {
                self.mainStackView.transform = CGAffineTransform(scaleX: scale, y: scale)
            }
        }
    }
    
    @objc
    private func touchUp() {
        UIView.animate(withDuration: 0.1) {
            self.mainStackView.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        delegate?.baseHeaderTitleFrameDidChanged()
    }
    
    func setTitle(title: String?) {
        titleView.updateText(text: title)
    }
    
    var templateTag: AutoFontLableTag? {
        didSet {
            updateTags()
        }
    }
    
    var extenrnalTag: AutoFontLableTag? {
        didSet {
            updateTags()
        }
    }
    
    func updateTags() {
        var tags: [AutoFontLableTag] = []
        if let extenrnalTag = extenrnalTag {
            tags.append(extenrnalTag)
        }
        if let templateTag = templateTag {
            tags.append(templateTag)
        }
        titleView.tags = tags
    }
    
    func setSubTitle(title: String?) {
        subTitleView.updateText(text: title)
    }
    
    func setIcon(icon: BTIcon, callback: (() -> Void)? = nil) {
        icon.apply(to: iconView, callback: callback)
    }
    
    func setSubIcon(icon: BTIcon?) {
        icon?.apply(to: subTitleIconView, tintColor: UDColor.iconN2)
        subTitleIconView.isHidden = icon == nil
    }
}
