//
//  SuspendManager.swift
//  LarkSuspendable
//
//  Created by bytedance on 2021/1/5.
//

import UIKit
import Foundation
import LarkStorage
import EENavigator
import Homeric
import LKWindowManager
import LKCommonsTracker
import LKCommonsLogging
import LarkTab
import LarkContainer
import LarkQuickLaunchInterface
import RxSwift
import LarkSetting

// 支持 KVStore 存储
extension CodableRect: KVNonOptionalValue { }
extension SuspendPatch: KVNonOptionalValue { }

public final class SuspendManager: NSObject {

    static let logger = Logger.log(SuspendManager.self, category: "Module.Core.LarkSuspendable")

    // MARK: Singleton

    /// 获取 SuspendManager 单例
    public static let shared = SuspendManager()

    // 这个单例持有用户态的实例，临时兼容当前用户使用 Provider 获取，避免用户实例过期，后面要改造（这个改造牵涉的范围有点大）

    /// 提供 QuickLaunch 功能的 Service 对象
    @available(*, deprecated, message: "已废弃，请直接依赖 QuickLaunchService")
    @Provider private var quickLaunchService: QuickLaunchService

    /// 提供 iPad 临时打开区功能的 Service 对象
    @available(*, deprecated, message: "已废弃，请直接依赖 TemporaryTabService")
    @Provider private var temporaryTabService: TemporaryTabService

    /// 提供 iPad 临时打开区功能的 Service 对象
    @available(*, deprecated, message: "已废弃，请直接依赖 PageKeeperService")
    @Provider private var pageKeeperService: PageKeeperService

    private let disposeBag = DisposeBag()

    private override init() {
        super.init()
        addKeyBoardObserver()
        addMemoryWarningObserver()
    }

    deinit {
        removeKeyBoardObserver()
        removeMemoryWarningObserver()
    }

    // 是否可以将气泡拖动到右下角删除（暂不支持此功能）
    let isBubbleRemovable: Bool = false

    /// 获取多任务浮窗的 Window
    public private(set) var suspendWindow: SuspendWindow?

    var suspendController: SuspendController? {
        return suspendWindow?.suspendController
    }

    internal var suspendItems: [SuspendPatch] = [] {
        didSet {
            addSuspendWindowIfNeeded()
            removeSuspendWindowIfNeeded()
        }
    }

    private func addSuspendItem(_ item: SuspendPatch) {
        suspendItems.insert(item, at: 0)
        refreshShowingItems()
        saveSuspendItems()
        changeBasketStateIfNeeded()
    }

    private func removeAllSuspendItems() {
        suspendItems.removeAll()
        refreshShowingItems()
        saveSuspendItems()
        changeBasketStateIfNeeded()
    }

    private func removeSuspendItem(byId id: String) {
        suspendItems.removeAll(where: { $0.id == id })
        refreshShowingItems()
        saveSuspendItems()
        changeBasketStateIfNeeded()
    }

    private func replaceSuspendItem(byId id: String, newItem: SuspendPatch) {
        if let index = suspendItems.firstIndex(where: { $0.id == id }) {
            let oldItem = suspendItems[index]
            var newItem = newItem
            newItem.source = oldItem.source
            newItem.params[SuspendManager.sourceIDKey] = oldItem.params[SuspendManager.sourceIDKey]
            if newItem.title.isEmpty {
                newItem.title = oldItem.title
            }
            suspendItems[index] = newItem
            refreshShowingItems()
            saveSuspendItems()
        }
    }

    private func refreshShowingItems(animated: Bool = true) {
        /*
        let filteredItems = suspendItems.filter {
            !self.showingIds.contains($0.id)
        }
        suspendController?.refresh(by: filteredItems)
         */
        guard SuspendManager.isSuspendEnabled else { return }
        suspendController?.refresh(by: suspendItems, animated: animated)
    }

    /// 记录页面打开（更新多任务列表）
    /// - Parameter id: 打开页面的 suspendIdentifier
    func viewControllerDidOpen(_ id: String) {
        showingIds.insert(id)
        /* 当前页面对应列表项高亮
        suspendController?.dockListView.refreshSelectedItem(id: id)
         */
        // refreshShowingItems()
    }

    /// 记录页面关闭（更新多任务列表）
    /// - Parameter id: 关闭页面的 suspendIdentifier
    func viewControllerDidClose(_ id: String) {
        showingIds.remove(id)
        /* 当前页面对应列表项高亮
        suspendController?.dockListView.refreshSelectedItem(id: nil)
         */
        // refreshShowingItems()
    }

    private var showingIds: Set<String> = []

