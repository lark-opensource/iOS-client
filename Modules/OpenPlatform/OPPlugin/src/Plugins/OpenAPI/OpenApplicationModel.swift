//
//  OpenApplicationModel.swift
//  OPPlugin
//
//  Created by yi on 2021/3/23.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPIGetLaunchOptionsResult: OpenAPIBaseResult {
    public var data: [AnyHashable: Any]

    public init(data: [AnyHashable: Any]) {
        self.data = data
        super.init()
    }
    public override func toJSONDict() -> [AnyHashable : Any] {
        return data
    }
}

final class OpenAPIGetHostLaunchQueryResult: OpenAPIBaseResult {
    public let launchQuery: String

    public init(launchQuery: String) {
        self.launchQuery = launchQuery
        super.init()
    }
    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["launchQuery": launchQuery]
    }
}

final class OpenAPIGetAppInfoSyncResult: OpenAPIBaseResult {
    public var appId: String
    public var session: String
    public var schema: String
    public var whiteList: [String]
    public var blackList: [String]

    public init(appId: String, session: String, schema: String, whiteList: [String], blackList: [String]) {
        self.appId = appId
        self.session = session
        self.schema = schema
        self.whiteList = whiteList
        self.blackList = blackList
        super.init()
    }

    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["appId": appId,
                "session": session,
                "schema": schema,
                "whiteList": whiteList,
                "blackList": blackList]
    }
}


final class OpenAPIGetAppbrandSettingsResult: OpenAPIBaseResult {
    public let data: String

    public init(data: String) {
        self.data = data
        super.init()
    }
    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["data": data]
    }
}

final class OpenAPIGetAppbrandSettingsParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "fields", validChecker: {
        !$0.isEmpty
    })
    public var fields: [String]

    public convenience init(fields: [String]) throws {
        let dict: [String: Any] = ["fields": fields]
        try self.init(with: dict)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_fields]
    }
}

final class OpenAPIMenuButtonAbilityParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userOptionWithJsonKey: "visible", defaultValue: true)
    public var visible: Bool
    
}

final class OpenAPIGetUserInfoInJSWorkerResult: OpenAPIBaseResult {
    public let userId: String
    public let userName: String
    public let userAvatarUrl: String

    public init(userId: String, userName: String, userAvatarUrl: String) {
        self.userId = userId
        self.userName = userId
        self.userAvatarUrl = userId
        super.init()
    }
    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["userId": userId, "userName": userName, "userAvatarUrl": userAvatarUrl]
    }
}

public final class OpenAPIEnableLeaveConfirmParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userOptionWithJsonKey: "effect", defaultValue: [])
    public var effect: [String]
    @OpenAPIRequiredParam(userOptionWithJsonKey: "title", defaultValue: "")
    public var title: String
    @OpenAPIRequiredParam(userOptionWithJsonKey: "content", defaultValue: "")
    public var content: String
    @OpenAPIRequiredParam(userOptionWithJsonKey: "confirmText", defaultValue: BundleI18n.OPPlugin.determine)
    public var confirmText: String
    @OpenAPIRequiredParam(userOptionWithJsonKey: "cancelText", defaultValue: BundleI18n.OPPlugin.cancel)
    public var cancelText: String
    @OpenAPIRequiredParam(userOptionWithJsonKey: "cancelColor", defaultValue: "")
    public var cancelColor: String
    @OpenAPIRequiredParam(userOptionWithJsonKey: "confirmColor", defaultValue: "")
    public var confirmColor: String
    
    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_effect, _title, _content, _confirmText, _cancelText, _cancelColor, _confirmColor]
    }
    
    public func checkError() -> OpenAPIError? {
        let params = self
        // 入参校验
        guard params.title.count <= 16 else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                .setMonitorMessage("parameter title invalid,should be less than 16 charactors")
                .setErrno(OpenAPICommonErrno.invalidParam(.invalidParam(param: "title, should be less than 16 charactors")))
            return error
        }
        
        guard params.content.count <= 80 else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                .setMonitorMessage("parameter content invalid,should be less than 80 charactors")
                .setErrno(OpenAPICommonErrno.invalidParam(.invalidParam(param: "content, should be less than 80 charactors")))
            return error
        }
        
        guard params.title.count > 0 || params.content.count > 0  else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                .setMonitorMessage("parameter title and content cannot be empty at the same time")
                .setErrno(OpenAPICommonErrno.invalidParam(.invalidParam(param: "title or content, cannot be empty at the same time")))
            return error
        }
        
        guard params.confirmText.count <= 8 else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                .setMonitorMessage("parameter confirmText invalid,should be less than 8 charactors")
                .setErrno(OpenAPICommonErrno.invalidParam(.invalidParam(param: "confirmText, should be less than 8 charactors")))
            return error
        }
        
        guard params.cancelText.count <= 8 else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                .setMonitorMessage("parameter cancelText invalid,should be less than 8 charactors")
                .setErrno(OpenAPICommonErrno.invalidParam(.invalidParam(param: "cancelText, should be less than 8 charactors")))
            return error
        }
        return nil
    }
}
