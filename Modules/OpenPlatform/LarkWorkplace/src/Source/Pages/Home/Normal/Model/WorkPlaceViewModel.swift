//
//  WorkPlaceUIModel.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2020/5/8.
//

import SwiftyJSON
import LKCommonsLogging
import LarkUIKit

final class WorkPlaceViewModel {
    static let logger = Logger.log(WorkPlaceViewModel.self)

    static let itemMinSpace: CGFloat = Display.pad ? 2 : 10
    /// 时间戳（单位：s）
    var timestamp: Int = 0
    /// 返回真实的Item
    var sectionsList: [WorkPlaceSection] = []
    /// 容器的宽度（默认值为屏幕宽度，初始化时会传入容器宽度）
    static var containerWidth: CGFloat = UIScreen.main.bounds.width
    /// data update
    var dataUpdateCallback: (([Int]) -> Void)?
    /// 每一行容纳的app item的个数
    static var appsCountPerRow: Int {
        let space = WorkPlaceViewModel.itemMinSpace
        /// 每一行最多可以排下来的item个数
        // swiftlint:disable line_length
        let maxAppsCount = (containerWidth - ItemModel.horizontalCellMargin * 2 + space) / (ItemModel.iconItemWidth + space)
        // swiftlint:enable line_length
        return Int(maxAppsCount)
    }
    /// 记录item额外信息的map
    var itemAdditionalMap: [String: ItemModelAdditionInfo] = [:]
    /// 全部应用分组
    var allAppSectionModel: SectionModel?
    private let dataManager: AppCenterDataManager
    /// 返回section的数量
    func getSectionsCount() -> Int {
        return sectionsList.count
    }
    /// 获取指定指定位置的section
    func getSectionModel(index: Int) -> WorkPlaceSection? {
        guard index < sectionsList.count else {
            Self.logger.error("getSectionModel wrong index \(index)")
            return nil
        }
        return sectionsList[index]
    }
    /// init method
    init(dataModel: WorkPlaceDataModel, containerWidth: CGFloat, dataManager: AppCenterDataManager) {
        self.dataManager = dataManager
        Self.logger.info("WorkPlaceViewModel initial start")
        self.timestamp = dataModel.timestamp
        WorkPlaceViewModel.containerWidth = containerWidth > 0.1 ? containerWidth : UIScreen.main.bounds.width
        /// 从groups中解析section，组装sectionList
        for group in dataModel.groups {
            let sectionModel = SectionModel(group: group, additionalInfoProxy: self)
            self.sectionsList.append(sectionModel)
        }
        updateDisplaySections() // 更新要展示的cell数据
    }

    /// 根据布局信息，检查是否需要刷新数据
    func refreshDisplayIfNeeded(with containerWidth: CGFloat) -> Bool {
        if WorkPlaceViewModel.containerWidth != containerWidth {
            WorkPlaceViewModel.containerWidth = containerWidth
            updateDisplaySections()
            return true
        } else {
            return false
        }
    }

    /// 在原始列表插入空白cell和间距之后，将数据更新到列表中
    func updateDisplaySections() {
        insertDisplayItemsIfNeeded()
    }
    
    func getFirstFavoriteIconIndexPath() -> IndexPath? {
        let section = sectionsList.firstIndex {
            $0.type == .favorite
        }
        
        guard let favoriteSection = section,
              let sectionModel = getSectionModel(index: favoriteSection) else {
            return nil
        }
        let row = sectionModel.getDisplayItems().firstIndex {
            $0.itemType == .icon
        }
        guard let favoriteIconRow = row else {
            return nil
        }
        return IndexPath(row: favoriteIconRow, section: favoriteSection)
    }

