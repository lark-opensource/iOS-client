//
//  BDPPreRunManager.swift
//  TTMicroApp
//
//  Created by ChenMengqi on 2022/11/16.
//

import Foundation
import LKCommonsLogging
import ECOInfra
import ECOProbe
import OPFoundation
import LKCommonsTracker

private let kGadgetPreRunNotificationName = "kGadgetPreRunNotificationName"
private let kLogPrefix = "[PreRun] BDPPreRunManager "

@objc public final class BDPPreRunManager: NSObject {
    private let log = Logger.oplog(BDPPreRunManager.self, category: "BDPPreRunManager")
    private var isAddNoti = false
    private var cacheModel: BDPPreRunCacheModel?
    var timer: Timer?
    private let lock = NSLock()

    @objc public static let sharedInstance: BDPPreRunManager = BDPPreRunManager()

    @objc public func startPreRunMonitor(){
        guard let settings = settings else {
            log.warn("\(kLogPrefix)openplatform_gadget_prerun is empty")
            return
        }
        log.info("\(kLogPrefix)openplatform_gadget_prerun settings value is \(settings)")
        if(!enablePreRun){
            return
        }
        if(isAddNoti){
            //避免切租户反复监听
            return
        }
        NotificationCenter.default.addObserver(self, selector: #selector(self.triggerPreRun), name: NSNotification.Name(rawValue: kGadgetPreRunNotificationName), object: nil)
        NotificationCenter.default.addObserver(self,selector: #selector(self.didReceiveMemoryWarning),name:UIApplication.didReceiveMemoryWarningNotification,object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.willTerminate), name: UIApplication.willTerminateNotification, object: nil)
        
        isAddNoti = true
    }

    @objc public func cacheModel(for uniqueID: OPAppUniqueID) -> BDPPreRunCacheModel? {
        guard cacheModel?.uniqueID.fullString == uniqueID.fullString else {
            log.info("\(kLogPrefix) can not get cacheModel for \(uniqueID.appID)")
            return nil
        }

        return cacheModel
    }
    
    deinit {
        cancelTimer()
    }
}

 
extension BDPPreRunManager {
    @objc private func triggerPreRun(_ noti: NSNotification){
        let startMonitor = OPMonitor("op_gadget_prerun_start")
        startMonitor.addCategoryValue("prerun_scene", noti.userInfo?["scenes"] ?? "")
        startMonitor.addCategoryValue("appid", noti.userInfo?["appid"] ?? "")
        startMonitor.flush()
        
        let resultMonitor = OPMonitor("op_gadget_prerun_result")
        if self .checkEnablePreRun(resultMonitor: resultMonitor) == false {
            return
        }
        if self.checkIfTooOfen(resultMonitor: resultMonitor) == true {
            return
        }
        if OPGadgetDRManager.shareManager.isDRRunning(){
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(delayTime)) {
            if self.checkIfIsBackground(resultMonitor: resultMonitor) == true {
                return
            }
            let globalQueue = DispatchQueue.global(qos: .default)
            globalQueue.async {
                self.lock.lock()
                defer {
                    self.lock.unlock()
                }
                let userInfo = noti.userInfo
                guard let prerunAppid = userInfo?["appid"] as? String,
                      prerunAppid != self.cacheModel?.appID else {
                    self.log.info("\(kLogPrefix) will not run, because appid \(String(describing: self.cacheModel?.appID)) is the same")
                    resultMonitor.setResultType(BDPPreRunFailedReason.triggerSameAppid.rawValue)
                    resultMonitor.flush()
                          return

                      }
                guard let scenes = userInfo?["scenes"] as? [Int] else {
                    self.log.info("\(kLogPrefix) will not run, because scene is not match [Int])")
                    resultMonitor.setResultType(BDPPreRunFailedReason.sceneDisable.rawValue)
                    resultMonitor.addCategoryValue("appid", prerunAppid)
                    resultMonitor.flush()
                    return
                }
                
                var sceneIsEnable = false
                for scene in scenes {
                    if self.enableCacheScene.contains(scene) {
                        sceneIsEnable = true
                        break
                    }
                }

                if sceneIsEnable == false {
                    self.log.info("\(kLogPrefix) will not run, because scene is not hit \(self.enableCacheScene)")
                    resultMonitor.setResultType(BDPPreRunFailedReason.sceneDisable.rawValue)
                    resultMonitor.addCategoryValue("appid", prerunAppid)
                    resultMonitor.flush()
                    return
                }

                if self.checkIfTooOfen(resultMonitor: resultMonitor) == true{
                    return
                }
                let openTimes = LaunchInfoAccessorFactory.launchInfoAccessor(type: .gadget)?.queryUsedOpenInDays(appid: prerunAppid, days: self.searchTime, scenes: scenes)
                if openTimes == false {
                    resultMonitor.setResultType(BDPPreRunFailedReason.notOpenInTime.rawValue)
                    resultMonitor.addCategoryValue("prerun_scene", scenes)
                    resultMonitor.addCategoryValue("appid", prerunAppid)
                    resultMonitor.flush()
                    return
                }
                //需要预prerun新的应用时,老的缓存上报一次replace失败(如果埋点还未上报的话)
                self.reportCacheModalFailMonitor(.cacheReplaced)
                // 替换当前的cacheModal对象
                self.cacheModel = BDPPreRunCacheModel(prerunAppid, prerunScene: scenes)

                self.cacheModel?.startPreRunGadgetFile()

                self.startTimer()
            }
        }
    }
    
    @objc private func didReceiveMemoryWarning(_ noti: NSNotification){
        log.info("\(kLogPrefix) clean all cache because of didReceiveMemoryWarning")
        reportCacheModalFailMonitor(.memoryWarning)
        cleanAllCache()
    }
    
    @objc private func didEnterBackground(_ noti: NSNotification){
        if(!shouldCleanAfterBackground){
            log.info("\(kLogPrefix) not clean all cache when didEnterBackground")
            return ;
        }
        log.info("\(kLogPrefix) clean all cache because of didEnterBackground")
        if(cacheModel == nil){
            return ;
        }
        reportCacheModalFailMonitor(.larkBackground)
        cleanAllCache()
    }
    
    @objc private func willTerminate(_ noti: NSNotification){
        log.info("\(kLogPrefix) clean all cache because of willTerminate")
        reportCacheModalFailMonitor(.larkTerminal)
        cleanAllCache()
    }

    public func cleanAllCacheByDR(){
        log.info("\(kLogPrefix) clean all cache because of DR")
        cleanAllCache()
        reportCacheModalFailMonitor(.DRClean)
    }

    @objc public func cleanAllCache(){
        lock.lock(); defer { lock.unlock() }
        self.cacheModel = nil
        //TODO worker & render
    }
    
}

// 埋点上报
extension BDPPreRunManager {
    public func reportCacheModalFailMonitor(_ reason: BDPPreRunFailedReason) {
        guard let cacheModel = cacheModel else {
            return
        }

        cacheModel.addFailedReasonAndReport(reason.rawValue)
    }

    public func reportCacheModalResultMonitor() {
        guard let cacheModel = cacheModel else {
            return
        }

        cacheModel.reportMonitorResult()
    }
}


//timer 每隔5min检查一次是否要将缓存清理
extension BDPPreRunManager{
    private func startTimer() {
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
        let timeout: TimeInterval = 60 * 5
        let timerTemp = Timer(timeInterval: timeout, repeats: true, block: { [weak self] _ in
            guard let self = self else { return }
            if(self.checkIfCacheIsExpired()){
                self.reportCacheModalFailMonitor(.cacheTimeout)
                self.cleanAllCache()
                self.cancelTimer()
            }
        })
        RunLoop.main.add(timerTemp, forMode: .common)
        timerTemp.fire()
        timer = timerTemp
    }
    
    private func checkIfCacheIsExpired() -> Bool {
        let currentTime = CACurrentMediaTime()
        let lastCacheTime = cacheModel?.startTime ?? 0
        return Int(currentTime - lastCacheTime) > self.maxCacheTime
    }
    
    private func cancelTimer() {
        timer?.invalidate()
        timer = nil
    }
}


// check 各类条件
extension BDPPreRunManager {
    private func checkEnablePreRun(resultMonitor: OPMonitor) -> Bool{
        if !enablePreRun {
            log.info("\(kLogPrefix) will not run, because enablePreRun is \(enablePreRun)")
            resultMonitor.setResultType(BDPPreRunFailedReason.settingsDisable.rawValue)
            resultMonitor.flush()
            return false
        }
        return true
    }
    
    private func checkIfTooOfen(resultMonitor: OPMonitor) -> Bool{
        let lastCacheTime = self.cacheModel?.startTime ?? 0
        let currentGapTime = CACurrentMediaTime() - lastCacheTime
        if Int(currentGapTime) < self.cacheTimeThreshold {
            self.log.info("\(kLogPrefix) will not run, because gap is less than \(self.cacheTimeThreshold)")
            resultMonitor.setResultType(BDPPreRunFailedReason.triggerTooOften.rawValue)
            resultMonitor.flush()
            return true
        }
        return false
    }
    
    private func checkIfIsBackground(resultMonitor: OPMonitor) -> Bool{
        if UIApplication.shared.applicationState == .background {
            resultMonitor.setResultType(BDPPreRunFailedReason.larkIsAlreadyBackground.rawValue)
            resultMonitor.flush()
            self.log.info("\(kLogPrefix) will not run, because lark is background")
            return true
        }
        return false
    }

}



//配置
extension BDPPreRunManager {
    
    @objc public var preRunABtestHit:Bool{
        var gadget_prerun_abvalue = 0
        if let gadget_prerun = Tracker.experimentValue(key: "gadget_prerun", shouldExposure: true) as? Int {
            gadget_prerun_abvalue = gadget_prerun
        }
        if gadget_prerun_abvalue == 2 {
            return true
        } else if gadget_prerun_abvalue == 1{
            return false
        } else {
            log.warn("\(kLogPrefix) use defaulse value \(gadget_prerun_abvalue)")
            return false
        }
    }
    
    private var settings: [String: Any]? {
        guard let s = ECOConfig.service().getLatestDictionaryValue(for: "openplatform_gadget_prerun") else {
            return nil
        }
        return s
    }
    
    @objc public var enablePreRun: Bool {
        guard let s = settings, let enable = s["enable"] as? Bool else {
            return false
        }
        return enable
    }
    
    private var delayTime : Int {
        guard let s = settings, let delayTime = s["delayTime"] as? Int else {
            return Int.max
        }
        return delayTime
    }

    //搜索该小程序使用时间，决定是否预加载，单位 天
    private var searchTime : Int {
        guard let s = settings, let searchTime = s["searchTime"] as? Int else {
            return 30
        }
        return searchTime
    }
    
    //最小缓存变更间隔时间，单位 秒，避免快速滑动消息卡片，反复更新
    private var cacheTimeThreshold : Int {
        guard let s = settings, let cacheTimeThreshold = s["cacheTimeThreshold"] as? Int else {
            return 60
        }
        return cacheTimeThreshold
    }
    
    //最大缓存时间，单位 秒
    private var maxCacheTime : Int {
        guard let s = settings, let maxCacheTime = s["maxCacheTime"] as? Int else {
            return 60*5
        }
        return maxCacheTime
    }
    
    //允许pre run的场景
    private var enableCacheScene : [Int] {
        guard let s = settings, let enbaleCacheScene = s["enbaleCacheScene"] as? [Int] else {
            return []
        }
        return enbaleCacheScene
    }
    
    //是否允许后台情况下被回收
    private var shouldCleanAfterBackground: Bool {
        guard let s = settings, let shouldCleanAfterBackground = s["shouldCleanAfterBackground"] as? Bool else {
            return false
        }
        return shouldCleanAfterBackground
    }

}
