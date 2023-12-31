//
//  SheetToolkitManager+Navigation.swift
//  SpaceKit
//
//  Created by Webster on 2019/10/16.
//

import Foundation
import SKCommon
import SKBrowser

extension SheetToolkitManager {
    /// 根据 URI 来定位到目标 view controller
    func show(_ panelURL: String, on view: UIView, animated: Bool? = true, completion: (() -> Void)? = nil) {
        guard let url = URL(string: panelURL),
            url.scheme == "sheetpanel",
            url.host == "client" else { return }
        let paths = url.pathComponents.filter { $0 != "/" }
        if paths.count == 0 { return }
        let context = url.queryParameters
        let withAnimator = animated ?? false
        superWidth = view.frame.size.width
        superHeight = view.frame.size.height
        if navigationController != nil { // 如果 navigationController 存在，则直接操作它的 viewControllers
            let oldViewStack = navigationController?.viewControllers
            var newViewStack = [UIViewController]()
            for path in paths {
                let oldVC = oldViewStack?.first(where: {
                    let identifier = ($0 as? SheetBaseToolkitViewController)?.resourceIdentifier
                    return identifier == path
                })
                if let realOldVC = oldVC {
                    newViewStack.append(realOldVC) // newViewStack 会从根节点到子节点依次插入页面，符合 push 和 pop 的顺序
                    refreshPanel(identifier: path)
                } else {
                    if let newVC = makePanel(path, context: context) {
                        storeWeakRefer(path, vc: newVC)
                        refreshPanel(identifier: path)
                        newViewStack.append(newVC)
                    }
                }
            }
            navigationController?.viewControllers = newViewStack
        } else {
            cleanView()
            let navigator = SheetToolkitNavigationController()
            navigationController = navigator
            navigator.gestureDelegate = self
            navigator.navigationDelegate = self
            navigator.preferredContentSize = CGSize(width: contentMaxWidth, height: viewHeight)
            var newViewStack = [UIViewController]()
            for path in paths {
                if let newVC = makePanel(path, context: context) {
                    storeWeakRefer(path, vc: newVC)
                    refreshPanel(identifier: path)
                    newViewStack.append(newVC)
                    if let vc = newVC as? SheetToolkitContainerViewController {
                        backView.delegate = vc
                    }
                }
                
            }
            navigator.viewControllers = newViewStack
            navigator.view.frame = hiddenRect
            backView.frame = CGRect(x: 0, y: superHeight, width: superWidth, height: viewHeight + assistButtonHeight + assistButtonPadding)
            view.addSubview(backView)
            view.addSubview(navigator.view)
            displayKeyboardFAB(on: view, show: true, outside: true)
            UIView.animate(withDuration: withAnimator ? 0.20 : 0.0, delay: 0, options: .curveEaseOut) {
                navigator.view.frame = self.defaultRect
                self.backView.frame = CGRect(origin: CGPoint(x: 0, y: self.defaultRect.origin.y), size: self.backView.frame.size)
                self.quickKeyboardBtn?.frame = self.assistButtonDefaultRect
            } completion: { completed in
                if completed {
                    completion?()
                }
            }
            reportPanel(height: showInnerHeight, show: true, trigger: DocsKeyboardTrigger.sheetOperation.rawValue)
        }

        //处理context
        if let panelIndex = context[SheetPanelContextKey.panelIndex] {
            containerVC?.showView(identitifer: panelIndex)
        }
    }

    /// 直接显示一级页面
    func displayToolkit(on view: UIView,
                        animated: Bool?,
                        infos: [SheetToolkitTapItem],
                        showToolkitButton: Bool?,
                        completion: (() -> Void)? = nil) {
        let withAnimator = animated ?? false
        superWidth = view.frame.size.width
        superHeight = view.frame.size.height
        toolInfos = infos
        if isShowingToolkit() {
            refreshPanel(identifier: BadgedItemIdentifier.toolkit.rawValue)
            return
        }
        cleanView()
        let vc = makePanel(BadgedItemIdentifier.toolkit.rawValue, context: [SheetPanelContextKey.tookkitBack: "0"]) as? SheetToolkitContainerViewController
        guard let toolkitVC = vc else { return }
        backView.delegate = toolkitVC
        containerVC = vc
        refreshPanel(identifier: BadgedItemIdentifier.toolkit.rawValue)
        let navigator = SheetToolkitNavigationController()
        navigator.gestureDelegate = self
        navigator.navigationDelegate = self
        navigator.preferredContentSize = CGSize(width: contentMaxWidth, height: viewHeight)
        navigator.viewControllers = [toolkitVC]
        view.addSubview(backView)
        view.addSubview(navigator.view)
        backView.frame = CGRect(x: 0, y: superHeight, width: superWidth, height: viewHeight + assistButtonHeight + assistButtonPadding)
        navigationController?.view.frame = hiddenRect
        navigationController = navigator
        displayKeyboardFAB(on: view, show: showToolkitButton ?? false, outside: true)
        UIView.animate(withDuration: withAnimator ? 0.25 : 0.0, delay: 0, options: .curveEaseOut) {
            self.navigationController?.view.frame = self.defaultRect
            self.backView.frame = CGRect(origin: CGPoint(x: 0, y: self.defaultRect.origin.y), size: self.backView.frame.size)
            self.quickKeyboardBtn?.frame = self.assistButtonDefaultRect
        } completion: { (completed) in
            if completed {
                completion?()
            }
        }
        reportPanel(height: showInnerHeight, show: true, trigger: DocsKeyboardTrigger.sheetOperation.rawValue)
    }

