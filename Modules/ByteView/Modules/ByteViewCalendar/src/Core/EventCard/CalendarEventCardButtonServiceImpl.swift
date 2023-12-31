//
//  CalendarEventCardButtonServiceImpl.swift
//  ByteViewCalendar
//
//  Created by lutingting on 2023/8/2.
//

import Foundation
import RxSwift
import RxCocoa
import LarkContainer
import ByteViewInterface
import ByteViewCommon
import ByteViewNetwork
import EENavigator
import LarkUIKit
import UniverseDesignToast
import ByteViewUI
import ByteViewTracker


final class CalendarEventCardButtonServiceImpl: CalendarEventCardButtonService {
    let userId: String
    let userResolver: UserResolver
    let logger: Logger = Logger.getLogger("EventCardButton")
    @RwAtomic
    private var buttons: [String: VisualButton] = [:]
    private var navigator: Navigatable { userResolver.navigator }

    private var httpClient: HttpClient? { try? userResolver.resolve(assert: HttpClient.self) }

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        self.userId = userResolver.userID
        Push.associatedVideoChatStatus.inUser(userResolver.userID).addObserver(self) { [weak self] in
            self?.didGetAssociatedVideoChatStatus($0)
        }
    }

    func createEventCardButton(_ info: EventCardButtonInfo) -> UIButton {
        let btn = VisualButton()
        btn.setTitle(I18n.Calendar_VideoMeeting_OpenVideoMeeting, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        btn.layer.borderWidth = 1
        btn.layer.cornerRadius = 6
        btn.setBGColor(UIColor.ud.udtokenComponentOutlinedBg, for: .normal)
        btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        btn.addTarget(self, action: #selector(joinMeeting(_:)), for: .touchUpInside)
        btn.eventInfo = info
        setButtonColor(isLiving: false, for: btn)
        buttons[info.uniqueId] = btn
        updateVideoMeetingStatus(info)
        return btn
    }

    func remove(uniqueId: String) {
        buttons.removeValue(forKey: uniqueId)
    }

    func removeAll() {
        buttons.removeAll()
    }

    func updateStatus(_ info: EventCardButtonInfo) {
        updateVideoMeetingStatus(info)
    }

    // 刷新视频按钮living态
    private func updateVideoMeetingStatus(_ info: EventCardButtonInfo, function: String = #function) {
        guard buttons[info.uniqueId] != nil, info.videoMeetingType == .vchat else { return }
        getVideoChatStatus(info) { [weak self] result in
            guard case let .success(videoChatStatus) = result else { return }
            Util.runInMainThread {
                self?.updateButtonStatus(info, with: videoChatStatus)
            }
        }
    }

    private func getVideoChatStatus(_ info: EventCardButtonInfo, completion: @escaping (Result<CalendarVideoChatStatus, Error>) -> Void, function: String = #function) {
        let instanceIdentifier = CalendarInstanceIdentifier(uid: info.key, originalTime: info.originalTime, instanceStartTime: info.startTime, instanceEndTime: info.endTime)
        let request = GetCalendarVchatStatusRequest(uniqueID: Int64(info.uniqueId) ?? 0, calendarInstanceIdentifier: instanceIdentifier, isAudience: info.isWebinarAudience)
        GetCalendarVchatStatusRequest.command = info.isFromPeople ? .server(.getInterviewVchatStatus) : .server(.getCalendarVchatStatus)

        httpClient?.getResponse(request) { result in
            switch result {
            case .success(let resp):
                completion(.success(resp.videoChatStatus))
            case .failure(let error):
                Logger.eventCard.error("GetCalendarVchatStatusRequest failure error: \(error), function: \(function)")
                completion(.failure(error))
            }
        }
    }

    private func updateButtonStatus(_ info: EventCardButtonInfo, with videoChatStatus: CalendarVideoChatStatus) {
        guard let cardButton = buttons[info.uniqueId] else {
            Logger.eventCard.error("updateButtonStatus failure because it not get cardButton")
            return
        }
        cardButton.eventInfo = info
        let isLiving = videoChatStatus.status == .live
        let isRehearsal = videoChatStatus.rehearsalMode
        let isRehearsaling = videoChatStatus.isRehearsal

        var text = I18n.Calendar_VideoMeeting_OpenVideoMeeting

        if isLiving {
            if info.isWebinar {
                if info.isWebinarOrganizer || info.isWebinarSpeaker {
                    text = isRehearsaling ? I18n.View_G_JoinRehearsal_Button : I18n.Calendar_G_JoinWebinar
                } else {
                    text = I18n.Calendar_G_JoinWebinar
                }
            } else {
                text = I18n.Calendar_VideoMeeting_JoinVideoMeeting
            }
            setButtonColor(isLiving: true, for: cardButton)
        } else {
            switch info.videoMeetingType {
            case .googleVideoConference:
                // 谷歌视频会议, google 日程 VC 链接设计文档: https://bytedance.feishu.cn/docs/doccnIQ6szozi9MxnVBIAEiZDhC#
                text = I18n.Calendar_VideoMeeting_JoinVideoMeeting
            case .unknownVideoMeetingType:
                text = I18n.Calendar_Edit_JoinVC
            default:
                if info.isWebinar {
                    // 对于组织者/嘉宾，显示为：开始彩排
                    if info.isWebinarOrganizer || info.isWebinarSpeaker {
                        text = isRehearsal ? I18n.View_G_StartRehearsal_Button : I18n.Calendar_G_StartWebinar
                    } else {
                        // 对于观众，显示为：加入研讨会；（同现状，不希望观众感知到彩排）
                        text = I18n.Calendar_G_JoinWebinar
                    }
                }
            }

            if Utils.isValidUrl(info.url) {
                setButtonColor(isLiving: false, for: cardButton)
            } else {
                cardButton.setTitleColor(UIColor.ud.textTitle, for: .normal)
                cardButton.setTitleColor(UIColor.ud.textTitle, for: .highlighted)
                cardButton.setBorderColor(UIColor.ud.textTitle, for: .normal)
            }
        }
        cardButton.setTitle(text, for: .normal)
    }

    private func setButtonColor(isLiving: Bool, for button: VisualButton) {
        let color: UIColor = isLiving ? .ud.functionSuccessContentDefault : .ud.primaryContentDefault
        let highlightedColor: UIColor = isLiving ? .ud.functionSuccessContentPressed : .ud.primaryContentPressed
        Util.runInMainThread {
            button.setTitleColor(color, for: .normal)
            button.setTitleColor(highlightedColor, for: .highlighted)
            button.setBorderColor(color, for: .normal)
            button.setBorderColor(highlightedColor, for: .highlighted)
        }
    }

    @objc private func joinMeeting(_ sender: UIButton) {
        logger.info("tap videomeeting action")
        guard let info = sender.eventInfo else { return }
        let view = sender.firstViewController()?.view ?? UIView()
        if info.videoMeetingType == .googleVideoConference {
            let urlString = info.url
            guard let url = URL(string: urlString) else {
                logger.info("cannot jump url: \(urlString)")
                return
            }
            if urlString.contains("meet.google.com") {
                // 跳转 google app
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                // 路由兜底
                pushByUrl(url)
            }
        } else if info.videoMeetingType == .vchat {
            if info.isExpired {
                self.logger.info("jump video expired")
                UDToast.showTips(with: I18n.Calendar_Detail_VCExpired, on: view)
            } else {
                guard !sender.isBlockClick else { return }
                jumpVideo(info, view: view)
            }
        } else {
            guard let url = URL(string: info.url) else {
                return
            }
            pushByUrl(url)
        }
    }

    private func pushByUrl(_ url: URL) {
        let fromVC = navigator.mainSceneWindow?.fromViewController ?? UIViewController()
        if ByteViewCommon.Display.pad {
            navigator.present(url,
                              context: ["from": "calendar"],
                              wrap: LkNavigationController.self,
                              from: fromVC,
                              prepare: { $0.modalPresentationStyle = .fullScreen })
        } else {
            navigator.push(url, context: ["from": "calendar"], from: fromVC)
        }
    }

    private func jumpVideo(_ info: EventCardButtonInfo, view: UIView) {
        self.logger.info("jump video")

        if info.isFromPeople {
            VCTracker.post(name: .feed_event_list_click, params: [.click: "enter_vc", "is_top": info.isTop, "feed_tab": info.feedTab])
            joinInterviewVideoMeeting(uniqueId: info.uniqueId)
        } else {
            UDToast.showLoading(with: I18n.Calendar_Common_LoadingCommon, on: view, disableUserInteraction: false)
            let btn = buttons[info.uniqueId]
            btn?.isBlockClick = true
            getVideoChatStatus(info) { [weak self] result in
                Util.runInMainThread {
                    btn?.isBlockClick = false
                    UDToast.removeToast(on: view)
                    if case let .success(videoChatStatus) = result {
                        let isLiving = videoChatStatus.status == .live
                        VCTracker.post(name: .feed_event_list_click, params: [.click: isLiving ? "enter_vc" : "launch_vc", "is_top": info.isTop, "feed_tab": info.feedTab])
                        self?.joinVideoMeeting(info, isStartMeeting: !isLiving)
                    }
                }
            }
        }
    }

    private func joinInterviewVideoMeeting(uniqueId: String) {
        logger.info("joinInterviewVideoMeeting, uniqueId: \(uniqueId)")
        let body = JoinMeetingBody(id: uniqueId, idType: .interview, entrySource: .calendarDetails)
        let fromVC = navigator.mainSceneWindow?.fromViewController ?? UIViewController()
        navigator.push(body: body, from: fromVC)
    }

    private func joinVideoMeeting(_ info: EventCardButtonInfo, isStartMeeting: Bool) {
        logger.info("joinVideoMeeting, uniqueId: \(info.uniqueId)")
        let fromVC = navigator.mainSceneWindow?.fromViewController ?? UIViewController()
        let body = JoinMeetingByCalendarBody(uniqueId: info.uniqueId, uid: info.key,
                                             originalTime: info.originalTime,
                                             instanceStartTime: info.startTime,
                                             instanceEndTime: info.endTime,
                                             title: info.displayTitle,
                                             entrySource: .calendarDetails,
                                             linkScene: false, isStartMeeting: isStartMeeting,
                                             isWebinar: info.isWebinar)
        navigator.push(body: body, from: fromVC)
    }
}

extension CalendarEventCardButtonServiceImpl {
    func didGetAssociatedVideoChatStatus(_ status: GetAssociatedVideoChatStatusResponse) {
        logger.info("onPush: VideoChatStatus")
        guard !buttons.isEmpty, let info = buttons[status.id]?.eventInfo else {
            logger.info("video meeting status push, skip!! id not match or buttons is empty")
            return
        }
        switch status.idType {
        case .uniqueID, .interviewUid:
            logger.info("video meeting status push")
            updateVideoMeetingStatus(info)
        default:
            break
        }
    }
}


private extension UIButton {
    static var eventCardButtonEventInfoKeys = "eventCardButtonEventInfoKeys"
    static var eventCardButtonBlockClickKeys = "eventCardButtonBlockClickKeys"

    var eventInfo: EventCardButtonInfo? {
        get { objc_getAssociatedObject(self, &Self.eventCardButtonEventInfoKeys) as? EventCardButtonInfo }
        set { objc_setAssociatedObject(self, &Self.eventCardButtonEventInfoKeys, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    var isBlockClick: Bool {
        get { objc_getAssociatedObject(self, &Self.eventCardButtonBlockClickKeys) as? Bool ?? false}
        set { objc_setAssociatedObject(self, &Self.eventCardButtonBlockClickKeys, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    //返回该view所在VC
    func firstViewController() -> UIViewController? {
        for view in sequence(first: self.superview, next: { $0?.superview }) {
            if let responder = view?.next {
                if responder.isKind(of: UIViewController.self){
                    return responder as? UIViewController
                }
            }
        }
        return nil
    }
}
