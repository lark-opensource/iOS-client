//
//  BTJSService+More.swift
//  SKBitable
//
//  Created by X-MAN on 2023/9/1.
//

import Foundation
import SKFoundation
import UniverseDesignMenu
import UniverseDesignIcon
import SKCommon
import SKUIKit

fileprivate struct MoreMenuItem: Codable {
    var id: String
    var enable: Bool
    var name: String
}

fileprivate struct MoreMenuModel: Codable {
    var normalPart: [MoreMenuItem]
    var undoRedo: [MoreMenuItem]
}

fileprivate let iconMapping: [String: UDIconType] = [
    "HISTORY_RECORD": .historyOutlined,
    "SHARE": .shareOutlined,
    "MESSAGE": .bellOutlined,
    "MORE_OPERATE": .appOutlined,
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
    "PRO": .bitableAuthorizationOutlined,
    "FEEDBACK": .editDiscriptionOutlined
]

extension BTJSService {
    func handleMore(_ params: [String: Any]) {
        guard let browser = navigator?.currentBrowserVC as? BitableBrowserViewController else {
            // dismiss
            self.moreMenu?.closeMenu(animated: true)
            self.moreMenu = nil
            DocsLogger.btError("[BTJSService] moreMenu action cant find browser")
            return
        }
        if let hidden = params["hidden"] as? Bool, hidden {
            // dismiss
            self.moreMenu?.closeMenu(animated: true)
            self.moreMenu = nil
            DocsLogger.info("[BTJSService] moreMenu action front end call hidden")
        }
        guard let callback = params["callback"] as? String else {
            // dismiss
            self.moreMenu?.closeMenu(animated: true)
            self.moreMenu = nil
            DocsLogger.error("[BTJSService] moreMenu params without callback")
            return
        }
        do {
            var selectId = ""
            let tapAction: (String) -> Void = { id in
                selectId = id
                // UDMenu消失带动画，立刻回调会导致menu还是当前Controller
            }
            let model = try CodableUtility.decode(MoreMenuModel.self, withJSONObject: params)
            
            let undoRedoActions = model.undoRedo.map { item in
                var icon: UIImage? = nil
                if let iconType = iconMapping[item.id] {
                    icon = UDIcon.getIconByKey(iconType)
                }
                var action = UDMenuAction(title: item.name, icon: icon) {
                    tapAction(item.id)
                }
                action.isDisabled = !item.enable
                return action
            }
            var normalPartActions: [UDMenuAction] = []
            let normalCount = model.normalPart.count
            for (index, item) in model.normalPart.enumerated() {
                var icon: UIImage? = nil
                if let iconType = iconMapping[item.id] {
                    icon = UDIcon.getIconByKey(iconType)
                }
                var action = UDMenuAction(title: item.name, icon: icon) {
                    tapAction(item.id)
                }
                action.isDisabled = !item.enable
                action.showBottomBorder = !undoRedoActions.isEmpty && index == normalCount - 1
                normalPartActions.append(action)
            }
            let actions = normalPartActions + undoRedoActions
            let cofig = UDMenuConfig(position: .bottomAuto)
            var style = UDMenuStyleConfig.defaultConfig()
            // 导航栏的icon时机上范围比较大，这里做个偏移
            style.marginToSourceX = -6
            style.showArrowInPopover = false
            let menu = UDMenu(actions: actions, config: cofig, style: style)
            self.moreMenu = menu
            // 倒序的，所以取第一个
            let showMenu = {
                let lastItem = browser.navigationBar.trailingBarButtonItems.first(where: { $0.id == .baseMore })?.associatedButton
                menu.showMenu(sourceView: lastItem ?? browser.navigationBar, sourceVC: browser, dismissed:  {
                    [weak self] in
                    guard let self = self else { return }
                    self.moreMenu = nil
                    if selectId.isEmpty {
                        DocsLogger.error("[BTJSService] moreMenu params select is empty")
                        return
                    }
                    DispatchQueue.main.async {
                        guard let model = self.model else {
                            DocsLogger.error("[BTJSService] moreMenu BrowserModelConfig is nil")
                            return
                        }
                        // menu 消失带动画，就这么处理吧
                        model.jsEngine.callFunction(DocsJSCallBack(callback), params: ["id": selectId], completion: nil)
                        model.docComponentDelegate?.docComponentHost(self.docComponentHost,
                                                                           onEvent: .onNavigationItemClick(item: selectId))
                        selectId = ""
                    }
                })
            }
            if SKDisplay.phone {
                // UDMenu 横屏下会自己进入竖屏，所以需要先进入竖屏
                container?.setBlockCatalogueHidden(blockCatalogueHidden: true)
                BTUtil.forceInterfaceOrientationIfNeed(to: .portrait) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showMenu()
                    }
                }
            } else {
                showMenu()
            }
            
        } catch let error {
            DocsLogger.btError("[BTJSService] more action data invalid \(error)")
            return
        }
    }
}
