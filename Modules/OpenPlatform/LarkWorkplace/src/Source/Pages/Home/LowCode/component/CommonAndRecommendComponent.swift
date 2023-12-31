//
//  CommonAndRecommendComponent.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2021/4/13.
//

import Foundation
import SwiftyJSON
import ECOProbe
import LarkWorkplaceModel
import LarkSetting
import LarkContainer
import LarkAccountInterface
import LKCommonsLogging

/// 常用和推荐 组件
final class CommonAndRecommendComponent: GroupComponent {
    static let logger = Logger.log(CommonAndRecommendComponent.self)

    private var enableRecentlyUsedApp: Bool {
        return configService?.fgValue(for: .enableRecentlyUsedApp) ?? false
    }

    let groupType: GroupComponentType = .CommonAndRecommend

    var componentState: ComponentState = .loading
    var lastComponentState: ComponentState?

    private(set) var componentID: String = ""
    private(set) var layoutParams: BaseComponentLayout?
    private(set) var extraComponents: [NodeComponentType: NodeComponent] = [:]
    var nodeComponents: [NodeComponent] { nodeComponentsMap[displaySubModule] ?? [] }

    private var isExposed: Bool = false
    private(set) var displaySubModule: FavoriteSubModule = .favorite
    private(set) var userSelectedSubModule: FavoriteSubModule?
    private(set) var subModuleList: [FavoriteSubModule] = [.favorite]
    private(set) var nodeComponentsMap: [FavoriteSubModule:[NodeComponent]] = [.favorite: []]

    // 原来的设计层级太深，后续需要重构，此处直接传递 userResolver
    private let userResolver: UserResolver?

    private var configService: WPConfigService? {
        return try? userResolver?.resolve(assert: WPConfigService.self)
    }

    private var userService: PassportUserService? {
        return try? userResolver?.resolve(assert: PassportUserService.self)
    }

    init(userResolver: UserResolver?) {
        self.userResolver = userResolver
    }

    func parse(json: JSON) -> GroupComponent {
        componentID = json[ComponentIdKey].string ?? ""   // ⚠️返回数据中没有ID，则数据异常
        // Component layout
        layoutParams = BaseComponentLayout(json: json[StylesKey])
        // Component configuration（title、background）
        let titleComponent = ParseGroupHelper.commonHeaderTitle(json: json)
        extraComponents[.GroupTitle] = titleComponent
        extraComponents[.GroupBackground] = ParseGroupHelper.background(json: json)
        return self
    }

    func updateModuleData(_ json: JSON, isPortalPreview: Bool = false) -> Bool {
        guard let module: FavoriteModule = decode(from: json) else { return false }

        // data model -> view model, default: show .favorite sub module
        if let subModule = module.config?.subModules, !subModule.isEmpty, enableRecentlyUsedApp {
            subModuleList = subModule
        }
        nodeComponentsMap[.favorite] = generateFavoriteNodes(
            items: module.favoriteItems,
            itemInfos: module.favoriteItemInfos,
            isPortalPreview: isPortalPreview
        )
        nodeComponentsMap[.recentlyUsed] = generateRecentNodes(
            items: module.recentItems,
            itemInfos: module.recentItemInfos
        )

        // user selected > the first non-empty sub-module > display the first sub-module.
        var displayIndex = 0
        if let userSelectedSubModule = userSelectedSubModule,
           let userSelectedIndex = subModuleList.firstIndex(of: userSelectedSubModule) {
            displayIndex = userSelectedIndex
            updateDisplayModule(index: displayIndex, isUserSelected: true)
        } else {
            displayIndex = subModuleList.firstIndex(where: { !(nodeComponentsMap[$0]?.isEmpty ?? true) }) ?? 0
            updateDisplayModule(index: displayIndex)
        }

        // Add "add favorite" button if there is are no app under .favorite tab
        if nodeComponentsMap[.favorite]?.isEmpty == true {
            nodeComponentsMap[.favorite]?.append(createAddRectNode())
        }

        // title configuration
        // priority: module >> schema
        let subTitle = getSubTitle(config: module.config)
        if !subTitle.isEmpty, enableRecentlyUsedApp {
            let titleComponent = GroupTitleComponent(title: subTitle[0], subTitle: subTitle)
            titleComponent.selectedSubTitleIndex = displayIndex
            extraComponents[.GroupTitle] = titleComponent
        }

        return true
    }

    func updateDisplayModule(index: Int, isUserSelected: Bool = false) {
        guard index < subModuleList.count else {
            userSelectedSubModule = nil
            return
        }
        displaySubModule = subModuleList[index]
        userSelectedSubModule = isUserSelected ? subModuleList[index] : nil
        if let titleComponent = extraComponents[.GroupTitle] as? GroupTitleComponent {
            titleComponent.selectedSubTitleIndex = index
        }
        componentState = (nodeComponents.isEmpty && displaySubModule == .recentlyUsed) ? .noApp : .running
    }

