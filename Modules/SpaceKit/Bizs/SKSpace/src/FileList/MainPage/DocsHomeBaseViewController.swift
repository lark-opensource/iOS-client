//
//  DocsHomeBaseViewController.swift
//  SpaceKit
//
//  Created by nine on 2019/10/19.
//

import Foundation
import RxSwift
import RxRelay
import LarkUIKit
import SKCommon
import SKFoundation
import SKResource

/// 用于和Lark导航栏通信
public protocol DocsHomeNavBarDelegate: AnyObject {
    // Naviba Bar 本 bar 提供的接口
    var larkNaviBarTitleView: UIView? { get }
    var larkNaviCreateButton: UIButton? { get }
    /// 改变Lark导航栏显示状态
    func changeLarkNaviBarPresentation(show: Bool?, animated: Bool)
}

/// 在Docs首页加入到DocsTabBarController中的VC需要继承于这个类，才能调用相关方法与Lark导航栏通信
/// 使用文档:https://bytedance.feishu.cn/space/doc/doccnVD6PS7oMjXJw9tFinrFklp#
open class DocsHomeBaseViewController: BaseViewController, DocsNaviBarDataSource, DocsNaviBarDelegate {
    public var isDefaultSearchButtonDisabled: Bool = false

    private var firstNavBarItem: NavigationBarItem?
    private var secondNavBarItem: NavigationBarItem?


    /// 调用Lark导航栏的相关方法
    public weak var larkNavDelegate: DocsHomeNavBarDelegate? {
        didSet {
            // 导航栏除了可以被setNavigationBarHidden控制，在上下移动时俊林的animator会对他进行透明度设置，所以animator也需要能够和lark导航栏通信
            animator.larkNavBarDelegate = larkNavDelegate
        }
    }

    // provide for SpaceDemo
    public var navBarDelegate: DocsHomeAnimatorNavBarDelegate? {
        get { return animator.navBarDelegate }
        set { animator.navBarDelegate = newValue }
    }

    public lazy var animator: DocsHomeAnimator = {
        let animator = DocsHomeAnimator()
        animator.larkNavBarDelegate = larkNavDelegate
        return animator
    }()
    
    /// 导航栏左侧标题
    var navTitle: String {
        return title ?? ""
    }
    /// Lark导航栏右侧按钮，最多两个。搜索图标会固定写死在第一个
    var larkNavBarItems: [NavigationBarItem] = [] {
        didSet {
            larkNavBarItems.enumerated().forEach { (index, item) in
                switch index {
                case 0:
                    firstNavBarItem = item
                case 1:
                    secondNavBarItem = item
                default:
                    spaceAssertionFailure("不支持超过2个以外的导航栏按钮")
                }
            }
        }
    }

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func setNavigationBarHidden(_ hidden: Bool, animated: Bool) {
        super.setNavigationBarHidden(hidden, animated: animated)
        // 控制lark的导航栏
        larkNavDelegate?.changeLarkNaviBarPresentation(show: !hidden, animated: animated)
    }
    // MARK: - DocsNaviBarDataSource
    public var titleTextBridge: BehaviorRelay<String> {
        return BehaviorRelay(value: navTitle)
    }
    public func larkNaviBarBridge(userDefinedButtonOf type: DocsNaviButtonType) -> UIButton? {
        switch type {
        case .first:
            return nil
        case .second:
            return nil
        default:
            break
        }
        return nil
    }
    // MARK: - DocsNaviBarDelegate
    public func onButtonTappedBridge(on button: UIButton, with type: DocsNaviButtonType) {
        switch type {
        case .first:
            firstNavBarItem?.action(button)
        case .second:
            secondNavBarItem?.action(button)
        default:
            break
        }
    }
}

public extension DocsHomeBaseViewController {
    struct NavigationBarItem {
        let image: UIImage?
        let action: (UIButton) -> Void?
    }
}
