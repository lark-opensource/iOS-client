//  Created by weidong fu on 5/2/2018.

import Foundation
import SKCommon
import SKFoundation
import SKResource
import SKUIKit
import UniverseDesignBadge
import UniverseDesignIcon
import SKInfra
import RxSwift
import SpaceInterface

class NavigationMenuService: BaseJSService {
    
    enum BadgeStyle: String {
        case noBadge = "none"
        case dotRed = "point"
        case numberRed = "num"
        case numberGrey = "mute"
    }
    
    struct MenuInfo {
        var id: String
        var iconID: UDIconType?
        var naviBarID: SKNavigationBar.ButtonIdentifier
        var text: String?  // 文字按钮，群公告场景会用到
        var image: UIImage? // 如果不存在 text 则用这个
        var disabled: Bool
        var selected: Bool?
        var customColorMapping: [UIColor]?
        var useOriginImageRendering: Bool = false // 渲染原始色彩的image: UIImage?，仅对image类型有效
        var badgeStyle: UDBadgeConfig?
        var callback: () -> Void
    }

    private var hasShownShareBadge = false
    private var hasShowMoreBadge = false
    private var lastInfos: [MenuInfo]?
    private let feedMuteEnabled: Bool
    private var disposeBag = DisposeBag()

    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        feedMuteEnabled = UserScopeNoChangeFG.CS.feedMuteEnabled
        super.init(ui: ui, model: model, navigator: navigator)
        model.browserViewLifeCycleEvent.addObserver(self)
    }
}

extension NavigationMenuService: BrowserViewLifeCycleEvent {
    func browserDidTransition(from: CGSize, to: CGSize) {
        // 有可能 navigation bar 在 layoutSubviews 里隐藏了某些导航栏按钮 due to width inefficiency
        // 在 browser 宽度变化之后，用前端传过来的最新的 lastInfo 刷新一下右边导航栏的按钮，尝试恢复
        if from.width < to.width, let lastInfo = lastInfos {
            resetItems(with: lastInfo)
        }
    }
    
    func browserDidSplitModeChange() {
        if let lastInfo = lastInfos {
            resetItems(with: lastInfo)
        }
    }
}

extension NavigationMenuService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [.navMenu]
    }

    func handle(params: [String: Any], serviceName: String) {
        guard let infos = params["items"] as? [[String: Any]] else { return }
        guard let callback = params["callback"] as? String else { return }
        var menuInfos: [MenuInfo] = []
        // 前端返回的是逆序列表，客户端要翻转一下
        infos.reversed().forEach { (info) in
            guard let id = info["id"] as? String else { return }
            let text = info["text"] as? String
            let iconID = _getIconID(from: id)
            var image: UIImage?
            if let iconID = iconID {
                image = UDIcon.getIconByKey(iconID)
            }
            let disabled = info["disabled"] as? Bool ?? false
            let selected = info["selected"] as? Bool
            let customColors = info["customColor"] as? [String]
            var badgeStyle = info["badgeStyle"] as? String ?? "none"
            let badgeNum = info["badgeNum"] as? Int ?? 0
            
            if badgeNum == 0 {
                badgeStyle = "none"
            } else {
                DocsLogger.info("reset navigation item badgeNum: \(badgeNum) id: \(id) disabled: \(disabled) badgeStyle: \(badgeStyle)")
            }
            let params = ["id": id]
            let info = MenuInfo(
                id: id,
                iconID: iconID,
                naviBarID: _skNaviBarButtonID(for: id),
                text: text,
                image: image,
                disabled: disabled,
                selected: selected,
                customColorMapping: customColors?.map { UIColor.docs.rgb($0) },
                badgeStyle: getUDBadgeConfig(style: badgeStyle, num: badgeNum),
                callback: { [weak self] in
                    guard let self = self else { return }
                    self.model?.jsEngine.callFunction(DocsJSCallBack(callback), params: params, completion: nil)
                    let itemId = params["id"] ?? ""
                    if !itemId.isEmpty {
                        self.model?.docComponentDelegate?.docComponentHost(self.docComponentHost,
                                                                            onEvent: .onNavigationItemClick(item: itemId))
                    }
                    DocsLogger.info("navigation menuitem onclick:\(itemId)")
                }
            )
            menuInfos.append(info)
        }
        let interceptionService = model?.jsEngine.fetchServiceInstance(NavigationMenuInterceptionService.self)
        menuInfos = interceptionService?.updateMenuInfo(current: menuInfos) ?? menuInfos
        lastInfos = menuInfos
        ui?.displayConfig.trailingButtonItems = self.barButtonItems(target: self, infos: menuInfos)
        informNavigationCustomLeftButtonStatus()
        observeShadowFileMoreItemChanged()
    }
    
    private func getUDBadgeConfig(style: String, num: Int) -> UDBadgeConfig? {
        let maxNumber = 999
        guard let styleType = BadgeStyle(rawValue: style) else { return nil }
        switch styleType {
        case .noBadge: // 不显示badge
            return nil
        case .dotRed:
            let config = UDBadgeConfig(type: .dot, number: num, maxNumber: maxNumber)
            return config
        case .numberRed:
            let config = UDBadgeConfig(type: .number, number: num, maxNumber: maxNumber)
            return config
        case .numberGrey: // 仅代表灰色的num
            var config = UDBadgeConfig(type: .number, number: num, maxNumber: maxNumber)
            let isDrive = model?.browserInfo.docsInfo?.type == .file
            if feedMuteEnabled, !isDrive {
                config.style = .dotBGGrey
            }
            return config
        }
    }
    
    private func resetItems(with infos: [MenuInfo]) {
        ui?.displayConfig.trailingButtonItems = self.barButtonItems(target: self, infos: infos)
    }

    private func additionSetup(for info: MenuInfo) -> MenuInfo {
        return addMoreRedPointIfNeeded(info: info)
    }

    /// 通知前端当前左侧自定义按钮的状态，目前包括（全屏按钮）
    private func informNavigationCustomLeftButtonStatus() {
        // 更新当前Icon状态 -》 前端
        // BTW：前端同学要求只需要获取是否全屏这个状态
        guard SKDisplay.pad, let lkSplitVC = navigator?.currentBrowserVC?.lkSplitViewController else {
            return
        }
        let isFullScreenMode = lkSplitVC.splitMode == .secondaryOnly
        if isFullScreenMode {
            model?.jsEngine.callFunction(.clickFullScreenButton, params: ["isFullsceenMode": isFullScreenMode], completion: nil)
        }
    }
}

