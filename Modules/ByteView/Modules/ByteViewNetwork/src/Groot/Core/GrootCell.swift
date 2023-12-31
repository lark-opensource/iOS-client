//
//  GrootCell.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/6.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Client GrootCell，客户端新增的数据，或者服务端下发的数据
/// - Videoconference_V1_GrootCell
public struct GrootCell {
    public init(action: Action,
                payload: Data,
                sender: ByteviewUser? = nil,
                upVersion: Int64 = 0,
                downVersion: Int64 = 0,
                pageID: Int64 = 0,
                dataType: DataType = .unknown) {
        self.action = action
        self.payload = payload
        self.sender = sender
        self.upVersion = upVersion
        self.downVersion = downVersion
        self.pageID = pageID
        self.dataType = dataType
    }

    public var action: Action

    public var payload: Data

    public var sender: ByteviewUser?

    /// 由客户端生成，用于用户纬度的上行顺序保证
    public var upVersion: Int64

    public var downVersion: Int64

    public var pageID: Int64

    public var dataType: DataType

    public enum DataType: Int, Hashable, CustomStringConvertible {

        case unknown = 0

        /// 白板绘制数据，需要合并到 snapshot 中
        case whiteboardDrawData = 1

        /// 白板非绘制数据，不需要合并到 snapshot 中
        case whiteboardSyncData = 2

        public var description: String {
            switch self {
            case .unknown:
                return "unknown"
            case .whiteboardDrawData:
                return "whiteboardDrawData"
            case .whiteboardSyncData:
                return "whiteboardSyncData"
            }
        }
    }

    public enum Action: Int, Hashable, CustomStringConvertible {
        case unknown = 0

        /// 客户端发起的请求更新数据
        case clientReq = 1

        /// 服务端boardcast推送的数据 //TODO 改成2！！！
        case serverSet = 3

        /// 由服务端或客户端触发的boardcast推送的数据（不发给触发者），但不改变version，不改变服务端State和log
        case trigger = 4

        public var description: String {
            switch self {
            case .unknown:
                return "unknown"
            case .clientReq:
                return "clientReq"
            case .serverSet:
                return "serverSet"
            case .trigger:
                return "trigger"
            }
        }
    }
}

extension GrootCell: CustomStringConvertible {
    public var description: String {
        String(indent: "GrootCell",
               "action: \(action)",
               "data: \(dataType)(\(payload.count))",
               "pageID: \(pageID)",
               "upVersion: \(upVersion)",
               "downVersion: \(downVersion)")
    }
}