    /// 保存支持热启动的 ViewController
    var vcHolder: [String: ViewControllerSuspendable] = [:]

    // 右下角扇形view
    lazy var basketView: BottomBasketView = {
        return BottomBasketView(frame: SuspendConfig.defaultBasketRect, state: .enabled)
    }()

    private var customViewHolder: [String: UIView] = [:]
    private var customViewControllerHolder: [String: UIViewController] = [:]

    private var dockListRemovalCallback: (() -> Void)?

    private func clear() {
        vcHolder.removeAll()
        showingIds.removeAll()
        dockListRemovalCallback = nil
        changeBasketStateIfNeeded()
    }

    func getTopViewController() -> UIViewController? {
        guard let mainWindow = UIApplication.shared.delegate?.window else { return nil }
        let mainRootController = mainWindow?.rootViewController
        return topViewController(mainRootController)
    }
}

// MARK: - Public API

extension SuspendManager {

    /// 多任务浮窗当前已收入页面数量
    public var count: Int {
        return suspendItems.count
    }

    /// 多任务浮窗是否已满（当前最多支持收入 5 个页面）
    public var isFull: Bool {
        return suspendItems.count >= SuspendConfig.maxDockLimit
    }

    /// 当前浮窗是否包含了指定 ID 的页面
    public func contains(suspendID id: String) -> Bool {
        return suspendItems.map({ $0.id }).contains(id)
    }

    /// 当前页面是否来自于浮窗
    public func isFromSuspend(sourceID: String?) -> Bool {
        guard let sourceID = sourceID else { return false }
        return suspendItems.map({ $0.source }).contains(sourceID)
    }

    /// 当前浮窗是否包含了指定 ID 的页面
    @available(*, deprecated, message: "use contains(suspendID:) instead.")
    public func contains(suspendIdentifier id: Int) -> Bool {
        let newID = String(id)
        return contains(suspendID: newID)
    }

    /// 退出登录时，清理多任务页面暂存
    public func clearSuspendItems() {
//        guard SuspendManager.isSuspendEnabled else { return }
        clear()
        suspendItems.removeAll()
        refreshShowingItems(animated: false)
        suspendController?.reset()
    }
}

// MARK: - Feature Gating

extension SuspendManager {

    /// SourceVC 默认 key
    public static var sourceIDKey: String {
        return "suspendSourceID"
    }

    /// 浮窗功能是否可用
    public private(set) static var isFloatingEnabled: Bool = loadFloatingFG()

    /// 多任务功能是否可用
    public private(set) static var isSuspendEnabled: Bool = loadSuspendFG()

    /// 主导航功能是否可用
    public private(set) static var isTabEnabled: Bool = true

    /// QuickLaunchService是否可用
    @available(*, deprecated, message: "QuickLaunch 和多任务浮窗已拆分为独立功能，该接口废弃，恒定返回 false。如果需要获取 isQuickLauncherEnabled，请直接依赖 QuickLaunchService.")
    public var isQuickLaunchServiceEnabled: Bool {
        // return quickLaunchService.isQuickLauncherEnabled
        return false
    }

    /// 是否开启了多任务浮窗功能
    @available(*, deprecated, message: "从 3.45 开始，原有 FG 拆分为 UI FG 和多任务功能 FG，如需添加自定义视图，请使用 isFloatingEnabled")
    public static var isFeatureEnabled: Bool {
        return isFloatingEnabled
    }

    // 给iPad禁用悬浮窗
    /// 浮窗功能是否可用
    private static func loadFloatingFG() -> Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }

    /// 多任务功能是否可用
    private static func loadSuspendFG() -> Bool {
        // 只支持手机端
        return UIDevice.current.userInterfaceIdiom == .phone
    }
}

// MARK: - 持久化存储

extension SuspendManager {
    // KVStore helper

    // 区分账号存储暂存列表
    private static var suspendItems = suspendItems(forSpace: .global)

    // 区分账号存储暂存列表
    static var tabCandidates: KVConfig<[TabCandidate]?> = {
        return .init(
            key: "tab_candidates",
            store: KVStores.udkv(space: .global, domain: Domain.biz.core.child("QuickLauncher"))
        )
    }()

    // 区分账号存储暂存气泡位置
    private static var bubbleRect = bubbleRect(forSpace: .global)

    #if DEBUG
    private static var currentClientID: String = "1"

    /// 提供给 Demo 的模拟账号切换 API
    public func changeClient(id: String) {
        SuspendManager.shared.clearSuspendItems()
        SuspendManager.currentClientID = id
    }
    #endif

