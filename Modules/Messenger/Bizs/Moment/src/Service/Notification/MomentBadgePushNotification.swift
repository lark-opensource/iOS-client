//
//  MomentBadgePushNotification.swift
//  Moment
//
//  Created by bytedance on 2021/3/3.
//

import UIKit
import Foundation
import RxSwift
import LarkRustClient
import LarkContainer
import ServerPB
import LarkSDKInterface

protocol MomentBadgePushNotification: AnyObject {
    var badgePush: PublishSubject<MomentsBadgeInfo> { get }
    var currentBadge: (messageCount: Int, reactionCount: Int) { get }
    var currentBadgeInfo: MomentsBadgeInfo? { get set }
    func updateBadgeIfNeedWith(badgeInfo: MomentsBadgeInfo, forceUpdate: Bool)
    func updateBadgeOnPutRead(messageCount: Int32, reactionCount: Int32)
    func forceGetBadgeFromServer()
}

final class MomentBadgePushNotificationManger: MomentBadgePushNotification, UserResolverWrapper {
    let badgePush: PublishSubject<MomentsBadgeInfo> = .init()
    @ScopedInjectedLazy private var noticeApi: NoticeApiService?
    @ScopedInjectedLazy private var handler: MomentsBadgePushNotificationHandler?
    @ScopedInjectedLazy private var momentsAccountService: MomentsAccountService?

    private var badgeBag = DisposeBag()
    private let userPushCenter: PushNotificationCenter

    var currentBadgeInfo: MomentsBadgeInfo?
    /// 当前的badge
    var currentBadge: (messageCount: Int, reactionCount: Int) {
        if let currentBadgeInfo = self.currentBadgeInfo,
           let currentBadgeCount = self.momentsAccountService?.getCurrentUserBadge(currentBadgeInfo) {
            return (Int(currentBadgeCount.messageCount), Int(currentBadgeCount.reactionCount))
        }
        return (0, 0)
    }

    let userResolver: UserResolver
    init(userResolver: UserResolver, userPushCenter: PushNotificationCenter) {
        self.userResolver = userResolver
        self.userPushCenter = userPushCenter
        self.getBadgeFromServer()
        self.handler?.rxBadgeCount
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (badgeCount) in
                self?.updateBadgeIfNeedWith(badgeInfo: badgeCount, forceUpdate: false)
        }).disposed(by: self.badgeBag)
        /// 监听app进入前台 重新获取一下badge信息
        NotificationCenter.default.rx
            .notification(UIApplication.willEnterForegroundNotification)
            .subscribe(onNext: { [weak self] _ in
                self?.getBadgeFromServer()
            }).disposed(by: self.badgeBag)
    }

    private func getBadgeFromServer(forceUpdate: Bool = false) {
        self.noticeApi?.getBadgeRequest()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (reponse) in
                self?.updateBadgeIfNeedWith(badgeInfo: reponse, forceUpdate: forceUpdate)
            }, onError: { [weak self] error in
                self?.momentsAccountService?.handleOfficialAccountErrorIfNeed(error: error, from: nil)
            }).disposed(by: self.badgeBag)
    }

    func forceGetBadgeFromServer() {
        getBadgeFromServer(forceUpdate: true)
    }

    /// 不区分数据来源, 只在意最新的
    func updateBadgeIfNeedWith(badgeInfo: MomentsBadgeInfo, forceUpdate: Bool) {
        /// 推送来的时候 本地没有server的数据 直接推送
        /// forceUpdate为true时，直接推送
        guard let lastBadgeCount = self.currentBadgeInfo else {
            self.currentBadgeInfo = badgeInfo
            self.badgePush.onNext(badgeInfo)
            return
        }

        if let newBadgeCount = lastBadgeCount.updateWith(badgeInfo, momentsAccountService: self.momentsAccountService) {
            self.currentBadgeInfo = newBadgeCount
            self.badgePush.onNext(newBadgeCount)
        } else if forceUpdate {
            self.badgePush.onNext(lastBadgeCount)
        }
    }

    /// 用户手动已读 置空一下消息数量
    func updateBadgeOnPutRead(messageCount: Int32, reactionCount: Int32) {
        if let data = self.currentBadgeInfo,
           let newBadgeInfo = self.momentsAccountService?.updateBadgeOnPutRead(data, messageCount: messageCount, reactionCount: reactionCount) {
            self.badgePush.onNext(newBadgeInfo)
            self.currentBadgeInfo = newBadgeInfo
        }
    }
}

private extension MomentsBadgeInfo {
    //返回nil表现不需要update
    //由于push不保证 对于每一组数据，根据reactionReadTs/messageReadTs
    func updateWith(_ newValue: MomentsBadgeInfo, momentsAccountService: MomentsAccountService?) -> MomentsBadgeInfo? {
        var needToUpdate = false
        var result = MomentsBadgeInfo(personalUserBadge: self.personalUserBadge, officialUsersBadge: [:])

        if let newPersonalBadge = self.personalUserBadge.updateWith(newValue.personalUserBadge) {
            needToUpdate = true
            result.personalUserBadge = newPersonalBadge
        }

        let officialUsers = momentsAccountService?.getMyOfficialUsers() ?? []
        if officialUsers.count != self.officialUsersBadge.count {
            needToUpdate = true
        }

        for user in officialUsers {
            let oldBadge = self.officialUsersBadge[user.userID]
            let newBadge = newValue.officialUsersBadge[user.userID]
            if let oldBadge = oldBadge,
               let newBadge = newBadge {
                if let resultBadge = oldBadge.updateWith(newBadge) {
                    needToUpdate = true
                    result.officialUsersBadge[user.userID] = resultBadge
                } else {
                    result.officialUsersBadge[user.userID] = oldBadge
                }
            } else {
                //如果oldBadge和newBadge 其中有一个（或两个）没值，那么哪个有值就填哪个
                result.officialUsersBadge[user.userID] = oldBadge ?? newBadge
                if newBadge != nil {
                    needToUpdate = true
                }
            }
        }

        return needToUpdate ? result : nil
    }
}
private extension RawData.MomentsBadgeCount {
    //返回nil表现不需要update
    func updateWith(_ newValue: RawData.MomentsBadgeCount) -> RawData.MomentsBadgeCount? {
        var needToUpdate = false
        var result = self
        if !newValue.reactionReadTs.isEmpty,
           stringToDoubleValue(newValue.reactionReadTs) > stringToDoubleValue(result.reactionReadTs) {
            needToUpdate = true
            result.reactionCount = newValue.reactionCount
            result.reactionReadTs = newValue.reactionReadTs
        }

        if !newValue.messageReadTs.isEmpty,
           stringToDoubleValue(newValue.messageReadTs) > stringToDoubleValue(result.messageReadTs) {
            needToUpdate = true
            result.messageCount = newValue.messageCount
            result.messageReadTs = newValue.messageReadTs
        }

        return needToUpdate ? result : nil
    }

    private func stringToDoubleValue(_ str: String) -> Double {
       return (str as NSString).doubleValue
    }
}
