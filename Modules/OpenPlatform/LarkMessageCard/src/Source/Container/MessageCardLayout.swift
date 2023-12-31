//
//  MessageCardLayout.swift
//  LarkMessageCard
//
//  Created by zhangjie.alonso on 2023/7/20.
//

import Foundation
import LarkMessageBase
import LarkMessageCard
import LarkOPInterface
import LKCommonsLogging
import LarkContainer

public protocol MessageCardLayoutService {
    func processLayout(_ cardContainerData: MessageCardContainer.ContainerData) -> CGSize
    func updateEnvData()
}


// 算高通用容器
public class MessageCardLayout: MessageCardLayoutService {

    private var _layoutContainer: MessageCardContainer? = nil

    private let lock: NSLock = NSLock()

    private let trace = OPTraceService.default().generateTrace()

    private func getLayoutContainer(_ cardContainerData: MessageCardContainer.ContainerData) -> MessageCardContainer {
        lock.lock()
        defer {
            lock.unlock()
        }
        guard let layoutContainer = _layoutContainer else {
            let container = MessageCardContainer.create(cardContainerData)
            self._layoutContainer = container
            return container
        }
        return layoutContainer
    }

    public func updateEnvData() {
        if Thread.isMainThread {
            self._layoutContainer?.updateEnvData()
        } else {
            DispatchQueue.main.async {
                self._layoutContainer?.updateEnvData()
            }
        }
    }

    public func processLayout(_ cardContainerData: MessageCardContainer.ContainerData) -> CGSize {
        var cardContainerData = cardContainerData
        var size: CGSize = .zero
        var layoutContainer = getLayoutContainer(cardContainerData)

        let calculateLayout = {
            cardContainerData.contextData.trace = self.trace
            layoutContainer.updateData(cardContainerData)
            layoutContainer.context.setBizContext(key: "setNoReportMonitor", value: true)
            layoutContainer.render()
            if let view = layoutContainer.view {
                size = CGSize(width: CGFloat(view.rootWidth()), height: CGFloat(view.rootHeight()))
            }
        }
        if Thread.isMainThread {
            calculateLayout()
        } else {
            DispatchQueue.main.sync {
                calculateLayout()
            }
        }
        return size
    }
}

// 消息卡片进入会话时机统一回调器
public class MessageCardEnterPageInitializer: PageService {

    @InjectedSafeLazy
    private var messageCardLayoutService: MessageCardLayoutService

    public init() {}

    public func pageInit() {
        messageCardLayoutService.updateEnvData()
    }

}