    func updateToolkit(infos: [SheetToolkitTapItem]) {
        toolInfos = infos
        refreshPanel(identifier: BadgedItemIdentifier.toolkit.rawValue)
        refreshPanel(identifier: BadgedItemIdentifier.freeze.rawValue)
        refreshPanel(identifier: BadgedItemIdentifier.filter.rawValue)
    }

    func toolkitContainerPush(_ panelIdentifier: String, animated: Bool = true, tryReuse: Bool = false) {
        guard let navigatorStack = navigationController?.viewControllers else { return }
        if tryReuse, let reuseIndex = existIndex(of: panelIdentifier) {
            var newStack = [UIViewController]()
            for j in 0...reuseIndex { newStack.append(navigatorStack[j]) }
            navigationController?.viewControllers = newStack
        } else {
            if let newVC = makePanel(panelIdentifier) {
                storeWeakRefer(panelIdentifier, vc: newVC)
                refreshPanel(identifier: panelIdentifier)
                navigationController?.docsPushViewController(newVC, animated: animated)
            }
        }
    }

    /// 寻找导航栈里的资源索引
    ///
    /// - Parameter panel: 资源标识
    /// - Returns: 资源索引
    private func existIndex(of panel: String) -> Int? {
        guard let navigatorStack = navigationController?.viewControllers, navigatorStack.count > 0 else { return nil }
        var reuseIndex: Int?
        for (index, vc) in navigatorStack.enumerated() {
            if let resourceVC = vc as? SheetBaseToolkitViewController, resourceVC.resourceIdentifier == panel {
                reuseIndex = index
                break
            }
        }
        return reuseIndex
    }

    func makePanel(_ panelIdentifier: String, context: [String: Any] = [:]) -> SheetBaseToolkitViewController? {
        guard let kindOfPanel = BadgedItemIdentifier(rawValue: panelIdentifier) else { return nil }
        switch kindOfPanel {
        case .toolkit:
            let toolkitVC = SheetToolkitContainerViewController(superWidth: superWidth, maxWidth: self.maxWidth)
            toolkitVC.delegate = self
            toolkitVC.badgeDelegate = self
            toolkitVC.preferredContentSize = CGSize(width: contentMaxWidth, height: viewHeight)
            return toolkitVC
        case .freeze:
            let vc = SheetFreezeViewController(info: freezeInfo())
            vc.delegate = self
            return vc
        case .filter:
            let vc = SheetFilterFacadeViewController(info: filterInfo(), preferWidth: contentMaxWidth)
            vc.delegate = self
            return vc
        case .filterValue:
            let info = specialFilterInfo(.byValue) ?? SheetFilterInfo(filterType: .byValue)
            let vc = SheetFilterByValueViewController(info, contentMaxWidth)
            vc.valueDelegate = self
            vc.delegate = self
            return vc
        case .filterColor:
            let info = specialFilterInfo(.byColor) ?? SheetFilterInfo(filterType: .byColor)
            let vc = SheetFilterByColorController(info)
            vc.delegate = self
            return vc
        case .filterCondition:
            let info = specialFilterInfo(.byCondition) ?? SheetFilterInfo(filterType: .byCondition)
            let vc = SheetFilterByConditionController(info)
            vc.delegate = self
            return vc
        case .uploadImage:
            let vc = SheetUploadImageViewController(delegate: self, info: uploadImageInfo())
            let oldFrame = navigationController?.view.frame ?? .zero
            navigationController?.view.frame = CGRect(x: 0, y: oldFrame.minY, width: superWidth, height: oldFrame.height)
            return vc
        default:
            return nil
        }
    }

    func storeWeakRefer(_ panelIdentifier: String, vc: SheetBaseToolkitViewController) {
        guard let kindOfPanel = BadgedItemIdentifier(rawValue: panelIdentifier) else { return }
        switch kindOfPanel {
        case .toolkit:
            containerVC = vc as? SheetToolkitContainerViewController
        case .freeze:
            freezeVC = vc as? SheetFreezeViewController
        case .filter:
            filterFacadeVC = vc as? SheetFilterFacadeViewController
        case .filterCondition, .filterValue, .filterColor:
            filterVC = vc as? SheetFilterDetailViewController
        case .uploadImage:
            uploadImageVC = vc as? SheetUploadImageViewController
        default:
            ()
        }
    }

