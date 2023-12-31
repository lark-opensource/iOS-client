//
//  MetaInfoModule.swift
//  Timor
//
//  Created by 武嘉晟 on 2020/5/16.
//

import LarkOPInterface
import LKCommonsLogging
import OPSDK

private let log = Logger.oplog(MetaInfoModule.self, category: "MetaInfoModule")

/// Meta 管理模块实现 单例
/// 功能：从网络下载Meta，获取本地Meta，清除Meta
@objcMembers
public final class MetaInfoModule: NSObject, MetaInfoModuleProtocol {
    /// 模块管理对象
    public var moduleManager: BDPModuleManager?
    /// 应用元数据 数据库管理对象（小程序老版本workaround）
    public let metaInfoAccessor: BDPMetaInfoAccessorProtocol
    /// Meta能力提供对象，例如组装meta请求和组装meta实体
    private let provider: (MetaProviderProtocol&MetaTTCodeProtocol)?

    /// meta远端请求器
    private var metaRemoteRequester: MetaRemoteRequester?

    /// meta本地存取器
    private let metaLocalAccessor: MetaLocalAccessor

    /// Meta 管理模块实现 初始化方法
    /// - Parameter provider: Meta 能力提供对象
    public init(provider: (MetaProviderProtocol&MetaTTCodeProtocol)?, appType: BDPType) {
        self.provider = provider
        self.metaInfoAccessor = BDPMetaInfoAccessor(appType: appType)
        self.metaLocalAccessor = MetaLocalAccessor(type: appType)
        if let provider = provider {
            self.metaRemoteRequester = MetaRemoteRequester(provider: provider, appType: appType)
        }
        super.init()
    }

    public func launchGetMeta(
        with context: MetaContext,
        local: ((AppMetaProtocol) -> Void)?,
        asyncUpdate: ((AppMetaProtocol?, OPError?, (() -> Void)?) -> Void)?,
        remote: ((AppMetaProtocol?, OPError?) -> Void)?
    ) {
        log.info("launch get meta start, identifier: \(context.uniqueID.identifier)", tag: BDPTag.metaManager)
        //  非预览模式才需要读缓存，预览模式每次都从网络拉最新的
        if context.uniqueID.versionType != .preview,
           let localMeta = getLocalMeta(with: context) {
            //  有本地meta，回调local，并且异步更新
            local?(localMeta)
            log.info("launch get local meta, identifier: \(context.uniqueID.identifier), and start async update meta", tag: BDPTag.metaManager)
            requestRemoteMeta(with: context, shouldSaveMeta: false, success: { [weak self] (meta, saveMetaBlock) in
                //  异步更新成功
                asyncUpdate?(meta, nil, saveMetaBlock)
            }) { [weak self] (error) in
                asyncUpdate?(nil, error, nil)
            }
            return
        }
        log.info("launch get meta has no local meta, start fetch remote meta, identifier: \(context.uniqueID.identifier)", tag: BDPTag.metaManager)
        //  无本地meta，网络请求meta，走remote回调
        requestRemoteMeta(with: context, shouldSaveMeta: true, success: { [weak self] (meta, _) in
            guard let `self` = self else { return }
            //  网络请求成功
            remote?(meta, nil)
            log.info("has no local meta, async update meta success, identifier: \(context.uniqueID.identifier)", tag: BDPTag.metaManager)
        }) { [weak self] (error) in
            guard let `self` = self else { return }
            remote?(nil, error)
        }
    }

    public func getLocalMeta(with context: MetaContext) -> AppMetaProtocol? {
        guard let (str, ts) = metaLocalAccessor.getLocalMetaAndTimestamp(with: context) else {
            //  无meta缓存
            log.info(BDPTag.metaLocalAccessor, tag: "identifier:\(context.uniqueID.identifier) has no local meta")
            return nil
        }
        let metaModel = buildMeta(with: str, context: context)
        metaModel?.setLastUpdateTimestamp(ts: ts)
        return metaModel
    }
    
    public func buildMeta(with str:String, context: MetaContext) -> AppMetaProtocol? {
        guard let provider = provider else {
            //  无meta缓存
            log.warn(BDPTag.metaLocalAccessor, tag: "provider is empty")
            return nil
        }
        var metaModel: AppMetaProtocol?
        do {
            metaModel = try provider.buildMetaModel(with: str, context: context)
        } catch {
            _ = error.newOPError(monitorCode: CommonMonitorCodeMeta.meta_db_error, message: "build local metamodel form db str failed")
            return nil
        }
        log.info("get local meta success, identifier: \(context.uniqueID.identifier)", tag: BDPTag.metaLocalAccessor)
        // TODO: yinyuan 确认这行删掉是否有影响
//        metaModel?.appType = moduleManager?.type ?? .unknown    //  workaround 被迫兼容H5小程序 等待H5小程序删除后就可以删掉这一句了
        return metaModel
    }

