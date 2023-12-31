//
//  MinutesInfoViewModel.swift
//  Minutes
//
//  Created by panzaofeng on 2021/1/11.
//

import Foundation
import MinutesFoundation
import MinutesNetwork
import LarkTimeFormatUtils

public struct CoverInfo: Codable {
    public let sectionName: String
    public let name: String
    public let image: String
    public let url: String
    public let permissionStatus: Int
    public var generateStatus: Int? = nil
}

protocol MinutesInfoItemValue {
    var string: String? { get set }
    var participants: [Participant] { get set }
    var files: [FileInfo] { get set }
    var groupChats: [CoverInfo] { get set }
    var channels: [CoverInfo] { get set }
    var fragments: [CoverInfo] { get set }
}

struct MinutesInfoItem<T> {
    enum ItemType {
        case name
        case owner
        case time
        case participant
        case summary
        case link
        case groupChat
        case channels
        case fragment
    }
    let type: ItemType
    let title: String
    var imageUrl: String? = nil
    let value: T
}

struct Value: MinutesInfoItemValue {
    var string: String? = nil
    var participants: [Participant] = []
    var files: [FileInfo] = []
    var groupChats: [CoverInfo] = []
    var channels: [CoverInfo] = []
    var fragments: [CoverInfo] = []
}

struct DateFormat {
    static func getLocalizedDate(timeInterval: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timeInterval / 1000)
        return TimeFormatUtils.formatDateTime(from: date, with: Options(timePrecisionType: .minute, dateStatusType: .relative))
    }

    static func getLongLocalizedDate(timeInterval: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timeInterval / 1000)
        return TimeFormatUtils.formatDateTime(from: date, with: Options(timeFormatType: .long, timePrecisionType: .minute))
    }
}

public final class MinutesInfoViewModel {

    public var minutes: Minutes
    var items: [MinutesInfoItem<MinutesInfoItemValue>] = []

    init(minutes: Minutes) {
        self.minutes = minutes
    }

