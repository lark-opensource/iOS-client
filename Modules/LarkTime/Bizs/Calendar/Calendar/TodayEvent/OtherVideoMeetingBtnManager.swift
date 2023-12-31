//
//  OtherVideoMeetingBtnManager.swift
//  Calendar
//
//  Created by chaishenghua on 2023/8/17.
//

import LarkContainer
import LarkUIKit
import EENavigator
import UIKit
import UniverseDesignToast
import UniverseDesignActionPanel
import LarkEMM
import RxRelay
import RxSwift
import RustPB

enum NewRoute {
    case url(url: URL)
    case applink(url: URL, vcType: Rust.ParsedMeetingLinkVCType)
    case selector(parsedMeetingLinks: [ParsedEventMeetingLink])
}

class OtherVideoMeetingBtnManager {
    let calendarApi: CalendarRustAPI?
    private weak var vc: UIViewController?
    private let rxParsedMeetingLinks = BehaviorRelay<[ParsedEventMeetingLink]>(value: [])
    private let rxToast = PublishRelay<ToastStatus>()
    private let userResolver: UserResolver
    private let disposebag = DisposeBag()

    let rxShowOtherVCBtn = BehaviorRelay<Bool>(value: false)
    let model: OtherMeetingBtnModel

    // 埋点数据
    let feedTab: String
    let feedIsTop: Int

    var isLinkAvaliable: Bool {
        return isMeetingLinkParsed
        || isValidUrl(model.videoMeeting.meetingURL)
        || (model.videoMeeting.videoMeetingType == .googleVideoConference)
        || (model.videoMeeting.videoMeetingType == .zoomVideoMeeting)
    }

    var btnSummary: String {
        if model.videoMeeting.videoMeetingType == .googleVideoConference ||
            model.videoMeeting.videoMeetingType == .zoomVideoMeeting {
            return BundleI18n.Calendar.Calendar_VideoMeeting_JoinVideoMeeting
        } else if model.videoMeeting.videoMeetingType == .other,
                  case .otherConfigs(let configs) = model.videoMeeting.customizedConfigs {
            if !configs.customizedDescription.isEmpty {
                return configs.customizedDescription
            } else {
                switch configs.icon {
                case .live:
                    return BundleI18n.Calendar.Calendar_Edit_EnterLivestream
                default:
                    return BundleI18n.Calendar.Calendar_Edit_JoinVC
                }
            }
        }
        else {
            if let link = getParsedLinkIfOnlyOne() {
                return getMeetingButtonText(by: link.vcType)
            } else {
                return BundleI18n.Calendar.Calendar_VideoMeeting_JoinVideoMeeting
            }
        }
    }

    var isLive: Bool {
        if model.videoMeeting.videoMeetingType == .other,
           case .otherConfigs(let configs) = model.videoMeeting.customizedConfigs,
           configs.icon == .live {
            return true
        } else {
            return false
        }
    }

    private var isMeetingLinkParsable: Bool {
        if self.model.location.isEmpty && self.model.description.isEmpty { return false }
        if self.model.videoMeeting.videoMeetingType == .noVideoMeeting {
            return true
        } else {
            let sourceMatched = [.email, .exchange].contains(self.model.source)
            return sourceMatched
        }
    }

    init(calendarApi: CalendarRustAPI?,
         userResolver: UserResolver,
         vc: UIViewController?,
         model: OtherMeetingBtnModel,
         feedTab: String,
         feedIsTop: Bool) {
        self.calendarApi = calendarApi
        self.userResolver = userResolver
        self.vc = vc
        self.model = model
        self.feedTab = feedTab
        self.feedIsTop = feedIsTop ? 1 : 0
        if model.videoMeeting.videoMeetingType != .noVideoMeeting {
            rxShowOtherVCBtn.accept(true)
        }
        bind()
    }

    private func bind() {
        guard let vc = vc else { return }
        self.rxToast
            .bind(to: vc.rx.toast)
            .disposed(by: disposebag)
        self.parseEventMeetingLinks()
    }

