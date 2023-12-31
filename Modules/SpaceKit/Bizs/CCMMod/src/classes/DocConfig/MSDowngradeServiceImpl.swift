//
//  MSDowngradeServiceImpl.swift
//  CCMMod
//
//  Created by ByteDance on 2023/12/17.
//

import Foundation
import SKFoundation
import LarkContainer
import RxSwift
import RxCocoa
import SpaceInterface
import LKCommonsLogging
#if ByteViewMod
import ByteViewInterface
#endif

final class MSDowngradeServiceImpl {
    
    private let logger = Logger.log(MSDowngradeServiceImpl.self, category: "Module.Docs")
    
    private let userResolver: LarkContainer.UserResolver
    
    #if ByteViewMod
    private var meetingService: MeetingService? {
        return try? userResolver.resolve(assert: MeetingService.self)
    }
    #endif
    
    // 会议数据变化监听器
    #if ByteViewMod
    private var meetingObserver: MeetingObserver?
    #endif
    
    private var currentInfo: CCMMagicSharePerfInfo?
    
    private let subject = PublishSubject<CCMMagicSharePerfInfo>()
    
    init(userResolver: LarkContainer.UserResolver) {
        self.userResolver = userResolver
        guard UserScopeNoChangeFG.CS.msDowngradeNewStrategyEnable else {
            return
        }
        #if ByteViewMod
        if let obs = meetingService?.createMeetingObserver() {
            logger.info("createMeetingObserver")
            self.meetingObserver = obs
            self.meetingObserver?.setDelegate(self)
        } else {
            logger.info("createMeetingObserver failed, has meetingService:\(meetingService != nil)")
        }
        #endif
    }
}

extension MSDowngradeServiceImpl: CCMMagicShareDowngradeService {
    
    var currentPerfInfo: CCMMagicSharePerfInfo? { currentInfo }
    
    var perfInfoObservable: Observable<CCMMagicSharePerfInfo> { subject.asObservable() }
    
    func startMeeting() {
        #if ByteViewMod
        if let meeting = meetingService?.currentMeeting {
            logger.info("get meeting perfInfo in startMeeting")
            self.currentInfo = getPerfInfoWithMeetting(meeting)
        }
        #endif
    }
    
    func stopMeeting() {
        currentInfo = nil
    }
}

#if ByteViewMod
extension MSDowngradeServiceImpl: MeetingObserverDelegate {
    
    func meetingObserver(_ observer: ByteViewInterface.MeetingObserver, 
                         meetingChanged meeting: ByteViewInterface.Meeting,
                         oldValue: ByteViewInterface.Meeting?) {
        let ccmInfo = getPerfInfoWithMeetting(meeting)
        self.currentInfo = ccmInfo
        self.subject.onNext(ccmInfo)
        logger.info("meeting perfInfo changed: level: \(ccmInfo.level),systemLoad: \(ccmInfo.systemLoadScore),dynamic: \(ccmInfo.dynamicScore),thermal: \(ccmInfo.thermalScore),openDoc: \(ccmInfo.openDocScore)")
    }
    
    func getPerfInfoWithMeetting(_ meeting: ByteViewInterface.Meeting) -> CCMMagicSharePerfInfo {
        let info = meeting.magicSharePerformanceInfo
        let ccmInfo = CCMMagicSharePerfInfo(level: info.level,
                                            systemLoadScore: info.systemLoadScore,
                                            dynamicScore: info.dynamicScore,
                                            thermalScore: info.thermalScore,
                                            openDocScore: info.openDocScore)
        return ccmInfo
    }
}
#endif
