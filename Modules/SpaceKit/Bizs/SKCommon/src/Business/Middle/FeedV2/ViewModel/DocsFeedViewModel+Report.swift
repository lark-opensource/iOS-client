//
//  DocsFeedViewModel+Report.swift
//  SKCommon
//
//  Created by huayufan on 2021/6/18.
//  


import RxSwift
import RxCocoa
import SKFoundation

enum FeedTimeStage: String, CaseIterable {
    
    // Feed面板外部部生命周期
    
    case larkFeed
    
    case beforeEditorOpen
    
    case makeEditorEnd
    
    case registerServices
    
    case controllerInit
    
    case willOpenFeed
    
    // Feed面板内部生命周期
    
    /// 创建Feed面板
    case create
    
    /// 接收到前端数据
    case receiveFrontend
    
    /// 对前端数据序列化完成
    case deserialize
    
    case viewDidAppear
    
    /// 缓存加载成功
    case cacheLoad
    
    case renderBegin
    
    case renderEnd
}

extension DocsFeedViewModel {
    
    func checkExternalStage() {
        if let time = from.getTimestamp(with: .larkFeed) {
            timeStamp[.larkFeed] = time
        }
        if let time = from.getTimestamp(with: .beforeEditorOpen) {
            timeStamp[.beforeEditorOpen] = time
        }
        
        if let time = from.getTimestamp(with: .makeEditorEnd) {
            timeStamp[.makeEditorEnd] = time
        }
        if let time = from.getTimestamp(with: .controllerInit) {
            timeStamp[.controllerInit] = time
        }
        if let time = from.getTimestamp(with: .openPanel) {
            timeStamp[.willOpenFeed] = time
        }
        
        if let time = from.getTimestamp(with: .registerServices) {
            timeStamp[.registerServices] = time
        }
        
    }
    
    /// 返回[from,to]之间的时间
    func getStageTime(from: FeedTimeStage, to: FeedTimeStage) -> TimeInterval {
        guard let left = timeStamp[from],
              let right = timeStamp[to] else {
            return -1
        }
        return right - left
    }
    
    func record(stage: FeedTimeStage) {
        if timeStamp[stage] == nil { // 以第一次为准
           timeStamp[stage] = Date().timeIntervalSince1970 * 1000
        }
        switch stage {
        case .viewDidAppear:
            DocsTracker.log(enumEvent: .viewDocsmessagePage,
                            parameters: ["file_id": DocsTracker.encrypt(id: docsInfo.objToken)])
        default:
            break
        }
       
    }
    
    func recordTimeout(_ seconds: Int = 20) {
        Observable.just(())
                  .delay(RxTimeInterval
                  .seconds(seconds), scheduler: MainScheduler.instance)
                  .subscribe(onNext: { [weak self] (_) in
            self?.status = .timeout
            self?.timeDisposeBag = DisposeBag()
        }).disposed(by: timeDisposeBag)
    }
    
    func report(status: FeedOpenStatus) {
        let tracker = DocFeedPanelTracker()
        tracker.report(event: .timeRecord(store: timeStamp), openStatus: status, docsInfo: docsInfo, fromInfo: from)
    }
    
    func reportMuteClick(_ isMute: Bool) {
        let params: [String: Any] = ["click": isMute ? "mute" : "remind",
                                     "target": "none"]
        DocsTracker.newLog(enumEvent: .feedMuteClick, parameters: params)
    }
    
    func reportCleanMessageClick() {
        let params: [String: Any] = ["click": "read_all",
                                     "target": "none"]
        DocsTracker.newLog(enumEvent: .feedMuteClick, parameters: params)
    }
    
    func debugReport() {
        #if DEBUG
        let tracker = DocFeedPanelTracker()
        tracker.debugInfo(event: .timeRecord(store: timeStamp))
        #endif
    }
}