extension NavigationMenuService {
    private func barButtonItems(target: AnyObject, infos: [MenuInfo]) -> [SKBarButtonItem] {
        var infos = infos
        setupShadowFileMoreItemIfNeed(menuInfos: &infos)
        let targetClasses: [AnyClass] = [type(of: target)]
        let editorIdentity = model?.jsEngine.editorIdentity ?? "webidUnknown"
        var items = [SKBarButtonItem]()
        DocsLogger.info("start build barButtonItems for \(editorIdentity), target \(infos.count)")
        for originInfo in infos {
            let info = additionSetup(for: originInfo)
            let aSelector = selector(uid: "docs_js_barbutton_command_\(ObjectIdentifier(target))_" + info.id, classes: targetClasses, block: info.callback)
            let item: SKBarButtonItem
            if let text = info.text, let image = info.image {
                DocsLogger.info("build barButtonItem for \(editorIdentity), image&title")
                item = SKBarButtonItem(image: image,
                                       style: .plain,
                                       target: target,
                                       action: aSelector)
                item.title = text
                _set(item, with: info)
            } else if let text = info.text {
                DocsLogger.info("build barButtonItem for \(editorIdentity), only title")
                item = SKBarButtonItem(title: text,
                                       style: .plain,
                                       target: target,
                                       action: aSelector)
                _set(item, with: info)
            } else if let image = info.image {
                DocsLogger.info("build barButtonItem for \(editorIdentity), got image")
                item = SKBarButtonItem(image: image,
                                       style: .plain,
                                       target: target,
                                       action: aSelector)
                _set(item, with: info)
            } else {
                DocsLogger.info("build barButtonItem for \(editorIdentity), no title or image, fail")
                continue
            }
            items.append(item)
        }
        DocsLogger.info("end build barButtonItems for \(editorIdentity), got \(items.count)")
        return items
    }
    
    private func _set(_ item: SKBarButtonItem, with info: MenuInfo) {
        item.id = info.naviBarID
        item.isEnabled = !info.disabled
        item.foregroundColorMapping = translateColorMapping(info.customColorMapping)
        guard info.image != nil else { return }
        if info.useOriginImageRendering {
            item.useOriginRenderedImage = true
            item.image = info.image
        }
        item.isInSelection = info.selected
        item.badgeStyle = info.badgeStyle
    }

    private func _skNaviBarButtonID(for str: String) -> SKNavigationBar.ButtonIdentifier {
        return [
            // text
            "PUBLISH_ANNOUNCEMENT": .publishAnnouncement, // 群公告 doc 右边按钮
            // image
            "HISTORY_RECORD": .history, // 群公告阅读态按钮
            "SHARE": .share, // 分享
            "MESSAGE": .feed, // 铃铛
            "MORE_OPERATE": .more, // 三个点
            "SEARCH": .findAndReplace, // 查找 (Sheet & Bitable)
            "COMMENT": .comment, // 评论 (iPad)
            "UNDO": .undo, // 撤销
            "REDO": .redo, // 重做
            "OUTLINE": .outline, // mindnote 大纲模式
            "MINDMAP": .mindmap, // mindnote 导图模式
            "SLIDE_EXPORT_CHECK_DOWN": .checked, // slide
            "SLIDE_EXPORT_CHECK_NOR": .unchecked, // slide
            "SCREEN_ORIENTATION_OPERATE": .orientation, // 切换横竖屏
            "CLOSE": .close, //叉号按钮
            "BASE_MORE": .baseMore, // Bitable新的more
            "VC_SHARE": .vcShare,
            "COPY": .copy,
            "FORWARD": .forward,
            "SYNCED_BLOCK_REFERENCES": .syncedReferences
        ][str] ?? .unknown(str)
    }

