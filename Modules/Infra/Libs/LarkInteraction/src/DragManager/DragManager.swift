//
//  DragManager.swift
//  LarkInteraction
//
//  Created by 李晨 on 2020/3/31.
//

import UIKit
import Foundation
import ThreadSafeDataStructure

public enum DragInteractionLifeCycle {
    case willLift
    case willBegin
    case willAdd
    case willEnd
    case didEnd
    case didTransfer
}

public struct DragInteractionLifeCycleInfo {
    public var type: DragInteractionLifeCycle
    public var interaction: UIDragInteraction
    public var session: UIDragSession
    public var items: [DragItemInfo]
}

public struct DragInteractionViewInfo {
    public var tag: String
    public weak var view: UIView?

    public init(
        tag: String,
        view: UIView
    ) {
        self.tag = tag
        self.view = view
    }
}

public final class DragInteractionManager: NSObject, UIDragInteractionDelegate {

    public var viewTagBlock: ((UIView) -> String)?

    /// handler 字典
    var handlerDic: [String: [DragInteractionHandler]] = [:]

    /// drag observers
    var observerDic: [String: (DragInteractionLifeCycleInfo) -> Void] = [:]

    /// 正在拖拽中的 DragItem
    var dragingView: NSMapTable<NSString, UIDragSession> = NSMapTable<NSString, UIDragSession>.strongToWeakObjects()

    /// 正在拖拽中的 DragItem, 以及他们对应的 item 
    var dragItemInfo: NSMapTable<UIDragItem, DragItemInfo> = NSMapTable<UIDragItem, DragItemInfo>.weakToStrongObjects()

    /// 注册 drag handler
    public func register(_ handler: DragInteractionHandler) {
        let handleViewTag = handler.dragInteractionHandleViewTag()
        var handlers = self.handlerDic[handleViewTag] ?? []
        handlers.append(handler)
        self.handlerDic[handleViewTag] = handlers
    }

    /// 添加生命周期监听者
    @discardableResult
    public func addLifeCycle(observer: @escaping (DragInteractionLifeCycleInfo) -> Void) -> String {
        let uuidString = UUID().uuidString
        observerDic[uuidString] = observer
        return uuidString
    }

    /// 删除生命周期监听者
    public func removeLiftCycle(observerID: String) {
        observerDic[observerID] = nil
    }

    private func handle(
        interaction: UIDragInteraction,
        session: UIDragSession,
        location: CGPoint
    ) -> [UIDragItem] {
        guard let viewTagBlock = self.viewTagBlock else { return [] }
        guard let checkView = interaction.view else { return [] }
        let location = checkView.convert(location, from: interaction.view)
        let result = self.find(checkView: checkView, point: location)

        /// 判断是否需要响应拖拽
        guard result.enable else { return [] }

        /// 转化 view 数组
        let viewTagInfos = result.handleViews.map { (view) -> DragInteractionViewInfo in
            return DragInteractionViewInfo(
                tag: viewTagBlock(view),
                view: view
            )
        }

        var uiDragItems: [UIDragItem] = []
        /// 遍历 view，寻找第一个可以响应的 handler
        for tagInfo in viewTagInfos {
            if let handlers = self.handlerDic[tagInfo.tag] {
                /// 过滤掉不需要响应的 handler
                let filteredHandlers = handlers.filter { (handler) -> Bool in
                    return handler.dragInteractionCanHandle(
                        context: result.context
                    )
                }
                for handler in filteredHandlers {
                    /// 获取 DragItem
                    if let dragItems = handler.dragInteractionHandle(
                        info: tagInfo,
                        context: result.context
                    ) {
                        /// 根据 viewTag 以及 context 计算出唯一 dragTag
                        let dragTag = viewIdentifier(tagInfo.tag, result.context)
                        /// 判断 dragitem 是否为空，并且当前 view 没有在被拖拽
                        if !dragItems.isEmpty,
                            dragingView.object(
                                forKey: dragTag
                            ) == nil {
                            dragingView.setObject(session, forKey: dragTag)

                            dragItems.forEach { (item) in
                                let dragContext = DragItemInfo(
                                    viewTag: tagInfo.tag,
                                    view: tagInfo.view,
                                    context: result.context,
                                    param: item.params
                                )
                                uiDragItems.append(item.dragItem)
                                dragItemInfo.setObject(dragContext, forKey: item.dragItem)
                            }
                        }
                        break
                    }
                }
            }
            if !uiDragItems.isEmpty {
                break
            }
        }

        return uiDragItems
    }

