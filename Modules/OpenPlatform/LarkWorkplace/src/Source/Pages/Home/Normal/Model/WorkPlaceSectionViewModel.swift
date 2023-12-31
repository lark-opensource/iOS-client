//
//  WorkPlaceSectionModel.swift
//  LarkWorkplace
//
//  Created by lilun.ios on 2020/8/12.
//

import UIKit
import LarkWorkplaceModel
import LKCommonsLogging

/// section 类型
enum SectionType {
    /// 常用组件
    case favorite
    /// 应用分组 （仅原生工作台）
    case normalSection
    /// 全部应用（仅原生工作台）
    case allAllsSection

    /// 转换为曝光 UI 类型
    var exposeUIType: WPExposeUIType {
        switch self {
        case .favorite:
            return .commom_and_recommend
        case .normalSection:
            return .appGroups
        case .allAllsSection:
            return .allApps
        }
    }

    var module: String {
        let type = exposeUIType
        switch type {
        case .appGroups:
            return "customized_group"
        case .allApps:
            return "all_applications"
        case .commom_and_recommend, .recentlyUsed:
            return "my_common"
        default:
            return ""
        }
    }
}

/// section 收缩状态
enum SectionState {
    case fold(count: Int)
    case unfold
    case none
}

enum SubSectionState {
    /// 数据加载中
    case loading
    /// 数据加载成功
    case success
    /// 数据加载失败
    case fail
    /// 无数据
    case empty
}

/// 一个子section的数据状态
struct SubSection {
    /// 对应的子Tag
    var currentTag: SubTag
    /// 状态
    var state: SubSectionState
    /// hasMore
    var hasMore: Bool = false
}

/// 所有应用的section
final class AllAppsSection {
    static let logger = Logger.log(AllAppsSection.self)

    /// 当前选中的tag
    var currentTag: SubTag
    /// 子Tag列表
    var subTags: [SubTag] = []
    /// data tagId -> Section Data
    var sectionData: [Int: SubSection]
    init(currentTag: SubTag, subTags: [SubTag], sectionData: [Int: SubSection]) {
        self.currentTag = currentTag
        self.subTags = subTags
        self.sectionData = sectionData
    }
    /// 更新状态数据
    func updateSubSection(
        forTag: SubTag,
        state: SubSectionState
    ) {
        Self.logger.info("updateSubSection \(forTag.tagName) to state \(state)")
        let hasMore = sectionData[forTag.tagId]?.hasMore ?? false
        sectionData[forTag.tagId] = SubSection(currentTag: forTag, state: state, hasMore: hasMore)
    }
    /// 更新是否存在hasMore
    func updateSubHasMore(
        forTag: SubTag,
        hasMore: Bool?
    ) {
        Self.logger.info("updateSubHasMore \(forTag.tagName) hasMore \(String(describing: hasMore))")
        if let subdata = sectionData[forTag.tagId] {
            sectionData[forTag.tagId] = SubSection(
                currentTag: forTag,
                state: subdata.state,
                hasMore: hasMore ?? false
            )
        }
    }
    /// 选中某个tag
    func selectSubTag(tag: SubTag, dataComplete: (() -> Void)? = nil) {
        Self.logger.info("selectSubTag \(tag.tagName)")
        if subTags.contains(where: { (subtag) -> Bool in
            return tag.tagId == subtag.tagId
        }), let subSectionData = sectionData[tag.tagId] {
            currentTag = tag
            if subSectionData.state == .fail || subSectionData.state == .empty {
                updateSubSection(forTag: tag, state: .loading)
            } else if subSectionData.state == .loading {
                /// pass
            } else {
            }
            dataComplete?()
        }
    }
    /// name list
    func nameList() -> [String] {
        let nameArray = subTags.map { (subtag) -> String in
            return subtag.tagName
        }
        return nameArray
    }
    /// selected index
    func selectedIndex() -> IndexPath {
        for i in 0..<subTags.count {
            let subtag = subTags[i]
            if subtag.tagId == currentTag.tagId {
                return IndexPath(item: i, section: 0)
            }
        }
        return IndexPath(item: 0, section: 0)
    }
}

