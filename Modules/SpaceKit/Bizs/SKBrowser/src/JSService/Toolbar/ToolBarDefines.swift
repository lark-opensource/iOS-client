// 
// Created by duanxiaochen.7 on 2020/7/15.
// Affiliated with SKCommon.
// 
// Description:

import Foundation
import SKCommon

//public typealias SKViewHeightModify = (_ height: CGFloat) -> Void

public protocol SKAttachedTBPanelDelegate: SKMainTBPanelDelegate {
    func didClickedItem(_ item: ToolBarItemInfo, panel: DocsAttachedToolBar, value: Any?)
}

public protocol SKMainTBPanelDelegate: AnyObject {
    /// 点击工具栏按钮触发的回调
    ///
    /// - Parameters:
    ///   - item: item 信息
    ///   - panel: panel 信息
    ///   - emptyClick: 是否是选中状态下的再次点击
    func didClickedItem(_ item: ToolBarItemInfo, panel: SKMainToolBarPanel, emptyClick: Bool)
    func didClickedItem(_ item: ToolBarItemInfo, panel: SKMainToolBarPanel, value: Any?)
    func didClickedItem(_ item: ToolBarItemInfo, panel: SKMainToolBarPanel, emptyClick: Bool, isFromRefresh: Bool)
    func hideHighlightView()
}

open class SKMainToolBarPanel: UIView {
    open weak var delegate: SKMainTBPanelDelegate?
    open func refreshStatus(status: [ToolBarItemInfo], service: DocsJSService) {}
    open func getCellFrame(byToolBarItemID: String) -> CGRect? { return nil }
    open func rollToItem(byID id: String) {}
}

public protocol SKSubTBPanelDelegate: AnyObject {
    func select(item: ToolBarItemInfo, update value: Any?, view: SKSubToolBarPanel)
    func select(item: ToolBarItemInfo, updateJson value: [String: Any]?, view: SKSubToolBarPanel)
    func requestShowKeyboard()
}

open class SKSubToolBarPanel: UIView {
    open weak var panelDelegate: SKSubTBPanelDelegate?
    open func showRootView() {}
    open func refreshViewLayout() {}
    open func updateStatus(status: [BarButtonIdentifier: ToolBarItemInfo]) {}
    open func getCurrentDisplayHeight() -> CGFloat? { return nil }
    open var shouldShowMainPanel: Bool {
        true
    }
    /// 作为inputView显示时，高度是否等于键盘
    open var canEqualToKeyboardHeight: Bool {
        return true
    }
    /// 当canEqualToKeyboardHeight为false时，这里要返回一个高度
    open var panelHeight: CGFloat? {
        return nil
    }
}

public protocol SKToolBarUICreater {
    //一级工具栏
    func updateMainToolBarPanel(_ status: [ToolBarItemInfo], service: DocsJSService) -> SKMainToolBarPanel
    func updateMainToolBarPanelV2(_ status: [ToolBarItemInfo], service: DocsJSService, isIPadToolbar: Bool) -> SKMainToolBarPanel

    //二级工具栏
    func updateSubToolBarPanel(_ status: [ToolBarItemInfo]?, identifier: String, curWindow: UIWindow?) -> SKSubToolBarPanel?
}

public extension SKToolBarUICreater {
    func updateMainToolBarPanelV2(_ status: [ToolBarItemInfo], service: DocsJSService, isIPadToolbar: Bool) -> SKMainToolBarPanel {
        assertionFailure("V1 和 V2 接口传入的 status 和 service 不一致，如果你真的需要调用这个方法，请提供自己的实现")
        return updateMainToolBarPanel(status, service: service)
    }
}

public struct SKBaseToolBarConfig {
    public var uiCreater: SKToolBarUICreater?
    public weak var hostView: UIView?
    public init(ui: SKToolBarUICreater? = nil, hostView: UIView?) {
        uiCreater = ui
        self.hostView = hostView
    }
}

public protocol SKBaseToolBarPluginProtocol: SKExecJSFuncService {
    func requestDisplayMainTBPanel(_ panel: SKMainToolBarPanel)
    func requestChangeSubTBPanel(_ panel: SKSubToolBarPanel, info: ToolBarItemInfo)
    func requestDisplaySubTBPanel(_ panel: SKSubToolBarPanel, info: ToolBarItemInfo)
    func requestShowKeyboard()
    func requestPresentViewController(_ vc: UIViewController, sourceView: UIView?, sourceRect: CGRect?)
    func requestDismissViewController(completion: (() -> Void)?)
    // sheet 统计
    // firstTimer 拼错了，应该是 time，firstTime 第一次
    // 建议写协议的同学加强英语能力
    func didReceivedOpenToolBarInfo(firstTimer: Bool, doubleClick: Bool)
    // sheet 统计
    func didReceivedCloseToolBarInfo()
    // 有附带文本编辑的输入
    func didReceivedInputText(text: Bool)

    //更新navigationPluginToolbar height
    func updateNavigationPluginToolBarHeight(height: CGFloat)

    func updateUiResponderTrigger(trigger: String)
    func resignFirstResponder()
}

// 以下接口默认实现是用来防止接口迭代后 lark 编译不过的，具体的实现类如果需要用到这些功能，是会实现具体的方法的
public extension SKBaseToolBarPluginProtocol {
    func callFunction(_ function: DocsJSCallBack, params: [String: Any]?, completion: ((_ info: Any?, _ error: Error?) -> Void)?) {
        assertionFailure("因为lark那边也用了这个接口，所以这里给个默认实现")
    }

    func requestPresentViewController(_ vc: UIViewController, sourceView: UIView?, sourceRect: CGRect?) {
        assertionFailure("该接口是用于显示工具栏 V2 的新增 block 面板的，如果还在使用旧版工具栏 / 自定义工具栏，则不需要调用该方法")
    }

    func requestDismissViewController(completion: (() -> Void)? = nil) {
        assertionFailure("该接口是用于隐藏工具栏 V2 的新增 block 面板的，如果还在使用旧版工具栏 / 自定义工具栏，则不需要调用该方法")
    }

    func requestDisplaySubTBPanel(_ panel: SKSubToolBarPanel, info: ToolBarItemInfo) {
        assertionFailure("该接口是用于显示工具栏 V2 的颜色面板的，如果还在使用旧版工具栏 / 自定义工具栏，则不需要调用该方法")
    }

    // sheet 统计
    func didReceivedOpenToolBarInfo(firstTimer: Bool, doubleClick: Bool) {
    }

    // sheet 统计
    func didReceivedCloseToolBarInfo() {
    }

    // 有附带文本编辑的输入
    func didReceivedInputText(text: Bool) {
    }

    //请求展示keyboard
    func requestShowKeyboard() {
    }

    //updateToolBar高度
    func updateNavigationPluginToolBarHeight(height: CGFloat) {
    }

    func updateUiResponderTrigger(trigger: String) {
    }

    func resignFirstResponder() {
    }
}

public enum ToolbarOrientation: Int {
    case horizontal = 0
    case vertical = 1
}

extension Notification.Name {
    public static let NavigationShowHighlightPanel: Notification.Name = Notification.Name("docs.highlight.show.notification")
    public static let NavigationHideHighlightPanel: Notification.Name = Notification.Name("docs.highlight.hide.notification")
}
