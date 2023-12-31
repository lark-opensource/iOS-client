//
//  LarkSplitViewController+Navigation.swift
//  LarkSplitViewController
//
//  Created by Yaoguoguo on 2022/9/5.
//

import UIKit
import Foundation

/// 用了和旧版LarkSplitViewController一样的逻辑
extension SplitViewController {

    private func removeSecondaryVC() {
        let secondary = self.viewController(for: .secondary)
        secondary?.view.removeFromSuperview()
        secondary?.removeFromParent()
        self.childrenVC[.secondary] = nil
    }

    func mergeSideAndAndSecondary() {
        guard self.delegate?.splitViewControllerCanMergeSide(self) ?? true else {
            removeSecondaryVC()
            return
        }

        if checkNavigationInTransition(completion: { [weak self] in
            self?.mergeSideAndAndSecondary()
        }) {
            return
        }
        
        let masterAndDetailNavi = SplitViewController.mergeSideAndSecondary(split: self,
                                                                            sideWrapperNavigation: self.sideWrapperNavigation,
                                                                            secondaryNavigation: self.secondaryNavigation,
                                                                            animated: false)
        self.sideWrapperNavigation = masterAndDetailNavi.0
        self.secondaryNavigation = masterAndDetailNavi.1
    }

    func splitSideAndSecondaryViewController() {
        if checkNavigationInTransition(completion: { [weak self] in
            self?.splitSideAndSecondaryViewController()
        }) {
            return
        }
        let masterAndDetailNavi = SplitViewController.splitSecondaryFromSide(split: self,
                                                                             sideWrapperNavigation: self.sideWrapperNavigation,
                                                                             secondaryNavigation: self.secondaryNavigation)
        self.sideWrapperNavigation = masterAndDetailNavi.0
        self.secondaryNavigation = masterAndDetailNavi.1

        if secondaryNavigation?.viewControllers.isEmpty ?? false, let result = self.defaultVCProvider?() {
            secondaryNavigation?.viewControllers.append(result.defaultVC)
            NotificationCenter.default.post(name: SplitViewController.SecondaryControllerChange, object: self)
        }
    }

    func mergeCompactAndSecondary() {
        Self.logger.info("Merge Compact And Secondary VC")

        guard self.delegate?.splitViewControllerCanMergeCompact(self) ?? true else {
            removeSecondaryVC()
            return
        }

        if checkNavigationInTransition(completion: { [weak self] in
            self?.mergeCompactAndSecondary()
        }) {
            return
        }
        let masterAndDetailNavi = SplitViewController.mergeSideAndSecondary(split: self,
                                                                            sideWrapperNavigation: self.compactNavigation,
                                                                            secondaryNavigation: self.secondaryNavigation,
                                                                            animated: false)
        self.compactNavigation = masterAndDetailNavi.0
        self.secondaryNavigation = masterAndDetailNavi.1
        self.mergePresentedViewController()
    }

    func splitCompactAndSecondaryViewController() {
        Self.logger.info("Split Compact And Secondary VC")

        if checkNavigationInTransition(completion: { [weak self] in
            self?.splitCompactAndSecondaryViewController()
        }) {
            return
        }
        let masterAndDetailNavi = SplitViewController.splitSecondaryFromSide(split: self,
                                                                             sideWrapperNavigation: self.compactNavigation,
                                                                             secondaryNavigation: self.secondaryNavigation)
        self.compactNavigation = masterAndDetailNavi.0
        self.secondaryNavigation = masterAndDetailNavi.1
        self.splitPresentedViewController()

        if secondaryNavigation?.viewControllers.isEmpty ?? false, let result = self.defaultVCProvider?() {
            secondaryNavigation?.viewControllers.append(result.defaultVC)
            NotificationCenter.default.post(name: SplitViewController.SecondaryControllerChange, object: self)
        }
    }
    
    // 在调用此函数之前，应先判断是否在transition中
    // 在调用此函数之后，应判断detailNavi是否为空，为空显示default
    // 从masterNavigation中划分出DetaiNavigation
    fileprivate static func splitSecondaryFromSide(
        split: SplitViewController,
        sideWrapperNavigation: UINavigationController?,
        secondaryNavigation: UINavigationController?) -> (UINavigationController?, UINavigationController?) {

        checkVCTag(split: split, navi: sideWrapperNavigation)
        var detailVCArray: [UIViewController] = []
        for vc in sideWrapperNavigation?.viewControllers ?? [] {

            var childrenIdentifier = vc.childrenIdentifier

            if let custom = vc.customChildrenIdentifier {
                childrenIdentifier = custom
            }

            if childrenIdentifier.contains(.secondary) {
                vc.childrenIdentifier.insert(.isTransfering)
                detailVCArray.append(vc)
            }
        }
        if !detailVCArray.isEmpty {
            detailVCArray.forEach {
                $0.childrenIdentifier.remove(.isTransfering)
                $0.removeSelfFromParentVC()
            }
            sideWrapperNavigation?.viewControllers.removeAll(where: { detailVCArray.contains($0) })
            checkVCTag(split: split, navi: secondaryNavigation)
            secondaryNavigation?.viewControllers.append(contentsOf: detailVCArray)
        }
        return (sideWrapperNavigation, secondaryNavigation)
    }