    private var _iconNameMapping: [String: UDIconType] {
        return [
            "HISTORY_RECORD": .historyOutlined,
            "SHARE": .shareOutlined,
            "MESSAGE": .bellOutlined,
            "MORE_OPERATE": .moreOutlined,
            "SEARCH": .findAndReplaceOutlined,
            "COMMENT": .addCommentOutlined,
            "UNDO": .undoOutlined,
            "REDO": .redoOutlined,
            "OUTLINE": .outlineOutlined,
            "MINDMAP": .mindmapOutlined,
            "SLIDE_EXPORT_CHECK_DOWN": .feedReadOutlined, // 这两个图标没找到使用场景，先用类似的替换
            "SLIDE_EXPORT_CHECK_NOR": .feedUnreadOutlined,
            "SECRET": .safeSettingsOutlined,
            "SCREEN_ORIENTATION_OPERATE": .landscapeModeColorful,
            "CLOSE": .closeOutlined,
            "BASE_MORE": .moreOutlined,
            "VC_SHARE": .shareScreenOutlined,
            "COPY": .copyOutlined,
            "FORWARD": .forwardOutlined,
            "SYNCED_BLOCK_REFERENCES": .linkRecordOutlined
        ]
    }

    private func _getIconID(from id: String) -> UDIconType? {
        return _iconNameMapping[id.uppercased()]
    }

    private func translateColorMapping(_ colors: [UIColor]?) -> [UIControl.State: UIColor]? {
        guard let colors = colors, colors.count == 4 else {
            DocsLogger.info("前端没有传正确的 bar button item 的 customColor 过来")
            return nil
        }
        return [
            .normal: colors[0],
            .highlighted: colors[1],
            .disabled: colors[2],
            .selected: colors[3],
            [.selected, .highlighted]: colors[1]
        ]
    }
}

// BTW: 我不想这样子写，但是安卓是这样写的，产品侧暂时没人力去梳理这块，后续会安排专项去搞(希望有吧)
extension NavigationMenuService {
    private func addMoreRedPointIfNeeded(info: MenuInfo) -> MenuInfo {
        // 曾经点击过红点，不再显示
        guard !hasShowMoreBadge else { return info }
        // 按钮被禁用，不展示红点
        guard !info.disabled else { return info }
        guard info.id.uppercased() == "MORE_OPERATE" else { return info }
        // 前端没有做控制的话
        guard info.badgeStyle == nil else { return info }
        // 判断是否需要显示
        guard CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.navMoreNewTag) == false else {
            return info
        }
        var newInfo = info
        newInfo.badgeStyle = .dot
        let oldCallback = info.callback
        newInfo.callback = { [weak self] in
            self?.hasShowMoreBadge = true
            CCMKeyValue.globalUserDefault.set(true, forKey: UserDefaultKeys.navMoreNewTag)
            if let lastInfos = self?.lastInfos {
                self?.resetItems(with: lastInfos)
            }
            oldCallback()
        }
        return newInfo
    }
}

extension NavigationMenuService {
    /// 监听影子文件的more菜单状态，控制more按钮的显示/隐藏
    private func observeShadowFileMoreItemChanged() {
        disposeBag = DisposeBag()
        guard let shadowFileId = docsInfo?.shadowFileId else { return }
        guard let shadowFileMgr = DocsContainer.shared.resolve(DriveShadowFileManagerProtocol.self) else { return }
        let (itemEnabled, itemVisable) = shadowFileMgr.getMoreItemState(id: shadowFileId)
        itemEnabled.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] itemEnabled in
            DocsLogger.info("==drive== shadow file naviMenu moreItemEnabled: \(itemEnabled)")
            guard let lastInfo = self?.lastInfos else { return }
            self?.resetItems(with: lastInfo)
        }).disposed(by: disposeBag)
        itemVisable.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] itemVisable in
            DocsLogger.info("==drive== shadow file naviMenu moreItemVisable: \(itemVisable)")
            guard let lastInfo = self?.lastInfos else { return }
            self?.resetItems(with: lastInfo)
        }).disposed(by: disposeBag)
    }

    /// 根据影子Drive文件配置more按钮的显示或置灰
    private func setupShadowFileMoreItemIfNeed(menuInfos: inout [MenuInfo]) {
        guard let shadowFileId = docsInfo?.shadowFileId else { return }
        guard let shadowFileMgr = DocsContainer.shared.resolve(DriveShadowFileManagerProtocol.self) else { return }
        let (itemEnabled, itemVisable) = shadowFileMgr.getMoreItemState(id: shadowFileId)
        let isMoreVisable = itemVisable.value
        let isMoreEnable = itemEnabled.value
        if isMoreVisable {
            if let index = menuInfos.firstIndex(where: { $0.naviBarID == .more }) {
                menuInfos[index].disabled = !isMoreEnable
            }
        } else {
            menuInfos.removeAll(where: { $0.naviBarID == .more })
        }
    }
}
