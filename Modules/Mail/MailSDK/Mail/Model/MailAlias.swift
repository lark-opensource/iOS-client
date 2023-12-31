//
//  MailAlias.swift
//  MailSDK
//
//  Created by 谭志远 on 2019/6/3.
//

import Foundation
import RustPB
import ServerPB

// mails.pb
public typealias MailInboxType = RustPB.Email_V1_MailInboxType

public typealias MailThreadFilterType = RustPB.Email_Client_V1_FilterType

// mail_entities.pb
// public typealias MailAddress = RustPB.Address
// public typealias MailAttachment = RustPB.Attachment
// public typealias MailImage = RustPB.MailImage
// public typealias MailContent = RustPB.MailContent
// public typealias MailStatus = RustPB.MailStatus
// public typealias MailMessage = RustPB.MailMessage
// public typealias MailDraft = RustPB.MailDraft
// public typealias MailThread = RustPB.MailThread

// mail_client_entities.pb
public typealias MailClientAddress = RustPB.Email_Client_V1_Address
public typealias MailClientGroupType = RustPB.Email_Client_V1_MailGroupType
public typealias MailClientAttachement = RustPB.Email_Client_V1_Attachment
public typealias MailClientDraftImage = RustPB.Email_Client_V1_DraftImage
public typealias MailClientFilterStatus = RustPB.Email_Client_V1_FilterStatus
public typealias MailClientMessage = RustPB.Email_Client_V1_Message
public typealias MailClientDraft = RustPB.Email_Client_V1_Draft
public typealias MailDraftPayload = RustPB.Email_Client_V1_MailUpdateDraftRequest.Payload
// public typealias MailClientThread = RustPB.Email_Client_V1_Thread
public typealias MailThreadAction = RustPB.Email_Client_V1_ThreadAction
public typealias MailClientLabel = RustPB.Email_Client_V1_Label
public typealias ThreadSecurity = RustPB.Email_Client_V1_Security
public typealias MailClientFilterType = RustPB.Email_Client_V1_FilterType
public typealias MailClientMessageDeliveryState = RustPB.Email_Client_V1_Message.DeliveryState
public typealias MailClientDocsPermissionConfig = RustPB.Email_Client_V1_DocsPermissionConfig
public typealias MailClientModelDocStruct = RustPB.Email_Client_V1_DocStruct
public typealias Doc = RustPB.Basic_V1_Doc
public typealias DocsInMailPermAction = RustPB.Email_Client_V1_DocsPermissionConfig.Action
public typealias ContactType = RustPB.Email_Client_V1_MailContactSearchResult.TypeEnum
public typealias ContactTagType = RustPB.Email_Client_V1_MailContactSearchResult.TagType
public typealias MailGroupMemberCountInfo = RustPB.Email_Client_V1_GroupMemberCountInfo
public typealias MailPermissionCode = RustPB.Email_Client_V1_PermissionCode
public typealias MailUserEngagementSetting = RustPB.Email_Client_V1_UserEngagementSetting
public typealias MailUserGuidePair = RustPB.Onboarding_V1_UserGuideViewAreaPair
public typealias MailAccount = RustPB.Email_Client_V1_MailAccount
public typealias MailBatchChangesAction = RustPB.Email_V1_MailBatchChangesEnd.Action
public typealias MailSyncEvent = RustPB.Email_Client_V1_MailSyncEventResponse.SyncEvent
public typealias MailOAuthURLType = RustPB.Email_Client_V1_MailGetOAuthURLRequest.OAuthType
public typealias MailDownloadStatus = RustPB.Email_Client_V1_MailPushDownloadCallback.Status
public typealias MailDownloadFailInfo = RustPB.Email_Client_V1_DownloadFailInfo
public typealias MailUploadStatus = RustPB.Email_Client_V1_MailPushUploadCallback.Status
public typealias MailTripartiteAccount = RustPB.Email_Client_V1_TripartiteAccount
public typealias MailTripartiteProvider = RustPB.Email_Client_V1_TripartiteProvider
public typealias MailIMAPMigrationOldestMessage = RustPB.Email_Client_V1_MailIMAPMigrationGetOldestMessageResponse
public typealias MailMixSearchState = RustPB.Email_Client_V1_MixedSearchState
public typealias MailBatchResultScene = RustPB.Email_Client_V1_MailBatchChanges.Scene
public typealias MailBatchResultStatus = RustPB.Email_Client_V1_MailGetLongRunningTaskResponse.TaskStatus
public typealias MailReplyType = RustPB.Email_Client_V1_ReplyType
public typealias MailPriorityType = RustPB.Email_Client_V1_PriorityType
public typealias MailDownloadProgressStatus = RustPB.Space_Drive_V1_PushDownloadCallback.Status
public typealias MailDownloadProgressInfo = RustPB.Space_Drive_V1_PushDownloadCallback
public typealias MailCleanCacheType = RustPB.Email_Client_V1_MailClientCleanCachePushResponse.MailClientCleanCacheType

