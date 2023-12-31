//
//  OpenPlatformLogoutClearRegister.swift
//  TTMicroApp
//
//  Created by ByteDance on 2023/7/4.
//

import LarkClean
import LarkStorage
import OPFoundation
import ECOInfra
import LarkSetting
import LKCommonsLogging

extension CleanRegistry {
    static let opLogger = Logger.oplog(CleanRegistry.self, category: "OpenPlatformCleanRegistry")

    @_silgen_name("Lark.LarkClean_CleanRegistry.OpenPlatform")
    public static func registerOpenPlatformPath() {
        //注册paths
        registerPaths(forGroup: "openPlatform") { ctx in
            let users = ctx.userList
            let models = OPClearManager.shared.clearModels
            opLogger.info("start clear paths models:\(models)")
            let clearModels = models.filter { clearModel in
                clearModel.dataType == 0 || clearModel.dataType == 2
            }
            var paths: [CleanIndex.Path] = []
            for user in users {
                for clearModel in clearModels {
                    let path = fileDataPath(userID: user.userId, tenantID: user.tenantId, appID: clearModel.appID, appType: clearModel.appType.bdpType)
                    paths.append(.abs(path))
                }
            }
            opLogger.info("LarkClean OpenPlatform Paths:\(paths)")
            return paths
        }
        
        //注册tasks
        registerTask(forName: "openPlatform") { ctx, subscriber in
            let users = ctx.userList
            let models = OPClearManager.shared.clearModels
            opLogger.info("start clear task models:\(models)")
            let clearModels = models.filter { clearModel in
                clearModel.dataType == 0 || clearModel.dataType == 1
            }
            var finished  = true
            for user in users {
                for clearModel in clearModels {
                    let result = clearKVData(userID: user.userId, tenantID: user.tenantId, appID: clearModel.appID, appType: clearModel.appType.bdpType)
                    if !result {
                        finished = false
                    }
                }
            }
            opLogger.info("LarkClean OpenPlatform Clean KV finished:\(finished)")
            subscriber.receive(completion: finished ? .finished : .failure(ClearDBError.removeAllFail)) // 通知完成
        }
        
    }
    

    ///获取指定文件路径
    fileprivate static func fileDataPath(userID: String,
                     tenantID: String,
                     appID: String,
                     appType: BDPType) -> String{
        
        let accountToken = OPAccountTokenHelper.accountToken(userID: userID, tenantID: tenantID)
        let manager = BDPLocalFileManager.init(type: appType, accountToken: accountToken)
        let uniqueID = BDPUniqueID(appID: appID, identifier: appID, versionType: .current, appType: appType)
        let sandboxPath = manager.appSandboxPath(with: uniqueID)
        return sandboxPath
    }
    
    ///清除KV
    fileprivate static func clearKVData(userID: String,
                     tenantID: String,
                     appID: String,
                     appType: BDPType) -> Bool{
        
        let accountToken = OPAccountTokenHelper.accountToken(userID: userID, tenantID: tenantID)
        let manager = BDPLocalFileManager.init(type: appType, accountToken: accountToken)
        let uniqueID = BDPUniqueID(appID: appID, identifier: appID, versionType: .current, appType: appType)
        let storagePath = manager.appStorageFilePath(with: uniqueID)

        //KV的擦除不能直接删除KV存储所用的db文件，db中包含多个表，只删除KV对应的表
        if LSFileSystem.fileExists(filePath: storagePath),
           let db = TMAKVDatabase(dbWithPath: storagePath),
           let store = db.storage(forName: "local_storage"){
            let result = store.removeAllObjects()
            opLogger.info("LarkClean OpenPlatform KV clean, storagePath:\(storagePath), result:\(result)")
            return result
        }
        opLogger.info("LarkClean OpenPlatform KV fileNotExists, storagePath:\(storagePath)")
        return true
    }

}

public enum ClearAppType {
    case gadget
    case webApp
    var bdpType: BDPType {
        switch self {
        case .gadget:
            return BDPType.gadget
        case .webApp:
            return BDPType.webApp
        }
    }
}

enum ClearDBError: Error {
    case removeAllFail
}

public struct ClearAPPModel {
    let appID: String
    let appType: ClearAppType
    let dataType: Int
    init(appID: String, appType: ClearAppType, dataType: Int) {
        self.appID = appID
        self.appType = appType
        self.dataType = dataType
    }
}

public final class OPClearManager{
    public static let shared: OPClearManager = OPClearManager()
    public var clearModels:[ClearAPPModel] = []
    
    public func setUpClearModels(){
        clearModels = getSettingsClearAPPModels()
    }
    
    private func getSettingsClearAPPModels() -> [ClearAPPModel] {
       do {
           let config: [String: Any] = try SettingManager.shared.setting(with: "openplatform_clear_data")
           guard let appConfig = config["appConfig"] as? [String: Any] else {
               return []
           }
           let array:[ClearAPPModel] = []
           let result = appConfig.reduce(array) { partialResult, dict in
               var temp = partialResult
               let appID = dict.key
               guard let value = dict.value as? [String: Any] else {
                   return temp
               }
               guard let appTypes = value["app_type"] as? [String] else {
                   return temp
               }
               guard let dataType = value["data_type"] as? Int else {
                   return temp
               }
               if appTypes.contains("gadget") {
                   temp.append(ClearAPPModel(appID: appID, appType: .gadget, dataType: dataType))
               }
               if appTypes.contains("webapp") {
                   temp.append(ClearAPPModel(appID: appID, appType: .webApp, dataType: dataType))
               }
               return temp
           }
           return result
       } catch {
           return []
       }
   }
    
}
