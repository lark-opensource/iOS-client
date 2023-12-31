//
//  NativeCardViewModel.swift
//  SKBitable
//
//  Created by zoujie on 2023/10/31.
//  


import SKFoundation
import SKCommon
import RxDataSources

fileprivate enum UpdateModelAction: String {
    case update
    case updateVisible
    case reload
}

fileprivate struct UpdateModelData {
    var action: UpdateModelAction = .reload
    var updateIndexs: [Int] = []
    var insertIndexs: [Int] = []
    var deleteIndexs: [Int] = []
}

protocol NativeCardViewModelListener: AnyObject {
    /// diff批量更新
    func diffUpdateModel(viewId: String, deleteIndexs: [Int], insertIndexs: [Int])
    ///  更新指定item
    func updateItems(viewId: String, indexs: [Int], needInvalidateLayout: Bool)
    /// 滚动到指定item
    func scrollToIndex(viewId: String, index: Int)
    /// 批量更新item
    func batchUpdate(viewId: String,
                     updateIndexs: [Int],
                     deleteIndexs: [Int],
                     insertIndexs: [Int],
                     completion: (() -> Void)?)
    /// 更新可视区的item
    func updateVisibleItems(viewId: String)
    /// 全量更新item
    func reloadItems(viewId: String, completion: (() -> Void)?)
    /// 更新吸顶header model
    func updateGroupHeaderModel(viewId: String)
}

final class NativeCardViewModel {
    struct Const {
        static let defaultFetchPageSize: Int = 100
        static let defaultFetchPreIndex: Int = 20
    }
    private let TAG = "[NativeCardViewModel]"
    private var model: CardPageModel // 前端传过来的数据
    private var collapsedGroupHeaderId: Set<String> = []  // 折叠起来的groupID
    
    private(set) var cachedRecordItems: [String: CardRecordModel] = [:] // 缓存的记录渲染数据
    private(set) var cachedGroupHeaderItems: [String: GroupModel] = [:] // 缓存的分组头渲染数据
    // 分页请求长度
    private var pageSize: Int {
        self.model.updateStrategy?.pageSize ?? Const.defaultFetchPageSize
    }
    // 预加载
    private var preIndex: Int {
        self.model.updateStrategy?.pageSize ?? Const.defaultFetchPreIndex
    }
    private var cachedFirstItemId: String?
    private var cachedLastItemId: String?
    
    private var dirtyRecordIds: [String] = [] // 记录标脏
    private var currentVisibleItemIndex: Int = 0
    
    weak var listener: NativeCardViewModelListener?
    private weak var service: BTContainerService?
    
    let fpsTrace = BTNativeRenderFPSTrace()
    
    // 视图渲染结构数据
    var uiModel: [RenderItem] = []
    
    var isInSearchMode = false
    
    private var isDark = false
    // 滚动过程中不触发数据更新
    private var isScrolling = false
    private var pendingUpdateData: UpdateModelData?
    
    var cardSetting: CardSettingModel? {
        model.setting
    }
    
    var hasCover: Bool {
        cardSetting?.showCover ?? false
    }
    
    /// 是否有分组
    var hasGroup: Bool {
        uiModel.first(where: { $0.type == .groupHeader }) != nil
    }
    
    // 列
    var columnCount: Int {
        cardSetting?.columnCount ?? 1
    }
    
    // 字段数
    var fieldCount: Int {
        cardSetting?.fieldCount ?? 0
    }
    
    // 副标题
    var hasSubTitle: Bool {
        cardSetting?.showSubTitle ?? false
    }
    
    var groupItem: [RenderItem] {
        uiModel.filter({ $0.type == .groupHeader })
    }
    
    var footerText: String? {
        model.footer?.text
    }
    
    init(model: CardPageModel, service: BTContainerService?) {
        self.model = model
        self.service = service
        self.isDark = UIColor.docs.isCurrentDarkMode
        self.uiModel = getViewRenderItems(model.renderForest?.renderTrees ?? [])
        // 首屏渲染数据
        self.cachedRecordItems = model.recordDataMap
        self.cachedGroupHeaderItems = model.groupDataMap
        updateBoundaryCachedItemId()
    }
    