    private func openVC(route: NewRoute) {
        guard let vc = self.vc else { return }
        switch route {
        case let .url(url):
            if Display.pad {
                userResolver.navigator.present(url,
                                         context: ["from": "calendar"],
                                         wrap: LkNavigationController.self,
                                         from: vc,
                                         prepare: { $0.modalPresentationStyle = .fullScreen })
            } else {
                userResolver.navigator.push(url, context: ["from": "calendar"], from: vc)
            }
        case let .applink(url, vcType):
            self.openApplink(url: url, linkType: vcType)
        case let .selector(parsedMeetingLinks):
            self.showMeetingPicker(parsedMeetingLinks: parsedMeetingLinks)
        }
    }

    private func openApplink(url: URL, linkType: Rust.ParsedMeetingLinkVCType) {
        guard let vc = self.vc else { return }
        if linkType == .lark {
            userResolver.navigator.open(url, from: vc)
        } else {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    private func showMeetingPicker(parsedMeetingLinks: [ParsedEventMeetingLink]) {
        if Display.pad {
            let vc = ParsedLinkViewController()
            let meetingLinks = generateMeetingLinkCellData(vcLinks: parsedMeetingLinks, baseVC: vc)
            let meetingSelectorView = MeetingSelectorView(meetingLinks: meetingLinks)
            vc.addContentView(meetingSelectorView, title: BundleI18n.Calendar.Calendar_Detail_JoinVC)
            let nav = LkNavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .formSheet
            nav.update(style: .custom(UIColor.ud.bgFloat))
            self.vc?.present(nav, animated: true, completion: nil)
        } else {
            let meetingSelectorVC = ActionPanelContentViewController()
            let meetingLinks = generateMeetingLinkCellData(vcLinks: parsedMeetingLinks, baseVC: meetingSelectorVC)
            let meetingSelectorView = MeetingSelectorView(meetingLinks: meetingLinks)
            
            let selectorViewHeight = meetingSelectorView.estimateHeight()
            meetingSelectorVC.addContentView(meetingSelectorView, contentHeight: selectorViewHeight, title: BundleI18n.Calendar.Calendar_Detail_JoinVC)
            
            let screenHeight = Display.height
            let actionPanelOriginY = max(screenHeight - CGFloat((selectorViewHeight + 140)), screenHeight * 0.2)
            let actionPanel = UDActionPanel(
                customViewController: meetingSelectorVC,
                config: UDActionPanelUIConfig(
                    originY: actionPanelOriginY,
                    canBeDragged: false,
                    backgroundColor: UIColor.ud.bgFloatBase
                )
            )
            self.vc?.present(actionPanel, animated: true, completion: nil)
        }
    }

    private func generateMeetingLinkCellData(vcLinks: [ParsedEventMeetingLink], baseVC: UIViewController) -> [MeetingLinkCellData] {
        let meetingLinkCellData = vcLinks.map {
            MeetingLinkCellData(parsedLinkData: $0,
                                onClick: { [weak self] link in
                guard let self = self, let url = URL(string: link.vcLink) else { return }
                baseVC.dismiss(animated: true)
                self.openApplink(url: url, linkType: link.vcType)
            },
                                onCopy: { vcLink in
                SCPasteboard.generalPasteboard(shouldImmunity: true).string = vcLink
                UDToast.showTips(with: BundleI18n.Calendar.Calendar_VideoMeeting_VCLinkSuccess, on: baseVC.view)
            })
        }
        return meetingLinkCellData
    }

    func tapVideoMeetingBtn() {
        if isLive {
            CalendarTracerV2.TodayEventCilck.traceClick() {
                $0.click("enter_live")
                $0.is_top = self.feedIsTop
                $0.feed_tab = self.feedTab
            }
        } else {
            CalendarTracerV2.TodayEventCilck.traceClick() {
                $0.click("enter_vc")
                $0.is_top = self.feedIsTop
                $0.feed_tab = self.feedTab
            }
        }
        if model.videoMeeting.videoMeetingType == .zoomVideoMeeting {
            let urlString = model.videoMeeting.zoomConfigs.meetingURL
            guard let url = URL(string: urlString) else {
                TodayEvent.logError("cannot jump url")
                return
            }
            self.openVC(route: .url(url: url))
        } else if model.videoMeeting.videoMeetingType == .googleVideoConference {
            let urlString = model.videoMeeting.meetingURL

            guard let url = URL(string: urlString) else {
                TodayEvent.logInfo("cannot jump googleVC url, url is invalid")
                return
            }
            if urlString.contains("meet.google.com") {
                // 跳转 google app
                self.openVC(route: .applink(url: url, vcType: .google))
            } else {
                self.openVC(route: .url(url: url))
            }
        } else {
            // 会议链接优化，如果解析到只一个会议链接，则展示之
            if isMeetingLinkParsed {
                let parsedLinks = rxParsedMeetingLinks.value
                if parsedLinks.count > 1 {
                    self.openVC(route: .selector(parsedMeetingLinks: parsedLinks))
                } else {
                    if let parsedLink = parsedLinks.first, let url = URL(string: parsedLink.vcLink) {
                        self.openVC(route: .applink(url: url, vcType: parsedLink.vcType))
                    }
                }
                return
            }
            guard let url = URL(string: model.videoMeeting.meetingURL) else {
                self.rxToast.accept(.failure(BundleI18n.Calendar.Calendar_Common_FailedToLoad))
                return
            }
            self.openVC(route: .url(url: url))
        }
    }

    var isMeetingLinkParsed: Bool {
        let parsed = self.isMeetingLinkParsable && !rxParsedMeetingLinks.value.isEmpty
        return parsed
    }

    private func parseEventMeetingLinks() {
        guard self.isMeetingLinkParsable else { return }
        if self.model.location.isEmpty && self.model.description.isEmpty { return }
        calendarApi?.parseEventMeetingLinks(eventLocation: model.location,
                                            eventDescription: model.description,
                                            eventSource: model.source,
                                            resourceName: [])
        .subscribe(onNext: {[weak self] resp in
            guard let self = self else { return }
            let locationVC = resp.locationItem.filter { $0.linkType == .vcLink && $0.vcType != .unknown }.map {
                ParsedEventMeetingLink(vcType: $0.vcType, vcLink: $0.locationURL.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            let descriptionVC = resp.descriptionLink.filter { $0.vcType != .unknown }.map { ParsedEventMeetingLink(vcType: $0.vcType, vcLink: $0.descriptionURL) }
            let links = self.duplicateLinksInOrder(locationVC + descriptionVC)
            if !links.isEmpty {
                EventDetail.logInfo("get \(links.count) links from parseEventMeetingLinks")
                self.rxParsedMeetingLinks.accept(links)
                self.rxShowOtherVCBtn.accept(true)
            }
        }, onError: { error in
            EventDetail.logError("parseEventMeetingLinks failed: \(error)")
        }).disposed(by: disposebag)
    }

    private func duplicateLinksInOrder(_ links: [ParsedEventMeetingLink]) -> [ParsedEventMeetingLink] {
        var newLinks: [ParsedEventMeetingLink] = []
        for item in links {
            if !newLinks.contains(item) {
                newLinks.append(item)
            }
        }
        return newLinks
    }

    private func getMeetingButtonText(by vcType: Rust.ParsedMeetingLinkVCType) -> String {
        switch vcType {
        case .google:
            return BundleI18n.Calendar.Calendar_Join_GoogleMeet
        case .zoom:
            return BundleI18n.Calendar.Calendar_Zoom_JoinMeetButton
        case .teams:
            return BundleI18n.Calendar.Calendar_Join_Teams
        case .webex:
            return BundleI18n.Calendar.Calendar_Join_Webex
        case .bluejeans:
            return BundleI18n.Calendar.Calendar_Join_BlueJeans
        case .tencent:
            return BundleI18n.Calendar.Calendar_Join_VooVMeeting
        case .lark:
            return BundleI18n.Calendar.Calendar_Join_BrandMeeting()
        default:
            return BundleI18n.Calendar.Calendar_Detail_JoinVC
        }
    }

    private func getParsedLinkIfOnlyOne() -> ParsedEventMeetingLink? {
        guard isMeetingLinkParsed else { return nil }
        if rxParsedMeetingLinks.value.count > 1 {
            return nil
        }
        return rxParsedMeetingLinks.value.first
    }

    func isValidUrl(_ urlString: String) -> Bool {
        if let url = NSURL(string: urlString) {
            return UIApplication.shared.canOpenURL(url as URL)
        }
        return false
    }
}
