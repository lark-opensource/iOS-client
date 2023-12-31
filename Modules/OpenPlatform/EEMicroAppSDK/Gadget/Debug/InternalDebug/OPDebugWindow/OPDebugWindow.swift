//
//  OPDebugWindow.swift
//  OPSDK
//
//  Created by 尹清正 on 2021/2/3.
//

import UIKit
import OPSDK
import LarkOPInterface
import LKCommonsLogging

fileprivate let logger = Logger.oplog(OPDebugWindow.self, category: "debugWindow")

@objcMembers
public final class OPDebugWindow: UIWindow {

    /// 用于存储非多Scene情况下的调试窗口实例，整个应用程序对应唯一一个调试窗口
    /// 若不为nil，说明应用开启了调试窗口，若为nil，说明应用没有开启(或者已经关闭)调试窗口
    static var sharedWindow: OPDebugWindow?

    /// 用于存储多Scene情况下的调试窗口实例，一个Scene对应一个调试窗口
    /// 若scenesWindow[someScene]值并不为nil，说明该someScene已经开启了调试窗口
    /// 若scenesWindow[someScene]值为nil，说明该someScene没有开启(或者已经关闭)调试窗口
    @available(iOS 13.0, *)
    static var scenesWindow = [UIWindowScene: OPDebugWindow]()

    // MARK: - private state variable:记录内部需要使用的一些状态

    /// 当前窗口展示的形态：最小化窗口还是正常调试窗口，默认是最小化窗口
    private var currentDisplayType = DisplayType.minimizedWindow

    /// 当前最小化窗口吸附的方向：左侧还是右侧，默认是右侧
    private var currentAdsorbDirection = AdsorbDirection.right

    /// 记录当前窗口的拖拽状态
    private var dragState: WindowTragState = .idle

    /// 保存订阅关系
    private var windowFrameChangeObservation: NSKeyValueObservation?

    /**
    保存当前调试窗口所属的主窗口
    如果支持多Scene，那么该窗口应该是调试窗口所在Scene的主Window
    如果不支持多Scene，那么该窗口就是应用程序的主Window
    所有布局边界信息由该window提供，如果为空则默认使用主Scene的主Window
    */
    public private(set) var currentMainWindow: UIWindow?

    /// 用于布局的工具类
    private lazy var layout: OPDebugWindowLayout = {
        let layout = OPDebugWindowLayout(withWindow: currentMainWindow)
        layout.safeAreaInsets = self.safeAreaInsets
        return layout
    }()

    // MARK: - 界面相关的变量
    /// 最小化调试窗口上次的位置(center_y)
    private lazy var lastMinimizedViewCenterY: CGFloat = {
        return layout.mainWindowSize.height/2
    }()

    /// window的rootViewController
    private lazy var rootController: OPDebugWindowController = {
        let controller = OPDebugWindowController()
        controller.moveDelegate = self
        controller.displayTypeDelegate = self
        controller.layout = layout
        return controller
    }()

    private lazy var rootNavigator: OPDebugWindowNavigator = {
        let navigator = OPDebugWindowNavigator(rootViewController: rootController)
        navigator.moveDelegate = self
        return navigator
    }()

    // MARK: -  initializers: 初始化方法

