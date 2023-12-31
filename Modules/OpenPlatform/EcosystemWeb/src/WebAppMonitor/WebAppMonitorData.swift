//
//  WebAppMonitorData.swift
//  EcosystemWeb
//
//  Created by dengbo on 2022/3/14.
//

import Foundation
import LKCommonsLogging

public struct LKWEventNativeBase: Codable {
    let navigationId: String?
    
    enum CodingKeys: String, CodingKey {
        case navigationId = "navigation_id"
    }
}

public struct LKWEventJSBase: Codable {
    let urlString: String?
    
    enum CodingKeys: String, CodingKey {
        case urlString = "url"
    }
}

public struct LKWEventException: Codable {
    let name: String?
    let message: String?
    let stack: String?
}

public struct LKWEventJSInfo: Codable {
    let tti: Int?
    let fmp: Int?
    
    let exception: LKWEventException?
}


public struct WebAppMonitorData: Codable {
    
    static let logger = Logger.lkwlog(WebAppMonitorData.self, category: "WebAppMonitorData")

    public let serviceType: String?
    public let nativeBase: LKWEventNativeBase?
    public let jsBase: LKWEventJSBase?
    public let jsInfo: LKWEventJSInfo?
    
    var urlWithoutQuery: String? {
        return jsBase?.urlString?.urlWithoutQuery()
    }
    
    public static func parseData(data: [AnyHashable: Any]) -> WebAppMonitorData? {
        guard JSONSerialization.isValidJSONObject(data) else {
            Self.logger.error("data is invalid")
            return nil
        }
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            let eventData = try JSONDecoder().decode(WebAppMonitorData.self, from: jsonData)
            Self.logger.info("parse data: \(eventData.toString())")
            return eventData
        } catch {
            Self.logger.error("parse data error: ", error: error)
            return nil
        }
    }
    
    private func toString() -> String {
        return """
            ParsedEventData(
            serviceType:\(serviceType ?? "nil"),
            navigationId:\(nativeBase?.navigationId ?? "nil"),
            url:\(urlWithoutQuery ?? "nil"),
            fmp:\(jsInfo?.fmp ?? 0),
            tti:\(jsInfo?.tti ?? 0)
        """
    }
}


extension String {
    func urlWithoutQuery() -> String? {
        guard let url = URL(string: self),
              var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                  return nil
              }
        
        // 移除query，只上报scheme + host + path + fragment
        urlComponents.query = nil
        return urlComponents.url?.absoluteString
    }
}