    func updateModel(model: CardPageModel) {
        guard self.model != model else {
            self.model.callback = model.callback
            return
        }
        
        let strategy = model.updateStrategy?.strategy ?? .rebuild
        DocsLogger.btInfo("\(TAG) recive FE strategy:\(strategy)")
        switch strategy {
        case .rebuild:
            handleDataRebuild(model: model)
        case .pull, .push:
            handlePullOrPushData(model: model)
        case .scroll:
            handleScroll(model: model)
        }
    }
    
    /// 是否标脏数据，同时请求数据
    private func shouldMarkDirtyAndFetchItemsData() -> Bool {
        if cachedRecordItems.isEmpty {
            // 缓存数据为空
            return true
        }
        
        if hasGroup, cachedGroupHeaderItems.isEmpty {
            // 有分组头的情况下，缓存的数据为空
            return true
        }
        
        if dirtyRecordIds != Array(cachedRecordItems.keys) {
            // 有新的数据要标脏
            return true
        }
        
        return false
    }
    
    /// 处理前端rebuild触发的数据更新
    private func handleDataRebuild(model: CardPageModel) {
        guard model.renderForest != nil else {
            // 数据错误，不处理
            return
        }
        var needUpdateUIModel = model.renderForest != self.model.renderForest
        let cardSettingHasChange = model.setting != self.model.setting
        let darkModeHasChange = isDark != UIColor.docs.isCurrentDarkMode
        
        if isInSearchMode {
            // 搜索状态下折叠的分组都要展开
            if !collapsedGroupHeaderId.isEmpty {
                collapsedGroupHeaderId.removeAll()
                needUpdateUIModel = true
            }
        }
        
        self.model = model
        let cacheDataHasChange = updateCacheData()
        if needUpdateUIModel {
            // 列表数据的结构发生变化，触发view刷新
            // 数据变更时才触发
            let oldUIModel = uiModel
            uiModel = getViewRenderItems(model.renderForest?.renderTrees ?? [])
            updateBoundaryCachedItemId()
            changeDiffUpdate(old: oldUIModel, new: uiModel)
            DocsLogger.btInfo("\(TAG) handleDataRebuild needUpdateUIModel")
        } else if cacheDataHasChange || cardSettingHasChange || darkModeHasChange {
            // 缓存、视图配置、暗黑模式发生变化，更新可视区的cell
            isDark = UIColor.docs.isCurrentDarkMode
            updateVisibleItems()
            listener?.updateGroupHeaderModel(viewId: model.viewId)
            DocsLogger.btInfo("\(TAG) handleDataRebuild updateVisibleItems")
        }
        
        if shouldMarkDirtyAndFetchItemsData() {
            // 脏区有变化或缓存数据为空时才触发数据拉取
            // 缓存数据标脏
            dirtyRecordIds = Array(cachedRecordItems.keys)
            fetchItemsDataIfNeed(items: getCachePageLengthPreloadItemsFrom(currentVisibleItemIndex))
            DocsLogger.btInfo("\(TAG) handleDataRebuild shouldMarkDirtyAndFetchItemsData")
        }
    }
    
    /// 处理native主动获取数据
    private func handlePullOrPushData(model: CardPageModel) {
        self.model.callback = model.callback
        // header的数据在rebuild时就全量下发了，主动pull或前端push均不会带groupHeader数据
        self.model.recordDataMap = model.recordDataMap
        updateDirty()
        let cacheDataHasChange = updateCacheData()
        updateBoundaryCachedItemId()
        if cacheDataHasChange {
            // 触发view刷新
           updateVisibleItems()
        }
    }
    
