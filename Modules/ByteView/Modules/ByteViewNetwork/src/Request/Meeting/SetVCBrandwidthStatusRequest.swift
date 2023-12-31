//
//  SetVCBandwidthStatusRequest.swift
//  ByteViewNetwork
//
//  Created by ZhangJi on 2022/2/11.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// - SET_VC_BANDWIDTH_STATUS = 800104
/// - Tool_V1_SetVcBandwidthStatusRequest
public struct SetVCBandwidthStatusRequest: Equatable {
    public static let command: NetworkCommand = .rust(.setVcBandwidthStatus)

    public init(vcStatus: VCStatus,
                bandwidthLevel: BandwidthLevel,
                limitStreamDirection: StreamDirection,
                detectedUpstreamBandwidth: Int64,
                detectedDownstreamBandwidth: Int64) {
        self.vcStatus = vcStatus
        self.bandwidthLevel = bandwidthLevel
        self.detectedUpstreamBandwidth = detectedUpstreamBandwidth
        self.detectedDownstreamBandwidth = detectedDownstreamBandwidth
        self.limitStreamDirection = limitStreamDirection
    }

    public var vcStatus: VCStatus
    public var bandwidthLevel: BandwidthLevel
    public var limitStreamDirection: StreamDirection
    public var detectedUpstreamBandwidth: Int64
    public var detectedDownstreamBandwidth: Int64

    public enum VCStatus: Int, Hashable {
        case open = 0
        case close // = 1
    }

    public enum BandwidthLevel: Int, Hashable {
        case unknown = 0
        case normal // = 1
        case low // = 2
        case extremelyLow // = 3
    }

    public enum StreamDirection: Int, Hashable {
        case upstream = 0
        case downstream // = 1
    }
}

extension SetVCBandwidthStatusRequest: RustRequest {
    typealias ProtobufType = Tool_V1_SetVcBandwidthStatusRequest
    func toProtobuf() throws -> Tool_V1_SetVcBandwidthStatusRequest {
        var request = ProtobufType()
        request.vcStatus = .init(rawValue: vcStatus.rawValue) ?? .open
        request.bandwidthLevel = .init(rawValue: bandwidthLevel.rawValue) ?? .levelUnknown
        request.limitStreamDirection = .init(rawValue: limitStreamDirection.rawValue) ?? .upstream
        request.detectedUpstreamBandwidth = detectedUpstreamBandwidth
        request.detectedDownstreamBandwidth = detectedDownstreamBandwidth
        return request
    }
}

extension SetVCBandwidthStatusRequest: CustomStringConvertible {
    public var description: String {
        String(indent: "SetVCBandwidthStatusRequest", "vcStatus: \(vcStatus)", "bandwidthLevel: \(bandwidthLevel)", "limitStreamDirection: \(limitStreamDirection)", "detectedUpstreamBandwidth: \(detectedUpstreamBandwidth)", "detectedDownstreamBandwidth: \(detectedDownstreamBandwidth)")
    }
}