    func refreshPanel(identifier: String) {
        guard let kindOfPanel = BadgedItemIdentifier(rawValue: identifier) else { return }
        switch kindOfPanel {
        case .toolkit:
            containerVC?.updateStatus(toolInfos)
        case .freeze:
            freezeVC?.update(freezeInfo())
        case .filter:
            filterFacadeVC?.update(filterInfo())
        case .filterCondition, .filterColor, .filterValue:
            if let type = filterVC?.filterInfo.filterType, let info = specialFilterInfo(type) {
                filterVC?.update(info)
            }
        default:
            ()
        }
    }

    func hideToolkitView(_ completed: FloatModifyFinishBlock? = nil, immediately: Bool = false) {
        
        func animateAction() {
            self.navigationController?.view.frame = self.hiddenRect
            self.backView.frame = CGRect(origin: CGPoint(x: 0, y: self.hiddenRect.origin.y), size: CGSize(width: self.backView.frame.size.width, height: self.hiddenRect.height))
            self.navigationController?.view.superview?.layoutIfNeeded()
            self.quickKeyboardBtn?.frame = self.assistButtonHiddenRect
        }
        
        func animateCompletionAction() {
            self.cleanView()
            OnboardingManager.shared.targetView(for: [.sheetOperationPanelOperate], updatedExistence: false)
            self.reportPanel(height: self.hiddenInnerHeight, show: false, trigger: DocsKeyboardTrigger.sheetOperation.rawValue)
        }
        if immediately {
            animateAction()
            animateCompletionAction()
        } else {
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
                animateAction()
            }, completion: { _ in
                animateCompletionAction()
                completed?()
            })
        }
    }

    func removeToolkitView(trigger: String) {
        guard isShowingToolkit() else { return }
        cleanView()
        reportPanel(height: hiddenInnerHeight, show: false, trigger: trigger)
        SheetTracker.report(event: .closeToolbox(action: 1), docsInfo: self.docsInfo)
    }

    func removeAllView(trigger: String) {
        cleanView()
        reportPanel(height: hiddenInnerHeight, show: false, trigger: trigger)
    }


    func cleanView() {
        self.backView.removeFromSuperview()
        self.navigationController?.view.removeFromSuperview()
        self.navigationController?.popToRootViewController(animated: false)
        self.navigationController = nil
        self.containerVC = nil
        self.freezeVC = nil
        self.filterVC = nil
        self.filterFacadeVC = nil
        self.uploadImageVC = nil
        self.fabButtonPanel?.isHidden = false
        self.removeKeyboardFAB()
    }
    
    private func uploadImageInfo() -> ToolBarItemInfo {
        let viewInfo = toolInfos.first { $0.tapId == ToolkitViewType.insert.rawValue }
        let defaultInfo = ToolBarItemInfo(identifier: BarButtonIdentifier.uploadImage.rawValue)
        return viewInfo?.info(for: BarButtonIdentifier.uploadImage.rawValue) ?? defaultInfo
    }

    private func freezeInfo() -> ToolBarItemInfo {
        let viewInfo = toolInfos.first { $0.tapId == ToolkitViewType.operation.rawValue }
        let defaultInfo = ToolBarItemInfo(identifier: BarButtonIdentifier.freeze.rawValue)
        return viewInfo?.info(for: BarButtonIdentifier.freeze.rawValue) ?? defaultInfo
    }

    private func filterInfo() -> ToolBarItemInfo {
        let viewInfo = toolInfos.first { $0.tapId == ToolkitViewType.operation.rawValue }
        let defaultInfo = ToolBarItemInfo(identifier: BarButtonIdentifier.cellFilter.rawValue)
        return viewInfo?.info(for: BarButtonIdentifier.cellFilter.rawValue) ?? defaultInfo
    }

    private func specialFilterInfo(_ type: SheetFilterType) -> SheetFilterInfo? {
        return filterDetailInfo[type]
    }
}

extension SheetToolkitManager: SheetBadgeLocator {
    func fetchBadgeList(_ controller: SheetBaseToolkitViewController) -> Set<String>? {
        let toolGuideSets = Set<String>(toolGuideIdentifiers ?? [String]())
        return toolGuideSets
    }

    func finishBadges(identifiers: [String], controller: SheetBaseToolkitViewController) {
        guard identifiers.count > 0 else { return }
        let params: [String: Any] = ["panelName": controller.resourceIdentifier, "badges": identifiers]
        dataSource?.supportJSEngine(self)?.callFunction(DocsJSCallBack.sheetClearBadges, params: params, completion: nil)
    }
}

extension SheetToolkitManager: SheetToolkitNavigationControllerDelegate {
    func requestPresentNewViewController(_ controller: UIViewController, navigator: SheetToolkitNavigationController) {
        removeToolkitView(trigger: DocsKeyboardTrigger.sheetOperation.rawValue)
    }

    func requestPushNewViewController(_ controller: UIViewController, navigator: SheetToolkitNavigationController) {
        removeToolkitView(trigger: DocsKeyboardTrigger.sheetOperation.rawValue)
    }
}
