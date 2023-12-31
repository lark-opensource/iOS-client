//
//  ParticipantGridChecker.swift
//  ByteView
//
//  Created by liujianlong on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import ByteViewNetwork
import ByteViewRtcBridge

public struct ParticipantGridDiagnosticInfo: CustomStringConvertible {
    public var participantID: ParticipantId?
    public var rtcJoinID: String?
    public var viewSize: CGSize
    public var indexPath: IndexPath?
    public var isAvatarHidden: Bool
    public var isCellVisible: Bool
    public var isRendering: Bool
    public var isCamMuted: Bool?
    public var isMicrophoneMuted: Bool?
    public var streamStatus: StreamStatus?

    public var description: String {
        "(indexPath:\(indexPath), id: \(participantID?.pid), rtcJoinID: \(rtcJoinID), viewSize: \(viewSize), isAvatarHidden:\(isAvatarHidden), isRendering:\(isRendering), isCamMuted:\(isCamMuted), isMicMuted:\(isMicrophoneMuted), \(streamStatus))"
    }
}

public protocol ParticipantGridDebugToolProtocol {
    func setup(collectionView: UICollectionView, statusChecker: ParticipantGridStatusChecker)
    func destroy()
}

public struct ParticipantGridDebugToolResolver {
    private static var generator: (() -> ParticipantGridDebugToolProtocol)?
    public static func setup(_ generator: @escaping () -> ParticipantGridDebugToolProtocol) {
        self.generator = generator
    }

    static func resolve() -> ParticipantGridDebugToolProtocol? {
        generator?()
    }
}

public final class ParticipantGridStatusChecker {
    public let meetingID: String
    let collectionView: UICollectionView
    let rtc: RtcStatus

    init(meetingID: String, collectionView: UICollectionView, rtc: RtcStatus) {
        self.meetingID = meetingID
        self.collectionView = collectionView
        self.rtc = rtc
    }

    public func checkCellStatus(_ cell: UICollectionViewCell) -> ParticipantGridDiagnosticInfo? {
        guard let cell = cell as? InMeetingParticipantGridCell else {
            return nil
        }
        return self.checkCellStatus(cell)
    }

    public func checkAllStreamStatus() -> [StreamStatus] {
        rtc.tryGetAllVideoStreamStatus()
    }

    private func checkCellStatus(_ cell: InMeetingParticipantGridCell) -> ParticipantGridDiagnosticInfo {
        let streamKey = cell.participantView.streamRenderView.streamKey
        let participant = cell.participantView.cellViewModel?.participant.value
        var diagnosticInfo = ParticipantGridDiagnosticInfo(participantID: participant?.participantId,
                                                           rtcJoinID: participant?.rtcJoinId,
                                                           viewSize: cell.participantView.streamRenderView.frame.size,
                                                           isAvatarHidden: cell.participantView.avatar.isHidden,
                                                           isCellVisible: cell.participantView.isCellVisible,
                                                           isRendering: cell.participantView.isRendering,
                                                           isCamMuted: participant?.settings.isCameraMutedOrUnavailable,
                                                           isMicrophoneMuted: participant?.settings.isMicrophoneMutedOrUnavailable)
        self.collectionView.indexPath(for: cell)
        diagnosticInfo.indexPath = collectionView.indexPath(for: cell)
        if let key = streamKey, let streamStatus = rtc.tryGetVideoStreamStatus(key: key) {
            diagnosticInfo.streamStatus = streamStatus
        }
        return diagnosticInfo
    }

    public func checkVisibleCellsStatus() -> [ParticipantGridDiagnosticInfo] {
        assert(Thread.isMainThread)

        let cells = self.collectionView.visibleCells
        var infos: [ParticipantGridDiagnosticInfo] = []
        infos.reserveCapacity(cells.count)
        for case let cell as InMeetingParticipantGridCell in cells {
            infos.append(self.checkCellStatus(cell))
        }
        return infos.sorted { ($0.indexPath?.row ?? 0) < ($1.indexPath?.row ?? 0) }
    }
}
