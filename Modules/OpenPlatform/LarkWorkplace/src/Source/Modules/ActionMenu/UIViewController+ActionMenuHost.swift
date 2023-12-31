//
//  UIViewController+ActionMenuHost.swift
//  LarkWorkplace
//
//  Created by Shengxy on 2023/7/11.
//

import Foundation
import LarkUIKit
import LarkWorkplaceModel
import RoundedHUD
import LarkTab
import UniverseDesignIcon

/// 操作菜单通用能力（原生工作台 & 模板工作台共用）
extension ActionMenuHost where Self: UIViewController {
    
    /// 展示 icon 形态应用操作菜单
    ///
    /// - Parameters:
    ///   - cell: cell 视图（用于蒙层剪裁）
    ///   - itemInfo: 应用的 data model（用于item类型判定，itemId获取）
    ///   - indexPath: 应用在 UICollectionView 上的索引（用于 cell 操作，设置/取消常用）
    func handleIconLongPress(cell: WorkPlaceIconCell, itemInfo: ItemModel, indexPath: IndexPath) {
        context.trace.info("handle icon long press", additionalData: [
            "hasNavigationView": "\(navigationController?.view != nil)",
            "isUILocalChanging": "\(actMenuShowManager.isUILocalChanging)"
        ])
        guard let window = navigationController?.view, !actMenuShowManager.isUILocalChanging else { return}

        var additionalSpace: CGFloat = 0
        if let layout = menuFromCollectionView.collectionViewLayout as? WPTemplateLayout {
            // 新版工作台
            additionalSpace = layout.commonAndRecommendHeaderHeight
        } else {
            // 老版工作台
            additionalSpace = getHeaderHeight(section: indexPath.section)
        }
        /// 生成要穿透展示的Frame
        let offsetY = getMaskFrameOffsetY(
            cell: cell,
            section: indexPath.section,
            additionalSpace: additionalSpace
        )
        var mainMaskRect = cell.iconView.convert(cell.iconView.bounds, to: window)
        mainMaskRect.origin.y += offsetY
        let maskFrame = TargetItemInfo(
            maskRect: mainMaskRect,
            maskRedius: WPUIConst.AvatarRadius.large,
            useSmoothCorner: true
        )
        /// 生成要装饰展示的view
        let extraViews: [UIView] = getIconExtraViews(cell: cell, window: window, offsetY: offsetY)
        /// 移动CV进行适配
        moveCollectionView(offsetY: offsetY)
        /// 生成菜单选项
        guard let menuConfig = getIconLongPressMenuConfig(path: indexPath, item: itemInfo) else {
            context.trace.error("generate menu config failed", additionalData: [
                "item": "\(itemInfo.getItemId() ?? "")"
            ])
            return
        }
        /// 生成长按菜单
        context.trace.info("ready to display longPress menu for iconApp")
        let longPressMenuView = WorkPlaceLongPressMenuView(
            parentViewRect: window.bounds,
            mainMaskFrame: maskFrame,
            extraViews: extraViews,
            menuConfig: menuConfig
        )
        if Display.pad {
            showPopOverLongPressMenu(targetView: cell.iconView, menuView: longPressMenuView, isWidget: false)
        } else {
            displayLongPressMenu(window: window, longPressMenu: longPressMenuView)
        }

        /// 记录菜单目标信息，以备在重新展示时使用
        actMenuShowManager.targetPath = indexPath
        actMenuShowManager.targetItemId = itemInfo.item.itemId

        // 业务埋点上报
        if let appId = itemInfo.getSingleAppInfo()?.appId {
            postActionMenuExpoOld(appId: appId)
        }
        context.tracker
            .start(.openplatform_workspace_main_page_component_expo_view)
            .setExposeUIType(.app_menu)
            .post()
    }

    /// 展示 widget 操作菜单
    ///
    /// - Parameters:
    ///   - cell: cell 视图（用于蒙层剪裁）
    ///   - path: 应用在 UICollectionView 上的索引（用于 cell 操作，设置/取消常用）
    ///   - itemInfo: 应用的 data model（用于item类型判定，itemId获取）
    ///   - isCommon: 是否是常用应用
    func handleWidgetLongPress(cell: UICollectionViewCell, path: IndexPath, itemInfo: ItemModel, isCommon: Bool) {
        context.trace.info("handle widget long press", additionalData: [
            "hasNavigationView": "\(navigationController?.view != nil)",
            "isUILocalChanging": "\(actMenuShowManager.isUILocalChanging)"
        ])
        guard let window = navigationController?.view, !actMenuShowManager.isUILocalChanging else { return }

        var maskRect = cell.convert(cell.contentView.frame, to: window)
        // widget 暂保持现状，待QA确认问题后，评估是否需要修复
        let offsetY = getMaskFrameOffsetY(cell: cell, section: path.section)
        maskRect.origin.y += offsetY
        let maskFrame = TargetItemInfo(
            maskRect: maskRect,
            maskRedius: WorkPlaceWidgetCell.widgetRadius,
            useSmoothCorner: false
        )
        /// 移动CV进行适配
        moveCollectionView(offsetY: offsetY)
        guard let menuConfig = getWidgetLongPressMenuConfig(path: path, item: itemInfo, isCommon: isCommon) else {
            context.trace.error("generate menu config failed", additionalData: [
                "item": "\(itemInfo.getItemId() ?? "")"
            ])
            return
        }
        context.trace.info("ready to display longPress menu for widget")
        let longPressMenu = WorkPlaceLongPressMenuView(
            parentViewRect: window.bounds,
            mainMaskFrame: maskFrame,
            menuConfig: menuConfig
        )
        if Display.pad {
            showPopOverLongPressMenu(targetView: cell.contentView, menuView: longPressMenu, isWidget: true)
        } else {
            displayLongPressMenu(window: window, longPressMenu: longPressMenu)
        }

        /// 记录菜单目标信息
        actMenuShowManager.targetPath = path
        actMenuShowManager.targetItemId = itemInfo.item.itemId

        // 业务埋点上报
        if let appId = itemInfo.getSingleAppInfo()?.appId {
            postActionMenuExpoOld(appId: appId)
        }
    }

