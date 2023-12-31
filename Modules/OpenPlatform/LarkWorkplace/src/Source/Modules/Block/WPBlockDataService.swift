//
//  WPBlockDataService.swift
//  LarkWorkplace
//
//  Created by Jiayun Huang on 2022/8/10.
//

import Foundation
import LKCommonsLogging
import LarkContainer
import SwiftyJSON
import RxSwift
import OPSDK
import OPBlock
import Blockit
import OPBlockInterface
import OPFoundation

protocol WPBlockDataService: AnyObject {

    func update(with blockData: [String: WPBlockPrefetchData]?)

    func update(with blockUnqueIds: [OPAppUniqueID]?)

    func getPrefetchData() -> [String: WPBlockPrefetchData]?

    func getBlockUniqueIds() -> [OPAppUniqueID]?

    func getBlockInfo(
        blockIds: [String],
        blockTypeIds: [String],
        blockTypeInfoDic: [String: BlockModel],
        portalType: WPPortal.PortalType,
        templateId: String?
    ) -> Single<[String: WPBlockPrefetchData]?>

    func preloadMetaPkg()
}

final class WPBlockDataServiceImpl: WPBlockDataService {
    struct WPRequestContext {
        let logId: String?
    }

    static let logger = Logger.log(WPBlockDataService.self)

    let traceService: WPTraceService
    private let blockService: BlockitService
    private let networkService: WPNetworkService

    private var blockPrefetchData: [String: WPBlockPrefetchData]?

    private var blockUniqueIds: [OPAppUniqueID]?

    private let queue = DispatchQueue(label: "com.workplace.WPBlockDataService")

    init(
        traceService: WPTraceService,
        blockService: BlockitService,
        networkService: WPNetworkService
    ) {
        self.traceService = traceService
        self.blockService = blockService
        self.networkService = networkService
    }

    func update(with prefetchData: [String: WPBlockPrefetchData]?) {
        blockPrefetchData = prefetchData
    }

    func update(with blockUniqueIds: [OPAppUniqueID]?) {
        self.blockUniqueIds = blockUniqueIds
    }

    func getPrefetchData() -> [String: WPBlockPrefetchData]? {
        return blockPrefetchData
    }

    func getBlockUniqueIds() -> [OPAppUniqueID]? {
        return blockUniqueIds
    }

    // swiftlint:disable closure_body_length
    /// Block接口合并
    func getBlockInfo(
        blockIds: [String],
        blockTypeIds: [String],
        blockTypeInfoDic: [String: BlockModel],
        portalType: WPPortal.PortalType,
        templateId: String?
    ) -> Single<[String: WPBlockPrefetchData]?> {
        let trace = traceService.lazyGetTrace(for: portalType, with: templateId)
        return fetchBlockInfo(
            blockIds: blockIds,
            blockTypeIds: blockTypeIds,
            portalType: portalType,
            templateId: templateId
        ).flatMap({ [weak self] (response, requestContext) -> Single<[String: WPBlockPrefetchData]?> in
            guard let `self` = self else {
                let error = WorkplaceError(
                    code: WPTemplateErrorCode.GetTemplateBlock.nil_self.rawValue,
                    originError: nil
                )
                throw error
            }

            var blockTypeIdToBlockIdMap: [String: String] = [:]
            var blockPrefetchDataMap: [String: WPBlockPrefetchData] = [:]
            // 解析 BlockEntity
            // key: blockID
            let entityMap = self.parseBlockEntity(
                entityPrefetch: response.entity,
                trace: trace,
                requestContext: requestContext
            )

            // 解析 GuideInfo
            // key: blockTypeID
            let guideInfoMap = self.parseBlockGuideInfo(
                guideInfoPrefetch: response.guideInfo,
                trace: trace,
                requestContext: requestContext
            )

            if entityMap.isEmpty && guideInfoMap.isEmpty {
                let error = WorkplaceError(
                    code: WPTemplateErrorCode.GetTemplateBlock.empty_entity_and_guide_info.rawValue,
                    originError: nil
                )
                throw error
            }

            // blockTypeId -> blockId
            // 获取 blockTypeID 对应的 blockEntity，转换成[blockID: WPBlockPrefetchData]
            for (blockTypeId, blockModel) in blockTypeInfoDic {
                blockTypeIdToBlockIdMap[blockTypeId] = blockModel.blockId
                let blockInfo = OPBlockInfo(
                    blockID: blockModel.blockId,
                    blockTypeID: blockModel.uniqueId.identifier,
                    sourceData: blockModel.sourceData ?? [:]
                )
                var prefetchData = WPBlockPrefetchData()
                prefetchData.blockEntity = blockInfo
                blockPrefetchDataMap[blockModel.blockId] = prefetchData
            }
            // 聚合数据
            for (blockId, blockInfo) in entityMap {
                var prefetchData = WPBlockPrefetchData()
                prefetchData.blockEntity = blockInfo
                blockPrefetchDataMap[blockId] = prefetchData
                blockTypeIdToBlockIdMap[blockInfo.blockTypeID] = blockId
            }

            for (blockTypeId, guideInfo) in guideInfoMap {
                guard let blockId = blockTypeIdToBlockIdMap[blockTypeId] else {
                    Self.logger.warn("blockTypeId does not match any blockId", additionalData: [
                        "blockTypeId": "\(blockTypeId)"
                    ])
                    continue
                }
                var prefetchData = blockPrefetchDataMap[blockId] ?? WPBlockPrefetchData()
                prefetchData.blockGuideInfo = guideInfo
                blockPrefetchDataMap[blockId] = prefetchData
            }

            return .just(blockPrefetchDataMap)
        })
    }

