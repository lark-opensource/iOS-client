//
//  ShortcutError.swift
//  LarkShortcut
//
//  Created by kiri on 2023/11/16.
//

import Foundation

public enum ShortcutError: Error {
    case unknown
    case handlerNotFound
    case noPermission
    case timeout
    case invalidParameter(String)
}
