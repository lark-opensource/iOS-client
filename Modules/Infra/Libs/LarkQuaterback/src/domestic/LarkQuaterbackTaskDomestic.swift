import Foundation
import Quaterback
import LarkAccountInterface
import LarkReleaseConfig
import LKCommonsTracker
import Swinject
import LarkContainer
import LarkFeatureGating
import LarkSetting

let LARKQUATERBACKEVENTNAME: String = "lark_quater_back"

public final class Quaterback: NSObject {

    public static let shared = Quaterback()

    @InjectedSafeLazy var deviceService: DeviceService // Global

    var fetchSignal: DispatchSemaphore?
    var syncFetchBandagesResult: DispatchTimeoutResult?

    override init() {
        super.init()
        configure(delegate: self)
    }

    func configure(delegate: BDQBDelegate?) {
        // 用于存储 FG 值，不做统一存储检查
        // lint:disable:next lark_storage_check
        if UserDefaults.standard.bool(forKey: "messenger.hotpatch.quaterback") {
            return
        }

        let conf = BDBDConfiguration()
        let getDeviceIdBlock: () -> String = { [unowned self] () -> String in
            return self.deviceService.deviceId
        }
        conf.getDeviceIdBlock = getDeviceIdBlock
        conf.aid = ReleaseConfig.appId
        conf.channel = ReleaseConfig.channelName
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let buildVersion = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String ?? ""
        let versionStr = "V\(appVersion)-\(buildVersion)"
        conf.appVersion = versionStr
        conf.distArea = BDDYCDeployArea.CN
        conf.appBuildVersion = versionStr
        // lint:disable:next lark_storage_check
        if UserDefaults.standard.bool(forKey: "messenger.hotpatch.ttnet") {
            conf.requestType = kBDBDMainRequestType.bdbdMainRequestTypeTTNet
        } else {
            conf.requestType = kBDBDMainRequestType.bdbdMainRequestTypeNSURLSession
        }
        var enableLog = false
        #if DEBUG
        enableLog = true
        #endif
        // let logConf = BDBDLogConfiguration()
        // logConf.enableModInitLog = enableLog
        // logConf.enablePrintLog = enableLog
        // logConf.enableInstExecLog = enableLog
        // logConf.enableInstCallFrameLog = enableLog
        // 设置是否输出log到console
        // BDBDMain.shared().logConf = logConf
        NotificationCenter.default.addObserver(self, selector: #selector(fetchListFinished(_:)), name: NSNotification.Name("kBetter_did_fetch_list"), object: nil)
        BDBDMain.start(with: conf, delegate: self)
        trackMetric(metric: .quaterbackInit)
    }

    func configFg(fg: FeatureGatingService) {
        let quaterbackFG = fg.staticFeatureGatingValue(with: "messenger.hotpatch.quaterback")
        let ttnetFG = fg.staticFeatureGatingValue(with: "messenger.hotpatch.ttnet")
        // lint:disable lark_storage_check
        UserDefaults.standard.set(quaterbackFG, forKey: "messenger.hotpatch.quaterback")
        UserDefaults.standard.set(ttnetFG, forKey: "messenger.hotpatch.ttnet")
        // lint:enable lark_storage_check
    }

    // 同步的方式拉取内容，仅安全模式调用
    public func syncFetchBandages() {
        trackMetric(metric: .fetchManually)

        fetchSignal = DispatchSemaphore(value: 0)
        BDBDMain.fetchBandages()
        syncFetchBandagesResult = fetchSignal?.wait(timeout: .now() + 10)

        if syncFetchBandagesResult == .timedOut {
            trackMetric(metric: .fetchTimeout)
        }
    }

}

extension Quaterback: BDQBDelegate {

    @objc
    public func fetchListFinished(_ notification: Notification) {
        // 非安全模式触发逻辑，无打点操作
        guard let fetchSignal = fetchSignal else {
            return
        }

        guard let fetchInfo = notification.object as? [String: Any] else {
            return
        }

        guard let downloadStatusNum = fetchInfo["bd_better_list_download_status_monitor"] as? NSNumber,
              let downloadStatus = kBDQuaterbackListDowmLoadStatus(rawValue: downloadStatusNum.intValue) else {
            return
        }

        if downloadStatus == .bdQuaterbackListDowmLoadStatusSuccessAndPatchListNotEmpty {
            trackMetric(metric: .fetchListSuccess)
        } else if downloadStatus == .bddQuaterbackListDowmLoadStatusUnKnow || downloadStatus == .bdQuaterbackListDowmLoadStatusError {
            trackMetric(metric: .fetchListFailed)
        }

        if downloadStatus != .bdQuaterbackListDowmLoadStatusSuccessAndPatchListNotEmpty {
            fetchSignal.signal()
        }
    }

    public func moduleData(_ aModule: Any?, didFetchWithError error: Error?) {
        // 非安全模式触发逻辑，无打点操作
        guard let fetchSignal = fetchSignal else {
            return
        }

        defer {
            fetchSignal.signal()
        }

        // time out 的情况
        if let syncFetchBandagesResult = syncFetchBandagesResult {
            return
        }

        if error == nil {
            trackMetric(metric: .fetchSuccess)
        } else {
            trackMetric(metric: .fetchFailed)
        }
    }

}

extension Quaterback {
    enum LQTrackerMetric: String {
        case quaterbackInit = "lark_quater_back_init"
        case fetchManually = "lark_quater_back_fetch_manually"
        case fetchSuccess = "lark_quater_back_fetch_manually_success"
        case fetchSuccessWithDid = "lark_quater_back_fetch_manually_success_with_did"
        case fetchFailed = "lark_quater_back_fetch_manually_failed"
        case fetchTimeout = "lark_quater_back_fetch_manually_timeout"
        case fetchListSuccess = "lark_quater_back_fetch_list_manually_success"
        case fetchListFailed = "lark_quater_back_fetch_list_manually_failed"
    }

    func trackMetric(metric: LQTrackerMetric) {
        DispatchQueue.global().async {
            Tracker.post(SlardarEvent(name: LARKQUATERBACKEVENTNAME,
                                      metric: [metric.rawValue: "1"],
                                      category: [:],
                                      extra: [:],
                                      immediately: true))
        }
    }

}
