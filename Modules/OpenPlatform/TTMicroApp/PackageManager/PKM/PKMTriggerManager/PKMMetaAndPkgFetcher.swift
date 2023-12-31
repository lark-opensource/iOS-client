//
//  PKMMetaFetcher.swift
//  TTMicroApp
//
//  Created by laisanpin on 2022/12/15.
//  PKM拉取meta和pkg资源文件

import Foundation
import OPFoundation
import OPSDK
import LKCommonsLogging

typealias PKMMetaRequestCompletion = (PKMBaseMetaProtocol?, Error?) -> Void

typealias PKMBatchMetaCompletion = ([(String, PKMBaseMetaProtocol?, Error?)]?, Error?) -> Void

typealias PKMPackgeRequestBegun = (PKMPackageReaderProtocol?) -> Void

typealias PKMPackageRequestProgress = (Int, Int, URL?) -> Void

typealias PKMPackageRequestCompletion = (Error?, Bool, PKMPackageReaderProtocol?) -> Void

/// meta请求参数对象
struct PKMMetaRequest {
    public let uniqueID: PKMUniqueID
    public let bizType: PKMType
    public let previewToken: String?
    public let batchMetaParams: [String : String]?

    init(uniqueID: PKMUniqueID,
         bizType: PKMType,
         previewToken: String? = nil,
         batchMetaParams: [String: String]? = nil) {
        self.uniqueID = uniqueID
        self.bizType = bizType
        self.previewToken = previewToken
        self.batchMetaParams = batchMetaParams
    }

    public func isPreview() -> Bool {
        return !BDPIsEmptyString(previewToken)
    }

    public func description() -> String {
        "appID: \(uniqueID.appID), identifier: \(String(describing: uniqueID.identifier)), bizType: \(bizType.toString()), isPreview:\(isPreview()), batchMeta:\(String(describing: batchMetaParams))"
    }
}

/// pkg请求参数对象
struct PKMPackageRequest {
    public let appMeta: AppMetaProtocol
    public let packageType: BDPPackageType
    public let loadType: PKMLoadType
    public let priority: Float
    public let extra: [String : Any]?
    public let tarce: BDPTracing
}

/// 包句柄封装类
struct PKMPackageReader: PKMPackageReaderProtocol {
    public let originReader: BDPPkgFileManagerHandleProtocol?

    init(originReader: BDPPkgFileManagerHandleProtocol?) {
        self.originReader = originReader
    }
}

/// PKM拉取远端meta工具类
final class PKMMetaFetcher {
    static let logger = Logger.log(PKMMetaFetcher.self, category: "PKMMetaFetcher")

    private let metaProviderLock = NSLock()

    func fetchRemoteMeta(with request: PKMMetaRequest,
                         completion: PKMMetaRequestCompletion?) {
        let bdpUniqueID = PKMUtil.configBDPUniqueID(request.uniqueID, appType: request.bizType, isPreview: request.isPreview())
        // 后面这边要根据bizeType进行meta拉取
        let metaCtx = MetaContext(uniqueID: bdpUniqueID, token: request.previewToken)
        requestGadgetMeta(metaCtx, completion: completion)
    }

    func batchMeta(with request: PKMMetaRequest,
                   completion: PKMBatchMetaCompletion?) {
        var params = request.batchMetaParams ?? [String : String]()
        params[request.uniqueID.appID] = ""
        Self.logger.info("\(String.MetaPrefix) batch metas: \(params)")
        batchGadgetMeta(params: params, completion: completion)
    }

    func batchGadgetMeta(params: [String : String],
                         completion: PKMBatchMetaCompletion?) {
        guard let metaProvider = gadgetMetaProvider() else {
            let error = PKMError(domain: .MetaError, msg: "can not get gadgetMetaProvider")
            completion?(nil, error)
            return
        }

        let _ = metaProvider.batchRequestRemoteMeta(params, scene: .gadgetLaunch, shouldSaveMeta: true) { resultList, saveMetaBlock in
            let metas = resultList.map { (appID, meta, error) in
                return (appID, meta as? PKMBaseMetaProtocol, error)
            }
            completion?(metas, nil)
        } failure: { error in
            let pkmError = PKMError(domain: .MetaError, msg: "batch meta failed: \(error.localizedDescription)", originError: error)
            completion?(nil, pkmError)
        }
    }

    /// 请求小程序meta
    func requestGadgetMeta(_ metaCtx: MetaContext,
                           completion: PKMMetaRequestCompletion?) {
        guard let metaProvider = gadgetMetaProvider() else {
            let error = PKMError(domain: .MetaError, msg: "can not get gadgetMetaProvider")
            completion?(nil, error)
            return
        }

        metaProvider.requestRemoteMeta(with: metaCtx, shouldSaveMeta: true) { appMeta, _ in
            guard let appMeta = appMeta as? PKMBaseMetaProtocol else {
                let error = PKMError(domain: .MetaError, msg: "can not get PKMBaseMetaProtocol")
                completion?(nil, error)
                return
            }
            completion?(appMeta, nil)
        } failure: { error in
            completion?(nil, error)
        }
    }

    private func gadgetMetaProvider() -> MetaInfoModule? {
        metaProviderLock.lock()
        defer{
            metaProviderLock.unlock()
        }
        guard let metaProvider = BDPModuleManager(of: .gadget)
            .resolveModule(with: MetaInfoModuleProtocol.self) as? MetaInfoModule else {
            OPAssertionFailureWithLog("\(String.MetaPrefix) no meta module manager for gadget")
            return nil
        }
        return metaProvider
    }
}

/// PKM拉取远端pkg工具类
final class PKMPackageFetcher {
    static let logger = Logger.log(PKMPackageFetcher.self, category: "PKMPackageFetcher")

