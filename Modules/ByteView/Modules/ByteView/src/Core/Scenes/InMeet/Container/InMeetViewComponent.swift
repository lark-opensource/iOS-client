//
//  InMeetViewComponent.swift
//  ByteView
//
//  Created by kiri on 2021/4/9.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UIKit

/// 表示添加到容器中的视图组件，提供视图层生命周期和布局变化的回调
protocol InMeetViewComponent: MeetingLayoutStyleListener {

    /// 初始化方法
    ///
    /// 可在初始化完成前把组件加入到容器里，但是不建议在此处设置constraint，因为其他的组件可能还未初始化。
    ///
    /// - parameter container: 容器
    /// - parameter viewModel: 视图模型
    /// - throws: 创建失败时或不希望加载该组件时可抛异常
    init(container: InMeetViewContainer, viewModel: InMeetViewModel, layoutContext: VCLayoutContext) throws

    /// 组件ID
    var componentIdentifier: InMeetViewComponentIdentifier { get }

    /// 组件全部创建完成后的回调
    ///
    /// 可在此处安全的使用container.component(by:id)，应在该函数返回之前完成添加ViewController、View、LayoutGuide到容器的工作
    func containerDidLoadComponent(container: InMeetViewContainer)

    /// 设置constraint约束
    ///
    /// 可以在此处安全的设置constraint约束，此时组件的ViewController、View、LayoutGuide已全部加入到容器。
    func setupConstraints(container: InMeetViewContainer)

    /// 旋转屏幕或者分屏的时候，在此处做布局更新
    func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext)
    func viewLayoutContextWillChange(to layoutContext: VCLayoutContext)
    func viewLayoutContextDidChanged()
    func containerWillAppear(container: InMeetViewContainer)
    func containerDidAppear(container: InMeetViewContainer)
    func containerDidFirstAppear(container: InMeetViewContainer)
    func containerWillDisappear(container: InMeetViewContainer)
    func containerDidDisappear(container: InMeetViewContainer)
    var childViewControllerForStatusBarHidden: InMeetOrderedViewController? { get }
    var childViewControllerForStatusBarStyle: InMeetOrderedViewController? { get }
    var childViewControllerForOrientation: InMeetOrderedViewController? { get }

    /// 通知即将发生大小窗变化
    func floatingWindowWillTransition(to frame: CGRect, isFloating: Bool)
    func floatingWindowWillChange(to isFloating: Bool)
    func floatingWindowDidChange(to isFloating: Bool)
}

extension InMeetViewComponent {
    func setupConstraints(container: InMeetViewContainer) {}
    func containerDidLoadComponent(container: InMeetViewContainer) {}
    func viewLayoutContextWillChange(to layoutContext: VCLayoutContext) {}
    func viewLayoutContextDidChanged() {}
    func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {}
    func containerDidChangeLayoutStyle(container: InMeetViewContainer, prevStyle: MeetingLayoutStyle?) {}
    func containerWillAppear(container: InMeetViewContainer) {}
    func containerDidAppear(container: InMeetViewContainer) {}
    func containerDidFirstAppear(container: InMeetViewContainer) {}
    func containerWillDisappear(container: InMeetViewContainer) {}
    func containerDidDisappear(container: InMeetViewContainer) {}
    var childViewControllerForStatusBarHidden: InMeetOrderedViewController? { nil }
    var childViewControllerForStatusBarStyle: InMeetOrderedViewController? { nil }
    var childViewControllerForOrientation: InMeetOrderedViewController? { nil }
    func floatingWindowWillTransition(to frame: CGRect, isFloating: Bool) {}
    func floatingWindowWillChange(to isFloating: Bool) {}
    func floatingWindowDidChange(to isFloating: Bool) {}
}