    init(_ window: UIWindow?) {
        logger.debug("start to initialize a debug window")
        if #available(iOS 13.0, *),
           let scene = window?.windowScene {
            currentMainWindow = OPWindowHelper.findSceneMainWindow(scene)
            super.init(windowScene: scene)
            OPDebugWindow.scenesWindow[scene] = self
            logger.debug("there is a UIScene API, so store the initialized window(hash:\(self.hashValue)) into scenesWindow map")
        } else {
            currentMainWindow = OPWindowHelper.fincMainSceneWindow()
            super.init(frame: .zero)
            OPDebugWindow.sharedWindow = self
            logger.debug("there is not a UIScene API, so store the initialized window(hash:\(self.hashValue)) as the global sharedWindow")
        }

        windowLevel = .debugWindowLevel
        isHidden = false
        // iPad masksToBounds设置为true iPad暂时放弃阴影现实
        // 因为如果没有masksToBounds iPad在旋转时会出现黑色色块
        if BDPDeviceHelper.isPadDevice() {
            layer.masksToBounds = true
        }
        // 阴影
        layer.shadowColor = OPDebugWindowLayout.windowShadowColor
        layer.shadowRadius = OPDebugWindowLayout.windowRadius
        layer.shadowOpacity = OPDebugWindowLayout.windowShadowOpacity
        // 圆角
        layer.cornerRadius = OPDebugWindowLayout.windowRadius
        // 边框
        layer.borderWidth = OPDebugWindowLayout.windowBorderWidth
        layer.borderColor = OPDebugWindowLayout.windowBorderColor

        rootViewController = rootNavigator

        // 如果满足调试小程序的FG就直接显示，如果不满足则只显示性能数据窗口
        if OPDebugFeatureGating.debugAvailable() {
            initDebugWindowMaximize()
        } else {
            initDebugWindowMinimize()
        }

        // 监听当前Window的大小变化，目的是在iPad开启多Scene、改变Scene大小、横竖屏转换时可以及时适应
        windowFrameChangeObservation = currentMainWindow?.observe(\.frame, options: .new, changeHandler: {
            [weak self] (window, change) in
            guard let self = self else {return}
            self.adaptWindowChange()
        })
    }

    deinit {
        logger.debug("debug window instance(hash:\(self.hashValue)) will be destroyed")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: -  public functions:对外公开的API方法

    /// 检查当前window下的调试窗口是否处于正在运行的状态
    @objc public static func debugStarted(withWindow window: UIWindow?) -> Bool {
        if !Thread.isMainThread {
            assertionFailure("Please invoke this function on main thread")
        }

        if #available(iOS 13.0, *),
           let scene = window?.windowScene {
            return OPDebugWindow.scenesWindow[scene] != nil
        } else {
            return OPDebugWindow.sharedWindow != nil
        }
    }


    /// 开启当前window下的调试窗口功能
    @objc public static func startDebug(withWindow window: UIWindow?) {
        OPFoundation.executeOnMainQueueAsync {
            _startDebug(withWindow: window)
        }
    }
    private static func _startDebug(withWindow window: UIWindow?) {
        // 只有当前window的调试窗口处于关闭状态下，才能开启
        if !debugStarted(withWindow: window) {
            logger.debug("start to show debug window")
            _ = OPDebugWindow(window)
        }
    }

    /// 关闭当前window下的调试窗口
    @objc public static func closeDebug(withWindow window: UIWindow?) {
        OPFoundation.executeOnMainQueueAsync {
            _closeDebug(withWindow: window)
        }
    }
    private static func _closeDebug(withWindow window: UIWindow?) {
        // 只有当前window的调试窗口处于开启状态下，才能关闭
        guard debugStarted(withWindow: window) else {
            return
        }

        logger.debug("start to dismiss debug window")
        if #available(iOS 13.0, *),
           let scene = window?.windowScene {
            // iPad上会为NavigationBar添加UIPointerInteraction来适配鼠标
            // 添加上的UIPointerInteraction会被挂载到当前的主window之上(强持有window)
            // 导致自定义window无法被销毁，所以在要关闭window的时候对NavigationBar的interaction进行统一删除
            if let window = OPDebugWindow.scenesWindow[scene] {
                for interaction in window.rootNavigator.navigationBar.interactions {
                    window.rootNavigator.navigationBar.removeInteraction(interaction)
                }
            }
            OPDebugWindow.scenesWindow.removeValue(forKey: scene)
        } else {
            OPDebugWindow.sharedWindow = nil
        }
    }

}

// MARK: - private functions:私有工具方法

fileprivate extension OPDebugWindow {
    /// 适应窗口的各种变换：旋转、多Scene等
    private func adaptWindowChange() {
        // 目前没有合适的逻辑可以做到同时监听多scene、改变scene大小、屏幕旋转
        // 暂时通过监听主window的size来实现
        // 缺点是，size的变化与事件真正发生并不是同步的，需要延时执行，推迟到下一次runloop
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            // 目的：设备旋转时大小可以及时适配
            switch self.currentDisplayType {
            case .normalWindow:
                self.op_size = self.layout.maximizedViewSize
            case .minimizedWindow:
                self.op_size = self.layout.minimizedViewSize
            }
            // 如果当前没有正在进行拖拽，就调用fitPostion方法使调试窗口及时适应Window边界
            // 目的：Scene主窗口的大小改变时及时适应
            if case .idle = self.dragState {
                self.fitPosition()
            }
        }
    }

