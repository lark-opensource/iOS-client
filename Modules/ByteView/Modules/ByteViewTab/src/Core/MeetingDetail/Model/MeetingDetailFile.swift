//
//  MeetingDetailFile.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2022/11/22.
//

import Foundation
import ByteViewNetwork
import UniverseDesignIcon
import RxSwift

class MeetingDetailFile {
    let title: String
    var icon: UIImage?
    let url: String?
    let desc: ((@escaping (String) -> Void) -> Void)?
    let isActive: Bool
    var statisticsStatus: TabStatisticsInfo.Status?
    var canForward: Bool = false
    var isMinutes: Bool = false
    var shouldShowOnboarding: Bool = false
    var isRecordingFile: Bool = false
    var isLocked: Bool = false
    var coverUrl: String?
    var breakoutMinutesCount: Int = 0
    var userName: ((@escaping (String) -> Void) -> Void)?
    var objectID: Int64 = 0
    var minutesDuration: Int64 = 0

    var isMinutesCollection: Bool {
        breakoutMinutesCount > 1
    }

    var docsIconDependency: TabDocsIconDependency?

    init(followModel: FollowAbbrInfo, meetingID: String, participantService: ParticipantService, docsIconDependency: TabDocsIconDependency) {
        self.title = followModel.fileTitle.isEmpty ? followModel.shareSubtype.defaultTitle : followModel.fileTitle
        self.url = followModel.rawURL
        self.icon = followModel.shareSubtype.icon
        self.docsIconDependency = docsIconDependency
        self.desc = { configer in
            participantService.participantInfo(pids: followModel.presenters, meetingId: meetingID) { users in
                configer("\(I18n.View_G_SharedBy)\(users.map { $0.name }.joined(separator: ", "))")
            }
        }
        self.isActive = true
    }

    init(statisticsInfo: TabStatisticsInfo, docsIconDependency: TabDocsIconDependency) {
        self.title = statisticsInfo.statisticsFileTitle.isEmpty ? I18n.View_VM_UntitledSheet : statisticsInfo.statisticsFileTitle
        self.url = statisticsInfo.statisticsURL
        self.icon = statisticsInfo.isBitable ? FollowShareSubType.ccmBitable.icon : FollowShareSubType.ccmSheet.icon
        self.docsIconDependency = docsIconDependency
        self.isActive = true
        self.desc = nil
        self.statisticsStatus = statisticsInfo.status
    }

    init(voteStatisticsInfo: TabVoteStatisticsInfo, meetingID: String, participantService: ParticipantService, docsIconDependency: TabDocsIconDependency) {
        if let statisticsFileTitle = voteStatisticsInfo.statisticsFileTitle {
            self.title = statisticsFileTitle.isEmpty ? I18n.View_G_ServerNoTitle : statisticsFileTitle
        } else {
            self.title = I18n.View_VM_UntitledSheet
        }
        self.url = voteStatisticsInfo.statisticsURL
        self.icon = UDIcon.getIconByKey(.fileSheetColorful, size: CGSize(width: 32, height: 32))
        self.docsIconDependency = docsIconDependency
        self.desc = { configer in
            guard let owner = voteStatisticsInfo.owner else { return }
            participantService.participantInfo(pid: owner, meetingId: meetingID) { user in
                configer("\(I18n.View_MV_MinuteFileOwner_Note(user.name))")
            }
        }
        self.isActive = true
        self.canForward = true
    }

    init(info: TabDetailRecordInfo.MinutesInfo, icon: UIImage?, meetingID: String, participantService: ParticipantService, breakoutMinutesCount: Int = 0) {
        var topic = info.topic
        if topic.isEmpty {
            topic = I18n.View_G_ServerNoTitle
        }
        self.title = topic
        self.url = info.url
        self.isActive = true
        self.icon = icon
        self.canForward = info.hasViewPermission
        self.isMinutes = true
        self.isRecordingFile = true
        self.desc = { configer in
            participantService.participantInfo(pid: info, meetingId: meetingID) { user in
                var desc = I18n.View_MV_MinuteFileOwner_Note(user.name, lang: nil)
                if breakoutMinutesCount > 1 {
                    desc = I18n.View_G_Collection + " ︳" + I18n.View_MV_MinuteFileOwner_Note(user.name, lang: nil)
                }
                configer(desc)
            }
        }
        self.coverUrl = info.coverUrl
        self.isLocked = !info.hasViewPermission
        self.breakoutMinutesCount = breakoutMinutesCount
        self.userName = { configer in
            participantService.participantInfo(pid: info, meetingId: meetingID) { user in
                configer(user.name)
            }
        }
    }

