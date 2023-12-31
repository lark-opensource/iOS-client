//
//  FeedMainViewController+PopOverFilter.swift
//  LarkFeed
//
//  Created by xiaruzhen on 2023/11/19.
//

import Foundation
import UniverseDesignTabs
import RustPB
import RxSwift
import RxCocoa

protocol PopoveContentControllerProvider: UIViewController {
    func getPopovePageHeight() -> CGFloat
}

protocol PopoveContentControllerDelegate: AnyObject {
    func popoveContentSizeChanged()
}

extension FeedMainViewController: PopoveContentControllerDelegate {
    struct Distance {
        let topDistance: CGFloat
        let bottomDistance: CGFloat
    }

    private static let filterPopoveControllerWidth: CGFloat = 320

    func popover(sendar: UIView) {
        guard let filterListViewModel = try? userResolver.resolve(assert: FeedFilterListViewModel.self) else { return }

        let contentVC = FeedFilterListViewController(
            viewModel: filterListViewModel)
        self.filterPopoveController = contentVC
        contentVC.modalPresentationStyle = .popover
        contentVC.delegate = self

        let popoverVC = contentVC.popoverPresentationController
        popoverVC?.sourceView = sendar // 设置弹出式视图的源视图

        //popVC?.delegate = self // 设置委托对象
        //popVC?.popoverLayoutMargins = UIEdgeInsets(top: 30, left: 0, bottom: 30, right: 0)

        let sendarDistance = self.getSendarDistanceToWindow(view: sendar)
        let contentPageHeight = contentVC.getPopovePageHeight()
        let arrowDirection = self.calPositon(distance: sendarDistance, contentHeight: contentPageHeight)
        let arrowMargin: CGFloat = 6
        var arrowYMargin: CGFloat = 0
        var arrowRMargin: CGFloat = 0
        if arrowDirection == .up {
            arrowYMargin = arrowMargin
            arrowRMargin = 0
        } else if arrowDirection == .down {
            arrowYMargin = -arrowMargin
            arrowRMargin = 0
        } else if arrowDirection == .left {
            arrowYMargin = 0
            arrowRMargin = arrowMargin
        }
        popoverVC?.sourceRect = CGRect(x: arrowRMargin, y: arrowYMargin, width: sendar.bounds.size.width, height: sendar.bounds.size.height) // 设置弹出式视图的源矩形

        popoverVC?.permittedArrowDirections = arrowDirection // 设置箭头的方向
        contentVC.preferredContentSize = CGSize(width: Self.filterPopoveControllerWidth, height: contentPageHeight)

        self.present(contentVC, animated: true)
    }

    private func getSendarDistanceToWindow(view: UIView) -> Distance {
        guard let window = self.view.window ?? self.userResolver.navigator.mainSceneWindow else {
            return FeedMainViewController.Distance(topDistance: 0, bottomDistance: 0)
        }
        let vMargin: CGFloat = 30
        let y = view.convert(view.bounds, to: window).origin.y
        let topDistance = view.convert(view.bounds, to: window).origin.y - vMargin
        let bottomDistance = window.bounds.size.height - y - view.bounds.size.height - vMargin
        return Distance(topDistance: topDistance, bottomDistance: bottomDistance)
    }

    private func calPositon(distance: Distance, contentHeight: CGFloat) -> UIPopoverArrowDirection {
        if distance.bottomDistance >= contentHeight {
            return .up
        } else if distance.topDistance >= contentHeight {
            return .down
        }
        return .left
    }

    func popoveContentSizeChanged() {
        let pageHeight = self.filterPopoveController?.getPopovePageHeight() ?? 0
        UIView.animate(withDuration: 0.1, animations: { [weak self] in
            self?.filterPopoveController?.preferredContentSize = CGSize(width: Self.filterPopoveControllerWidth, height: pageHeight)
        })
    }
}
