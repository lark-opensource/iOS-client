//
//  CustomPasteboardCache.swift
//  LarkKeyboardView
//
//  Created by liluobin on 2023/1/9.
//

import Foundation
import UIKit
import LarkStorage
import LKCommonsLogging

public struct CustomPasteboardModel: Persistable {
    public static let `default` = CustomPasteboardModel(content: "")

    public var unarchiveSuccess = false
    public var content: String = ""
    public var expandInfo: [String: String]

    public init(content: String, expandInfo: [String : String] = [:]) {
        self.content = content
        self.expandInfo = expandInfo
    }

    public init(unarchive: [String: Any]) {
        guard let content = unarchive["content"] as? String else {
            self.expandInfo = [:]
            self.unarchiveSuccess = false
            return
        }
        self.unarchiveSuccess = true
        self.content = content
        self.expandInfo = (unarchive["expandInfo"] as? [String : String]) ?? [:]
    }

    public func archive() -> [String: Any] {
        return [
            "content": content,
            "expandInfo": expandInfo
        ]
    }

    static func parseJsonStr(_ str: String) -> CustomPasteboardModel? {
        if str.isEmpty { return nil }
        let model = CustomPasteboardModel.parse(str)
        if model.unarchiveSuccess {
            return model
        }
        return CustomPasteboardModel(content: str)
    }
}

public class CustomPasteboardCache {
    private var cache: [String: String] = [:]
    private let cachePath: IsoPath
    static let logger = Logger.log(CustomPasteboardCache.self, category: "CustomPasteboardCache")

    static public let share = CustomPasteboardCache()

    public init() {
        cachePath = .in(space: .global, domain: Domain.biz.core.child("Pasteboard")).build(.document)
            + "CustomPasteboard/pasteboard.plist"
    }

    public func saveInfo(_ info: [String: String]) {
        cache = info
        if !cachePath.exists {
            let dirPath = cachePath.deletingLastPathComponent
            do {
                try dirPath.createDirectoryIfNeeded()
            } catch let error {
                Self.logger.error("createDirectoryIfNeeded \(dirPath) \(error.localizedDescription)")
            }
            do {
                try cachePath.createFileIfNeeded()
            } catch let error {
                Self.logger.error("createFileIfNeeded \(cachePath.absoluteString) \(error.localizedDescription)")
            }
        }
        do {
            try info.write(to: cachePath, atomically: true)
        } catch let error {
            Self.logger.error("info.write to \(cachePath.absoluteString) error:\(error.localizedDescription) count: \(info.values.first?.count)")
        }
    }

    public func getInfo(key: String) -> String? {
        let value = cache[key]
        if value != nil {
            return value
        }
        let startDate = Date()
        do {
            let info = try [String: String].read(from: cachePath)
            Self.logger.info("getInfo key: \(key) localCache cost: \(Date().timeIntervalSince(startDate))")
            /// 向内存中缓存一份
            if !info.isEmpty { cache = info }
            return info[key]
        } catch let error {
            Self.logger.error("getInfo key: \(key) error:\(error.localizedDescription) cost: \(Date().timeIntervalSince(startDate))")
            return nil
        }
    }
}