    init(info: TabDetailRecordInfo.MinutesInfo, icon: UIImage?, objectID: Int64 = 0) {
        var topic = info.topic
        if topic.isEmpty {
            topic = I18n.View_G_ServerNoTitle
        }
        self.title = topic
        self.url = info.url
        self.isActive = true
        self.icon = icon
        self.canForward = info.hasViewPermission
        self.isMinutes = true
        self.isRecordingFile = true
        self.coverUrl = info.coverUrl
        self.isLocked = !info.hasViewPermission
        self.desc = nil
        self.objectID = objectID
    }

    init(info: TabNotesInfo,
         meetingID: String,
         participantService: ParticipantService,
         breakoutMinutesCount: Int = 0,
         docsIconDependency: TabDocsIconDependency) {
        self.title = info.fileTitle
        self.url = info.notesURL
        self.isActive = true
        self.icon = UDIcon.getIconByKeyNoLimitSize(.fileDocColorful)
        self.docsIconDependency = docsIconDependency
        self.canForward = true
        self.isMinutes = false
        self.isRecordingFile = false
        self.isLocked = false
        self.desc = { configer in
            participantService.participantInfo(pid: info.owner.participantId.pid, meetingId: meetingID) { user in
                configer(I18n.View_MV_MinuteFileOwner_Note(user.name, lang: nil))
            }
        }
    }

    init(info: TabDetailRecordInfo.RecordInfo, icon: UIImage?, meetingID: String, participantService: ParticipantService, breakoutMinutesCount: Int = 0) {
        var topic = info.topic
        if topic.isEmpty {
            topic = I18n.View_G_ServerNoTitle
        }
        self.title = topic
        self.url = info.url
        self.isActive = true
        self.icon = icon
        self.canForward = true
        self.isMinutes = false
        self.isRecordingFile = true
        self.desc = { configer in
            participantService.participantInfo(pid: info, meetingId: meetingID) { user in
                var desc = I18n.View_MV_MinuteFileOwner_Note(user.name, lang: nil)
                if breakoutMinutesCount > 1 {
                    desc = I18n.View_G_Collection + " ︳" + I18n.View_MV_MinuteFileOwner_Note(user.name, lang: nil)
                }
                configer(desc)
            }
        }
        self.breakoutMinutesCount = breakoutMinutesCount
        self.userName = { configer in
            participantService.participantInfo(pid: info, meetingId: meetingID) { user in
                configer(user.name)
            }
        }
    }

    init(url: String, topic: String, icon: UIImage?, meetingID: String) {
        var topic = topic
        if topic.isEmpty {
            topic = I18n.View_G_ServerNoTitle
        }
        self.title = topic
        self.url = url
        self.isActive = true
        self.icon = icon
        self.canForward = true
        self.isMinutes = false
        self.isRecordingFile = true
        self.desc = nil
    }

    init(info: TabDetailChatHistoryV2, meetingID: String, participantService: ParticipantService, docsIconDependency: TabDocsIconDependency) {
        self.title = info.title
        self.url = info.url
        self.icon = info.type.icon
        self.docsIconDependency = docsIconDependency
        self.isActive = true
        self.canForward = self.isActive
        self.isMinutes = false
        self.desc = { configer in
            participantService.participantInfo(pid: info.owner, meetingId: meetingID) { user in
                configer(I18n.View_MV_MinuteFileOwner_Note(user.name, lang: nil))
            }
        }
    }

    init(info: TabDetailCheckinInfo, meetingID: String, participantService: ParticipantService, docsIconDependency: TabDocsIconDependency) {
        self.title = info.title
        self.url = info.url
        self.icon = UDIcon.getIconByKeyNoLimitSize(.fileBitableColorful)
        self.docsIconDependency = docsIconDependency
        self.isActive = true
        self.canForward = self.isActive
        self.isMinutes = false
        self.desc = { configer in
            participantService.participantInfo(pid: ParticipantId(id: info.ownerUserId, type: .larkUser), meetingId: meetingID) { user in
                configer(I18n.View_MV_MinuteFileOwner_Note(user.name, lang: nil))
            }
        }
    }