    /// 加载用户的多任务配置（在每次启动或切换账号时调用）
    /// - Parameter id: 用户的唯一标识
    public func loadSuspendConfig(forUserId id: String) {
        guard SuspendManager.isSuspendEnabled else { return }
        loadBubblePosition(forUserId: id)
        loadSuspendItems(forUserId: id)
    }

    // 气泡位置

    /// 从 KVStore 中读取当前租户的气泡位置
    static func getBubbleRect() -> CGRect {
        return bubbleRect.value.cgRect
    }

    /// 持久化存储气泡位置
    static func saveBubbleRect(rect: CGRect) {
        bubbleRect.value = .init(cgRect: rect)
    }

    static func bubbleRect(forSpace space: Space) -> KVConfig<CodableRect> {
        return .init(
            key: "bubble_rect",
            default: CodableRect(cgRect: SuspendConfig.defaultBubbleRect),
            store: KVStores.udkv(space: space, domain: Domain.biz.core.child("Suspendable"))
        )
    }

    private func loadBubblePosition(forUserId id: String) {
        SuspendManager.bubbleRect = SuspendManager.bubbleRect(forSpace: .user(id: id))
        suspendController?.setBubblePositionIfNeeded(SuspendManager.bubbleRect.value.cgRect)
    }

    // 多任务页面

    static func suspendItems(forSpace space: Space) -> KVConfig<[SuspendPatch]?> {
        return .init(
            key: "suspend_items",
            store: KVStores.udkv(space: space, domain: Domain.biz.core.child("Suspendable"))
        )
    }

    private func saveSuspendItems() {
        SuspendManager.suspendItems.value = suspendItems
    }

    private func loadSuspendItems(forUserId id: String) {
        SuspendManager.suspendItems = SuspendManager.suspendItems(forSpace: .user(id: id))
        if let loadedItems = SuspendManager.suspendItems.value {
            for item in loadedItems where !suspendItems.contains(where: { $0.id == item.id }) {
                suspendItems.append(item)
            }
            refreshShowingItems(animated: false)
        }
    }
}

// MARK: - 添加/删除页面

extension SuspendManager {

