//
//  SheetToolkitManager.swift
//  SpaceKit
//
//  Created by Webster on 2019/7/15.
//

import Foundation
import SKCommon
import SKUIKit
import SKBrowser
import SKFoundation

protocol SheetToolkitManagerDelegate: AnyObject {

    //面板点击导航元素
    func toolkitRequestNavigation(identifier: String, value: Any?, viewType: ToolkitViewType, manager: SheetToolkitManager, itemIsEnable: Bool)
    //面板点击切换一级面板
    func toolkitRequestSwitchPanel(_ panelId: String, value: String?, manager: SheetToolkitManager)
    //面板高度更新
    func didChangePanelHeight(_ info: SimulateKeyboardInfo, manager: SheetToolkitManager)
    //拖动显示
    func adjustPanelModel(_ model: SheetToolkitFloatModel, fromToolkit: Bool, manager: SheetToolkitManager)
    //点击了快速操作面板上方的键盘切换
    func didPressAccessoryKeyboard(_ button: FloatButton?, manager: SheetToolkitManager)
    //筛选更新单个数据
    func filterRequestJsUpdateValue(_ identifier: String, value: String?, filterInfo: SheetFilterInfo, manager: SheetToolkitManager)
    //筛选更新range数据
    func filterRequestJsUpdateRange(_ identifier: String, range: [Any]?, filterInfo: SheetFilterInfo, manager: SheetToolkitManager, bySearch: Bool?)
    //按值筛选
    func filterByValueDidPressPanelSearchButton(fromToolkit: Bool, manager: SheetToolkitManager)
    //
    func filterByValueDidPressKeyboardSearchButton(fromToolkit: Bool, manager: SheetToolkitManager)
}

protocol SheetToolkitManagerDataSource: AnyObject {
    var primaryBrowserViewDistanceToWindowBottom: CGFloat { get }
    var statusBarHeight: CGFloat { get }
    var topContainerHeight: CGFloat { get }
    func supportJSEngine(_ manager: SheetToolkitManager) -> BrowserJSEngine?
}

class SheetToolkitManager {
    let assistButtonHeight: CGFloat = 40
    let assistButtonPadding: CGFloat = 16
    let maxWidth: CGFloat = 764
    var superWidth: CGFloat = 0
    var superHeight: CGFloat = 0
    var inhibitsDraggability: Bool? // 按值筛选搜索场景会暂时关闭拖动功能
    var beginPoint: CGPoint = CGPoint.zero
    var navigationController: SheetToolkitNavigationController?
    lazy var backView = SheetToolkitHostView() // 这个 backView 在 iPad 上会比 containerVC.view 大，见 SheetToolkitHostView 文件头注释
    weak var containerVC: SheetToolkitContainerViewController? // 三个一级页面的容器
    weak var filterFacadeVC: SheetFilterFacadeViewController? // 筛选二级页面，可以进入下面的三级页面
    weak var filterVC: SheetFilterDetailViewController? // filterValue、filterColor, filterCondition 三个三级页面
    weak var freezeVC: SheetFreezeViewController? // 冻结二级页面
    weak var delegate: SheetToolkitManagerDelegate?
    weak var dataSource: SheetToolkitManagerDataSource?
    weak var quickKeyboardBtn: FloatSecondaryButton?
    weak var fabButtonPanel: UIView?
    weak var navigator: BrowserNavigator?
    var uploadImageVC: SheetUploadImageViewController? // 避免在转屏后收起工具箱后自动被 deinit，所以不用 weak，会手动设置为 nil
    var toolInfos: [SheetToolkitTapItem] = [SheetToolkitTapItem]()
    var filterDetailInfo = [SheetFilterType: SheetFilterInfo]()
    var toolGuideIdentifiers: [String]?
    var docsInfo: DocsInfo?
    var viewHeight: CGFloat {
        let height = navigator?.currentBrowserVC?.view.window?.bounds.size.height ?? SKDisplay.mainScreenBounds.size.height
        return ceil(height * 359 / 812)
    }
    var contentMaxWidth: CGFloat {
        return min(maxWidth, superWidth)
    }
    var nearlyFullRect: CGRect {
        let height = superHeight * 0.75
        let yOffset = superHeight - height
        return CGRect(x: (superWidth - contentMaxWidth) / 2.0, y: yOffset, width: contentMaxWidth, height: height)
    }

    var defaultRect: CGRect {
        let yOffset = superHeight - viewHeight
        return CGRect(x: (superWidth - contentMaxWidth) / 2.0, y: yOffset, width: contentMaxWidth, height: viewHeight)
    }

    var hiddenRect: CGRect {
        return CGRect(x: (superWidth - contentMaxWidth) / 2.0, y: superHeight, width: contentMaxWidth, height: viewHeight + assistButtonHeight + assistButtonPadding)
    }

    var assistButtonDefaultRect: CGRect {
        let xOffset = superWidth - assistButtonHeight - assistButtonPadding
        let yOffset = superHeight - viewHeight - assistButtonHeight - assistButtonPadding
        return CGRect(x: xOffset, y: yOffset, width: assistButtonHeight, height: assistButtonHeight)
    }

