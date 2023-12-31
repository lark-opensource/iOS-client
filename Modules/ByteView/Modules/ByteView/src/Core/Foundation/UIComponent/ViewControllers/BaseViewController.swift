//
//  BaseViewController.swift
//  ByteView
//
//  Created by kiri on 2020/7/21.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit
import UniverseDesignIcon
import ByteViewCommon
import ByteViewUI

// 布局的三种情况，尽可能不直接依赖方向，依赖该值作为布局参考
enum LayoutType {
    case regular
    case compact
    case phoneLandscape

    var isRegular: Bool {
        return self == .regular
    }

    var isPhoneLandscape: Bool {
        return self == .phoneLandscape
    }

    var isCompact: Bool {
        return self == .compact
    }
}

// 布局刷新函数调用原因
enum LayoutChangeReason {
    case refresh // 强刷
    case sizeChanged // 分屏或者缩放窗口
    case orientationChanged //横竖屏

    var isOrientationChanged: Bool {
        return self == .orientationChanged
    }
}

// 布局所需的依赖参数，包括当前布局样式，尺寸，变化原因
struct VCLayoutContext {
    var layoutType: LayoutType
    var viewSize: CGSize
    var layoutChangeReason: LayoutChangeReason
}

class BaseViewController: ByteViewUI.BaseViewController {

    // 仅用于临时保存willTransition回调中的newCollection
    private var lastTraitCollection: UITraitCollection?
    // 用于保存上一次回调
    private var lastIsLandscape: Bool = false

    // warning: 该值不一定是准确的，依赖于使用时机。
    // 当前layoutContext，可用于辅助布局刷新
    var currentLayoutContext: VCLayoutContext = .init(layoutType: Display.phone ? .compact : .regular, viewSize: .zero, layoutChangeReason: .refresh)

    override func viewDidLoad() {
        super.viewDidLoad()
        lastIsLandscape = view.isLandscape
        currentLayoutContext.layoutType = convertTraitCollectionToLayoutType(self.traitCollection)
        currentLayoutContext.viewSize = self.view.bounds.size
        addTapGestureRecognizer()
    }

    /// 给导航栏添加退出键盘的点击手势
    func addTapGestureRecognizer() {
        if let gestureRecognizers = self.navigationController?.navigationBar.gestureRecognizers, gestureRecognizers.contains(where: { $0 is UITapGestureRecognizer }) {
            return
        }
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(exitEdit))
        self.navigationController?.navigationBar.addGestureRecognizer(recognizer)
    }

    @objc private func exitEdit() {
        self.view.endEditing(true)
    }

    func checkChangedForRefresh() {
        let lastContext = self.currentLayoutContext
        let isLandscapeChanged = lastIsLandscape != view.isLandscape
        lastIsLandscape = view.isLandscape
        let newLayoutType = convertTraitCollectionToLayoutType(self.traitCollection)
        if isLandscapeChanged || currentLayoutContext.layoutType != newLayoutType {
            self.currentLayoutContext.layoutChangeReason = .refresh
            self.currentLayoutContext.viewSize = self.view.bounds.size
            self.currentLayoutContext.layoutType = newLayoutType
            self.viewLayoutContextIsChanging(from: lastContext, to: self.currentLayoutContext)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        self.checkChangedForRefresh()
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        self.checkChangedForRefresh()
        super.viewDidAppear(animated)
    }

    // 仅用于更新UITraitCollection
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        self.lastTraitCollection = newCollection
        // 兜底，对currentLayoutContext.layoutType进行更新
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            guard let self = self else { return }
            // 如果只有该回调，没有viewWillTransition回调，补充刷新检查
            if self.lastTraitCollection != nil {
                self.checkChangedForRefresh()
            } else {
                let newLayoutType = self.convertTraitCollectionToLayoutType(self.traitCollection)
                self.currentLayoutContext.layoutType = newLayoutType
            }
            self.lastTraitCollection = nil
        }
        super.willTransition(to: newCollection, with: coordinator)
    }

    // 横竖屏旋转，分屏等依赖此方法
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        let newLayoutContext: VCLayoutContext = .init(layoutType: self.convertTraitCollectionToLayoutType(lastTraitCollection ?? self.traitCollection), viewSize: size, layoutChangeReason: view.isLandscape != lastIsLandscape ? .orientationChanged : .sizeChanged)
        self.lastTraitCollection = nil
        viewLayoutContextWillChange(to: newLayoutContext)
        let lastLayoutContext = self.currentLayoutContext
        self.currentLayoutContext = newLayoutContext
        coordinator.animate(alongsideTransition: { [weak self] _ in
            guard let self = self else { return }
            self.currentLayoutContext.layoutType = self.convertTraitCollectionToLayoutType(self.traitCollection)
            self.currentLayoutContext.layoutChangeReason = view.isLandscape != lastIsLandscape ? .orientationChanged : .sizeChanged
            self.viewLayoutContextIsChanging(from: lastLayoutContext, to: self.currentLayoutContext)
        }, completion: { [weak self] _ in
            guard let self = self else { return }
            self.lastIsLandscape = self.view.isLandscape
            self.viewLayoutContextDidChanged()
        })
        // 确保顺序是从下往上传递
        super.viewWillTransition(to: size, with: coordinator)
    }

    private func convertTraitCollectionToLayoutType(_ traitCollection: UITraitCollection) -> LayoutType {
        if #available(iOS 13.0, *) {
            if Display.phone {
                // 优先取windowScene方向作为判断基准
                if let orientation = self.view.orientation {
                    return orientation.isLandscape ? .phoneLandscape : .compact
                }
                // 取不到则以traitCollection的组合作为判断基准
                if traitCollection.horizontalSizeClass == .compact, traitCollection.verticalSizeClass == .regular {
                    return .compact
                }
                return .phoneLandscape
            }
            return traitCollection.horizontalSizeClass == .compact ? .compact : .regular
        } else {
            // ios12手机上取traitCollection，取出来的是unspecified
            if Display.phone {
                return UIApplication.shared.statusBarOrientation.isLandscape ? .phoneLandscape : .compact
            } else {
                return VCScene.isRegular ? .regular : .compact
            }
        }
    }

    // for override
    // 动画前调用，一般可用于处理和刷新布局无关的任务
    // warning，此时不推荐做布局刷新，访问currentLayoutContext为变化前的值，不可靠
    func viewLayoutContextWillChange(to layoutContext: VCLayoutContext) {}
    // 动画过程中调用，布局更新一般情况下应该在这里面进行
    func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {}
    // 动画结束后调用，可根据业务特殊需要刷新布局或者进行其他任务
    func viewLayoutContextDidChanged() {}
}
