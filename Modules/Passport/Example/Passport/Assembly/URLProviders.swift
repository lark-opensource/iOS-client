//
//  URLProviders.swift
//  LarkAccountDev
//
//  Created by Miaoqi Wang on 2021/3/29.
//

import Foundation
import LarkAccountInterface
import LarkEnv

class NativeStaticURLProvider: URLProviderProtocol {
    func getUrl(_ key: URLKey) -> URLValue {
        let url: String?
        switch key {
        case .api:
            switch EnvManager.env.type {
            case .staging:
                switch EnvManager.env.unit {
                case Unit.BOECN:
                    url = "https://internal-api-lark-api.feishu-boe.cn/"
                case Unit.BOEVA:
                    url = "https://internal-api-lark-api.larksuite-boe.com/"
                default:
                    url = nil
                }
            case .preRelease:
                switch EnvManager.env.unit {
                case Unit.NC:
                    url = "https://internal-api-lark-api.feishu-pre.cn/"
                case Unit.EA:
                    url = "https://internal-api-lark-api.larksuite-pre.com/"
                default:
                    url = nil
                }
            case .release:
                switch EnvManager.env.unit {
                case Unit.NC:
                    url = "https://internal-api-lark-api.feishu.cn/"
                case Unit.EA:
                    url = "https://internal-api-lark-api.larksuite.com/"
                default:
                    url = nil
                }
            default:
                url = nil
            }

        default:
            url = nil
        }
        return .init(value: url, provider: .runtimeInjectConfig)
    }
}

class NativeStaticDomainProvider: DomainProviderProtocol {

    func getDomain(_ key: DomainAliasKey) -> DomainValue {
        let domain: String?
        switch key {
        case .ttApplog:
            switch EnvManager.env.type {
            case .staging:
                switch EnvManager.env.unit {
                case Unit.BOECN:
                    domain = "boe.i.snssdk.com"
                case Unit.BOEVA:
                    domain = "boe.i.snssdk.com"
                default:
                    domain = nil
                }
            case .preRelease:
                switch EnvManager.env.unit {
                case Unit.NC:
                    domain = "toblog.ctobsnssdk.com"
                case Unit.EA:
                    domain = "toblog.ctobsnssdk.com"
                default:
                    domain = nil
                }
            case .release:
                switch EnvManager.env.unit {
                case Unit.NC:
                    domain = "toblog.ctobsnssdk.com"
                case Unit.EA:
                    domain = "toblog.ctobsnssdk.com"
                default:
                    domain = nil
                }
            default:
                domain = nil
            }
        default:
            domain = nil
        }
        return .init(value: domain, provider: .runtimeInjectConfig)
    }

}