    /// insert space item if need, 插入分割的cell
    private func insertDisplayItemsIfNeeded() {
        Self.logger.info("updateDisplayItems")
        var lastWPItem: WorkPlaceItem?   // 记录上一个Item
        let itemSpaceHeight = getCellBetweens() // 获取不同cell之间的上下间距
        /// 默认间隔
        let defaultSpaceHeight: CGFloat = 24.0
        /// 遍历section
        for (sectionIndex, section) in sectionsList.enumerated() {
            var tempItems: [WorkPlaceItem] = []
            /// 遍历其中的item
            for (index, item) in section.getOriginItemsApplyFoldState().enumerated() {
                if let lastItem = lastWPItem {   // 非整个首个item
                    let lastItemType = lastItem.itemType    // 上一个item的类型
                    let itemType = item.itemType    // 当前item的类型
                    let key = spaceKeyBetween(upItemType: lastItemType, nextItemType: itemType)
                    if index == 0 && sectionIndex > 0 { // 下一个section的开始（非首个section的第一个item）
                        let sectionSpaceHeight = (itemSpaceHeight[key] ?? defaultSpaceHeight) + ItemModel.miniLineSpace
                        let sectionSpaceItem = EmptySpaceItemModel(height: sectionSpaceHeight)
                        /// 将上一个section的尾部插入空白，作为section之间的间距
                        let lastSection = sectionsList[sectionIndex - 1]
                        var lastSectionDisplayItems = lastSection.getDisplayItems()
                        appendEmptyItemsBeforeSpace(tempItems: &lastSectionDisplayItems)    // 补齐尾部填充item，保障icon展示结构正常
                        lastSectionDisplayItems.append(sectionSpaceItem)
                        lastSection.setDisplayItems(
                            items: lastSectionDisplayItems,
                            subtag: lastSection.allAppsData?.currentTag
                        )
                    } else {    // section内部间距填充
                        var isNeedSectionInnerItem: Bool = false
                        /// 相同类型时，widget与widget之间需要填充
                        if lastItemType.isWidgetOrBlock && itemType.isWidgetOrBlock {
                            isNeedSectionInnerItem = true
                        } else if lastItemType != itemType {
                            // 不同类型时，出现需要补齐尾部item的情况时，需要填充
                            if isNeedSectionTrailItem(lastItemType: lastItemType, itemType: itemType) {
                                isNeedSectionInnerItem = true
                                // 补齐尾部填充item，保障icon展示结构正常
                                appendEmptyItemsBeforeSpace(tempItems: &tempItems)
                            }
                        }
                        // 内部间距填充
                        if isNeedSectionInnerItem, let height = itemSpaceHeight[key] {
                            tempItems.append(EmptySpaceItemModel(height: height))
                        }
                    }
                } else {
                    // 首个item
                    // 第一个距离顶部的高度是16（上下两个间距就是ItemModel.miniLineSpace * 2），所以这里是0
                    tempItems.append(EmptySpaceItemModel(height: 0))
                }
                // 填入正常的item
                lastWPItem = item
                tempItems.append(item)
            }
            /// 如果当前section的item个数为0
            if section.getOriginItemsApplyFoldState().isEmpty && sectionIndex > 0 {
                let sectionSpaceItem = EmptySpaceItemModel(height: defaultSpaceHeight)
                /// 将上一个section的尾部插入空白
                let lastSection = sectionsList[sectionIndex - 1]
                var lastSectionDisplayItems = lastSection.getDisplayItems()
                appendEmptyItemsBeforeSpace(tempItems: &lastSectionDisplayItems)
                lastSectionDisplayItems.append(sectionSpaceItem)
                lastSection.setDisplayItems(items: lastSectionDisplayItems, subtag: lastSection.allAppsData?.currentTag)
            }
            /// 更新计算布局后的item列表
            section.setDisplayItems(items: tempItems, subtag: section.allAppsData?.currentTag)
            Self.logger.info("section index \(sectionIndex) items count \(tempItems.count)")
        }
    }

    /// 根据上下item的类型组合，判断section内部是否需要补齐填充item
    private func isNeedSectionTrailItem(lastItemType: ItemType, itemType: ItemType) -> Bool {
        // 1、当前类型和上个item的类型不相同，上一个是icon，下一个是widget
        let needInsertSpace1 = (lastItemType == .icon || lastItemType == .addIcon) && itemType != .addIcon
        /// 2、当前类型和上个item的类型不相同，上一个是widget，下面是icon
        let needInsertSpace2 = lastItemType.isWidgetOrBlock && (itemType == .addIcon || itemType == .icon)
        /// 3、当前类型和上个item的类型不相同，上一个是addrect，下面是widget
        let needInsertSpace3 = lastItemType == .addRect && itemType.isWidgetOrBlock
        /// 4、当前类型和上个item的类型不相同，上一个是widget，下面是addrect
        let needInsertSpace4 = lastItemType.isWidgetOrBlock && itemType == .addRect
        /// 多种条件下合并都需要调整间距
        let needInsertSpace = needInsertSpace1 || needInsertSpace2 || needInsertSpace3 || needInsertSpace4
        return needInsertSpace
    }

