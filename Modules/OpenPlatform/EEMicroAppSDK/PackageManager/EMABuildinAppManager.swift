//
//  EMABuildinAppManager.swift
//  EEMicroAppSDK
//
//  Created by Nicholas Tau on 2023/3/13.
//

import Foundation
import LKCommonsLogging
import OPSDK
import OPBlock
import TTMicroApp

extension OPBlockMetaProvider: MetaProviderProtocol {
    
    public func buildMetaModel(with data: Data, ttcode: BDPMetaTTCode, context: TTMicroApp.MetaContext) throws -> TTMicroApp.AppMetaProtocol {
        var json = try JSONSerialization.jsonObject(with: data)
        guard let jsonDic = json as? [String: Any] else {
            let msg = "jsonDic form data is nil"
            let opError = OPError.error(monitorCode: CommonMonitorCodeMeta.invalid_params, message: msg)
            assertionFailure(opError.description)
            throw opError
        }
        return try buildMetaModelWithDict(jsonDic, ttcode: ttcode, context: context)
    }
    
    public func buildMetaModelWithDict(
            _ dict: [String: Any],
            ttcode: BDPMetaTTCode,
            context: MetaContext
    ) throws -> AppMetaProtocol  {
        let provider = OPBlockMetaProvider()
        if  let data = try? JSONSerialization.data(withJSONObject: dict),
            let blockMeta = provider.getMeta(with: data, uniqueID: context.uniqueID) {
                return blockMeta
        }
        throw OPError.error(monitorCode: CommonMonitorCodeMeta.invalid_params, message: "buildMetaModelWithDict with error, blockMeta return nil")
    }
    
    public func buildMetaModel(with metaJsonStr: String, context: MetaContext) throws -> AppMetaProtocol {
        let provider = OPBlockMetaProvider()
        if  let data = metaJsonStr.data(using: .utf8),
            let blockMeta = provider.getMeta(with: data, uniqueID: context.uniqueID) {
            return blockMeta
        }
        throw OPError.error(monitorCode: CommonMonitorCodeMeta.invalid_params, message: "buildMetaModel with error, blockMeta return nil")
    }
}

public class EMABuildinAppManager: NSObject {
    private let log = Logger.oplog(EMABuildinAppManager.self, category: "BuildInManagerModule")
    
    @objc public static let sharedInstance = EMABuildinAppManager()