    /// 将 ViewController 添加到多任务列表
    /// - Parameters:
    ///   - viewController: 符合 ViewControllerSuspendable 协议的 VC
    ///   - shouldClose: 添加完成后是否关闭该页面
    ///   - completion: 完成回调
    ///
    /// 如果 VC  的 isWarmStartEnabled 属性为 false（默认值），SuspendManager 只保存用于恢复 VC 的必要信息，不会持有 VC 实例
    public func addSuspend(viewController: ViewControllerSuspendable,
                           shouldClose: Bool = true,
                           isBySlide: Bool = false,
                           completion: (() -> Void)? = nil) {
        guard SuspendManager.isSuspendEnabled else { return }
        if isFull {
            // 达到上限，不能添加
            let alert = UIAlertController(
                title: nil,
                message: BundleI18n.LarkSuspendable.Lark_Core_FloatingLimitDesc,
                preferredStyle: .alert
            )
            let action = UIAlertAction(
                title: BundleI18n.LarkSuspendable.Lark_Core_FloatingLimitDescOK,
                style: .default) { _ in
                self.setSuspendWindowHiddenInternal(false)
                self.suspendController?.showDockList(animated: true)
                self.dockListRemovalCallback = { [weak self] in
                    guard let self = self else { return }
                    self.addSuspend(
                        viewController: viewController,
                        shouldClose: shouldClose,
                        completion: completion
                    )
                }
            }
            alert.addAction(action)
            getTopViewController()?.present(alert, animated: true, completion: { [weak self] in
                guard let self = self else { return }
                alert.view.superview?.isUserInteractionEnabled = true
                alert.view.superview?.addGestureRecognizer(
                    UITapGestureRecognizer(target: self, action: #selector(self.dismissAlertOnTapOutside))
                )
            })
            setSuspendWindowHiddenInternal(true)
            // Analytics
            if !isBySlide {
                Tracker.post(TeaEvent(Homeric.TASKLIST_ADD_BY_FIX, params: [
                    "add_result": "failure",
                    "task_type": viewController.analyticsTypeName
                ]))
            }
        } else {
            // 未达到上限，直接添加
            addSuspendItem(viewController.getPatch())
            if viewController.isWarmStartEnabled {
                vcHolder[viewController.suspendID] = viewController
            }
            setSuspendWindowHiddenInternal(false)
            if shouldClose, let window = Navigator.shared.mainSceneWindow { //Global
                Navigator.shared.pop(from: window, animated: true) { //Global
                    completion?()
                }
            } else {
                completion?()
            }
            // Analytics
            if !isBySlide {
                Tracker.post(TeaEvent(Homeric.TASKLIST_ADD_BY_FIX, params: [
                    "add_result": "success",
                    "task_type": viewController.analyticsTypeName
                ]))
            }
        }
    }

    /// 从多任务列表中删除 ViewController
    /// - Parameter viewController: 待移除的 ViewController
    ///
    /// 如果传入 ViewController 不在浮窗中，则不执行任何操作。
    public func removeSuspend(viewController: ViewControllerSuspendable) {
        guard SuspendManager.isSuspendEnabled else { return }
        removeSuspendItem(byId: viewController.suspendID)
        vcHolder[viewController.suspendID] = nil
        // Analytics
        Tracker.post(TeaEvent(Homeric.TASKLIST_DELETE_BY_FIX, params: [
            "task_type": viewController.analyticsTypeName
        ]))
    }

    /// 从多任务列表中删除指定 ID 的页面
    /// - Parameter id: 待移除 ViewController 的 suspendID
    ///
    /// 如果浮窗中不包含指定 ID 的项目，则不执行任何操作。
    public func removeSuspend(byId id: String) {
        guard SuspendManager.isSuspendEnabled else { return }
        guard contains(suspendID: id) else { return }
        removeSuspendItem(byId: id)
        vcHolder[id] = nil
        // Analytics
        if let item = suspendItems.first(where: { $0.id == id }) {
            Tracker.post(TeaEvent(Homeric.TASKLIST_DELETE_BY_FIX, params: [
                "task_type": item.analytics
            ]))
        }
    }

    /// 更新多任务列表中的数据（根据 suspendID 匹配）
    /// - Parameter viewController: 待更新的 ViewController
    ///
    /// 如果页面内参数进行了变化，可以手动调用该方法，更新暂存的数据。该方法会在页面关闭时自动调用，以保存最新的页面数据。
    public func updateSuspend(viewController: ViewControllerSuspendable) {
        guard SuspendManager.isSuspendEnabled else { return }
        if viewController.isWarmStartEnabled {
            vcHolder[viewController.suspendID] = viewController
        }
        replaceSuspendItem(
            byId: viewController.suspendID,
            newItem: viewController.getPatch()
        )
    }

    /// 替换多任务列表项，用于页面内部跳转导致 suspendID 发生变化时
    /// - Parameters:
    ///   - id: 变化前的 suspendID
    ///   - patch: 变化后的 suspendPatch
    ///
    /// 当在一个 VC 内部进行了跳转时（如文档页面内点击了目录跳转，或网页内点击了超链接），虽然 VC 没有变化，但是跳转前后被认为是两个不同页面，此时需要调用 updateSuspend，将
    func replaceSuspend(byId id: String, patch: SuspendPatch) {
        guard SuspendManager.isSuspendEnabled else { return }
        if contains(suspendID: patch.id) {
            /*
            removeSuspendItem(byId: patch.id)
            removeSuspendItem(byId: id)
            addSuspendItem(patch)
            */
        } else {
            vcHolder[id] = nil
            replaceSuspendItem(byId: id, newItem: patch)
        }
    }

    /// 根据当前暂存列表是否已满，更改右下角篮筐状态
    func changeBasketStateIfNeeded() {
        basketView.state = isFull ? .disabled : .enabled
    }

    @objc
    private func dismissAlertOnTapOutside() {
        guard let alert = getTopViewController() as? UIAlertController else {
            return
        }
        alert.dismiss(animated: true, completion: {
            self.setSuspendWindowHiddenInternal(false)
        })
    }
}

// MARK: - 添加/删除自定义视图

extension SuspendManager {

    /// 获取自定义 View
    @available(*, deprecated, message: "use customView(forKey:) instead.")
    public var customView: UIView? {
        return customView(forKey: "default_custom")
    }

    /// 获取自定义 ViewController
    @available(*, deprecated, message: "use customViewController(forKey:) instead.")
    public var customViewController: UIViewController? {
        return customViewController(forKey: "default_custom")
    }

    /// 获取自定义 View 的位置
    @available(*, deprecated, message: "use customFrame(forKey:) instead.")
    public var customFrame: CGRect? {
        return customFrame(forKey: "default_custom")
    }

    /// 添加自定义 View
    @available(*, deprecated, message: "use addCustomView(:size:forKey:) instead.")
    public func addCustomView(_ view: UIView, size: CGSize) {
        addCustomView(view, size: size, forKey: "default_custom")
    }

