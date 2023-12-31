//
//  SheetSetTabsService.swift
//  SpaceKit
//
//  Created by 段晓琛 on 2019/7/16.
//

import Foundation
import SKCommon
import SKBrowser
import SKFoundation
import SKInfra

protocol ShowSheetTabsDelegate: AnyObject {
    var jsEngine: BrowserJSEngine { get }
    var tabSwitcher: SheetTabSwitcherView { get }
    func showTabSwitcher()
    func hideTabSwitcher()
}

extension SheetBrowserViewController: ShowSheetTabsDelegate {

    var jsEngine: BrowserJSEngine {
        return self.editor
    }

    func showTabSwitcher() {
        sheetTopContainer.tabSwitcherTransitioner.onNext((hidden: false, animated: false))
    }

    func hideTabSwitcher() {
        sheetTopContainer.tabSwitcherTransitioner.onNext((hidden: true, animated: false))
    }
}

class SheetTabService: BaseJSService {
    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        model.browserViewLifeCycleEvent.addObserver(self)
    }
}

extension SheetTabService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [.sheetSetTabs]
    }

    func handle(params: [String: Any], serviceName: String) {
        guard let delegate = registeredVC as? SheetBrowserViewController else {
            DocsLogger.info("🧶当前 VC 不符合要求，delegate 设置失败")
                return
        }
        guard let tabs = params["data"] as? [[String: Any]], !tabs.isEmpty else {
            DocsLogger.debug("🧶前端啥都没传，要隐藏工作表")
            delegate.hideTabSwitcher()
            return
        }
        let tabEditable = params["editable"] as? Bool ?? false
        let sheetEditable = sheetEditPermission()
        let callback = params["callback"] as? String ?? ""
        var tabInfos: [SheetTabInfo] = []
        var index = 0
        tabs.forEach { (tab) in
            if let name = tab["name"] as? String, let id = tab["id"] as? String,
                let hidden = tab["hidden"] as? Bool, let locked = tab["locked"] as? Bool,
                let selected = tab["isSelected"] as? Bool,
                let enabled = tab["enabled"] as? Bool {
                if hidden {
                    DocsLogger.debug("🧶这个表要被隐藏")
                } else {
                    let customIcon = tab["customIcon"] as? [String: Any]
                    let info = SheetTabInfo(index: index, text: name, id: id, editable: tabEditable, isHidden: hidden, isLocked: locked, isSelected: selected, customIcon: customIcon, enabled: enabled)
                    tabInfos.append(info)
                    index += 1
                }
            }
        }
        delegate.tabSwitcher.update(infos: tabInfos,
                                    tabEditable: tabEditable,
                                    sheetEditable: sheetEditable,
                                    callback: callback,
                                    canShowExitLandscapeButton: !self.isInVideoConference)
        delegate.tabSwitcher.delegate = delegate
        delegate.tabSwitcher.forbidDropDelegate = delegate
        delegate.showTabSwitcher()
    }

    private func sheetEditPermission() -> Bool {
        guard let sheetFileToken = model?.hostBrowserInfo.docsInfo?.token else {
            return false
        }
        if sheetFileToken.isFakeToken {
            return true
        }
        if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation,
           let service = model?.permissionConfig.getPermissionService(for: .hostDocument) {
            let result = service.validate(operation: .moveSheetTab)
            return result.allow
        } else {
            guard let permissionManager = DocsContainer.shared.resolve(PermissionManager.self),
                  let userPermission = permissionManager.getUserPermissions(for: sheetFileToken) else {
                return false
            }
            return userPermission.canEdit()
        }
    }
}

extension SheetTabService: BrowserViewLifeCycleEvent {
    func browserWillTransition(from: CGSize, to: CGSize) {
        DispatchQueue.main.async { [weak self] in
            guard let delegate = self?.registeredVC as? ShowSheetTabsDelegate else { return }
            delegate.tabSwitcher.scrollToSelectedItem()
        }
    }
}
