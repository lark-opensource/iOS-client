//
//  MailMessageListTemplate.swift
//  MailSDK
//
//  Created by majx on 2020/3/20.
//

import Foundation
import LarkFoundation
import LarkStorage
import MailNativeTemplate

struct MailMessageListTemplate {
    let template: String

    let sectionMain: String

    let sectionMessageLabelItem: String

    let sectionDraftItem: String

    let sectionSafetyTipAvatar: String

    let sectionMessageListAvatar: String

    let sectionMessageListNativeAvatar: String

    let sectionMessageListItem: String

    let sectionAttachmentTag: String

    let sectionPriorityTag: String

    let sectionPriorityBanner: String

    let setionSafeTipsMessageBanner: String

    let setionRecallMessageBanner: String

    let setionScheduleMessageBanner: String

    let sectionRecallTag: String

    let sectionAttachment: String

    let sectionTopAttachment: String
    
    let sectionMessageActionBar: String
    
    let sectionMessageLoadMore: String
    
    let sectionAttachmentListItem: String

    let sectionAttachmentSummary: String

    let sectionRecipientsItem: String

    let sectionAddressItem: String

    let sectionDelegationItem: String

    let sectionCalendarCard: String

    let sectionCalendarCardBody: String

    let sectionCalendarCardFeedback: String

    let sectionCalendarCardFooter: String

    let sectionCalendarCardInvalid: String

    let sectionCalendarCardRemoved: String

    let sectionCalendarCardNotFound: String

    let sectionFoldRecipientsList: String

    let sectionContextMenu: String

    let sectionBannerContainer: String

    let sectionItemContent: String

    let sectionMailListIcon: String

    let sectionGroupIcon: String

    let sectionRedirectBanner: String

    let sectionMessageHeaderItem: String

    let sectionMessageCoverHeaderItem: String

    let sectionNativeHeaderItem: String

    let sectionSendStatusBanner: String

    let sectionCalendarLoading: String

    let sectionMessageItemDivider: String

    let contentContainer: String

    let messageInnerContent: String

    let setionInterceptTipsMessageBanner: String

    let sectionReadReceiptTipsBanner: String

    let sectionImportantContactBanner: String

    let sectionMessageDraftContainer: String

    let isRemoteFile: Bool
    let baseURL: URL?

    let fontNormalBase64: String
    let fontBoldBase64: String

