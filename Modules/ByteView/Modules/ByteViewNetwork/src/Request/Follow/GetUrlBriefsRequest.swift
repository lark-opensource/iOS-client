//
//  GetUrlBriefsRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/22.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// - GET_URL_BRIEFS = 88053
/// - Videoconference_V1_GetUrlBriefsRequest
public struct GetUrlBriefsRequest {
    public static let command: NetworkCommand = .rust(.getURLBriefs)
    public typealias Response = GetUrlBriefsResponse

    public init(urls: [String]) {
        self.urls = urls
    }

    public var urls: [String]
}

/// Videoconference_V1_GetUrlBriefsResponse
public struct GetUrlBriefsResponse {

    public var urlBriefs: [String: FollowUrlBrief]
}

extension GetUrlBriefsRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_GetUrlBriefsRequest
    func toProtobuf() throws -> Videoconference_V1_GetUrlBriefsRequest {
        var request = ProtobufType()
        request.urls = urls
        var opts = ProtobufType.Opts()
        opts.getTitle = true
        opts.getType = true
        opts.getThumbnail = false
        request.opts = opts
        return request
    }
}

extension GetUrlBriefsResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_GetUrlBriefsResponse
    init(pb: Videoconference_V1_GetUrlBriefsResponse) throws {
        self.urlBriefs = pb.urlBriefs.mapValues({ FollowUrlBrief(pb: $0) })
    }
}

extension GetUrlBriefsRequest: CustomStringConvertible {
    public var description: String {
        String(indent: "GetUrlBriefsRequest", "urls count: \(urls.count)")
    }
}

extension GetUrlBriefsResponse: CustomStringConvertible {
    public var description: String {
        String(indent: "GetUrlBriefsResponse", "urlBriefs count: \(urlBriefs.count)")
    }
}