    /// 获取不同cell之间的间距
    private func getCellBetweens() -> [String: CGFloat] {
        var itemSpaceHeight: [String: CGFloat] = [:]
        /// widget 和widget之间的间距是16
        /// widget 和icon 之间的间距是32
        // swiftlint:disable line_length
        itemSpaceHeight[spaceKeyBetween(upItemType: .widget, nextItemType: .icon)] = 32.0 - ItemModel.miniLineSpace * 2
        itemSpaceHeight[spaceKeyBetween(upItemType: .widget, nextItemType: .addIcon)] = 32.0 - ItemModel.miniLineSpace * 2
        itemSpaceHeight[spaceKeyBetween(upItemType: .widget, nextItemType: .widget)] = 16.5 - ItemModel.miniLineSpace * 2
        itemSpaceHeight[spaceKeyBetween(upItemType: .widget, nextItemType: .addRect)] = 24.0 - ItemModel.miniLineSpace * 2
        itemSpaceHeight[spaceKeyBetween(upItemType: .icon, nextItemType: .widget)] = 24.0 - ItemModel.miniLineSpace * 2
        itemSpaceHeight[spaceKeyBetween(upItemType: .icon, nextItemType: .icon)] = 20.0 - ItemModel.miniLineSpace * 2
        itemSpaceHeight[spaceKeyBetween(upItemType: .icon, nextItemType: .addRect)] = 24.0 - ItemModel.miniLineSpace * 2
        itemSpaceHeight[spaceKeyBetween(upItemType: .addIcon, nextItemType: .icon)] = 20.0 - ItemModel.miniLineSpace * 2
        itemSpaceHeight[spaceKeyBetween(upItemType: .addRect, nextItemType: .widget)] = 24.0 - ItemModel.miniLineSpace * 2
        itemSpaceHeight[spaceKeyBetween(upItemType: .addRect, nextItemType: .icon)] = 24.0 - ItemModel.miniLineSpace * 2
        itemSpaceHeight[spaceKeyBetween(upItemType: .addIcon, nextItemType: .widget)] = 24.0 - ItemModel.miniLineSpace * 2
        // swiftlint:enable line_length
        return itemSpaceHeight
    }

