//
//  NewTagWrapperView.swift
//  LarkTag
//
//  Created by CharlieSu on 4/24/20.
//

import UIKit
import Foundation
import SnapKit
import UniverseDesignTag
import UniverseDesignIcon

/// Tag 包装View，用来显示一组Tag
///
/// let tagView = TagWrapperView()
/// self.view.addSubview(tagView)
/// tagView.setElements(TagType.TagType)
///
public final class TagWrapperView: UIView {

    static let height = 18
    static let spacing = 6

    /// 最多显示Tag数量，默认为2
    public var maxTagCount: Int = 2 {
        didSet { reloadTag() }
    }

    /// 当前Tags，因为maxTagCount未显示出来的也算
    public private(set) var tags: [Tag]?

    /// cache labels
    private var cachedLabels: [UDTag] = []
    // 提供设置约束优先级的能力。当撑满最大宽度时，告诉布局引擎如何处理约束冲突问题
    public var lastTagTrailingPriority: SnapKit.ConstraintPriority = .required
    public override init(frame: CGRect) {
        super.init(frame: frame)

        self.setContentHuggingPriority(.required, for: .horizontal)
        self.setContentCompressionResistancePriority(.required, for: .horizontal)
        self.layer.masksToBounds = true
        snp.makeConstraints { $0.height.equalTo(Self.height).priority(.low) }
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public static func sizeToFit(tagType: TagType, containerSize: CGSize) -> CGSize {
        let configuration = tagConfig(tagType: tagType)
        return UDTag.sizeToFit(configuration: configuration, containerSize: containerSize)
    }
}

// MARK: set view info
extension TagWrapperView {
    /// rmove all old view
    private func clearOldTag() {
        let views = subviews
        views.forEach { (view) in
            view.snp.removeConstraints()
            view.removeFromSuperview()

            /// cache old label or imageView for reuse
            if let udTag = view as? UDTag {
                cachedLabels.append(udTag)
            }
        }
    }

    private func getReuseTag() -> UDTag {
        if !cachedLabels.isEmpty {
            return cachedLabels.removeLast()
        } else {
            return TagWrapperView.newTag()
        }
    }

    /// reload tags
    private func reloadTag() {
        clearOldTag()

        let count = min(tags?.count ?? 0, maxTagCount)
        for index in 0..<count {
            if let tag = tags?[index] {
                addSubview(view(for: tag))
            }
        }

        let subviews = self.subviews
        guard subviews.count > 0 else { return }

        var leading = self.snp.leading
        var offset = 0

        for item in subviews {
            item.snp.makeConstraints { (maker) in
                maker.leading.equalTo(leading).offset(offset)
                maker.centerY.equalToSuperview()
            }
            leading = item.snp.trailing
            offset = Self.spacing
        }

        subviews.last?.snp.makeConstraints { (maker) in
            // 默认为 required（线上逻辑）
            maker.trailing.equalToSuperview().priority(lastTagTrailingPriority)
        }
    }

    /// 由Tag生成对应的View（Label|UIImageView），有则读缓存，无则创建
    private func view(for tag: Tag) -> UIView {
        assert(!(tag.title ?? "").isEmpty || tag.image != nil, "One of image or text should have a value")

        let tagView = getReuseTag()
        tagView.sizeClass = tag.size
        var configuration = tagView.configuration
        configuration.text = tag.title
        configuration.icon = tag.image
        configuration.textAlignment = .left
        configuration.iconColor = nil
        configuration.textColor = tag.style.textColor
        configuration.backgroundColor = tag.style.backColor

        // 目前 iconTypes 内的图标大小由图片自身大小决定
        if TagType.iconTypes.contains(tag.type), let image = tag.image {
            configuration.iconSize = image.size
            tagView.updateConfiguration(configuration)
        } else {
            tagView.updateConfiguration(configuration)
        }

        return tagView
    }

