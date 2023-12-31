//
//  PropsView.swift
//  Blockit
//
//  Created by 夏汝震 on 2020/10/10.
//

import LarkUIKit
import EENavigator
import RichLabel
import UniverseDesignColor
import UniverseDesignTheme
import LarkContainer

// MARK: - delegate

public protocol PropsViewDelegate: AnyObject {
    func propsView(_ propsView: PropsView, didSelectLink: URL)
    func propsView(_ propsView: PropsView, contentSize: CGSize)
}

public extension PropsViewDelegate {
    func propsView(_ propsView: PropsView, didSelectLink: URL) {}
    func propsView(_ propsView: PropsView, contentSize: CGSize) {}
}

public protocol PropsViewDataSource: AnyObject {
    func propsView(_ propsView: PropsView, dataSource: ItemTags)
}

public extension PropsViewDataSource {
    func propsView(_ propsView: PropsView, dataSource: ItemTags) {}
}

// MARK: - layout config

public struct PropsViewConfig {

    public var contentInsets: UIEdgeInsets
    public var font: UIFont
    public var textColor: UIColor
    public var lineSpacing: CGFloat
    public var alignment: NSTextAlignment
    public var numberOfLines: Int
    public var isUserInteractionEnabled: Bool
    public var context: String?
    public var actionPanelEnabled: Bool

    public init(contentInsets: UIEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16),
                font: UIFont = UIFont.systemFont(ofSize: 14, weight: .regular),
                textColor: UIColor = UIColor.ud.colorfulBlue,
                lineSpacing: CGFloat = 10,
                alignment: NSTextAlignment = .left,
                numberOfLines: Int = 0,
                isUserInteractionEnabled: Bool = true,
                context: String? = nil,
                actionPanelEnabled: Bool = true) {
        self.contentInsets = contentInsets
        self.font = font
        self.textColor = textColor
        self.lineSpacing = lineSpacing
        self.alignment = alignment
        self.numberOfLines = numberOfLines
        self.isUserInteractionEnabled = isUserInteractionEnabled
        self.context = context
        self.actionPanelEnabled = actionPanelEnabled
    }
}

public final class PropsView: UIView {

    public var contentSize: CGSize {
        _contentSize
    }

    public override var intrinsicContentSize: CGSize {
        return _contentSize
    }

    public var preferredMaxLayoutWidth: CGFloat = 0 {
        didSet {
            self.bounds.size.width = preferredMaxLayoutWidth
            label.preferredMaxLayoutWidth = bounds.size.width - config.contentInsets.left - config.contentInsets.right
            label.invalidateIntrinsicContentSize()
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
    }

    public weak var delegate: PropsViewDelegate?
    public weak var dataSource: PropsViewDataSource?

    // datasource
    private var itemTags: ItemTags
    private var blockInfo: BlockInfo
    private var blockit: BlockitService

    // view
    private var config: PropsViewConfig
    private var label = LKLabel()
    private var button = UIButton()
    private var _contentSize = CGSize(width: 0, height: 0)

    public init(blockInfo: BlockInfo,
                tags: ItemTags,
                config: PropsViewConfig?,
                blockit: BlockitService) {
        self.blockInfo = blockInfo
        self.itemTags = tags
        self.config = config ?? PropsViewConfig()
        self.blockit = blockit
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        button.frame = bounds
        layout()
    }

    private func setup() {
        let backColor = UIColor.ud.N00
        backgroundColor = backColor
        layer.masksToBounds = true
        isUserInteractionEnabled = config.isUserInteractionEnabled

        if config.isUserInteractionEnabled && config.actionPanelEnabled {
            setupDoAction()
        }

        addSubview(label)
        label.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(config.contentInsets)
        }
        label.isUserInteractionEnabled = config.isUserInteractionEnabled
        label.backgroundColor = .clear
        label.font = config.font
        label.textColor = config.textColor
        label.lineSpacing = config.lineSpacing
        label.textAlignment = config.alignment
        /// 开放平台：非 Office 场景，暂时逃逸
        // swiftlint:disable ban_linebreak_byChar
        label.lineBreakMode = .byCharWrapping
        // swiftlint:enable ban_linebreak_byChar
        label.numberOfLines = config.numberOfLines
        let attributes = [NSAttributedString.Key.foregroundColor: config.textColor]
        label.linkAttributes = [NSAttributedString.Key.foregroundColor: config.textColor]
        label.activeLinkAttributes = [:]
        label.autoDetectLinks = false
        label.delegate = self
        label.outOfRangeText = NSAttributedString(string: "...", attributes: attributes)
        updateTags(itemTags)
    }
}

// MARK: - updateTags & layout
extension PropsView {

    func updateData(_ tags: ItemTags) {
        itemTags = tags
        updateTags(tags)
        layout()
        dataSource?.propsView(self, dataSource: tags)
    }

    private func updateTags(_ itemTags: ItemTags) {
        let texts = itemTags.tags.map { "#\($0.tagInfo.name)" }
        let placedChar = "    "
        let text = texts.joined(separator: placedChar)
        let placedCharLength = placedChar.utf16.count
        var location = 0
        let attributes = [NSAttributedString.Key.foregroundColor: config.textColor]
        for (index, tag) in itemTags.tags.enumerated() {
            let tagLength = texts[index].utf16.count
            if let url = NSURL(string: tag.appLink) {
                var textLink = RichLabel.LKTextLink(range: NSRange(location: location, length: tagLength), type: .link, attributes: attributes)
                textLink.url = url as URL
                label.addLKTextLink(link: textLink)
            }
            location += (tagLength + placedCharLength)
        }
        label.text = text
    }

    private func layout() {
        let labelWidth = bounds.size.width - config.contentInsets.left - config.contentInsets.right
        label.preferredMaxLayoutWidth = labelWidth
        label.invalidateIntrinsicContentSize()
        let labelHeight = label.sizeThatFits(CGSize(width: labelWidth, height: CGFloat(MAXFLOAT))).height
        let size = CGSize(width: bounds.size.width, height: labelHeight + config.contentInsets.top + config.contentInsets.bottom)
        if _contentSize != size {
            _contentSize = size
            self.invalidateIntrinsicContentSize()// 告知外部 contentSize 失效
            delegate?.propsView(self, contentSize: size)
        }
    }
}

// MARK: - Actions
extension PropsView: LKLabelDelegate {

    fileprivate func setupDoAction() {
        addSubview(button)
        self.button.addTarget(self, action: #selector(doAction), for: .touchUpInside)
    }

    @objc fileprivate func doAction() {
        if let parentVC = self.parentVC {
            blockit.doAction(blockInfo: blockInfo, context: config.context, extra: nil, from: parentVC)
        }
    }

    public func attributedLabel(_ label: LKLabel, didSelectLink url: URL) {
        if let parentVC = self.parentVC {
            // Pano 业务依赖的，后续可以下线了
            Container.shared.getCurrentUserResolver().navigator.open(url, from: parentVC)
        }
        delegate?.propsView(self, didSelectLink: url)
        if let tag = self.itemTags.tags.first(where: { $0.appLink == url.absoluteString }) {
            BlockitTracker.trackJumpPano(tagId: tag.instanceId)
        }
    }
}

extension UIView {
    /// 获取View所在的ViewController
    var parentVC: UIViewController? {
        let maxDepth = 20 // 频控
        var currentDepth = 0
        var parentResponder: UIResponder? = self
        while parentResponder != nil, currentDepth < maxDepth {
            parentResponder = parentResponder?.next
            currentDepth += 1
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}
