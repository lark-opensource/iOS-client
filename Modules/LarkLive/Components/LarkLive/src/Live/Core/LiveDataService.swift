//
//  LiveDataService.swift
//  ByteView
//
//  Created by tuwenbo on 2021/1/17.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import LKCommonsLogging

class LiveDataService {
    static let logger = LKCommonsLogging.Logger.log(LiveDataService.self, category: "larkLive")

    private var liveSettings: NewLarkLiveSettings?

    public init() {
    }

    public func setup() {
        Logger.live.info("LiveDataService setup")
        fetchSettings()
    }

    private func fetchSettings() {
        Logger.live.info("LiveDataService Fetching live settings")
        ConfigRequestor.requestSettings(.liveSettings, type: NewLarkLiveSettings.self) { [weak self] (r) in
            switch r {
            case .success(let settings):
                self?.liveSettings = settings
                Self.logger.info("LiveDataService Live settings: \(settings)")
            case .failure(let error):
                Self.logger.info("LiveDataService Live settings fetch error: \(error)")
            }
        }
    }

    private func preCheckCondition() -> Bool {
        if !(self.liveSettings?.liveNative ?? false) {
            Self.logger.info("LiveDataService live native false")
            return false
        }

        if Display.pad {
            Self.logger.info("LiveDataService pad")
            return false
        }
        
        return true
    }

    public func verifyURL(url: URL?) -> Bool {
        /// IM中的点击直播链接埋点不需要precheck
        if preCheckCondition() == false {
            Self.logger.info("LiveDataService pre check false")
            return false
        }

        guard let url = url else {
            Self.logger.info("LiveDataService live url is nil")
            return false
        }

        // 优先检查是否有全链接匹配的情况
        if let liveUrls = self.liveSettings?.liveUrls {
            if liveUrls.contains(url.absoluteString) {
                Self.logger.info("LiveDataService match liveUrls")
                return true
            }
        }

        var isFeishuHost: Bool = false
        if let hosts = self.liveSettings?.liveHosts {
            if let host = url.host, hosts.contains(host) {
                isFeishuHost = true
            }
        }
        
        if isFeishuHost {
            Self.logger.info("is feishu host, old check")

            // 飞书走老的判断
            let path = url.path

            for pattern in self.liveSettings?.livePaths ?? [] {
                guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
                    Self.logger.info("LiveDataService livePaths not match")
                    return false
                }
                let range = NSRange(location: 0, length: path.count)
                guard regex.matches(in: path, range: range).first != nil else {
                    continue
                }
                Self.logger.info("LiveDataService livePaths matched")
                return true
            }

            return false
        } else {
            Self.logger.info("is not feishu host, new check")
            
            var hosts: [String] = []
            
            let currentUrlHost = url.host
            let currentUrlPath = url.path
            var currentUrlRule: NewLarkLiveRule?
            
            if let liveHostRules = liveSettings?.liveHostRules {
                for rule in liveHostRules {
                    hosts.append(rule.host)
                    if rule.host == currentUrlHost {
                        currentUrlRule = rule
                    }
                }
            }
            guard let host = url.host, hosts.contains(host) else {
                Self.logger.info("LiveDataService liveHost failed")
                return false
            }
            
            guard let regexes = currentUrlRule?.paths else {
                Self.logger.info("LiveDataService livePaths failed")
                return false
            }
            Self.logger.info("LiveDataService livePaths regexes: \(regexes)")
            for pattern in regexes {
                if let regexExpression = try? NSRegularExpression(pattern: pattern, options: [])  {
                    let range = NSRange(location: 0, length: currentUrlPath.count)
                    if regexExpression.matches(in: currentUrlPath, range: range).first != nil {
                        Self.logger.info("LiveDataService livePaths matched")
                        return true
                    }
                }
            }
            Self.logger.info("LiveDataService livePaths failed match")
            return false
        }
    }
}
