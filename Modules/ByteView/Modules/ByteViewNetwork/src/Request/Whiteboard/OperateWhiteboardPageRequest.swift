//
//  OperateWhiteboardPageRequest.swift
//  ByteViewNetwork
//
//  Created by helijian on 2023/1/5.
//

import Foundation
import RustPB

/// Videoconference_V1_OperateWhiteboardPageRequest
public struct OperateWhiteboardPageRequest {
    public static let command: NetworkCommand = .rust(.operateWhiteboardPage)
    public typealias Response = OperateWhiteboardPageResponse
    public enum Action: Int, Hashable {
        case newPage = 1
        case deletePage
        case changeSharePage
    }

    public var action: Action
    public var whiteboardId: Int64
    public var pages: [WhiteboardPage]

    public init(action: Action, whiteboardId: Int64, pages: [WhiteboardPage]) {
        self.action = action
        self.whiteboardId = whiteboardId
        self.pages = pages
    }
}

public struct OperateWhiteboardPageResponse {
    public var whiteboardPages: [WhiteboardPage]
}

extension OperateWhiteboardPageRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_OperateWhiteboardPageRequest
    func toProtobuf() throws -> Videoconference_V1_OperateWhiteboardPageRequest {
        var request = ProtobufType()
        switch action {
        case .newPage:
            request.action = .newPage
        case .deletePage:
            request.action = .deletePage
        case .changeSharePage:
            request.action = .changeSharePage
        }
        request.whiteboardID = whiteboardId
        request.pages = pages.map { $0.pbType }
        return request
    }
}

extension OperateWhiteboardPageResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_OperateWhiteboardPageResponse
    init(pb: Videoconference_V1_OperateWhiteboardPageResponse) throws {
        self.whiteboardPages = pb.pages.map { $0.vcType }
    }
}
