//
//  OPAppMetaBuilder.swift
//  OPSDK
//
//  Created by lixiaorui on 2020/11/12.
//

import Foundation
import LarkOPInterface
import OPFoundation

fileprivate extension OPAppType {
    /// 后端对应的type字段: 目前webapp没有对应的type
    var extensionType: String {
        switch self {
        case .unknown, .sdkMsgCard:
            return "unknown"
        //webApp默认在服务端的数据扩展类型为 webapp
        //https://bytedance.feishu.cn/wiki/wikcnzaVrtpMIIt8ofVgef9hTFf#doxcnAkGW8IOes0gukLYN6p6hlg
        case .webApp:
            return "webapp"
        case .block:
            return "block"
        case .widget:
            return "widget"
        case .gadget:
            return "mobile_mini"
        case .thirdNativeApp:
            return "third_native_app"
        case .dynamicComponent:
            return "dynamic_component"
        }
    }
}

/// Meta相关构造器，一种类型会对应一个构造器
public protocol OPAppMetaBuilder: AnyObject {

    /// 从string数据生成meta：目前用于从db数据
    /// - Parameter jsonStr: 生成meta的源字符串
    func buildFromJson(_ jsonStr: String) throws -> OPBizMetaProtocol

    /// 从data数据返回data生成meta：目前用于网络请求meta接口返回
    /// - Parameter data: 生成meta的源数据
    /// - Parameter uniqueID: 请求meta所用的uniqueID
    func buildFromData(_ data: Data, uniqueID: OPAppUniqueID) throws -> OPBizMetaProtocol

}

extension OPAppMetaBuilder {

    /// 解析后端返回response
    /// - Parameters:
    ///   - data: 后端response data
    ///   - uniqueID: 请求的uniqueID
    public func deserializeResponse(with data: Data, uniqueID: OPAppUniqueID) throws -> (OPAppBaseInfo, OPAppExtensionMeta) {
        do {
            let metaResponse = try JSONDecoder().decode(OPAppMetaResponse.self, from: data)
            guard metaResponse.code == 0 else {
                // meta 返回业务错误码
                throw OPError.error(monitorCode: OPSDKMonitorCodeLoader.get_meta_biz_error, userInfo: ["code": metaResponse.code, "msg": metaResponse.msg])
            }
            guard let data = metaResponse.data else {
                throw OPError.error(monitorCode: OPSDKMonitorCodeLoader.get_data_from_response_failed, message: "can not get data from response for app \(uniqueID)")
            }
            guard let appMetas = data.appMetas, let metaInfo = appMetas.first(where: { $0.appBaseInfo.appID == uniqueID.appID }) else {
                throw OPError.error(monitorCode: OPSDKMonitorCodeLoader.get_meta_info_from_data_failed, message: "can not get metaInfo from data for app \(uniqueID)")
            }
            guard let extensionMeta = metaInfo.extensionMetas.first(where: { $0.extensionID == uniqueID.identifier && $0.extensionType == uniqueID.appType.extensionType }) else {
                throw OPError.error(monitorCode: OPSDKMonitorCodeLoader.get_extension_meta_from_data_failed, message: "can not get extensionMeta from data for app \(uniqueID)")
            }
            return (metaInfo.appBaseInfo, extensionMeta)
        } catch {
            throw error
        }
    }

    /// 获取拉meta的request
    /// - Parameter uniqueID: 需要拉取meta的ID
    /// - Throws: 无法组装url时会抛出异常
    /// - Returns: 组装好的拉取meta的request
    public func generateMetaRequest(_ uniqueID: OPAppUniqueID, previewToken: String?) throws -> URLRequest {
        guard let metaURL = URL.opURL(domain: OPApplicationService.current.domainConfig.openDomain,
                                path: String.OPNetwork.OPPath.minaPath,
                                resource: String.OPNetwork.OPInterface.meta) else {
            throw OPError.error(monitorCode: OPSDKMonitorCodeLoader.get_meta_url_failed, message: "can not get metaURL for app \(uniqueID)")
        }
        var headers: [String: String] = [:]
        headers["Cookie"] = "session=\(OPApplicationService.current.accountConfig.userSession)"
        headers["Content-Type"] = "application/json"
        
        var params: [String: Any] = [:]
        params["lark_version"] = "\(OPApplicationService.current.envConfig.larkVersion)"
        params["lang"] = "\(OPApplicationService.current.envConfig.language)"
        
        var application = ["app_id": uniqueID.appID,
                           "extension_id": uniqueID.identifier,
                           "extension_type": uniqueID.appType.extensionType]
        if let token = previewToken, !token.isEmpty {
            application["preview_token"] = token
        }
        var appID = uniqueID.appID
        //如果是动态组件，需要添加依赖的应用版本
        if uniqueID.appType == .dynamicComponent {
            //如果是动态组件，外层传递的应该是宿主ID
            guard let hostID = uniqueID.instanceID else {
                throw OPError.error(monitorCode: OPSDKMonitorCodeLoader.get_meta_url_failed, message: "uniqueID:\(uniqueID)'s instanceID can't be nil")
            }
            appID = hostID
            application["app_version"] = uniqueID.requireVersion
        }
        params["app_queries"] = [["app_id": appID, "extension_queries":[application]]]
        var request = OPURLSessionTaskConfigration(identifier: uniqueID.description,
                                            url: metaURL,
                                            method: .post,
                                            headers: NSDictionary(dictionary: headers),
                                            params: NSDictionary(dictionary: params)).urlRequest
        request.cachePolicy = .reloadIgnoringCacheData
        request.timeoutInterval = 15.0
        return request
    }
}