    init(info: BitableInfo, meetingID: String, participantService: ParticipantService, docsIconDependency: TabDocsIconDependency) {
        self.title = info.title
        self.url = info.url
        self.icon = UDIcon.getIconByKeyNoLimitSize(.fileBitableColorful)
        self.docsIconDependency = docsIconDependency
        self.isActive = true
        self.canForward = self.isActive
        self.isMinutes = false
        self.desc = { configer in
            participantService.participantInfo(pid: info.owner.participantId, meetingId: meetingID) { user in
                configer(I18n.View_MV_MinuteFileOwner_Note(user.name, lang: nil))
            }
        }
    }

    init(placeholderType: TabDetailRecordInfo.RecordType, topic: String, isMinutes: Bool = true, breakoutMinutesCount: Int = 0, objectID: Int64 = 0) {
        var topic = topic
        if topic.isEmpty {
            topic = I18n.View_G_ServerNoTitle
        }
        self.title = topic
        self.isActive = false
        self.icon = placeholderType.icon
        self.url = nil
        self.desc = nil
        self.isMinutes = isMinutes
        self.isRecordingFile = true
        self.breakoutMinutesCount = breakoutMinutesCount
        self.objectID = objectID
    }
}

extension TabDetailChatHistoryV2.DocType {
    var icon: UIImage {
        switch self {
        case .doc: return UDIcon.getIconByKeyNoLimitSize(.fileDocColorful)
        case .docx: return UDIcon.getIconByKeyNoLimitSize(.fileDocxColorful)
        default: return UDIcon.getIconByKeyNoLimitSize(.fileUnknowColorful)
        }
    }
}

extension FollowShareSubType {
    var icon: UIImage {
        switch self {
        case .ccmDoc, .ccmWikiDoc: return UDIcon.getIconByKeyNoLimitSize(.fileDocColorful)
        case .ccmPpt: return UDIcon.getIconByKeyNoLimitSize(.filePptColorful)
        case .ccmPdf: return UDIcon.getIconByKeyNoLimitSize(.filePdfColorful)
        case .ccmExcel: return UDIcon.getIconByKeyNoLimitSize(.fileExcelColorful)
        case .ccmMindnote, .ccmWikiMindnote: return UDIcon.getIconByKeyNoLimitSize(.fileMindnoteColorful)
        case .ccmSheet, .ccmWikiSheet: return UDIcon.getIconByKeyNoLimitSize(.fileSheetColorful)
        case .ccmWord: return UDIcon.getIconByKeyNoLimitSize(.fileWordColorful)
        case .ccmBitable: return UDIcon.getIconByKeyNoLimitSize(.fileBitableColorful)
        case .ccmDemonstration: return UDIcon.getIconByKeyNoLimitSize(.fileSlideColorful)
        case .ccmDocx, .ccmWikiDocX: return UDIcon.getIconByKeyNoLimitSize(.fileDocxColorful)
        default: return UDIcon.getIconByKeyNoLimitSize(.fileUnknowColorful)
        }
    }

    var defaultTitle: String {
        switch self {
        case .ccmSheet: return I18n.View_VM_UntitledSheet
        case .ccmMindnote: return I18n.View_VM_UntitledMindnote
        default: return I18n.View_VM_UntitledDocument
        }
    }
}

extension TabDetailRecordInfo.RecordType {
    var icon: UIImage? {
        switch self {
        case .larkMinutes: return UDIcon.getIconByKeyNoLimitSize(.minutesLogoFilled, iconColor: .ud.W600.dynamicColor)
        case .record: return UDIcon.getIconByKeyNoLimitSize(.minutesLogoFilled, iconColor: .ud.iconDisabled)
        }
    }
}

extension TabDetailRecordInfo.MinutesInfo: ParticipantIdConvertible {
    public var participantId: ParticipantId {
        ParticipantId(id: owner.id, type: ParticipantType(rawValue: owner.type.rawValue), deviceId: owner.deviceId)
    }
}

extension TabDetailRecordInfo.RecordInfo: ParticipantIdConvertible {
    public var participantId: ParticipantId {
        ParticipantId(id: owner.id, type: ParticipantType(rawValue: owner.type.rawValue), deviceId: owner.deviceId)
    }
}