    /// 处理前端控制滚动
    private func handleScroll(model: CardPageModel) {
        self.model.callback = model.callback
        self.model.recordDataMap = model.recordDataMap
        guard let id = model.updateStrategy?.scrollToId else {
            return
        }
        
        guard let index = uiModel.firstIndex(where: { $0.id == id }) else {
            DocsLogger.btInfo("\(TAG) handleScroll failed")
            return
        }
        
        updateDirty()
        updateCacheData()
        updateBoundaryCachedItemId()
        
        let indexs = model.recordDataMap.compactMap { (key, _) in
            uiModel.firstIndex(where: { $0.id == key })
        }
        
        DocsLogger.btInfo("\(TAG) handleScroll indexs:\(indexs)")
        updateItems(indexs: indexs)
        listener?.scrollToIndex(viewId: model.viewId, index: index)
    }
    
    private func diffInsertAndDelete(old: [RenderItem], new: [RenderItem]) -> ([Int]?, [Int]?) {
        do {
            let oldData = RenderItemContainer(identifier: "nativeCardView", items: old)
            let newData = RenderItemContainer(identifier: "nativeCardView", items: new)
            let differences = try Diff.differencesForSectionedView(initialSections: [oldData], finalSections: [newData])
            
            var inserts: [Int] = []
            var deletes: [Int] = []
            for different in differences {
                let insert = different.insertedItems.map(\.itemIndex)
                let delete = different.deletedItems.map(\.itemIndex)
                inserts.append(contentsOf: insert)
                deletes.append(contentsOf: delete)
            }

            return (inserts, deletes)
        } catch {
            DocsLogger.btInfo("\(TAG) changeDiffUpdate failed")
            return (nil, nil)
        }
    }
    
    /// 精细化更新
    private func changeDiffUpdate(old: [RenderItem], new: [RenderItem]) {
        let (inserts, deletes) = diffInsertAndDelete(old: old, new: new)
        if let insertIds = inserts,
            let deleteIds = deletes {
            listener?.diffUpdateModel(viewId: model.viewId, 
                                      deleteIndexs: deleteIds,
                                      insertIndexs: insertIds)
        } else {
            reloadItems()
        }
    }
    
    /// 设置缓存数据上下边界的itemID
    private func updateBoundaryCachedItemId() {
        cachedFirstItemId = uiModel.first(where: { hasCached($0) && !cacheDataIsDirty($0) })?.id
        cachedLastItemId = cachedFirstItemId
        for item in uiModel {
            if hasCached(item), !cacheDataIsDirty(item) {
                cachedLastItemId = item.id
            } else {
                return
            }
        }
    }
    
    private func updateDirty() {
        // 清除脏区
        dirtyRecordIds.removeAll(where: { model.recordDataMap.keys.contains($0) })
    }
    
    /// 记录是否被标脏
    private func cacheDataIsDirty(_ item: RenderItem) -> Bool {
        if item.type == .record {
            return dirtyRecordIds.contains(item.id)
        }
        
        return false
    }
    
    /// 数据是否有缓存
    private func hasCached(_ item: RenderItem) -> Bool {
        if item.type == .record {
            return cachedRecordItems[item.id] != nil
        } else if item.type == .groupHeader {
            return cachedGroupHeaderItems[item.id] != nil
        }
        
        return false
    }
    
    /// 处理分组头折叠和展开
    /// - Parameters:
    ///   - id: 分组头ID
    func handleGroupHeaderClick(id: String) {
        guard let index = uiModel.firstIndex(where: { $0.id == id }) else {
            return
        }
        
        let collapsed = !collapsedGroupHeaderId.contains(id)
        if collapsed {
            // 折叠
            collapsedGroupHeaderId.insert(id)
        } else {
            // 展开
            collapsedGroupHeaderId.remove(id)
        }
        
        if let cachedHeader = cachedGroupHeaderItems[id] {
            var newCachedHeader = cachedHeader
            newCachedHeader.isCollapsed = collapsed
            cachedGroupHeaderItems.updateValue(newCachedHeader, forKey: id)
        }
        
        groupStateChanged(index: index, collapsed: collapsed)
        DocsLogger.btInfo("\(TAG) handleGroupHeaderClick id:\(id) collapsed:\(collapsed)")
        
        if collapsed {
            // 点击收起，需要加载下面的记录
            preloadItems(itemIndex: index, direction: 1)
        }
    }
    
