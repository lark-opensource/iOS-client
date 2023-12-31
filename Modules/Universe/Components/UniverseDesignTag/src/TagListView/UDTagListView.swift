//
//  UDTagListView.swift
//  UniverseDesignTag
//
//  Created by Hayden on 2023/2/8.
//

import Foundation
import UIKit

@objc
public protocol UDTagListViewDelegate {

    /// Inform the delegate that the tag has been tapped.
    @objc
    optional func tagListView(_ tagListView: UDTagListView, didSelectTag tagView: UDTagListItemView, atIndex index: Int)

    /// Inform the delegate that the tag remove button has been tapped.
    @objc
    optional func tagListView(_ tagListView: UDTagListView, didTapRemoveButtonForTag tagView: UDTagListItemView, atIndex index: Int)
}

@IBDesignable
open class UDTagListView: UIView {

    @IBOutlet
    open weak var delegate: UDTagListViewDelegate?
    public var onTagSelected: ((Int, UDTagListItemView) -> Void)?
    public var onTagRemoving: ((Int, UDTagListItemView) -> Void)?


    // MARK: Tag appearance configuration

    @IBInspectable
    open dynamic var textColor: UIColor = .white {
        didSet { tagViews.forEach { $0.textColor = textColor } }
    }

    @IBInspectable
    open dynamic var selectedTextColor: UIColor = .white {
        didSet { tagViews.forEach { $0.selectedTextColor = selectedTextColor } }
    }

    open dynamic var tagLineBreakMode: NSLineBreakMode = .byTruncatingMiddle {
        didSet { tagViews.forEach { $0.titleLineBreakMode = tagLineBreakMode } }
    }

    @IBInspectable
    open dynamic var tagBackgroundColor: UIColor = UIColor.gray {
        didSet { tagViews.forEach { $0.tagBackgroundColor = tagBackgroundColor } }
    }

    @IBInspectable
    open dynamic var tagHighlightedBackgroundColor: UIColor? {
        didSet { tagViews.forEach { $0.highlightedBackgroundColor = tagHighlightedBackgroundColor } }
    }

    @IBInspectable
    open dynamic var tagSelectedBackgroundColor: UIColor? {
        didSet { tagViews.forEach { $0.selectedBackgroundColor = tagSelectedBackgroundColor } }
    }

    @IBInspectable
    open dynamic var tagCornerRadius: CGFloat = 0 {
        didSet { tagViews.forEach { $0.tagCornerRadius = tagCornerRadius } }
    }

    @IBInspectable
    open dynamic var tagBorderWidth: CGFloat = 0 {
        didSet { tagViews.forEach { $0.tagBorderWidth = tagBorderWidth } }
    }

    @IBInspectable
    open dynamic var tagBorderColor: UIColor? {
        didSet { tagViews.forEach { $0.tagBorderColor = tagBorderColor } }
    }

    @IBInspectable
    open dynamic var tagSelectedBorderColor: UIColor? {
        didSet { tagViews.forEach { $0.tagSelectedBorderColor = tagSelectedBorderColor } }
    }

    @IBInspectable
    open dynamic var tagShadowColor: UIColor = .white {
        didSet { rearrangeViews() }
    }

    @IBInspectable
    open dynamic var tagShadowRadius: CGFloat = 0 {
        didSet { rearrangeViews() }
    }

    @IBInspectable
    open dynamic var tagShadowOffset: CGSize = .zero {
        didSet { rearrangeViews() }
    }

    @IBInspectable
    open dynamic var tagShadowOpacity: Float = 0 {
        didSet { rearrangeViews() }
    }

    @IBInspectable
    open dynamic var isRemoveButtonEnabled: Bool = false {
        didSet {
            defer { rearrangeViews() }
            tagViews.forEach {
                $0.isRemoveButtonEnabled = isRemoveButtonEnabled
            }
        }
    }

    @IBInspectable
    open dynamic var removeIconSize: CGFloat = 12 {
        didSet {
            defer { rearrangeViews() }
            tagViews.forEach {
                $0.removeIconSize = removeIconSize
            }
        }
    }

    @IBInspectable
    open dynamic var removeIconLineWidth: CGFloat = 1 {
        didSet {
            defer { rearrangeViews() }
            tagViews.forEach {
                $0.removeIconLineWidth = removeIconLineWidth
            }
        }
    }

    @IBInspectable
    open dynamic var removeIconColor: UIColor = UIColor.white.withAlphaComponent(0.54) {
        didSet {
            defer { rearrangeViews() }
            tagViews.forEach {
                $0.removeIconColor = removeIconColor
            }
        }
    }