    /// 添加自定义 ViewController
    @available(*, deprecated, message: "use addCustomViewController(:size:forKey:) instead.")
    public func addCustomViewController(_ viewController: UIViewController, size: CGSize) {
        addCustomViewController(viewController, size: size, forKey: "default_custom")
    }

    /// 移除自定义 View
    @available(*, deprecated, message: "use removeCustomView(forKey:) instead.")
    @discardableResult
    public func removeCustomView() -> UIView? {
        return removeCustomView(forKey: "default_custom")
    }

    /// 移除自定义 ViewController
    @available(*, deprecated, message: "use removeCustomViewController(forKey:) instead.")
    @discardableResult
    public func removeCustomViewController() -> UIViewController? {
        return removeCustomViewController(forKey: "default_custom")
    }
}

// MARK: - 添加自定义视图（新）

extension SuspendManager {

    /// 自定义视图在多任务浮窗中的排列顺序
    public struct Level: Hashable, Equatable, RawRepresentable, ExpressibleByIntegerLiteral {

        public typealias IntegerLiteralType = UInt8

        /// 自定义视图最上方
        public static let top: Level = Level(.max)

        /// 自定义视图中间
        public static let middle: Level = Level(.min + (.max - .min) / 2)

        /// 自定义视图最下方
        public static let bottom: Level = Level(.min)

        public var rawValue: UInt8

        public init(_ rawValue: UInt8) {
            self.init(rawValue: rawValue)
        }

        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }

        public init(integerLiteral value: UInt8) {
            self.init(rawValue: value)
        }

        static public func + (left: Level, right: UInt8) -> Level {
            if left == .top, right > 0 {
                assertionFailure("Level 值超过了上边界")
            }
            return Level(left.rawValue + right)
        }

        static public func - (left: Level, right: UInt8) -> Level {
            if left == .bottom, right > 0 {
                assertionFailure("Level 值超过了下边界")
            }
            return Level(left.rawValue - right)
        }
    }

    /// 获取自定义 View
    public func customView(forKey key: String) -> UIView? {
        return customViewHolder[key]
    }

    /// 获取自定义 ViewController
    public func customViewController(forKey key: String) -> UIViewController? {
        return customViewControllerHolder[key]
    }

    /// 获取自定义 View 的位置
    public func customFrame(forKey key: String) -> CGRect? {
        guard let view = customViewHolder[key] else { return nil }
        return view.superview?.convert(view.frame, to: nil)
    }

    private func addCustomViewInternal(_ view: UIView,
                                       size: CGSize,
                                       level: Level,
                                       forKey key: String,
                                       isBackgroundOpaque: Bool,
                                       tapHandler: (() -> Void)? = nil) {
        guard customViewHolder[key] == nil else { return }
        customViewHolder[key] = view
        addSuspendWindowIfNeeded()
        suspendController?.addCustomView(view,
                                         size: size,
                                         level: level.rawValue,
                                         forKey: key,
                                         isBackgroundOpaque: isBackgroundOpaque,
                                         tapHandler: tapHandler)
    }

    /// 向浮窗添加自定义视图
    /// - Parameters:
    ///   - view: 自定义视图
    ///   - size: 自定义视图尺寸
    ///   - key: 自定义视图的唯一标志符（通过 key 识别 view）
    ///   - level: 优先级（较大的值排在靠上的位置，默认放在最上层）
    ///   - tapHandler: 点击事件（可选）
    public func addCustomView(_ view: UIView,
                              size: CGSize,
                              forKey key: String,
                              level: Level = .top - 1,
                              tapHandler: (() -> Void)? = nil) {
        addCustomViewInternal(view,
                              size: size,
                              level: level,
                              forKey: key,
                              isBackgroundOpaque: false,
                              tapHandler: tapHandler)
    }