    // MARK: UIDragInteractionDelegate
    public func dragInteraction(
        _ interaction: UIDragInteraction,
        itemsForBeginning session: UIDragSession
    ) -> [UIDragItem] {
        guard let view = interaction.view else { return [] }
        let location = session.location(in: view)
        let dragItems = handle(interaction: interaction, session: session, location: location)
        if !dragItems.isEmpty {
            self.handleObserver(
                type: .willLift,
                interaction: interaction,
                session: session,
                dragItems: dragItems
            )
        }
        return dragItems
    }

    public func dragInteraction(
        _ interaction: UIDragInteraction,
        itemsForAddingTo session: UIDragSession,
        withTouchAt point: CGPoint
    ) -> [UIDragItem] {
        let dragItems = handle(interaction: interaction, session: session, location: point)
        if !dragItems.isEmpty {
            self.handleObserver(
                type: .willAdd,
                interaction: interaction,
                session: session,
                dragItems: dragItems
            )
        }
        return dragItems
    }

    public func dragInteraction(
        _ interaction: UIDragInteraction,
        sessionForAddingItems sessions: [UIDragSession],
        withTouchAt point: CGPoint
    ) -> UIDragSession? {
        return nil
    }

    // MARK: - Animation
    public func dragInteraction(
        _ interaction: UIDragInteraction,
        willAnimateLiftWith animator: UIDragAnimating,
        session: UIDragSession
    ) {
    }

    public func dragInteraction(
        _ interaction: UIDragInteraction,
        item: UIDragItem,
        willAnimateCancelWith animator: UIDragAnimating
    ) {
    }

    // MARK: - Session
    public func dragInteraction(_ interaction: UIDragInteraction, sessionWillBegin session: UIDragSession) {
        self.handleObserver(
            type: .willBegin,
            interaction: interaction,
            session: session,
            dragItems: session.items
        )
    }

    public func dragInteraction(
        _ interaction: UIDragInteraction,
        session: UIDragSession,
        willAdd items: [UIDragItem],
        for addingInteraction: UIDragInteraction
    ) {
    }

    public func dragInteraction(_ interaction: UIDragInteraction, sessionDidMove session: UIDragSession) {
    }

    public func dragInteraction(
        _ interaction: UIDragInteraction,
        session: UIDragSession,
        willEndWith operation: UIDropOperation
    ) {
        self.handleObserver(
            type: .willEnd,
            interaction: interaction,
            session: session,
            dragItems: session.items
        )
    }

    public func dragInteraction(
        _ interaction: UIDragInteraction,
        session: UIDragSession,
        didEndWith operation: UIDropOperation
    ) {
        self.handleObserver(
            type: .didEnd,
            interaction: interaction,
            session: session,
            dragItems: session.items
        )
    }

    public func dragInteraction(_ interaction: UIDragInteraction, sessionDidTransferItems session: UIDragSession) {
        self.handleObserver(
            type: .didTransfer,
            interaction: interaction,
            session: session,
            dragItems: session.items
        )
    }

    // MARK: - Preview
    public func dragInteraction(
        _ interaction: UIDragInteraction,
        previewForLifting item: UIDragItem,
        session: UIDragSession
    ) -> UITargetedDragPreview? {
        guard let info = dragItemInfo.object(forKey: item),
            let view = info.view,
            let containerView = interaction.view else { return nil }

        if let snapshot = createViewLayer(view: view) {
            let imageView = UIImageView(image: snapshot)
            imageView.bounds = view.bounds
            let center = containerView.convert(view.center, from: view.superview)
            let target = UIDragPreviewTarget(container: containerView, center: center)

            if let dragPreviewParameters = info.param.dragPreviewParameters {
                /// 添加 item preview provider
                item.previewProvider = {
                    let dragPreview = UIDragPreview(view: imageView, parameters: dragPreviewParameters)
                    return dragPreview
                }
            }

            return UITargetedDragPreview(
                view: imageView,
                parameters: info.param.targetDragPreviewParameters ?? UIDragPreviewParameters(),
                target: target
            )
        } else {
            return UITargetedDragPreview(
                view: view
            )
        }
    }

    public func dragInteraction(
        _ interaction: UIDragInteraction,
        previewForCancelling item: UIDragItem,
        withDefault defaultPreview: UITargetedDragPreview
    ) -> UITargetedDragPreview? {
        return nil
    }

