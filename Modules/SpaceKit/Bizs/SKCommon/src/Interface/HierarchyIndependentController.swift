//
//  HierarchyIndependentController.swift
//  SKCommon
//
//  Created by huayufan on 2022/5/30.
//  


import UIKit
import SKFoundation

/// viewController以modal方式呈现出来时，支持dimiss
/// 中间viewController而不影响上层viewController展示
/// 比如当前VC结构：
/// A-->B-->C
/// 可以 dismiss B掉不影响C的展示，每个业务的根控制器继承自本协议即可
/// 并且被高优先级的present时，会自动调整层级
public protocol HierarchyIndependentController: AnyObject {
    
    /// 标识不同业务
    var businessIdentifier: String { get }
    
    var preventFlashing: Bool { get }
    
    /// 关掉自己保留顶部仍需要显示的控制器
    func priorityDismissSelf(animated: Bool, completion: (() -> Void)?)
    
    
    /// 如果topMost的优先级更高，需要将topMost 和当前要展示的层级调整
    func priorityPresentSelf(with topMost: UIViewController, animated: Bool, completion: (() -> Void)?)
    
    /// 优先级越大层级越高, 目前只用于priorityPresentSelf作为判断依据
    var hierarchyPriority: HierarchyIndependentPriority { get }
    
    /// 是否允许再次被present（防止异步原因，再被present时其实已经被dismiss了，这种时候不需要被展示出来）
    var representEnable: Bool { get }
}
    
extension HierarchyIndependentController where Self: UIViewController {
    
    public var preventFlashing: Bool {
        return false
    }
    
    
    /// 关掉自己保留顶部仍需要显示的控制器
    public func priorityDismissSelf(animated: Bool, completion: (() -> Void)?) {
        guard let vc = findIndependentController() else {
            self.presentingViewController?.dismiss(animated: animated, completion: completion)
            return
        }
        guard let parentVC = self.presentingViewController else { return }
        
        var imageView: UIImageView?
        if preventFlashing, let imgView = getCurrentSnapshot() {
            self.view.window?.addSubview(imgView)
            // 防止移除失败，2s后超时自动移除
            imageView?.removeFromSuperview(after: 2)
            imageView = imgView
        }
        let vcs = self.linkControllers(with: vc)
        DocsLogger.info("[Hierarchy Present] number of vcs:\(vcs.count) on top level", component: LogComponents.commentPic)
        vcs.forEach {
           let vc = ($0 as? HierarchyIndependentController)
            if vc?.representEnable == true {
                vc?.isBeingExchanging = true
            }
        }
        parentVC.dismiss(animated: false) { [weak parentVC] in
            guard let vc = parentVC else { return }
            vcs.forEach {
                ($0 as? HierarchyIndependentController)?.isBeingExchanging = false
            }
            self.restoreControllers(parentVC: vc, vcs: vcs, animated: false) {
                completion?()
                imageView?.removeFromSuperview()
            }
        }
    }
    
    public func priorityPresentSelf(with topMost: UIViewController, animated: Bool, completion: (() -> Void)?) {
        guard let topMostVC = topMost as? HierarchyIndependentController,
              topMostVC.businessIdentifier != businessIdentifier,
              topMostVC.hierarchyPriority.rawValue > hierarchyPriority.rawValue,
             let grandVC = topMost.presentingViewController else {
            // 不需要处理
            topMost.present(self, animated: animated, completion: completion)
            return
        }
        DocsLogger.info("[Hierarchy Present] exchange [\(topMostVC.businessIdentifier)] -> [\(businessIdentifier)]", component: LogComponents.commentPic)
        // 开始调换层级
        topMostVC.isBeingExchanging = true
        topMost.dismiss(animated: false) { [weak topMost] in
            guard let topMost = topMost else { return }
            (topMost as? HierarchyIndependentController)?.isBeingExchanging = false
            grandVC.present(self, animated: false) { [weak topMost] in
                guard let tempVC = topMost else { return }
                self.present(tempVC, animated: false)
            }
        }
    }
    
    
}

extension HierarchyIndependentController where Self: UIViewController {
    