    func updateDisplayModule(module: FavoriteSubModule, isUserSelected: Bool = false) {
        guard let index = subModuleList.firstIndex(of: module) else {
            userSelectedSubModule = nil
            return
        }
        updateDisplayModule(index: index, isUserSelected: isUserSelected)
    }

    func updateFavoriteAreaState(state: WPCommonAreaState) {
        guard displaySubModule == .favorite else { return }
        nodeComponents.forEach { $0.updateEditState(isEditing: state == .editing) }
        switch state {
        case .normal:
            removeTipsNode()
        case .editing:
            addTipsNode()
        }
    }

    func switchToFavoriteEmptyState() {
        guard displaySubModule == .favorite else { return }
        updateFavoriteAreaState(state: .normal)
        appendAddNode()
    }

    private func getSubTitle(config: FavoriteModule.Config?) -> [GroupTitleComponent.Title] {
        guard let config = config else { return [] }
        let subTitleList: [GroupTitleComponent.Title] = subModuleList.compactMap({
            switch $0 {
            case .favorite:
                return .init(text: WPi18nUtil.getI18nText(
                    config.favoriteTitle.text,
                    defaultLocale: config.favoriteTitle.defaultLocale
                ) ?? "" , iconUrl: config.favoriteIconURL)
            case .recentlyUsed:
                return .init(text: WPi18nUtil.getI18nText(
                    config.recentTitle.text,
                    defaultLocale: config.recentTitle.defaultLocale
                ) ?? "", iconUrl: config.recentIconURL)
            @unknown default:
                assertionFailure("should not be here")
                return nil
            }
        })
        return subTitleList
    }

    private func decode<T: Codable>(from json: JSON) -> T? {
        do {
            return try JSONDecoder().decode(T.self, from: json.rawData())
        } catch {
            Self.logger.error("Favorite Component \(componentID) decode error \(error)")
            return nil
        }
    }

    /// Data model -> View model. Only icon and block is supported in favorite sub-module
    ///
    /// - Parameters:
    ///   - items: tag of each application
    ///   - itemInfos: key: item identifier of each application; value: properties of each application
    ///   - isPortalPreview: in portal preview page or not
    private func generateFavoriteNodes(
        items: [FavoriteAppTag]?,
        itemInfos: [String: WPAppItem]?,
        isPortalPreview: Bool
    ) -> [NodeComponent] {
        guard let items = items, let itemInfos = itemInfos else { return [] }
        var iconNodes: [CommonIconComponent] = []
        var blockNodes: [BlockComponent] = []
        items.forEach { item in
            guard let itemId = item.itemId, let iteminfo = itemInfos[itemId],
                  let itemType = item.type, let itemSubType = item.subType else { return }
            switch itemType {
            case .icon:
                let node = CommonIconComponent()
                node.setData(itemData: ItemModel(dataItem: ItemUnit(type: itemType, subType: itemSubType, itemID: itemId, item: iteminfo), isAddRect: false))
                node.appScene = itemSubType
                iconNodes.append(node)
            case .block, .nonStandardBlock:
                guard let blockScene = itemSubType.getBlockScene(isFromTemplate: true) else { return }
                let node = BlockComponent()
                node.updateDataModel(
                    iteminfo,
                    scene: blockScene,
                    elementId: itemId,
                    displaySize: item.size,
                    isPortalPreview: isPortalPreview
                )
                blockNodes.append(node)
            case .widget:
                return
            }
        }
        // The icon needs to be displayed before the block
        return iconNodes + blockNodes
    }

    /// Data model -> View model. Only icon is supported in recent sub-module
    ///
    /// - Parameters:
    ///   - items: tag of each application
    ///   - itemInfos: key: item identifier of each application; value: properties of each application
    private func generateRecentNodes(items: [FavoriteAppTag]?, itemInfos: [String: WPAppItem]?) -> [NodeComponent] {
        guard let items = items, let itemInfos = itemInfos else { return [] }
        return items.compactMap { item in
            guard let itemId = item.itemId, let iteminfo = itemInfos[itemId] else { return nil }
            let node = CommonIconComponent()
            node.setData(itemData: ItemModel(dataItem: ItemUnit(type: .icon, subType: item.subType, itemID: itemId, item: iteminfo), isAddRect: false))
            return node
        }
    }

    func updateGroupState(_ newState: ComponentState) {
        if lastComponentState != .loadFailed || componentState != .loading {
            lastComponentState = componentState
        }

        // 最近使用子模块的 noApp 状态只能在 CommonAndRecommendComponent 内部修改
        if componentState == .noApp && nodeComponents.isEmpty && displaySubModule == .recentlyUsed {
            return
        }

        if componentState != .running {
            componentState = newState
        }
    }

