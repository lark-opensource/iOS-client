//
//  TeamEventViewModel.swift
//  LarkFeed
//
//  Created by chaishenghua on 2022/8/30.
//

import UIKit
import Foundation
import ServerPB
import LarkContainer
import LarkRustClient
import RxSwift
import EENavigator
import LarkMessengerInterface
import Swinject
import RxRelay
import LKCommonsLogging
import RichLabel
import LarkModel

final class TeamEventViewModel {

    enum TeamEventPullState {
        // 正在拉
        case loading
        // 拉完了
        case display
        // 拉取错误
        case error
    }

    static let logger = Logger.log(TeamEventViewModel.self, category: "LarkTeam")
    var teamEventModel: [TeamEventModel]
    let numberOfLoadingSections = 1
    let numberOfLoadingRows = 5
    private let numberOfFirstPull: Int32 = 20
    private let numberOfUpdate: Int32 = 20
    var hasMore: Bool
    var currentDate: String
    var state: TeamEventPullState

    private let dependency: TeamEventDependency
    private let teamID: Int64
    private let disposeBag: DisposeBag
    private var offset: Int64

    private var TeamEventModelRelay = BehaviorRelay<Void>(value: ())
    var teamEventModelObservable: Observable<Void> {
        return TeamEventModelRelay.asObservable()
    }

    init(teamEventDependency: TeamEventDependency, teamID: Int64) {
        //向服务端拉数据
        self.dependency = teamEventDependency
        self.teamID = teamID
        offset = 0
        teamEventModel = [TeamEventModel]()
        disposeBag = DisposeBag()
        hasMore = true
        currentDate = ""
        state = .loading
        getTeamEvents(limit: numberOfFirstPull)
    }

    private func getTeamEvents(limit: Int32) {
        if !hasMore {
            return
        }
        dependency.pullTeamEvent(teamID: teamID, limit: limit, offset: offset)
            .subscribe(onNext: { [weak self] teamEventsResponse in
                guard let self = self else { return }
                TeamEventViewModel.logger.info("TeamLog-getTeamEvents offset: \(teamEventsResponse.nextOffset), hasMore: \(teamEventsResponse.hasMore_p), teamID: \(self.teamID)")
                self.hasMore = teamEventsResponse.hasMore_p
                self.offset = teamEventsResponse.nextOffset
                self.mergeData(response: teamEventsResponse)
                self.state = .display
                self.TeamEventModelRelay.accept(())
            }, onError: { [weak self] _ in
                TeamEventViewModel.logger.error("TeamLog-getTeamEvents error")
                guard let self = self else { return }
                self.state = .error
            }).disposed(by: disposeBag)
    }

    func pullMoreEvents() {
        getTeamEvents(limit: numberOfUpdate)
    }

    private func mergeData(response: ServerPB.ServerPB_Team_PullTeamEventsResponse) {
        var teamEventCellModel: TeamEventCellModel
        for teamEvent in response.events {
            teamEventCellModel = transformData(serviceTeamEvents: teamEvent)
            if currentDate != teamEventCellModel.date {
                currentDate = teamEventCellModel.date
                teamEventModel.append(TeamEventModel(title: teamEventCellModel.date))
            }
            teamEventModel[teamEventModel.count - 1].list.append(teamEventCellModel)
        }
    }

    private func transformData(serviceTeamEvents: ServerPB.ServerPB_Entities_TeamEvent) -> TeamEventCellModel {
        //分割字符串{{operator}}创建了{{team}}。首先按{{分割字符串，结果为
        //"", "operator}}创建了", "team}}"
        //然后去掉空值，再按}}分割
        //"operator", "创建了" 和 "team", "" 记得去掉空值
        // 然后把这些输入到字典中，有值的则为key，无值的为普通文本
        let strArray = serviceTeamEvents.template.components(separatedBy: "{{")
        let links: [LKTextLink]
        let event: String
        var elements: [String] = []
        for str in strArray {
            if !str.isEmpty {
                elements.append(contentsOf: str.components(separatedBy: "}}"))
            }
        }
        (event, links) = parseEvent(elements: elements, templateKv: serviceTeamEvents.templateKv)
        let date = Date(timeIntervalSince1970: Double(serviceTeamEvents.createTime / 1000)).lf.formatedDate()
        let time = Date(timeIntervalSince1970: Double(serviceTeamEvents.createTime / 1000)).lf.formatedTime_v2()

        let eventAttributedString = NSMutableAttributedString(string: event)
        let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16),
                                                         NSAttributedString.Key.foregroundColor: UIColor.ud.textTitle]
        eventAttributedString.addAttributes(attributes, range: NSRange(location: 0, length: event.utf16.count))

        return TeamEventCellModel(event: eventAttributedString,
                                  time: time,
                                  date: date,
                                  links: links,
                                  userResolver: self.dependency.userResolver)
    }

    private func parseEvent(elements: [String],
                            templateKv: [String: ServerPB_Entities_TeamEventTemplateValue]) -> (String, [LKTextLink]) {
        var links: [LKTextLink] = []
        var link: LKTextLink
        var event: String = ""
        for element in elements {
            if element.isEmpty {
                continue
            }
            if let value = templateKv[element] {
                for item in value.items {
                    var text = item.text
                    switch item.type {
                    case .unknown:
                        break
                    case .user:
                        link = createLink(url: "//teamEvent/userProfile?userid=\(item.id)",
                                           color: UIColor.ud.textLinkNormal,
                                           range: NSRange(location: event.utf16.count, length: text.utf16.count))
                        links.append(link)
                    case .text:
                        break
                    case .chat:
                        if item.chatInfo.isTeamOpenChat || item.chatInfo.operatorInChat {
                            let mode: Int
                            let isCrypto: Bool
                            if item.chatInfo.hasChatMode {
                                mode = item.chatInfo.chatMode.rawValue
                            } else {
                                mode = ServerPB.ServerPB_Entities_Chat.ChatMode.default.rawValue
                            }
                            if item.chatInfo.hasIsCrypto {
                                isCrypto = item.chatInfo.isCrypto
                            } else {
                                isCrypto = false
                            }

                            link = createLink(url: "//teamEvent/group?chatid=\(item.id)&chatMode=\(mode)&isCrypto=\(isCrypto)&teamID=\(teamID)",
                                               color: UIColor.ud.textLinkNormal,
                                               range: NSRange(location: event.utf16.count, length: text.utf16.count))
                            links.append(link)
                        } else {
                            link = createLink(url: "//teamEvent/operatorNotInChat",
                                               color: UIColor.ud.textCaption,
                                               range: NSRange(location: event.utf16.count, length: text.utf16.count))
                            links.append(link)
                        }
                    case .team:
                        break
                    @unknown default:
                        break
                    }
                    event += text
                    if let last = value.items.last, last != item {
                        event += value.itemsJoiner
                    }
                }
            } else {
                event += element
            }
        }
        return (event, links)
    }

    private func createLink(url: String, color: UIColor, range: NSRange) -> LKTextLink {
        var link = LKTextLink(range: range,
                              type: .link,
                              attributes: [NSAttributedString.Key.foregroundColor: color],
                              activeAttributes: [NSAttributedString.Key.foregroundColor: color])
        link.url = URL(string: url)
        return link
    }
}
