//
//  PstnInComingCallInfoRequest.swift
//  ByteViewNetwork
//
//  Created by wangpeiran on 2023/5/5.
//

import Foundation
import RustPB

/// Videoconference_V1_PstnInComingCallInfoRequest
public struct PstnInComingCallInfoRequest {
    public static let command: NetworkCommand = .rust(.pstnIncomingCallInfo)
    public typealias Response = PstnInComingCallInfoResponse

    public init(tenantID: String, uniqueID: String, userId: Int64, isInterview: Bool, calendarInstanceIdentifier: CalendarInstanceIdentifier) {
        self.tenantID = tenantID
        self.uniqueID = uniqueID
        self.userId = userId
        self.isInterview = isInterview
        self.calendarInstanceIdentifier = calendarInstanceIdentifier
    }

    public var tenantID: String

    public var uniqueID: String

    public var userId: Int64

    public var isInterview: Bool

    public var calendarInstanceIdentifier: CalendarInstanceIdentifier
}

/// - Videoconference_V1_PstnInComingCallInfoResponse
public struct PstnInComingCallInfoResponse {
    public init(fcPstnIncomingCallEnable: Bool, adminSettingPstnEnableIncomingCall: Bool, pstnIncomingCallCountryDefault: [String], pstnIncomingCallPhoneList: [PSTNPhone]) {
        self.fcPstnIncomingCallEnable = fcPstnIncomingCallEnable
        self.adminSettingPstnEnableIncomingCall = adminSettingPstnEnableIncomingCall
        self.pstnIncomingCallCountryDefault = pstnIncomingCallCountryDefault
        self.pstnIncomingCallPhoneList = pstnIncomingCallPhoneList
    }

    /// featureConfig是否支持呼入 对应GetPstnSipFeatureConfigResponse.FeatureConfig.Pstn.incoming_call_enable 这个布尔值
    public var fcPstnIncomingCallEnable: Bool

    /// adminSetting是否支持呼入 对应GetAdminSettingsResponse.pstn_enable_incoming_call 这个布尔值
    public var adminSettingPstnEnableIncomingCall: Bool

    public var pstnIncomingCallCountryDefault: [String] = []

    public var pstnIncomingCallPhoneList: [PSTNPhone] = []

}

extension PstnInComingCallInfoRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_PstnInComingCallInfoRequest
    func toProtobuf() throws -> Videoconference_V1_PstnInComingCallInfoRequest {
        var request = ProtobufType()
        request.tenantID = tenantID
        request.uniqueID = uniqueID
        request.userID = userId
        request.calendarType = isInterview ? .interview : .unknown
        request.calendarInstanceIdentifier = calendarInstanceIdentifier.pbType
        return request
    }
}

extension PstnInComingCallInfoResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_PstnInComingCallInfoResponse
    init(pb: Videoconference_V1_PstnInComingCallInfoResponse) throws {
        self.fcPstnIncomingCallEnable = pb.fcPstnIncomingCallEnable
        self.adminSettingPstnEnableIncomingCall = pb.adminSettingPstnEnableIncomingCall
        self.pstnIncomingCallCountryDefault = pb.pstnIncomingCallCountryDefault
        self.pstnIncomingCallPhoneList = pb.pstnIncomingCallPhoneList.map({ .init(pb: $0) })
    }
}
