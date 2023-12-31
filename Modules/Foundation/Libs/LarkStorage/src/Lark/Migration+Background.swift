//
//  Migration+Background.swift
//  LarkStorage
//
//  Created by 7Up on 2023/9/4.
//

import Foundation

extension KVMigrationRegistry {
    public static func observeBackgroundNotification() {
        let notiName = UIApplication.didEnterBackgroundNotification
        // swiftlint:disable discarded_notification_center_observer
        NotificationCenter.default.addObserver(forName: notiName, object: nil, queue: nil) { _ in
            guard LarkStorageFG.keyValueBGTask else {
                logger.info("disable keyvalue background task")
                return
            }
            logger.info("will handle keyvalue background task")
            guard let passport = Dependencies.passport else {
                logger.info("missing passport")
                return
            }
            var spaces = [Space]()

            let curUserId = passport.foregroundUserId
            if let curUserId, !curUserId.isEmpty {
                spaces.append(.user(id: curUserId))
            }
            spaces.append(.global)
            for userId in passport.userIdList where !userId.isEmpty && userId != curUserId {
                spaces.append(.user(id: userId))
            }
            KVUtils.runMigrationTasks(forSpaces: spaces)
        }
        // swiftlint:enable discarded_notification_center_observer
    }
}

extension SBMigrationRegistry {
    public static func observeBackgroundNotification() {
        let notiName = UIApplication.didEnterBackgroundNotification
        // swiftlint:disable discarded_notification_center_observer
        NotificationCenter.default.addObserver(forName: notiName, object: nil, queue: nil) { _ in
            guard LarkStorageFG.sandboxBGTask else {
                logger.info("disable sandbox background task")
                return
            }
            logger.info("will handle sandbox background task")

            guard let passport = Dependencies.passport else {
                logger.info("missing passport")
                return
            }

            var spaces = [Space]()

            let curUserId = passport.foregroundUserId
            if let curUserId, !curUserId.isEmpty {
                spaces.append(.user(id: curUserId))
            }
            spaces.append(.global)
            for userId in passport.userIdList where !userId.isEmpty && userId != curUserId {
                spaces.append(.user(id: userId))
            }
            SBUtils.runMigrationTasks(forSpaces: spaces)
        }
        // swiftlint:enable discarded_notification_center_observer
    }
}
