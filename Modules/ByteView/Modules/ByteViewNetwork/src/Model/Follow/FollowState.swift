//
//  FollowState.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/9.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
/// 表示一个strategy的全量数据
/// - Videoconference_V1_FollowState
public struct FollowState: Equatable {
    public init(sender: String, dataType: FollowDataType, stateKey: String?, webData: FollowWebData?) {
        self.sender = sender
        self.dataType = dataType
        self.stateKey = stateKey
        self.webData = webData
    }

    /// 发送者UID
    public var sender: String

    public var dataType: FollowDataType

    public var stateKey: String?

    public var webData: FollowWebData?
}

/// Videoconference_V1_FollowDataType
public enum FollowDataType: Int, Hashable {
    case unknown // = 0
    case followWebData // = 1
}

/// follow中要应用到网页中的数据
/// - Videoconference_V1_FollowWebData
public struct FollowWebData: Equatable {
    public init(id: Int64, strategyID: String, payload: String) {
        self.id = id
        self.strategyID = strategyID
        self.payload = payload
    }

    /// web_data的id，用于去重
    public var id: Int64

    /// 产生改数据的策略的id
    public var strategyID: String

    public var payload: String

    /// 这里只定义了所关心的payload，例如strategy id是dom时，会unmarshal payload成DomPayload
    //    public struct DomPayload {
    //
    //        /// 使用json marshal/unmarshal
    //        public var doms: [String: DomPayload.Dom]
    //
    //        public struct Dom {
    //
    //            public var id: String
    //
    //            public var children: [String] = []
    //
    //            public var attributes: [String: String] = [:]
    //
    //            public var data: [String: String] = [:]
    //        }
    //    }
}

extension FollowWebData: CustomStringConvertible {
    public var description: String {
        String(
            indent: "FollowWebData",
            "id: \(id)",
            "strategyId: \(strategyID)"
        )
    }
}