    public func requestRemoteMeta(
        with context: MetaContext,
        shouldSaveMeta: Bool,
        success: ((AppMetaProtocol, (() -> Void)?) -> Void)?,
        failure: ((OPError) -> Void)?
    ) {
        log.info("start fetch remote meta, identifier: \(context.uniqueID.identifier)", tag: BDPTag.metaManager)
        metaRemoteRequester?.requestRemoteMeta(with: context, success: { [weak self] (meta) in
            guard let `self` = self else { return }
            if shouldSaveMeta {
                //  持久化
                self.saveMeta(meta)
                success?(meta, nil)
            } else {
                //  外界自己决定何时持久化
                success?(meta, { [weak self] in
                    guard let `self` = self else { return }
                    self.saveMeta(meta)
                })
            }
        }, failure: failure)
    }
    
    public func batchRequestRemoteMeta (
        _ entities: [String: String],
        scene: BatchLaunchScene,
        shouldSaveMeta: Bool,
        success: (([(String, AppMetaProtocol?, OPError?)], (() -> Void)?) -> Void)?,
        failure: ((OPError) -> Void)?
    ) {
        log.info("start batch fetch remote meta, entities: \(entities)", tag: BDPTag.metaManager)
        //检查参数是否长度超出，若超出直接报错
        //默认如果没有拿到配置，最大长度是 50
        let maxLimit =  BDPBatchMetaHelper.batchMetaConfig().batchMetaCountConfig.countWithScene(scene)
        //参数长度超出，报错
        if entities.count > maxLimit {
            failure?(OPError.error(monitorCode: CommonMonitorCodeMeta.invalid_params, message: "entities count out of boundary"))
            return
        }
        metaRemoteRequester?.batchRequestRemoteMetaWith(entities, scene: scene, success: { [weak self] (resultList) in
            guard let `self` = self else { return }
            let saveMetaBlock = { [weak self] in
                guard let `self` = self else { return }
                //  持久化
                resultList.forEach { appID, meta, opError in
                    //有 meta 且 opError为空，否额终止
                    if let meta = meta as? GadgetMeta,
                       opError == nil {
                        meta.batchMetaVersion = BDPBatchMetaHelper.batchMetaConfig().batchMetaVersion
                        self.saveMeta(meta)
                    } else {
                        log.info("batch result with error: \(opError?.description ?? "meta is empty")", tag: BDPTag.metaManager)
                    }
                }
            }
            if shouldSaveMeta {
                //  持久化
                saveMetaBlock()
                success?(resultList, nil)
            } else {
                //  外界自己决定何时持久化
                success?(resultList, saveMetaBlock)
            }
        }, failure: failure)
    }


    public func removeMetas(with contexts: [MetaContext]) {
        metaLocalAccessor.removeMetas(with: contexts)
    }

    public func removeAllMetas() {
        //审核时关闭清理meta的能力
        if(OPSDKFeatureGating.isBoxOff()) {
            return
        }
        metaLocalAccessor.removeAllMetas()
    }

    public func clearAllMetaRequests() {
        metaRemoteRequester?.clearAllRequests()
    }

    public func closeDBQueue() {
        metaInfoAccessor.closeDBQueue()
        metaLocalAccessor.closeDBQueue()
    }
}

extension MetaInfoModule {

    /// 持久化Meta
    /// - Parameter meta: meta模型
     func saveMeta(_ meta: AppMetaProtocol) {
        let key = meta.uniqueID.identifier
        var jsonStr: String?
        if OPSDKFeatureGating.enableMetaSaveCheckIfNecessary(meta.uniqueID) {
            log.warn("enableMetaSaveCheckIfNecessary is true, shouldn't save meta into db")
            return
        }
        if OPSDKFeatureGating.isBuildInPackageProcessEnable() {
            if let existedMeta = getLocalMeta(with: MetaContext(uniqueID: meta.uniqueID, token: nil)) {
                //如果写入的 meta 版本于本地相同，则丢弃【避免buildIn信息丢失】
                //有可能出现version小于本地版本的情况【服务端回滚】
                if BDPVersionManager.compareVersion(existedMeta.version, with: meta.version) == 0 {
                    var existedMetaJsonStr: String?
                    do {
                        jsonStr = try meta.toJson()
                        existedMetaJsonStr = try existedMeta.toJson()
                    } catch {
                        let strName = jsonStr == nil ? "jsonStr" : "existedMetaJsonStr"
                        log.error("MetaInfoModule save meta failed, identifier:\(meta.uniqueID.identifier), \(strName) is nil", tag: BDPTag.metaManager, error: error)
                    }
                    if let jsonStr = jsonStr,
                       let existedMetaJsonStr = existedMetaJsonStr {
                        if jsonStr == existedMetaJsonStr {
                            log.info("MetaInfoModule save meta failed, existed meta version is same with the one to write in")
                            return
                        }
                    }
                }
            }
        }
        if jsonStr == nil {
            do {
                jsonStr = try meta.toJson()
            } catch {
                log.error("MetaInfoModule save meta failed, identifier:\(meta.uniqueID.identifier)", tag: BDPTag.metaManager, error: error)
                return
            }
        }
        if let jsonStr = jsonStr {
            if let opError = metaLocalAccessor.saveLocalMeta(with: meta.uniqueID.versionType, key: key, value: jsonStr) {
                //异步上报埋点，以免影响启动性能
                DispatchQueue.global().async {
                    OPMonitor("mp_app_meta_db_error").setUniqueID(meta.uniqueID)
                        .setError(opError)
                        .flush()
                }
            }
        } else {
            log.error("MetaInfoModule save meta failed, jsonStr is nil")
        }
    }
}
