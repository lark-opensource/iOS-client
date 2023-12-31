//
//  LarkBadgeNumberUpdater.swift
//  LarkNotificationServiceExtensionLib
//
//  Created by mochangxing on 2019/8/28.
//

import Foundation

public typealias Completion = (Bool) -> Void

#if DEBUG
let groupId = "group.com.bytedance.ee.lark.yzj"
#else
let groupId = Bundle.main.infoDictionary?["EXTENSION_GROUP"] as? String ?? ""
#endif

public final class LarkBadgeNumberUpdater {

    static let directory: URL? = {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupId)?
            .appendingPathComponent("badgeNumber")
    }()

    static let filePath: String? = {
        let filePath = LarkBadgeNumberUpdater.directory?.appendingPathComponent("entity").path
        return filePath
    }()

    fileprivate static func createDirectoryIfNeed() {
        guard let directory = LarkBadgeNumberUpdater.directory else {
            return
        }
        let fileManager = FileManager.default
        var isDirectory = ObjCBool(true)
        let exists = fileManager.fileExists(atPath: directory.path, isDirectory: &isDirectory)
        if !exists {
            do {
                try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
            }
        }
    }

    public class func updateBadgeNumber(_ number: Int, _ completion: Completion) {

        guard let filePath = LarkBadgeNumberUpdater.filePath else {
            return
        }

        createDirectoryIfNeed()
        let writeLock = FileWriteLock(filePath: filePath)
        if writeLock.getFileLock(processor: { (newURL, finished) in
            defer {
                finished()
            }
            let dict: NSDictionary = ["badgeNumber": number]
            let result = dict.write(to: newURL, atomically: true)
            completion(result)
        }) != nil {
            completion(false)
        }
    }

    public class func getBadgeNumber() -> Int? {
        guard let filePath = LarkBadgeNumberUpdater.filePath else {
            return nil
        }

        var badgeNumber: Int?
        let writeLock = FileReadLock(filePath: filePath)
        _ = writeLock.getFileLock(processor: { (_, finished) in
            defer {
                finished()
            }
            if let dict = NSDictionary(contentsOfFile: filePath),
                let number = dict["badgeNumber"] as? Int {
                badgeNumber = number
            }
        })
        return badgeNumber
    }
}
