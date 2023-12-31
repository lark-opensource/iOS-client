//
//  MeetingCopyUtil.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/5/16.
//

import Foundation
import LarkLocalizations
import ByteViewCommon
import ByteViewNetwork

public struct MeetingCopyInfoRequest {
    public var type: TypeEnum
    public var topic: String
    public var meetingURL: String
    public var isWebinar: Bool
    public var isInterview: Bool
    public var meetingTime: String?
    public var meetingNumber: String?
    public var isE2EeMeeting: Bool

    public init(type: TypeEnum, topic: String, meetingURL: String, isWebinar: Bool, isInterview: Bool, meetingTime: String?, meetingNumber: String?, isE2EeMeeting: Bool) {
        self.type = type
        self.topic = topic
        self.meetingURL = meetingURL
        self.isWebinar = isWebinar
        self.isInterview = isInterview
        self.meetingTime = meetingTime
        self.meetingNumber = meetingNumber
        self.isE2EeMeeting = isE2EeMeeting
    }

    public enum TypeEnum {
        case calendar(CalendarInfo)
        case tab(TabAccessInfos)
    }

    public struct CalendarInfo {
        public var tenantId: String
        public var uniqueId: String
        public var instance: CalendarInstanceIdentifier

        public init(tenantId: String, uniqueId: String, instance: CalendarInstanceIdentifier) {
            self.tenantId = tenantId
            self.uniqueId = uniqueId
            self.instance = instance
        }
    }

    fileprivate var unwrappedMeetingNumber: String {
        if let s = self.meetingNumber, !s.isEmpty {
            return s
        }
        if let s = self.meetingURL.split(separator: "/").last {
            return String(s)
        }
        return ""
    }
}

public struct MeetingCopyInfoResponse {
    public var isPstnEnabled: Bool         // pstn 信息是否展示
    public var copyContent: String         // 复制信息
}

public struct PstnIncomingCallInfo {
    public let isPstnEnabled: Bool
    public let defaultPhoneNumber: String
    public let phoneList: [PSTNPhone]
}

extension MeetingSettingManager {
    public func fetchCopyInfo(completion: @escaping (Result<MeetingCopyInfoResponse, Error>) -> Void) {
        if self.meetingId.isEmpty {
            completion(.failure(MeetingCopyInfoError.missingContext))
            return
        }
        if isMeetingLocked {
            completion(.failure(MeetingCopyInfoError.locked))
            return
        }
        if self.meetingURL.isEmpty {
            service.httpClient.getResponse(GetMeetingURLInfoRequest(meetingId: self.meetingId)) { [weak self] result in
                guard let self = self, case .success(let resp) = result else {
                    completion(.failure(MeetingCopyInfoError.requestFailed))
                    return
                }
                self._fetchCopyInfo(meetingNumber: resp.meetingNo, topic: resp.topic, meetingURL: resp.meetingURL,
                                    isInterview: resp.meetingSource == .vcFromInterview, completion: completion)
            }
        } else {
            self._fetchCopyInfo(meetingNumber: videoChatInfo.meetNumber, topic: videoChatSettings.topic, meetingURL: self.meetingURL,
                                isInterview: self.isInterviewMeeting, completion: completion)
        }
    }

    private func _fetchCopyInfo(meetingNumber: String, topic: String, meetingURL: String, isInterview: Bool,
                                completion: @escaping (Result<MeetingCopyInfoResponse, Error>) -> Void) {
        self.service.fetchCopyInfo(meetingNumber: meetingNumber, topic: topic, meetingURL: meetingURL,
                                   isWebinar: isWebinarMeeting, isInterview: isInterview, meetingTime: nil,
                                   isH323CopyInvitationEnabled: fg.isH323CopyInvitationEnabled,
                                   isPstnIncomingCallEnabled: isPstnIncomingEnabled, pstnIncomingCallPhoneList: pstnIncomingCallPhoneList,
                                   sipSetting: videoChatSettings.sipSetting, h323Setting: videoChatSettings.h323Setting, isE2EeMeeting: videoChatSettings.isE2EeMeeting,
                                   completion: { [weak self] in
            if let self = self, self.isMeetingLocked {
                completion(.failure(MeetingCopyInfoError.locked))
            } else {
                completion($0)
            }
        })
    }
}

