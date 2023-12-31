//
//  VideoChatDisplayOrderInfo.swift
//  ByteViewNetwork
//
//  Created by Tobb Huang on 2022/11/25.
//

import Foundation

/// Videoconference_V1_VideoChatDisplayOrderInfo
public struct VideoChatDisplayOrderInfo: Equatable {

    public var action: VideoChatOrderAction

    /// 排序信息
    public var orderList: [ByteviewUser] = []

    /// 共享流插入的位置，插入到「position」位置，原来「position」位置的参会人向后移动一个位置，，index从0开始递增
    public var shareStreamInsertPosition: Int32

    /// rust使用，确保给客户端的是最新版本的排序信息，仅下行赋值
    public var versionID: Int64

    /// 顺序信息开始的index，仅下行赋值
    public var indexBegin: Int32

    /// 用来记录主持人主动点击【同步】的次数，客户端依据此值判断是否需要返回第一屏
    public var hostSyncSeqID: Int64

    /// 推送/拉取场景下，用以指示返回的是否为完整的视频顺序列表
    public var hasMore_p: Bool

    public init(action: VideoChatOrderAction, orderList: [ByteviewUser], shareStreamInsertPosition: Int32,
                versionID: Int64, indexBegin: Int32, hostSyncSeqID: Int64, hasMore_p: Bool) {
        self.action = action
        self.orderList = orderList
        self.shareStreamInsertPosition = shareStreamInsertPosition
        self.versionID = versionID
        self.indexBegin = indexBegin
        self.hostSyncSeqID = hostSyncSeqID
        self.hasMore_p = hasMore_p
    }

    public init(action: VideoChatOrderAction, orderList: [ByteviewUser], shareStreamInsertPosition: Int32) {
        self.init(action: action,
                  orderList: orderList,
                  shareStreamInsertPosition: shareStreamInsertPosition,
                  versionID: 0, indexBegin: 0, hostSyncSeqID: 0, hasMore_p: false)
    }
}

extension VideoChatDisplayOrderInfo: CustomStringConvertible {

    public var description: String {
        String(
            indent: "VideoChatDisplayOrderInfo",
            "action: \(action)",
            "orderList: \(orderList.count)",
            "shareStreamInsertPosition: \(shareStreamInsertPosition)",
            "versionID: \(versionID)",
            "indexBegin: \(indexBegin)",
            "hostSyncSeqID: \(hostSyncSeqID)",
            "hasMore_p: \(hasMore_p)"
        )
    }
}
