//
//  TagViewBuilder.swift
//  LarkBizTag
//
//  Created by 白镜吾 on 2022/11/23.
//

import Foundation
import LarkTag
import ThreadSafeDataStructure

/// https://bytedance.feishu.cn/docx/CCcBd2hhhoSwylxwqDRczQZonLe
open class TagViewBuilder {

    /// builder 接收的 tagItem 数组
    private var tagItems: SafeArray<TagDataItem> = [] + .readWriteLock

    /// builder 生成的 View
    open var tagsView: TagWrapperView?

    private var displayedCount: Int = 2

    /// 互斥标签数组
    ///
    /// 同一组数组为互斥数组，仅会出现最前面面的元素
    ///
    /// 如 `[[.relation, .organization, .external]]` 这样一组互斥标签 A，当业务输入的标签中包含 A 中两个及以上的标签时，只会显示第一个，也就是 `relation` 标签
    open var mutexTags: [[TagType]] {
        get {
            return []
        }
    }

    /// 业务自定义的 互斥关系，如果为空则走默认
    internal var customMutexTags: [[TagType]]?

    // 同标签类型允许存在多个
    private let uncheckedSameType: Set<TagType> = [.tenantTag]

    /// 设置 生成器 tag 互斥关系
    open func setMutexTags(mutexTags: [[TagType]] = []) -> Self {
        self.customMutexTags = mutexTags
        return self
    }

    public init() {}

    /// 构造包含多个 Tag 的 TagView，Tag 会在本函数中重新排序、并根据 mutexTags 中的规则进行筛选
    open func build() -> TagWrapperView {
        if self.tagsView == nil {
            self.tagsView = TagWrapperView()
        }
        // 通过互斥标签列表，选出最终展示出来的标签
        self.getSupportTags()
        self.tagsView?.maxTagCount = self.displayedCount
        // setTags 内部会根据标签唯一的优先级进行排序，确保最终展示顺序一致
        self.tagsView?.setElements(tagItems.map({ $0 }))
        guard let tagsView = self.tagsView else { return TagWrapperView() }
        return tagsView
    }

    /// 刷新 Tag 数组，如果不更新之前的 Tag， 则继续保留
    open func refresh() {
        Helper.execInMainThread {
            self.tagsView = self.build()
        }
    }

    /// 去掉当前所有tag
    /// 当还没有重置 TagView
    /// 如果重置并更新view，可以使用update方法
    @discardableResult
    open func reset(with tagData: [TagDataItem]) -> Self {
        self.tagItems.removeAll()
        self.addTags(with: tagData)
        return self
    }

    /// 更新 TagDataItem 数组，重新绘制 TagView
    ///
    /// - Parameters:
    ///  - with: 一组 TagDataItem
    @discardableResult
    open func update(with tagData: [TagDataItem]) -> TagWrapperView {
        guard self.tagsView != nil else {
            assertionFailure("tagsView does not exist, please use 'build()' to generate")
            return TagWrapperView()
        }
        self.reset(with: tagData)
        return self.build()
    }

    /// 获取到最终展示到UI上的标签是否为空
    @discardableResult
    open func isDisplayedEmpty() -> Bool {
        return tagItems.isEmpty
    }

    /// 展示的标签数
    @discardableResult
    open func setDisplayedCount(_ displayedCount: Int) -> Self {
        guard displayedCount > 0 else {
            assertionFailure("The number of labels displayed needs to be greater than 0")
            return self
        }
        self.displayedCount = displayedCount
        return self
    }

    /// 新增一个 Tag
    ///
    /// - Parameters:
    ///  - with: 一个 TagDataItem
    @discardableResult
    open func addTag(with tagDataItem: TagDataItem) -> Self {
        guard tagDataItem.tagType != .unKnown else {
            assertionFailure("This Type Cant be Unknown")
            return self
        }

        if !uncheckedSameType.contains(tagDataItem.tagType) {
            // 需要对同类型标签进行去重
            if (self.tagItems.contains(where: { $0.tagType == tagDataItem.tagType })) {
                /// 如果当前已有该type了，不重复添加
                return self
            }
        }
        let defaultTagInfo = Tag.defaultTagInfo(for: tagDataItem.tagType.convert())
        let item = TagDataItem(text: tagDataItem.text ?? defaultTagInfo.title,
                               image: tagDataItem.image ?? defaultTagInfo.image,
                               tagType: tagDataItem.tagType,
                               frontColor: tagDataItem.frontColor ?? defaultTagInfo.style.textColor,
                               backColor: tagDataItem.backColor ?? defaultTagInfo.style.backColor,
                               priority: tagDataItem.priority)
        self.tagItems.append(item)
        return self
    }

    /// 新增多个 Tag
    /// - Parameters:
    ///  - with: 一组 TagDataItem
    @discardableResult
    open func addTags(with tagData: [TagDataItem]) -> Self {
        tagData.forEach { tagDataItem in
            self.addTag(with: tagDataItem)
        }
        return self
    }

    /// 通过 TagType 添加 TagItem，均将采用默认值进行转换
    ///
    /// - Parameters:
    ///  - with: 标签类型
    @discardableResult
    open func addTagItem(with tagType: TagType) -> Self {
        guard tagType != .unKnown else {
            assertionFailure("This Type Cant be Unknown")
            return self
        }
        if !uncheckedSameType.contains(tagType) {
            // 需要对同类型标签进行去重
            if (self.tagItems.contains(where: { $0.tagType == tagType })) {
                /// 如果当前已有该type了，不重复添加
                return self
            }
        }
        let defaultTagInfo = Tag.defaultTagInfo(for: tagType.convert())
        let item = TagDataItem(text: defaultTagInfo.title,
                               image: defaultTagInfo.image,
                               tagType: tagType,
                               frontColor: defaultTagInfo.style.textColor,
                               backColor: defaultTagInfo.style.backColor,
                               priority: tagType.rawValue)
        self.tagItems.append(item)
        return self
    }

    /// 通过一组 TagType 添加 TagItem，均将采用默认值进行转换
    ///
    /// - Parameters:
    ///  - with: 一组标签类型
    @discardableResult
    open func addTagItems(with tagTypes: [TagType]) -> Self {
        tagTypes.forEach { tagType in
            self.addTagItem(with: tagType)
        }
        return self
    }

    /// 通过 TagType 添加 TagItem，均将采用默认值进行转换
    ///
    /// - Parameters:
    ///  - with: 标签类型
    @discardableResult
    open func removeTag(with tagType: TagType) -> Self {
        Helper.execInMainThread {
            if let index = self.tagItems.firstIndex(where: { $0.tagType == tagType }) {
                self.tagItems.remove(at: index)
            }
        }
        return self
    }

    /// 去除互斥 Tag，获得最终展示的 Tags
    public func getSupportTags() -> SafeArray<TagDataItem> {
        for tags in mutexTags {
            var findFirst = true
            for tagType in tags {
                /// 当前用户输入 Tag 中存在 互斥 tag
                if !uncheckedSameType.contains(tagType) {
                    // 需要对同类型标签进行去重
                    guard self.tagItems.contains(where: { $0.tagType == tagType }) else { continue }
                }
                if findFirst {
                    findFirst = false
                } else {
                    Helper.execInMainThread {
                        self.removeTag(with: tagType)
                    }
                }
            }
        }
        return self.tagItems
    }

    /// 判断是否需要添加 / 删除 Tag
    open func judgeType(value: Bool, tagType: TagType) {
        if value {
            self.addTagItem(with: tagType)
        } else {
            self.removeTag(with: tagType)
        }
    }
}
