//
//  PreloadKey.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/7/19.
// swiftlint:disable file_length

import Foundation
import SwiftyJSON
import SpaceInterface
import RxSwift
import SKFoundation
import ThreadSafeDataStructure
import SKInfra
import LarkDocsIcon

public enum PreloadPriority: Int, Equatable {
    case high = 10          // 高优先级，比如docs_feed、IM卡片
    case middle = 0         // 默认优先级
    case low = -10          // 最低优先级
}

public struct PreloadKey: Hashable, CustomDebugStringConvertible, DocsParamConvertible {
    public static var cacheKeyPrefix = "" // 这个是 tenantID_userID_ ，在登录之后会刷新
    static var preloadImagesDic = SafeDictionary<String, [PreloadPicInfo]>() //需要预加载的图片（暂时是docx用到，由RN返回）
    public static func == (lhs: PreloadKey, rhs: PreloadKey) -> Bool {
        guard lhs.objToken == rhs.objToken,
            lhs.type == rhs.type else {
                return false
        }
        return true
    }
    public let encryptedObjToken: String
    public let objToken: String
    public let type: DocsType
    public var fromSource: PreloadFromSource?
    /// 预加载返回的数据长度
    public var responseLength: Int?
    public let memberId = OpenAPI.memberId
    public let driveFileType: DriveFileType?
    public let cacheKeyPrefix: String // tenantID_userID_
    public let newCacheAPI: NewCacheAPI
    public let driveDownloadCacheServive: SpaceDownloadCacheProtocol
    public let driverDownloader: DocCommonDownloadProtocol
    public let clientVarMetaDataManagerAPI: ClientVarMetaDataManagerAPI
    public let disposeBag: DisposeBag = DisposeBag()
    public let wikiInfo: WikiInfo?     // wiki类型的预加载需要知道wikiInfo
    public let maxRNPreloadSubBlockNum = 5 // 投票subblock预加载的最大个数，避免请求过多
    let sheetSSRfg = LKFeatureGating.sheetSSRFg
    private var docVersionRequest: DocsRequest<JSON>?
    // 预加载优先级
    public var loadPriority: PreloadPriority
    public var preloadClientVars: Bool
    public var preloadSSR: Bool

    public init(objToken: String,
                type: DocsType,
                source: FromSource? = nil,
                driveFileType: DriveFileType? = nil,
                resolver: DocsResolver = DocsContainer.shared,
                wikiInfo: WikiInfo? = nil,
                loadPriority: PreloadPriority? = .middle) {
        self.newCacheAPI = resolver.resolve(NewCacheAPI.self)!
        self.driverDownloader = resolver.resolve(DocCommonDownloadProtocol.self)!
        self.driveDownloadCacheServive = resolver.resolve(SpaceDownloadCacheProtocol.self)!
        self.clientVarMetaDataManagerAPI = resolver.resolve(ClientVarMetaDataManagerAPI.self)!
        self.objToken = objToken
        self.type = type
        self.fromSource = PreloadFromSource(source)
        self.driveFileType = driveFileType
        self.encryptedObjToken = DocsTracker.encrypt(id: objToken)
        self.cacheKeyPrefix = PreloadKey.cacheKeyPrefix
        self.wikiInfo = wikiInfo
        self.preloadClientVars = false
        self.preloadSSR = false
        self.loadPriority = loadPriority ?? .middle
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(objToken)
        hasher.combine(type)
    }

    var typeToServer: String {
        switch type {
        case .doc: return "DOC"
        case .sheet: return "SPREADSHEET"
        case .mindnote: return "MINDNOTE"
        case .wiki: return "WIKI"
        case .docX: return "DOCX"
        default:
            spaceAssertionFailure("not supported")
            return ""
        }
    }

    public var debugDescription: String {
        return "PreloadKey(encryptedObjToken: \(encryptedObjToken), type: \(type.name), fromSource: \(fromSource?.rawValue ?? "nil"))"
    }

    private static let contextParams: [String: String] = {
        var dict: [String: String] = [:]
        dict["os"] = UIDevice.current.systemName
        dict["os_version"] = UIDevice.current.systemVersion
        dict["platform"] = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String
        let appSubVersion = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String
        let appMainVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        var appVersion = appMainVersion.map { appSubVersion == nil ? "\($0)" : "\($0).\(appSubVersion!)" }
        dict["app_version"] = appVersion
        return dict
    }()