    /// 删除所有Tag
    ///
    /// - Parameter isHidden: 是否隐藏TagView
    public func clean(_ isHidden: Bool = false) {
        self.tags = []
        reloadTag()
        self.isHidden = isHidden
    }

    /// 设置一组 'Tag'
    ///
    /// - Parameters:
    ///   - tags: Tag数组
    ///   - autoSort: 是否需要自动按照默认`TagType`的`rawvalue`从小到大的s顺序排序,  默认为 `true`
    public func setTags(_ tagTypes: [TagType], autoSort: Bool = true) {
        self.setElements(tagTypes, autoSort: autoSort)
    }

    /// 设置一组 'TagElement'
    ///
    /// - Parameters:
    ///   - elements: `TagElement` 数组
    ///   - autoSort: 是否需要自动按照默认`TagType`的`rawvalue`从小到大的s顺序排序,  默认为 `true`
    public func setElements(_ elements: [TagElement], autoSort: Bool = true) {
        self.tags = (autoSort ? elements.sorted { $0.type.rawValue < $1.type.rawValue } : elements).map { $0.tag }
        reloadTag()
    }

    public func set(tags: [Tag], autoSort: Bool = true) {
        self.tags = (autoSort ? tags.sorted { $0.type.rawValue < $1.type.rawValue } : tags)
        reloadTag()
    }
}

// MARK: - calss method
extension TagWrapperView {
    private class func tagConfig(tagType: TagType) -> UDTag.Configuration {
        var configuration: UDTag.Configuration

        if TagType.titleTypes.contains(tagType) {
            configuration = .text("", tagSize: tagType.tag.size)
        } else if TagType.iconTypes.contains(tagType), let image = tagType.tag.image {
            configuration = .icon(image, tagSize: tagType.tag.size)
            configuration.iconSize = image.size
        } else if TagType.iconTextTypes.contains(tagType) {
            configuration = .iconText(UIImage(), text: "", tagSize: tagType.tag.size)
        } else {
            configuration = .icon(UIImage(), tagSize: tagType.tag.size)
        }
        return configuration
    }

    /// create new Tag
    private class func newTag() -> UDTag {
        return UDTag(withIcon: UIImage(), text: "")
    }

    /// 通过TagType创建一个文本类型的View
    /// - Parameter tagType: TagType
    public class func titleTagView(for tagType: TagType) -> UDTag {
        return titleTagView(for: tagType.tag)
    }

    /// 通过Tag创建创建一个文本类型的View
    /// - Parameter tag: Tag
    public class func titleTagView(for tag: Tag) -> UDTag {
        assert(TagType.titleTypes.contains(tag.type), "Tag.Type error")
        assert(tag.title != nil && !tag.tag.title!.isEmpty, "’title‘ 不应该为nil")

        let labelTag = newTag()
        labelTag.sizeClass = tag.size
        var configuration = labelTag.configuration
        configuration.text = tag.title
        configuration.icon = nil
        configuration.textAlignment = .left
        configuration.textColor = tag.style.textColor
        configuration.backgroundColor = tag.style.backColor
        labelTag.updateConfiguration(configuration)
        return labelTag
    }

    /// 通过TagType创建一个图片类型的View
    /// - Parameter tagType: TagType
    public class func iconTagView(for tagType: TagType) -> UDTag {
        return iconTagView(for: (tagType as TagElement).tag)
    }

    /// 通过Tag创建创建一个图片类型的View
    /// - Parameter tag: Tag
    public class func iconTagView(for tag: Tag) -> UDTag {
        assert(TagType.iconTypes.contains(tag.type), "Tag.Type error")
        assert(tag.image != nil, "‘image’ 不应该为nil")

        let imageTag = newTag()
        guard let image = tag.image else { return imageTag }
        var configuration = imageTag.configuration
        configuration.iconColor = nil
        configuration.text = nil
        configuration.icon = image
        configuration.backgroundColor = tag.style.backColor
        configuration.iconSize = image.size
        imageTag.updateConfiguration(configuration)
        return imageTag
    }
}