    // 在调用此函数之前，应先判断是否在transition中，displayMode是否是masterAndDetail
    // 将detail和master合并进入masterNavi中
    fileprivate static func mergeSideAndSecondary(split: SplitViewController,
                                                  sideWrapperNavigation: UINavigationController?,
                                                  secondaryNavigation: UINavigationController?,
                                                  animated: Bool) -> (UINavigationController?, UINavigationController?) {
        var mergeVCArray: [UIViewController] = []

        // detail最后一个为default页面，不展示在master上
        if let vc = secondaryNavigation?.viewControllers.last, vc is DefaultDetailVC {
            secondaryNavigation?.viewControllers.removeLast()
            vc.removeFromParent()
        }

        // 不直接将所有的VC添加进入mergeVCArray的原因，是因为外部可能会不允许指定VC merge，需要调用方实现协议
        secondaryNavigation?.viewControllers.forEach({
            if split.delegate?.splitViewController(split, isMergeFor: $0) ?? true {
                $0.childrenIdentifier.insert(.isTransfering)
                mergeVCArray.append($0)
            }
        })

        // 没有需要merge的，则不需要做任何事情
        guard !mergeVCArray.isEmpty else { return (sideWrapperNavigation, secondaryNavigation) }
        secondaryNavigation?.viewControllers.removeAll(where: { mergeVCArray.contains($0) })
        mergeVCArray.forEach {
            $0.removeFromParent()
        }

        // 当view Controller为空的时候，无法刷新NavigationBar.items
        // 造成 detailNavigation 继续持有 mergeVC 的 NavigationItem
        // 引发显示 BUG
        if secondaryNavigation?.viewControllers.isEmpty ?? false {
            let placeholder = UIViewController()
            placeholder.supportSecondaryOnly = true
            secondaryNavigation?.setViewControllers([placeholder], animated: false)
            placeholder.removeSelfFromParentVC()
        }

        var masterVCs = sideWrapperNavigation?.viewControllers ?? []
        masterVCs.append(contentsOf: mergeVCArray)
        sideWrapperNavigation?.setViewControllers(masterVCs, animated: animated)

        if animated {
            DispatchQueue.main.async {
                mergeVCArray.forEach { $0.childrenIdentifier.remove(.isTransfering) }
            }
        } else {
            mergeVCArray.forEach { $0.childrenIdentifier.remove(.isTransfering) }
        }
        return (sideWrapperNavigation, secondaryNavigation)
    }
    
    func splitPresentedViewController() {
        DispatchQueue.global().async {
            let _ = self.presentSemaphore.wait(timeout: .now() + 5)
            DispatchQueue.main.async() {
                guard let presentedViewController = self.compactNavigation?.presentedViewController,
                      presentedViewController.modalPresentationStyle == .overCurrentContext ||
                        presentedViewController.modalPresentationStyle == .currentContext,
                        presentedViewController.childrenIdentifier.contains(.secondary) else {
                    self.presentSemaphore.signal()
                    return
                }
                presentedViewController.childrenIdentifier.insert(.isTransfering)
                self.compactNavigation?.dismiss(animated: false, completion: {
                    self.secondaryNavigation?.present(presentedViewController, animated: false, completion: { [weak self] in
                        presentedViewController.childrenIdentifier.remove(.isTransfering)
                        self?.presentSemaphore.signal()
                    })
                })
            }
        }
    }

    func mergePresentedViewController() {
        DispatchQueue.global().async {
            let _ = self.presentSemaphore.wait(timeout: .now() + 5)
            DispatchQueue.main.async() {
                guard let presentedViewController = self.secondaryNavigation?.presentedViewController,
                      presentedViewController.modalPresentationStyle == .overCurrentContext ||
                        presentedViewController.modalPresentationStyle == .currentContext,
                      presentedViewController.childrenIdentifier.contains(.secondary) else {
                    self.presentSemaphore.signal()
                    return
                }
                presentedViewController.childrenIdentifier.insert(.isTransfering)
                self.secondaryNavigation?.dismiss(animated: false, completion: {
                    self.compactNavigation?.present(presentedViewController, animated: false, completion: { [weak self] in
                        presentedViewController.childrenIdentifier.remove(.isTransfering)
                        self?.presentSemaphore.signal()
                    })
                })
            }
        }
    }

    // 检查navi中的各个VC的标记是否缺失
    // 如果缺失，进行补充
    static func checkVCTag(split: SplitViewController, navi: UINavigationController?) {
        guard let navi = navi else { return }
        // 检查第一个VC是否有标记，如果没有标记，根据他是detailNavi还是masterNavi分别标上不同的标记
        if let vc = navi.viewControllers.first, vc.childrenIdentifier == .init(identifier: [.undefined]) {
            vc.childrenIdentifier.splitViewController = split
            if navi == split.secondaryNavigation {
                vc.childrenIdentifier = .init(identifier: [.secondary, .initial])
                markChildrenTag(vc)
            } else {
                vc.childrenIdentifier = .init(identifier: [.primary, .initial])
                markChildrenTag(vc)
            }
        }

        for (index, vc) in navi.viewControllers.enumerated() {
            vc.childrenIdentifier.splitViewController = split
            if vc.childrenIdentifier == .init(identifier: [.undefined]) {
                // 如果不是第一个VC缺失，则根据前一个VC的标记，做当前VC的标记
                vc.childrenIdentifier = navi.viewControllers[index - 1].childrenIdentifier
                markChildrenTag(vc)
            } else {
                markChildrenTag(vc)
            }
        }
    }
    
    // 标记VC下的childrenVC的tag
    static func markChildrenTag(_ vc: UIViewController) {
        vc.children.forEach { childVC in
            if childVC.childrenIdentifier == .init(identifier: [.undefined]) {
                childVC.childrenIdentifier = vc.childrenIdentifier
            }
            childVC.childrenIdentifier.splitViewController = vc.childrenIdentifier.splitViewController
            // 递归调用
            if !childVC.children.isEmpty {
                markChildrenTag(childVC)
            }
        }
    }
}