    private func spaceKeyBetween(upItemType: ItemType, nextItemType: ItemType) -> String {
        return "\(upItemType.spaceKey)_\(nextItemType.spaceKey)"
    }
    /// 插入填充item，避免最后一行因为item个数不够导致布局错乱🤪
    private func appendEmptyItemsBeforeSpace(tempItems: inout [WorkPlaceItem]) {
        /// 最后一个必须是icon类型
        guard let lastItem = tempItems.last, (lastItem.itemType == .icon || lastItem.itemType == .addIcon) else {
            return
        }
        var startIndex: Int = tempItems.count - 1
        for (index, item) in tempItems.enumerated().reversed() {
            if item.itemType == .icon || item.itemType == .addIcon {
                startIndex = index
                continue
            }
            break
        }
        /// tempItems.count - 1 , the last index
        /// startIndex， first icon app index
        /// (tempItems.count - 1) - startIndex + 1), sum(app of icon type)
        // 需要填充的那一行的cell数量
        guard WorkPlaceViewModel.appsCountPerRow > 0 else {
            Self.logger.warn("""
                    current container width couldn't support the full display of a single icon,
                    container width: \(WorkPlaceViewModel.containerWidth)
            """)
            return
        }
        let needEmptyCells = ((tempItems.count - 1) - startIndex + 1) % WorkPlaceViewModel.appsCountPerRow
        Self.logger.debug("current view last line has \(needEmptyCells) items")
        if needEmptyCells > 0 {
            let repeatValue = EmptyFillSpaceItemModel(itemType: .fillItem)
            let emptyCells = [EmptyFillSpaceItemModel](
                repeating: repeatValue,
                count: WorkPlaceViewModel.appsCountPerRow - needEmptyCells
            )
            tempItems.append(contentsOf: emptyCells)
        }
    }
    /// 选中一个带有子分组section的sub tag
    func didSelect(sectionTag: Tag, subTag: SubTag) {
        Self.logger.info("didSelect sectionTag \(sectionTag.name) subTag \(subTag.tagName)")
        var reloadSections: [Int] = []
        for (i, section) in self.sectionsList.enumerated() where sectionTag.id == section.tag.id {
            /// 找到对应的section
            reloadSections.append(i)
            self.sectionsList[i].allAppsData?.selectSubTag(tag: subTag, dataComplete: { [weak self] in
                self?.notifySectionUpdate(sections: reloadSections)
            })
            requestTagItems(sectionTag: sectionTag, tag: subTag)
            break
        }
    }
    /// 添加一个常用应用
    /// - Parameters:
    ///   - sourcePath: 原来这个应用的indexPath
    ///   - appId:
    func addCommon(sourcePath: IndexPath, itemId: String) {
        Self.logger.info("addCommon sourcePath \(sourcePath) itemId \(itemId)")
        guard sourcePath.section >= 0 && sourcePath.section < sectionsList.count else {
            Self.logger.error("addCommon out of index \(sourcePath) \(itemId)")
            return
        }
        /// 找到需要添加的item
        let sourcesection = sectionsList[sourcePath.section]
        var resultItem: ItemModel?
        for item in sourcesection.getOriginItems() where item.getItemId() == itemId {
            resultItem = item as? ItemModel
            break
        }
        resultItem?.isAddCommonLocal = true
        resultItem?.dataItem.subType = .common
        guard let localItem = resultItem else {
            Self.logger.error("addCommon can't find item \(sourcePath) \(itemId)")
            return
        }
        /// 将新增加的item放在添加icon之前
        var widgetInsertPos: Int = Int.min
        /// 如果添加的item已经在main tag中先将它移除出去
        let filterTagItems = mainTagItems()?.filter({ (item) -> Bool in
            return item.getItemId() != localItem.itemID
        })
        if let items = filterTagItems, !items.isEmpty {
            Self.logger.info("addCommon last item \(localItem.dataItem.item.name)")
            /// 检查是否存在widget
            var resultItems: [WorkPlaceItem] = []
            for (i, item) in items.enumerated() {
                if item.itemType.isWidgetOrBlock || (item.itemType == .addIcon || item.itemType == .addRect) {
                    widgetInsertPos = i
                }
                /// 只有非widget的才插入，如果是widget，那么计算需要插入widget的位置
                if (item.itemType == .addIcon || item.itemType == .addRect) && !localItem._itemType.isWidgetOrBlock {
                    resultItems.append(localItem)
                    resultItems.append(ItemModel.makeAddItem(isRect: false))
                    continue
                }
                resultItems.append(item)
            }
            if localItem._itemType.isWidgetOrBlock {
                /// 如果找不到
                if widgetInsertPos == Int.min {
                    /// 如果没有widget
                    resultItems.append(localItem)
                } else if (widgetInsertPos + 1) <= resultItems.count {
                    resultItems.insert(localItem, at: widgetInsertPos + 1)
                }
            }
            /// 更新常用应用
            updateMainTagItems(items: resultItems)
        }
    }
    /// 移除一个常用应用
    /// - Parameters:
    ///   - indexPath: 要移除的常用应用的indexPath
    ///   - appId:
    func removeCommon(indexPath: IndexPath, itemId: String) {
        Self.logger.info("removeCommon \(indexPath) itemId \(itemId)")
        if let items = mainTagItems()?.filter({ (item) -> Bool in
            return itemId != item.getItemId()
        }) {
            updateMainTagItems(items: items)
        }
    }
    /// 得到主tag的items
    private func mainTagItems() -> [WorkPlaceItem]? {
        Self.logger.info("mainTagItems get")
        for section in sectionsList where section.type == .favorite {
            Self.logger.info("mainTagItems get exist")
            return section.getOriginItems()
        }
        return nil
    }
    /// 更新主tag的items
    private func updateMainTagItems(items: [WorkPlaceItem]) {
        Self.logger.info("updateMainTagItems \(items.count)")
        for (i, section) in sectionsList.enumerated() where (section.type == .favorite) {
            section.setOriginItems(items: items, subtag: section.allAppsData?.currentTag)
            insertDisplayItemsIfNeeded()
            notifySectionUpdate(sections: [i])
            Self.logger.info("updateMainTagItems \(items.count) end")
            break
         }
    }
    /// 判断一个应用是否是常用应用
    /// - Parameters:
    ///   - itemId:
    func isCommonItem(itemId: String) -> Bool {
        for item in (mainTagItems() ?? []) where itemId == item.getItemId() {
            return item.isAddCommonLocal || item.isCommon()
        }
        return false
    }

