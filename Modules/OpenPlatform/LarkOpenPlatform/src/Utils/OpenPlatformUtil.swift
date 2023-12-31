//
//  OpenPlatformUtil.swift
//  Action
//
//  Created by tujinqiu on 2019/8/13.
//

import Foundation
import LarkModel
import Reachability
import CoreTelephony
import LarkFeatureGating
import Swinject
import LarkEnv
import RustPB
import LKCommonsLogging

private let logger = Logger.oplog(String.self, category: "OpenPlatformUtil")
class OpenPlatformUtil {
    static var netStatus: RustPB.Basic_V1_DynamicNetStatusResponse.NetStatus = .excellent

    static func getNetStatus() -> String {
        switch netStatus {
        case .excellent:
            return "excellent"
        case .evaluating:
            return "evaluating"
        case .weak:
            return "weak"
        case .netUnavailable:
            return "netUnavailable"
        case .serviceUnavailable:
            return "serviceUnavailable"
        case .offline:
            return "offline"
        @unknown default:
            return "evaluating"
        }
    }

    static func getNetworkType() -> String {
        guard let reach = Reachability() else { return "unkown" }
        if reach.connection == .wifi {
            return "wifi"
        } else if reach.connection == .cellular {
            switch CTTelephonyNetworkInfo.lu.shared.lu.currentSpecificStatus {
            case .📶2G:
                return "2G"
            case .📶3G:
                return "3G"
            case .📶4G:
                return "4G"
            case .📶5G:
                return "5G"
            default:
                break
            }
        }
        return "none"
    }

    static func getEnvType() -> Env.TypeEnum {
        return EnvManager.env.type
    }
}

extension String {
    func possibleURL() -> URL? {
        do {
            return try URL.forceCreateURL(string: self)
        } catch let error {
            logger.error("conver string: \(self.safeURL()) to url fail with error: \(error)")
            return nil
        }
    }

    func urlStringAddParameter(parameters: [String: String]) -> String {
        /// Lark的URL的扩展添加参数的方法存在问题，现在重新写一个
        var parameterStr = ""
        for (key, value) in parameters {
            if parameterStr.isEmpty {
                parameterStr = "\(key)=\(value)"
            } else {
                parameterStr += "&\(key)=\(value)"
            }
        }
        parameterStr = parameterStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? parameterStr
        if self.contains("?") || self.contains("&") {
            return (self + "&" + parameterStr)
        }
        return (self + "?" + parameterStr)
    }
}

extension UIImage {
    open class func imageWithColor(_ color: UIColor, opaque: Bool = true) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContextWithOptions(rect.size, opaque, 0)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img ?? UIImage()
    }
}

extension Optional {
    var logValue: String {
        switch self {
        case .none:
            return "<nil>"
        case let .some(value):
            return "\(value)"
        }
    }
}