    // 网络请求的 params
    public var params: Params {
        switch type {
        case .doc:
            let dataInfo: [String: Any] = ["type": "CLIENT_VARS",
                                           "token": objToken,
                                           "member_id": memberId,
                                           "open_type": 1] // 0为前台打开，1为后台打开
            let params: [String: Any] = ["type": typeToServer,
                                         "data": dataInfo,
                                         "context": PreloadKey.contextParams]
            return params
        case .sheet:
            let extraData = ["row": 0, "row_count": 25, "col": 0, "col_count": 8]
            let dataInfo: [String: Any] = ["type": "CLIENT_VARS",
                                           "token": objToken,
                                           "version": 6,
                                           "member_id": memberId,
                                           "extra_data": extraData,
                                           "open_type": 1] // 0为前台打开，1为后台打开
            let params: [String: Any] = ["type": typeToServer,
                                         "version": 2,
                                         "req_id": 38,
                                         "context": PreloadKey.contextParams,
                                         "data": dataInfo]
            return params
        case .mindnote:
            let dataInfo: [String: Any] = ["type": "CLIENT_VARS",
                                           "token": objToken,
                                           "member_id": memberId,
                                           "open_type": 1] // 0为前台打开，1为后台打开
            let params: [String: Any] = ["type": typeToServer,
                                         "data": dataInfo,
                                         "context": PreloadKey.contextParams]
            return params
        case .slides:
            let dataInfo: [String: Any] = ["type": "CLIENT_VARS",
                                           "token": objToken,
                                           "member_id": memberId,
                                           "version": 0,
                                           "base_rev": 0,
                                           "open_type": 1] // 0为前台打开，1为后台打开]
            let params: [String: Any] = ["type": typeToServer,
                                         "data": dataInfo,
                                         "req_id": 1,
                                         "tenant_id": 4, // 中台给业务方分配的业务ID
                "version": 2,
                "context": PreloadKey.contextParams]
            return params
        case .docX:
            let params: [String: Any] = ["id": objToken]
            return params
        default:
            spaceAssertionFailure("not supported \(type)")
            return [:]
        }
    }

    public static func getClientVarKey(type: DocsType) -> String {
        switch type {
        case .doc, .sheet, .bitable, .mindnote, .slides, .docX:
            return type.clientVarKey()
        case .wiki:
            spaceAssertionFailure("should not get/set wikiInfo by clientvar key @peipei, use wikiInfoKey")
            return ""
        default:
            spaceAssertionFailure("not supported type")
            return ""
        }
    }

    public var clientVarKey: String {
        PreloadKey.getClientVarKey(type: type)
    }

    public var hasClientVar: Bool {
        switch type {
        case .mindnote, .slides, .doc, .docX:
            return clientVarMetaDataManagerAPI.getMetaDataRecordBy(objToken).hasClientVar
        case .sheet:
            return hasCachedSheet(objToken)
        case .bitable:
            return hasCachedBitable(objToken)
        case .wiki:
            return wikiRealPreloadKey?.hasClientVar ?? false
        case .file, .wikiCatalog:
            return false
        default:
            spaceAssertionFailure("not supported type")
            return false
        }
    }

    public func needPreload() -> Bool {
        if type == .wiki {
            return wikiRealPreloadKey?.needPreload() ?? false
        }
        if type == .sheet {
            if sheetSSRfg {
                return (!hasClientVar) || (!hasCachedSheetSSR(objToken))
            } else {
                return !hasClientVar
            }
        } else {
            return !hasClientVar
        }
    }
    
    var isTimeOut: Bool {
        if type == .wiki {
            return false
        }
        guard let updateTime = self.clientVarUpdateTime else {
            DocsLogger.info("cant get clientVar pdateTime, need preload", component: LogComponents.preload)
            return true
        }
        let currentTime = Int64(Date().timeIntervalSinceReferenceDate)
        let clientVarUpdateTime: Int64 = Int64(updateTime)
        if (currentTime - clientVarUpdateTime) * 1000 >= OpenAPI.RecentCacheConfig.updateClientvarFrequency {
            return true
        }
        return false
    }

    func savePreloadedData(_ data: [String: Any]) {
        DocsLogger.info("savePreloadedData \(self) cacheFromPreload", component: LogComponents.preload)
        if type == .wiki {
            saveWikiClientVar(data)
        } else {
            newCacheAPI.set(object: data as NSCoding, for: objToken, subkey: clientVarKey, cacheFrom: .cacheFromPreload)
        }
    }

    var toWatermarkKey: WatermarkKey {
        return WatermarkKey(objToken: objToken, type: type.rawValue)
    }

