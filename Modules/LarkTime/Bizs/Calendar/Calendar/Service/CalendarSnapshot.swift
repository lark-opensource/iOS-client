//
//  CalendarSnapshot.swift
//  Calendar
//
//  Created by zhuheng on 2021/8/17.
//

import Foundation
import CalendarFoundation
import CryptoSwift
import LKCommonsLogging
import RxSwift
import LarkContainer
import LarkStorage

final class CalendarSnapshot: UserResolverWrapper {
    internal let userResolver: UserResolver

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    static let logger = Logger.log(CalendarSnapshot.self, category: "Calendar.larkCalendar.Snapshot")
    private lazy var cacheDir: IsoPath = {
        calendarDependency?.userLibraryPath() ?? filePath + "home"
    }()
    private lazy var filePath: IsoPath = {
        (cacheDir + "calendar").usingCipher()
    }()
    private var calendarsHashValue: Int = 0
    @ScopedInjectedLazy var calendarDependency: CalendarDependency?

    /// 读取磁盘缓存
    func read() -> [Rust.Calendar] {
        do {
            let data = try Data.read(from: self.filePath)

            if let snapshotData = NSKeyedUnarchiver.unarchiveObject(with: data) as? CalendarSnapshotData, let calendarDependency = calendarDependency {
                if snapshotData.userId == calendarDependency.currentUser.id &&
                    snapshotData.tenantId == calendarDependency.currentUser.tenantId {
                    calendarsHashValue = snapshotData.calendars.hashValue
                    CalendarSnapshot.logger.info("load file sucess")
                    return snapshotData.calendars
                } else {
                    CalendarSnapshot.logger.info("user not match")
                }
            } else {
                CalendarSnapshot.logger.info("file is empty")
            }
        } catch let err {
            CalendarSnapshot.logger.error("load file error \(err)")
        }
        return []
    }

    /// 写入磁盘
    /// - Parameter calendars: [Rust.Calendar]
    /// - Returns: true 成功 / false 失败
    func writeToDisk(calendars: [Rust.Calendar]) -> Bool {
        guard let calendarDependency = calendarDependency else { return false }
        let currentUser = calendarDependency.currentUser
        guard calendarsHashValue != calendars.hashValue else { return true }
        do {
            try? cacheDir.createDirectoryIfNeeded()
            try? filePath.createFileIfNeeded()
            if filePath.exists {
                let snapshotData = CalendarSnapshotData(calendars: calendars, userId: currentUser.id, tenantId: currentUser.tenantId)
                let data = NSKeyedArchiver.archivedData(withRootObject: snapshotData)
                try data.write(to: self.filePath)
                calendarsHashValue = calendars.hashValue
                CalendarSnapshot.logger.info("write to disk succeed")
                return true
            }
        } catch let err {
            CalendarSnapshot.logger.error("write to disk error \(err)")
        }
        return false
    }
}

extension Array where Element == Rust.Calendar {
    func hashValue() -> Int {
        reduce(0) { result, calendar in
            result + calendar.hashValue
        }
    }
}
final class CalendarSnapshotData: NSObject, NSCoding {
    func encode(with coder: NSCoder) {
        do {
            let calendarsBase64Str: String = try calendars.reduce("") { result, calendar in
                let data = try calendar.serializedData()
                let base64String = data.base64EncodedString()
                return result.appending(base64String).appending(separater)
            }

            coder.encode(calendarsBase64Str, forKey: "calendars")
        } catch let error {
            CalendarSnapshot.logger.error("encode error \(error)")
        }
        coder.encode(userId, forKey: "userId")
        coder.encode(tenantId, forKey: "tenantId")
    }

    required init?(coder: NSCoder) {
        self.calendars = []
        if let calendarsBase64Str = coder.decodeObject(forKey: "calendars") as? String {
            do {
                self.calendars = try calendarsBase64Str.components(separatedBy: separater)
                    .compactMap { base64Str -> Rust.Calendar? in
                        guard !base64Str.isEmpty else { return nil }
                        if let data = Data(base64Encoded: base64Str) {
                            return try Rust.Calendar(serializedData: data)
                        }
                        return nil
                    }
            } catch let error {
                CalendarSnapshot.logger.error("decode error \(error)")
            }

        }
        self.userId = coder.decodeObject(forKey: "userId") as? String
        self.tenantId = coder.decodeObject(forKey: "tenantId") as? String
    }

    private let separater = "_"
    private(set) var calendars: [Rust.Calendar]
    private(set) var userId: String?
    private(set) var tenantId: String?

    init(calendars: [Rust.Calendar], userId: String, tenantId: String) {
        self.calendars = calendars
        self.userId = userId
        self.tenantId = tenantId
    }
}
