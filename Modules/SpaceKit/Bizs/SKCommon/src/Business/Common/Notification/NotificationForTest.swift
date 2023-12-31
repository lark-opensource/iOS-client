//
//  NotificationForTest.swift
//  SpaceKit
//
//  Created by huahuahu on 2018/11/21.
//

import Foundation

extension Notification {
    /// Used as a namespace for all `Notification` user info dictionary keys.
    public struct DocsKey {
        public static let editorIdentifer = "docs.bytedance.notification.key.editorIdentifier"
    }
}

extension Notification.Name {
    public struct PreloadTest {
        public static let preloadStart = Notification.Name(rawValue: "docs.bytedance.notification.name.PreloadTest.preloadstart")
        public static let preloadok = Notification.Name(rawValue: "docs.bytedance.notification.name.PreloadTest.preloadok")
    }
}

extension Notification.Name {
    public struct OpenFileRecord {
        public static let StageStart = Notification.Name(rawValue: "docs.bytedance.notification.name.OpenFileRecord.stageStart")
        public static let StageEnd = Notification.Name(rawValue: "docs.bytedance.notification.name.OpenFileRecord.stageEnd")
        public static let EventHappen = Notification.Name(rawValue: "docs.bytedance.notification.name.OpenFileRecord.eventHappen")
        public static let OpenEnd = Notification.Name(rawValue: "docs.bytedance.notification.name.OpenFileRecord.openEnd")
        public static let OpenStart = Notification.Name(rawValue: "docs.bytedance.notification.name.OpenFileRecord.openStart")
        public static let AutoOpenEnd = Notification.Name(rawValue: "docs.bytedance.notification.name.OpenFileRecord.autoOpenEnd")
    }
}

extension Notification.Name {
    public struct JSLog {
        public static let pullStart = Notification.Name(rawValue: "docs.bytedance.notification.name.JSLog.pullStart")
        public static let pullEnd = Notification.Name(rawValue: "docs.bytedance.notification.name.JSLog.pullEnd")
        public static let renderStart = Notification.Name(rawValue: "docs.bytedance.notification.name.JSLog.renderStart")
        public static let renderEnd = Notification.Name(rawValue: "docs.bytedance.notification.name.JSLog.renderEnd")
    }
}