    ///  分组头折叠展开更新ui
    /// - Parameters:
    ///   - index: 点击的分组头index
    ///   - collapsed: 点击后分组头的状态 true: 折叠，false: 展开
    /// - Returns: 更新是否成功
    private func groupStateChanged(index: Int, collapsed: Bool) {
        let oldUIModel = uiModel
        uiModel = getViewRenderItems(model.renderForest?.renderTrees ?? [])
        
        let (inserts, deletes) = diffInsertAndDelete(old: oldUIModel, new: uiModel)
        if let insertIds = inserts,
           let deleteIds = deletes {
            DocsLogger.btInfo("\(TAG) groupStateChanged insertIds:\(insertIds) deleteIds:\(deleteIds) updateIndexs:\(index)")
            listener?.batchUpdate(viewId: model.viewId,
                                  updateIndexs: [index],
                                  deleteIndexs: deleteIds,
                                  insertIndexs: insertIds) { [weak self] in
                guard let self = self else { return }
                if let nextGroupHeaderIndex = self.getNextGroupItemIndex(index) {
                    // 当前groupHeader的下一个groupHeader也需要更新
                    self.updateItems(indexs: [nextGroupHeaderIndex])
                }
            }
        } else {
            reloadItems()
        }
    }
    
    /// 更新缓存数据，返回是否有更新
    @discardableResult
    private func updateCacheData() -> Bool {
        let oldCachedRecordItems = cachedRecordItems
        let oldCachedGroupHeaderItems = cachedGroupHeaderItems
        
        cachedRecordItems.merge(model.recordDataMap) { $1 }
        cachedGroupHeaderItems.merge(model.groupDataMap) { (old, new) in
            var newModel = new
            newModel.isCollapsed = !isInSearchMode && old.isCollapsed
            return newModel
        }
        
        return oldCachedRecordItems != cachedRecordItems ||
               oldCachedGroupHeaderItems != cachedGroupHeaderItems
    }
    
    
    /// 获取当前groupHeader下一个groupHeader的index
    /// - Parameter currentIndex: 当前groupHeader的index
    /// - Returns: 下一个groupHeader的index
    private func getNextGroupItemIndex(_ currentIndex: Int) -> Int? {
        guard currentIndex >= 0, currentIndex < uiModel.count - 1 else {
            return nil
        }
        
        for index in (currentIndex + 1)...(uiModel.count - 1) {
            if uiModel[index].type == .groupHeader {
                return index
            }
        }
        
        return nil
    }
    
    /// 将树状结构拍平为一维数组
    /// - Parameter trees: 树状结构
    /// - Returns: 拍平后的一维结构
    func getViewRenderItems(_ trees: [RenderTree]) -> [RenderItem] {
        var items: [RenderItem] = []
        
        trees.forEach({ tree in
            items.append(contentsOf: getViewRenderItem(tree))
        })
        
        return items
    }
    
    func getViewRenderItem(_ tree: RenderTree) -> [RenderItem] {
        var items: [RenderItem] = []
        items.append(contentsOf: tree.current)
        
        if tree.type == .groupTree && !collapsedGroupHeaderId.contains(tree.current.first?.id ?? "") {
            // 分组展开
            tree.children.forEach { child in
                items.append(contentsOf: getViewRenderItem(child))
            }
        }
        return items
    }
    
    /// 获取渲染数据
    /// - Parameter items: 需要获取渲染数据的item，无缓存或被标脏则会触发请求
    func fetchItemsDataIfNeed(items: [RenderItem]) {
        var needFetchItems: [RenderItem] = []
        
        items.forEach { item in
            if !hasCached(item) {
                // 没有缓存，请求数据
                needFetchItems.append(item)
            } else if cacheDataIsDirty(item) {
                // 记录被标脏
                needFetchItems.append(item)
            }
        }
        
        guard !needFetchItems.isEmpty else {
            return
        }
        fetchItems(items: needFetchItems)
    }
     
