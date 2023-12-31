//
//  PerformanceTiming.swift
//  LarkWebViewContainer
//
//  Created by lijuyou on 2020/9/21.
//  

import Foundation

/// performance timing for LarkWebView
public extension LarkWebView {
    /// WebView性能监控数据
    /// - https://developer.mozilla.org/zh-CN/docs/Web/API/PerformanceTiming
    /// - https://www.w3.org/TR/navigation-timing-2/#processing-model
    struct PerformanceTiming: Codable {
        /// 准备加载页面的起始时间截。如果当前文档为空，则navigationStart的值等于fetchStart
        public let navigationStart: UInt64

        /// 如果前一个文档和当前文档同源,返回前一个文档开始unload的时间截
        public let unloadEventStart: UInt64

        /// 如果前一个文档和当前文档同源,返回前一个文档开始unload结束的时间截
        public let unloadEventEnd: UInt64

        /// 如果有重定向,这里是重定向开始的时间截
        public let redirectStart: UInt64

        /// 如果有重定向,这里是重定向结束的时间截
        public let redirectEnd: UInt64

        /// 开始检查缓存或开始获取资源的时间截
        public let fetchStart: UInt64

        /// 开始进行DNS查询的时间截
        public let domainLookupStart: UInt64

        /// DNS查询结束的时间截
        public let domainLookupEnd: UInt64

        /// 开始建立TCP连接请求资源的时间截
        public let connectStart: UInt64

        /// 建立连接TCP成功的时间截
        public let connectEnd: UInt64

        /// 如果是https请求.返回ssl握手的时间
        public let secureConnectionStart: UInt64

        /// 开始请求文档时间(包括从服务器,本地缓存请求)
        public let requestStart: UInt64

        /// HTTP开始接收响应的时间（获取到第一个字节），包括从本地读取缓存
        public let responseStart: UInt64

        /// HTTP 响应全部接收完成的时间（获取到最后一个字节），包括从本地读取缓存
        public let responseEnd: UInt64

        /// 开始解析渲染 DOM 树的时间，此时 Document.readyState 变为 loading，并将抛出 readystatechange 相关事件
        public let domLoading: UInt64

        /// 完成解析 DOM 树的时间，Document.readyState 变为 interactive，并将抛出 readystatechange 相关事件.（注意只是 DOM 树解析完成，这时候并没有开始加载网页内的资源）
        public let domInteractive: UInt64

        /// DOM 解析完成后，网页内资源加载开始的时间
        public let domContentLoadedEventStart: UInt64

        /// DOM 解析完成后，网页内资源加载完成的时间（如 JS 脚本加载执行完毕）
        public let domContentLoadedEventEnd: UInt64

        /// DOM 树解析完成，且资源也准备就绪的时间，Document.readyState 变为 complete，并将抛出 readystatechange 相关事件
        public let domComplete: UInt64

        /// 触发onload事件的时间
        public let loadEventStart: UInt64

        /// onload事件结束的时间
        public let loadEventEnd: UInt64

        /// DNS查询耗时
        public var dnsTime: Int64 {
            Int64(domainLookupEnd) - Int64(domainLookupStart)
        }

        /// TCP连接耗时
        public var tcpTime: Int64 {
            Int64(connectEnd) - Int64(connectStart)
        }

        /// 网络请求耗时,内容加载完成的时间
        public var requestTime: Int64 {
            Int64(responseEnd) - Int64(requestStart)
        }

        /// 解析DOM树耗时
        public var parseDomTime: Int64 {
            Int64(domComplete) - Int64(domInteractive)
        }

        /// 白屏时长
        public var blankTime: Int64 {
            Int64(domLoading) - Int64(fetchStart)
        }

        /// DOM Ready时长
        public var domReadyTime: Int64 {
            Int64(domContentLoadedEventEnd) - Int64(fetchStart)
        }

        /// 执行onLoad函数的时长
        public var onLoadTime: Int64 {
            Int64(loadEventEnd) - Int64(loadEventStart)
        }

        /// 页面加载完成(DOM+JS)的时长,代表了用户等待页面可用的时间
        public var pageLoadTime: Int64 {
            Int64(loadEventEnd) - Int64(fetchStart)
        }

        /// 重定向的时长
        public var redirectTime: Int64 {
            Int64(redirectEnd) - Int64(redirectStart)
        }

        // swiftlint:disable nesting
        enum CodingKeys: String, CodingKey {
            case navigationStart
            case unloadEventStart
            case unloadEventEnd
            case redirectStart
            case redirectEnd
            case fetchStart
            case domainLookupStart
            case domainLookupEnd
            case connectStart
            case connectEnd
            case secureConnectionStart
            case requestStart
            case responseStart
            case responseEnd
            case domLoading
            case domInteractive
            case domContentLoadedEventStart
            case domContentLoadedEventEnd
            case domComplete
            case loadEventStart
            case loadEventEnd
        }
        // swiftlint:enable nesting

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.navigationStart = try container.decodeIfPresent(type(of: navigationStart), forKey: .navigationStart) ?? 0
            self.unloadEventStart = try container.decodeIfPresent(type(of: unloadEventStart), forKey: .unloadEventStart) ?? 0
            self.unloadEventEnd = try container.decodeIfPresent(type(of: unloadEventEnd), forKey: .unloadEventEnd) ?? 0
            self.redirectStart = try container.decodeIfPresent(type(of: redirectStart), forKey: .redirectStart) ?? 0
            self.redirectEnd = try container.decodeIfPresent(type(of: redirectEnd), forKey: .redirectEnd) ?? 0
            self.fetchStart = try container.decodeIfPresent(type(of: fetchStart), forKey: .fetchStart) ?? 0
            self.domainLookupStart = try container.decodeIfPresent(type(of: domainLookupStart), forKey: .domainLookupStart) ?? 0
            self.domainLookupEnd = try container.decodeIfPresent(type(of: domainLookupEnd), forKey: .domainLookupEnd) ?? 0
            self.connectStart = try container.decodeIfPresent(type(of: connectStart), forKey: .connectStart) ?? 0
            self.connectEnd = try container.decodeIfPresent(type(of: connectEnd), forKey: .connectEnd) ?? 0
            self.secureConnectionStart = try container.decodeIfPresent(type(of: secureConnectionStart), forKey: .secureConnectionStart) ?? 0
            self.requestStart = try container.decodeIfPresent(type(of: requestStart), forKey: .requestStart) ?? 0
            self.responseStart = try container.decodeIfPresent(type(of: responseStart), forKey: .responseStart) ?? 0
            self.responseEnd = try container.decodeIfPresent(type(of: responseEnd), forKey: .responseEnd) ?? 0
            self.domLoading = try container.decodeIfPresent(type(of: domLoading), forKey: .domLoading) ?? 0
            self.domInteractive = try container.decodeIfPresent(type(of: domInteractive), forKey: .domInteractive) ?? 0
            self.domContentLoadedEventStart = try container.decodeIfPresent(type(of: domContentLoadedEventStart), forKey: .domContentLoadedEventStart) ?? 0
            self.domContentLoadedEventEnd = try container.decodeIfPresent(type(of: domContentLoadedEventEnd), forKey: .domContentLoadedEventEnd) ?? 0
            self.domComplete = try container.decodeIfPresent(type(of: domComplete), forKey: .domComplete) ?? 0
            self.loadEventStart = try container.decodeIfPresent(type(of: loadEventStart), forKey: .loadEventStart) ?? 0
            self.loadEventEnd = try container.decodeIfPresent(type(of: loadEventEnd), forKey: .loadEventEnd) ?? 0
        }
    }
}