    @IBInspectable
    open dynamic var fontSize: CGFloat = 12 {
        didSet {
            textFont = UIFont(name: fontName, size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
        }
    }

    @IBInspectable
    open dynamic var fontName: String = "PingFangSC-Regular" {
        didSet {
            textFont = UIFont(name: fontName, size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
        }
    }

    @objc
    open dynamic var textFont: UIFont = .systemFont(ofSize: 12) {
        didSet {
            defer { rearrangeViews() }
            tagViews.forEach {
                $0.textFont = textFont
            }
        }
    }

    // MARK: Tag appearance configuration

    @objc public enum Alignment: Int {
        case left
        case center
        case right
    }

    public var alignment: Alignment = .left {
        didSet {
            rearrangeViews()
        }
    }

    @IBInspectable
    open dynamic var paddingX: CGFloat = 5 {
        didSet {
            defer { rearrangeViews() }
            tagViews.forEach {
                $0.paddingX = paddingX
            }
        }
    }

    @IBInspectable
    open dynamic var paddingY: CGFloat = 2 {
        didSet {
            defer { rearrangeViews() }
            tagViews.forEach {
                $0.paddingY = paddingY
            }
        }
    }

    @IBInspectable
    open dynamic var marginY: CGFloat = 2 {
        didSet {
            rearrangeViews()
        }
    }

    @IBInspectable
    open dynamic var marginX: CGFloat = 5 {
        didSet {
            rearrangeViews()
        }
    }

    // MARK: Privates

    public private (set) var tagViews: [UDTagListItemView] = []
    private(set) var tagWrapperViews: [UIView] = []
    private(set) var rowViews: [UIView] = []
    private(set) var tagViewHeight: CGFloat = 0
    private(set) var numberOfRows = 0 {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    // MARK: Interface Builder

    public override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        addTag("Tag 1")
        addTag("Tag 2")
        addTag("Tag 3")
        addTag("Selected Tag").isSelected = true
        addTag("Highlighted Tag").isHighlighted = true
    }

    // MARK: Layout

    public override func layoutSubviews() {
        super.layoutSubviews()
        rearrangeViews()
    }

    private func rearrangeViews() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }

        let views = tagViews as [UIView] + tagWrapperViews + rowViews
        views.forEach {
            $0.removeFromSuperview()
        }
        rowViews.removeAll(keepingCapacity: true)

        var currentRow = 0
        var currentRowView: UIView = UIView()
        var currentRowWidth: CGFloat = 0
        var numberOfTagsInCurrentRow = 0

        for (index, tagView) in tagViews.enumerated() {
            tagView.frame.size = tagView.intrinsicContentSize
            tagViewHeight = tagView.frame.height

            let hasCurrentRow = numberOfTagsInCurrentRow != 0
            let shouldCreateNextRow = currentRowWidth + tagView.frame.width > frame.width
            if  !hasCurrentRow || shouldCreateNextRow {
                currentRow += 1
                currentRowWidth = 0
                numberOfTagsInCurrentRow = 0
                currentRowView = UIView()
                currentRowView.frame.origin.y = CGFloat(currentRow - 1) * (tagViewHeight + marginY)

                rowViews.append(currentRowView)
                addSubview(currentRowView)

                tagView.frame.size.width = min(tagView.frame.size.width, frame.width)
            }

            let tagWrapperView = tagWrapperViews[index]
            tagWrapperView.frame.origin = CGPoint(x: currentRowWidth, y: 0)
            tagWrapperView.frame.size = tagView.bounds.size
            tagWrapperView.layer.shadowColor = tagShadowColor.cgColor
            tagWrapperView.layer.shadowPath = UIBezierPath(roundedRect: tagWrapperView.bounds, cornerRadius: tagCornerRadius).cgPath
            tagWrapperView.layer.shadowOffset = tagShadowOffset
            tagWrapperView.layer.shadowOpacity = tagShadowOpacity
            tagWrapperView.layer.shadowRadius = tagShadowRadius
            tagWrapperView.addSubview(tagView)
            currentRowView.addSubview(tagWrapperView)

            numberOfTagsInCurrentRow += 1
            currentRowWidth += tagView.frame.width + marginX

            switch alignment {
            case .left:
                currentRowView.frame.origin.x = 0
            case .center:
                currentRowView.frame.origin.x = (frame.width - (currentRowWidth - marginX)) / 2
            case .right:
                currentRowView.frame.origin.x = frame.width - (currentRowWidth - marginX)
            }
            currentRowView.frame.size.width = currentRowWidth
            currentRowView.frame.size.height = max(tagViewHeight, currentRowView.frame.height)
        }
        numberOfRows = currentRow

        setContentHuggingPriority(.defaultHigh, for: .vertical)
        setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
    }

    // MARK: Manage tags

    override public var intrinsicContentSize: CGSize {
        var height: CGFloat = 0
        if numberOfRows > 0 {
            height += CGFloat(numberOfRows) * (tagViewHeight + marginY) - marginY
        }
        return CGSize(width: frame.width, height: height)
    }

