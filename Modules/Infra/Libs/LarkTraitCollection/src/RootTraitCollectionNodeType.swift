//
//  RootTraitCollectionNodeType.swift
//  LarkUIKit
//
//  Created by Meng on 2019/9/10.
//

import UIKit
import Foundation

public protocol RootTraitCollectionNodeType: UITraitEnvironment {
    var nodeView: UIView? { get }

    var nodeViewController: UIViewController? { get }

    var nodeWindow: UIWindow? { get }

    #if canImport(Combine)
    @available(iOS 13.0, *)
    var nodeWindowScene: UIWindowScene? { get }
    #endif

    func customChildNode(vc: UIViewController) -> Bool
}

extension UIView: RootTraitCollectionNodeType {
    public var nodeView: UIView? {
        return self
    }

    public var nodeViewController: UIViewController? {
        return viewController()
    }

    public var nodeWindow: UIWindow? {
        return window
    }

    #if canImport(Combine)
    @available(iOS 13.0, *)
    public var nodeWindowScene: UIWindowScene? {
        return window?.windowScene
    }
    #endif

    @objc
    open func customChildNode(vc: UIViewController) -> Bool {
        return false
    }
}

extension UIViewController: RootTraitCollectionNodeType {
    public var nodeView: UIView? {
        return view
    }

    public var nodeViewController: UIViewController? {
        return self
    }

    public var nodeWindow: UIWindow? {
        return view.window
    }

    #if canImport(Combine)
    @available(iOS 13.0, *)
    public var nodeWindowScene: UIWindowScene? {
        return view.window?.windowScene
    }
    #endif

    @objc
    open func customChildNode(vc: UIViewController) -> Bool {
        return false
    }
}

extension RootTraitCollectionNodeType {
    private var needCheck: Bool {
//        #if canImport(Combine)
//        if #available(iOS 13.0, *), UIApplication.shared.supportsMultipleScenes {
//            return true
//        }
//        #endif
//        return false

        // 先默认全部检查，在尽可能多的环境（iOS 10-13）中测试RootTraitCollection
        // 待稳定后打开上面的注释, 用于iOS 13 & 多窗口场景
        return true
    }

    @inline(__always)
    func checkNeedNotifyRootChange(of childNode: RootTraitCollectionNodeType) -> Bool {
        return !needCheck
            || checkNodeWindowScene(childNode)
            || checkNodeWindows(childNode)
            || checkNodeViewController(childNode)
            || checkNodeView(childNode)
    }

    @inline(__always)
    private func checkNodeWindowScene(_ childNode: RootTraitCollectionNodeType) -> Bool {
        #if canImport(Combine)
        if #available(iOS 13.0, *) {
            return nodeWindowScene === childNode.nodeWindowScene
        }
        #endif
        return false
    }

    @inline(__always)
    private func checkNodeWindows(_ childNode: RootTraitCollectionNodeType) -> Bool {
        return nodeWindow === childNode.nodeWindow
    }

    private func checkNodeViewController(_ childNode: RootTraitCollectionNodeType) -> Bool {
        guard let rootVC = nodeViewController, let childNodeVC = childNode.nodeViewController else { return false }
        return rootVC === childNodeVC
            || rootVC === childNodeVC.parent
            || rootVC === childNodeVC.presentingViewController
            || rootVC === childNodeVC.navigationController
            || rootVC === childNodeVC.tabBarController
            || rootVC === childNodeVC.splitViewController
            || (rootVC as? UIPageViewController)?.viewControllers?.contains(where: { $0 === childNodeVC }) ?? false
            || (childNodeVC.parent != nil && checkNodeViewController(childNodeVC.parent!))
            || (childNodeVC.presentingViewController != nil &&
                    checkNodeViewController(
                        childNodeVC.presentingViewController!
                    )
                )
            || (childNodeVC.navigationController != nil && checkNodeViewController(childNodeVC.navigationController!))
            || (childNodeVC.tabBarController != nil && checkNodeViewController(childNodeVC.tabBarController!))
            || (childNodeVC.splitViewController != nil && checkNodeViewController(childNodeVC.splitViewController!))
            || customChildNode(vc: childNodeVC)
    }

    @inline(__always)
    private func checkNodeView(_ childNode: RootTraitCollectionNodeType) -> Bool {
        guard let rootView = nodeView, let childNodeView = childNode.nodeView else { return false }
        return rootView === childNodeView
            || childNodeView.isDescendant(of: rootView)
    }
}
