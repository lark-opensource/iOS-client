//
//  SketchGrootCell.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/15.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

public typealias SketchOperationUnit = Videoconference_V1_SketchOperationUnit
public typealias SketchGrootSession = TypedGrootSession<SketchGrootCellNotifier>

public protocol SketchGrootCellObserver: AnyObject {
    func didReceiveSketchGrootCells(_ cells: [SketchGrootCell], for channel: GrootChannel)
    func didReceiveSketchGrootCells(_ cells: [SketchGrootCell], sender: [ByteviewUser?], for channel: GrootChannel)
}

public final class SketchGrootCellNotifier: GrootCellNotifier<SketchGrootCell, SketchGrootCellObserver> {

    override func dispatch(message: [SketchGrootCell], to observer: SketchGrootCellObserver) {
        observer.didReceiveSketchGrootCells(message, for: channel)
    }

    override func dispatch(message: [SketchGrootCell], sender: [ByteviewUser?], to observer: SketchGrootCellObserver) {
        observer.didReceiveSketchGrootCells(message, sender: sender, for: channel)
    }
}

/// 顺序由op保证，sketch相关pb不再转换
/// - Videoconference_V1_SketchGrootCellPayload
public struct SketchGrootCell: Equatable {
    public init(meetingID: String, units: [SketchOperationUnit]) {
        self.meetingID = meetingID
        self.units = units
    }

    public var meetingID: String
    public var units: [SketchOperationUnit]
}
