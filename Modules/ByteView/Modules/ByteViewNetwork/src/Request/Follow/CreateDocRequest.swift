//
//  CreateDocRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/22.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon
import RustPB

/// - Space_Doc_V1_CreateDocRequest
public struct CreateDocRequest {
    public static let command: NetworkCommand = .rust(.createDoc)
    public typealias Response = CreateDocResponse

    public init(docType: VcDocType) {
        self.docType = docType
    }

    public var docType: VcDocType
}

/// - Space_Doc_V1_CreateDocResponse
public struct CreateDocResponse {

    public var url: String
}

extension CreateDocRequest: RustRequestWithResponse {
    typealias ProtobufType = Space_Doc_V1_CreateDocRequest
    func toProtobuf() throws -> Space_Doc_V1_CreateDocRequest {
        var request = ProtobufType()
        request.type = .unknown
        request.createType = docType.createDocType
        return request
    }
}

extension CreateDocResponse: RustResponse {
    typealias ProtobufType = Space_Doc_V1_CreateDocResponse
    init(pb: Space_Doc_V1_CreateDocResponse) throws {
        self.url = pb.url
    }
}

extension CreateDocResponse: CustomStringConvertible {
    public var description: String {
        String(indent: "CreateDocResponse", "url: \(url.hash)")
    }
}

private extension VcDocType {
    var createDocType: CreateDocRequest.ProtobufType.CreateDocType {
        switch self {
        case .doc:
            return .doc
        case .sheet:
            return .sheet
        case .mindnote:
            return .mindnote
        case .docx:
            return .docx
        case .bitable:
            return .bitable
        default:
            Logger.network.warn("selected an unknown file type, will return ccmDoc")
            return .doc
        }
    }
}
