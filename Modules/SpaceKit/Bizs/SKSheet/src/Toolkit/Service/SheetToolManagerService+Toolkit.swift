//
//  SheetToolManagerService+toolkit.swift
//  SpaceKit
//
//  Created by Webster on 2019/7/28.
//

import SKCommon
import SKBrowser

extension SheetToolManagerService {
    func handlePanelInfo(_ params: [String: Any]) {
        guard let open = params["forceOpen"] as? Bool, let callBack = params["callback"] as? String else { return }
        guard let data = params["data"] as? [[String: Any]], data.count > 0 else {
            rangeType = nil
            mustDisplayToolkit = false
            manager.removeToolkitView(trigger: DocsKeyboardTrigger.sheetOperation.rawValue)
            return
        }
        manager.toolGuideIdentifiers = params["badges"] as? [String]
        toolkitRedirectURL = params["uri"] as? String ?? ""
        guard registeredVC?.view != nil else { return }
        toolJsMethod = callBack
        mustDisplayToolkit = (params["showEditButton"] as? Bool) ?? false
        manager.updateKeyboardButtonIfShowToolkit(container: registeredVC?.view, show: mustDisplayToolkit)
        if let sType = params["rangeType"] as? String {
            rangeType = SheetRangeType(rawValue: sType)
        }
        reloadToolkitInfos(data: data)
        manager.updateToolkit(infos: toolkitInfos)

        if open, !toolkitRedirectURL.isEmpty {
            redirectToURL(url: toolkitRedirectURL)
        } else if open {
            showToolkitView()
        }
    }

    private func reloadToolkitInfos(data: [[String: Any]]) {
        toolkitInfos.removeAll()
        for tapInfo in data {
            var tapModel = SheetToolkitTapItem()
            tapModel.tapId = (tapInfo["id"] as? String) ?? ""
            tapModel.title = (tapInfo["title"] as? String) ?? ""
            tapModel.enable = (tapInfo["enable"] as? Bool) ?? true
            if let subItems = tapInfo["items"] as? [[String: Any]] {
                for item in subItems {
                    guard let sId = item["id"] as? String else { continue }
                    let groupID = item["groupId"] as? String
                    let model = ToolBarItemInfo(identifier: sId, json: item)
                    model.parentIdentifier = groupID ?? sId
                    if let childrenInfos = item["items"] as? [[String: Any]] {
                        model.children = [ToolBarItemInfo]()
                        for childDict in childrenInfos {
                            let parentId = childDict["groupId"] as? String
                            if let newId = childDict["id"] as? String {
                                let childItem = ToolBarItemInfo(identifier: newId, json: childDict)
                                childItem.parentIdentifier = parentId ?? newId
                                model.children?.append(childItem)
                            }
                        }
                    }
                    tapModel.items.append((sId, model))
                }
            }
            toolkitInfos.append(tapModel)
        }
    }

    func redirectToURL(url: String) {
        guard let docsBrowserVC = registeredVC as? BrowserViewController else { return }
        manager.show(url, on: docsBrowserVC.view) { [weak docsBrowserVC, weak manager] in
            guard let toolkitView = manager?.navigationController?.view, let browserView = docsBrowserVC?.view else { return }
            let toolkitFrameInBrowser = toolkitView.convert(toolkitView.bounds, to: browserView)
            if toolkitFrameInBrowser != .zero {
                docsBrowserVC?.onboardingTargetRects[.sheetOperationPanelOperate] = toolkitFrameInBrowser
                OnboardingManager.shared.targetView(for: [.sheetOperationPanelOperate], updatedExistence: true)
            }
        }
    }

    func showToolkitView() {
        guard let docsBrowserVC = registeredVC as? BrowserViewController else { return }
        manager.displayToolkit(on: docsBrowserVC.view,
                               animated: true,
                               infos: toolkitInfos,
                               showToolkitButton: mustDisplayToolkit) { [weak docsBrowserVC, weak manager] in
            guard let toolkitView = manager?.navigationController?.view, let browserView = docsBrowserVC?.view else { return }
            let toolkitFrameInBrowser = toolkitView.convert(toolkitView.bounds, to: browserView)
            if toolkitFrameInBrowser != .zero {
                docsBrowserVC?.onboardingTargetRects[.sheetOperationPanelOperate] = toolkitFrameInBrowser
                OnboardingManager.shared.targetView(for: [.sheetOperationPanelOperate], updatedExistence: true)
            }
        }
    }

    func clearBorderPanel() {
        manager.resetBorderPanel()
    }
}