    private func fetchBlockInfo(
        blockIds: [String],
        blockTypeIds: [String],
        portalType: WPPortal.PortalType,
        templateId: String?
    ) -> Single<(WPBlockPrefetchResponse, WPRequestContext)> {
        Self.logger.info("start fetch block data")
        let trace = traceService.lazyGetTrace(for: portalType, with: templateId)
        let context = WPNetworkContext(injectInfo: .cookie, trace: trace)
        let params: [String: Any] = [
            "lark_version": WPUtils.appVersion,
            "lang": WorkplaceTool.curLanguage(),
            "block_type_ids": blockTypeIds,
            "block_ids": blockIds,
            "host": "workplace"
        ]
        return networkService.request(
            WPGetBlockInfoConfig.self,
            params: params,
            context: context
        )
        .observeOn(ConcurrentDispatchQueueScheduler(queue: self.queue))
        .catchError({ error -> Single<JSON> in  // 网络库错误
            let nsError = error as NSError
            let workplaceError = WorkplaceError(
                code: WPTemplateErrorCode.server_error.rawValue, originError: nsError
            )
            let logId = nsError.userInfo[WPNetworkConstants.logId] as? String
            throw workplaceError
        })
        .flatMap({ json -> Single<(WPBlockPrefetchResponse, WPRequestContext)> in
            let logId = json[WPNetworkConstants.logId].string
            do {
                let data = try json.rawData()
                let resp = try JSONDecoder().decode(WPBlockPrefetchResponseWrap.self, from: data)
                if resp.data.entity == nil && resp.data.guideInfo == nil {
                    let error = WorkplaceError(
                        code: WPTemplateErrorCode.GetTemplateBlock.empty_entity_and_guide_info.rawValue,
                        originError: nil
                    )
                    throw error
                }
                return .just((resp.data, WPRequestContext(logId: logId)))
            } catch {
                let workplaceError = WorkplaceError(
                    code: WPTemplateErrorCode.GetTemplateBlock.parse_entity_fail.rawValue,
                    originError: nil
                )
                throw workplaceError
            }
        })
    }
    // swiftlint:enable closure_body_length

    private func parseBlockEntity(
        entityPrefetch: WPBlockEntityPrefetch?,
        trace: OPTraceProtocol?,
        requestContext: WPRequestContext
    ) -> [String: OPBlockInfo] {
        Self.logger.info("start parse block entity")
        var entityMap: [String: OPBlockInfo] = [:]
        guard let entityPrefetchData = entityPrefetch else {
            // 没有entity的情况属于正常情况，比如工作台只有标准组件，就不会请求GetBlockEntity
            Self.logger.info("no block entity to parse")
            return entityMap
        }
        guard entityPrefetchData.code == 0,
              let blocks = entityPrefetchData.blocks,
              !blocks.isEmpty else {
                  return entityMap
              }

        for (blockId, entityResp) in blocks {
            guard entityResp.status == 0,
                  let entity = entityResp.entity else {
                      Self.logger.error("parse entity item fail", additionalData: [
                        "status": "\(entityResp.status)",
                        "hasEntity": "\(entityResp.entity != nil)"
                      ])
                      continue
                  }
            entityMap[blockId] = BlockInfo(
                blockID: entity.blockID,
                blockTypeID: entity.blockTypeID,
                sourceLink: entity.sourceLink,
                sourceData: entity.sourceData,
                sourceMeta: entity.sourceMeta,
                i18nPreview: entity.preview,
                i18nSummary: entity.summary
            ).toOPInfo()
        }
        return entityMap
    }

    private func parseBlockGuideInfo(
        guideInfoPrefetch: WPBlockGuideInfoPrefetch?,
        trace: OPTraceProtocol?,
        requestContext: WPRequestContext
    ) -> [String: OPBlockGuideInfo] {
        Self.logger.info("start parse block guide info")
        let guideInfoMap: [String: OPBlockGuideInfo] = [:]
        guard let guideInfoPrefetchData = guideInfoPrefetch else {
            Self.logger.error("parse block guide info fail, no guide info")
            return guideInfoMap
        }

        guard guideInfoPrefetchData.code == 0,
              let extensions = guideInfoPrefetchData.blockExtensions,
              !extensions.isEmpty else {
                  Self.logger.error("parse block  guide info fail", additionalData: [
                    "code": "\(guideInfoPrefetchData.code)",
                    "hasExtensions": "\(guideInfoPrefetchData.blockExtensions?.isEmpty ?? true)"
                  ])
                  return guideInfoMap
              }
        return extensions
    }

    func preloadMetaPkg() {
        DispatchQueue.main.async {
            if let idList = self.blockUniqueIds,
                !idList.isEmpty {
                Self.logger.info("start trigger preinstall meta & pkg")
                self.blockService.triggerPreInstall(idList: idList)
            }
        }
    }
}