struct SectionItems {
    /// ItemModel列表
    var itemList: [WorkPlaceItem] = []
    /// ItemModel Map（全部分类）
    var itemMap: [Int: [WorkPlaceItem]] = [:]
    /// subTagInfo（全部分类的子tag）
    var subTagMap: [Int: SubTagItemInfo] = [:]
}

protocol WorkPlaceSection {
    var originItems: SectionItems { get set }
    var displayItems: SectionItems { get set }
    /// 如果没有分组Name，返回空串
    var sectionName: String { get }
    /// 是否显示分组Name
    var isDisplayHeader: Bool { get }
    /// 获取收缩状态
    var foldState: SectionState { get set }
    /// source Tag
    var tag: Tag { get }
    /// 所有应用的数据模型
    var allAppsData: AllAppsSection? { get set }
    /// 分组类型
    var type: SectionType { get }
    /// 获取分组header尺寸
    func getHeaderSize(superViewWidth: CGFloat) -> CGSize
    /// 获取分组footer尺寸
    func getFooterSize(collectionview: UICollectionView, section: Int, itemsPerRow: Int) -> CGSize
    /// 获取指定位置的item
    func getItemAtIndex(index: Int) -> WorkPlaceItem?
    /// 获取item数量
    func getDisplayItemCount() -> Int
    /// 获取item列表
    func getOriginItems() -> [WorkPlaceItem]
    /// 获取item列表
    func getOriginItemsApplyFoldState() -> [WorkPlaceItem]
    /// 经过处理的item列表
    func getDisplayItems() -> [WorkPlaceItem]
    /// 设置原始items，可能是针对当前的子tag
    func setOriginItems(items: [WorkPlaceItem], subtag: SubTag?)
    /// 设置原始items，可能是针对当前的子tag
    func setDisplayItems(items: [WorkPlaceItem], subtag: SubTag?)
    /// 同步旧数据
    func syncDataFrom(oldSection: WorkPlaceSection)
    /// 折叠状态流转
    func stateSwitch()
    /// 是否有更多数据
    func hasMoreData() -> Bool
    /// badge key
    func badgeKey() -> [WorkPlaceBadge.BadgeSingleKey]?
    /// need display badge first row
    func needDisplayBadgesInFirstRow() -> Bool
}
final class SectionModel: WorkPlaceSection {
    static let logger = Logger.log(SectionModel.self)

    /// 原始items
    var originItems: SectionItems
    /// 布局之后的items
    var displayItems: SectionItems
    /// 是否展示section的header
    var isDisplayHeader: Bool = false
    /// 获取收缩状态
    var foldState: SectionState = .none
    /// section的headerName，默认为空
    var sectionName: String = ""
    /// tag
    var tag: Tag
    /// 所有应用的数据
    var allAppsData: AllAppsSection?
    /// 分组类型
    let type: SectionType
    /// 折叠状态下的最多展示数量
    static let maxNumFold: Int = 12
    /// 分组应用标题的height
    static let normalGroupHeaderHeight: CGFloat = 24
    /// 带有子tag的分组高度
    static let subTagHeaderHeight: CGFloat = 70
    /// 水平方向相对于父布局的单边间距
    static let horizontalSectionMargin: CGFloat = 16