    /// 曝光上报
    func exposePost() {
        if !isExposed {
            isExposed = true
            WPEventReport(
                name: WPNewEvent.openplatformWorkspaceMainPageComponentExpoView.rawValue,
                userId: userResolver?.userID,
                tenantId: userService?.userTenant.tenantID
            )
                .set(key: WPEventNewKey.type.rawValue, value: WPExposeUIType.commom_and_recommend.rawValue)
                .post()
        }
    }

    func monitorComponentShow(trace: OPTraceProtocol?) {
        let isRetry = lastComponentState == .loadFailed
        WPMonitor().setCode(WPMCode.workplace_native_component_show_content)
            .setTrace(trace)
            .setInfo([
                "component_type": groupType.rawValue,
                "component_id": componentID,
                "is_retry": isRetry
            ])
            .flush()
    }

    func moveComponent(to targetIndex: Int, previousIndex: Int) {
        guard nodeComponents.count > targetIndex && nodeComponents.count > previousIndex else { return }
        let previousNode = nodeComponents[previousIndex]
        nodeComponentsMap[displaySubModule]?.remove(at: previousIndex)
        nodeComponentsMap[displaySubModule]?.insert(previousNode, at: targetIndex)
    }

    func removeComponent(at index: Int, for notAuth: Bool) {
        guard nodeComponents.count > index, !notAuth else {
            return
        }
        nodeComponentsMap[displaySubModule]?.remove(at: index)
    }

    private func appendAddNode() {
        let addAppComponent = createAddRectNode()
        nodeComponentsMap[displaySubModule]?.append(addAppComponent)
    }

    private func addTipsNode() {
        if (nodeComponents.first as? CommonTipsComponent) != nil { return }
        nodeComponentsMap[displaySubModule]?.insert(CommonTipsComponent(), at: 0)
    }

    private func removeTipsNode() {
        nodeComponentsMap[displaySubModule]?.removeAll { $0.type == .CommonTips }
    }

    /// 判断常用区域是否可管理
    /// 如果只有管理员推荐应用，则不可管理
    func isGroupManageable() -> Bool {
        let firstCustomItem = nodeComponents.first { node in
            if let iconComponent = node as? CommonIconComponent {
                return iconComponent.isEditable
            }
            if let blockComponent = node as? BlockComponent {
                return blockComponent.isEditable
            }
            return false
        }
        return firstCustomItem != nil
    }

    private func createAddRectNode() -> CommonIconComponent {
        let addAppComponent = CommonIconComponent()
        let addItem = WPAppItem.buildAddItem()
        let addUnit = ItemUnit(type: .icon, subType: .systemAdd, itemID: "", item: addItem)
        addAppComponent.setData(itemData: ItemModel(dataItem: addUnit, isAddRect: true))
        return addAppComponent
    }

    func checkNodeListIsEmpty() -> Bool {
        let filteredNodes = nodeComponents.filter { nodeComponent in
            if nodeComponent.type == .CommonTips {
                return false
            }
            if let iconComponent = nodeComponent as? CommonIconComponent {
                return iconComponent.itemModel?.itemType != .addRect
            }
            return true
        }
        return filteredNodes.isEmpty
    }
}

/// 常用&推荐应用的Icon应用
final class CommonIconComponent: NodeComponent {
    var type: NodeComponentType = .CommonIconApp

    var layoutParams: BaseComponentLayout?

    var itemModel: ItemModel?

    /// 应用类型细分
    var appScene: WPTemplateModule.ComponentDetail.Favorite.AppSubType?

    /// 固定样式，无需解析
    func parse(json: JSON) -> NodeComponent {
        return self
    }

    func setData(itemData: ItemModel) {
        self.itemModel = itemData
    }

    /// 是否是可编辑（删除、拖拽）的应用
    var isEditable: Bool {
        isDeletable || isSortable
    }

    /// 是否可删除
    var isDeletable: Bool {
        itemModel?.isDeletable ?? false
    }

    /// 是否可排序
    var isSortable: Bool {
        itemModel?.isSortable ?? false
    }

    /// 是否是推荐应用
    var isRecommand: Bool {
        return itemModel?.isRecommand ?? false
    }

    var appId: String? {
        return itemModel?.appId
    }
}

final class CommonTipsComponent: NodeComponent {
    var type: NodeComponentType = .CommonTips

    var layoutParams: BaseComponentLayout?

    var itemModel: ItemModel?

    /// 固定样式，无需解析
    func parse(json: JSON) -> NodeComponent {
        return self
    }
}