    /// 展示 block 操作菜单
    ///
    /// - Parameters:
    ///   - cell: cell 视图（用于蒙层剪裁）
    ///   - items: Block 操作菜单项列表
    func showActionMenu(_ cell: BlockCell, items: [ActionMenuItem]) {
        context.trace.info("show action menu", additionalData: [
            "hasNavigationView": "\(navigationController?.view != nil)",
            "isUILocalChanging": "\(actMenuShowManager.isUILocalChanging)"
        ])
        guard let window = navigationController?.view, !actMenuShowManager.isUILocalChanging else { return }

        var additionalSpace: CGFloat
        if let layout = self.menuFromCollectionView.collectionViewLayout as? WPTemplateLayout {
            // 新版工作台
            additionalSpace = layout.commonAndRecommendHeaderHeight
        } else {
            // 老版工作台，我的常用没有 header，移位高度为 0
            additionalSpace = 0
        }
        /// 生成要穿透展示的Frame
        var mainMaskRect = cell.convert(cell.contentView.frame, to: window)
        let offsetY = WPActionMenuView.getMaskFrameOffsetY(
            cell: cell,
            collectionView: menuFromCollectionView,
            additionalSpace: additionalSpace
        )
        mainMaskRect.origin.y += offsetY
        let maskFrame = WPMaskItemInfo(
            maskRect: WPActionMenuView.adjustMaskRect(originRect: mainMaskRect),
            maskRedius: 16
        )

        /// 移动CV进行适配
        moveCollectionView(offsetY: offsetY)

        /// 生成弹窗配置
        var type: TitleLayoutType = .none
        if let isTitleInner = cell.isTitleInner() {
            type = isTitleInner ? .inner : .outter
        }
        let menuConfig = WPMenuConfig(options: items, headerType: type, dismissCallback: dismissActionMenu)
        let actionMenu = WPActionMenuView(
            parentViewRect: window.bounds,
            mainMaskFrame: maskFrame,
            menuConfig: menuConfig,
            host: self,
            isForPad: Display.pad
        )

        /// 展示容器弹窗
        if Display.pad {
            let target = cell.getTargetViewForPad()
            showPopOverActionMenu(targetView: target, menuView: actionMenu)
        } else {
            displayActionMenu(window: window, actionMenu: actionMenu)
        }

        /// 记录菜单目标信息
        if let indexPath = menuFromCollectionView.indexPath(for: cell) {
            actMenuShowManager.targetPath = indexPath
            actMenuShowManager.targetItemId = cell.blockModel?.editorProps?.itemId
        } else {
            context.trace.info("blockCell(\(cell)) indexPath not find, reappear may failed")
        }

        /// 菜单展示曝光
        cell.postActionMenuExpo()
    }

    /// 隐藏操作菜单，重置相关数据
    func dismissActionMenu() {
        context.trace.info("dismissActionMenu")
        actMenuShowManager.showMenuPopOver?.dismiss(animated: false, completion: nil)
        actMenuShowManager.showMenuPopOver = nil
        actMenuShowManager.longPressMenuView = nil
        actMenuShowManager.actionMenuView = nil
        actMenuShowManager.targetPath = nil
        actMenuShowManager.targetItemId = nil
        menuFromCollectionView.isScrollEnabled = true
    }

    /// 打开第三方链接
    func openTriLink(url: String) {
        context.trace.info("open thrid link", additionalData: ["url": url])
        guard let link = URL(string: url) else { return }
        context.navigator.showDetailOrPush(
            link,
            context: ["from": "appcenter"],
            wrap: LkNavigationController.self,
            from: self
        )
    }

    /// 点击操作菜单项，执行 action 操作 （iPad 场景特化处理）
    ///
    /// - Parameter action: 操作菜单项对应的执行逻辑
    func handleMenuAction(action: @escaping () -> Void) {
        context.trace.info("handle icon app menu aciton")
        if Display.pad {
            actMenuShowManager.showMenuPopOver?.dismiss(animated: true, completion: {
                action()
            })
        } else {
            action()
        }
    }