    init(group: GroupUnit, additionalInfoProxy: WorkPlaceQueryAdditionContext? = nil) {
        Self.logger.info("WorkPlaceViewModel's SectionModel init start")
        /// section相关信息
        let sectionTag = group.category
        self.isDisplayHeader = sectionTag.showTagHeader
        self.sectionName = sectionTag.categoryName
        self.tag = group.category.tag
        self.originItems = SectionItems()
        self.displayItems = SectionItems()
        Self.logger.info("SectionModel init \(self.sectionName)")
        self.type = Self.getSectionType(tag: group.category.tag)
        /// 检查子标签和分类列表数据
        checkSectionCategoryInfo(hasMore: sectionTag.tag.hasMore ?? false)
        /// 解析items列表
        let items = group.itemUnits
        var tempOriginItems: [ItemModel] = []
        let isAddRect = isAddIconRect(items: items) // 判断添加应用（system_add）是否是方形的
        /// 遍历items，组装itemList
        items.forEach { (item) in
            if item.type == .icon, item.subType == .systemAdd {
                let itemModel = ItemModel(
                    dataItem: item,
                    isAddRect: isAddRect
                )
                tempOriginItems.append(itemModel)
                Self.logger.info("SectionModel init with system_add")
            } else {
                let itemModel = ItemModel(
                    dataItem: item,
                    isAddRect: false,
                    sectionCanDisplayBadge: group.shouldDisplayBadge(),
                    additionalInfoProxy: additionalInfoProxy
                )
                tempOriginItems.append(itemModel)
            }
        }
        Self.logger.info("SectionModel init with items \(tempOriginItems.count)")
        setOriginItems(items: tempOriginItems, subtag: self.allAppsData?.currentTag)
    }

    private static func getSectionType(tag: Tag) -> SectionType {
        if let isMainTag = tag.isMainTag, isMainTag {
            return .favorite
        } else if let subTags = tag.subTags, !subTags.isEmpty {
            return .allAllsSection
        } else {
            return .normalSection
        }
    }

    /// 检查子标签和分类列表数据，如果含有子tag, 那么高度需要变换为带子tag的header高度
    private func checkSectionCategoryInfo(hasMore: Bool) {
        if let subTags = self.tag.subTags, !subTags.isEmpty {
            /// 全部应用默认展示header
            isDisplayHeader = true
            /// 填充全部分类页面数据
            var sectionData: [Int: SubSection] = [:]
            for subTag in subTags {
                let subsection = SubSection(currentTag: subTag, state: .loading)
                sectionData[subTag.tagId] = subsection
            }
            self.allAppsData = AllAppsSection(currentTag: subTags[0], subTags: subTags, sectionData: sectionData)
            /// 初始化第一次从首页列表中带下来的HasMore标记
            self.allAppsData?.updateSubHasMore(forTag: subTags[0], hasMore: hasMore)
        }
    }

    /// 检查 system_add 的上一个item是什么类型，如果是widget，或者不存在，就是方形，其他是圆形
    private func isAddIconRect(items: [ItemUnit]) -> Bool {
        var prevItemType: WPTemplateModule.ComponentDetail.Favorite.AppType?
        for (index, item) in items.enumerated() where
        item.type == .icon && item.subType == .systemAdd && index > 0 {
            /// 如果上一个item的类型存在
            prevItemType = items[index - 1].type
            break
        }
        /// 如果上一个类型不存在或者是widget，那么就是方形
        return (prevItemType == nil || prevItemType == .widget || prevItemType == .block)
    }

    /// 状态流转
    func stateSwitch() {
        switch self.foldState {
        case .fold:
            self.foldState = .unfold
        case .unfold:
            self.foldState = .fold(count: getOriginItems().count)
        case .none:
            self.foldState = .none
        }
    }

