//
//  Logger.swift
//  LibArchiveKit
//
//  Created by ZhangYuanping on 2021/9/30.
//  


import LKCommonsLogging

public final class ArchiveLogger {
    public static let shared = Logger.log(ArchiveLogger.self, category: "Module.LibArchiveKit")

    public static func assertionFailure(_ message: String) {
        Swift.assertionFailure(message)
        shared.error(message)
    }
}