    /// 获取记录渲染数据
    /// - Parameter index: 下标
    /// - Returns: 记录数据，如果为空需要显示骨架图
    func getCardItemData(index: Int) -> CardRecordModel? {
        guard index < uiModel.count, index >= 0 else {
            return nil
        }
        
        let item = uiModel[index]
        guard item.type == .record else {
            return nil
        }
        
        return cachedRecordItems[item.id]
    }
    
    /// 获取分组头渲染数据
    /// - Parameter index: 下标
    /// - Returns: 分组头数据，如果为空需要显示骨架图
    func getGroupHeaderData(index: Int) -> GroupModel? {
        guard index < uiModel.count, index >= 0 else {
            return nil
        }
        
        let item = uiModel[index]
        guard item.type == .groupHeader else {
            return nil
        }
        
        return cachedGroupHeaderItems[item.id]
    }
    
    // 请求数据
    func fetchItems(items: [RenderItem]) {
        // 区分分组头和记录
        // 请求完的数据放到对应的缓存中，且需要从标脏数组中移除
        let itemsJSON = items.compactMap { item in
            return item.toJsonOrNil()
        }
        
        let params: [String: Any] = ["action": "PullCardData",
                                     "list": itemsJSON]
        
        DocsLogger.btInfo("\(TAG) fetchItems data count: \(items.count)")
        handleJSCallBack(params: params)
    }
    
    /// 从指定index开始，向上和向下获取缓存分页长度的item
    /// - Parameter index: 指定index
    /// - Returns: 向上和向下获取缓存分页长度的item
    func getCachePageLengthPreloadItemsFrom(_ index: Int) -> [RenderItem] {
        let startIndex = max(index - pageSize, 0)
        let endIndex = min(index + pageSize, uiModel.count - 1)
        return Array(uiModel[startIndex...endIndex])
    }
    
    /// 数据预拉取处理
    /// - Parameters:
    ///   - itemIndex: 视口区边界itemIndex
    ///   - direction: 滑动方向 1: 向上滑动 0:  向下滑动
    func preloadItems(itemIndex: Int, direction: CGFloat) {
        // 预加载数据
        currentVisibleItemIndex = itemIndex
        var preloadItems: [RenderItem] = []
        if direction > 0 {
            // 向上滑动
            let index = uiModel.firstIndex(where: { $0.id == cachedLastItemId }) ?? itemIndex
            if index - itemIndex < preIndex, index >= itemIndex {
                // 触发预拉取
                let preloadIndex = min(uiModel.count - 1, index + pageSize)
                guard index > 0, index < uiModel.count, index < preloadIndex else {
                    return
                }
                preloadItems = Array(uiModel[index...preloadIndex])
            } else {
                // 超出缓存边界值，拉取当前可见前后100条数据
                preloadItems = getCachePageLengthPreloadItemsFrom(itemIndex)
            }
        } else {
            // 向下滑动
            let index = uiModel.firstIndex(where: { $0.id == cachedFirstItemId }) ?? itemIndex
            if itemIndex - index < preIndex, itemIndex >= index {
                // 触发预拉取
                let preloadIndex = max(0, index - pageSize)
                guard index > 0, index < uiModel.count, index > preloadIndex else {
                    return
                }
                preloadItems = Array(uiModel[preloadIndex...index])
            } else {
                // 超出缓存边界值，拉取当前可见前后100条数据
                preloadItems = getCachePageLengthPreloadItemsFrom(itemIndex)
            }
        }
        fetchItemsDataIfNeed(items: preloadItems)
    }
    
    /// 上一个item的类型
    /// - Parameter item: 当前item
    /// - Returns: 上一个item的类型
    func preItemType(_ item: RenderItem) -> RenderItemType? {
        guard let index = uiModel.firstIndex(of: item) else {
            return nil
        }
        
        if index == 0 {
            return nil
        }
        
        let preIndex = index - 1
        return uiModel[preIndex].type
    }
    
