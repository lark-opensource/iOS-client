//
//  SyncUpcomingInstances.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/12.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// - PUSH_VC_SYNC_UPCOMING_INSTANCES = 89362
/// - Videoconference_V1_PushVcSyncUpcomingInstances
public struct PushSyncUpcomingInstances {}

extension PushSyncUpcomingInstances: NetworkDecodable {
    public static let protoName: String = "Videoconference_V1_PushVcSyncUpcomingInstances"
    public init(serializedData data: Data) throws {}
}