    public func createNewTagView(_ title: String) -> UDTagListItemView {
        let tagView = UDTagListItemView(title: title)

        tagView.textColor = textColor
        tagView.selectedTextColor = selectedTextColor
        tagView.tagBackgroundColor = tagBackgroundColor
        tagView.highlightedBackgroundColor = tagHighlightedBackgroundColor
        tagView.selectedBackgroundColor = tagSelectedBackgroundColor
        tagView.titleLineBreakMode = tagLineBreakMode
        tagView.tagCornerRadius = tagCornerRadius
        tagView.tagBorderWidth = tagBorderWidth
        tagView.tagBorderColor = tagBorderColor
        tagView.tagSelectedBorderColor = tagSelectedBorderColor
        tagView.paddingX = paddingX
        tagView.paddingY = paddingY
        tagView.textFont = textFont
        tagView.removeIconLineWidth = removeIconLineWidth
        tagView.removeIconSize = removeIconSize
        tagView.isRemoveButtonEnabled = isRemoveButtonEnabled
        tagView.removeIconColor = removeIconColor
        tagView.addTarget(self, action: #selector(tagPressed(_:)), for: .touchUpInside)
        tagView.removeButton.addTarget(self, action: #selector(removeButtonPressed(_:)), for: .touchUpInside)

        // On long press, deselect all tags except this one
        /*
        tagView.onLongPress = { [unowned self] this in
            self.tagViews.forEach {
                $0.isSelected = $0 == this
            }
        }
         */

        return tagView
    }

    @discardableResult
    public func addTag(icon: UIImage, title: String, spacing: CGFloat, iconSize: CGFloat, code: Int = 0) -> UDTagListItemView {
        defer { rearrangeViews() }
        let tagView = createNewTagView(title)
        tagView.isTagIconEnabled = true
        tagView.spacing = spacing
        tagView.tagIconTintColor = textColor
        tagView.tagIconSize = iconSize
        tagView.tagIconImage = icon
        tagView.tag = code
        return addTagView(tagView)
    }

    @discardableResult
    public func addTag(_ title: String, textColor: UIColor? = nil, backgroundColor: UIColor? = nil) -> UDTagListItemView {
        defer { rearrangeViews() }
        let tagView = createNewTagView(title)
        if let textColor = textColor {
            tagView.textColor = textColor
        }
        if let backgroundColor = backgroundColor {
            tagView.backgroundColor = backgroundColor
        }
        return addTagView(tagView)
    }

    @discardableResult
    public func addTags(_ titles: [String]) -> [UDTagListItemView] {
        return addTagViews(titles.map(createNewTagView))
    }

    @discardableResult
    public func addTagView(_ tagView: UDTagListItemView) -> UDTagListItemView {
        defer { rearrangeViews() }
        addTagViews([tagView])
        return tagView
    }

    @discardableResult
    public func addTagViews(_ tagViews: [UDTagListItemView]) -> [UDTagListItemView] {
        defer { rearrangeViews() }
        for tagView in tagViews {
            self.tagViews.append(tagView)
            self.tagWrapperViews.append(UIView(frame: tagView.bounds))
        }
        return tagViews
    }

    @discardableResult
    public func insertTag(_ title: String, at index: Int) -> UDTagListItemView {
        return insertTagView(createNewTagView(title), at: index)
    }

    @discardableResult
    public func insertTagView(_ tagView: UDTagListItemView, at index: Int) -> UDTagListItemView {
        defer { rearrangeViews() }
        tagViews.insert(tagView, at: index)
        tagWrapperViews.insert(UIView(frame: tagView.bounds), at: index)

        return tagView
    }

    public func removeTag(_ title: String) {
        tagViews.reversed().filter({ $0.currentTitle == title }).forEach(removeTagView)
    }

    public func removeTagView(_ tagView: UDTagListItemView) {
        defer { rearrangeViews() }

        tagView.removeFromSuperview()
        if let index = tagViews.firstIndex(of: tagView) {
            tagViews.remove(at: index)
            tagWrapperViews.remove(at: index)
        }
    }

    public func removeAllTags() {
        defer {
            tagViews = []
            tagWrapperViews = []
            rearrangeViews()
        }

        let views: [UIView] = tagViews + tagWrapperViews
        views.forEach { $0.removeFromSuperview() }
    }

    public func getSelectedTags() -> [UDTagListItemView] {
        return tagViews.filter { $0.isSelected }
    }

    public func contains(_ title: String) -> Bool {
        for tagView in tagViews where tagView.title == title {
            return true
        }
        return false
    }

    public func contains(_ tagView: UDTagListItemView) -> Bool {
        return tagViews.contains(tagView)
    }

    public func setTitle(_ title: String, at index: Int) {
        tagViews[index].titleLabel?.text = title
    }

    // MARK: Events

    @objc
    func tagPressed(_ sender: UDTagListItemView) {
        sender.onTap?(sender)
        let index = tagViews.firstIndex(of: sender) ?? 0
        delegate?.tagListView?(self, didSelectTag: sender, atIndex: index)
        onTagSelected?(index, sender)
    }

    @objc
    func removeButtonPressed(_ closeButton: CloseButton) {
        if let tagView = closeButton.tagView {
            let index = tagViews.firstIndex(of: tagView) ?? 0
            delegate?.tagListView?(self, didTapRemoveButtonForTag: tagView, atIndex: index)
            onTagRemoving?(index, tagView)
        }
    }
}