    fileprivate func restoreControllers(parentVC: UIViewController, vcs: [UIViewController], animated: Bool, completion: (() -> Void)?) {
        guard vcs.isEmpty == false else {
            completion?()
            return
        }
        var controllers = vcs
        let vc = controllers.removeFirst()
        if let hierarchyVC = vc as? HierarchyIndependentController, hierarchyVC.representEnable == false {
            DocsLogger.info("[Hierarchy Present] representEnable is false", component: LogComponents.commentPic)
            return
        }
        if vc.presentingViewController != nil {
            vc.dismiss(animated: animated) { [weak vc] in
                guard let vc = vc else { return }
                if let hierarchyVC = vc as? HierarchyIndependentController, hierarchyVC.representEnable == false {
                    DocsLogger.info("[Hierarchy Present] representEnable is false", component: LogComponents.commentPic)
                    return
                }
                DocsLogger.info("[Hierarchy Present] present vc:\(vc)", component: LogComponents.commentPic)
                parentVC.present(vc, animated: animated) { [weak vc] in
                    guard let vc = vc else { return }
                    self.restoreControllers(parentVC: vc, vcs: controllers, animated: animated, completion: completion)
                }
            }
        } else {
            parentVC.present(vc, animated: animated) {
                if let hierarchyVC = vc as? HierarchyIndependentController, hierarchyVC.representEnable == false {
                    DocsLogger.info("[Hierarchy Present] representEnable is false", component: LogComponents.commentPic)
                    return
                }
                DocsLogger.info("[Hierarchy Present] present vc:\(vc)", component: LogComponents.commentPic)
                self.restoreControllers(parentVC: vc, vcs: controllers, animated: animated, completion: completion)
            }
        }
    }
    
    fileprivate func linkControllers(with node: UIViewController) -> [UIViewController] {
        var vcs: [UIViewController] = []
        var current: UIViewController? = node
        vcs.append(node)
        while let vc = current?.presentedViewController {
            vcs.append(vc)
            current = vc
        }
        return vcs
    }
    
    fileprivate func findIndependentController() -> UIViewController? {
        var vc = self.presentedViewController
        while vc != nil {
            if let aVC = vc as? HierarchyIndependentController,
               aVC.businessIdentifier != businessIdentifier,
               vc?.isBeingDismissed == false {
                DocsLogger.info("[Hierarchy Present] find identifier:\(aVC.businessIdentifier) on top level", component: LogComponents.commentPic)
                return vc
            }
            vc = vc?.presentedViewController
        }
        return nil
    }
    
    fileprivate func getCurrentSnapshot() -> UIImageView? {
        let currentLayer = self.view.window?.layer ?? view.layer
        var bounds = self.view.window?.bounds ?? self.view.bounds
        if bounds.size.width == 0 { bounds.size.width = 1 }
        if bounds.size.height == 0 { bounds.size.height = 1 }
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.main.scale)
        var image: UIImage?
        if let context = UIGraphicsGetCurrentContext() {
            currentLayer.render(in: context)
            image = UIGraphicsGetImageFromCurrentImageContext()
        }
        UIGraphicsEndImageContext()
        if let img = image {
            let imgView = UIImageView(frame: bounds)
            imgView.frame = bounds
            imgView.image = img
            return imgView
        }
        return nil
    }
}

private struct HierarchyIndependentAssociatedKey {
    static var beingExchanging = "beingExchanging"
}

extension HierarchyIndependentController  {
    /// 是否正在做视图层级调换，这时并不是真正的dismiss
    var isBeingExchanging: Bool {
        get {
            let obj = objc_getAssociatedObject(self, &HierarchyIndependentAssociatedKey.beingExchanging) as? Bool
            return obj ?? false
        }
        set {
            objc_setAssociatedObject(self, &HierarchyIndependentAssociatedKey.beingExchanging, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

extension UIImageView {
    
    func removeFromSuperview(after overtime: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(overtime), execute: { [weak self] in
            self?.removeFromSuperview()
        })
    }
}


public enum HierarchyIndependentPriority: Int {
    
    case comment = 10
    
    case docImage = 20 // MS不支持图片评论，图片理应要显示在评论上面
    
    case commentImage = 30
}
