//
//  BlockitAPI.swift
//  Blockit
//
//  Created by 夏汝震 on 2020/10/10.
//
import SwiftyJSON
import ECOInfra
import LKCommonsLogging
import LarkOPInterface
import OPBlockInterface
import OPFoundation
import LarkContainer

final class BlockitAPI {
    static let log = Logger.log(BlockitAPI.self, category: "BlockitAPI")

    private let netStatusService: OPNetStatusHelper
    private let network: HttpClientManager

    init(netStatusService: OPNetStatusHelper, config: BlockitConfig, network: HttpClientManager) {
        self.netStatusService = netStatusService
        self.network = network
    }

    /// 生成 blockID
    /// - Parameters:
    ///   - domain: 业务域
    ///   - uuid: 对应到唯一的业务实体
    ///   - blockTypeID: 开发者后台生成 (套件业务)
    ///   - success: 成功时回调，携带BlockID
    ///   - failure: 失败时回调
    func generateBlockID(
        domain: String,
        uuid: String,
        blockTypeID: String,
        isIdFromLocal: Bool = false,
        success: @escaping (String) -> Void,
        failure: @escaping (Error) -> Void
    ) {
        if isIdFromLocal {
            success("\(domain)-\(uuid)")
        }
        let path = "/open-apis/block/server/api/GenerateBlockID"
        let params = [
            "domain": domain,
            "uuid": uuid,
            "blockTypeID": blockTypeID
        ]
        network.post(path: path, params: params, success: { json in
            guard let code = json["code"] as? Int, code == 0 else {
                let error = NSError(domain: "code != 0", code: -1, userInfo: nil)
                Blockit.log.error("url: generateBlockID, reponse: \(json), error: \(error)")
                failure(error)
                return
            }

            guard let data = json["data"] as? [String: String], let blockID = data["blockID"] else {
                let error = NSError(domain: "unpack failure", code: -1, userInfo: nil)
                Blockit.log.error("url: generateBlockID, reponse: \(json), error: \(error)")
                failure(error)
                return
            }
            if !isIdFromLocal {
                success(blockID)
            }
        }, failure: failure)
    }

    /// 根据blockID 获取 blockEntity
    /// - Parameters:
    ///   - blockIDs: blockIDs 数组
    ///   - success: 成功时回调，携带BlockID
    ///   - failure: 失败时回调
    ///   - trace: OPTraceProtocol
    func getBlockEntity(
        blockIDs: [String],
        success: @escaping ([BlockInfo]) -> Void,
        failure: @escaping (Error) -> Void,
        trace: OPTraceProtocol? = nil
    ) {
        OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                  code: OPBlockitMonitorCodeMountEntity.start_fetch_block_entity)
            .addCategoryValue("blocks", blockIDs)
            .tracing(trace)
            .flush()
        let path = "/open-apis/block/server/api/MGetBlockEntityV2"
        let params = ["blockIDs": blockIDs] as [String: Any]
        network.post(path: path, params: params, success: { json in
            guard let code = json["code"] as? Int, code == 0 else {
                let error = NSError(domain: "code != 0", code: -1, userInfo: nil)
                Blockit.log.error("url: getBlockEntity, reponse: \(json), error: \(error)")
                let monitorCode = OPBlockitMonitorCodeMountEntity.fetch_block_entity_biz_error
                OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                          code: monitorCode)
                    .tracing(trace)
                    .addMap([
                        "biz_code": json["code"] as? Int,
                        "data_keys": json.map({"\($0.key)" }) ?? [],
                        "biz_error_code": "\(OPBlockitEntityBizErrorCode.invalidCode.rawValue)"
                    ])
                    .setResultTypeFail()
                    .setError(error)
                    .flush()
                failure(error.newOPError(monitorCode: monitorCode))
                return
            }

            guard let data = json["data"] as? [String: [String: Any]],
                let blocks = data["blocks"] as? [String: [String: Any]] else {
                let error = NSError(domain: "unpack failure", code: -1, userInfo: nil)
                Blockit.log.error("url: getBlockEntity, reponse: \(json), error: \(error)")
                let monitorCode = OPBlockitMonitorCodeMountEntity.fetch_block_entity_biz_error
                OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                          code: monitorCode)
                    .tracing(trace)
                    .setResultTypeFail()
                    .addMap([
                        "biz_code": json["code"] as? Int,
                        "data_keys": json.map({"\($0.key)" }) ?? [],
                        "biz_error_code": "\(OPBlockitEntityBizErrorCode.unpackFailure.rawValue)"
                    ])
                    .setError(error)
                    .flush()
                failure(error.newOPError(monitorCode: monitorCode))
                return
            }

