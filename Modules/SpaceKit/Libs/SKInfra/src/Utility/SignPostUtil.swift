//
//  SignPostUtil.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/6/30.
//  
// 对signpost的封装

import Foundation
import os

//enum DocSignpostType {
//    case begin
//    case end
//    case event
//
//    @available(iOS 12.0, *)
//    var toOSSignpostType: OSSignpostType {
//        switch self {
//        case .begin: return .begin
//        case .end: return .end
//        case .event: return .event
//        }
//    }
//}
/// 对应doc SDK 核心场景的性能
public enum DocsCorePerformanceScene: String {
    case sdkInit
    case runloop
    case docsTabInit
    case docsViewControllerFactoryResolve
    case gecko
    case docsTabVC
    case readClientVar
    case readHtmlCache

    fileprivate var signpostID: UInt64 {
        switch self {
        case .sdkInit:
            return 1
        case .runloop:
            return 2
        case .docsTabInit:
            return 3
        case .docsViewControllerFactoryResolve:
            return 4
        case .gecko:
            return 5
        case .docsTabVC:
            return 6
        case .readClientVar:
            return 7
        case .readHtmlCache:
            return 8
        }
    }

    fileprivate var name: StaticString {
        switch self {
        case .sdkInit:
            return "sdkInit"
        case .runloop:
            return "runloop"
        case .docsTabInit:
            return "docsTabInit"
        case .docsViewControllerFactoryResolve:
            return "docsViewControllerFactoryResolve"
        case .gecko:
            return "gecko"
        case .docsTabVC:
            return "docsTabVC"
        case .readClientVar:
            return "readClientVar"
        case .readHtmlCache:
            return "readHtmlCache"
        }
    }
}

private let performanceLog = OSLog(subsystem: "com.doc.bytedance", category: "performance")
//typealias DocSignpostID = UInt64

//0
//func docSignPost(_ type: DocSignpostType, log: OSLog = DocsSDK.runLoopLog, name: StaticString, docSignpostID: DocSignpostID, format: StaticString, arguments: CVarArg...) {
//    #if DEBUG
//    guard #available(iOS 12.0, *) else {
//        return
//    }
//    let osSignpostID = OSSignpostID(docSignpostID)
//    os_signpost(type.toOSSignpostType, log: log, name: name, signpostID: osSignpostID, format, arguments)
//    #endif
//}

public func docsStartTrace(_ scene: DocsCorePerformanceScene) {
    #if DEBUG
    guard #available(iOS 12.0, *) else {
        return
    }
    let osSignpostID = OSSignpostID(scene.signpostID)

    os_signpost(.begin, log: performanceLog, name: scene.name, signpostID: osSignpostID, "")
    #endif
}

public func docsEndTrace(_ scene: DocsCorePerformanceScene) {
    #if DEBUG
    guard #available(iOS 12.0, *) else {
        return
    }
    let osSignpostID = OSSignpostID(scene.signpostID)
    os_signpost(.end, log: performanceLog, name: scene.name, signpostID: osSignpostID, "")
    #endif
}