    /// 初始化Window界面为最大化窗口的形式显示
    func initDebugWindowMaximize() {
        currentDisplayType = .normalWindow
        op_size = layout.maximizedViewSize
        op_origin = .zero
        rootController.showMaximizedView()
        fitPosition()
    }

    /// 初始化Window界面为最小化窗口的形式显示
    func initDebugWindowMinimize() {
        currentDisplayType = .minimizedWindow
        op_size = layout.minimizedViewSize
        op_centerY = layout.mainWindowSize.height/2
        op_right = layout.mainWindowSize.width - layout.expectedMargin.right
        rootController.showMinimizedView()
        fitPosition()
    }

    /// 将window从正常的调试窗口变为最小化窗口
    func minimizeDebugWindow() {
        guard case .normalWindow = currentDisplayType else { return }
        currentDisplayType = .minimizedWindow
        // 改变视图层级
        rootController.showMinimizedView()
        // 确定大小以及位置
        op_size = layout.minimizedViewSize
        op_centerY = lastMinimizedViewCenterY
        switch currentAdsorbDirection {
        case .right:
            op_left = op_left + (layout.maximizedViewSize.width - layout.minimizedViewSize.width)
        case .left:
            break
        }
        fitPosition()
    }

    /// 将window从最小化窗口变为正常的调试窗口
    func maximizeDebugWindow() {
        guard case .minimizedWindow = currentDisplayType else { return }
        lastMinimizedViewCenterY = op_centerY
        currentDisplayType = .normalWindow
        // 改变视图层级
        rootController.showMaximizedView()
        // 确定大小以及位置
        op_size = layout.maximizedViewSize
        if !BDPDeviceHelper.isPadDevice() {
            op_origin = .zero
        } else {
            switch currentAdsorbDirection {
            case .right:
                op_left = op_left - (layout.maximizedViewSize.width - layout.minimizedViewSize.width)
            case .left:
                break
            }
        }
        fitPosition()
    }

    /// 调整view的位置，以防止发生了frame的变化之后存在超出屏幕外的部分
    func fitPosition() {
        switch currentDisplayType {
        case .minimizedWindow:
            fitPositionWithMinimizedType()
        case .normalWindow:
            fitPositionWithNormalType()
        }
    }

    /// 当前窗口处于最小化状态时去调整view的位置以适应界面的边界
    func fitPositionWithMinimizedType() {
        guard case .minimizedWindow = currentDisplayType else {
            return
        }
        // 判断悬浮窗的吸附方向
        let direction: AdsorbDirection
        let splitX = layout.mainWindowSize.width / 2
        if op_centerX > splitX {
            direction = .right
        } else {
            direction = .left
        }
        currentAdsorbDirection = direction
        // 根据悬浮窗吸附方向确定x坐标位置
        switch direction {
        case .right:
            op_right = layout.mainWindowSize.width - layout.expectedMargin.right
        case .left:
            op_left = layout.expectedMargin.left
        }
        // 判断悬浮窗y坐标位置
        if op_top < layout.expectedMargin.top {
            op_top = layout.expectedMargin.top
        }
        if op_bottom > layout.mainWindowSize.height - layout.expectedMargin.bottom {
            op_bottom = layout.mainWindowSize.height - layout.expectedMargin.bottom
        }
    }

