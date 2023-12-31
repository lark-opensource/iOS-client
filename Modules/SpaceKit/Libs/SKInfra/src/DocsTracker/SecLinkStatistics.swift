//
//  SecLinkStatistics.swift
//  SpaceKit
//
//  Created by lizechuang on 2019/12/9.
//
//点击链接的上报 https://bytedance.feishu.cn/docs/doccnzzp51OvlcXraWINo8rXw3d

import SKFoundation
import SpaceInterface

public final class SecLinkStatistics {
    public class func didClickLink(sourceURL: URL?) {
        guard let url = sourceURL else {
            return
        }
        guard let parameters = Self.parseURL(sourceURL: url) else {
            return
        }
        Self.recordClickLinkStatistics(scene: parameters.scene, location: parameters.location)
    }

    public class func recordClickLinkStatistics(scene: SecLinkScene, location: SecLinkLocation) {
        DocsTracker.log(enumEvent: .linkClicked, parameters: ["scene": scene.rawValue, "location": location.rawValue])
    }

//    public class func didClickEventDescriptionLink(sourceURL: URL?) {
//        guard let url = sourceURL else {
//            return
//        }
//        let path = url.path
//        if path.contains("calendar_v2") {
//            Self.recordClickLinkStatistics(scene: .calendar, location: .eventDescription)
//        }
//    }

    public class func didClickFeedContentLink(type: DocsType?) {
        guard let type = type else {
            return
        }
        let scene = SecLinkScene.ccm
        var location = SecLinkLocation.ccmDocs
        switch type {
        case .doc:
            location = .ccmDocs
        case .sheet:
            location = .ccmSheet
        case .bitable:
            location = .ccmBitable
        case .mindnote:
            location = .ccmMindnote
        case .file:
            location = .ccmDrive
        case .slides:
            location = .ccmSlides
        case .wiki:
            location = .ccmWiki
        default:
            return
        }
        Self.recordClickLinkStatistics(scene: scene, location: location)
    }

    private class func parseURL(sourceURL: URL) -> (scene: SecLinkScene, location: SecLinkLocation)? {
        let queryParameters = sourceURL.queryParameters
        let path = sourceURL.path
        var scene = SecLinkScene.ccm
        var location = SecLinkLocation.ccmDocs
        if let from = queryParameters["from"] {
            switch from {
            case "calendar":
                scene = .ccm
                location = .openDocConferenceRecords
            case "group_tab_notice":
                scene = .messenger
                location = .messengerGroupAnnouncement
            case "docs_feed":
                scene = .messenger
                location = .messengerLarkFeed
            default:
                scene = .ccm
                guard let curLocation = Self.judgeLocation(sourcePath: path) else {
                    return nil
                }
                location = curLocation
            }
        } else {
            scene = .ccm
            guard let curLocation = Self.judgeLocation(sourcePath: path) else {
                return nil
            }
            location = curLocation
        }
        return (scene, location)
    }

    private class func judgeLocation(sourcePath: String) -> SecLinkLocation? {
        if sourcePath.contains("docs") {
            return .ccmDocs
        }
        if sourcePath.contains("sheets") {
            return .ccmSheet
        }
        if sourcePath.contains("slides") {
            return .ccmSlides
        }
        if sourcePath.contains("mindnotes") {
            return .ccmMindnote
        }
        if sourcePath.contains("wiki") {
            return .ccmWiki
        }
        return nil
    }
}
extension SecLinkStatistics {
    public enum SecLinkScene: String {
        case ccm
        case email
        case calendar
        case messenger
    }

    public enum SecLinkLocation: String {
        case ccmDocs = "ccm_docs"
        case ccmSheet = "ccm_sheet"
        case ccmSlides = "ccm_slides"
        case ccmBitable = "ccm_bitable"
        case ccmMindnote = "ccm_mindnote"
        case ccmDrive = "ccm_drive"
        case ccmWiki = "ccm_wiki"
        case driveSdkCreation = "drivesdk_creation"
        case emailAttachmentPreview = "email_attachment_preview"
        case eventAttachmentPreview = "event_attachment_preview"
        case eventDescription = "event_description"
        case docsSdkComment = "docs_sdk_comment"
        case messengerGroupAnnouncement = "messenger_group_announcement"
        case openDocConferenceRecords = "opendoc_conference records"
        case messengerLarkFeed = "messenger_lark_feed"
        case opGadget = "op_gadget"
    }
}
