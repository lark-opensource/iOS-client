//
//  CreateEnterprisePhoneRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// - CREATE_ENTERPRISE_PHONE = 89450
/// - ServerPB_Videochat_CreateEnterprisePhoneRequest
public struct CreateEnterprisePhoneRequest {
    public static let command: NetworkCommand = .server(.createEnterprisePhone)
    public typealias Response = CreateEnterprisePhoneResponse

    public init(calleeId: String, chatId: String?, phoneNumber: String?, phoneType: EnterprisePhoneType?, candidateInfo: CandidateInfo?) {
        self.calleeId = calleeId
        self.chatId = chatId
        self.phoneNumber = phoneNumber
        self.phoneType = phoneType
        self.candidateInfo = candidateInfo
    }

    public var calleeId: String

    public var chatId: String?

    public var phoneNumber: String?

    public var phoneType: EnterprisePhoneType?

    public var candidateInfo: CandidateInfo?

}

public enum EnterprisePhoneType: Int, Hashable, CustomStringConvertible {
    case enterprise // = 0
    case recruitment // = 1

    public var description: String {
        switch self {
        case .enterprise:
            return "enterprise"
        case .recruitment:
            return "recruitment"
        }
    }
}

public struct CandidateInfo {

    public var candidateID: String

    public var candidateName: String?

    public var candidatePhoneNumber: String?

    public init(candidateID: String, candidateName: String?, candidatePhoneNumber: String?) {
        self.candidateID = candidateID
        self.candidateName = candidateName
        self.candidatePhoneNumber = candidatePhoneNumber
    }

}

/// ServerPB_Videochat_CreateEnterprisePhoneResponse
public struct CreateEnterprisePhoneResponse {

    public var enterprisePhoneID: String
    public var candidateInfo: CandidateInfo?
}

extension CreateEnterprisePhoneRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_CreateEnterprisePhoneRequest
    typealias PBCandidateInfo = ServerPB_Videochat_CandidateInfo
    func toProtobuf() throws -> ServerPB_Videochat_CreateEnterprisePhoneRequest {
        var request = ProtobufType()
        request.calleeID = calleeId
        if let chatId = chatId {
            request.chatID = chatId
        }
        if let phoneNumber = phoneNumber {
            request.phoneNumber = phoneNumber
        }
        if let phoneType = phoneType {
            request.phoneType = ProtobufType.PhoneType(rawValue: phoneType.rawValue) ?? .enterprise
        }
        if let candidateInfo = candidateInfo {
            var pbCandidateInfo = PBCandidateInfo()
            pbCandidateInfo.candidateID = candidateInfo.candidateID
            pbCandidateInfo.candidateName = candidateInfo.candidateName ?? ""
            pbCandidateInfo.candidatePhoneNumber = candidateInfo.candidatePhoneNumber ?? ""
            request.candidateInfo = pbCandidateInfo
        }
        return request
    }
}

extension CreateEnterprisePhoneResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_CreateEnterprisePhoneResponse
    init(pb: ServerPB_Videochat_CreateEnterprisePhoneResponse) throws {
        self.enterprisePhoneID = pb.enterprisePhoneID
        self.candidateInfo = .init(candidateID: pb.candidateInfo.candidateID, candidateName: pb.candidateInfo.candidateName, candidatePhoneNumber: pb.candidateInfo.candidatePhoneNumber)
    }
}

extension CandidateInfo: CustomStringConvertible {
    public var description: String {
        String(name: "CandidateInfo", dropNil: true, [
            "candidateID": candidateID, "candidatePhoneNumber": candidatePhoneNumber?.count
        ])
    }
}

extension CreateEnterprisePhoneRequest: CustomStringConvertible {
    public var description: String {
        String(name: "CreateEnterprisePhoneRequest", dropNil: true, [
            "calleeId": calleeId, "chatId": chatId, "phoneNumber": phoneNumber?.count,
            "phoneType": phoneType, "candidateInfo": candidateInfo
        ])
    }
}
