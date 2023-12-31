//
//  LKAssetBrowserLogger.swift
//  LKBaseAssetBrowser
//
//  Created by Hayden Wang on 2022/1/25.
//

import Foundation

public struct LKAssetBrowserLogger {

    /// 日志重要程度等级
    public enum Level: Int {
        case none
        case error
        case warn
        case info
        case debug
    }

    /// 允许输出日志的最低等级。`forbidden`为禁止所有日志
    public static var minimumLevel: Level = .debug

    public static func error(_ item: @autoclosure () -> Any) {
        guard Level.error.rawValue <= minimumLevel.rawValue else { return }
        #if DEBUG
        debugPrint("--->>> [LKAssetBrowser] [❤️error]", item())
        #endif
    }

    public static func warn(_ item: @autoclosure () -> Any) {
        guard Level.warn.rawValue <= minimumLevel.rawValue else { return }
        #if DEBUG
        debugPrint("--->>> [LKAssetBrowser] [💛warn]", item())
        #endif
    }

    public static func info(_ item: @autoclosure () -> Any) {
        guard Level.info.rawValue <= minimumLevel.rawValue else { return }
        #if DEBUG
        debugPrint("--->>> [LKAssetBrowser] [💙info]", item())
        #endif
    }
    
    public static func debug(_ item: @autoclosure () -> Any) {
        guard Level.debug.rawValue <= minimumLevel.rawValue else { return }
        #if DEBUG
        debugPrint("--->>> [LKAssetBrowser] [💚debug]", item())
        #endif
    }
}
