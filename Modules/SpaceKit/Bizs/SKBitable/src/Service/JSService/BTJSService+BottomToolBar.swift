//
//  BTJSService+BottomToolBar.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/7/11.
//  


import SKFoundation
import SKCommon
import SKBrowser
import SKUIKit
import UIKit

struct BTBottomToolBarParams: Codable, BTEventBaseDataType {
    var baseId: String = ""
    var tableId: String = ""
    var viewId: String = ""
    var callback: String = ""
    var menus: [BTBottomToolBarItemModel] = []
    // 看看数据是否一致。
    func isSameData(to other: BTBottomToolBarParams) -> Bool {
        return baseId == other.baseId &&
        tableId == other.tableId &&
        viewId == other.viewId &&
        menus == other.menus
    }
}

extension BTJSService {
    /// 由 services 触发 展示底部 toolbar
    private func showToolBar(params: BTBottomToolBarParams) {
        guard let hostVC = registeredVC as? BrowserViewController else {
            DocsLogger.btError("[SYNC] not in BrowserViewController")
            hideToolBar()
            return
        }
        guard !toolbarsContainer.toolbarParams.isSameData(to: params) else {
            return
        }
        bottomToolBarTrack(.view(isShow: true), baseData: nil)
        params.menus.map { model in
            if let hasInvalidCondition = model.hasInvalidCondition {
                let type = model.itemType.rawValue.lowercased()
                bottomToolBarTrack(.tipsView(reason: "limited_premium_permission", type: type), baseData: nil)

            }
        }
        toolbarsContainer.updateToolbar(params: params)
        relayoutToolbarsContainer(browserVC: hostVC, cardVC: cardVC)
        
        setLayoutUserGuideRectIfNeeded(params)
    }
    
    // 设置表格视图卡片样式入口的默认引导位置，此位置可能会被前端给的位置更新
    private func setLayoutUserGuideRectIfNeeded(_ params: BTBottomToolBarParams) {
        guard params.menus.contains(where: { $0.itemType == .layout }) else {
            // 没有布局按钮，无需设置
            return
        }
        // 未开启移动端默认卡片视图，引导位置设置在 Toolbar 的 itemView 上
        guard let layoutItemView = toolbarsContainer.toolbarView.itemView(for: .layout),
              let bvc = registeredVC as? BitableBrowserViewController else {
            DocsLogger.error("table layout item onBoarding rect set failed!", component: BTTableLayoutLogTag)
            return
        }
        toolbarsContainer.superview?.layoutIfNeeded()
        let itemRect = layoutItemView.convert(layoutItemView.bounds, to: bvc.view)
        bvc.onboardingTargetRects[.mobileBitableGridMobileView2] = itemRect
        DocsLogger.info("table layout item onBoarding rect set: \(itemRect)", component: BTTableLayoutLogTag)
    }
    
    /// 由 services 触发隐藏底部 toolbar
    func hideToolBar() {
        toolbarsContainer.updateToolbar(params: BTBottomToolBarParams())
    }
    /// 由用户动作触发显示隐藏底部 toolbar
    func setToolbarHide(_ isHidden: Bool, animted: Bool) {
        // 只有当前工具栏当前状态和需要转变的状态不一致才做处理
        guard isHidden != toolbarsContainer.isToolbarHide else {
            return
        }
        let baseData = BTBaseData(baseId: toolbarsContainer.toolbarParams.baseId,
                                  tableId: toolbarsContainer.toolbarParams.tableId,
                                  viewId: toolbarsContainer.toolbarParams.viewId)
        bottomToolBarTrack(.view(isShow: !isHidden), baseData: baseData)
        toolbarsContainer.setToolbarHide(isHidden, animated: animted)
    }
}

// MARK: - BTBottomToolbarDelegate
extension BTJSService: BTBottomToolbarDelegate {
    /// 底部工具栏点击响应
    func bottomToolbar(_ toolbar: BTBottomToolBar, didSelect item: BTBottomToolBarItemModel) {
        DocsLogger.btInfo("bottomToolbard didSelcted \(item.id)")
        let params = ["id": item.id]
        let baseData = BTBaseData(baseId: toolbarsContainer.toolbarParams.baseId, tableId: toolbarsContainer.toolbarParams.tableId, viewId: toolbarsContainer.toolbarParams.viewId)
        bottomToolBarTrack(.click(item: item), baseData: baseData)
        model?.jsEngine.callFunction(toolbarsContainer.toolbarCallback, params: params, completion: nil)
    }
}

// MARK: - 监控 UIEvent，监控 move 手势
extension BTJSService {
    
    func startUIEventMonitor() {
        guard let ancestorView = (self.ui?.editorView as? DocsWebViewProtocol)?.contentView ?? self.ui?.editorView else {
            DocsLogger.btError("startMonitor get ancestorView error")
            return
        }
        uiEventMonitor = BTUIEventMonitor(ancestorView: ancestorView)
        uiEventMonitor?.didReceiveMove = {[weak self] moveTranslaction in
            self?.handleTranslaction(moveTranslaction)
        }
    }
    
    func stopUIEventMonitor() {
        uiEventMonitor = nil
    }
    
    private func handleTranslaction(_ translation: CGPoint) {
        let direction = TranslationDirectionDetector.detect(translation)
        handleDirection(direction)
    }
    
    private func handleDirection(_ direction: TranslationDirectionDetector.ScrollDirection) {
        switch direction {
        case .up:
            self.setToolbarHide(true, animted: true)
        case .down:
            self.setToolbarHide(false, animted: true)
        default: break
        }
    }
}

// MARK: - event track
extension BTJSService {
    
    enum BottomToolBarEventType {
        case view(isShow: Bool)
        case click(item: BTBottomToolBarItemModel)
        case tipsView(reason: String, type: String)
    }
    
    func bottomToolBarTrack(_ evenType: BottomToolBarEventType, baseData: BTBaseData?) {
        var commonParams = BTEventParamsGenerator.createCommonParams(by: model?.hostBrowserInfo.docsInfo,
                                                                     baseData: baseData ?? toolbarsContainer.toolbarParams)
        let baseId = baseData?.baseId ?? toolbarsContainer.toolbarParams.baseId
        if let type = BTGlobalTableInfo.currentViewInfoForBase(baseId)?.gridViewLayoutType {
            commonParams[BTTableLayoutSettings.ViewType.trackKey] = type.trackValue
            if type == .card, UserScopeNoChangeFG.XM.nativeCardViewEnable {
                commonParams.merge(other: CardViewConstant.commonParams)
            }
        } else {
            commonParams[BTTableLayoutSettings.ViewType.trackKey] = BTTableLayoutSettings.ViewType.classic.trackValue
        }
        switch evenType {
        case .view(let isShow):
            if toolbarsContainer.isToolbarHide, isShow {
                DocsTracker.newLog(enumEvent: .bitableFilterSortBoardView, parameters: commonParams)
            }
        case .click(let item):
            commonParams.updateValue(item.id.lowercased(), forKey: "click")
            commonParams.updateValue(item.trackTarget, forKey: "target")
            commonParams.updateValue(DocsTracker.toString(value: item.hasInvalidCondition), forKey: "is_premium_limited")
            DocsTracker.newLog(enumEvent: .bitableFilterSortBoardClick, parameters: commonParams)
        case let .tipsView(reason, type):
            commonParams.updateValue(reason, forKey: "reason")
            commonParams.updateValue(type, forKey: "limit_type")
            DocsTracker.newLog(enumEvent: .bitableToolbarLimitedTips, parameters: commonParams)
        }
    }
}