    /// 获取当前section的headerSize
    func getHeaderSize(superViewWidth: CGFloat) -> CGSize {
        /// 默认是普通的header高度
        var headerHeight = SectionModel.normalGroupHeaderHeight
        /// 如果含有子tag, 那么高度需要变换为带子tag的header高度
        switch type {
        case .allAllsSection:
            headerHeight = SectionModel.subTagHeaderHeight
        case .favorite, .normalSection:
            break
        }
        if isDisplayHeader {
            return CGSize(
                width: superViewWidth - SectionModel.horizontalSectionMargin * 2,
                height: headerHeight
            )
        } else {
            return .zero
        }
    }
    /// 得到footer的高度
    func getFooterSize(collectionview: UICollectionView, section: Int, itemsPerRow: Int) -> CGSize {
        let items = getDisplayItems()
        guard type == .allAllsSection, !items.isEmpty else { return .zero }
        var totalHeight = SectionModel.subTagHeaderHeight
        var rows: CGFloat = 0.0
        var icons: Int = 0
        for i in 0..<items.count {
            let item = items[i]
            if item.itemType == .addIcon ||
                item.itemType == .fillItem ||
                item.itemType == .icon {
                icons += 1
                rows += 1.0 / CGFloat(itemsPerRow)
            } else {
                /// 计算icons的高度
                if icons > 0 {
                    totalHeight += ItemModel.iconItemSize.height * ceil(CGFloat(icons) / CGFloat(itemsPerRow))
                    /// 清0计数
                    icons = 0
                }
                totalHeight += item.getItemLayoutSize(superViewWidth: collectionview.bdp_width).height
                rows += 1.0
            }
        }
        totalHeight += ItemModel.iconItemSize.height * ceil(CGFloat(icons) / CGFloat(itemsPerRow))
        totalHeight += (ceil(rows) - 1) * ItemModel.miniLineSpace
        let diffHeight = collectionview.bdp_height - totalHeight
        let width = collectionview.bdp_width - SectionModel.horizontalSectionMargin * 2
        var height = diffHeight >= 0 ? diffHeight : 0
        /// 如果存在hasmore，那么高度最少是footerViewHeight，显示hasmore
        height = hasMoreData() ? max(height, footerViewHeight) : height
        return CGSize(width: width, height: height)
    }
    /// 获取当前的Item列表
    func getOriginItems() -> [WorkPlaceItem] {
        switch type {
        case .favorite, .normalSection:
            return originItems.itemList
        case .allAllsSection:
            if let subtag = self.allAppsData?.currentTag {
                return originItems.itemMap[subtag.tagId] ?? []
            }
        }
        return []
    }
    /// 应用收起状态下面的原始items个数
    func getOriginItemsApplyFoldState() -> [WorkPlaceItem] {
        let items = getOriginItems()
        switch self.foldState {
        case .fold:
            return Array(items.prefix(SectionModel.maxNumFold))
        default:
            return items
        }
    }
    private func markCanDisplayWidget(items: [WorkPlaceItem]) -> [WorkPlaceItem] {
        return items.map({ (item: WorkPlaceItem) -> WorkPlaceItem in
            var copyItem = item
            copyItem.sectionCanDisplayWidget = tag.canDisplayWidget()
            return copyItem
        })
    }
    /// 更新原始items数据
    func setOriginItems(items: [WorkPlaceItem], subtag: SubTag?) {
        Self.logger.info("setOriginItems items count \(items.count) for tag \(subtag?.tagName ?? "")")
        switch type {
        case .favorite, .normalSection:
            originItems.itemList = markCanDisplayWidget(items: items)
        case .allAllsSection:
            if let tag = subtag {
                originItems.itemMap[tag.tagId] = markCanDisplayWidget(items: items)
            }
        }
        /// update section fold state
        setSectionFoldState(itemsCount: items.count)
    }

    /// 初始化分组的折叠状态
    private func setSectionFoldState(itemsCount: Int) {
        switch type {
        case .favorite, .allAllsSection:
            self.foldState = .none
        case .normalSection:
            if itemsCount > SectionModel.maxNumFold {    // 数量超过显示，需要折叠
                self.foldState = .fold(count: itemsCount)
            } else {
                self.foldState = .none
            }
        }

    }

    /// 获取展示的item列表
    func getDisplayItems() -> [WorkPlaceItem] {
        switch type {
        case .favorite, .normalSection:
            return displayItems.itemList
        case .allAllsSection:
            guard let allAppData = self.allAppsData,
                  let subdata = allAppData.sectionData[allAppData.currentTag.tagId] else { return [] }
            switch subdata.state {
            case .success:
                return displayItems.itemMap[allAppData.currentTag.tagId] ?? []
            case .loading:
                return makeStateItems(state: .loading, repeatCount: WorkPlaceViewModel.appsCountPerRow * 3)
            case .fail:
                return makeStateItems(state: .fail)
            case .empty:
                return makeStateItems(state: .empty)
            }
        }
        return []
    }
    private func makeStateItems(
        state: SubSectionState,
        repeatCount: Int = 1
    ) -> [StateItemModel] {
        var result: [StateItemModel] = []
        for _ in 1...max(repeatCount, 1) {
            let model = StateItemModel(
                itemType: .stateItem,
                state: state
            )
            result.append(model)
        }
        return result
    }