    /// 向浮窗添加自定义按钮
    /// - Parameters:
    ///   - icon: 按钮图标
    ///   - size: 图标尺寸，若不指定则使用默认尺寸
    ///   - key: 自定义按钮的唯一标志符（通过 key 识别 view）
    ///   - level: 优先级（较大的值排在靠上的位置，默认放在最底层）
    ///   - tapHandler: 点击事件（可选）
    /// - Returns: 将传入的 Icon 包装后的 UIView 对象
    ///
    /// 可以持有返回的 UIView 包装对象，以添加自定义手势监听，但需要注意及时释放
    @discardableResult
    public func addCustomButton(_ icon: UIImage,
                                size: CGSize? = nil,
                                forKey key: String,
                                level: Level = Level.bottom + 1,
                                tapHandler: (() -> Void)? = nil) -> UIView {
        let iconView = UIView()
        let imageView = UIImageView(image: icon)
        imageView.contentMode = .scaleAspectFit
        iconView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(size ?? SuspendBubbleView.customIconSize)
        }
        addCustomViewInternal(iconView,
                              size: SuspendBubbleView.customSize,
                              level: level,
                              forKey: key,
                              isBackgroundOpaque: true,
                              tapHandler: tapHandler)
        return iconView
    }

    /// 移除自定义图标 View
    public func removeCustomButton(forKey key: String) {
        removeCustomView(forKey: key)
    }

    /// 添加自定义 ViewController
    public func addCustomViewController(_ viewController: UIViewController,
                                        size: CGSize,
                                        forKey key: String,
                                        level: Level = .top - 1,
                                        tapHandler: (() -> Void)? = nil) {
        guard customViewControllerHolder[key] == nil else { return }
        customViewControllerHolder[key] = viewController
        suspendController?.addCustomViewController(viewController, forKey: key)
        addCustomView(viewController.view,
                      size: size,
                      forKey: key,
                      level: level,
                      tapHandler: tapHandler
        )
    }

    /// 移除自定义 View
    @discardableResult
    public func removeCustomView(forKey key: String) -> UIView? {
        guard customViewHolder[key] != nil else { return nil }
        customViewHolder[key] = nil
        let view = suspendController?.removeCustomView(forKey: key)
        removeSuspendWindowIfNeeded()
        return view
    }

    /// 移除自定义 ViewController
    @discardableResult
    public func removeCustomViewController(forKey key: String) -> UIViewController? {
        guard customViewControllerHolder[key] != nil else { return nil }
        removeCustomView(forKey: key)
        customViewControllerHolder[key] = nil
        let viewController = suspendController?.removeCustomViewController(forKey: key)
        return viewController
    }
}

// MARK: - 添加/删除保护区域

extension SuspendManager {

    /// 添加保护区域
    /// - Parameters:
    ///   - rect: 保护区域的位置（坐标需转换为 UIScreen 的坐标系）
    ///   - key: 该保护区域的唯一标识（支持添加多个保护区域，用 key 区分）
    ///
    /// - 可通过调用 `view.superview?.convert(view.frame, to: nil)` 转换坐标系
    public func addProtectedZone(_ rect: CGRect, forKey key: String) {
        suspendController?.addProtectedZone(rect, forKey: key)
    }

    /// 移除保护区域
    /// - Parameter key: 通过 key 查找已添加的保护区域
    public func removeProtectedZone(forKey key: String) {
        suspendController?.removeProtectedZone(forKey: key)
    }

    /// 添加视图作为保护区域
    ///
    /// - SuspendManager 不会持有视图
    /// - 方法内部调用了 `addProtectedZone(:forKey:)`，内部已处理了坐标转换问题，
    /// 并使用 UIView 的指针地址作为 key。
    public func addMutexView(_ view: UIView) {
        let key = "\(Unmanaged.passUnretained(view).toOpaque())"
        if let frame = view.superview?.convert(view.frame, to: nil) {
            addProtectedZone(frame, forKey: key)
        }
    }

    /// 移除视图相应的保护区域
    ///
    /// - SuspendManager 不会持有视图
    public func removeMutexView(_ view: UIView) {
        let key = "\(Unmanaged.passUnretained(view).toOpaque())"
        removeProtectedZone(forKey: key)
    }
}

// MARK: - 自定义水印

extension SuspendManager {

    /// 添加/更新水印视图
    /// - Parameter view: 水印视图
    public func updateWatermark(_ view: UIView) {
        suspendController?.updateWatermark(view)
    }

    /// 移除水印视图
    public func removeWatermark() {
        suspendController?.removeWatermark()
    }
}

// MARK: - 监听键盘

extension SuspendManager {

    private func addKeyBoardObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    private func removeKeyBoardObserver() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc
    private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardRect = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
              let bubbleRect = suspendController?.bubbleView.frame else {
            return
        }
        if keyboardRect.intersects(bubbleRect) {
            setSuspendWindowHiddenInternal(true, animated: true)
        }
    }

    @objc
    private func keyboardWillHide(_ notification: Notification) {
        setSuspendWindowHiddenInternal(false, animated: true)
    }

}

// MARK: - 监听内存警告

extension SuspendManager {

    private func addMemoryWarningObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }

    private func removeMemoryWarningObserver() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }

    @objc
    private func didReceiveMemoryWarning() {
        vcHolder.removeAll()
    }
}

// MARK: - SuspendControllerDelegate

