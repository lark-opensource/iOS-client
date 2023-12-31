//
//  FetchAllSketchDataRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/23.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

public typealias SketchDataUnit = Videoconference_V1_SketchDataUnit

/// - FETCH_ALL_SKETCH_DATA
/// - Videoconference_V1_FetchAllSketchDataRequest
public struct FetchAllSketchDataRequest {
    public static let command: NetworkCommand = .rust(.fetchAllSketchData)
    public typealias Response = FetchAllSketchDataResponse

    public init(shareScreenId: String) {
        self.shareScreenId = shareScreenId
    }

    public var shareScreenId: String
}

/// - Videoconference_V1_FetchAllSketchDataResponse
public struct FetchAllSketchDataResponse {

    public var sketchUnits: [SketchDataUnit]

    /// 用于给 open groot channel
    public var version: Int32

    /// fetch data的用户的step
    public var currentStep: Int32
}

extension FetchAllSketchDataRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_FetchAllSketchDataRequest
    func toProtobuf() throws -> Videoconference_V1_FetchAllSketchDataRequest {
        var req = ProtobufType()
        req.shareScreenID = shareScreenId
        return req
    }
}

extension FetchAllSketchDataResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_FetchAllSketchDataResponse
    init(pb: Videoconference_V1_FetchAllSketchDataResponse) throws {
        self.sketchUnits = pb.sketchUnits
        self.version = pb.version
        self.currentStep = pb.currentStep
    }
}
