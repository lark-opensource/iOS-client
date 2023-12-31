//
//  SwitchTabDialogManager.swift
//  LarkTour
//
//  Created by aslan on 2022/1/15.
//

import Foundation
import UGReachSDK
import UGDialog
import LKCommonsLogging
import LarkContainer
import Swinject
import RxSwift
import LarkNavigation
import LarkTab
import LKCommonsTracker
import LarkDialogManager

final class SwitchTabDialogManager: UserResolverWrapper {
    static let logger = Logger.log(SwitchTabDialogManager.self, category: "UGDialog")
    static let IMDialogRPId = "RP_IM_DIALOG"
    static let IMDialogSceneId = "SCENE_IM_DIALOG"
    static let ContactDialogRPId = "RP_CONTACT_DIALOG"
    static let ContactDialogSceneId = "SCENE_CONTACT_DIALOG"
    private let disposeBag = DisposeBag()

    private let enableDialogTabKeys: [String] = [LarkTab.Tab.feed.key, LarkTab.Tab.contact.key]
    private var tabSwitchCountMap: [String: Int] = [:]
    private var dialogRPMap: [String: DialogReachPoint] = [:]

    @ScopedProvider private var navigationService: NavigationService?
    @ScopedProvider var reachService: UGReachSDKService?
    @ScopedProvider private var dialogManagerService: DialogManagerService?

    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        self.enableDialogTabKeys.forEach { key in
            self.tabSwitchCountMap[key] = 0
        }
        if let key = self.navigationService?.firstTab?.key,
           self.enableDialogTabKeys.contains(key),
           let count = self.tabSwitchCountMap[key] {
            self.tabSwitchCountMap[key] = count + 1
        }
        _ = observerNavigation
    }

    deinit {
        Self.logger.info("deinit")
    }

    public func excute() {
        Self.logger.info("begin excute")
        imDialogReachPoint?.delegate = self
        contactDialogReachPoint?.delegate = self
        if let tab = self.navigationService?.firstTab {
            self.tryExposeAt(tab: tab)
        }
    }

    private lazy var observerNavigation: Void = {
        DispatchQueue.main.async {
            self.navigationService?.tabDriver.drive(onNext: { [weak self]  in
                guard let `self` = self,
                      let tab = $0.newTab else { return }
                self.excuteDialogShowAt(tab: tab)
                self.tryExposeAt(tab: tab)
            }).disposed(by: self.disposeBag)
        }
    }()

    lazy var imDialogReachPoint: DialogReachPoint? = {
        let bizContextProvider = UGSyncBizContextProvider(scenarioId: Self.IMDialogSceneId) { [:] }
        let reachPoint: DialogReachPoint? = reachService?.obtainReachPoint(
            reachPointId: Self.IMDialogRPId,
            bizContextProvider: bizContextProvider
        )
        return reachPoint
    }()

    lazy var contactDialogReachPoint: DialogReachPoint? = {
        let bizContextProvider = UGSyncBizContextProvider(scenarioId: Self.ContactDialogSceneId) { [:] }
        let reachPoint: DialogReachPoint? = reachService?.obtainReachPoint(
            reachPointId: Self.ContactDialogRPId,
            bizContextProvider: bizContextProvider
        )
        return reachPoint
    }()

    func tryExposeAt(tab: LarkTab.Tab) {
        Self.logger.info("try expose dialog at tab:\(tab.key)")
        guard let count = self.tabSwitchCountMap[tab.key],
        count == 1 else {
            return
        }
        switch tab {
        case .feed:
            reachService?.tryExpose(by: Self.IMDialogSceneId, specifiedReachPointIds: [Self.IMDialogRPId])
            Self.logger.info("expose dialog at feed, RP_IM_DIALOG")
        case .contact:
            reachService?.tryExpose(by: Self.ContactDialogSceneId, specifiedReachPointIds: [Self.ContactDialogRPId])
            Self.logger.info("expose dialog at contact: RP_CONTACT_DIALOG")
        default: break
        }
    }

    func excuteDialogShowAt(tab: LarkTab.Tab) {
        if let count = self.tabSwitchCountMap[tab.key] {
            self.tabSwitchCountMap[tab.key] = count + 1
            if let dialogReachPoint = self.dialogRPMap[tab.key],
               count + 1 == 2 {
                // 弹窗管理避免冲突
                dialogManagerService?.addTask(task: DialogTask(onShow: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: { [weak self] in
                        /// tab 第二次被点击时候弹窗
                        self?.showDialogWithDialogInfo(rp: dialogReachPoint)
                        dialogReachPoint.reportShow()
                        dialogReachPoint.reportClosed()
                        Self.logger.info("dialog show at:\(tab.key)")
                    })
                }))
            }
        }
    }

    func showDialogWithDialogInfo(rp: DialogReachPoint) {
        guard let dialogInfo = rp.dialogData,
        let jsonData = dialogInfo.data.data(using: .utf8),
        let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
            Self.logger.info("dialog data invalid")
            return
        }
        let taskID = dialogInfo.base.taskID
        DialogView.show(data: jsonObject, cancelHandler: { [weak self] in
            self?.trackClickEvent(click: "close", taskID: taskID)
            self?.dialogManagerService?.onDismiss()
        }, confirmHandler: { [weak self] in
            self?.trackClickEvent(click: "get", taskID: taskID)
            self?.dialogManagerService?.onDismiss()
        })
        Tracker.post(
            TeaEvent("growth_popup_view", params: [
                "task_id": taskID,
                "popup_id": taskID,
                "popup_type": "part_screen"
            ])
        )
        Self.logger.info("dialog data: \(jsonObject)")
    }

    func trackClickEvent(click: String, taskID: Int64) {
        Tracker.post(
            TeaEvent("growth_popup_click", params: [
                "task_id": taskID,
                "popup_id": taskID,
                "click": click,
                "target": "none"
            ])
        )
    }
}

extension SwitchTabDialogManager: DialogReachPointDelegate {
    func onShow(dialogReachPoint: DialogReachPoint) {
        if dialogReachPoint.reachPointId == Self.IMDialogRPId {
            self.dialogRPMap[LarkTab.Tab.feed.key] = dialogReachPoint
        } else if dialogReachPoint.reachPointId == Self.ContactDialogRPId {
            self.dialogRPMap[LarkTab.Tab.contact.key] = dialogReachPoint
        }
        Self.logger.info("dialog data show rpId: \(dialogReachPoint.reachPointId)")
    }
}
