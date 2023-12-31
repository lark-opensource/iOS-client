//
//  JoinTeamReqBody.swift
//  SuiteLogin
//
//  Created by Yiming Qu on 2020/5/13.
//

import Foundation

class TeamCodeReqBody: RequestBody {
    let type: String
    let teamCode: String?
    let qrUrl: String?
    let flowType: String?
    let sceneInfo: [String: String]?
    let context: UniContextProtocol

    init(
        type: String,
        teamCode: String? = nil,
        qrUrl: String? = nil,
        flowType: String? = nil,
        sceneInfo: [String: String]? = nil,
        context: UniContextProtocol
    ) {
        self.type = type
        self.teamCode = teamCode
        self.qrUrl = qrUrl
        self.flowType = flowType
        self.sceneInfo = sceneInfo
        self.context = context
    }

    func getParams() -> [String: Any] {
        var params: [String: Any] = [
            "type": type
        ]
        if let teamCode = teamCode {
            params["team_code"] = teamCode
        }
        if let qrUrl = qrUrl {
            params["qr_code"] = qrUrl
        }
        if let flowType = flowType {
            params["flow_type"] = flowType
        }
        return params
    }
}

class UserCreateReqBody: RequestBody {
    let isC: Bool
    let tenantName: String?
    let userName: String?
    let tenantType: Int?
    let optIn: Bool?
    let sceneInfo: [String: String]?
    let staffSize: String?
    let industryType: String?
    let regionCode: String?
    let flowType: String?
    let usePackageDomain: Bool
    let context: UniContextProtocol
    let trustedMailIn: Bool?

    init(
        isC: Bool,
        tenantName: String? = nil,
        userName: String? = nil,
        tenantType: Int? = nil,
        optIn: Bool? = nil,
        sceneInfo: [String: String]? = nil,
        staffSize: String? = nil,
        industryType: String? = nil,
        regionCode: String? = nil,
        flowType: String? = nil,
        usePackageDomain: Bool = false,
        context: UniContextProtocol,
        trustedMailIn: Bool? = nil
    ) {
        self.isC = isC
        self.tenantName = tenantName
        self.userName = userName
        self.tenantType = tenantType
        self.optIn = optIn
        self.sceneInfo = sceneInfo
        self.staffSize = staffSize
        self.industryType = industryType
        self.regionCode = regionCode
        self.flowType = flowType
        self.usePackageDomain = usePackageDomain
        self.context = context
        self.trustedMailIn = trustedMailIn
    }

    func getParams() -> [String: Any] {
        var params: [String: Any] = ["is_c": isC]
        if let tname = tenantName {
            params["tenant_name"] = tname
        }
        if let userName = userName {
            params["user_name"] = userName
        }
        if let tenantType = tenantType {
            params["tenant_type"] = tenantType
        }

        if let staffSize = staffSize {
            params["staff_size"] = staffSize
        }

        if let industryType = industryType {
            params["industry_type"] = industryType
        }
        
        if let regionCode = regionCode {
            params["region_code"] = regionCode
        }

        if let flowType = flowType {
            params["flow_type"] = flowType
        }
        if let trustedMailIn = trustedMailIn {
            params["trusted_mail_in"] = trustedMailIn
        }

        params["opt_in"] = optIn ?? NSNull()

        return params
    }
}

