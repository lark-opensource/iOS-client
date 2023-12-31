//
//  DocsConfig.swift
//  SKCommon
//
//  Created by lijuyou on 2020/6/11.
//  

import Foundation
import SKUIKit
import SKInfra

public struct DocsConfig {
    public struct Domains {
        /**
         打开文档详情时动态拼接url，比如doc、sheet、mindnote，由主工程注入
         */
        public var userDomain: String!

        public var docsHomeDomain: String!
        /**
         带space的，，由主工程注入
         1、用于普通网络请求，比如请求我的空间-由我创建文件列表；
         2、RN注册用，key是apiPrefix
         */
        public var docsApiDomain: String!

        /**
         不带space的,内部域名，业务上暂时没有用到，由主工程注入
         */
        public var internalApiDomain: String!

        /**
         用于打开帮助文档等，由主工程注入
         */
        public var docsHelpDomain: String!
        /**
         长链域名，目前是bitable在用，由主工程注入
         */
        public var docsLongConDomain: [String]!

        /**
         当前套件域名，目前DocsSDK内部用于文档url合法性校验的兜底domain，
         不同KA租户，这个域名一二级域名都可能会变；
         如果是bytedance 国内，这个值是 "feishu.cn"，国外是“larksuite.com”
         */
        public var suiteMainDomain: String!

        /**
         Docs的主域名， 国内，这个值是 "feishu.cn"
         */
        public var docsMainDomain: String?

        /**
         gecko域名，由lark动态传入，KA用户的域名可能会变
         */
        public var docsFeResourceUrl: String?
        
        //mg下对应的文档api
        public var docsMgApi: [String: [String: String]]?
        //mg下对应的长链域名
        public var docsMgFrontier: [String: [String: [String]]]?
        //mg下文档api匹配正则
        public var docsMgGeoRegex: String?
        //mg下文档长链匹配正则
        public var docsMgBrandRegex: String?
        

        /// Drive 流式下载用的域名，由主工程注入
        public var docsDriveDomain: String?

        /// 飞书举报域名
        public var tnsReportDomain: [String]?
        
        /**
         Lark举报域名，由lark动态传入国内这个值是 "feishu.cn"，国外是“larksuite.com”
         */
        public var tnsLarkReportDomain: [String]?
        
        ///帮助中心域名
        public var helpCenterDomain: String?
        
        /// feishu举报域名
        public var suiteReportDomain: String?
        
        ///  服务台下发域名
        public var mpAppLinkDomain: String?

        public static func getADomains() -> Domains {
            return Domains()
        }
    }
    /// for all user agent and http headers
    public var infos = [String: String]()

    public var domains = Domains()
    public var envInfo: DomainConfig.EnvInfo!

    ///geckoConfig
    public let geckoConfig: GeckoInitConfig?
    public init(geckoConfig: GeckoInitConfig) {
        self.geckoConfig = geckoConfig

    }

    /// 从Lark传入，透传给RN 的appinfo的appkey, SaaS 环境为nil
    public var appKey: String?
}