    init() {
        var templateHTMLContent: String?
        var dirBaseUrl: URL?
        let templateFileName = "template.html"

        var filePath = MailNativeTemplate.I18n.resourceBundle.bundlePath + "/\(templateFileName)"
        self.isRemoteFile = false
        #if DEBUG
        let kvStore = MailKVStore(space: .global, mSpace: .global)
        let loadLocalTemplate = kvStore.value(forKey: MailDebugViewController.kMailLoadLocalTemplate) ?? false
        if LarkFoundation.Utils.isSimulator && loadLocalTemplate {
            filePath = I18n.resourceBundle.bundlePath + "/\(templateFileName)"
            let templateRelativeDir = #file.replacingOccurrences(of: "MailMessageListTemplate.swift", with: "../../../../Resources/mail-native-template/template")
            filePath = templateRelativeDir + "/\(templateFileName)"
            MailLogger.info("MailMessageListTemplate filePath \(filePath ?? "")")
        }
        #endif

        do {
            templateHTMLContent = try String.read(from: AbsPath(filePath), encoding: .utf8)
            let baseURLString = URL(fileURLWithPath: filePath).deletingLastPathComponent().path
            dirBaseUrl = URL(fileURLWithPath: baseURLString, isDirectory: true)
        } catch {
            MailLogger.error("MailMessageListTemplate \(error)")
        }

        if let dirBaseUrl = dirBaseUrl {
            baseURL = dirBaseUrl
        } else {
            if let resourcePath = BundleConfig.MailSDKBundle.resourceURL {
                baseURL = URL(fileURLWithPath: resourcePath.path, isDirectory: true)
            } else {
                baseURL = nil
            }
            // 请检查项目内是否有 MailSDK/Resources/mail-native-template/template/template.html 文件
            mailAssertionFailure("MailMessageListTemplate baseUrlError")
        }
        template = templateHTMLContent ?? ""
        sectionMain = template.getTemplateSectionWithName("main") ?? "<html><body>No Content</body></html>"
        sectionMessageLabelItem = template.getTemplateSectionWithName("message_label_item") ?? ""
        sectionDraftItem = template.getTemplateSectionWithName("draft_item") ?? ""
        sectionMessageListAvatar = template.getTemplateSectionWithName("message_list_avatar") ?? ""
        sectionMessageListNativeAvatar = template.getTemplateSectionWithName("message_list_native_avatar") ?? ""
        sectionMessageListItem = template.getTemplateSectionWithName("message_list_item") ?? ""
        sectionAttachmentTag = template.getTemplateSectionWithName("attachment_tag") ?? ""
        sectionPriorityTag = template.getTemplateSectionWithName("priority_tag") ?? ""
        sectionPriorityBanner = template.getTemplateSectionWithName("priority_banner") ?? ""
        setionSafeTipsMessageBanner = template.getTemplateSectionWithName("safe_tips_banner") ?? ""
        sectionSafetyTipAvatar = template.getTemplateSectionWithName("safety_tip_avatar") ?? ""
        setionRecallMessageBanner = template.getTemplateSectionWithName("recall_message_banner") ?? ""
        setionScheduleMessageBanner = template.getTemplateSectionWithName("schedule_message_banner") ?? ""
        sectionRecallTag = template.getTemplateSectionWithName("recall_tag") ?? ""
        sectionAttachment = template.getTemplateSectionWithName("attachment") ?? ""
        sectionTopAttachment = template.getTemplateSectionWithName("top-attachment") ?? ""
        sectionMessageActionBar = template.getTemplateSectionWithName("message-action-bar-container") ?? ""
        sectionMessageLoadMore = template.getTemplateSectionWithName("message-loadmore-container") ?? ""
        sectionAttachmentListItem = template.getTemplateSectionWithName("attachment_list_item") ?? ""
        sectionAttachmentSummary = template.getTemplateSectionWithName("attachment_summary") ?? ""
        sectionRecipientsItem = template.getTemplateSectionWithName("recipients_item") ?? ""
        sectionAddressItem = template.getTemplateSectionWithName("address_item") ?? ""
        sectionDelegationItem = template.getTemplateSectionWithName("delegation_item") ?? ""
        sectionCalendarCard = template.getTemplateSectionWithName("calendar-card") ?? ""
        sectionCalendarCardBody = template.getTemplateSectionWithName("calendar-card-body") ?? ""
        sectionCalendarCardFeedback = template.getTemplateSectionWithName("calendar-card-feedback") ?? ""
        sectionCalendarCardFooter = template.getTemplateSectionWithName("calendar-card-footer") ?? ""
        sectionCalendarCardInvalid = template.getTemplateSectionWithName("calendar-card-invalid") ?? ""
        sectionCalendarCardRemoved = template.getTemplateSectionWithName("calendar-card-removed") ?? ""
        sectionCalendarCardNotFound = template.getTemplateSectionWithName("calendar-card-notfound") ?? ""
        sectionFoldRecipientsList = template.getTemplateSectionWithName("fold_recipients_list") ?? ""
        sectionContextMenu = template.getTemplateSectionWithName("context-menu") ?? ""
        sectionBannerContainer = template.getTemplateSectionWithName("banner_container") ?? ""
        sectionItemContent = template.getTemplateSectionWithName("item-content") ?? ""
        sectionMailListIcon = template.getTemplateSectionWithName("address-mail-list-icon") ?? ""
        sectionGroupIcon = template.getTemplateSectionWithName("address-group-icon") ?? ""
        sectionRedirectBanner = template.getTemplateSectionWithName("message-redirect-banner") ?? ""
        sectionMessageHeaderItem = template.getTemplateSectionWithName("message_header_item") ?? ""
        sectionMessageCoverHeaderItem = template.getTemplateSectionWithName("message_header_item_with_cover") ?? ""
        sectionNativeHeaderItem = template.getTemplateSectionWithName("native_header_item") ?? ""
        sectionSendStatusBanner = template.getTemplateSectionWithName("send_status_banner") ?? ""
        sectionCalendarLoading = template.getTemplateSectionWithName("calendar-loading") ?? ""
        sectionMessageItemDivider = template.getTemplateSectionWithName("message_item_divider") ?? ""
        contentContainer = template.getTemplateSectionWithName("content-container") ?? ""
        messageInnerContent = template.getTemplateSectionWithName("message-inner-content") ?? ""
        setionInterceptTipsMessageBanner = template.getTemplateSectionWithName("intercept_tips_banner") ?? ""
        sectionReadReceiptTipsBanner = template.getTemplateSectionWithName("read_receipt_request_banner") ?? ""
        sectionImportantContactBanner = template.getTemplateSectionWithName("important-contact-banner") ?? ""
        sectionMessageDraftContainer = template.getTemplateSectionWithName("message-draft-container") ?? ""
        (fontNormalBase64, fontBoldBase64) = getLarkCircularFontBase64String()
    }
}
