import Foundation
import UIKit

@objc
public protocol KATabProtocol {
    /// appId，和开平申请的 appId 一致
    var appId: String { get }
    /// 是否展示 navi bar
    var showNaviBar: Bool { get }
    /// tab 对应的 ViewController
    var tabViewController: () -> UIViewController { get }
    /// navi bar 上方右侧第一个按钮，无需设置 size（会自动调整大小），仅当 showNaviBar 为 true 时生效，入参为 tabViewController
    var firstNaviBarButton: ((UIViewController) -> UIButton?)? { get }
    /// navi bar 上方右侧第二个按钮，无需设置 size（会自动调整大小），仅当 showNaviBar 为 true 时生效，入参为 tabViewController
    var secondNaviBarButton: ((UIViewController) -> UIButton?)? { get }
    /// navi bar 标题，仅当 showNaviBar 为 true 时生效
    var naviBarTitle: String? { get }
    /// tab 单击事件
    var tabSingleClick: (() -> Void)? { get }
    /// tab 双击事件
    var tabDoubleClick: (() -> Void)? { get }
}

public extension KATabProtocol {
    var firstNaviBarButton: ((UIViewController) -> UIButton?)? {
        nil
    }
    var secondNaviBarButton: ((UIViewController) -> UIButton?)? {
        nil
    }
    var naviBarTitle: String? {
        nil
    }
    var tabSingleClick: (() -> Void)? {
        nil
    }
    var tabDoubleClick: (() -> Void)? {
        nil
    }
}

@objcMembers
public class KATabExternal: NSObject {
    public override init() {
    }
    public static let shared = KATabExternal()
    var delegates: [KATabProtocol] = []
    public static func getTabs() -> [KATabConfig] {
        shared.delegates.map(KATabConfig.init(config:))
    }
    public static func register(delegate: KATabProtocol) {
        shared.delegates.append(delegate)
    }
}

public struct KATabConfig {
    public let tabViewController: () -> UIViewController
    public let appId: String
    public let showNaviBar: Bool
    public let firstNaviBarButton: ((UIViewController) -> UIButton?)?
    public let secondNaviBarButton: ((UIViewController) -> UIButton?)?
    public let naviBarTitle: String?
    public let tabSingleClick: (() -> Void)?
    public let tabDoubleClick: (() -> Void)?
    fileprivate init(config: KATabProtocol) {
      tabViewController = config.tabViewController
      appId = config.appId
      showNaviBar = config.showNaviBar
      firstNaviBarButton = config.firstNaviBarButton
      secondNaviBarButton = config.secondNaviBarButton
      naviBarTitle = config.naviBarTitle
      tabSingleClick = config.tabSingleClick
      tabDoubleClick = config.tabDoubleClick
    }
}

