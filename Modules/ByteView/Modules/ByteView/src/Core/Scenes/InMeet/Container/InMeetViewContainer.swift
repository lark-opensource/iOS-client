//
//  InMeetContainer.swift
//  ByteView
//
//  Created by kiri on 2021/4/2.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// 会中视图容器的协议，一个以z-index（InMeetContentLevel）为基础的视图组件容器
protocol InMeetViewContainer: BaseViewController {
    var context: InMeetViewContext { get }
    var layoutContainer: InMeetLayoutContainer { get }
    var viewModel: InMeetViewModel { get }
    var meetingLayoutStyle: MeetingLayoutStyle { get }
    var fullScreenDetector: InMeetFullScreenDetector { get }
    func switchMeetLayoutStyle(_ style: MeetingLayoutStyle, animated: Bool)

    var sceneManager: InMeetSceneManager { get }
    var sceneMode: InMeetSceneManager.SceneMode { get }
    var contentMode: InMeetSceneManager.ContentMode { get }

    func addMeetLayoutStyleListener(_ listener: MeetingLayoutStyleListener)
    func addMeetSceneModeListener(_ listener: MeetingSceneModeListener)
    func makeSceneController(content: InMeetSceneManager.ContentMode, scene: InMeetSceneManager.SceneMode) -> InMeetSceneController?
    /// 加载某个level的root view到容器
    /// - parameter level: 想要加载的层级
    /// - returns: 该level的root view
    func loadContentViewIfNeeded(for level: InMeetContentLevel) -> UIView

    /// 添加UIViewController到容器
    /// - parameter viewController: 需要添加到容器的vc
    /// - parameter level: vc展示在哪一层
    /// - returns: 该level的root view
    /// - note: 该方法会自动调用```container.addChild(viewController)```和```viewController.didMove(toParent:)```
    @discardableResult
    func addContent(_ viewController: UIViewController, level: InMeetContentLevel) -> UIView

    func removeContent(_ vc: UIViewController, level: InMeetContentLevel)

    func removeContent(_ view: UIView, level: InMeetContentLevel)

    /// 添加UIView到容器
    /// - parameter view: 需要添加到容器的view
    /// - parameter level: view展示在哪一层
    /// - returns: 该level的root view
    @discardableResult
    func addContent(_ view: UIView, level: InMeetContentLevel) -> UIView

    /// 添加一个LayoutGuide到容器，如果已存在该key的LayoutGuide，则直接返回已有的。
    ///
    /// LayoutGuide会被添加到container的root view上
    ///
    /// - parameter key: 用来唯一标识LayoutGuide
    /// - returns: 创建的或找到的LayoutGuide
    @discardableResult
    func addLayoutGuideIfNeeded(for key: InMeetLayoutGuideKey) -> UILayoutGuide

    /// 查找一个容器所持有的组件。
    /// - parameter id: 组件ID
    /// - returns: 找到的组件或```nil```
    func component(by id: InMeetViewComponentIdentifier) -> InMeetViewComponent?
}