    /// traitCollection 发生变化时的刷新菜单（ipad分转屏）
    func refreshMenuOnTraitCollectionDidChange() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
            if self.actMenuShowManager.isNeedRefreshMenuView, let targetPath = self.actMenuShowManager.targetPath {
                let targetItemId = self.actMenuShowManager.targetItemId
                self.dismissActionMenu()
                self.reappearActionMenu(originIndexPath: targetPath, itemId: targetItemId)
            }
        })
    }

    /// 重新展示操作菜单
    func reappearActionMenu(originIndexPath: IndexPath, itemId: String?) {
        context.trace.info("handle reappear action menu", additionalData: [
            "originIndexPath": "\(originIndexPath)",
            "itemId": "\(itemId ?? "")"
        ])
        var indexPath = originIndexPath
        // 检查itemId对应的item的indexPath是否有改变
        if let targetId = itemId, let realIndexPath = getIndexPath(itemId: targetId, section: indexPath.section) {
            indexPath = realIndexPath
            context.trace.info("update path[\(originIndexPath)] to real path[\(realIndexPath)]")
        }
        // 找到要展示菜单的cell
        guard let cell = self.menuFromCollectionView.cellForItem(at: indexPath) else {
            context.trace.error("find path[\(indexPath)] cell failed, not display menu")
            return
        }
        // 展示新的长按菜单
        if let blockCell = cell as? BlockCell {
            guard let menuItems = blockCell.getActionMenuItems() else {
                context.trace.warn("block[\(indexPath)] has no menu item, not display")
                return
            }
            showActionMenu(blockCell, items: menuItems)
        } else {
            guard let itemModel = getWorkPlaceItem(indexPath: indexPath) else {
                context.trace.error("find path[\(indexPath)] data failed, not display menu")
                return
            }
            if let iconCell = cell as? WorkPlaceIconCell {
                handleIconLongPress(cell: iconCell, itemInfo: itemModel, indexPath: indexPath)
            } else {
                handleWidgetLongPress(cell: cell, path: indexPath, itemInfo: itemModel, isCommon: itemModel.isCommon())
            }
        }
    }

    /// 获取蒙层穿透的适配偏移量
    ///
    /// - Parameters:
    ///   - cell: UICollectionViewCell
    ///   - section: Int
    private func getMaskFrameOffsetY(
        cell: UICollectionViewCell,
        section: Int,
        additionalSpace: CGFloat = 0
    ) -> CGFloat {
        var offsetY: CGFloat = 0
        let originOffsetY = menuFromCollectionView.contentOffset.y
        /// cell上边缘超出CV可见区域，向下移动，回到屏幕可见区域
        if cell.frame.minY < originOffsetY + additionalSpace {
            offsetY = menuFromCollectionView.contentOffset.y + additionalSpace - cell.frame.minY
        }
        /// cell下边缘超出，向上移动，回到屏幕可见区域
        let botEdge = menuFromCollectionView.frame.height - menuFromCollectionView.contentInset.bottom + originOffsetY
        if cell.frame.maxY > botEdge {
            offsetY = botEdge - cell.frame.maxY
        }
        return offsetY
    }

    /// 展示长按菜单（蒙层弹窗）
    private func displayLongPressMenu(window: UIView, longPressMenu: WorkPlaceLongPressMenuView) {
        menuFromCollectionView.isScrollEnabled = false
        actMenuShowManager.longPressMenuView = longPressMenu
        window.addSubview(longPressMenu)
        window.bringSubviewToFront(longPressMenu)
        longPressMenu.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    /// 展示操作菜单（气泡弹窗）
    private func showPopOverActionMenu(targetView: UIView, menuView: WPActionMenuView) {
        let popOver = buildMenuPopOver(
            targetView: targetView,
            menuSize: menuView.menuSize,
            sourceRect: targetView.bounds.insetBy(dx: 0, dy: -4),
            menuView: menuView.menuView
        )
        actMenuShowManager.showMenuPopOver = popOver  // 只有ipad下才会触发分/转屏，考虑重写一个VC来管理长按菜单
        actMenuShowManager.actionMenuView = menuView    // 主要用于保存「相关信息」，触发分屏/转屏的长按菜单刷新
        context.navigator.present(popOver, from: self)
    }

    /// 生成菜单气泡popOver
    private func buildMenuPopOver(
        targetView: UIView,
        menuSize: CGSize,
        sourceRect: CGRect,
        menuView: UIView
    ) -> BaseUIViewController {
        let popOver = BaseUIViewController()
        popOver.preferredContentSize = menuSize
        popOver.modalPresentationStyle = .popover
        popOver.popoverPresentationController?.sourceView = targetView
        popOver.popoverPresentationController?.sourceRect = sourceRect
        popOver.popoverPresentationController?.permittedArrowDirections = [.down, .up]
        popOver.popoverPresentationController?.delegate = self as? UIPopoverPresentationControllerDelegate
        popOver.view.addSubview(menuView)
        popOver.view.backgroundColor = UIColor.ud.bgFloat
        menuView.snp.makeConstraints { (make) in
            make.width.height.equalTo(popOver.view.safeAreaLayoutGuide) // 需要看一下，新老menu是适配
            make.center.equalTo(popOver.view.safeAreaLayoutGuide)   // 避免了箭头遮挡视图的尴尬
        }
        return popOver
    }

    /// 展示操作菜单（蒙层弹窗）
    private func displayActionMenu(window: UIView, actionMenu: WPActionMenuView) {
        menuFromCollectionView.isScrollEnabled = false
        actMenuShowManager.actionMenuView = actionMenu
        window.addSubview(actionMenu)
        window.bringSubviewToFront(actionMenu)
        actionMenu.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    /// 展示长按菜单（气泡弹窗）
    /// - Parameters:
    ///   - targetView: 要指向的目标视图
    ///   - menuView: 要显示的菜单视图内容
    ///   - arrowDir: 菜单箭头指向
    ///   - isWidget: 是否是widget
    private func showPopOverLongPressMenu(targetView: UIView, menuView: WorkPlaceLongPressMenuView, isWidget: Bool) {
        // widget的气泡要求右对齐
        let popOverOffsetX: CGFloat = isWidget ? ((targetView.bounds.width - menuView.getMenuSize().width) / 2) : 0
        let sourceRect: CGRect = isWidget ? targetView.bounds.offsetBy(dx: popOverOffsetX, dy: 0) : targetView.bounds
        let popOver = buildMenuPopOver(
            targetView: targetView,
            menuSize: menuView.getMenuSize(),
            sourceRect: sourceRect.insetBy(dx: 0, dy: -10),
            menuView: menuView.getMenuContentView()
        )
        actMenuShowManager.showMenuPopOver = popOver  // 只有ipad下才会触发分/转屏，考虑重写一个VC来管理长按菜单
        actMenuShowManager.longPressMenuView = menuView    // 主要用于保存「相关信息」，触发分屏/转屏的长按菜单刷新
        context.navigator.present(popOver, from: self)
    }

    /// 移动collectionView指定的偏移量
    /// - Parameter offsetY
    private func moveCollectionView(offsetY: CGFloat) {
        let originOffsetY = menuFromCollectionView.contentOffset.y
        menuFromCollectionView.setContentOffset(CGPoint(x: 0, y: originOffsetY - offsetY), animated: false)
    }

    /// 获取ICON类型的长按菜单装饰view
    /// - Parameters:
    ///   - cell:装饰view的来源
    ///   - window:要附着的window
    ///   - offsetY:适配偏移量
    private func getIconExtraViews(cell: WorkPlaceIconCell, window: UIView, offsetY: CGFloat) -> [UIView] {
        var extraViews: [UIView] = []
        if !cell.tagView.isHidden {  // 标签
            var maskRect = cell.convert(cell.tagView.frame, to: window)
            maskRect.origin.y += offsetY
            if let tagView = cell.tagView.snapshotView(afterScreenUpdates: false) {
                tagView.frame = maskRect
                extraViews.append(tagView)
            } else {
                context.trace.error("tagView snapshot failed")
            }
        }
        if let badgeView = cell.badgeView, !badgeView.isHidden {  // badge红点
            var targetRect = badgeView.convert(badgeView.bounds, to: window)
            targetRect.origin.y += offsetY
            if let targetView = badgeView.snapshotView(afterScreenUpdates: false) {
                targetView.frame = targetRect
                extraViews.append(targetView)
            } else {
                context.trace.error("badgeView snapshot failed")
            }
        }
        return extraViews
    }

    /// 获取 icon 形态应用的操作菜单项
    ///
    /// - Parameters:
    ///   - path: 应用对应的 cell 在 UICollectionView 中的索引
    ///   - itemInfo: 应用 data model
    ///   顺序：「添加到导航栏」 、「设为常用」、「排序」、「分享」、「设置角标」、「移除常用」
    private func getIconLongPressMenuConfig(path: IndexPath, item: ItemModel) -> MenuConfig? {
        // 检查itemId,appId,sectionModel
        guard let itemId = item.getItemId() else {
            context.trace.error("get single appInfo failed(\(item)), get no option")
            return nil
        }
        let isMainSection = isCommonAndRec(section: path.section)
        let isRecentlyUsed = isInRecentlyUsedSubModule(section: path.section)
        var menuOptions: [MenuOptionSetting] = []

        var showAddToQuickLaunchOption = false
        /// 「添加到导航栏」菜单项
        let mobileDefaultAbility = item.item.mobileDefaultAbility
        /// FG 开，仅 iPhone 原生工作台的小程序和网页应用支持「添加到导航栏」
        if Display.phone,
           context.configService.fgValue(for: .enableAddAppToNavbar),
           host == .normal,
           let appId = item.appId,
           !appId.isEmpty {
            if mobileDefaultAbility == .miniApp,
               let miniAppUrl = item.item.url?.mobileMiniAppURL,
               !miniAppUrl.isEmpty {
                menuOptions.append(addToQuickLaunchOption(itemModel: item, bizType: CustomBizType.MINI_APP, url: miniAppUrl, appId: appId))
                showAddToQuickLaunchOption = true
            } else if mobileDefaultAbility == .web,
                      let webUrl = item.item.url?.mobileWebURL,
                      !webUrl.isEmpty {
                menuOptions.append(addToQuickLaunchOption(itemModel: item, bizType: CustomBizType.WEB_APP, url: webUrl, appId: appId))
                showAddToQuickLaunchOption = true
            }
        }
        
        // 添加到常用菜单项
        if !isMainSection, item.canAddComon {
            menuOptions.append(addCommonOption(indexPath: path, itemId: itemId))
        }
        
        // 排序菜单项
        if isMainSection, showRankOptionInLongPressMenu {
            let tip = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_RemovableAppActionNull2
            menuOptions.append(rankOption(indexPath: path, disableTip: item.isSortable ? nil : tip))
        }

        // 分享菜单项
        // 分享选项
        var showShare: Bool = isShareEnable(isWidget: false, itemType: item.item.itemType)
        // 本地集成应用暂不支持分享。产品决策长期需支持分享。技术支持后，该特化逻辑需删除。
        if item.item.mobileDefaultAbility == .native || item.item.pcDefaultAbility == .native {
            showShare = false
        }
        let disableTip = showShare ? nil : BundleI18n.LarkWorkplace.OpenPlatform_Share_NotShareableToast
        menuOptions.append(shareOption(indexPath: path, itemModel: item, disableTip: disableTip))
        
        // 角标设置菜单项
        if context.configService.fgValue(for: .badgeOn),
            context.configService.fgValue(for: .workflowOptimize),
           host == .normal {
            let badgeAuthed = item.item.badgeAuthed ?? false
            let disableTip = badgeAuthed ? nil : BundleI18n.LarkWorkplace.OpenPlatform_WorkplaceMgt_BadgeSettingsBttnDisabledTooltip
            menuOptions.append(
                badgeSettingsOption(
                    itemModel: item,
                    disableTip: disableTip
                )
            )
        }

        // 移除常用菜单项
        if isMainSection, !isRecentlyUsed {
            let tip = BundleI18n.LarkWorkplace.OpenPlatform_Share_RecAppUnfavoriteErrToast
            menuOptions.append(canCelCommonOption(indexPath: path, itemId: itemId, isInCommonSection: true, disableTip: item.isDeletable ? nil : tip))
        } else if !isMainSection, !item.canAddComon {
            let tip = BundleI18n.LarkWorkplace.OpenPlatform_Share_RecAppUnfavoriteErrToast
            menuOptions.append(canCelCommonOption(indexPath: path, itemId: itemId, isInCommonSection: false, disableTip: item.isDeletable ? nil : tip))
        }

        
        appAreaPost(appId: getDefaultAppId(item: item.dataItem), section: path.section)
        /// 展示 icon 类型的长按菜单会触发这个埋点
        /// appAreaPost 是所有长按菜单展示都会埋点
        context.tracker
            .start(.openplatform_workspace_icon_menu_item_view)
            .setValue((showAddToQuickLaunchOption ? "true": "false"), for: .has_add_to_navigation)
            .post()
        
        context.trace.info("icon long press menu config", additionalData: [
            "appId" : item.appId ?? "",
            "enableAddAppToNavbar": "\(context.configService.fgValue(for: .enableAddAppToNavbar))",
            "host": "\(host.rawValue)",
            /// mobileDefaultAbility 从 0(unknown) 开始, -1 代表不存在
            "mobileDefaultAbility": "\(mobileDefaultAbility?.rawValue ?? -1)",
            "showAddToQuickLaunchOption": "\(showAddToQuickLaunchOption)",
            "showShare": "\(showShare)",
            "isWorkflowOptimize": "\(context.configService.fgValue(for: .workflowOptimize))",
            "isBadgeOn": "\(context.configService.fgValue(for: .badgeOn))"
        ])
        
        return MenuConfig(
            isDisplayArrow: false,
            displayMode: .target,
            options: menuOptions,
            footerTip: nil,
            dismissCallback: dismissActionMenu
        )
    }

    /// 获取 widget 的操作菜单项
    ///
    /// - Parameters:
    ///   - path: 应用对应的 cell 在 UICollectionView 中的索引
    ///   - itemInfo: 应用 data model
    ///   - isCommon: 是否是常用应用
    private func getWidgetLongPressMenuConfig(path: IndexPath, item: ItemModel, isCommon: Bool) -> MenuConfig? {
        // 检查itemId,appId,sectionModel
        guard let itemId = item.getItemId() else {
            context.trace.error("get widget appInfo failed(\(item)), get no option")
            return nil
        }
        let isMainSection = isCommonAndRec(section: path.section)
        var menuOptions: [MenuOptionSetting] = []
        let subType = item.dataItem.subType
        if isMainSection {
            // 主分组（推荐+常用）
            let isDisable: Bool = (subType == .recommend) || (subType == .platformWidget)   // 推荐应用
            // 根据是否是推荐应用判断可用性
            let enableTip = isDisable ? BundleI18n.LarkWorkplace.OpenPlatform_Share_RecAppUnfavoriteErrToast : nil
            let rankDisableTip = isDisable ? BundleI18n.LarkWorkplace.OpenPlatform_Share_RecAppSortErrToast : nil
            menuOptions.append(canCelCommonOption(
                indexPath: path,
                itemId: itemId,
                isInCommonSection: true,
                disableTip: enableTip
            ))
            menuOptions.append(rankOption(indexPath: path, disableTip: rankDisableTip))
        } else {
            if isCommon {
                menuOptions.append(canCelCommonOption(indexPath: path, itemId: itemId, isInCommonSection: false))
            } else {
                menuOptions.append(addCommonOption(indexPath: path, itemId: itemId))
            }
        }
        // 应用分享选项
        let showShare: Bool = isShareEnable(isWidget: true, itemType: item.item.itemType)
        // 如果可用则无disableTip
        let disableTip = showShare ? nil : BundleI18n.LarkWorkplace.OpenPlatform_Share_WidgetNotShareableToast
        menuOptions.append(shareOption(indexPath: path, itemModel: item, disableTip: disableTip))
        appAreaPost(appId: getDefaultAppId(item: item.dataItem), section: path.section)
        return MenuConfig(
            isDisplayArrow: false,
            displayMode: .rightAlign,
            options: menuOptions,
            footerTip: nil,
            dismissCallback: dismissActionMenu
        )
    }

    /// Icon 形态应用菜单项 - 「取消常用」
    ///
    /// - Parameters:
    ///   - disableTip: 选项不可用提示语，不可用时传入；可用时默认为nil；
    func canCelCommonOption(
        indexPath: IndexPath,
        itemId: String,
        isInCommonSection: Bool,
        disableTip: String? = nil
    ) -> MenuOptionSetting {
        let dataItem = getWorkPlaceItem(indexPath: indexPath)?.dataItem
        let appSubType = dataItem?.subType
        let cancelText: String
        if !isInCommonSection {
            // 在全部应用分组里：“移除常用”
            cancelText = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_RemoveFrqBttnCustomCat
        } else {
            // 在常用应用分组里：“移除”
            cancelText = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_RemoveFrqBttn
        }

        if let tip = disableTip {   // 选项不可用
            return MenuOptionSetting(
                isEnableStyle: false,
                text: cancelText,
                img: Resources.menu_cancel_disable,
                block: { [weak self] in
                    self?.disableActionWith(tip: tip)
                }
            )
        } else {
            return MenuOptionSetting(
                isEnableStyle: true,
                text: cancelText,
                img: Resources.menu_cancel_common,
                // swiftlint:disable closure_body_length
                block: { [weak self] in
                    guard let `self` = self else { return }
                    self.context.trace.info("user tap cancel common in longPress menu")
                    self.context.tracker
                        .start(.appcenter_set_cancel_commonuse)
                        .setValue(self.getDefaultAppId(item: dataItem), for: .app_id)
                        .post()
                    self.removeCommon(indexPath: indexPath, itemId: itemId)

                    var click: WorkplaceTrackClickValue = .icon_menu_item
                    var removeType: WorkplaceTrackFavoriteRemoveType = .icon
                    if dataItem?.item.itemType == .link, dataItem?.item.linkURL != nil {
                        removeType = .link
                        click = .link_menu_item
                    }

                    self.context.tracker
                        .start(.openplatform_workspace_main_page_click)
                        .setClickValue(click)
                        .setTargetView(.none)
                        .setMenuType(.remove)
                        .setHost(self is TemplateViewController ? .template : .old)
                        .setFavoriteRemoveType(removeType)
                        .setValue(appSubType?.trackIntVal, for: .my_common_type)
                        .setValue(self.getDefaultAppId(item: dataItem), for: .app_id)
                        .setValue(dataItem?.item.itemId, for: .item_id)
                        .post()
                }
                // swiftlint: enable closure_body_length
            )
        }
    }
    /// Icon 形态应用菜单项 - 「添加常用」
    /// - Parameters:
    ///   - cell: cell视图（用于cell的视图增删）
    ///   - indexPath: item数据路径（用于数据的增删）
    ///   - itemId:用于数据请求
    func addCommonOption(indexPath: IndexPath, itemId: String) -> MenuOptionSetting {
        let addCommon = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_SetFrqBttn
        let dataItem = self.getWorkPlaceItem(indexPath: indexPath)?.dataItem
        return MenuOptionSetting(
            isEnableStyle: true,   // 目前没有不可用的情况
            text: addCommon,
            img: Resources.menu_add_common,
            block: { [weak self] in
                self?.context.trace.info("user tap add common in longPress menu")
                self?.context.tracker
                    .start(.appcenter_set_commonuse)
                    .setValue(self?.getDefaultAppId(item: dataItem), for: .app_id)
                    .post()
                self?.addCommon(indexPath: indexPath, itemId: itemId)
            }
        )
    }
    /// Icon 形态应用菜单项 - 「排序」
    /// - Parameters:
    ///   - disableTip: 选项不可用提示语，不可用时传入；可用时默认为nil；
    /// - Returns: 菜单选项
    func rankOption(indexPath: IndexPath, disableTip: String? = nil) -> MenuOptionSetting {
        let rankText = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_SortAppBttn
        if let tip = disableTip {   // 选项不可用
            return MenuOptionSetting(
                isEnableStyle: false,
                text: rankText,
                img: Resources.menu_rank_disable,
                block: { [weak self] in
                    self?.disableActionWith(tip: tip)
                }
            )
        } else {
            return MenuOptionSetting(isEnableStyle: true, text: rankText, img: Resources.menu_rank) { [weak self] in
                self?.context.trace.info("user tap rank option to rankPage")
                guard let `self` = self else { return }
                let dataItem = self.getWorkPlaceItem(indexPath: indexPath)?.dataItem
                self.context.tracker
                    .start(.appcenter_set_order)
                    .setValue(self.getDefaultAppId(item: dataItem), for: .app_id)
                    .post()

                // 这里不走 Block 菜单的 onMenuItemTap，避免打点混淆
                // 原来从排序进入到设置页，是没有角标设置入口的，「工作台管理功能前置」需求需要跟安卓对齐，在gadget.open_app.badge开启时加上角标设置
                let showBadge = context.configService.fgValue(for: .badgeOn)
                let body = WorkplaceSettingBody(showBadge: showBadge, commonItemsUpdate: nil)
                self.context.navigator.showDetailOrPush(body: body, wrap: LkNavigationController.self, from: self)
                self.dismissActionMenu()

                let rt = dataItem?.subType
                self.context.tracker
                    .start(.openplatform_workspace_main_page_click)
                    .setClickValue(.icon_menu_item)
                    .setTargetView(.none)
                    .setMenuType(.sort)
                    .setValue(rt?.trackIntVal, for: .my_common_type)
                    .setHost(self is TemplateViewController ? .template : .old)
                    .setValue(self.getDefaultAppId(item: dataItem), for: .app_id)
                    .post()
            }
        }
    }
    /// Icon 形态应用菜单项 - 「分享」
    /// - Parameters:
    ///   - itemModel: ItemModel
    ///   - disableTip: 选项不可用提示语，不可用时传入；可用时默认为nil；
    /// - Returns: 菜单选项
    func shareOption(indexPath: IndexPath, itemModel: ItemModel, disableTip: String? = nil) -> MenuOptionSetting {
        let shareText = BundleI18n.LarkWorkplace.OpenPlatform_Share_WorkplaceAppShareBttn
        if let tip = disableTip {   // 选项不可用
            return MenuOptionSetting(
                isEnableStyle: false,
                text: shareText,
                img: Resources.menu_share_disable,
                block: { [weak self] in
                    self?.disableActionWith(tip: tip)
                }
            )
        } else {
            return MenuOptionSetting(
                isEnableStyle: true,
                text: shareText,
                img: Resources.menu_share,
                block: { [weak self] in
                    self?.context.trace.info("user tap share option to shareModule")
                    self?.handleMenuAction {
                        self?.shareItem(with: itemModel, indexPath: indexPath)
                    }
                }
            )
        }
    }
    
    /// Icon 形态应用菜单项 - 「添加到导航栏」
    /// - Parameters:
    /// - itemModel: ItemModel
    /// - bizType: 应用所属的业务类型
    /// - url: pin 到主导航后的跳转链接
    /// - appId: 应用 appId
    /// - Returns: 菜单选项
    func addToQuickLaunchOption(itemModel: ItemModel, bizType: CustomBizType, url: String, appId: String) -> MenuOptionSetting {
        let rankText = BundleI18n.LarkWorkplace.OpenPlatform_WorkplaceApp_AddToNavBar
        return MenuOptionSetting(
            isEnableStyle: true,
            text: rankText,
            img: UDIcon.getIconByKey(.pinOutlined)
        ) { [weak self] in
            self?.context.trace.info("user tap add to quick launch option", additionalData: [
                "appId" : appId,
                "tabBizType": "\(bizType.rawValue)",
                "tabTitle": itemModel.item.name
            ])
            guard let `self` = self else { return }
            
            let appSubType = itemModel.dataItem.subType
            self.context.tracker
                .start(.openplatform_workspace_main_page_click)
                .setClickValue(.icon_menu_item)
                .setTargetView(.none)
                .setMenuType(.add_to_navigation)
                .setHost(self is TemplateViewController ? .template : .old)
                .setValue(appSubType?.trackIntVal, for: .my_common_type)
                .setValue(appId, for: .app_id)
                .post()
            
            // pinToQuickLaunchWindow 只会返回一个 .empty 的 complete事件，拿不到 pin 的结果
            self.quickLaunchService.pinToQuickLaunchWindow(
                id: appId,
                tabBizID: appId,
                tabBizType: bizType,
                // 目前主导航栏传 imageKey 加载会有问题，先使用 iconURL 加载 logo
                tabIcon: .urlString(itemModel.item.iconURL ?? ""),
                tabTitle: itemModel.item.name,
                tabURL: url,
                tabMultiLanguageTitle: [:]
            ).subscribe(onCompleted: { [weak self] in
                self?.context.trace.info("add to quick launch complete", additionalData: [
                    "appId" : appId
                ])
            }).disposed(by: self.disposeBag)
        }
    }
    
    /// Icon 形态应用菜单项 - 「角标设置」
    /// - Parameters:
    ///   - itemModel: ItemModel
    ///   - disableTip: 选项不可用提示语，不可用时传入；可用时默认为nil；
    /// - Returns: 菜单选项
    private func badgeSettingsOption(
        itemModel: ItemModel,
        disableTip: String? = nil
    ) -> MenuOptionSetting {
        let badgeSettingsText = BundleI18n.LarkWorkplace.OpenPlatform_WorkplaceMgt_BadgeSettingsBttn
        if let tip = disableTip {
            /// 选项不可用
            return MenuOptionSetting(
                isEnableStyle: false,
                text: badgeSettingsText,
                img: UDIcon.getIconByKey(.badgeOutlined),
                block: { [weak self] in
                    self?.disableActionWith(tip: tip)
                }
            )
        } else {
            return MenuOptionSetting(
                isEnableStyle: true,
                text: badgeSettingsText,
                img: UDIcon.getIconByKey(.badgeOutlined),
                block: { [weak self] in
                    guard let `self` = self else { return }
                    
                    self.context.trace.info("user tap badge setting option to set badge")
                    self.context.navigator.showDetailOrPush(
                        body: AppBadgeSettingBody(),
                        wrap: LkNavigationController.self,
                        from: self
                    )
                    self.context.tracker
                        .start(.openplatform_workspace_main_page_click)
                        .setClickValue(.icon_menu_item)
                        .setTargetView(.none)
                        .setMenuType(.badge_management)
                        .setHost(self is TemplateViewController ? .template : .old)
                        .setValue(itemModel.dataItem.subType?.trackIntVal, for: .my_common_type)
                        .setValue(self.getDefaultAppId(item: itemModel.dataItem), for: .app_id)
                        .post()
                }
            )
        }
    }

    /// 判断是否是分享可用的应用
    private func isShareEnable(isWidget: Bool, itemType: WPAppItem.AppType) -> Bool {
        return !isWidget && (itemType == .normalApplication || itemType == .link)
    }

    /// 功能禁用的点击提示block
    private func disableActionWith(tip: String) {
        handleMenuAction {
            RoundedHUD.showFailure(with: tip, on: self.view)
        }
    }

    /// Icon 形态应用分享
    private func shareItem(with itemModel: ItemModel, indexPath: IndexPath) {
        context.trace.info("start share item", additionalData: [
            "type": "\(itemModel.item.itemType)",
            "link": itemModel.item.linkURL ?? ""
        ])

        let rt = itemModel.dataItem.subType

        let trackEvent = context.tracker
            .start(.openplatform_workspace_main_page_click)
            .setTargetView(.none)
            .setMenuType(.share)
            .setHost(self is TemplateViewController ? .template : .old)
            .setValue(rt?.trackIntVal, for: .my_common_type)

        if itemModel.item.itemType == .link {
            guard let link = itemModel.item.linkURL else { return }
            dependency.share.sharePureLink(with: link, from: self) { [weak self](userIds, chatIds) in
                self?.context.trace.info("share link item finished", additionalData: [
                    "userIds": "\(userIds)",
                    "chatIds": "\(chatIds)"
                ])
            }

            trackEvent
                .setClickValue(.link_menu_item)
                .setValue(itemModel.item.itemId, for: .item_id)
                .post()
        }

        if itemModel.item.itemType == .normalApplication {
            guard let appId = getDefaultAppId(item: itemModel.dataItem) else {
                self.context.trace.error("share app with no appId", additionalData: ["itemId": itemModel.itemID])
                return
            }
            dependency.share.shareAppFromWorkplaceAppCard(with: appId, from: self)
            context.tracker
                .start(.openplatform_workspace_appcard_action_menu_click)
                .setClickValue(.app_share)
                .setTargetView(.openplatform_application_share_view)
                .setValue(appId, for: .application_id)
                .post()

            trackEvent
                .setClickValue(.icon_menu_item)
                .setValue(appId, for: .app_id)
                .post()
        }
    }

    /// 获取缺省情况下的appId
    /// - Parameter item
    private func getDefaultAppId(item: ItemUnit?) -> String? {
        context.trace.info("get default appId", additionalData: [
            "appId": "\(item?.item.appId ?? "")",
            "itemId": "\(item?.item.itemId ?? "")"
        ])
        if let appId = item?.item.appId {
            return appId
        }
        /// 业务逻辑，书签(bookMark)没有appId，使用itemId作为缺省appId
        if item?.item.itemType == .personCustom, let itemId = item?.item.itemId {
            return itemId
        }
        return nil
    }

    /// 操作菜单（老版）
    private func postActionMenuExpoOld(appId: String) {
        context.tracker
            .start(.openplatform_workspace_appcard_action_menu_view)
            .setValue(appId, for: .application_id)
            .post()
    }

    /// 长按菜单事件上报
    private func appAreaPost(appId: String?, section: Int) {
        let isMainTag = isCommonAndRec(section: section)
        let appArea = isMainTag ? 1 : 2 // 1: 我的常用,2: 分组应用
        context.tracker
            .start(.appcenter_set_more)
            .setValue(appId, for: .app_id)
            .setValue("\(appArea)", for: .app_area)
            .post()
    }
}