// 日程相关
typealias MailCalendarEventInfo = Basic_V1_EmailCalendarEventInfo
// public typealias MailCalendarEventUnkown = Basic_V1_EmailCalendarEventInfo.Unkown
typealias MailCalendarEventInvite = Basic_V1_EmailCalendarEventInfo.EventInvite
typealias MailCalendarEventUpdate = Basic_V1_EmailCalendarEventInfo.EventUpdate
typealias MailCalendarEventUpdateOutdated = Basic_V1_EmailCalendarEventInfo.EventUpdateOutdated
typealias MailCalendarEventReply = Basic_V1_EmailCalendarEventInfo.EventReply
typealias MailCalendarFullEventInfo = Basic_V1_EmailCalendarEventInfo.FullEventInfo
typealias MailCalendarPartEventInfo = Basic_V1_EmailCalendarEventInfo.PartEventInfo
typealias MailCalendarAttendeeStatus = Basic_V1_EmailCalendarEventInfo.AttendeeStatus
// public typealias MailCalendarMessageType = Basic_V1_EmailCalendarEventInfo.CalendarMailMessageType
typealias MailCalendarEventReplyOption = Email_Client_V1_MailReplyCalendarEventRequest.Option

// TODO: 需要包装一层Model
// mail_client.pb
public typealias MailThreadItem = RustPB.Email_Client_V1_MailGetThreadListResponse.ThreadItem
// public typealias Payload = RustPB.Email_Client_V1_MailUpdateThreadRequest.Payload
public typealias DraftAction = RustPB.Email_Client_V1_MailCreateDraftRequest.CreateDraftAction
public typealias MailMessageItem = RustPB.Email_Client_V1_MessageItem
public typealias FromViewMailMessageItem = RustPB.Email_Client_V1_FromViewMessageItem
public typealias MailFeedDraftItem = RustPB.Email_Client_V1_FromViewDraftItem
// image.pb
// public typealias MailSecureImageType = RustPB.Media_V1_UploadSecureImageRequest.TypeEnum

// requset & response
public typealias MailGetThreadListResponse = Email_Client_V1_MailGetThreadListResponse
public typealias GetAuthURLRequest = RustPB.Email_Client_V1_MailGetOAuthURLRequest
public typealias GetAuthURLResponse = RustPB.Email_Client_V1_MailGetOAuthURLResponse
public typealias OutBoxMessageInfo = RustPB.Email_Client_V1_OutboxMessageInfo

// event
public typealias ClientEvent = RustPB.Email_Client_V1_MailNoticeClientEventRequest.Event

public typealias EmailAlias = RustPB.Email_Client_V1_EmailAlias

public typealias LarkContactSource = RustPB.Basic_V1_ContactSource

public typealias AppConfig = RustPB.Basic_V1_AppConfig

public typealias UnreadCountColor = RustPB.Email_Client_V1_UnreadCountColor

// push
public typealias DynamicNetStatus = RustPB.Basic_V1_DynamicNetStatusResponse.NetStatus
public typealias RecallStatus = RustPB.Email_Client_V1_Message.RecallStatus

typealias SendHttpRequest = RustPB.Basic_V1_SendHttpRequest
typealias SendHttpResponse = RustPB.Basic_V1_SendHttpResponse

