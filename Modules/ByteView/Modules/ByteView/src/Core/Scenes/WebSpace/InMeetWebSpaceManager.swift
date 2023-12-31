//
//  InMeetWebSpaceManager.swift
//  ByteView
//
//  Created by fakegourmet on 2022/12/28.
//

import Foundation
import ByteViewNetwork

protocol InMeetWebSpaceDataObserver: AnyObject {
    func didChangeUrl(urlString: String)
    func didChangeWeb(title: String?)
    /// 作为 WebSpace 模块的起始事件
    /// 在 didChangeWebSpace 事件之前调用
    func didAutoOpenWebSpace(_ isAutoOpen: Bool)
}

extension InMeetWebSpaceDataObserver {
    func didChangeUrl(urlString: String) {}
    func didChangeWeb(title: String?) {}
    func didAutoOpenWebSpace(_ isAutoOpen: Bool) {}
}

/// 会中一直存在的vm，而非仅在 FullScreen 状态存在
final class InMeetWebSpaceManager: InMeetViewModelSimpleComponent {

    /// 控制入口和数据监听
    var isWebspaceEnabled: Bool {
        meeting.isInterviewMeeting && meeting.myself.role == .interviewee
    }
    var isWebSpaceGuideShown: Bool = false
    var hasData: Bool { urlString != nil }

    private var title: String? {
        currentRuntime?.documentVC.view.vc.getWebView()?.title
    }
    private lazy var magicShareRuntimeFactory: FollowDocumentFactory = meeting.service.ccm.createFollowDocumentFactory()
    private(set) var currentRuntime: MagicShareRuntime?
    private var urlString: String?

    private let meeting: InMeetMeeting
    init(meeting: InMeetMeeting) {
        self.meeting = meeting

        guard isWebspaceEnabled else { return }

        meeting.shareData.addListener(self)
        fetchData()
    }

    private let listeners = Listeners<InMeetWebSpaceDataObserver>()
    func addListener(_ listener: InMeetWebSpaceDataObserver, fireImmediately: Bool = true) {
        listeners.addListener(listener)
        if fireImmediately {
            if let urlString = urlString {
                listener.didChangeUrl(urlString: urlString)
            }
            if currentRuntime != nil {
                listener.didChangeWeb(title: title)
            }
        }
    }

    func removeListener(_ listener: InMeetWebSpaceDataObserver) {
        listeners.removeListener(listener)
    }

    func fetchData() {
        let request = CheckInterviewMeetingPromotionRequest(meetingID: meeting.meetingId, userID: meeting.userId)
        meeting.httpClient.getResponse(request) { [weak self] result in
            switch result {
            case .success(let response):
                guard let url = response.url, !url.isEmpty else {
                    break
                }
                self?.urlString = url
                self?.listeners.forEach {
                    $0.didChangeUrl(urlString: url)
                }
                self?.openWebSpaceIfNeeded()
            case .failure:
                break
            }
        }
    }

    func loadIfNeeded() {
        guard let urlString = urlString else { return }
        currentRuntime = createRuntime(with: urlString)
    }

    func close() {
        meeting.webSpaceData.setWebSpaceShow(false)
    }

    /// 没有面试官且不在共享时默认开启企业宣传页
    private var shouldOpenWebSpaceAutomatically: Bool = false

    private func openWebSpaceIfNeeded() {
        let workItem: DispatchWorkItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            Util.runInMainThread {
                let shouldOpenWebSpaceAutomatically: Bool = self.meeting.shareData.isSharingContent == false && self.meeting.participant.interviewerCount == 0
                self.shouldOpenWebSpaceAutomatically = shouldOpenWebSpaceAutomatically
                self.listeners.forEach {
                    $0.didAutoOpenWebSpace(shouldOpenWebSpaceAutomatically)
                }
                if shouldOpenWebSpaceAutomatically {
                    Logger.webSpace.info("open web space when no interviewers and no sharing")
                    self.meeting.webSpaceData.setWebSpaceShow(true)
                }
            }
        }
        if meeting.shareData.isSharingContent {
            // 有共享数据，直接执行
            workItem.perform()
        } else {
            // 无共享数据，可能是服务端推送延迟，延迟一秒执行
            // 若一秒后共享数据仍不完整，则走无共享数据逻辑
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + .seconds(1), execute: workItem)
        }
    }

    private func createRuntime(with urlString: String) -> MagicShareRuntime {
        let runtime = magicShareRuntimeFactory.createRuntime(
            document: MagicShareDocument.create(urlString: urlString, meeting: meeting),
            meeting: meeting,
            delegate: self,
            documentChangeDelegate: self,
            createSource: .untracked,
            participantsCount: meeting.participant.currentRoom.count
        )
        runtime.ownerID = ObjectIdentifier(self)
        return runtime
    }
}

extension InMeetWebSpaceManager: MagicShareRuntimeDelegate {

    func magicShareRuntimeDidReady(_ magicShareRuntime: MagicShareRuntime) {
        Logger.webSpace.info("\(#function)")
        if let title = title {
            listeners.forEach {
                $0.didChangeWeb(title: title)
            }
        }
    }

    func magicShareRuntime(_ magicShareRuntime: MagicShareRuntime, onOperation operation: MagicShareOperation) {}

    func magicShareRuntime(_ magicShareRuntime: MagicShareRuntime, onPresenterFollowerLocationChange location: MagicSharePresenterFollowerLocation) {}

    func magicShareRuntime(_ magicShareRuntime: MagicShareRuntime, onRelativePositionChange position: MagicShareRelativePosition) {}

    func magicShareRuntime(_ magicShareRuntime: MagicShareRuntime, onApplyStates states: [ByteViewNetwork.FollowState], uuid: String, timestamp: CGFloat) {}

    func magicShareRuntime(_ magicShareRuntime: MagicShareRuntime, onFirstPositionChangeAfterFollow receiveFollowInfoTime: TimeInterval) {}
}

extension InMeetWebSpaceManager: MagicShareDocumentChangeDelegate {
    func magicShareRuntime(_ magicShareRuntime: MagicShareRuntime, didDocumentChange userOperation: MagicShareOperation) {}
}

// - MARK: 负责处理抢共享逻辑
extension InMeetWebSpaceManager: InMeetShareDataListener {

    func didChangeShareContent(to newScene: InMeetShareScene, from oldScene: InMeetShareScene) {
        guard meeting.webSpaceData.isWebSpace else { return }
        if [.othersSharingScreen, .magicShare, .shareScreenToFollow, .whiteboard, .selfSharingScreen].contains(newScene.shareSceneType) {
            close()
        }
    }

}
