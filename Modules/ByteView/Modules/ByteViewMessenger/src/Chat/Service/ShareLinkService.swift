//
//  ShareLinkService.swift
//  LarkByteView
//
//  Created by kiri on 2021/9/3.
//

import Foundation
import RxSwift
import LarkLocalizations
import ByteViewNetwork
import LarkContainer

final class ShareLinkService {
    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    // 分享链接
    func shareMeet(meetingId: String, content: String?, toUsers userIds: [String], groups groupIds: [String], fromQrCode: Bool, piggybackText: String?) -> Observable<ShareVideoChatResponse> {
        guard let httpClient = try? userResolver.resolve(assert: HttpClient.self) else {
            return .empty()
        }
        var request = ShareVideoChatRequest(meetingId: meetingId, userIds: userIds, groupIds: groupIds)
        if let content = content {
            request.shareMessage = content
        }
        if let piggybackText = piggybackText {
            request.piggybackText = piggybackText
        }
        if fromQrCode {
            request.shareFrom = .fromQrCode
        }
        return RxTransform.single {
            httpClient.getResponse(request, completion: $0)
        }.asObservable()
    }

    func getMeetingContent(meetingId: String) -> Observable<String> {
        guard !meetingId.isEmpty, let account = try? userResolver.resolve(assert: AccountInfo.self),
              let httpClient = try? userResolver.resolve(assert: HttpClient.self) else {
            return .error(RxError.noElements)
        }
        let userName = account.userName
        return RxTransform.single {
            httpClient.getResponse(GetMeetingURLInfoRequest(meetingId: meetingId), completion: $0)
        }.asObservable().flatMap { resp in
            // subtype 参数用于判断分享出来的会议是否为 webinar 会议，进而异化分享文案。这里拿不到 meeting 对象，
            // 且调用方目前仅限扫 room 二维码分享，不涉及 webinar 会议，所以传入 .default
            self.getPasteboardContent(httpClient: httpClient, userName: userName, meetingNumber: resp.meetingNo,
                                      topic: resp.topic, meetingSubtype: .default, meetingURL: resp.meetingURL,
                                      isInterview: resp.meetingSource == .vcFromInterview)
        }
    }

    private struct I18Key {
        static let meetingIdColon = "View_M_MeetingIdColon"
        static let meetingTopicColon = "View_M_MeetingTopicColon"
        static let meetingLinkColon = "View_M_MeetingLinkColon"
        static let meetingInterviewTopic = "View_M_VideoInterviewNameBraces"
        static let invitesToFeishuMeeting = "View_MV_InvitesToFeishuMeeting"
        static let invitesToWebinar = "View_G_NameInviteYouJoinWebinar"
        static let meetingTimeHere = "View_MV_MeetingTimeHere"
        static let meetingRules = "View_MV_MeetingRules"
    }

    private func getPasteboardContent(httpClient: HttpClient, userName: String, meetingNumber: String,
                                      topic: String, meetingSubtype: MeetingSubType, meetingURL: String,
                                      isInterview: Bool) -> Observable<String> {
        let appName = LanguageManager.bundleDisplayName
        let inviteKey = meetingSubtype == .webinar ? I18Key.invitesToWebinar : I18Key.invitesToFeishuMeeting
        let keys = [inviteKey,
                    I18Key.meetingIdColon,
                    I18Key.meetingTimeHere,
                    I18Key.meetingTopicColon,
                    I18Key.meetingLinkColon,
                    I18Key.meetingInterviewTopic]
        return RxTransform.single {
            httpClient.i18n.get(keys, completion: $0)
        }.asObservable().map { templates in
            var result: [String] = []

            let defaultInviteInfo: String = meetingSubtype == .webinar ? I18n.View_G_NameInviteYouJoinWebinar(name: userName, appName: appName) : I18n.View_MV_InvitesToFeishuMeeting(userName, appName)
            let inviteInfo: String = templates[inviteKey]?
                .replacingOccurrences(of: "{{name}}", with: userName).replacingOccurrences(of: "{{appName}}", with: appName) ?? defaultInviteInfo
            result.append(inviteInfo)
            let topicPre = templates[I18Key.meetingTopicColon] ?? I18n.View_M_MeetingTopicColon
            var topicInfo: String

            if isInterview {
                let interviewTopic = templates[I18Key.meetingInterviewTopic]?
                    .replacingOccurrences(of: "{{name}}", with: topic) ?? defaultInviteInfo
                topicInfo = "\(topicPre)\(interviewTopic)"
            } else {
                topicInfo = "\(topicPre)\(topic)"
            }
            result.append(topicInfo)

            let meetingNumberPre = templates[I18Key.meetingIdColon] ?? I18n.View_M_MeetingIdColon
            let meetingNumberInfo = "\(meetingNumberPre)\(meetingNumber)"
            result.append(meetingNumberInfo)

            let meetingURLPre = templates[I18Key.meetingLinkColon] ?? I18n.View_M_MeetingLinkColon
            let meetingURLInfo = "\(meetingURLPre)\(meetingURL)"
            result.append(meetingURLInfo)
            return result.joined(separator: "\n")
        }
    }
}
