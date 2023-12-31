//
//  VCNoticeGrootCell.swift
//  ByteViewNetwork
//
//  Created by lutingting on 2022/9/20.
//

import Foundation

public typealias VCNoticeGrootSession = TypedGrootSession<VCNoticeGrootCellNotifier>

public protocol VCNoticeGrootCellObserver: AnyObject {
    func didReceiveVCNoticeGrootCells(_ cells: [VCNoticeGrootCell], for channel: GrootChannel)
}

public final class VCNoticeGrootCellNotifier: GrootCellNotifier<VCNoticeGrootCell, VCNoticeGrootCellObserver> {

    override func dispatch(message: [VCNoticeGrootCell], to observer: VCNoticeGrootCellObserver) {
        observer.didReceiveVCNoticeGrootCells(message, for: channel)
    }
}

/// 主端事件卡片groot推送结构
/// Videoconference_V1_VCNoticeGrootCellPayload
public struct VCNoticeGrootCell {

    /// 事件卡片信息
    public var upsertImNoticeInfo: IMNoticeInfo

    /// 要消失的卡片
    public var dismissNoticeMeetingId: String?

    /// 统计数据对应的会议下行版本号，用于与详情页拉取得到的版本号比对
    public var version: Int32

    public init(upsertImNoticeInfo: IMNoticeInfo, dismissNoticeMeetingId: String?, version: Int32) {
        self.upsertImNoticeInfo = upsertImNoticeInfo
        self.dismissNoticeMeetingId = dismissNoticeMeetingId
        self.version = version
    }
}
