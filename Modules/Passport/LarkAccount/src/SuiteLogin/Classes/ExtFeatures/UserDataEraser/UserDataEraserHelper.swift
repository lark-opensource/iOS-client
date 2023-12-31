//
//  UserDataEraserService.swift
//  LarkAccount
//
//  Created by ByteDance on 2023/7/4.
//

import Foundation
import LarkAccountInterface
import LarkClean
import LKCommonsLogging
import LarkSetting

struct UserDataEraseError: Error {
    let errorCodes: [Int]
}

class UserDataEraserHelper {

    static let shared = UserDataEraserHelper()

    private static let logger = Logger.log(UserDataEraserHelper.self, category: "UserDataEraserHelper")
    //数据擦除失败重试次数
    let cleanRetryCount: Int = 3
    //数据擦除擦除用户数限制
    let cleanUserLimit: Int = 100

    //数据擦除云控配置(追加擦除的path 和 统一存储 kv)
    fileprivate static var eraseSettings: [String: Any]?

    //数据擦除需要擦除的user
    lazy var userScopeList: [EraseUserScope] = PassportStore.eraseUserValue(key: PassportStore.PassportStoreKey.eraseUserScopeListKey) ?? [] {
        didSet {
            PassportStore.eraseUserSet(key: PassportStore.PassportStoreKey.eraseUserScopeListKey, value: userScopeList)
        }
    }

    //数据擦除任务标识，擦除失败重启后需要使用此标识继续擦除任务
    private var cleanTaskIdentifier: String? {
        get {
            PassportStore.eraseUserValue(key: PassportStore.PassportStoreKey.eraseTaskIdentifier)
        }
        set {
            PassportStore.eraseUserSet(key: PassportStore.PassportStoreKey.eraseTaskIdentifier, value: newValue)
        }
    }

    //重启app是否需要继续数据擦除
    public func needEraseDataForBootup() -> Bool {
        guard let identifier = cleanTaskIdentifier else {
            return false
        }
        return Cleaner.shared.needsResume(withIdentifier: identifier)
    }

    //执行数据擦除
    public func startEraseTask(progress: @escaping (Float) -> Void, callback: @escaping (Result<Void,UserDataEraseError>) -> Void) {
        //转换成Clean的数据模型
        let cleanUserDataList = userScopeList.compactMap { scope in
            CleanContext.User(userId: scope.userID, tenantId: scope.tenantID)
        }

        Self.logger.info("n_action_user_data_erase_user_list", body: "\(cleanUserDataList)")

        let cleanContext = CleanContext(userList: cleanUserDataList)
        cleanTaskIdentifier = Cleaner.shared.start(withContext: cleanContext, retryCount: cleanRetryCount, handler: {[weak self] event in
            SuiteLoginUtil.runOnMain {
                self?.transformCallback(cleanerEvent: event, progress: progress, callback: callback)
            }
        })
    }

    //resume 数据擦除
    public func resumeEraseTask(progress: @escaping (Float) -> Void, callback: @escaping (Result<Void,UserDataEraseError>) -> Void) {

        guard let identifier = cleanTaskIdentifier else {
            Self.logger.info("n_action_user_data_erase_succ", body: "no identifier")
            //如果没有要恢复清理的擦除任务，当做succ
            callback(.success(()))
            return
        }

        Cleaner.shared.resume(withIdentifier: identifier) {[weak self] event in
            SuiteLoginUtil.runOnMain {
                self?.transformCallback(cleanerEvent: event, progress: progress, callback: callback)
            }
        }
    }

    //取消数据擦除
    public func cancelEraseTask() {

        guard let identifier = cleanTaskIdentifier else {
            Self.logger.info("n_action_user_data_erase_skip_cancel", body: "no identifier")
            return
        }

        Cleaner.shared.cancel(withIdentifier: identifier)
        //取消擦除任务只清理擦除的task，不清空记录的历史需要擦除的uid
        resetEraseTaskIdentifier()
    }

