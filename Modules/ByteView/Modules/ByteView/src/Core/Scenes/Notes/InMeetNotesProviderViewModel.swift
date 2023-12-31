//
//  InMeetNotesProviderViewModel.swift
//  ByteView
//
//  Created by shin on 2023/7/21.
//

import Foundation
import ByteViewUI
import ByteViewSetting
import ByteViewNetwork

/// 提供纪要分屏等数据创建相关逻辑
final class InMeetNotesProviderViewModel {
    let resolver: InMeetViewModelResolver
    private let meeting: InMeetMeeting
    weak var notesContainerVC: InMeetNotesContainerViewController?

    /// 会议是否开启“在纪要文档中生成智能会议纪要”
    var inMeetGenerateMeetingSummaryInDocs: Bool = false

    /// 进入会议的时间
    let enterMeetingDate = Date().timeIntervalSince1970

    /// 定期拉取会议纪要文档协作者
    var syncTimer: Timer?

    @RwAtomic
    /// 拉取接口返回的间隔，每次拉取后更新；实际拉取时取该值与settings规定值的较大值
    var pullInterval: NSInteger = 30

    @RwAtomic
    /// 本地缓存协作者头像
    var cachedNotesCollaborators = [NotesCollaborator]()

    @RwAtomic
    /// 当前正在展示头像的协作者信息
    var currentNotesCollaboratorInfo: NotesCollaboratorInfo?

    private let listeners = Listeners<NotesCollaboratorAvatarListener>()

    // MARK: - Listeners

    func addListener(_ listener: NotesCollaboratorAvatarListener, fireImmediately: Bool = true) {
        listeners.addListener(listener)
        if fireImmediately {
            fireListenerOnAdd(listener)
        }
    }

    func removeListener(_ listener: NotesCollaboratorAvatarListener) {
        listeners.removeListener(listener)
    }

    private func fireListenerOnAdd(_ listener: NotesCollaboratorAvatarListener) {
        listener.didChangeNotesCollaborators(currentNotesCollaboratorInfo)
    }

    // MARK: - Allocations

    init(resolver: InMeetViewModelResolver) {
        self.resolver = resolver
        self.meeting = resolver.meeting
        self.inMeetGenerateMeetingSummaryInDocs = meeting.setting.inMeetGenerateMeetingSummaryInDocs
        if #available(iOS 13.0, *) {
            VCSideBarSceneService.addProvider(self, for: InMeetNotesKeyDefines.generateNotesSceneInfo(with: meeting.meetingId))
        }
        self.meeting.notesData.addListener(self)
    }

    deinit {
        if #available(iOS 13.0, *) {
            VCSideBarSceneService.removeProvider(for: InMeetNotesKeyDefines.generateNotesSceneInfo(with: meeting.meetingId))
        }
        invalidateTimer()
    }

    /// 当前场景模板ID，分为1v1、日程会议与即时会议
    var notesTemplateCategoryId: String {
        var config: NotesTemplateConfig = meeting.setting.notesTemplateConfig
        if config.vcCallMeeting == -1 {
            if meeting.accountInfo.isChinaMainlandGeo { // 通过账号走不同的默认兜底config
                config = .feishuConfig
            } else {
                config = .larkConfig
            }
        }
        switch meeting.notesData.subScene {
        case InMeetNotesKeyDefines.MeetType.vcCallMeeting: return "\(config.vcCallMeeting)"
        case InMeetNotesKeyDefines.MeetType.vcCalendarMeeting: return "\(config.vcCalendarMeeting)"
        case InMeetNotesKeyDefines.MeetType.vcNormalMeeting: return "\(config.vcNormalMeeting)"
        default: return "\(config.vcNormalMeeting)"
        }
    }
}

@available(iOS 13.0, *)
extension InMeetNotesProviderViewModel: VCSideBarSceneProvider {
    func createViewController(scene: UIScene,
                              session: UISceneSession,
                              options: UIScene.ConnectionOptions,
                              sceneInfo: SceneInfo,
                              localContext: AnyObject?) -> UIViewController?
    {
        if sceneInfo != InMeetNotesKeyDefines.generateNotesSceneInfo(with: meeting.meetingId) {
            return nil
        }
        let notesVC: InMeetNotesContainerViewController
        if let vc = notesContainerVC {
            notesVC = vc
        } else {
            let notesContainerVM = InMeetNotesContainerViewModel(meeting: meeting, resolver: resolver)
            let notesContainerVC = InMeetNotesContainerViewController(viewModel: notesContainerVM)
            if !meeting.notesData.hasCreatedNotes {
                let bvTemplate = meeting.service.ccm.createBVTemplate()
                notesContainerVM.bvTemplate = bvTemplate
                let categoryId = self.notesTemplateCategoryId
                if let topMost = meeting.router.topMost,
                   let templateVC = bvTemplate?.createTemplateViewController(with: notesContainerVM, categoryId: categoryId, fromVC: topMost) {
                    notesContainerVC.setRootVC(templateVC)
                } else {
                    VCScene.deactive(from: scene)
                }
            }
            notesVC = notesContainerVC
            self.notesContainerVC = notesContainerVC
        }
        return notesVC
    }
}

extension InMeetNotesProviderViewModel: InMeetNotesDataListener {

    func didChangeNotesInfo(_ notes: NotesInfo?, oldValue: NotesInfo?) {
        if notes != nil, Display.pad {
            startSyncIfNeeded()
        }
    }

}

