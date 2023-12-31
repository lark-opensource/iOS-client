//
//  FollowGrootCellPayload.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/9.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

public typealias FollowGrootSession = TypedGrootSession<FollowGrootCellNotifier>

public protocol FollowGrootCellObserver: AnyObject {
    func didReceiveFollowGrootCells(_ cells: [FollowGrootCell], for channel: GrootChannel)
}

public final class FollowGrootCellNotifier: GrootCellNotifier<FollowGrootCell, FollowGrootCellObserver> {

    override func dispatch(message: [FollowGrootCell], to observer: FollowGrootCellObserver) {
        observer.didReceiveFollowGrootCells(message, for: channel)
    }
}

/// Follow通过Groot发包的通用结构体
/// - Videoconference_V1_FollowGrootCellPayload
public struct FollowGrootCell: Equatable {
    public init(type: TypeEnum, patches: [FollowPatch], states: [FollowState]) {
        self.type = type
        self.patches = patches
        self.states = states
    }

    public init(patches: [FollowPatch]) {
        self.type = .patches
        self.patches = patches
    }

    public init(states: [FollowState]) {
        self.type = .states
        self.states = states
    }

    public var type: TypeEnum

    public var patches: [FollowPatch] = []

    public var states: [FollowState] = []

    public enum TypeEnum: Int, Hashable {
        case unknown // = 0

        /// 代表是一个传输patch的包
        case patches // = 1

        /// 代表是一个传输全量state包
        case states // = 2
    }
}