    var fileName: String {
        #if DEBUG
        let tokenNode = TokenStruct(token: objToken)
        let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)
        return dataCenterAPI?.spaceEntry(token: tokenNode)?.name ?? ""
        #else
        return ""
        #endif
    }

    var docxPreloadImages: [[String: Any]]? {
        let clientVarKey = Self.getClientVarKey(type: type)
        guard let clientVars = newCacheAPI.object(forKey: objToken, subKey: clientVarKey) as? [String: Any] else {
            return nil
        }
        guard let data = clientVars["data"] as? [String: Any],
              let preloadImages = data["preloadedImages"] as? [[String: Any]] else {
            return nil
        }
        return preloadImages
    }

    var resources: [String: Any]? {
        return PreloadKey.getClientVarResources(type: wikiRealPreloadKey?.type ?? type,
                                                objToken: objToken,
                                                newCacheAPI: newCacheAPI)
    }

    static func getClientVarResources(type: DocsType,
                                      objToken: FileListDefine.ObjToken,
                                      newCacheAPI: NewCacheAPI) -> [String: Any]? {
        let clientVarKey = Self.getClientVarKey(type: type)
        guard let clientVars = newCacheAPI.object(forKey: objToken, subKey: clientVarKey) as? [String: Any] else {
            return nil
        }
        guard let data = clientVars["data"] as? [String: Any],
              let collabClientVars = data["collab_client_vars"] as? [String: Any],
              let resources = collabClientVars["resources"] as? [String: Any] else {
            return nil
        }
        return resources
    }
    
    var clientVarUpdateTime: TimeInterval? {
        let realKey = wikiRealPreloadKey ?? self
        let realType = realKey.type
        let realToken = realKey.objToken
        let clientVarKey = Self.getClientVarKey(type: realType)
        let recordKey = H5DataRecordKey(objToken: realToken, key: clientVarKey)
        guard let dataRecord = newCacheAPI.getH5RecordBy(recordKey),
                let updateTime = dataRecord.updateTime else {
            DocsLogger.info("clientVar updateTime is nil", component: LogComponents.preload)
            return nil
        }
        return updateTime
    }
    
    var clientVarVersion: Int? {
        guard let data = Self.getClientVarData(type: type,
                                               objToken: objToken,
                                               newCacheAPI: newCacheAPI) else {
            return nil
        }
        switch type {
        case .docX:
            return data["structure_version"] as? Int
        case .doc:
            guard let collabClientVars = data["collab_client_vars"] as? [String: Any] else {
                return nil
            }
            return collabClientVars["rev"] as? Int
        case .bitable:
            guard let snapshot = data["snapshot"] as? [String: Any],
                  let base = snapshot["base"] as? [String: Any] else {
                return nil
            }
            return base["rev"] as? Int
        case .sheet:
            return data["revision"] as? Int
        case .mindnote:
            return data["version"] as? Int
        case .wiki:
            spaceAssertionFailure("should not get/set wikiInfo by clientvar key @peipei, use wikiInfoKey")
            return nil
        default:
            return nil
        }
    }
    static func getClientVarData(type: DocsType,
                                      objToken: FileListDefine.ObjToken,
                                      newCacheAPI: NewCacheAPI) -> [String: Any]? {
        let clientVarKey = Self.getClientVarKey(type: type)
        guard let clientVars = newCacheAPI.object(forKey: objToken, subKey: clientVarKey) as? [String: Any] else {
            return nil
        }
        guard let data = clientVars["data"] as? [String: Any] else {
            return nil
        }
        return data
    }
    
    func setClietVarUpdateTime() {
        let clientVarKey = Self.getClientVarKey(type: type)
        newCacheAPI.setClientVarUpdateTime(forKey: objToken, subKey: clientVarKey)
    }
    
    func fetchDocsVersion(preloadKey: PreloadKey, completion: @escaping(String?, Int?, Error?) -> Void) -> DocsRequest<JSON>? {
        var objList: [[String: Any]] = []
        var obj: [String: Any] = ["type": preloadKey.type.name.uppercased(),
                   "token": preloadKey.objToken]
        if preloadKey.type == .docX {
            obj["resource_type"] = "structure"
        }
        objList.append(obj)
        let params = ["obj_list": objList]
        return DocsRequest<JSON>(path: OpenAPI.APIPath.remoteVersion, params: params)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
            .start(result: { (result, error) in
                DocsLogger.info("get DocVersion result", component: LogComponents.preload)
                guard let json = result,
                        let code = json["code"].int,
                        error == nil else {
                        completion(nil, nil, error)
                        return
                }
                if code == 0 {
                    if let dataDic = json.rawString()?.toDictionary()?["data"] as? [String: Any],
                       let objVersion = dataDic["obj_version"] as? [[String: Any]],
                       objVersion.count > 0,
                        let token = objVersion[0]["token"] as? String,
                        let version = objVersion[0]["version"] as? Int {
                        completion(token, version, nil)
                    } else {
                        DocsLogger.info("get DocVersion is nil")
                        completion(nil, nil, nil)
                    }
                } else {
                    DocsLogger.error("get DocVersion error code: \(code)")
                    completion(nil, nil, nil)
                }
            })
    }
    
    mutating func updatePreloadClientVars(_ isClientVars: Bool) {
        preloadClientVars = isClientVars
    }
    
    mutating func updatePreloadSSR(_ isSSR: Bool) {
        preloadSSR = isSSR
    }
}