public extension UserSettingManager {
    func fetchCopyInfo(_ request: MeetingCopyInfoRequest, completion: @escaping (Result<MeetingCopyInfoResponse, Error>) -> Void) {
        switch request.type {
        case .calendar(let info):
            fetchCalendarCopyInfo(request, info, completion: completion)
        case .tab(let accessInfos):
            fetchCopyInfo(meetingNumber: request.unwrappedMeetingNumber, topic: request.topic, meetingURL: request.meetingURL,
                          isWebinar: request.isWebinar, isInterview: request.isInterview, meetingTime: request.meetingTime,
                          isH323CopyInvitationEnabled: self.isH323CopyInvitationEnabled,
                          isPstnIncomingCallEnabled: accessInfos.pstnIncomingSetting.pstnEnableIncomingCall,
                          pstnIncomingCallPhoneList: accessInfos.pstnIncomingSetting.toPstnIncomingCallPhoneListEx(self.mobileCodes),
                          sipSetting: accessInfos.sipSetting, h323Setting: accessInfos.h323Setting, isE2EeMeeting: request.isE2EeMeeting, completion: completion)
        }
    }

    func fetchPstnIncomingCallInfo(tenantId: String, uniqueId: String, isInterview: Bool, calendarIdentifier: CalendarInstanceIdentifier,
                                   completion: @escaping (Result<PstnIncomingCallInfo, Error>) -> Void) {
        let request = PstnInComingCallInfoRequest(tenantID: tenantId, uniqueID: uniqueId, userId: Int64(userId) ?? 0, isInterview: isInterview, calendarInstanceIdentifier: calendarIdentifier)
        httpClient.getResponse(request) { [weak self] result in
            guard let self = self else {
                completion(.failure(NetworkError.unknown))
                return
            }
            switch result {
            case .success(let resp):
                completion(.success(resp.toInfo(self.mobileCodes)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

private extension UserSettingManager {
    struct I18Key {
        static let meetingIdColon = "View_M_MeetingIdColon"
        static let meetingTopicColon = "View_M_MeetingTopicColon"
        static let meetingLinkColon = "View_M_MeetingLinkColon"
        static let meetingInterviewTopic = "View_M_VideoInterviewNameBraces"
        static let invitesToFeishuMeeting = "View_MV_InvitesToFeishuMeeting"
        static let invitesToWebinar = "View_G_NameInviteYouJoinWebinar"
        static let meetingTimeHere = "View_MV_MeetingTimeHere"
        static let meetingRules = "View_MV_MeetingRules"
    }

    /// 是否允许SIP信息复制到剪贴板
    var isH323CopyInvitationEnabled: Bool { fg("byteview.meeting.copyh323invitation") }

    func fetchCopyInfo(meetingNumber: String, topic: String, meetingURL: String,
                       isWebinar: Bool, isInterview: Bool, meetingTime: String?,
                       isH323CopyInvitationEnabled: Bool,
                       isPstnIncomingCallEnabled: Bool, pstnIncomingCallPhoneList: [PSTNPhone],
                       sipSetting: VideoChatSettings.SIPSetting?, h323Setting: H323Setting?,
                       isE2EeMeeting: Bool,
                       completion: @escaping (Result<MeetingCopyInfoResponse, Error>) -> Void) {
        let inviteKey = isWebinar ? I18Key.invitesToWebinar : I18Key.invitesToFeishuMeeting
        var i18nKeys = [inviteKey,
                        I18Key.meetingIdColon,
                        I18Key.meetingTimeHere,
                        I18Key.meetingTopicColon,
                        I18Key.meetingLinkColon,
                        I18Key.meetingInterviewTopic]
        h323Setting?.h323AccessList.forEach {
            i18nKeys.append($0.country)
        }
        self.httpClient.i18n.get(i18nKeys) { [weak self] in
            guard let self = self else {
                completion(.failure(MeetingCopyInfoError.missingContext))
                return
            }

            switch $0 {
            case .success(let templates):
                let content = self.createCopyContent(meetingNumber: meetingNumber, topic: topic, isWebinar: isWebinar, meetingTime: meetingTime, meetingURL: meetingURL, isInterview: isInterview, isH323CopyInvitationEnabled: isH323CopyInvitationEnabled, isPstnIncomingCallEnabled: isPstnIncomingCallEnabled, pstnIncomingCallPhoneList: pstnIncomingCallPhoneList, sipSetting: sipSetting, h323Setting: h323Setting, isE2EeMeeting: isE2EeMeeting, i18nInfo: templates)
                completion(.success(MeetingCopyInfoResponse(isPstnEnabled: isPstnIncomingCallEnabled, copyContent: content)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func createCopyContent(meetingNumber: String, topic: String, isWebinar: Bool,
                           meetingTime: String?, meetingURL: String, isInterview: Bool,
                           isH323CopyInvitationEnabled: Bool,
                           isPstnIncomingCallEnabled: Bool, pstnIncomingCallPhoneList: [PSTNPhone],
                           sipSetting: VideoChatSettings.SIPSetting?, h323Setting: H323Setting?,
                           isE2EeMeeting: Bool,
                           i18nInfo: [String: String]) -> String {
        var copyContent = ""
        let userName = self.userName
        let appName = LanguageManager.bundleDisplayName
        let formatedMeetingNumber = Self.formatMeetingNumber(meetingNumber)
        let inviteKey = isWebinar ? I18Key.invitesToWebinar : I18Key.invitesToFeishuMeeting

        let defaultInviteInfo = isWebinar ? I18n.View_G_NameInviteYouJoinWebinar(name: userName, appName: appName) : I18n.View_MV_InvitesToFeishuMeeting(userName, appName)
        var inviteInfo = defaultInviteInfo
        if let i18nInvite = i18nInfo[inviteKey] {
            inviteInfo = i18nInvite.replacingOccurrences(of: "{{name}}", with: userName).replacingOccurrences(of: "{{appName}}", with: appName)
        }
        copyContent += inviteInfo

        copyContent += "\n"
        copyContent += i18nInfo[I18Key.meetingTopicColon, default: I18n.View_M_MeetingTopicColon]
        if isInterview {
            if let i18nTopic = i18nInfo[I18Key.meetingInterviewTopic] {
                copyContent += i18nTopic.replacingOccurrences(of: "{{name}}", with: topic)
            } else {
                copyContent += defaultInviteInfo
            }
        } else {
            copyContent += topic
        }

        if let meetingTime = meetingTime {
            copyContent += "\n"
            if let i18nTime = i18nInfo[I18Key.meetingTimeHere] {
                copyContent += i18nTime.replacingOccurrences(of: "{{time}}", with: meetingTime)
            } else {
                copyContent += I18n.View_MV_MeetingTimeHere(meetingTime)
            }
        }

        copyContent += "\n"
        copyContent += i18nInfo[I18Key.meetingIdColon, default: I18n.View_M_MeetingIdColon]
        copyContent += formatedMeetingNumber

        copyContent += "\n"
        copyContent += i18nInfo[I18Key.meetingLinkColon, default: I18n.View_M_MeetingLinkColon]
        copyContent += meetingURL

        if isPstnIncomingCallEnabled, !isE2EeMeeting {
            let defaultIncomingPhones = pstnIncomingCallPhoneList.filter { $0.mobileCode.isDefault }.map {
                return "\n\(I18n.View_M_JoinMeetingByPhoneEntry($0.number, meetingNumber, $0.countryName))"
            }
            if !defaultIncomingPhones.isEmpty {
                copyContent += "\n\n\(I18n.View_M_JoinMeetingByPhone)"
            }
            defaultIncomingPhones.forEach { (phoneLine) in
                copyContent += phoneLine
            }

            let fullIncomingPhones = pstnIncomingCallPhoneList
                .map { "\n\(I18n.View_M_DialInByLocationEntry($0.number, $0.countryName))" }
            if !fullIncomingPhones.isEmpty {
                copyContent += "\n\n\(I18n.View_M_DialInByLocation)"
            }
            fullIncomingPhones.forEach { (phoneLine) in
                copyContent += phoneLine
            }
        }

        if let sipSetting = sipSetting, !isE2EeMeeting {
            Logger.setting.info("fetch meeting copy info, isShowSipCrc = \(sipSetting.isShowCrc)")
            if sipSetting.isShowCrc && !sipSetting.domain.isEmpty {
                copyContent += "\n\n\(I18n.View_G_JoinByRoomSystem)"
                copyContent += "\n\(meetingNumber)@\(sipSetting.domain)"
            }
            if !sipSetting.ercDomainList.isEmpty {
                copyContent += "\n\n\(I18n.View_G_JoinByRoomSystem)"
                sipSetting.ercDomainList.forEach {
                    copyContent += "\n\(meetingNumber)@\($0)"
                }
            }
        }

        if !isE2EeMeeting, isH323CopyInvitationEnabled, let h323Setting = h323Setting {
            Logger.setting.info("fetch meeting copy info, isShowH323Crc = \(h323Setting.isShowCrc)")
            if h323Setting.isShowCrc {
                let h323Infos = h323Setting.h323AccessList.compactMap {
                    if let country = i18nInfo[$0.country] {
                        return "\n\($0.ip)\(country)"
                    } else {
                        return nil
                    }
                }
                if !h323Infos.isEmpty {
                    copyContent += "\n\n\(I18n.View_G_Use323ToJoin)"
                    h323Infos.forEach {
                        copyContent += $0
                    }
                    copyContent += "\n\(I18n.View_G_MeetingIdVariable)\(formatedMeetingNumber)"
                }
            }
            if !h323Setting.ercDomainList.isEmpty {
                copyContent += "\n\n\(I18n.View_G_Use323ToJoin)"
                h323Setting.ercDomainList.forEach {
                    copyContent += "\n\($0)"
                }
                copyContent += "\n\(I18n.View_G_MeetingIdVariable)\(formatedMeetingNumber)"
            }
        }
        return copyContent
    }

    func fetchCalendarCopyInfo(_ request: MeetingCopyInfoRequest, _ calendarInfo: MeetingCopyInfoRequest.CalendarInfo,
                               completion: @escaping (Result<MeetingCopyInfoResponse, Error>) -> Void) {
        let meetingNumber = request.unwrappedMeetingNumber
        let calendarInstance = calendarInfo.instance
        var adminSettings: GetAdminSettingsResponse?
        var featureConfig: GetPstnSipFeatureConfigResponse?
        var sipSetting: VideoChatSettings.SIPSetting = .init(domain: "", ercDomainList: [], isShowCrc: false)
        var h323Setting: H323Setting = .init(h323AccessList: [], ercDomainList: [], isShowCrc: false)
        var finalError: Error?

        let batch = DispatchGroup()
        let parsedUniqueId = Int64(calendarInfo.uniqueId) ?? 0
        if parsedUniqueId != 0 {
            batch.enter()
            refreshAdminSettings(force: true, tenantId: calendarInfo.tenantId, uniqueId: calendarInfo.uniqueId) { result in
                switch result {
                case .success(let resp):
                    adminSettings = resp
                case .failure(let error):
                    finalError = error
                }
                batch.leave()
            }

            batch.enter()
            let featureConfigRequest = GetPstnSipFeatureConfigRequest(userId: Int64(userId) ?? 0, uniqueId: parsedUniqueId, tenantId: tenantId, isInterview: request.isInterview, calendarInstance: calendarInstance)
            httpClient.getResponse(featureConfigRequest) { result in
                switch result {
                case .success(let resp):
                    featureConfig = resp
                case .failure(let error):
                    finalError = error
                }
                batch.leave()
            }
        }

        batch.enter()
        httpClient.getResponse(GetSipDomainRequest(uniqueId: parsedUniqueId, calendarInstance: calendarInstance)) { result in
            switch result {
            case .success(let resp):
                sipSetting = .init(domain: resp.domain, ercDomainList: resp.ercDomainList, isShowCrc: resp.isShowCrc)
            case .failure(let error):
                finalError = error
            }
            batch.leave()
        }

        batch.enter()
        let h323Request = GetH323AccessInfoRequest(uniqueId: parsedUniqueId, meetingNumber: meetingNumber, calendarInstance: calendarInstance)
        httpClient.getResponse(h323Request) { result in
            switch result {
            case .success(let resp):
                h323Setting = resp.h323Access
            case .failure(let error):
                finalError = error
            }
            batch.leave()
        }

        batch.notify(queue: .global()) { [weak self] in
            if let error = finalError {
                completion(.failure(error))
                return
            }
            guard let self = self else {
                completion(.failure(MeetingCopyInfoError.missingContext))
                return
            }

            var isPstnEnabled = false
            var pstnPhones: [PSTNPhone] = []
            if let adminSettings = adminSettings, let featureConfig = featureConfig {
                isPstnEnabled = adminSettings.pstnEnableIncomingCall && featureConfig.pstn.incomingCallEnable && !adminSettings.pstnIncomingCallPhoneList.isEmpty
                pstnPhones = adminSettings.toPstnIncomingCallPhoneListEx(self.mobileCodes)
            }
            self.fetchCopyInfo(meetingNumber: meetingNumber, topic: request.topic, meetingURL: request.meetingURL,
                               isWebinar: request.isWebinar, isInterview: request.isInterview, meetingTime: request.meetingTime,
                               isH323CopyInvitationEnabled: self.isH323CopyInvitationEnabled,
                               isPstnIncomingCallEnabled: isPstnEnabled, pstnIncomingCallPhoneList: pstnPhones,
                               sipSetting: sipSetting, h323Setting: h323Setting, isE2EeMeeting: request.isE2EeMeeting, completion: completion)
        }
    }

    static func formatMeetingNumber(_ meetingNumber: String) -> String {
        let s = meetingNumber
        guard s.count >= 9 else {
            return ""
        }
        let index1 = s.index(s.startIndex, offsetBy: 3)
        let index2 = s.index(s.endIndex, offsetBy: -3)
        return "\(s[..<index1]) \(s[index1..<index2]) \(s[index2..<s.endIndex])"
    }
}

private enum MeetingCopyInfoError: Equatable, Error {
    case missingContext
    case requestFailed
    case locked
}

extension GetAdminSettingsResponse {
    func toPstnIncomingCallPhoneListEx(_ mobileCodes: [MobileCode]) -> [PSTNPhone] {
        let defaultIncomings = Set(pstnIncomingCallCountryDefault)
        let cache: [String: MobileCode] = mobileCodes.reduce(into: [:], { $0[$1.key] = $1 })
        return pstnIncomingCallPhoneList.map({
            let key = $0.country
            var code: MobileCode = cache[key, default: .emptyCode(key)]
            code.isDefault = defaultIncomings.contains(key)
            return PSTNPhone(country: $0.country, type: $0.type, number: $0.number, numberDisplay: $0.numberDisplay, mobileCode: code)
        })
    }

    func toPstnMobileCodes(_ mobileCodes: [MobileCode]) -> PstnMobileCodes {
        let defaultIncomings = Set(pstnIncomingCallCountryDefault)
        let defaultOutgoings = Set(pstnOutgoingCallCountryDefault)
        let cache: [String: MobileCode] = mobileCodes.reduce(into: [:], { $0[$1.key] = $1 })
        var result = PstnMobileCodes()
        result.pstnIncomingCallCountryDefault = self.pstnIncomingCallCountryDefault.map({ key in
            var code: MobileCode = cache[key, default: .emptyCode(key)]
            code.isDefault = true
            return code
        })
        result.pstnIncomingCallPhoneList = self.pstnIncomingCallPhoneList.map({
            let key = $0.country
            var code = cache[key, default: .emptyCode(key)]
            code.isDefault = defaultIncomings.contains(key)
            return PSTNPhone(country: $0.country, type: $0.type, number: $0.number, numberDisplay: $0.numberDisplay, mobileCode: code)
        })
        result.pstnOutgoingCallCountryDefault = self.pstnOutgoingCallCountryDefault.map({ key in
            var code: MobileCode = cache[key, default: .emptyCode(key)]
            code.isDefault = true
            return code
        })
        result.pstnOutgoingCallCountryList = self.pstnOutgoingCallCountryList.map({ key in
            var code: MobileCode = cache[key, default: .emptyCode(key)]
            code.isDefault = defaultOutgoings.contains(key)
            return code
        })
        return result
    }

    struct PstnMobileCodes {
        /// PSTN 呼入默认国家
        var pstnIncomingCallCountryDefault: [MobileCode] = []
        /// PSTN 呼入号码列表
        var pstnIncomingCallPhoneList: [PSTNPhone] = []
        /// PSTN 呼出默认国家
        var pstnOutgoingCallCountryDefault: [MobileCode] = []
        /// PSTN 呼出国家列表
        var pstnOutgoingCallCountryList: [MobileCode] = []
    }
}

private extension TabAccessInfos.PstnIncomingSetting {
    func toPstnIncomingCallPhoneListEx(_ mobileCodes: [MobileCode]) -> [PSTNPhone] {
        let defaultIncomings = Set(pstnIncomingCallCountryDefault)
        let cache: [String: MobileCode] = mobileCodes.reduce(into: [:], { $0[$1.key] = $1 })
        return pstnIncomingCallPhoneList.map({
            let key = $0.country
            var code: MobileCode = cache[key, default: .emptyCode(key)]
            code.isDefault = defaultIncomings.contains(key)
            return PSTNPhone(country: $0.country, type: $0.type, number: $0.number, numberDisplay: $0.numberDisplay, mobileCode: code)
        })
    }
}

private extension PstnInComingCallInfoResponse {
    func toInfo(_ mobileCodes: [MobileCode]) -> PstnIncomingCallInfo {
        let defaultIncomings = Set(pstnIncomingCallCountryDefault)
        let cache: [String: MobileCode] = mobileCodes.reduce(into: [:], { $0[$1.key] = $1 })
        let isPstnEnabled = fcPstnIncomingCallEnable && adminSettingPstnEnableIncomingCall && !pstnIncomingCallPhoneList.isEmpty
        var phoneList: [PSTNPhone] = []
        var defaultPhoneNumber: String = ""
        for phone in pstnIncomingCallPhoneList {
            let key = phone.country
            var code: MobileCode = cache[key, default: .emptyCode(key)]
            code.isDefault = defaultIncomings.contains(key)
            if code.isDefault, !key.isEmpty && !phone.numberDisplay.isEmpty {
                defaultPhoneNumber = "\(phone.numberDisplay) (\(code.name))"
            }
            phoneList.append(PSTNPhone(country: phone.country, type: phone.type, number: phone.number, numberDisplay: phone.numberDisplay, mobileCode: code))
        }
        if defaultPhoneNumber.isEmpty, let phone = phoneList.first {
            defaultPhoneNumber = "\(phone.numberDisplay) \(phone.countryName)"
        }
        return PstnIncomingCallInfo(isPstnEnabled: isPstnEnabled, defaultPhoneNumber: defaultPhoneNumber, phoneList: phoneList)
    }
}