    //重置数据
    public func resetAllData(_ callback: @escaping (Bool) -> Void) {
        Self.logger.info("n_action_user_data_erase_reset_data")

        Cleaner.shared.deepClean(with: {[weak self] result in
            Self.logger.info("n_action_user_data_erase_reset_data_result", body: "\(result)")
            SuiteLoginUtil.runOnMain {
                callback(result)
                if result {
                    //只有重置成功才清除记录的所有需要擦除的uid
                    self?.resetEraseUserList()
                }
            }
        })
        //重置后即使失败也不会再尝试擦除，清空擦除
        resetEraseTaskIdentifier()
    }

    private func transformCallback(cleanerEvent: Cleaner.Event, progress: @escaping (Float) -> Void, callback: @escaping (Result<Void,UserDataEraseError>) -> Void) {
        SuiteLoginUtil.runOnMain {
            switch cleanerEvent {
            case .begin(total: _):
                Self.logger.info("n_action_user_data_erase_start")
            case .progress(let ratio):
                progress(ratio)
            case .end(result: let result):
                switch result {
                case .success(_):
                    Self.logger.info("n_action_user_data_erase_succ")
                    //擦除完成，清空需要擦除的user信息和擦除任务
                    self.resetEraseUserList()
                    self.resetEraseTaskIdentifier()
                    callback(.success(()))
                case .failure(let error):
                    Self.logger.error("n_action_user_data_erase_fail", error: error)
                    callback(.failure(UserDataEraseError(errorCodes: error.errorCodes)))
                }
            @unknown default:
                Self.logger.info("n_action_user_data_erase", body: "unknown default")
            }
        }
    }

    private func resetEraseTaskIdentifier() {
        cleanTaskIdentifier = nil
    }

    private func resetEraseUserList() {
        userScopeList = []
    }

    private init() {}
}

extension UserDataEraserHelper: LauncherDelegate {
    var name: String { "UserDataEraserHelper" }

    func beforeLogout(conf: LogoutConf) {

        guard conf.type == .all else {
            return
        }
        //这里不判断FG是否开启，都记录
        Self.eraseSettings = try? SettingManager.shared.setting(with: "lark_security_logout_all_eraser_dynamic")
    }

    func logoutUserList(by userIDs: [String]) {
        //这里不判断FG是否开启，都记录
        let newEraseUserScopeList = userIDs.compactMap { userID in
            if let userInfo = UserManager.shared.getUser(userID: userID) {
                return EraseUserScope(userID: userInfo.userID, tenantID: userInfo.user.tenant.id)
            }
            return nil
        }

        //去重更新
        userScopeList = (userScopeList + newEraseUserScopeList).uniqued({ item in
            item.userID
        })

        //超过限制个数，删除超限数据（从旧数据开始删除）
        if userScopeList.count > cleanUserLimit {
            userScopeList.removeSubrange((0..<(userScopeList.count - cleanUserLimit)))
        }
    }
}

extension CleanRegistry {

    @_silgen_name("Lark.LarkClean_CleanRegistry.Passport")
    public static func registerCleanIndexesFromSettings() {
        CleanRegistry.registerIndexes(forGroup: "RemoteSetting") { context in
            // 1.get setting config
            let config: [String: Any]
            #if DEBUG || BETA || ALPHA
            //1、正式版本 eraseSettings获取在登出的时候，beforeLogout()
            //2、QA 可能在debug菜单中打开注册路径的收集，此时需要实时获取下settings配置
            let settings = (try? SettingManager.shared.setting(with: "lark_security_logout_all_eraser_dynamic")) ?? [:]
            config = UserDataEraserHelper.eraseSettings ?? settings
            #else
            //这里不兜底默认配置的原因，担心默认配置出现异常时，可能还有部分流量走到了异常数据
            config = UserDataEraserHelper.eraseSettings ?? [:]
            #endif
            // 2. parse setting to [CleanIndex]
            return CleanRegistry.parseIndexes(with: config, context: context)
        }
    }
}