    func fetchData(_ completion: @escaping (() -> Void)) {
        let info = minutes.info
        let data = minutes.data

        var items: [MinutesInfoItem<MinutesInfoItemValue>] = []
        /// 所有者
        items.append(MinutesInfoItem(type: .owner,
                                     title: BundleI18n.Minutes.MMWeb_G_MeetingInfoOwner_Subtitle,
                                     imageUrl: info.basicInfo?.ownerInfo?.avatarURL,
                                     value: Value(string: info.basicInfo?.ownerInfo?.userName)))
        /// 参会人
        items.append(MinutesInfoItem(type: .participant,
                                     title: BundleI18n.Minutes.MMWeb_G_MeetingInfoParticipants_Subtitle,
                                     value: Value(participants: info.participants)))

        /// 创建时间
        items.append(MinutesInfoItem(type: .time,
                                     title: BundleI18n.Minutes.MMWeb_G_MeetingInfoCreated_Subtitle,
                                     value: Value(string: DateFormat.getLongLocalizedDate(timeInterval: TimeInterval(info.basicInfo?.startTime ?? 0)))))


        let group = DispatchGroup()

        /// 会议纪要
        var summaryInfo: MinutesInfoItem<MinutesInfoItemValue>?
        group.enter()
        fetchMeetingNotes(success: { info in
            summaryInfo = MinutesInfoItem(type: .summary,
                                          title: BundleI18n.Minutes.MMWeb_G_MeetingNotesHere_Desc,
                                          value: Value(files: [info]))
            group.leave()
        }, failure: {
            group.leave()
        })

        /// 分组讨论
        var groupInfo: MinutesInfoItem<MinutesInfoItemValue>?
        if data.groupMeetings?.isEmpty == false {
            let groups: [CoverInfo] = (data.groupMeetings ?? []).map({ CoverInfo(sectionName: BundleI18n.Minutes.MMWeb_G_BreakoutRoomsMenu, name: $0.topic, image: $0.videoCover, url: $0.url, permissionStatus: $0.permissionStatus, generateStatus: $0.generateStatus) })
            groupInfo = MinutesInfoItem(type: .groupChat,
                                        title: BundleI18n.Minutes.MMWeb_G_BreakoutRoomsMenu,
                                        value: Value(groupChats: groups))
        }
        /// 同声传译
        var channelInfo: MinutesInfoItem<MinutesInfoItemValue>?
        group.enter()
        fetchMeetingChannels(success: { channels in
            let c: [CoverInfo] = channels.map({ CoverInfo(sectionName: BundleI18n.Minutes.MMWeb_G_InterpretationInfo_Desc, name: $0.topic, image: $0.videoCover, url: $0.url, permissionStatus: $0.permissionStatus, generateStatus: $0.generateStatus) })
            if c.isEmpty == false {
                channelInfo = MinutesInfoItem(type: .channels,
                                              title: BundleI18n.Minutes.MMWeb_G_InterpretationInfo_Desc,
                                              value: Value(channels: c))
            }
            group.leave()
        }, failure: {
            group.leave()
        })

        /// 片段
        var clipsInfo: MinutesInfoItem<MinutesInfoItemValue>?
        if shouldShowClipListItem {
            group.enter()
            fetchClips(success: { clips in
                let c: [CoverInfo] = clips.map({ CoverInfo(sectionName: BundleI18n.Minutes.MMWeb_G_MeetingClipsHere_Desc, name: $0.topic, image: $0.videoCover, url: $0.url, permissionStatus: $0.permissionStatus, generateStatus: $0.generateStatus) })
                if c.isEmpty == false {
                    clipsInfo = MinutesInfoItem(type: .fragment,
                                                  title: BundleI18n.Minutes.MMWeb_G_MeetingClipsHere_Desc,
                                                  value: Value(fragments: c))
                }
                group.leave()
            }, failure: {
                group.leave()
            })
        }

        group.notify(queue: .main) {
            /// 会议纪要
            if let info = summaryInfo {
                items.append(info)
            }
            /// 相关链接
            if info.files.isEmpty == false {
                items.append(MinutesInfoItem(type: .link,
                                             title: BundleI18n.Minutes.MMWeb_G_MeetingInfoRelatedLinks_Subtitle,
                                             value: Value(files: info.files)))
            }
            /// 分组讨论
            if let info = groupInfo {
                items.append(info)
            }
            /// 同声传译
            if let info = channelInfo {
                items.append(info)
            }
            /// 片段
            if let info = clipsInfo {
                items.append(info)
            }
            self.items = items
            completion()
        }
    }

    var shouldShowClipListItem: Bool {
        guard let someBasicInfo = minutes.basicInfo else { return false }

        if let clipInfo = someBasicInfo.clipInfo, clipInfo.clipNumber > 0, someBasicInfo.isOwner == true {
            return true
        } else {
            return false
        }
    }

    public func fetchMeetingNotes(success: ((FileInfo) -> Void)? = nil, failure: (() -> Void)? = nil) {
        let request = MeetingNotesRequest(objectToken: minutes.objectToken, catchError: false)
        minutes.api.sendRequest(request) { (result) in
            switch result {
            case .success(let res):
                DispatchQueue.main.async {
                    success?(res.data)
                }
            case .failure:
                DispatchQueue.main.async {
                    failure?()
                }
            }
        }
    }

    public func fetchMeetingChannels(success: (([MeetingChannelInfo]) -> Void)? = nil, failure: (() -> Void)? = nil) {
        let request = MeetingChannelsRequest(objectToken: minutes.objectToken, catchError: false)
        minutes.api.sendRequest(request) { (result) in
            switch result {
            case .success(let res):
                let channels = res.data.channels
                DispatchQueue.main.async {
                    success?(channels)
                }
            case .failure:
                DispatchQueue.main.async {
                    failure?()
                }
            }
        }
    }

    public func fetchClips(success: (([MinutesClipListItem]) -> Void)? = nil, failure: (() -> Void)? = nil) {
        minutes.doClipListRequest { res in
            switch res {
            case .success(let clipList):
                DispatchQueue.main.async {
                    success?(clipList.list)
                }
            case .failure(_):
                DispatchQueue.main.async {
                    failure?()
                }
            }
        }
    }
}
