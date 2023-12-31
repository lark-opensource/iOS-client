//
//  LauncherLog.swift
//  SpaceKit
//
//  Created by nine on 2020/1/17.
//

import Foundation

//避免单测时，因为引入了DocsLogger，而无法进行，所以单独在这一层将log隔离
extension Launcher {
    func info(_ message: String) {
        DocsLogger.info(message)
    }

    func debug(_ message: String) {
        DocsLogger.debug(message)
    }

    func error(_ message: String) {
        DocsLogger.error(message)
    }
}
