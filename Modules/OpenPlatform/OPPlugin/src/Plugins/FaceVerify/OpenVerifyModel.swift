//
//  OpenVerifyModel.swift
//  OPPlugin
//
//  Created by zhysan on 2021/4/27.
//

import Foundation
import LarkOpenAPIModel

// MAKR: - Params

private let kOfflineVerifyPrepareTimeoutDefault = 60.0

final class OpenSetAuthenticationInfoParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "identifyName")
    var identifyName: String
    
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "identifyCode")
    var identifyCode: String
    
    @OpenAPIOptionalParam(jsonKey: "mobile")
    var mobile: String?
    
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "appId")
    var appId: String
    
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "nonce")
    var nonce: String
    
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "timestamp")
    var timestamp: String
    
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "sign")
    var sign: String
    
    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_identifyName,
                _identifyCode,
                _mobile,
                _appId,
                _nonce,
                _timestamp,
                _sign,
        ]
    }
    
    func toJSONDict() -> [String: Any] {
        var dict = [String: Any]()
        dict["identifyName"] = identifyName
        dict["identifyCode"] = identifyCode
        dict["mobile"] = mobile
        dict["appId"] = appId
        dict["nonce"] = nonce
        dict["timestamp"] = timestamp
        dict["sign"] = sign
        return dict
    }
}

final class OpenStartFaceVerifyParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "userId")
    var userId: String
    
    // jssdk session
    @OpenAPIOptionalParam(jsonKey: "session")
    var session: String?
    
    /// description: 动作场景值：
    /// "NULL_ACTION"：零动作
    /// "REMOVE_WINK_ACTION":去除眨眼动作
    @OpenAPIOptionalParam(
            jsonKey: "actionsScene",
            validChecker: OpenAPIValidChecker.length(0.nextUp...))
    var actionsScene: String?
    
    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_userId, _session, _actionsScene]
    }
}

final class OpenStartFaceIdentifyParams: OpenAPIBaseParams {
    
    // jssdk session
    @OpenAPIOptionalParam(jsonKey: "session")
    var session: String?

    @OpenAPIOptionalParam(jsonKey: "authType")
    var authType: String?

    @OpenAPIOptionalParam(jsonKey: "identityName")
    var identityName: String?

    @OpenAPIOptionalParam(jsonKey: "identityCode")
    var identityCode: String?

    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_session, _authType, _identityName, _identityCode]
    }
}

final class OpenPrepareLocalFaceVerifyParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(
        userOptionWithJsonKey: "timeout",
        defaultValue: kOfflineVerifyPrepareTimeoutDefault
    )
    var timeout: Double
    
    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_timeout]
    }
}

//活体指定动作.活体最多三个动作
enum MotionType:String {
    case WINK = "WINK"              //眨眼
    case OPEN_MOUTH = "OPEN_MOUTH"  //张嘴
    case NOD = "NOD"                //点头
    case SHAKE = "SHAKE"            //左右摇头
    
    public var typeInt: Int {
        switch self {
        case .WINK:
            return 0
        case .OPEN_MOUTH:
            return 1
        case .NOD:
            return 2
        case .SHAKE:
            return 3
        }
    }
}

final class OpenStartLocalFaceVerifyParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "path")
    var path: String
    @OpenAPIOptionalParam(jsonKey: "scene")
    var scene: String?
    @OpenAPIOptionalParam(jsonKey: "ticket")
    var ticket: String?
    @OpenAPIOptionalParam(jsonKey: "certAppId")
    var certAppId: String?
    @OpenAPIOptionalParam(jsonKey: "mode")
    var mode: Int?
    @OpenAPIOptionalParam(jsonKey: "motionTypes")
    var motionTypes: [String]?
    
    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_path, _scene, _ticket, _certAppId, _mode, _motionTypes]
    }
}

// MAKR: - Result

final class OpenOnlineFaceVerifyResult: OpenAPIBaseResult {
    let reqNo: String
    required init(reqNo: String) {
        self.reqNo = reqNo
        super.init()
    }
    
    override func toJSONDict() -> [AnyHashable : Any] {
        return [
            "reqNo": reqNo
        ]
    }
}

// MAKR: - Server Data Model

enum VerifyTicketType: String {
    /// 有源比对
    case identified = "verify"
    /// 无源比对
    case unidentified = "face_auth"
}

struct VerifyTicketParam {
    let ticketType: VerifyTicketType
    let uid: String
    let h5Session: String?
    let minaSession: String?
    var actionsScene: String? = nil
    
    // 加密后的姓名
    let name: String?
    // 加密后的身份证号码
    let code: String?

    func toServerJsonDict() -> [String: Any] {
        var dict = [
            "ticketType": ticketType.rawValue,
            "uid": uid,
            "h5Session": h5Session ?? "",
            "minaSession": minaSession ?? "",
            "name": name ?? "",
            "code": code ?? ""
        ]
        if let actionsScene {
            dict["scene"] = actionsScene
        }
        return dict
    }
}

struct VerifyTicket: Codable {
    let ticket: String
    let scene: String?
    let appId: Int?
    let mode: Int?
    
    func toSDKJsonDict() -> [AnyHashable: Any] {
        var dict = [AnyHashable: Any]()
        dict["ticket"] = ticket
        dict["scene"] = scene
        // 注意这个字段，传给 SDK 的和服务端返回的命名不一致
        dict["aid"] = appId
        dict["mode"] = mode
        return dict
    }
}

