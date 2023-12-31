//
//  LarkNCExtensionFactory.swift
//  LarkNotificationContentExtension
//
//  Created by yaoqihao on 2022/4/6.
//

import UserNotifications
import Foundation
import LarkExtensionServices

public final class LarkNCExtensionFactory {
    public static let logger = LogFactory.createLogger(label: "LarkNotification.LarkNCExtensionFactory")

    public static let shared = LarkNCExtensionFactory()

    private var processors: [String: LarkNotificationContentExtensionProcessor.Type] = [:]

    private init() { }

    public func register(_ processor: LarkNotificationContentExtensionProcessor.Type) {
        guard self.processors[processor.category] == nil else {
            assertionFailure("processor already exists")
            LarkNCExtensionFactory.logger.error("processor already exists key:\(processor.category)")
            return
        }
        self.processors[processor.category] = processor
        LarkNCExtensionFactory.logger.info("processor register success key:\(processor.category)")
    }

    public func registerCategories() -> [UNNotificationCategory] {
        return processors.values.map { (processor) -> UNNotificationCategory in
            return processor.registerCategory()
        }
    }

    public func createBy(category: String) -> LarkNotificationContentExtensionProcessor? {
        return processors[category]?.init()
    }
}
