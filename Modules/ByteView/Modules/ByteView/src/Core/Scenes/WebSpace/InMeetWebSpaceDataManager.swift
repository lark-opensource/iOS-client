//
//  InMeetWebSpaceDataManager.swift
//  ByteView
//
//  Created by liurundong.henry on 2023/4/4.
//

import Foundation

final class InMeetWebSpaceDataManager {

    /// 在看面试会议企业招聘信息
    @RwAtomic private(set) var isWebSpace: Bool = false

    private let listeners = Listeners<InMeetWebSpaceDataListener>()

    init() {}

    func addListener(_ listener: InMeetWebSpaceDataListener, fireImmediately: Bool = true) {
        listeners.addListener(listener)
        if fireImmediately {
            fireListenerOnAdd(listener)
        }
    }

    func removeListener(_ listener: InMeetWebSpaceDataListener) {
        listeners.removeListener(listener)
    }

    private func fireListenerOnAdd(_ listener: InMeetWebSpaceDataListener) {
        listener.didChangeWebSpace(isWebSpace)
    }

    func setWebSpaceShow(_ isShow: Bool) {
        Logger.webSpace.info("set webSpace to: \(isShow)")
        if isWebSpace != isShow {
            isWebSpace = isShow
            MeetingTracksV2.trackEnterprisePromotionShow(isShow)
            listeners.forEach { $0.didChangeWebSpace(isShow) }
        }
    }

}

protocol InMeetWebSpaceDataListener: AnyObject {
    /// 面试企业宣传页面
    func didChangeWebSpace(_ isShow: Bool)
}

extension InMeetWebSpaceDataListener {
    func didChangeWebSpace(_ isShow: Bool) {}
}
