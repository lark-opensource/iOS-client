//
//  FeedMainViewController+FeedPresentProcessorDelegate.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/12/22.
//

import UIKit
import Foundation
import EENavigator
import RxSwift
import LarkUIKit
import LarkTraitCollection

extension FeedMainViewController: FeedPresentProcessorDelegate {
    func showPresent(for type: PresentType, source: PopoverSource?, completion: @escaping (FeedPresentAnimationViewController) -> Void) {

        let dismissAction: () -> Void = { [weak self] in
            guard let self = self else { return }
            self.presentProcessor.dismissCurrentIfNeeded(checkType: type)
        }

        switch type {
        case .filterType:
            break
        case .floatAction:
            presentFromFloatAction(source: source, dismissAction: dismissAction, completion: completion)
        }
    }

    func present(source: PopoverSource?,
                 compactVC: () -> FeedPresentAnimationViewController,
                 regularVC: () -> FeedPresentAnimationViewController,
                 completion: @escaping (FeedPresentAnimationViewController) -> Void) {
        let presentVC: FeedPresentAnimationViewController
        let animated: Bool
        var isCollapsed: Bool
        if let larkSplitViewController = self.larkSplitViewController {
            isCollapsed = larkSplitViewController.isCollapsed
        } else {
            isCollapsed = self.view.horizontalSizeClass != .regular
        }
        if !isCollapsed {
            animated = true
            presentVC = regularVC()
            presentVC.modalPresentationStyle = .popover
            presentVC.popoverPresentationController?.backgroundColor = UIColor.ud.bgFloat
            presentVC.popoverPresentationController?.sourceView = source?.sourceView
            presentVC.popoverPresentationController?.sourceRect = source?.sourceRect ?? .zero
            presentVC.popoverPresentationController?.delegate = presentProcessor
        } else {
            animated = false
            presentVC = compactVC()
            presentVC.modalPresentationStyle = .overFullScreen
        }
        navigator.present(presentVC, from: self, animated: animated, completion: { completion(presentVC) })
    }

    /// CR切换时，需要dismiss present的(filterType/filterCard/floatAction)
    func dismissProcesserWhenTransition() {
        guard Display.pad else { return }
        RootTraitCollection.observer
            .observeRootTraitCollectionWillChange(for: self)
            .subscribe(onNext: { [weak self] _ in
                self?.presentProcessor.dismissCurrentIfNeeded(animate: false) {}
            }).disposed(by: disposeBag)
    }
}