extension SuspendManager: SuspendControllerDelegate {

    func suspendController(_ controller: SuspendController, didSelectItem item: SuspendPatch) {
        suspendController?.hideDockList(animated: true)
        guard let topViewController = getTopViewController() else {
            return
        }
        // 顶层为普通 VC，直接 push
        guard let topSuspendable = topViewController as? ViewControllerSuspendable else {
            pushViewController(by: item, animated: true)
            return
        }
        // 顶层 VC 与当前待推入 VC 重复
        guard topSuspendable.suspendID != item.id else {
            return
        }
        // 对于热恢复的页面，除了判断 id，还要判断 VC 实例是否相同。
        // 防止网页类的页面内进行跳转，suspendID 变化而 VC 不变。
        if let savedVC = vcHolder[item.id],
           topViewController === savedVC {
            return
        }
        // iOS 12 下 replace 顶层页面，有可能会导致聊天页面无法又划关闭。
        // 复现路径：浮窗打开文档 -> 浮窗打开聊天覆盖文档。
        if #available(iOS 13, *) {} else {
            pushViewController(by: item, animated: true)
            return
        }
        // 如果顶层 VC 已在多任务列表，则替换顶层；否则直接 push
        if contains(suspendID: topSuspendable.suspendID) {
            showingIds.remove(topSuspendable.suspendID)
            updateSuspend(viewController: topSuspendable)
            replaceTopViewController(by: item, animated: true)
        } else {
            pushViewController(by: item, animated: true)
        }
    }

    func suspendController(_ controller: SuspendController, didDeleteItem item: SuspendPatch) {
        removeSuspendItem(byId: item.id)
        vcHolder[item.id] = nil
        if suspendItems.isEmpty {
            suspendController?.hideDockList(animated: true)
        }
        // 浮窗已满，删除已有项目以添加新项目
        if let completion = dockListRemovalCallback {
            dockListRemovalCallback = nil
            suspendController?.hideDockList(animated: false, completion: completion)
        }
    }

    func suspendControllerDidDeleteAllItems(_ controller: SuspendController) {
        removeAllSuspendItems()
        vcHolder.removeAll()
        suspendController?.hideDockList(animated: true)
        // 浮窗已满，删除已有项目以添加新项目
        if let completion = dockListRemovalCallback {
            dockListRemovalCallback = nil
            suspendController?.hideDockList(animated: false, completion: completion)
        }
    }

    func suspendControllerDidHideDockList(_ controller: SuspendController) {
        dockListRemovalCallback = nil
    }

    /// 通过 SuspendPatch 找到页面，并 push 进当前的 NavigationController
    func pushViewController(by item: SuspendPatch,
                            animated: Bool,
                            completion: ((Bool) -> Void)? = nil) {
        guard let pageURL = URL(string: item.url),
              let window = Navigator.shared.mainSceneWindow else { //Global
            completion?(false)
            return
        }
        if let savedVC = vcHolder[item.id], let navi = getTopViewController()?.navigationController {
            // replace stack
            navi.pushOrPopViewController(savedVC, animated: true, completion: {
                completion?(true)
            })
            return
        }

        var context = item.untreatedParams
        context[NavigationKeys.launcherFrom] = NavigationKeys.LauncherFrom.suspend
        Navigator.shared.getResource(pageURL, context: context) { [weak self] (resource) in //Global
            guard let self = self else { return }
            guard let targetVC: UIViewController = resource as? UIViewController else { return }
            Helper.rotateToPortraitIfNeeded(targetVC)
            Navigator.shared.push(targetVC, from: window, animated: animated) { //Global
                completion?(true)
            }
        }
    }

    /// 通过 SuspendPatch 找到页面，并替换当前 NavigationController 顶部的 VC
    func replaceTopViewController(by item: SuspendPatch,
                                  animated: Bool,
                                  completion: ((Bool) -> Void)? = nil) {
        guard let pageURL = URL(string: item.url),
              let navi = getTopViewController()?.navigationController else {
            completion?(false)
            return
        }
        if let savedVC = vcHolder[item.id] {
            navi.replaceTopViewController(with: savedVC, animated: true, completion: {
                completion?(true)
            })
            return
        }
        Navigator.shared.getResource(pageURL, context: item.untreatedParams) { resource in //Global
            guard let viewController = resource as? UIViewController else {
                completion?(false)
                return
            }
            navi.replaceTopViewController(with: viewController, animated: true, completion: {
                completion?(true)
            })
        }
    }

    /// 通过 SuspendPatch 找到页面，并在当前页面顶部 present 出来
    func presentViewController(by item: SuspendPatch,
                               animated: Bool,
                               completion: ((Bool) -> Void)? = nil) {
        // Currently not supported.
    }
}