// MARK: - 定期拉取纪要文档协作者数据，更新Notes按钮

protocol NotesCollaboratorAvatarListener: AnyObject {
    func didChangeNotesCollaborators(_ info: NotesCollaboratorInfo?)
}

extension InMeetNotesProviderViewModel {

    private func startSyncIfNeeded() {
        guard syncTimer == nil else {
            return
        }
        pullNotesCollaboratorInfo()
        setNewTimer()
    }

    private func setNewTimer() {
        Logger.notes.debug("will set new notes collaborator timer")
        invalidateTimer()
        let settingsTimeInterval = meeting.setting.vcMeetingNotesConfig.getNotesCollaboratorsSyncRequestTimeInterval(currentParticipantsCount: meeting.participant.global.count)
        let timeInterval = max(settingsTimeInterval, pullInterval)
        let timer = Timer(timeInterval: Double(timeInterval), repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Logger.notes.debug("notes collaborator timer action")
            self.pullNotesCollaboratorInfo()
            self.checkNextTimer()
        }
        RunLoop.main.add(timer, forMode: .common)
        syncTimer = timer
    }

    private func checkNextTimer() {
        Logger.notes.debug("notes collaborator check next timer")
        if let timer = syncTimer {
            let settingsTimeInterval = meeting.setting.vcMeetingNotesConfig.getNotesCollaboratorsSyncRequestTimeInterval(currentParticipantsCount: meeting.participant.global.count)
            let timeInterval = max(settingsTimeInterval, pullInterval)
            if Double(timeInterval) != timer.timeInterval {
                Logger.notes.debug("timer is invalid, time interval is different, will set to: \(timeInterval)")
                setNewTimer()
            }
        } else {
            Logger.notes.debug("timer is nil, set new timer")
            setNewTimer()
        }
    }

    private func invalidateTimer() {
        syncTimer?.invalidate()
        syncTimer = nil
    }

    private func pullNotesCollaboratorInfo() {
        Logger.notes.debug("will pull notes collaborator info")
        let domain = meeting.service.ccm.getDocsAPIDomain()
        let objToken = meeting.notesData.urlToken
        let cachedUserIds = cachedNotesCollaborators.map { $0.userId }
        let completion: (([NotesCollaborator], [String], NSInteger, NSInteger) -> Void) = { [weak self] (newNotesCollaborators: [NotesCollaborator], remainCollaboratorIds: [String], pullInterval: NSInteger, count: NSInteger) in
            Logger.notes.info("pull notes collaborator info completed, newNotesCollaborators: \(newNotesCollaborators), remainCollaboratorIds: \(remainCollaboratorIds), pullInterval: \(pullInterval), count: \(count)")
            self?.pullInterval = pullInterval
            self?.updateNotesCollaboratorsInfo(newCollaborators: newNotesCollaborators, remainCollaboratorIds: remainCollaboratorIds, count: count)
        }
        meeting.httpClient.notes.pullNotesCollaboratorInfo(domain: domain,
                                                           objToken: objToken,
                                                           cachedUserIds: cachedUserIds,
                                                           session: meeting.accountInfo.accessToken,
                                                           completion: completion)
    }

    private func updateNotesCollaboratorsInfo(newCollaborators: [NotesCollaborator], remainCollaboratorIds: [String], count: Int) {
        var latestCollaborator: NotesCollaborator?
        // 更新显示头像使用的协作者数据和协作者数量
        if let currentCollaboratorUserId = currentNotesCollaboratorInfo?.showAvatarCollaborator?.userId { // 如果现在有展示头像的人
            if remainCollaboratorIds.contains(currentCollaboratorUserId) { // 当前显示头像的用户依然在看文档，不更改头像
                latestCollaborator = currentNotesCollaboratorInfo?.showAvatarCollaborator
            } else if let firstRemainUserId = remainCollaboratorIds.first, cachedNotesCollaborators.map({ $0.userId }).contains(firstRemainUserId) { // 不包含了，remain有值，取remain的第一个
                latestCollaborator = cachedNotesCollaborators.first { $0.userId == firstRemainUserId }
            } else if let firstNewCollaborator = newCollaborators.first { // remain没有值，取new的第一个
                latestCollaborator = firstNewCollaborator
            } else {
                latestCollaborator = nil
            }
        } else {
            if let firstRemainUserId = remainCollaboratorIds.first, cachedNotesCollaborators.map({ $0.userId }).contains(firstRemainUserId) {
                latestCollaborator = cachedNotesCollaborators.first { $0.userId == firstRemainUserId }
            } else if let firstNewCollaborator = newCollaborators.first {
                latestCollaborator = firstNewCollaborator
            } else {
                latestCollaborator = nil
            }
        }
        currentNotesCollaboratorInfo = NotesCollaboratorInfo(showAvatarCollaborator: latestCollaborator, collaboratorsCount: count)
        Logger.notes.info("notes collaborator avatar update to: \(currentNotesCollaboratorInfo)")
        // 更新全部（ID+头像）数据缓存
        newCollaborators.forEach {
            if !cachedNotesCollaborators.map({ $0.userId }).contains($0.userId) {
                cachedNotesCollaborators.append($0)
            }
        }
        // 推送更新
        listeners.forEach {
            $0.didChangeNotesCollaborators(currentNotesCollaboratorInfo)
        }
    }

}