            let entitys = blocks.values
            let blockInfos = entitys.compactMap { entity -> BlockInfo? in
                guard let code = entity["status"] as? Int, code == 0,
                      let blockEntity = entity["entity"] as? [String: Any] else { return nil }

                guard let blockID = blockEntity["blockID"] as? String,
                      let blockTypeID = blockEntity["blockTypeID"] as? String,
                      let sourceMeta = blockEntity["sourceMeta"] as? String else { return nil }

                let sourceLink = blockEntity["sourceLink"] as? String ?? ""
                let sourceData = blockEntity["sourceData"] as? String
                let i18nSummary = blockEntity["i18nSummary"] as? String ?? ""
                let i18nPreview = blockEntity["i18nPreview"] as? String

                let blockInfo = BlockInfo(blockID: blockID,
                                          blockTypeID: blockTypeID,
                                          sourceLink: sourceLink,
                                          sourceData: sourceData,
                                          sourceMeta: sourceMeta,
                                          i18nPreview: i18nPreview,
                                          i18nSummary: i18nSummary)
                return blockInfo
            }
            let logId = json[HttpClientManager.logId] ?? ""
            OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                      code: OPBlockitMonitorCodeMountEntity.fetch_block_entity_success)
                .tracing(trace)
                .addMetricValue("block_infos", blockInfos.map({ $0.blockID }))
                .addCategoryValue("log_id", logId)
                .setResultTypeSuccess()
                .flush()
            success(blockInfos)
        }, failure: { [weak self]error in
            guard let self = self else { return }
            let logId = (error as NSError).userInfo[HttpClientManager.logId] ?? ""
            let monitorCode = OPBlockitMonitorCodeMountEntity.fetch_block_entity_network_error
            OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                      code: monitorCode)
                .tracing(trace)
                .setError(error)
                .addMetricValue("http_code", (error as NSError).code)
                .addCategoryValue("log_id", logId)
                .addCategoryValue("net_status", self.netStatusService.status.rawValue)
                .setResultTypeFail()
                .flush()
            failure(error.newOPError(monitorCode: monitorCode))
        })
    }
    
    func getBlockEntityVersion(
        blockIDs: [String],
        success: @escaping ([BlockOnEntityMessageData]) -> Void,
        failure: @escaping (Error) -> Void
    ) {
        let path = "/open-apis/block/server/api/MGetBlockEntityV2"
        let params = ["blockIDs": blockIDs] as [String : Any]
        network.post(path: path, params: params, success: { json in
            guard let code = json["code"] as? Int, code == 0 else {
                let error = NSError(domain: "code != 0", code: -1, userInfo: nil)
                Blockit.log.error("url: getBlockEntityVersion, reponse: \(json), error: \(error)")
                failure(error)
                return
            }

            guard let data = json["data"] as? [String: [String: Any]],
                  let blocks = data["blocks"] as? [String: [String: Any]] else {
                let error = NSError(domain: "unpack failure", code: -1, userInfo: nil)
                Blockit.log.error("url: getBlockEntityVersion, reponse: \(json), error: \(error)")
                failure(error)
                return
            }

            let entitys = blocks.values
            
            let messageData = entitys.compactMap { entity -> (BlockOnEntityMessageData?) in
                guard let code = entity["status"] as? Int,code == 0,
                      let blockEntity = entity["entity"] as? [String: Any],
                      let blockVersion = entity["version"] as? Int,
                      let sourceData = blockEntity["sourceData"] as? String
                else {
                    Blockit.log.error("url: getBlockEntityVersion entity error , entity is: \(entity)")
                    return nil
                }
                let blockInfo = BlockOnEntityMessageData(version: blockVersion, sourceData: sourceData)
                return blockInfo
            }
            success(messageData)
        }, failure: failure)
    }

    func getAvailableBlockList(
        param: BlockDetailReqParam,
        success: @escaping ([BlockDetail]) -> Void,
        failure: @escaping (Error) -> Void
    ) {
        let path = "/lark/app_explorer/api/GetBlockTemplateList"
        let param = param.toDictionary()
        network.post(path: path, params: param, success: { json in
            guard let code = json["code"] as? Int, code == 0 else {
                let error = NSError(domain: "code != 0", code: -1, userInfo: nil)
                Blockit.log.error("url: getAvailableBlockList, reponse: \(json), error: \(error)")
                failure(error)
                return
            }

            guard let dataDic = json["data"] as? [String: Any] else {
                let error = NSError(domain: "unpack failure", code: -1, userInfo: nil)
                Blockit.log.error("url: getAvailableBlockList, reponse: \(json), error: \(error)")
                failure(error)
                return
            }

            guard let data = HttpSerializer.toData(dataDic) else {
                let error = NSError(domain: "toData failure", code: -1, userInfo: nil)
                Blockit.log.error("url: getAvailableBlockList, reponse: \(json), error: \(error)")
                failure(error)
                return
            }
            do {
                let result = try JSONDecoder().decode([BlockDetail].self, from: data)
                Blockit.log.info("url: getAvailableBlockList, success")
                success(result)
            } catch let err {
                failure(err)
            }
        }, failure: failure)
    }

    func createBlock(
        param: BlockInfoReq,
        success: @escaping (String) -> Void,
        failure: @escaping (Error) -> Void
    ) {
        let path = "/open-apis/block/server/api/CreateBlockEntity"

        // param
        let param = [
            "Entity": param.toDictionary()
        ]
        network.post(path: path, params: param, success: { json in
            guard let code = json["code"] as? Int, code == 0 else {
                let error = NSError(domain: "code != 0", code: -1, userInfo: nil)
                Blockit.log.error("url: createBlock, reponse: \(json), error: \(error)")
                failure(error)
                return
            }

            guard let blockID = json["BlockId"] as? String else {
                let error = NSError(domain: "param error", code: -1, userInfo: nil)
                Blockit.log.error("url: createBlock, reponse: \(json), error: \(error)")
                failure(error)
                return
            }
            Blockit.log.info("url: createBlock success, blockID: \(blockID)")
            success(blockID)
        }, failure: failure)
    }

    ///用户维度数据拉取block信息，接口文档 https://bytedance.feishu.cn/docs/doccnJWEcnDj0drdefiQSlBxVKf#hCUc5v
    func getOpenMessage(
        headers: [String: String],
        params: [String: Any],
        success: @escaping (OpenMessageRes) -> Void,
        failure: @escaping (Error) -> Void
    ) {
        let path = "/open-apis/block/server/api/MGetOpenMessage"
        network.post(path: path, params: params, headers: headers, success: { json in
            guard let code = json["code"] as? Int, code == 0 else {
                let error = NSError(domain: "code != 0", code: -1, userInfo: nil)
                Blockit.log.error("url: getOpenMessage, reponse: \(json), error: \(error)")
                failure(error)
                return
            }
            guard let dataDic = json["data"] as? [String: Any] else {
                let error = NSError(domain: "unpack failure", code: -1, userInfo: nil)
                Blockit.log.error("url: getOpenMessage, reponse: \(json), error: \(error)")
                failure(error)
                return
            }
            guard let data = HttpSerializer.toData(dataDic) else {
                let error = NSError(domain: "toData failure", code: -1, userInfo: nil)
                Blockit.log.error("url: getOpenMessage, reponse: \(json), error: \(error)")
                failure(error)
                return
            }
            do {
                let result = try JSONDecoder().decode(OpenMessageRes.self, from: data)
                Blockit.log.info("url: getOpenMessage, success")
                success(result)
            } catch let err {
                failure(err)
            }
        }, failure: failure)
    }
}
