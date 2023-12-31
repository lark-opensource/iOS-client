//
//  VoteContent.swift
//  LarkModel
//
//  Created by bytedance on 2022/4/18.
//

import Foundation
import RustPB

public struct VoteContent: MessageContent {
    public typealias PBModel = RustPB.Basic_V1_Message
    public typealias VoteScopeType = RustPB.Vote_V1_VoteScopeType
    public typealias VoteContainerType = Vote_V1_VoteContainerType
    public typealias VoteOption = RustPB.Vote_V1_VoteOption
    public typealias VoteStatus = RustPB.Vote_V1_VoteStatus

    public var uuid: Int64
    public var scopeID: String // 在会话场景下赋值，发起投票所在 chat
    public var scopeType: VoteScopeType  //投票范围类型，目前只支持IM_CHAT
    public var containerType: VoteContainerType  //投票容器类型，目前只支持IM_MESSAGE
    public var topic: String
    public var minPickNum: Int64  //最少投票数
    public var maxPickNum: Int64 //最多投票数
    public var isPublic: Bool //投票是否公开，false时为匿名
    public var options: [VoteOption] // 选项列表
    public var status: VoteStatus //投票状态，0为打开，1为关闭，其他为预留
    public var initiator: Int64 // 投票发起人

    public static func transform(pb: PBModel) -> VoteContent {
        return transform(content: pb.content.voteContent)
    }

    /// 一开始上面`transform(pb: PBModel) -> VoteContent`写的有问题，用的Basic_V1_Message，这并不合理，因为无法跟假消息复用，考虑到public方法的兼容问题，额外补充下面方法。
    static func transform(content: RustPB.Vote_V1_VoteContent) -> VoteContent {
        return VoteContent(uuid: content.uuid,
                           scopeID: content.scopeID,
                           scopeType: content.scopeType,
                           containerType: content.containerType,
                           topic: content.topic,
                           minPickNum: content.minPickNum,
                           maxPickNum: content.maxPickNum,
                           isPublic: content.isPublic,
                           options: content.options,
                           status: content.status,
                           initiator: content.initiator)
    }

    public func complement(entity: RustPB.Basic_V1_Entity, message: Message) {}
}
