//
//  URLMapping.swift
//  LarkBaseService
//
//  Created by 李晨 on 2019/12/19.
//

import Foundation
import EENavigator
import LarkContainer
import LKCommonsLogging
import LarkFeatureGating
import OfflineResourceManager
import LarkDebug

/// check the URL has match dynamic pattern
public final class URLMapHandler: MiddlewareHandler {

    // 业务动态化配置表 [[regexStr: urlString]]
    static private(set) var urlMappers: [DynamicUrlMapper] = []
    private static var debugMappersBackUp: [DynamicUrlMapper]?
    static let dynamicUrlMapKey = "dynamic_url_mapper"
    static let dynamicDowngradeStrategyKey = "dynamic_ds"
    static let dyanmciBizNameKey = "dynamic_bn"
    static let log = LKCommonsLogging.Logger.log(URLMapHandler.self, category: "Lark.URLMapHandler")

    struct DynamicUrlMapper: Codable {
        let pattern: String
        let dynamicUrlInfo: DynamicUrlInfo

        // swiftlint:disable nesting
        enum CodingKeys: String, CodingKey {
            case pattern
            case dynamicUrlInfo = "url"
        }
        // swiftlint:enable nesting
    }

    struct DynamicUrlInfo: Codable {
        let newUrl: String
        let accessKey: String
        let bizName: String
        let channel: String
        let forceApply: Bool?

        // swiftlint:disable nesting
        enum CodingKeys: String, CodingKey {
            case newUrl
            case accessKey
            case bizName
            case channel
            case forceApply
        }
        // swiftlint:enable nesting
    }

    // swiftlint:disable function_body_length
    public func handle(req: EENavigator.Request, res: Response) {
        guard !URLMapHandler.urlMappers.isEmpty else {
            URLMapHandler.log.debug("urlMappers isEmpty")
            return
        }

        URLMapHandler.log.debug(
            "URLMapHandler handle",
            additionalData: ["self.urlMappers": "\(URLMapHandler.urlMappers)"]
        )

        // get current enviroment
        let mapper: DynamicUrlMapper? = URLMapHandler.urlMappers.first(where: {
            self.isMapPattern(urlStr: req.url.absoluteString, pattern: $0.pattern)
        })

        let reqUrl = req.url
        if let mapper = mapper {
            let newUrlString = mapper.dynamicUrlInfo.newUrl
            URLMapHandler.log.debug(
                "URLMapHandler mapper = \(mapper), req.url.absoluteString = \(reqUrl.absoluteString)"
            )

            /// 正则pattern
            let regexPattern = mapper.pattern

            let range = NSRange(location: 0, length: reqUrl.absoluteString.count)
            guard let regExp = try? NSRegularExpression(pattern: regexPattern) else {
                URLMapHandler.log.error("URLMapHandler Cann't parse [\(regexPattern)] into regular expression")
                return
            }
            guard let match = regExp.firstMatch(in: reqUrl.absoluteString, range: range) else {
                URLMapHandler.log.error("URLMapHandler Cann't match [\(reqUrl.absoluteString)] regular [\(regExp)]")
                return
            }

            var handledUrlString = newUrlString
            for idx in 1..<match.numberOfRanges {
                if let param = NSString(string: reqUrl.absoluteString)
                    .substring(with: match.range(at: idx))
                    .removingPercentEncoding {
                        handledUrlString = handledUrlString.replacingOccurrences(of: "{\(idx)}", with: param)
                        URLMapHandler.log.debug(
                            "URLMapHandler match param = \(param), handledUrlString = \(handledUrlString)"
                        )
                    }
                }

            guard let handledUrl = URL(string: handledUrlString) else {
                URLMapHandler.log.error(
                    "URLMapHandler handledUrlString convert to URL failed",
                    additionalData: ["handledUrlString": handledUrlString]
                )
                return
            }
            /// merge queryParameters of reqUrl, not force
            let newUrl = handledUrl.append(parameters: reqUrl.queryParameters, forceNew: false)
            if newUrl.queryParameters.keys.contains(URLMapHandler.dynamicDowngradeStrategyKey),
                let bizName = newUrl.queryParameters[URLMapHandler.dyanmciBizNameKey],
                OfflineResourceManager.getResourceStatus(byId: bizName) != .ready {
                // downgrade strategy: when use offline resource, if resource is not ready, use native
            } else {
                res.redirect(newUrl)
            }

            URLMapHandler.log.debug("URLMapHandler router redirect",
                                    additionalData: ["newUrl": "\(newUrl)",
                                        "queryParameters": "\(reqUrl.queryParameters)",
                                        "handledUrlString": handledUrlString])

        } else {
            URLMapHandler.log.debug("URLMapHandler mapper is nil!")
        }
    }
    // swiftlint:enable function_body_length

    func isMapPattern(urlStr: String, pattern: String) -> Bool {
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        let isRexVailed = predicate.evaluate(with: urlStr)
        URLMapHandler.log.debug(
            "URLMapHandler isMapPattern",
            additionalData: [
                "pattern regex": pattern,
                "isRexVailed": "\(isRexVailed)"
            ]
        )
        return isRexVailed
    }

    static func getDynamicURLMappers(settingDic: [String: String]) -> [DynamicUrlMapper]? {
        let mapperFGOn = true

        if let dynamicInfoDict = settingDic[URLMapHandler.dynamicUrlMapKey],
            let data = dynamicInfoDict.data(using: .utf8) {
            do {
                let decoder = JSONDecoder()
                guard let dynamicUrlMappersDict = try decoder.decode([String: [DynamicUrlMapper]]?.self, from: data),
                    let dynamicUrlMappers = dynamicUrlMappersDict[URLMapHandler.dynamicUrlMapKey] else {
                        return nil
                }

                URLMapHandler.urlMappers = dynamicUrlMappers.filter { (mapper) -> Bool in
                    let forceApply = mapper.dynamicUrlInfo.forceApply ?? false
                    return mapperFGOn || forceApply
                }

                let debugInfo = self.getDynamicDebugInfo(dynamicUrlMappers: dynamicUrlMappers)
                URLMapHandler.log.debug(
                    "DynamicUrlMapper get encodedUrlMappers",
                    additionalData: ["debugInfo": debugInfo]
                )
                return URLMapHandler.urlMappers
            } catch {
                URLMapHandler.log.error("DynamicUrlMapper decode failed", error: error)
                return nil
            }
        } else {
            URLMapHandler.log.debug("can not get dynamic url data)")
            return nil
        }
    }

    /// debug log
    static func getDynamicDebugInfo(dynamicUrlMappers: [DynamicUrlMapper]) -> String {
        var debugBizNames = ""
        dynamicUrlMappers.forEach {
            debugBizNames += "bizName=\($0.dynamicUrlInfo.bizName),"
        }
        return debugBizNames
    }
}
// MARK: - support debug
extension URLMapHandler {
    class func debugSettingsDisable(_ disable: Bool) {
        if appCanDebug() {
            if disable {
                URLMapHandler.log.debug("debug switch disable mappers \(URLMapHandler.urlMappers)")
                URLMapHandler.debugMappersBackUp = URLMapHandler.urlMappers
                URLMapHandler.urlMappers = []
            } else {
                // check empty in case urlMappers is updated after switch account
                if URLMapHandler.urlMappers.isEmpty, let mappers = URLMapHandler.debugMappersBackUp {
                    URLMapHandler.log.debug("debug switch enable mappers \(mappers)")
                    URLMapHandler.urlMappers = mappers
                }
            }
        }
    }
}