extension SuspendManager {

    private func addSuspendWindowIfNeeded() {
        guard SuspendManager.isFloatingEnabled else { return }
        guard suspendWindow == nil else { return }
        guard !suspendItems.isEmpty || !customViewHolder.isEmpty else { return }
        if #available(iOS 13.0, *) {
            self.setupSuspendWindowByConnectScene()
        } else {
            self.setupSuspendWindowByApplicationDelegate()
        }

        guard let window = self.suspendWindow else { return }
        self.suspendWindow?.isHidden = false
        suspendController?.delegate = self
    }
    
    @available(iOS 13.0, *)
    private func setupSuspendWindowByConnectScene() {
        if let scene = UIApplication.shared.windowApplicationScenes.first,
           let windowScene = scene as? UIWindowScene,
           let rootWindow = Utility.rootWindowForScene(scene: windowScene) {
            self.suspendWindow = self.createSuspendWindow(window: rootWindow)
        }
    }

    private func setupSuspendWindowByApplicationDelegate() {
        guard let delegate = UIApplication.shared.delegate,
              let weakWindow = delegate.window,
              let rootWindow = weakWindow else {
            return
        }
        self.suspendWindow = self.createSuspendWindow(window: rootWindow)
    }

    private func createSuspendWindow(window: UIWindow) -> SuspendWindow {
        let suspendWindow = SuspendWindow(frame: window.bounds)
        if #available(iOS 13.0, *) {
            suspendWindow.windowScene = window.windowScene
        }
        return suspendWindow
    }
    
    private func removeSuspendWindowIfNeeded() {
        /*
        guard suspendItems.isEmpty else { return }
        guard customViewInternal == nil, customViewController == nil else { return }
        suspendWindow?.removeFromSuperview()
        suspendWindow = nil
         */
    }

    /// 显示/隐藏多任务浮窗
    public func setSuspendWindowHidden(_ isHidden: Bool, animated: Bool = true) {
        guard let suspendWindow = suspendWindow else { return }
        if animated {
            let prevAlpha = suspendWindow.alpha
            UIView.animate(withDuration: SuspendConfig.animateDuration, animations: {
                suspendWindow.alpha = isHidden ? 0 : 1
            }, completion: { success in
                suspendWindow.alpha = prevAlpha
                if success {
                    suspendWindow.isHidden = isHidden
                }
            })
        } else {
            suspendWindow.isHidden = isHidden
        }
    }

    private func setSuspendWindowHiddenInternal(_ isHidden: Bool, animated: Bool = true) {
        let alpha: CGFloat = isHidden ? 0 : 1
        changeSuspendWindowAlpha(alpha, animated: animated)
    }

    private func changeSuspendWindowAlpha(_ alpha: CGFloat, animated: Bool) {
        if animated {
            UIView.animate(withDuration: SuspendConfig.animateDuration) {
                self.suspendWindow?.alpha = alpha
            }
        } else {
            suspendWindow?.alpha = alpha
        }
    }
}

extension SuspendManager {

    /// Do NOT call this method manually in Lark / Messenger project.
    public static func swizzleViewControllerLifeCycle() {
        guard SuspendManager.isSuspendEnabled else { return }
        UINavigationController.initializeSuspendOnce()
        UIViewController.initializeSuspendOnceForViewController()
    }
}

/// 上报最近访问页面
extension SuspendManager {

    @available(*, deprecated, message: "已废弃，请直接使用 QuickLaunchService")
    func addRecentRecord(vc: TabContainable) {
        quickLaunchService.addRecentRecords(vc: vc)
    }

    @available(*, deprecated, message: "已废弃，请直接使用 TemporaryTabService")
    func addTemporaryTab(vc: TabContainable) {
        temporaryTabService.updateTab(vc)
    }

    @available(*, deprecated, message: "已废弃，请直接使用 TemporaryTabService")
    func showTemporaryTab(vc: TabContainable) {
        temporaryTabService.showTab(vc)
    }

    @available(*, deprecated, message: "已废弃，请直接使用 TemporaryTabService")
    func addPagePreservable(vc: PagePreservable) {
        pageKeeperService.cachePage(vc, with: nil)
    }

    @available(*, deprecated, message: "已废弃，请直接使用 QuickLaunchService")
    func pinToQuickLaunchWindow(vc: TabContainable) {
        quickLaunchService.pinToQuickLaunchWindow(vc: vc).subscribe().disposed(by: self.disposeBag)
    }
}