    //处理预置包的逻辑
    @objc public func buildinPackageProcess() {
        if OPSDKFeatureGating.isBuildInPackageProcessEnable() {
            log.info("ready to execute builin process")
            DispatchQueue.global().async { [weak self] in
                self?.executeBuildinResources()
                self?.log.info("executeBuildinResources finished")
            }
        }
    }
    //当前只支持 gaget 和 block，如果需要其他类型，需要适配
    func executeBuildinResources() {
        log.info("executeBuildinResources executing")
        //小程序资源内置解压处理
        if let buildinResourceBundle =  PKMApplePieManager.shared().bundlePath(forBuildin: true) {
            let buildInMetaListMap: [OPAppType: String] = [.gadget: "appMetaList", .block: "blockMetaList"]
            buildInMetaListMap.forEach { appType, metaListFileName in
                if  let buindinBundleForJSON = PKMApplePieManager.shared().bundlePath(forBuildin: false),
                    let buildMetaJsonData = try? Data(contentsOf: URL(fileURLWithPath: buindinBundleForJSON.appending("/\(metaListFileName).json"))),
                   let metaList = try? JSONSerialization.jsonObject(with: buildMetaJsonData, options: .allowFragments) as? [[String: Any]] {
                    buildinExtractor(buildinResourceBundle: buildinResourceBundle, buildinMetaList: metaList, appType: appType)
                } else {
                    log.error("executeBuildinResources error: json invalid")
                }
            }
        } else {
            log.error("executeBuildinResources error: BuildinResources.bundle  invalid")
        }
        //小程序的内置数据
        func buildinExtractor(buildinResourceBundle: String, buildinMetaList: [[String: Any]], appType: OPAppType) {
            log.info("buildinExtractor with buildinMetaList:\(buildinMetaList) and appType:\(appType)")
            //****只支持gadget、block内置，如果有新的业务需要拍内置，内部的代码需要适配*****//
            let appTypeSupported = appType == .gadget || appType == .block
            //检查一下是否是已经支持的内置类型
            guard appTypeSupported else {
                log.info("appTypeSupported is false, executeBuildinResources ended")
                assert(false ,"executeBuildinResources fail")
                return
            }
            log.info("buildinExtractor with appType:\(appType)")
            for json in buildinMetaList {
                //检查一下 JSON 内部数据的合法性，是不是包含必要字段
                let isJSONInvalid = appType == .gadget ? json["appid"] != nil : json["data"] != nil
                if isJSONInvalid {
                    var appID = json["appid"] as? String
                    //如果是block，需要塞 block 的 extension 作为 identifier。可以默认是nil
                    var identifier: String? = nil
                    //如果不是小程序，json里不包含appid。需要从 meta_extensions 里面找
                    if appType != .gadget,
                       appID == nil,
                       let data = json["data"] as? [String: Any],
                       let appMeta = (data["app_metas"] as? [[String: Any]])?.first {
                        let extensionMeta = (appMeta["extension_metas"] as? [[String: Any]])?.first
                        appID = extensionMeta?["app_id"] as? String
                        identifier =  extensionMeta?["extension_id"] as? String
                    }
                    let uniqueId = OPAppUniqueID(appID: appID ?? "", identifier: identifier, versionType: .current, appType: appType)
                    let metaContext = MetaContext(uniqueID: uniqueId, token: nil)
                    //这里只适配 gadget 和 block，其他类型如果需要内置要是配 MetaProviderProtocol 协议
                    let provider: MetaProviderProtocol = appType == .gadget ? GadgetMetaProvider(type: .gadget) : OPBlockMetaProvider()
                    guard let buildInMeta = try? provider.buildMetaModelWithDict(json, ttcode: BDPMetaTTCode.buildInApp(), context: metaContext) as? AppMetaProtocol else {
                        log.error("buildin meta constructed with error")
                        return
                    }
                    //插入预置标记信息（如果是小程序meta）
                    (buildInMeta.businessData as? GadgetBusinessData)?.isFromBuildin = true
                    let metaLocalAccessor = MetaLocalAccessor(type: appType)
                    if let buildinJsonStr = try? buildInMeta.toJson() {
                        if let existedMetaString = metaLocalAccessor.getLocalMeta(with: metaContext),
                           let existedMeta = try? provider.buildMetaModel(with: existedMetaString, context: metaContext) as? AppMetaProtocol {
                            //判断两边的版本，只有内置的版本比已存在的还要高，才进行写入
                            if BDPVersionManager.compareVersion(buildInMeta.version, with: existedMeta.version) > 0  {
                                //预置的版本比本地的要高，保存 meta 信息
                                metaLocalAccessor.saveLocalMeta(with: .current, key: uniqueId.identifier, value: buildinJsonStr)
                            } else {
                                //log here
                                log.error("existed meta found, and buildin version compare fail: \(uniqueId)")
                            }
                        } else {
                            //本地不存在meta信息，直接写入
                            metaLocalAccessor.saveLocalMeta(with: .current, key: uniqueId.identifier, value: buildinJsonStr)
                        }
                    } else {
                        log.error("buildInMeta buildin json invalid: \(uniqueId)")
                    }
                    let packageContext = BDPPackageContext(appMeta: buildInMeta, packageType: appType == .gadget ? .pkg : .zip, packageName: nil, trace: BDPTracing(traceId: ""))
                    //检查当前gadget的package是否已经存在
                    let packageExisted = BDPPackageLocalManager.isLocalPackageExsit(packageContext)
                    if packageExisted {
                        //如果存在，啥也不干，写点日志
                        log.info("package existed with uniqueId:\(uniqueId), buildin package has been discard")
                    } else {
                        //写入包信息到本地沙箱目录，同时修改DB状态，将 package state设置为 downloaded
                        let fromResourcePath = buildinResourceBundle.appending("/\(uniqueId.identifier).zip")
                        if let bulidInPackageData =  try? Data(contentsOf: URL(fileURLWithPath: fromResourcePath)) {
                            //目标地址目录，必须保证 pktDirPath 是 String 而不是 String?
                            let pkgDirPath = (BDPPackageLocalManager.localPackageDirectoryPath(for: packageContext) as? NSString)?.deletingLastPathComponent as? String ?? ""
                            do {
                                try BDPPackageManagerStrategy.installPackage(with: packageContext, packagePath: fromResourcePath, installPath: pkgDirPath ?? "", isApplePie:true)
                                log.info("install finished:\(packageContext)")
                            } catch {
                                log.error("installPackage with error:\(error) from:\(fromResourcePath) to:\(pkgDirPath)")
                            }
                            //修改本地package 数据库状态
                            let packageInfoManager = BDPPackageInfoManager(appType: appType)
                            packageInfoManager.replaceInToPkgInfo(with: .downloaded, with: uniqueId, pkgName: packageContext.packageName, readType: .normal)
                            //内置目录没有，尝试走降级ODR
                        } else if OPSDKFeatureGating.isEnableApplePie() {
                            //所有内置的资源，从 ODR 资源预热
                            PKMApplePieManager.shared().warmPies([uniqueId]) { error, uniqueID in
                                if error == nil {
                                    //没有error，认为成功了。进行安装
                                    var retryCount = 0
                                    var installSuccess = false
                                    //默认允许重试三次
                                    while(retryCount < 3 && !installSuccess) {
                                        let pathForPie = PKMApplePieManager.shared().specificPath(forPie: uniqueId)
                                        if let pathForPie = pathForPie,
                                           FileManager.default.fileExists(atPath: pathForPie),
                                           let pkgDirPath = BDPPackageLocalManager.localPackagePath(for: packageContext) as? NSString {
                                           do {
                                               //安装如果已经提前存在，先清理一下。避免数据库状态和文件不一致导致 installPackage 安装失败
                                               if FileManager.default.fileExists(atPath: pkgDirPath.deletingLastPathComponent) {
                                                   try FileManager.default.removeItem(atPath: pkgDirPath.deletingLastPathComponent)
                                               }
                                               try BDPPackageManagerStrategy.installPackage(with: packageContext, packagePath: pathForPie, installPath: pkgDirPath.deletingLastPathComponent, isApplePie: true)
                                               //修改本地package 数据库状态
                                               let packageInfoManager = BDPPackageInfoManager(appType: appType)
                                               packageInfoManager.replaceInToPkgInfo(with: .downloaded, with: uniqueId, pkgName: packageContext.packageName, readType: .normal)
                                               installSuccess = true
                                               self.log.info("install finished:\(packageContext)")
                                           } catch {
                                               self.log.error("installPackage with error:\(error) from:\(pathForPie) to:\(pkgDirPath)")
                                               retryCount += 1
                                           }
                                        } else {
                                            self.log.error("pathForPie is nil")
                                            retryCount += 1
                                        }
                                    }
                                    self.log.info("installation finished with status:\(installSuccess) retryCount:\(retryCount)")
                                } else {
                                    self.log.error("warmPies with error:\(error?.localizedDescription)")
                                }
                            }
                        } else {
                            log.error("bulidInPackageData is exmpty with path:\(fromResourcePath)")
                        }
                    }
                } else {
                    log.warn("isJSONInvalid is false, check failed")
                }
            }
        }
    }
}
