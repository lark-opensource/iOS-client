//
//  GetExtraMeetingVirtualBackgroundRequest.swift
//  ByteViewNetwork
//
//  Created by wangpeiran on 2022/11/21.
//

import Foundation
import ServerPB
import ByteViewCommon

public struct VirtualBgImage: Decodable {
    public let name: String
    @DefaultDecodable.EmptyString
    public var url: String
    @DefaultDecodable.EmptyString
    public var portraitUrl: String
    @DefaultDecodable.False
    public var isSetting: Bool
    @DefaultDecodable.False
    public var isPeople: Bool

    public init(name: String, url: String, portraitUrl: String, isSetting: Bool, isPeople: Bool) {
        self.name = name
        self.url = url
        self.portraitUrl = portraitUrl
        self.isSetting = isSetting
        self.isPeople = isPeople
    }
}

public struct GetExtraMeetingVirtualBackgroundRequest {
    public typealias Response = GetExtraMeetingVirtualBackgroundResponse
    public static let command: NetworkCommand = .server(.getExtraMeetingEffectSettings)

    public init(uniqueID: String?, meetingId: String?, isWebinar: Bool?) {
        self.uniqueID = uniqueID
        self.meetingId = meetingId
        self.isWebinar = isWebinar
    }

    public var uniqueID: String?
    public var meetingId: String?
    public var isWebinar: Bool?
}

public struct GetExtraMeetingVirtualBackgroundResponse {
    public var allowVirtualBackground: Bool
    public var allowVirtualAvatar: Bool

    public var virtualBgImage: VirtualBgImage?
}

extension GetExtraMeetingVirtualBackgroundRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_material_GetExtraMeetingEffectSettingsRequest
    func toProtobuf() throws -> ServerPB_Videochat_material_GetExtraMeetingEffectSettingsRequest {
        var request = ProtobufType()
        if let uniqueID = uniqueID {
            request.uniqueID = uniqueID
        } else if let meetingId = meetingId {
            request.meetingID = meetingId
        }
        if let isWebinar = isWebinar {
            request.meetingSubType = isWebinar ? .webinar : .default
        }
        return request
    }
}

extension GetExtraMeetingVirtualBackgroundResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_material_GetExtraMeetingEffectSettingsResponse
    init(pb: ServerPB_Videochat_material_GetExtraMeetingEffectSettingsResponse) throws {
        self.allowVirtualBackground = pb.hasAllowVirtualBackground ? pb.allowVirtualBackground : true
        self.allowVirtualAvatar = pb.hasAllowVirtualAvatar ? pb.allowVirtualAvatar : true
        self.virtualBgImage = pb.hasVirtualBackground ? .init(name: pb.virtualBackground.name, url: pb.virtualBackground.url, portraitUrl: pb.virtualBackground.portraitURL, isSetting: false, isPeople: false) : nil
    }
}

extension VirtualBgImage: CustomStringConvertible {
    public var description: String {
        String(name: "VirtualBgImage", ["name": name, "url": url.hash, "portraitUrl": portraitUrl.hash, "isSetting": isSetting, "isPeople": isPeople])
    }
}