    var assistButtonMaxRect: CGRect {
        let fullHeight = superHeight * 0.75
        let xOffset = superWidth - assistButtonHeight - assistButtonPadding
        let yOffset = superHeight - fullHeight - assistButtonHeight - assistButtonPadding
        return CGRect(x: xOffset, y: yOffset, width: assistButtonHeight, height: assistButtonHeight)
    }

    var assistButtonHiddenRect: CGRect {
        let xOffset = superWidth - assistButtonHeight - assistButtonPadding
        return CGRect(x: xOffset, y: superHeight, width: assistButtonHeight, height: assistButtonHeight)
    }

    var statusBarAndTopContainerHeight: CGFloat {
        guard let dataSource = dataSource else { return 0 }
        return dataSource.statusBarHeight + dataSource.topContainerHeight
    }

    //fab面板、工具栏面板隐藏的时候告诉前端的高度
    var hiddenInnerHeight: CGFloat {
        let height = superHeight - statusBarAndTopContainerHeight
        return CGFloat(height)
    }
    //fab面板、工具栏面板展示的时候告诉前端的高度
    var showInnerHeight: CGFloat {
        let height = superHeight - statusBarAndTopContainerHeight - viewHeight
        return CGFloat(height)
    }

    init(navigator: BrowserNavigator?) {
        self.navigator = navigator
        self.superWidth = navigator?.currentBrowserVC?.view.bounds.size.width ?? SKDisplay.activeWindowBounds.size.width
        self.superHeight = navigator?.currentBrowserVC?.view.window?.bounds.size.height ?? SKDisplay.activeWindowBounds.size.height
        NotificationCenter.default.addObserver(self, selector: #selector(statusBarOrientationDidChange(_:)), name: UIApplication.willChangeStatusBarOrientationNotification, object: nil)
    }

    @objc
    private func statusBarOrientationDidChange(_ notification: Notification) {
        
        guard let intValue = notification.userInfo?[UIApplication.statusBarOrientationUserInfoKey] as? Int,
            let orientation = UIInterfaceOrientation(rawValue: intValue) else {
            DocsLogger.error("statusBarOrientationDidChange fatal error！")
            return
        }
        
        // 在屏幕方向真的发生变化时再做处理
        if orientation != UIInterfaceOrientation.unknown {
            removeToolkitView(trigger: DocsKeyboardTrigger.sheetOperation.rawValue)
            SheetTracker.report(event: .closeToolbox(action: 1), docsInfo: self.docsInfo)
        } else {
            DocsLogger.info("statusBarOrientationDidChange to unknown")
        }
    }
    
    func resetBorderPanel() {
        containerVC?.resetBorderPanel()
    }

    func isShowingToolkit() -> Bool {
        //直接展示toolkit的时候
        if let navigator = navigationController,
            navigator.viewControllers.count > 0,
            navigator.viewControllers[0] as? SheetToolkitContainerViewController != nil,
            navigator.view.superview != nil {
            return true
        }
        return false
    }

    func reportPanel(height: CGFloat, show: Bool, trigger: String) {
        let info = SimulateKeyboardInfo(height: height, isShow: show, trigger: trigger)
        delegate?.didChangePanelHeight(info, manager: self)
    }
}

extension SheetToolkitManager: SheetFreezeViewControllerDelegate {
    func freezeDidRequstUpdate(identifier: String, value: String?, controller: SheetFreezeViewController) {
        delegate?.toolkitRequestNavigation(identifier: identifier, value: value, viewType: .operation, manager: self, itemIsEnable: true)
    }
}

extension SheetToolkitManager: SheetToolkitContainerViewControllerDelegate {

    func toolkitDidFireAction(identifier: String, value: Any?, viewType: ToolkitViewType, controller: SheetToolkitContainerViewController, itemIsEnable: Bool) {
        if currentFloatModel() != .middle,
            identifier == BarButtonIdentifier.uploadImage.rawValue {
            switchToFloatModel(model: .middle) { [weak self] in
                guard let strongSelf = self else { return }
                self?.delegate?.toolkitRequestNavigation(identifier: identifier, value: value, viewType: viewType, manager: strongSelf, itemIsEnable: itemIsEnable)
            }
        } else {
            delegate?.toolkitRequestNavigation(identifier: identifier, value: value, viewType: viewType, manager: self, itemIsEnable: itemIsEnable)
        }
    }

    func toolkitDidChangeViewType(toViewType: ToolkitViewType, controller: SheetToolkitContainerViewController) {
        delegate?.toolkitRequestSwitchPanel(toViewType.rawValue, value: nil, manager: self)
    }

    func toolkitRequestExitSelf(controller: SheetToolkitContainerViewController) {
        hideToolkitView()
    }
}

extension SheetToolkitManager: SheetUploadImageViewControllerDelegate {

    var rootVC: UIViewController? {
        navigator?.currentBrowserVC?.view?.window?.rootViewController
    }

    var distanceToWindowBottom: CGFloat {
        return dataSource?.primaryBrowserViewDistanceToWindowBottom ?? 0.0
    }

    func didFinishPickingMedia(params: [String: Any]) {
        hideToolkitView { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.dataSource?.supportJSEngine(strongSelf)?.simulateJSMessage(DocsJSService.simulateFinishPickFile.rawValue, params: params)
            strongSelf.uploadImageVC = nil
        }
    }
    
    func exitUploadImageController() {
        uploadImageVC = nil
    }
}
