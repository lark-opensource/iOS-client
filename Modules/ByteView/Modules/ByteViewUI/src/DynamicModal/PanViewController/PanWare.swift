//
//  PanWare.swift
//  ByteRtcRenderDemo
//
//  Created by huangshun on 2019/10/17.
//  Copyright © 2019 huangshun. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class PanWare: NSObject {

    let wrapper: PanWrapperView

    let viewController: UIViewController

    var layoutGuide: UILayoutGuide?

    var panProxy: PanChildViewControllerProtocol {

        guard let panProxy = viewController as? PanChildViewControllerProtocol
            else { return PanViewControllerProtocolWrapper.default }

        return panProxy
    }

    var gestureDelegate: UIGestureRecognizerDelegate {
        return self
    }

    init(wrapper: PanWrapperView, viewController: UIViewController) {
        self.wrapper = wrapper
        self.viewController = viewController
        super.init()
        self.configWrapper(wrapper)
    }

    func configWrapper(_ wrapper: PanWrapperView) {
//        wrapper.barForegroundView.backgroundColor = panProxy.maskColor
//        wrapper.foregroundView.backgroundColor = panProxy.maskColor
        wrapper.barView.backgroundColor = panProxy.backgroudColor
        wrapper.barView.isHidden = !panProxy.showBarView
        wrapper.bottomView.backgroundColor = panProxy.backgroudColor
        wrapper.icon.backgroundColor = panProxy.indicatorColor
        wrapper.icon.isHidden = !panProxy.showDragIndicator
        panProxy.configurePanWareContentView(wrapper.contentView)
        wrapper.configTopCorner()
    }

    func containerHeight(_ view: UIView, layout: RoadLayout) -> CGFloat {
        let axis = orientation.roadAxis
        let height = panProxy.height(axis, layout: layout)

        switch height {
        case let .contentHeight(value, minTopInset):
            let w = view.window ?? UIApplication.shared.windows.first(where: { $0.isKeyWindow })
            let safeAreaBottom: CGFloat = w?.safeAreaInsets.bottom ?? 0
            let contentHeight = value + safeAreaBottom
            let max = view.bounds.height - minTopInset
            return min(contentHeight, max)
        case let .maxHeightWithTopInset(value):
            return view.bounds.size.height - value
        case .intrinsicHeight:
            let content = viewController.view
            let targetSize = CGSize(
                width: view.bounds.width,
                height: UIView.layoutFittingCompressedSize.height
            )
            return content?.systemLayoutSizeFitting(targetSize).height ?? 0
        }
    }

    func containerWidth(_ layout: RoadLayout, make: ConstraintMaker) {
        let axis = orientation.roadAxis
        let width = panProxy.width(axis, layout: layout)

        switch width {
        case .fullWidth:
            make.left.right.equalToSuperview()
        case let .inset(left, right):
            make.left.equalToSuperview().offset(left)
            make.right.equalToSuperview().offset(-right)
        case let .maxWidth(width):
            make.centerX.equalToSuperview()
            make.left.right.equalToSuperview().priority(.low)
            make.width.lessThanOrEqualTo(width)
        }
    }

    func updateLayout(_ top: CGFloat, view: UIView) {
        let expand = containerHeight(view, layout: .expand)
        let shrink = containerHeight(view, layout: .shrink)

        // 上下移动高度不变, 达到压缩值底部下沉
        var height = view.bounds.height - top
        height = height < shrink ? shrink : height
        height = height > expand ? expand : height

        let bottom = top + height - view.bounds.height
        if bottom < 0 { return }

        layoutGuide?.snp.updateConstraints({ (make) in
            make.height.equalTo(height)
            make.bottom.equalTo(view).offset(bottom)
        })

        /** 临时去掉新滑动交互, 滚动时pan手势state 终止于 change 导致未能还原真实高度 **/
        // 更新高度时取消scrollble当前滑动的手势
//        panProxy.panScrollable?.panGestureRecognizer.isEnabled = false
//        panProxy.panScrollable?.panGestureRecognizer.isEnabled = true
    }

    func makeAutoLayoutIfNeed(_ layout: RoadLayout, view: UIView) -> UILayoutGuide {
        if let autoLayout = layoutGuide {
            return autoLayout
        }
        let newLayout = UILayoutGuide()
        view.addLayoutGuide(newLayout)
        newLayout.snp.makeConstraints({ (make) in
            containerWidth(layout, make: make)
            make.bottom.equalTo(view)
            make.height.equalTo(containerHeight(view, layout: layout))
        })
        wrapper.snp.makeConstraints { (make) in
            make.edges.equalTo(newLayout.snp.edges)
        }
        layoutGuide = newLayout
        return newLayout
    }

    func resetLayout(_ layout: RoadLayout, view: UIView) {
        guard wrapper.superview != nil else { return }
        let layoutGuide = makeAutoLayoutIfNeed(layout, view: view)
        layoutGuide.snp.remakeConstraints({ (make) in
            containerWidth(layout, make: make)
            make.bottom.equalTo(view)
            make.height.equalTo(containerHeight(view, layout: layout))
        })
        wrapper.snp.remakeConstraints { (make) in
            make.edges.equalTo(layoutGuide.snp.edges)
        }
    }

    func updateLayoutUnderBottom(_ view: UIView, layout: RoadLayout) {
        let layoutGuide = makeAutoLayoutIfNeed(layout, view: view)
        layoutGuide.snp.updateConstraints({ (make) in
            make.bottom.equalTo(view).offset(containerHeight(view, layout: layout))
        })
    }
}

fileprivate extension UIView {
    var orientation: UIInterfaceOrientation? {
        if #available(iOS 13.0, *) {
            if let scene = self.window?.windowScene {
                return scene.interfaceOrientation
            }
            return nil
        } else {
            return UIApplication.shared.statusBarOrientation
        }
    }

    var isLandscape: Bool {
        orientation?.isLandscape ?? (UIDevice.current.userInterfaceIdiom == .pad ? true : false)
    }
}

extension PanWare {
    var orientation: UIInterfaceOrientation {
        // 优先取当前view的方向
        if let currentOrientation = wrapper.orientation {
            return currentOrientation
        }
        // 取不到取presentingViewController的方向
        if let currentOrientation = viewController.presentingViewController?.view.orientation {
            return currentOrientation
        }
        // 还取不到就取statusBarOrientation作为兜底，理论上不应该走到最后这种情况
        return UIApplication.shared.statusBarOrientation
    }
}
