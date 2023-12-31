//
//  NetworkCommand.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/24.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB
import ServerPB

@frozen public enum NetworkCommand: Hashable, CustomStringConvertible {
    case rust(Basic_V1_Command)
    case server(ServerPB_Improto_Command)

    public var rawValue: Int {
        switch self {
        case .rust(let cmd):
            return cmd.rawValue
        case .server(let cmd):
            return cmd.rawValue
        }
    }

    public var description: String {
        switch self {
        case .rust(let cmd):
            return "[r][\(cmd)](\(cmd.rawValue))"
        case .server(let cmd):
            return "[s][\(cmd)](\(cmd.rawValue))"
        }
    }

    public var isServerCommand: Bool {
        switch self {
        case .server:
            return true
        default:
            return false
        }
    }
}
