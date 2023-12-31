//
//  RouterMatch.swift
//  Calendar
//
//  Created by huoyunjie on 2023/4/18.
//

import Foundation
import LarkReleaseConfig
import LarkSetting

/*
 var urlComponents = URLComponents()
 urlComponents.scheme = "https"
 urlComponents.host = "www.example.com"
 urlComponents.path = "/path/to/resource"
 urlComponents.queryItems = [
     URLQueryItem(name: "id", value: "123")
 ]

 上述构造的 URL 为: https://www.example.com/path/to/resource?id=123
 */
struct RouterMatchConfig {
    /// 是否进行主机（域名）匹配，不区分大小写
    var matchHost: Bool = true
    /// 路径：区分大小写，nil 表示不参与匹配
    var path: String?
    /// schema：不区分大小写，nil 表示不参与匹配
    var schema: String? = "https"
    /// 端口，nil 表示不参与匹配
    var port: Int?
    /// 查询参数：区分大小写，nil 表示不参与匹配
    var queryItems: [String]?
}

class RouterMatch {

    /// 域名，例如 ['feishu.cn', 'feishu-pre.cn', 'larksuite.com', 'larksuite-pre.com']
    private var domains: [String] {
        if ReleaseConfig.isPrivateKA {
            // 私有化部署
            let domainSetting = DomainSettingManager.shared.currentSetting
            return domainSetting[DomainKey.suiteMainDomain] ?? []
        } else {
            // saas
            @LarkSetting.Setting(key: UserSettingKey.make(userKeyLiteral: "saas_suite_main_domain"))
            var saasDomains: [String]?
            return saasDomains ?? []
        }
    }

    private lazy var domainREs: [NSRegularExpression] = {
        domains.compactMap({ domain in
            let pattern = "(^|\\.)\(domain.replacingOccurrences(of: ".", with: "\\."))$"
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
                return regex
            } catch {
                assertionFailure("Invalid regular expression: \(error.localizedDescription)")
                return nil
            }
        })
    }()

    private var blackDomains: [String] {
        @LarkSetting.Setting(key: UserSettingKey.make(userKeyLiteral: "cal_biz_domain_interception_black_list"))
        var domains: [String]?
        return domains ?? []
    }

    private let config: RouterMatchConfig

    init(config: RouterMatchConfig) {
        self.config = config
    }

    func match(url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return false }

        let schema = components.scheme
        let host = components.host
        let path = components.path
        let port = components.port
        let queryItems = (components.queryItems ?? []).map(\.name)

        return matchSchema(schema) && matchHost(host) && matchPort(port) && matchPath(path) && matchQueryItems(queryItems)
    }

    /// 匹配域名
    private func matchHost(_ host: String?) -> Bool {
        guard self.config.matchHost else { return true }
        guard let host = host else { return false }

        let range = NSRange(location: 0, length: host.utf16.count)
        return !blackDomains.contains(where: { host.hasSuffix($0) }) &&
        domainREs.contains(where: { regex in
            !regex.matches(in: host, range: range).isEmpty
        })
    }

    /// 匹配 schema
    private func matchSchema(_ schema: String?) -> Bool {
        guard let matchedSchema = self.config.schema else { return true }
        guard let schema = schema else { return false }

        do {
            let regex = try NSRegularExpression(pattern: matchedSchema, options: [.caseInsensitive])
            return !regex.matches(in: schema, range: NSRange(location: 0, length: schema.utf16.count)).isEmpty
        } catch {
            assertionFailure("Invalid regular expression: \(error.localizedDescription)")
            return true
        }
    }

    /// 匹配 path
    private func matchPath(_ path: String?) -> Bool {
        guard let matchedPath = self.config.path else { return true }
        guard let path = path else { return false }

        return path == matchedPath
    }

    /// 匹配 port
    private func matchPort(_ port: Int?) -> Bool {
        guard let matchedPort = self.config.port else { return true }
        guard let port = port else { return false }
        return matchedPort == port
    }

    /// 匹配 queryItems
    private func matchQueryItems(_ queryItems: [String]?) -> Bool {
        guard let matchedQueryItems = self.config.queryItems else { return true }
        guard let queryItems = queryItems else { return false }
        return Set(matchedQueryItems).isSubset(of: Set(queryItems))
    }

}
