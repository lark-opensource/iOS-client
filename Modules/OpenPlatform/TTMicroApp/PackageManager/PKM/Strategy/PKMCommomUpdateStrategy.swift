//
//  PKMCommomUpdateStrategy.swift
//  TTMicroApp
//
//  Created by Nicholas Tau on 2023/2/2.
//

import Foundation
import OPSDK
import LarkOPInterface
import LKCommonsLogging

public enum PKMCommomUpdateStrategy: String {
    case async //正常异步请求meta. default值
    case syncTry // 满足syncTry策略
    case syncForce // 满足syncForce策略
}


struct PKMCommonStrategy: PKMMetaBuilderProtocol & PKMTriggerStrategyProtocol {
    
    static let logger = Logger.oplog(PKMCommonStrategy.self, category: "PKMCommonStrategy")

    let useLocalMeta: Bool

    let uniqueID: BDPUniqueID

    let expireStrategy: PKMCommomUpdateStrategy

    var loadType: TTMicroApp.PKMLoadType

    let metaProvider: MetaFromStringProtocol

    var pkgDownloadPriority: Float {
        switch loadType {
        case .normal:
            return URLSessionDataTask.highPriority
        default:
            return URLSessionDataTask.lowPriority
        }
    }

    var extra: [String : Any]?

    init(uniqueID: BDPUniqueID,
         loadType: TTMicroApp.PKMLoadType,
         useLocalMeta: Bool,
         expireStrategy: PKMCommomUpdateStrategy,
         metaProvider: MetaFromStringProtocol,
         extra: [String : Any]? = nil) {
        self.uniqueID = uniqueID
        self.loadType = loadType
        self.useLocalMeta = useLocalMeta
        self.expireStrategy = expireStrategy
        self.metaProvider = metaProvider
        self.extra = extra
    }

    func updateStrategy(_ context: TTMicroApp.PKMTriggerStrategyContext, beforeInvoke:(() ->())? = nil) -> TTMicroApp.PKMMetaUpdateStrategy {
        beforeInvoke?()
        // 如果本地没有meta信息,则直接走远程策略
        guard let _ = context.localMeta else {
            return .forceRemote
        }
        // 止血或者(批量的meta过期)走远程策略
        guard useLocalMeta else {
            return .forceRemote
        }
        // 根据过期类型决定使用哪种策略
        switch expireStrategy {
        case .async:
            return .useLocal
        case .syncTry:
            return .tryRemote
        default:
            return .forceRemote
        }
    }

    func copy() -> PKMTriggerStrategyProtocol {
        return PKMCommonStrategy(uniqueID: uniqueID, loadType: loadType, useLocalMeta: useLocalMeta, expireStrategy: expireStrategy, metaProvider: metaProvider)
    }

    func buildMeta(with json: String?) -> TTMicroApp.PKMBaseMetaProtocol? {
        guard let json = json else {
            Self.logger.warn("build pkm meta failed: jsonStr is nil")
            return nil
        }
        do {
            let metaOriginal = try metaProvider.buildMetaModel(with: json)
            return metaOriginal as? TTMicroApp.PKMBaseMetaProtocol
        } catch {
            Self.logger.warn("build pkm meta failed")
            return nil
        }
    }
}
