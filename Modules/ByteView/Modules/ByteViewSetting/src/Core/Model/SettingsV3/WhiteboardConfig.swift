//
//  WhiteboardConfig.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/4/10.
//

import Foundation

// disable-lint: magic number
public struct WhiteboardConfig: Decodable {
    public let canvasSize: CanvasSize
    public let sendSyncDataIntervalMs: Int
    public let replaySyncDataFps: Int
    public let larkPageMaxCount: Int

    static let `default` = WhiteboardConfig(canvasSize: CanvasSize(width: 1920, height: 1080), sendSyncDataIntervalMs: 200, replaySyncDataFps: 60, larkPageMaxCount: 10)

    public struct CanvasSize: Decodable, CustomStringConvertible {
        public let width: Int
        public let height: Int

        public var description: String {
            "CanvasSize(width: \(width), height: \(height))"
        }
    }
}