typealias SendStatusByMessageIDRequest = ServerPB_Mails_GetMessageSendStatusByMessageIDRequest
typealias SendStatusByMessageIDResp = ServerPB_Mails_GetMessageSendStatusByMessageIDResponse
typealias SendStatusDetail = ServerPB.ServerPB_Mail_entities_MailSendStatusDetail
typealias ServerRequestBase = ServerPB_Mail_entities_MailRequestBase
typealias ServerShareEmailAccount = ServerPB_Mail_entities_SharedEmailAccount
typealias SendStatus = ServerPB_Mail_entities_MailSendStatusDetail.DetailStatus
typealias FileRiskTag = ServerPB_Compliance_MGetRiskTagByTokenResponse.FileRiskTag
typealias FileBannedInfo = ServerPB_Mails_BannedInfo
public typealias SigListData = RustPB.Email_Client_V1_MailGetSignatureResponse
typealias MailSignature = RustPB.Email_Client_V1_MailSignature
typealias SignatureUsage = RustPB.Email_Client_V1_MailSignatureUsage
public typealias MailOldSignature = Email_Client_V1_Signature
typealias largeTokenReq = RustPB.Email_Client_V1_MailTranslateLargeTokenRequest
typealias largeTokenResp = RustPB.Email_Client_V1_MailTranslateLargeTokenResponse
typealias DraftCalendarEvent = RustPB.Email_Client_V1_DraftCalendarEvent
public typealias CalendarBasicEvent = RustPB.Calendar_V1_CalendarBasicEvent
public typealias CalendarLocation = RustPB.Calendar_V1_CalendarLocation
public typealias CalendarEventAtteedee = RustPB.Calendar_V1_CalendarEventAttendee
public typealias CalendarMeetingconfig = RustPB.Calendar_V1_EventVideoMeetingConfig
public typealias CalendarMeeting = RustPB.Calendar_V1_VideoMeeting
public typealias CalendarEventResult = (CalendarEventModel) -> Void
public typealias CalendarEventModel = (
    CalendarBasicEvent,
    CalendarLocation,
    [CalendarEventAtteedee],
    CalendarMeeting,
    Calendar_V1_CalendarEventRef,
    [Calendar_V1_CalendarEventReminder]
)
typealias MailAddressNamePush = RustPB.Email_Client_V1_UpdateAddressNamePacket
typealias MailUpdateCleanMessageStatusReq = ServerPB_Mails_UpdateCleanMessageStatusRequest
typealias MailUpdateCleanMessageStatusResp = ServerPB_Mails_UpdateCleanMessageStatusResponse

typealias MailLargeAttachmentInfo = ServerPB_Mails_LargeAttachmentInfo
typealias MailLargeAttachmentStatus = ServerPB_Mails_LargeAttachmentStatus
typealias MailLargeAttachmentInfoListType = ServerPB_Mails_LargeAttachmentInfoListType
typealias MailOrderFiled = ServerPB_Mails_OrderFiled
typealias MailOrderType = ServerPB_Mails_OrderType
typealias MailListLargeAttachmentReq = ServerPB_Mails_ListLargeAttachmentRequest
typealias MailListLargeAttachmentResp = ServerPB_Mails_ListLargeAttachmentResponse
typealias MailDeleteLargeAttachmentReq = ServerPB_Mails_MDeleteLargeAttachmentRequest
typealias MailDeleteLargeAttachmentResp = ServerPB_Mails_MDeleteLargeAttachmentResponse
typealias MailLargeAttachmentCapacityReq = ServerPB_Mails_GetLargeAttachmentCapacityRequest
typealias MailLargeAttachmentCapacityResp = ServerPB_Mails_GetLargeAttachmentCapacityResponse
typealias MailCheckAttachmentMountPermissionReq = ServerPB_Mails_CheckAttachmentMountPermissionRequest
typealias MailCheckAttachmentMountPermissionResp = ServerPB_Mails_CheckAttachmentMountPermissionResponse

typealias MailFileDownloadScene = Email_Client_V1_MailFileDownloadRequest.MailFileDownloadScene