    public func dragInteraction(
        _ interaction: UIDragInteraction,
        prefersFullSizePreviewsFor session: UIDragSession
    ) -> Bool {
        return false
    }

    public func dragInteraction(
        _ interaction: UIDragInteraction,
        sessionIsRestrictedToDraggingApplication session: UIDragSession
    ) -> Bool {
        return false
    }

    public func dragInteraction(
        _ interaction: UIDragInteraction, sessionAllowsMoveOperation session: UIDragSession) -> Bool {
        return false
    }
}
extension DragInteractionManager {

    struct FindDragViewResult {
        var handleViews: [UIView]
        var context: DragContext
        var enable: Bool
    }

    /// 获取当前 drag 需要响应的 view 以及 context
    private func find(checkView: UIView, point: CGPoint) -> FindDragViewResult {
        /// 判断当前 checkView 是否正在显示
        guard !checkView.isHidden,
            checkView.alpha > 0.01,
            checkView.bounds.contains(point) else {
            return FindDragViewResult(
                handleViews: [],
                context: DragContext(),
                enable: true
            )
        }

        var context: DragContext = DragContext()
        var forwardCheckView: UIView?
        var hitViews: [UIView] = []
        var dragEnable: Bool = true

        /// 如果当前 view 满足 DragContainer 协议或者实现了dragContainerProxy
        if let container: DragContainer = checkView.dragContainerProxy ?? (checkView as? DragContainer) {
            /// 判断当前 container 是否支持 drag
            guard container.dragInteractionEnable(location: point) else {
                return FindDragViewResult(
                    handleViews: [],
                    context: context,
                    enable: false
                )
            }
            /// 判断当前 container 是否忽略 drag
            if container.dragInteractionIgnore(location: point) {
                return FindDragViewResult(
                    handleViews: [],
                    context: context,
                    enable: false
                )
            }

            /// 获取当前上下文参数
            if let currentContext = container.dragInteractionContext(location: point) {
                context = context.merge(context: currentContext)
            }

            /// 判断是否存在转发
            if let forward = container.dragInteractionForward(location: point) {
                forwardCheckView = forward
            }
        }

        if let forward = forwardCheckView {
            /// 如果存在转发 view，直接在 forward 上继续寻找
            let convertPoint = forward.convert(point, from: checkView)
            let findResult = find(checkView: forward, point: convertPoint)
            if !findResult.enable {
                dragEnable = false
            } else if !findResult.handleViews.isEmpty {
                context = context.merge(context: findResult.context)
                hitViews.append(contentsOf: findResult.handleViews)
            }
        } else {
            /// 遍历所有 subviews
            for subView in checkView.subviews.reversed() {
                let convertPoint = subView.convert(point, from: checkView)
                let subHitResult = find(checkView: subView, point: convertPoint)
                if !subHitResult.enable {
                    dragEnable = false
                    break
                } else if !subHitResult.handleViews.isEmpty {
                    context = context.merge(context: subHitResult.context)
                    hitViews.append(contentsOf: subHitResult.handleViews)
                    break
                }
            }
        }

        if dragEnable {
            hitViews.append(checkView)
        }
        return FindDragViewResult(
            handleViews: hitViews,
            context: context,
            enable: dragEnable
        )
    }

    // viewTag 与 context 组合出 Identifier
    func viewIdentifier(_ viewTag: String, _ context: DragContext) -> NSString {
        return context.identifier + "_view_" + viewTag as NSString
    }

    private func handleObserver(
        type: DragInteractionLifeCycle,
        interaction: UIDragInteraction,
        session: UIDragSession,
        dragItems: [UIDragItem]
    ) {
        let items = dragItems.compactMap { (dragItem) -> DragItemInfo? in
            return dragItemInfo.object(forKey: dragItem)
        }

        let info = DragInteractionLifeCycleInfo(
            type: type,
            interaction: interaction,
            session: session,
            items: items
        )
        self.observerDic.values.forEach { (observer) in
            observer(info)
        }
    }

    private func createViewLayer(view: UIView) -> UIImage? {
        var screenshot: UIImage?
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, UIScreen.main.scale)
        if let context = UIGraphicsGetCurrentContext() {
            view.layer.render(in: context)
            screenshot = UIGraphicsGetImageFromCurrentImageContext()
        }
        UIGraphicsEndImageContext()
        return screenshot
    }
}