    private var packageModule: BDPPackageModuleProtocol?

    private let packageModuleLock = NSLock()

    func downloadPackage(with request: PKMPackageRequest,
                         begun: PKMPackgeRequestBegun?,
                         progress: PKMPackageRequestProgress?,
                         complete: PKMPackageRequestCompletion?) {
        guard let packageModule = getPackageModule() else {
            Self.logger.warn("\(String.PkgPrefix) packageModule is nil")
            let error = PKMError(domain: .MetaError, msg: "can not get packageModule")
            complete?(error, false, nil)
            return
        }

        let packageCtx = BDPPackageContext(appMeta: request.appMeta, packageType: request.packageType, packageName: nil, trace: request.tarce)

        let priority = request.priority
        if let startPage = request.extra?["pkm_startPage"] as? String {
            Self.logger.info("\(String.PkgPrefix) \(request.appMeta.uniqueID.appID) contain startPage")
            packageCtx.updateStartPage(startPage)
        }

        let downloadBeginBlock: BDPPackageDownloaderBegunBlock = { reader in
            begun?(PKMPackageReader(originReader: reader))
        }

        let downloadProcessBlock: BDPPackageDownloaderProgressBlock = { receivedSize, expectedSize, url in
            progress?(receivedSize, expectedSize, url)
        }

        let downloadCompleteBlock: BDPPackageDownloaderCompletedBlock = { error, isCancelled, reader in
            complete?(error, isCancelled, PKMPackageReader(originReader: reader))
        }

        switch request.loadType {
        case .normal:
            packageModule.normalLoadPackage(with: packageCtx, priority: priority, begun: downloadBeginBlock, progress: downloadProcessBlock, completed: downloadCompleteBlock)
        case .update:
            packageModule.asyncDownloadPackage(with: packageCtx, priority: priority, begun: downloadBeginBlock, progress: downloadProcessBlock, completed: downloadCompleteBlock)
        case .prehandle:
            packageModule.predownloadPackage(with: packageCtx, priority: priority, begun: downloadBeginBlock, progress: downloadProcessBlock, completed: downloadCompleteBlock)
        }
    }

    func getPackageModule() -> BDPPackageModuleProtocol? {
        packageModuleLock.lock()
        defer {
            packageModuleLock.unlock()
        }
        if let packageModule = packageModule {
            return packageModule
        } else {
            guard let packageModule = BDPModuleManager(of: .gadget)
                .resolveModule(with: BDPPackageModuleProtocol.self) as? BDPPackageModuleProtocol else {
                return nil
            }
            self.packageModule = packageModule
            return packageModule
        }
    }
}

extension PKMPackageFetcher {
    func packageReadTypes(with uniqueID: PKMUniqueID,
                          bizType: PKMType,
                          pkgName: String?) -> [NSNumber]? {
        guard let packageModule = getPackageModule(), let pkgName = pkgName else {
            Self.logger.warn("\(String.PkgPrefix) pkgName is invalid")
            return nil
        }

        let bdpUniqueID = PKMUtil.configBDPUniqueID(uniqueID, appType: bizType, isPreview: false)
        return packageModule.packageInfoManager.queryPkgReadType(of: bdpUniqueID, pkgName: pkgName)
    }

    func prehandeInfo(with uniqueID: PKMUniqueID,
                      bizType: PKMType,
                      pkgName: String?) -> (String, Int) {
        let commonDefaultValue = ("unknown", -1)
        guard OPSDKFeatureGating.packageExtReadWriteEnable() else {
            return commonDefaultValue
        }

        guard let packageModule = getPackageModule(), let pkgName = pkgName else {
            Self.logger.warn("\(String.PkgPrefix) pkgName is invalid")
            return commonDefaultValue
        }

        let bdpUniqueID = PKMUtil.configBDPUniqueID(uniqueID, appType: bizType, isPreview: false)
        let extDic = packageModule.packageInfoManager.extDictionary(bdpUniqueID, pkgName: pkgName)

        let prehandleSceneName = extDic?[kPkgTableExtPrehandleSceneKey] as? String ?? "unknown"
        let preUpdatePullType = extDic?[kPkgTableExtPreUpdatePullTypeKey] as? Int ?? -1

        return (prehandleSceneName, preUpdatePullType)
    }
}

final class PKMUtil {
    public static func configBDPUniqueID(_ pkmUniqueID: PKMUniqueID, appType: PKMType, isPreview: Bool) -> OPAppUniqueID {
        return BDPUniqueID(appID: pkmUniqueID.appID,
                           identifier: pkmUniqueID.identifier,
                           versionType: isPreview ? .preview : .current,
                           appType: appType.toAppType())
    }

    static func monitorTrace(with uniqueID: PKMUniqueID,
                             bizType: PKMType,
                             isPreivew: Bool) -> BDPTracing {
        let oldUniqueID = PKMUtil.configBDPUniqueID(uniqueID, appType: bizType, isPreview: isPreivew)
        if let trace = BDPTracingManager.sharedInstance().getTracingBy(oldUniqueID) {
            return trace
        }
        return BDPTracingManager.sharedInstance().generateTracing()
    }

    public static func configPKMUniqueID(with oldUniqueID: BDPUniqueID) -> PKMUniqueID {
        return oldUniqueID.toPKMUniqueID()
    }
}

extension BDPUniqueID {
    func toPKMUniqueID() -> PKMUniqueID {
        if self.appID == self.identifier {
            return PKMUniqueID(appID: self.appID, identifier: nil)
        } else {
            return PKMUniqueID(appID: self.appID, identifier: self.identifier)
        }
    }
}

fileprivate extension String {
    static let MetaPrefix = "[PKMMetaFetcher]"
    static let PkgPrefix = "[PKMPkgFetcher]"
}