    /// 获取全部应用某个分类下面的应用
    private func requestTagItems(sectionTag: Tag, tag: SubTag) {
        dataManager.requestItemsWithSubTag(
            subtagID: tag.tagId,
            success: {[weak self] (iteminfo) in
                var result: [ItemUnit] = []
                for itemTag in iteminfo.children ?? [] {
                    if let item = iteminfo.allItemInfos?[itemTag.itemId] {
                        let unit = ItemUnit(
                            type: itemTag.type,
                            subType: itemTag.subType,
                            itemID: item.itemId,
                            item: item
                        )
                        result.append(unit)
                    }
                }
                self?.handleTagItems(
                    sectionTag: sectionTag,
                    tag: tag,
                    hasMore: iteminfo.hasMore,
                    result: result,
                    error: nil
                )
            },
            failure: { [weak self]  (error) in
                Self.logger.error("select subtag then request itemlist error:", error: error)
                self?.handleTagItems(
                    sectionTag: sectionTag,
                    tag: tag,
                    hasMore: nil,
                    result: [],
                    error: error
                )
            }
        )
    }
    private func handleTagItems(
        sectionTag: Tag,
        tag: SubTag,
        hasMore: Bool?,
        result: [ItemUnit],
        error: Error?
    ) {
        /// 将item列表转换为item model
        let itemModels = result.map { (unit) -> ItemModel in
            return ItemModel(dataItem: unit, isAddRect: false)
        }
        for (i, section) in sectionsList.enumerated() where sectionTag.id == section.tag.id {
            /// 更新原始数据
            if error == nil {
                section.setOriginItems(items: itemModels, subtag: tag)
            } else {
                /// 如果拉去数据存在错误，那么看当前的state，如果是loading，那么设置成失败
                if let subsection = section.allAppsData?.sectionData[tag.tagId], subsection.state == .loading {
                    section.allAppsData?.updateSubSection(forTag: tag, state: .fail)
                }
            }
            /// 给子tag打上是否有更多的标记
            section.allAppsData?.updateSubHasMore(forTag: tag, hasMore: hasMore)
            /// 刷新UI数据
            updateDisplaySections()
            /// 通知界面刷新
            notifySectionUpdate(sections: [i])
            break
        }
    }
    /// 这里必须异步重新刷新，否则会触发在读过程中同时写数据的异常
    @objc
    private func notifySectionUpdate(sections: [Int]) {
        Self.logger.info("notifySectionUpdate \(sections.count)")
        DispatchQueue.main.async {
            self.dataUpdateCallback?(sections)
        }
    }
    /// 从旧的数据model同步数据
    func syncDataFrom(oldModel: WorkPlaceViewModel?) {
        Self.logger.info("syncDataFrom")
        guard let model = oldModel else {
            return
        }
        for section in model.sectionsList {
            /// 找到当前的对应的section
            for newsection in sectionsList where newsection.tag.id == section.tag.id {
                newsection.syncDataFrom(oldSection: section)
            }
        }
        updateDisplaySections()
        /// 拷贝addition info
        itemAdditionalMap = oldModel?.itemAdditionalMap ?? itemAdditionalMap
    }
    ///
    func foldStateToggle(sectionIndex: Int) {
        Self.logger.info("foldStateToggle \(sectionIndex)")
        if sectionIndex < sectionsList.count {
            let section = sectionsList[sectionIndex]
            section.stateSwitch()
            updateDisplaySections()
            notifySectionUpdate(sections: [sectionIndex])
        }
    }
}
/// 实现workplace item additional info 查询协议
extension WorkPlaceViewModel: WorkPlaceQueryAdditionContext {
    func queryAdditionItem(itemId: String) -> ItemModelAdditionInfo? {
        return itemAdditionalMap[itemId]
    }
    func updateAdditionItem(itemId: String, item: ItemModelAdditionInfo?) {
        if item == nil {
            itemAdditionalMap.removeValue(forKey: itemId)
        } else {
            itemAdditionalMap[itemId] = item
        }
    }
}
