import Foundation
import LarkAssembler
import LKStatisticsExternal
import LKCommonsLogging
import LarkLocalizations
import RangersAppLog
import Swinject
import LarkReleaseConfig

public class LKStatisticsExternalAssembly: LarkAssemblyInterface {
    public init() { KAStatisticsExternal.shared.statistics = KAStatisticsImpl.shared }
}

final class KAStatisticsImpl {
    private enum UserType {
        case lark
        case external
    }
    
    public static let shared = KAStatisticsImpl()
    
    private let serialQueue = DispatchQueue(label: "ka.tracker.queue", qos: .background)
    private let logger = Logger.log(KAStatisticsImpl.self, category: "Module.KAStatistics")
    private var userType = UserType.lark
    private var currentLarkUserID: String? { didSet { userType == .lark ? tracker?.setCurrentUserUniqueID(currentLarkUserID) : nil } }
    private var tracker: BDAutoTrack?

    private init() {}
}

extension KAStatisticsImpl: KAStatisticsProtocol {
    func initConfig(appId: String, registerHost: String, appLogHost: String, commonParams: [String: AnyHashable]) {
        let config = BDAutoTrackConfig(appID: appId)
        config.serviceVendor = .private
        config.channel = commonParams["channel"] as? String ??
        (ReleaseConfig.isKA ? ReleaseConfig.kaChannelForAligned : ReleaseConfig.channelName)
        config.monitorEnabled = false
        config.autoFetchSettings = false
        config.abEnable = commonParams["abSwitch"] as? Bool ?? false
        config.screenOrientationEnabled = true
        #if ENABLE_UITRACKER
        config.autoTrackEnabled = commonParams["autoTrackdSwitch"] as? Bool ?? false
        #endif
        #if ENABLE_SM2
        if commonParams["GMEncryptSwitch"] as? Bool ?? false, let publicKey = commonParams["publicKey"] as? String {
            config.encryptionType = .cstcSM2
            BDAutoTrackEncryptorSM2.setPublickKey(publicKey)
        }
        #endif
        if commonParams["isDebug"] as? Bool ?? false {
            config.logNeedEncrypt = false
            config.showDebugLog = true
            config.logger = { [weak self] in self?.logger.info($0 ?? "") }
        }
        
        tracker = BDAutoTrack(config: config)
        tracker?.setFilterEnable(true)
        tracker?.setAppLauguage(commonParams["appLauguage"] as? String ?? LanguageManager.currentLanguage.localeIdentifier)
        tracker?.setAppRegion(commonParams["appRegion"] as? String ?? LanguageManager.currentLanguage.regionCode)
        tracker?.setRequestHostBlock {
            let host = ($1 == .urlRegister ? registerHost : appLogHost)
            return host.hasPrefix("http") ? host : "https://" + host
        }
        tracker?.setCustomHeaderBlock { commonParams["customHeader"] as? [String: AnyHashable] ?? [:] }
        userType = commonParams.keys.contains("user_unique_id") ? .external : .lark
        tracker?.setCurrentUserUniqueID(commonParams["user_unique_id"] as? String ?? currentLarkUserID)
        tracker?.start()
        logger.info("KA---Watch: set tracker for appID: \(appId), registerHost: \(registerHost), appLogHost: \(appLogHost), commonParams: \(commonParams)")
    }
    
    func sendEvent(name: String) { serialQueue.async { self.tracker?.eventV3(name, params: [:]) } }
    
    func sendEvent(name: String, params: [String: String]) { serialQueue.async { self.tracker?.eventV3(name, params: params) } }
}