    /// 是否是当前分组下的第一条记录
    /// - Parameter item: 记录item
    /// - Returns: 是/否
    func isGroupFirstRecord(_ item: RenderItem) -> Bool {
        return preItemType(item) == .groupHeader
    }
    
    /// 是否是当前分组下的最后一条记录
    /// - Parameter item: 记录item
    /// - Returns: 是/否
    func isGroupLastRecord(_ item: RenderItem) -> Bool {
        guard let index = uiModel.firstIndex(of: item) else {
            return false
        }
        
        if index == uiModel.count - 1 {
            return true
        }
        
        let nextIndex = index + 1
        return uiModel[nextIndex].type == .groupHeader
    }
    
    /// 当前分组头上一个元素是否也是分组头
    /// - Parameter item: 分组头item
    /// - Returns: 是/否
    func preItemIsGroupHeader(_ item: RenderItem) -> Bool {
        return preItemType(item) == .groupHeader
    }
    
    /// 返回区间内最后一个固定分组头的id
    /// - Parameters:
    ///   - from: 区间头
    ///   - to: 区间尾
    /// - Returns: 最后一个固定分组头的id
    func getLastFixedGroupId(from: Int, to: Int) -> String? {
        guard from >= 0,
              from < uiModel.count,
              to >= 0,
              to < uiModel.count,
              from <= to else {
            return nil
        }
        
        let trimModel = uiModel[from...to]
        let lastFixedGroupModel = trimModel.last(where: {
            $0.type == .groupHeader && (cachedGroupHeaderItems[$0.id]?.lastLevelGroup ?? false)
        })
        
        return lastFixedGroupModel?.id
    }
    
    func handleJSCallBack(params: [String: Any]?, completion: ((_ info: Any?, _ error: Error?) -> Void)? = nil) {
        service?.callFunction(DocsJSCallBack(model.callback), params: params, completion: completion)
    }
    
    func fetchVisibleItemDataIfNeed(index: Int?) {
        guard let index = index else { return }
        fetchItemsDataIfNeed(items: getCachePageLengthPreloadItemsFrom(index))
    }
    
    func didScroll(_ scrollView: UIScrollView) {
        isScrolling = !(!scrollView.isTracking && !scrollView.isDragging && !scrollView.isDecelerating)
        service?.gesturePlugin?.scrolledToTop(scrollView.btScrolledToTop)
    }
    
    func didEndScroll() {
        isScrolling = false
        handlePendingUpdateData()
    }
    
    private func handlePendingUpdateData() {
        guard let pendingModel = pendingUpdateData else { return }
        DocsLogger.btInfo("\(TAG) handlePendingUpdateData action:\(pendingModel.action)")
        // 滚动停止，有pending的更新
        switch pendingModel.action {
        case .update:
            updateItems(indexs: pendingModel.updateIndexs)
        case .updateVisible:
            updateVisibleItems()
        case .reload:
            reloadItems()
        }
        
        pendingUpdateData = nil
    }
    
    ///  更新指定item
    private func updateItems(indexs: [Int]) {
        guard !isScrolling else {
            pendingUpdateData = UpdateModelData(action: .update,
                                                updateIndexs: indexs)
            DocsLogger.btInfo("\(TAG) updateItems isScrolling")
            return
        }
        
        listener?.updateItems(viewId: model.viewId, indexs: indexs, needInvalidateLayout: true)
    }
    
    /// 更新可视区的item
    private func updateVisibleItems() {
        guard !isScrolling else {
            pendingUpdateData = UpdateModelData(action: .updateVisible)
            DocsLogger.btInfo("\(TAG) updateVisibleItems isScrolling")
            return
        }
        
        listener?.updateVisibleItems(viewId: model.viewId)
    }
    
    /// 全量更新item
    private func reloadItems() {
        guard !isScrolling else {
            pendingUpdateData = UpdateModelData(action: .reload)
            DocsLogger.btInfo("\(TAG) reloadItems isScrolling")
            return
        }
        
        listener?.reloadItems(viewId: model.viewId, completion: nil)
    }
}
