//
//  HTTPRequest.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2022/4/13.
//

import LarkSetting
import Alamofire
import LarkAccountInterface
import LarkContainer
import LarkReleaseConfig
import LarkFoundation
import Foundation
import LarkExtensions
import LarkSensitivityControl
private let pathSuffx = "/lark/scs/compliance"
private let schema = "https://"

public protocol Request {
    func asURLRequest() throws -> URLRequest
    // 打点上报使用
    var desc: [String: Any] { get }
}

public struct HTTPRequest {

    private let deviceID: String

    let path: String
    let method: HTTPMethod
    let params: [String: Any]
    let query: [String: Any]
    let headers: [String: String]
    let domain: String?

    public init(
        path: String,
        method: HTTPMethod = .get,
        params: [String: Any] = [:],
        query: [String: Any] = [:],
        headers: [String: String] = [:],
        domain: String? = nil
    ) {
        self.path = path
        self.method = method
        self.params = params
        self.query = query
        self.headers = headers
        @Provider var service: DeviceService // Global
        self.deviceID = service.deviceId
        self.domain = domain
    }
}

extension HTTPRequest: Request {

    public var desc: [String: Any] {
        return ["path": path,
                "method": method.rawValue,
                "domain": domain ?? ""]
    }

    public func asURLRequest() throws -> URLRequest {
        let requestDomain: String? = self.domain ?? DomainSettingManager.shared.currentSetting[.securityCompliance]?.first
        guard let domain = requestDomain else {
            Logger.error("invalid domain with \(self)")
            throw LSCError.domainInvalid
        }
        var aPath = path
        if !aPath.hasPrefix("/") {
            aPath = "/" + aPath
        }
        let urlStr = schema + domain + pathSuffx + aPath
        let queryItems = self.query.map { value in
            return URLQueryItem(name: value.key, value: "\(value.value)")
        }
        var url = URLComponents(string: urlStr)
        if !queryItems.isEmpty {
            url?.queryItems = queryItems
        }
        guard let realURL = url?.url else { throw LSCError.domainInvalid }
        let aHeaders = addCommonHeaders(headers)
        var request = try URLRequest(url: realURL, method: method, headers: aHeaders)
        if !params.isEmpty {
            let data = try JSONSerialization.data(withJSONObject: params)
            request.httpBody = data
        }
        return request
    }

    private func addCommonHeaders(_ headers: [String: String]) -> [String: String] {
        // 添加共有 header
        var aHeaders = headers
        let version = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? ""
        aHeaders["content-type"] = "application/json"
        aHeaders["lark-version"] = version
        aHeaders["device-id"] = deviceID
        aHeaders["os"] = "ios"
        aHeaders["X-Device-Info"] = getXDeviceInfo()
        aHeaders["terminal_type"] = "4" // iOS terminal_type: 4

        return aHeaders
    }

    struct Const {
        static let deviceID: String = "device_id"
        static let deviceName: String = "device_name"
        static let deviceOS: String = "device_os"
        static let deviceModel: String = "device_model"
        static let larkVersion: String = "lark_version"
        static let rustVersion: String = "rust_version"
        static let packageName: String = "package_name"
        static let channel: String = "channel"
        static let afID: String = "af_id"
        static let ttAppID: String = "tt_app_id"
    }

    private func getXDeviceInfo() -> String {

        var deviceName: String = ""
        do {
            let token = Token("LARK-PSDA-initiate_httpRequest_request_deviceName")
            deviceName = try DeviceInfoEntry.getDeviceName(forToken: token, device: UIDevice.current)
        } catch {
            Logger.error(error.localizedDescription)
        }

        var deviceInfo = [
            Const.packageName: Utils.appName,
            Const.deviceID: deviceID,
            Const.deviceName: (deviceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? UIDevice.current.lu.modelName() : deviceName),
            Const.deviceOS: UIDevice.current.systemName + " " + UIDevice.current.systemVersion,
            Const.deviceModel: UIDevice.current.lu.modelName(),
            Const.larkVersion: Utils.appVersion,
            Const.channel: ReleaseConfig.appBrandName,
            Const.ttAppID: ReleaseConfig.appId
        ]
        #if DEBUG || BETA || ALPHA
        deviceInfo[Const.packageName] = ReleaseConfig.isLark ? "com.larksuite.lark" : "com.bytedance.ee.lark"
        #endif

        return deviceInfo.reduce("") { (res, kv) -> String in
            let (key, value) = kv
            return res + "\(key)=\(value.urlEncode);"
        }
    }
}

public extension String {
    var urlEncode: String {
        self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    }
}