    /// 获取指定位置的Item
    /// - Parameter index: item位置
    func getItemAtIndex(index: Int) -> WorkPlaceItem? {
        let items = getDisplayItems()
        if index < items.count {
            return items[index]
        }
        return nil
    }

    /// 获取当前section的item数量
    func getDisplayItemCount() -> Int {
        getDisplayItems().count
    }
    /// 获取展示的item列表
    func setDisplayItems(items: [WorkPlaceItem], subtag: SubTag?) {
        Self.logger.info("setDisplayItems items count \(items.count) for tag \(subtag?.tagName ?? "")")
        switch type {
        case .favorite, .normalSection:
            displayItems.itemList = items
        case .allAllsSection:
            guard let tag = subtag else { return }
            displayItems.itemMap[tag.tagId] = items
            /// 如果当前已经是失败状态
            if let currentState = allAppsData?.sectionData[tag.tagId],
                currentState.state == .fail {
                let state: SubSectionState = !items.isEmpty ? .success : .fail
                allAppsData?.updateSubSection(forTag: tag, state: state)
            } else {
                let state: SubSectionState = !items.isEmpty ? .success : .empty
                allAppsData?.updateSubSection(forTag: tag, state: state)
            }
        }
    }
    /// 同步旧的section的数据
    func syncDataFrom(oldSection: WorkPlaceSection) {
        Self.logger.info("syncDataFrom oldSection \(oldSection.sectionName)")
        switch type {
        case .favorite, .normalSection:
            foldState = oldSection.foldState
        case .allAllsSection:
            guard let allData = oldSection.allAppsData else { return }
            for subtag in allData.subTags {
                if originItems.itemMap[subtag.tagId] == nil,
                    let originItems = oldSection.originItems.itemMap[subtag.tagId],
                    let displayItems = oldSection.originItems.itemMap[subtag.tagId],
                    let subsection = allData.sectionData[subtag.tagId] {
                    setOriginItems(
                        items: originItems,
                        subtag: subtag
                    )
                    setDisplayItems(
                        items: displayItems,
                        subtag: subtag
                    )
                    allAppsData?.updateSubSection(
                        forTag: subtag,
                        state: subsection.state
                    )
                }
            }
            /// 同步当前选中的tag
            allAppsData?.currentTag = allData.currentTag
        }
    }
    /// 是否存在更多数据
    func hasMoreData() -> Bool {
        switch type {
        case .allAllsSection:
            if let subtag = self.allAppsData?.currentTag {
                return self.allAppsData?.sectionData[subtag.tagId]?.hasMore ?? false
            }
        case .favorite, .normalSection:
            return false
        }
        return false
    }
    /// badge key
    func badgeKey() -> [WorkPlaceBadge.BadgeSingleKey]? {
        var result: [WorkPlaceBadge.BadgeSingleKey] = []
        for item in originItems.itemList {
            if let badgeList = item.badgeKey() {
                result += badgeList
            }
        }
        return result.isEmpty ? nil : result
    }
    /// 判断第一行是否有badge
    func needDisplayBadgesInFirstRow() -> Bool {
        var result: [WorkPlaceBadge.BadgeSingleKey] = []
        for item in originItems.itemList.prefix(WorkPlaceViewModel.appsCountPerRow) {
            /// 只有icon类型的badge才会对topInset产生影响
            if item.itemType == .icon,
               let badgeList = item.badgeKey() {
                result += badgeList
            }
        }
        if let badgeCount = BadgeTool.getBadge(badgeKey: result) {
            return badgeCount > 0
        }
        return false
    }
}
