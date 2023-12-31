//
//  MeegoNetClientDefine.swift
//  LarkMeegoPush
//
//  Created by ByteDance on 2022/7/7.
//

import Foundation

public enum MeegoHeaderKeys {
    static let appVersion = "app-version"
    static let versionCode = "versioncode"
    static let appHost = "apphost"
    static let deviceId = "device-id"
    static let appId = "app-id"
    static let platform = "platform"
    static let userAgent = "user-agent"
    static let clientPipe = "client-pipe"
    static let locale = "locale"
    static let cookie = "cookie"
    static let ttEnv = "x-tt-env"
    static let ttUsePPE = "x-use-ppe"
    static let contentLanguage = "x-content-language"

    public static let csrfToken = "x-meego-csrf-token"   // header key for meego csrfToken
    public static let ttLogId = "x-tt-logid"
    public static let switchToLarkGateway = "x-lark-gw"
    // key in cookie
    public enum CookieName {
        public static let csrfToken = "meego_csrf_token"
    }
}

public enum HttpMethod {
    public static let GET = "GET"
    public static let POST = "POST"
    public static let PUT = "PUT"
    public static let DELETE = "DELETE"
}

public enum TTNetErrorUserInfoKeys {
    public static let errorNum = "error_num"
}

public enum MeegoNetClientErrorCode {
    public static let unknownError = 1000
    public static let jsonTransformToModelFailed = 1005
    public static let invalidResponseData = 1008
}