// MARK: - Sheet Stuff
extension PreloadKey {
    var shouldPreloadIndependentSheet: Bool {
        return needPreload()
    }

    var independentSheetToken: String? {
        if type == .wiki {
            return wikiRealPreloadKey?.independentSheetToken
        } else {
            return objToken
        }
    }

    var shouldPreloadEmbeddedSheet: Bool {
        if let embeddedSheetToken = embeddedSheetToken, !embeddedSheetToken.isEmpty {
            return !hasCachedSheet(objToken) // 判断 embedded sheet 的存储，要用宿主的 objToken
        } else {
            return false
        }
    }

    var embeddedSheetToken: String? {
        if type == .wiki {
            return wikiRealPreloadKey?.embeddedSheetToken
        } else {
            guard mayContainEmbeddedDataTypes.contains(type), let res = resources else {
                return nil
            }
            if let sheets = res["sheets"] as? [[String: Any]],
                let firstSheet = sheets.first,
                let token = firstSheet["token"] as? String {
                return String(token.split(separator: "_").first ?? "")
            }
            return nil
        }
    }

    func hasCachedSheet(_ objToken: FileListDefine.ObjToken) -> Bool {
        let completeKey = cacheKeyPrefix + "SHEET_DATA_COMPLETE"

        let sheetComplete = newCacheAPI.object(forKey: objToken, subKey: completeKey)
        return (sheetComplete as? Bool) ?? false
    }

    func hasCachedSheetSSR(_ objToken: FileListDefine.ObjToken) -> Bool {
        let renderKey = DocsType.htmlCacheKey
        let ssrKey = cacheKeyPrefix + renderKey
        let sheetSSR = newCacheAPI.object(forKey: objToken, subKey: ssrKey)
        return sheetSSR != nil
    }
}

// MARK: - Bitable Stuff
extension PreloadKey {
    var shouldPreloadIndependentBitable: Bool {
        return !hasCachedBitable(objToken)
    }

    var independentBitableToken: String? {
        if type == .wiki {
            return wikiRealPreloadKey?.independentBitableToken
        } else {
            return objToken
        }
    }

    var shouldPreloadEmbeddedBitable: Bool {
        if let embeddedBitableToken = embeddedBitableToken, !embeddedBitableToken.isEmpty {
            return !hasCachedBitable(objToken) // 判断 embedded bitable 的存储，要用宿主的 objToken
        } else {
            return false
        }
    }

    // 4.8 暂时不会预加载 embedded bitable，后面会上
    var embeddedBitableToken: String? {
        if type == .wiki {
            return wikiRealPreloadKey?.embeddedBitableToken
        } else {
            guard mayContainEmbeddedDataTypes.contains(type), let res = resources else {
                return nil
            }
            if let bitableBlocks = res["bitable"] as? [[String: Any]],
               let firstBitableBlock = bitableBlocks.first,
               let token = firstBitableBlock["token"] as? String {
                return String(token.split(separator: "_").first ?? "")
            }
            return nil
        }
    }

    func hasCachedBitable(_ objToken: FileListDefine.ObjToken) -> Bool {
        let bitableComplete = newCacheAPI.object(forKey: objToken, subKey: clientVarKey)
        return bitableComplete != nil
    }
}

// MARK: - WIKI utils
extension PreloadKey {
    // 使用wikitoken加载完clientVar后，wiki中包含的sheet、图片、投票、评论需要使用wiki对应单品token进行下载
    var wikiRealPreloadKey: PreloadKey? {
        guard type == .wiki else {
            return nil
        }
        guard let wikiInfo = wikiInfo else {
//            spaceAssertionFailure("wiki type preloadKey must have wikiInfo @peipei")
            return nil
        }
        return PreloadKey(objToken: wikiInfo.objToken, type: wikiInfo.docsType)
    }

    // 保存wiki 真正的clientvars
    private func saveWikiClientVar(_ dict: [String: Any]) {
        guard let wikiInfo = wikiInfo else {
            spaceAssertionFailure("wiki type preloadKey must have wikiInfo @peipei")
            return
        }
        var realClientVar = dict
        realClientVar["type"] = wikiInfo.docsType.name.uppercased()
        realClientVar["token"] = wikiInfo.objToken
        newCacheAPI.set(object: realClientVar as NSCoding,
                        for: wikiInfo.objToken, subkey: wikiInfo.docsType.clientVarKey(), cacheFrom: .cacheFromPreload)
    }
}