    /// 当前窗口处于正常调试显示状态时去调整view的位置以适应界面的边界
    func fitPositionWithNormalType() {
        guard case .normalWindow = currentDisplayType else {
            return
        }
        if op_top < 0 {
            op_top = 0
        }
        if op_left < 0 {
            op_left =  0
        }
        if op_right > layout.mainWindowSize.width {
            op_right = layout.mainWindowSize.width
        }
        if op_bottom > layout.mainWindowSize.height {
            op_bottom = layout.mainWindowSize.height
        }
    }
}

// MARK: - private types

extension OPDebugWindow {
    /**
    Window的显示内容有两种
    一种是最小化形式的悬浮窗口显示
    另一种是显示正常的小程序悬浮窗口
    */
    private enum DisplayType {
        /// 最小化窗口形式
        case minimizedWindow
        /// 正常显示小程序悬浮窗口
        case normalWindow
    }

    /**
    最小化窗口会吸附到屏幕的左右两侧
    该枚举代表吸附哪一侧
    */
    private enum AdsorbDirection {
        case right
        case left
    }

    /// 当前窗口拖拽的状态
    private enum WindowTragState {
        /// 空闲状态，没有被拖拽
        case idle
        /// 正在被拖拽，关联值为一次拖拽开始的position
        case tragging(CGPoint)
    }
}



// MARK: - OPDebugCommandWindowMoveDelegate

/// OPDebugCommandWindow对外提供根据手势移动的能力
protocol OPDebugCommandWindowMoveDelegate: AnyObject {
    /// 开始拖拽
    func touchBegan(_ touch: UITouch?)
    /// 正在拖拽
    func touchMoved(_ touch: UITouch?)
    /// 结束拖拽
    func touchEnded(_ touch: UITouch?)
}
extension OPDebugWindow: OPDebugCommandWindowMoveDelegate {
    func touchBegan(_ touch: UITouch?) {
        if let position = touch?.location(in: self) {
            dragState = .tragging(position)
        }
    }

    func touchMoved(_ touch: UITouch?) {
        guard let currentPosition = touch?.location(in: self),
              case .tragging(let beginPosition) = dragState else {
            return
        }

        let offsetX = currentPosition.x - beginPosition.x
        let offsetY = currentPosition.y - beginPosition.y

        self.center =  CGPoint(x: self.center.x + offsetX, y: self.center.y + offsetY)
    }

    func touchEnded(_ touch: UITouch?) {
        dragState = .idle
        UIView.beginAnimations(nil, context: nil)
        fitPosition()
        UIView.commitAnimations()
    }
}

// MARK: - OPDebugCommandWindowDisplayTypeDelegate
/// 对外提供控制OPDebugCommandWindow的displayStyle的能力
protocol OPDebugCommandWindowDisplayTypeDelegate: AnyObject {
    /// 最小化window，使debugWindow处于最小化的形态
    func minimize()
    /// 最大化window，使debugWindow处于正常的调试器状态
    func maximize()
    /// 关闭window
    func close()
}
extension OPDebugWindow: OPDebugCommandWindowDisplayTypeDelegate {
    func minimize() {
        guard case .normalWindow = currentDisplayType else {
            return
        }
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self else {return}
            self.minimizeDebugWindow()
            self.layoutIfNeeded()
        }
    }

    func maximize() {
        // 如果用户当前对调试小程序不可见，那么不允许最大化
        guard OPDebugFeatureGating.debugAvailable() else {
            return
        }
        guard case .minimizedWindow = currentDisplayType else {
            return
        }
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self else {return}
            self.maximizeDebugWindow()
            self.layoutIfNeeded()
        }
    }

    func close() {
        Self.closeDebug(withWindow: self.currentMainWindow)
    }
}
