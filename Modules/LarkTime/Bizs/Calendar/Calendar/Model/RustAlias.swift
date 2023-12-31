//
//  Alias.swift
//  Calendar
//
//  Created by SolaWing on 2019/10/12.
//

import Foundation
import RustPB
import ServerPB

public enum Rust {}
public enum Server {}

public typealias CalendarEvent = RustPB.Calendar_V1_CalendarEvent
public typealias EventAttendeeStatistics = RustPB.Calendar_V1_EventAttendeeInfo
public typealias SkinSetting = RustPB.Calendar_V1_SkinSetting
public typealias MappingColor = RustPB.Calendar_V1_MappingColor
public typealias CalendarEventInstance = RustPB.Calendar_V1_CalendarEventInstance
public typealias WorkHourSetting = RustPB.Calendar_V1_WorkHourSetting
public typealias GetChatterProfileResponse = RustPB.Contact_V1_GetChatterProfileResponse
public typealias Chatter = RustPB.Basic_V1_Chatter
public typealias CalendarSetting = RustPB.Calendar_V1_CalendarSetting
public typealias CalendarTenantSetting = RustPB.Calendar_V1_CalendarTenantSetting
public typealias GetConfigSettingsResponse = RustPB.Calendar_V1_GetConfigSettingsResponse
public typealias RedDotUiItem = RustPB.Calendar_V1_RedDotUiItem
public typealias MarkRedDotsDisappearResponse = RustPB.Calendar_V1_MarkRedDotsDisappearResponse
public typealias EventOperationType = RustPB.Calendar_V1_EventOperationType
public typealias NotificationBoxType = RustPB.Calendar_V1_NotificationBoxType
public typealias JudgeNotificationBoxTypeResponse = RustPB.Calendar_V1_JudgeNotificationBoxTypeResponse
public typealias DayInstancesSlotMetric = RustPB.Calendar_V1_DayInstancesSlotMetric
public typealias GetInstancesLayoutResponse = RustPB.Calendar_V1_GetInstancesLayoutResponse
public typealias GetMeetingEventResponse = RustPB.Calendar_V1_GetMeetingEventResponse
public typealias GetMeetingsByChatIdsResponse = RustPB.Calendar_V1_GetMeetingsByChatIdsResponse
public typealias MarkMeetingEnteredResponse = RustPB.Calendar_V1_MarkMeetingEnteredResponse
public typealias CalendarEventUniqueField = RustPB.Calendar_V1_CalendarEventUniqueField
public typealias CalendarEventAttendee = RustPB.Calendar_V1_CalendarEventAttendee
public typealias CalendarLocation = RustPB.Calendar_V1_CalendarLocation
public typealias CalendarAlarm = RustPB.Calendar_V1_CalendarAlarm
public typealias DayInstanceLayout = RustPB.Calendar_V1_DayInstancesLayout
public typealias MultiCalendarSearchResponse = RustPB.Calendar_V1_MultiCalendarSearchResponse
public typealias UpdateCalendarVisibilityResponse = RustPB.Calendar_V1_UpdateCalendarVisibilityResponse
public typealias SyncCalendarsAndEventsResponse = RustPB.Calendar_V1_SyncCalendarsAndEventsResponse
public typealias GetAllCalendarsResponse = RustPB.Calendar_V1_GetAllCalendarsResponse
public typealias GetBuildingsResponse = RustPB.Calendar_V1_GetBuildingsResponse
public typealias GetMeetingRoomsStatusInformationRequest = RustPB.Calendar_V1_GetMeetingRoomsStatusInformationRequest
public typealias GetMeetingRoomsStatusInformationResponse = RustPB.Calendar_V1_GetMeetingRoomsStatusInformationResponse
public typealias MeetingRoomInfo = RustPB.Calendar_V1_MeetingRoomInformation
public typealias SubscriptionInfo = RustPB.Calendar_V1_MeetingRoomSubscriptionInfo
public typealias UnusableReasons = RustPB.Calendar_V1_MeetingRoomUnusableReasons
public typealias StatusInformation = RustPB.Calendar_V1_GetMeetingRoomsStatusInformationResponse.StatusInformation
public typealias MeetingRoomStatus = RustPB.Calendar_V1_MeetingRoomStatus
public typealias PullAttendeeDisplayInfoListRequest = RustPB.Calendar_V1_PullAttendeeDisplayInfoListRequest
public typealias PullAttendeeDisplayInfoListResponse = RustPB.Calendar_V1_PullAttendeeDisplayInfoListResponse
public typealias PullEventIndividualSimpleAttendeeListRequest = RustPB.Calendar_V1_PullEventIndividualSimpleAttendeeListRequest
public typealias PullEventIndividualSimpleAttendeeListResponse = RustPB.Calendar_V1_PullEventIndividualSimpleAttendeeListResponse
public typealias PullEventGroupsSimpleAttendeeListRequest = RustPB.Calendar_V1_PullEventGroupsSimpleAttendeeListRequest
public typealias PullEventGroupsSimpleAttendeeListResponse = RustPB.Calendar_V1_PullEventGroupsSimpleAttendeeListResponse
public typealias GetAttendeesByChatterIdsResponse = RustPB.Calendar_V1_GetAttendeesByChatterIdsResponse
public typealias PullGroupsAttendeesResponse = RustPB.Calendar_V1_PullGroupsAttendeesResponse
public typealias SearchMeetingRoomsResponse = RustPB.Calendar_V1_SearchMeetingRoomsResponse
public typealias GetMeetingRoomsInBuildingResponse = RustPB.Calendar_V1_GetMeetingRoomsInBuildingResponse
public typealias MGetChattersResponse = RustPB.Contact_V1_MGetChattersResponse
public typealias GetChattersByCalendarIdsResponse = RustPB.Calendar_V1_GetChattersByCalendarIdsResponse
public typealias GetCalendarSettingsResponse = RustPB.Calendar_V1_GetCalendarSettingsResponse
public typealias GetCalendarTenantSettingsResponse = RustPB.Calendar_V1_GetCalendarTenantSettingsResponse
public typealias SetCalendarSettingsResponse = RustPB.Calendar_V1_SetCalendarSettingsResponse
public typealias QuitMeetingResponse = RustPB.Calendar_V1_QuitMeetingResponse
public typealias GetAppConfigResponse = RustPB.Basic_V1_GetAppConfigResponse
public typealias GetSettingsResponse = RustPB.Settings_V1_GetSettingsResponse
public typealias GetCalendarEventMappingColorsResponse = RustPB.Calendar_V1_GetCalendarEventMappingColorsResponse
public typealias SubscribeCalendarRequest = RustPB.Calendar_V1_SubscribeCalendarRequest
public typealias SubscribeCalendarResponse = RustPB.Calendar_V1_SubscribeCalendarResponse
public typealias UnsubscribeCalendarRequest = RustPB.Calendar_V1_UnsubscribeCalendarRequest
public typealias UnsubscribeCalendarResponse = RustPB.Calendar_V1_UnsubscribeCalendarResponse
public typealias MultiCalendarSearchRequest = RustPB.Calendar_V1_MultiCalendarSearchRequest
public typealias LanguageType = RustPB.Basic_V1_LanguageType
public typealias GetParsedRruleTextRequest = RustPB.Calendar_V1_GetParsedRruleTextRequest
public typealias GetParsedRruleTextResponse = RustPB.Calendar_V1_GetParsedRruleTextResponse
public typealias MGetServerInstancesResponse = RustPB.Calendar_V1_MGetServerInstancesResponse
public typealias GetInstancesResponse = RustPB.Calendar_V1_GetInstancesResponse
public typealias SaveEventResponse = RustPB.Calendar_V1_SaveEventResponse
public typealias GetEventResponse = RustPB.Calendar_V1_GetEventResponse
public typealias MGetServerEventsByUniqueFieldsResponse = RustPB.Calendar_V1_MGetServerEventsByUniqueFieldsResponse
public typealias MGetServerEventsResponse = RustPB.Calendar_V1_MGetServerEventsResponse
public typealias DeleteEventResponse = RustPB.Calendar_V1_DeleteEventResponse
public typealias PreloadServerEventsResponse = RustPB.Calendar_V1_PreloadServerEventsResponse
public typealias ShareCalendarEventMessageResponse = RustPB.Calendar_V1_ShareCalendarEventMessageResponse
public typealias JoinCalendarEventResponse = RustPB.Calendar_V1_JoinCalendarEventResponse
public typealias UpgradeToMeetingResponse = RustPB.Calendar_V1_UpgradeToMeetingResponse
public typealias MarkMeetingScrollClickedResponse = RustPB.Calendar_V1_MarkMeetingScrollClickedResponse
public typealias GetExceptionalEventsResponse = RustPB.Calendar_V1_GetExceptionalEventsResponse
public typealias TransferCalendarEventRequest = RustPB.Calendar_V1_TransferCalendarEventRequest
public typealias TransferCalendarEventResponse = RustPB.Calendar_V1_TransferCalendarEventResponse
public typealias GetGoogleAuthURLRequest = RustPB.Calendar_V1_GetGoogleAuthURLRequest
public typealias GetGoogleAuthURLResponse = RustPB.Calendar_V1_GetGoogleAuthURLResponse
public typealias RecallGoogleTokenRequest = RustPB.Calendar_V1_RecallGoogleTokenRequest
public typealias RevokeExchangeAccountRequest = RustPB.Calendar_V1_RevokeExchangeAccountRequest
public typealias SaveCalendarWithMembersRequest = RustPB.Calendar_V1_SaveCalendarWithMembersRequest
public typealias MGetCalendarsWithIDsRequest = RustPB.Calendar_V1_MGetCalendarsWithIDsRequest
public typealias MGetCalendarsWithIDsResponse = RustPB.Calendar_V1_MGetCalendarsWithIDsResponse
public typealias DeleteCalendarRequest = RustPB.Calendar_V1_DeleteCalendarRequest
public typealias GetCalendarMembersByIdsRequest = RustPB.Calendar_V1_GetCalendarMembersByIdsRequest
public typealias GetCalendarMembersByIdsResponse = RustPB.Calendar_V1_GetCalendarMembersByIdsResponse
public typealias JudgeEventAttendeesChangeAffectRequest = RustPB.Calendar_V1_JudgeEventAttendeesChangeAffectRequest
public typealias JudgeEventAttendeesChangeAffectResponse = RustPB.Calendar_V1_JudgeEventAttendeesChangeAffectResponse
public typealias GetResourceWithTokenRequest = RustPB.Calendar_V1_GetResourceWithTokenRequest
public typealias GetResourceWithTokenResponse = RustPB.Calendar_V1_GetResourceWithTokenResponse
public typealias SeizeResourceRequest = RustPB.Calendar_V1_SeizeResourceRequest
public typealias SeizeResourceResponse = RustPB.Calendar_V1_SeizeResourceResponse
public typealias SetSeizeResourceWhetherNeedPopUpRequest = RustPB.Calendar_V1_SetSeizeResourceWhetherNeedPopUpRequest
public typealias GetVideoMeetingByEventRequest = RustPB.Calendar_V1_GetVideoMeetingByEventRequest
public typealias GetVideoMeetingByEventResponse = RustPB.Calendar_V1_GetVideoMeetingByEventResponse
public typealias GetVideoMeetingsStatusRequest = RustPB.Calendar_V1_GetVideoMeetingsStatusRequest
public typealias GetVideoMeetingsStatusResponse = RustPB.Calendar_V1_GetVideoMeetingsStatusResponse
public typealias GetAssociatedLiveStatusWithEventIDRequest = RustPB.Videoconference_V1_GetAssociatedLiveStatusWithEventIDRequest
public typealias GetAssociatedLiveStatusWithEventIDResponse = RustPB.Videoconference_V1_GetAssociatedLiveStatusWithEventIDResponse
public typealias GetEventInfoByVideoMeetingIdRequest = RustPB.Calendar_V1_GetEventInfoByVideoMeetingIdRequest
public typealias GetEventInfoByVideoMeetingIdResponse = RustPB.Calendar_V1_GetEventInfoByVideoMeetingIdResponse
public typealias GetCanRenewExpiredVideoMeetingNumberRequest = RustPB.Calendar_V1_GetCanRenewExpiredVideoMeetingNumberRequest
public typealias GetCanRenewExpiredVideoMeetingNumberResponse = RustPB.Calendar_V1_GetCanRenewExpiredVideoMeetingNumberResponse
public typealias CreateMeetingMinuteByChatIdRequest = RustPB.Calendar_V1_CreateMeetingMinuteByChatIdRequest
public typealias CreateMeetingMinuteByChatIdResponse = RustPB.Calendar_V1_CreateMeetingMinuteByChatIdResponse
public typealias CreateMeetingMinuteByEventRequest = RustPB.Calendar_V1_CreateMeetingMinuteByEventRequest
public typealias CreateMeetingMinuteByEventResponse = RustPB.Calendar_V1_CreateMeetingMinuteByEventResponse
public typealias GetMeetingMinuteHasUpdateByChatIdRequest = RustPB.Calendar_V1_GetMeetingMinuteHasUpdateByChatIdRequest
public typealias GetMeetingMinuteHasUpdateByChatIdResponse = RustPB.Calendar_V1_GetMeetingMinuteHasUpdateByChatIdResponse
public typealias SetEventInstanceImportanceScoreFeedbackRequest = RustPB.Calendar_V1_SetEventInstanceImportanceScoreFeedbackRequest
public typealias UpgradeToChatRequest = RustPB.Calendar_V1_UpgradeToChatRequest
public typealias DisplayTransferChatScrollCheckRequest = RustPB.Calendar_V1_DisplayTransferChatScrollCheckRequest
public typealias DisplayTransferChatScrollCheckResponse = RustPB.Calendar_V1_DisplayTransferChatScrollCheckResponse
public typealias AdvanceSearchCalendarEventResponse = RustPB.Calendar_V1_AdvanceSearchCalendarEventResponse
public typealias QuickSearchCalendarEventRequest = RustPB.Calendar_V1_QuickSearchCalendarEventRequest
public typealias QuickSearchCalendarEventResponse = RustPB.Calendar_V1_QuickSearchCalendarEventResponse
public typealias GetChatFreeBusyFavorRequest = RustPB.Calendar_V1_GetChatFreeBusyFavorRequest
public typealias GetChatFreeBusyFavorResponse = RustPB.Calendar_V1_GetChatFreeBusyFavorResponse
public typealias SetChatFreeBusyFavorRequest = RustPB.Calendar_V1_SetChatFreeBusyFavorRequest
public typealias SortChattersInChatRequest = RustPB.Calendar_V1_SortChattersInChatRequest
public typealias SortChattersInChatResponse = RustPB.Calendar_V1_SortChattersInChatResponse
public typealias OptimisticReplyCalendarEventInvitationResponse = RustPB.Calendar_V1_OptimisticReplyCalendarEventInvitationResponse
public typealias OptimisticReplyCalendarEventInvitationWithSpanResponse = RustPB.Calendar_V1_OptimisticReplyCalendarEventInvitationWithSpanResponse
public typealias CalendarEventReminder = RustPB.Calendar_V1_CalendarEventReminder
public typealias UpdateCalendarVisibilityRequest = RustPB.Calendar_V1_UpdateCalendarVisibilityRequest
public typealias SyncCalendarsAndEventsRequest = RustPB.Calendar_V1_SyncCalendarsAndEventsRequest
public typealias GetAllCalendarsRequest = RustPB.Calendar_V1_GetAllCalendarsRequest
public typealias GetRemoteUserPrimaryCalendarRequest = Calendar_V1_GetRemoteUserPrimaryCalendarRequest
public typealias GetRemoteUserPrimaryCalendarResponse = Calendar_V1_GetRemoteUserPrimaryCalendarResponse
public typealias GetBuildingsRequest = RustPB.Calendar_V1_GetBuildingsRequest
public typealias GetAttendeesByChatterIdsRequest = RustPB.Calendar_V1_GetAttendeesByChatterIdsRequest
public typealias PullGroupsAttendeesRequest = RustPB.Calendar_V1_PullGroupsAttendeesRequest
public typealias SearchMeetingRoomsRequest = RustPB.Calendar_V1_SearchMeetingRoomsRequest
public typealias GetChatterProfileRequest = RustPB.Contact_V1_GetChatterProfileRequest
public typealias GetMeetingRoomsInBuildingRequest = RustPB.Calendar_V1_GetMeetingRoomsInBuildingRequest
public typealias MGetChattersRequest = RustPB.Contact_V1_MGetChattersRequest
public typealias GetChattersByCalendarIdsRequest = RustPB.Calendar_V1_GetChattersByCalendarIdsRequest
public typealias GetCalendarSettingsRequest = RustPB.Calendar_V1_GetCalendarSettingsRequest
public typealias GetCalendarTenantSettingsRequest = RustPB.Calendar_V1_GetCalendarTenantSettingsRequest
public typealias SetCalendarSettingsRequest = RustPB.Calendar_V1_SetCalendarSettingsRequest
public typealias QuitMeetingRequest = RustPB.Calendar_V1_QuitMeetingRequest
public typealias GetAppConfigRequest = RustPB.Basic_V1_GetAppConfigRequest
public typealias GetConfigSettingsRequest = RustPB.Calendar_V1_GetConfigSettingsRequest
public typealias GetSettingsRequest = RustPB.Settings_V1_GetSettingsRequest
public typealias MarkRedDotsDisappearRequest = RustPB.Calendar_V1_MarkRedDotsDisappearRequest
public typealias MGetServerInstancesRequest = RustPB.Calendar_V1_MGetServerInstancesRequest
public typealias GetInstancesRequest = RustPB.Calendar_V1_GetInstancesRequest
public typealias SaveEventRequest = RustPB.Calendar_V1_SaveEventRequest
public typealias JudgeNotificationBoxTypeRequest = RustPB.Calendar_V1_JudgeNotificationBoxTypeRequest
public typealias GetEventRequest = RustPB.Calendar_V1_GetEventRequest
public typealias MGetServerEventsByUniqueFieldsRequest = RustPB.Calendar_V1_MGetServerEventsByUniqueFieldsRequest
public typealias GetCalendarEventInfoRequest = RustPB.Calendar_V1_GetCalendarEventInfoRequest
public typealias MGetServerEventsRequest = RustPB.Calendar_V1_MGetServerEventsRequest
public typealias DeleteEventRequest = RustPB.Calendar_V1_DeleteEventRequest
public typealias PreloadServerEventsRequest = RustPB.Calendar_V1_PreloadServerEventsRequest
public typealias GetInstancesLayoutRequest = RustPB.Calendar_V1_GetInstancesLayoutRequest
public typealias GetMeetingsByChatIdsRequest = RustPB.Calendar_V1_GetMeetingsByChatIdsRequest
public typealias GetMeetingEventRequest = RustPB.Calendar_V1_GetMeetingEventRequest
public typealias MarkMeetingEnteredRequest = RustPB.Calendar_V1_MarkMeetingEnteredRequest
public typealias ShareCalendarEventMessageRequest = RustPB.Calendar_V1_ShareCalendarEventMessageRequest
public typealias JoinCalendarEventRequest = RustPB.Calendar_V1_JoinCalendarEventRequest
public typealias UpgradeToMeetingRequest = RustPB.Calendar_V1_UpgradeToMeetingRequest
public typealias MarkMeetingScrollClickedRequest = RustPB.Calendar_V1_MarkMeetingScrollClickedRequest
public typealias GetExceptionalEventsRequest = RustPB.Calendar_V1_GetExceptionalEventsRequest
public typealias AdvanceSearchCalendarEventRequest = RustPB.Calendar_V1_AdvanceSearchCalendarEventRequest
public typealias EventFilter = RustPB.Calendar_V1_EventFilter
public typealias OptimisticReplyCalendarEventInvitationRequest = RustPB.Calendar_V1_OptimisticReplyCalendarEventInvitationRequest
public typealias OptimisticReplyCalendarEventInvitationWithSpanRequest = RustPB.Calendar_V1_OptimisticReplyCalendarEventInvitationWithSpanRequest
public typealias EventCreator = RustPB.Calendar_V1_EventCreator
public typealias TodayFeedViewEvent = RustPB.Calendar_V1_TodayFeedViewEvent

public typealias PushCalendarEventRefreshNotification = RustPB.Calendar_V1_PushCalendarEventRefreshNotification
public typealias PushCalendarEventSyncNotification = RustPB.Calendar_V1_PushCalendarEventSyncNotification
public typealias PushScrollClosedNotification = RustPB.Calendar_V1_PushScrollClosedNotification
public typealias PushReminderClosedNotification = RustPB.Calendar_V1_PushReminderClosedNotification
public typealias PushCalendarBindGoogleNotification = RustPB.Calendar_V1_PushCalendarBindGoogleNotification
public typealias PushEventShareToChatNotification = RustPB.Calendar_V1_PushEventShareToChatNotification
public typealias DayOfWeek = RustPB.Calendar_V1_DayOfWeek
public typealias InstanceLayout = RustPB.Calendar_V1_InstanceLayout
public typealias InstanceSlotMetric = RustPB.Calendar_V1_InstanceSlotMetric
public typealias CalendarConfigs = RustPB.Basic_V1_CalendarConfigs
public typealias SearchCalendarEventContent = RustPB.Calendar_V1_SearchCalendarEventContent
public typealias WorkHourSpan = RustPB.Calendar_V1_WorkHourSpan
public typealias WorkHourItem = RustPB.Calendar_V1_WorkHourItem
public typealias AttachmentType = CalendarEventAttachment.TypeEnum
public typealias CalendarEventAttachment = RustPB.Calendar_V1_CalendarEventAttachment
public typealias GetSharedCalendarEventRequest = RustPB.Calendar_V1_GetSharedCalendarEventRequest
public typealias GetSharedCalendarEventResponse = RustPB.Calendar_V1_GetSharedCalendarEventResponse
public typealias GetPrimaryCalendarLoadingStatusRequest = RustPB.Calendar_V1_GetPrimaryCalendarLoadingStatusRequest
public typealias GetPrimaryCalendarLoadingStatusResponse = RustPB.Calendar_V1_GetPrimaryCalendarLoadingStatusResponse
public typealias GetHasMeetingEventRequest = RustPB.Calendar_V1_GetHasMeetingEventRequest
public typealias GetHasMeetingEventResponse = RustPB.Calendar_V1_GetHasMeetingEventResponse
public typealias CloseEventReminderCardRequest = RustPB.Calendar_V1_CloseEventReminderCardRequest
public typealias CloseEventReminderCardResponse = RustPB.Calendar_V1_CloseEventReminderCardResponse
public typealias GetInstancesByEventUniqueFieldsRequest = RustPB.Calendar_V1_GetInstancesByEventUniqueFieldsRequest
public typealias GetInstancesByEventUniqueFieldsResponse = RustPB.Calendar_V1_GetInstancesByEventUniqueFieldsResponse
public typealias GetEventShareLinkRequest = RustPB.Calendar_V1_GetCalendarEventShareLinkRequest
public typealias GetEventShareLinkResponse = RustPB.Calendar_V1_GetCalendarEventShareLinkResponse
public typealias AlternateCalendarEnum = RustPB.Calendar_V1_AlternateCalendar
public typealias AlternateCalendarDefaultMap = RustPB.Calendar_V1_CalendarSettingConfig
public typealias PullEventGroupsSimpleMembersRequest = RustPB.Calendar_V1_PullEventGroupsSimpleMembersRequest
public typealias PullEventGroupsSimpleMembersResponse = RustPB.Calendar_V1_PullEventGroupsSimpleMembersResponse
public typealias MeetingRoomGetResourceCheckInInfoRequest = RustPB.Calendar_V1_GetResourceCheckInInfoRequest
public typealias MeetingRoomGetResourceCheckInInfoResponse = RustPB.Calendar_V1_GetResourceCheckInInfoResponse
public typealias PullEventIndividualAttendeesRequest = RustPB.Calendar_V1_PullEventIndividualAttendeesRequest
public typealias PullEventIndividualAttendeesResponse = RustPB.Calendar_V1_PullEventIndividualAttendeesResponse
public typealias GetWebinarIndividualAttendeesByPageRequest = RustPB.Calendar_V1_GetWebinarIndividualAttendeesByPageRequest
public typealias GetWebinarIndividualAttendeesByPageResponse = RustPB.Calendar_V1_GetWebinarIndividualAttendeesByPageResponse
public typealias WebinarAttendeeType = RustPB.Calendar_V1_WebinarAttendeeType
public typealias WebinarEventAttendeeInfo = RustPB.Calendar_V1_WebinarEventAttendeeInfo
public typealias CreateCalendarRequest = RustPB.Calendar_V1_CreateCalendarRequest
public typealias CreateCalendarResponse = RustPB.Calendar_V1_CreateCalendarResponse
public typealias PatchCalendarRequest = RustPB.Calendar_V1_PatchCalendarRequest
public typealias PatchCalendarResponse = RustPB.Calendar_V1_PatchCalendarResponse
public typealias EventMeetingChatExtra = RustPB.Calendar_V1_EventMeetingChatExtra
public typealias EventWebinarInfo = RustPB.Calendar_V1_CalendarEventWebinarInfo
public typealias DeleteWebinarEventRequest = RustPB.Calendar_V1_DeleteWebinarEventRequest

public typealias AppointmentMessageNotify = RustPB.Calendar_V1_AppointmentMessageNotify
public typealias AppointmentMessageRoundRobin = RustPB.Calendar_V1_AppointmentMessageRoundRobin
public typealias AppointmentAction = RustPB.Calendar_V1_AppointmentAction
public typealias AppointmentMessageStatus = RustPB.Calendar_V1_AppointmentMessageStatus
public typealias AppointmentMessageExpiredReason = RustPB.Calendar_V1_AppointmentMessageExpiredReason
public typealias Scheduler = RustPB.Calendar_V1_Scheduler

// Scheduler RoundRobin 操作
extension Server {
    public typealias GetSchedulerAvailableTimeRequest = ServerPB_Calendar_scheduler_GetSchedulerAvailableTimeRequest
    public typealias GetSchedulerAvailableTimeResponse = ServerPB_Calendar_scheduler_GetSchedulerAvailableTimeResponse
    public typealias RescheduleAppointmentRequest = ServerPB_Calendar_scheduler_RescheduleAppointmentRequest
    public typealias RescheduleAppointmentResponse = ServerPB_Calendar_scheduler_RescheduleAppointmentResponse
    public typealias GetAppointmentTokenRequest = ServerPB_Calendar_scheduler_GetAppointmentTokenRequest
    public typealias GetAppointmentTokenResponse = ServerPB_Calendar_scheduler_GetAppointmentTokenResponse
    public typealias SchedulerAvailableTimes = ServerPB_Calendar_entities_SchedulerAvailableTimes
    public typealias SchedulerAvailableTime = ServerPB_Calendar_entities_SchedulerAvailableTime
}

// myai
extension Server {
    public typealias LoadEventInfoByKeyForMyAIRequest = ServerPB_Calendarevents_LoadEventInfoByKeyForMyAIRequest
    public typealias LoadEventInfoByKeyForMyAIResponse = ServerPB_Calendarevents_LoadEventInfoByKeyForMyAIResponse
}

extension Rust {
    public typealias LoadResourcesByCalendarIdsRequest = Calendar_V1_GetResourcesByCalendarIdsRequest
    public typealias LoadResourcesByCalendarIdsResponse = Calendar_V1_GetResourcesByCalendarIdsResponse
}

// MARK: 日历
extension Rust {
    public typealias Calendar = RustPB.Calendar_V1_Calendar
}

// MARK: 日程

extension Rust {
    public typealias Event = RustPB.Calendar_V1_CalendarEvent
    public typealias Instance = RustPB.Calendar_V1_CalendarEventInstance
    public typealias Span = RustPB.Calendar_V1_CalendarEvent.Span
    public typealias UniqueField = RustPB.Calendar_V1_CalendarEventUniqueField
    typealias EventButtonDisplayType = RustPB.Calendar_V1_CalendarEventDisplayInfo.ButtonDisplayType
    public typealias CalendarEventSource = RustPB.Calendar_V1_CalendarEvent.Source
}

// MARK: 日程块（非全天）布局
extension Rust {
    public typealias InstanceLayoutSlotMetric = RustPB.Calendar_V1_DayInstancesSlotMetric
    public typealias InstanceLayoutSeed = RustPB.Calendar_V1_InstanceSlotMetric
    public typealias InstanceLayout = RustPB.Calendar_V1_InstanceLayout
}

// MARK: 参与人

extension Rust {
    public typealias Attendee = RustPB.Calendar_V1_CalendarEventAttendee
    public typealias SimpleMembers = RustPB.Calendar_V1_SimpleMembers
    public typealias SimpleMember = RustPB.Calendar_V1_SimpleMember
    public typealias UserAttendeeBaseInfo = RustPB.Calendar_V1_UserAttendeeBaseInfo

    public typealias AttendeeDisplayInfo = RustPB.Calendar_V1_AttendeeDisplayInfo
    public typealias IndividualSimpleAttendee = RustPB.Calendar_V1_IndividualSimpleAttendee
    public typealias EncryptedSimpleAttendee = RustPB.Calendar_V1_EncryptedSimpleAttendee
    public typealias IndividualSimpleLarkAttendee = RustPB.Calendar_V1_IndividualSimpleAttendee.IndividualSimpleLarkAttendee
    public typealias IndividualSimpleEmailAttendee = RustPB.Calendar_V1_IndividualSimpleAttendee.IndividualSimpleEmailAttendee
    public typealias SimpleAttendees = RustPB.Calendar_V1_SimpleAttendees
    public typealias ChatChatterIds = RustPB.Calendar_V1_ChatChatterIds
    public typealias EventSimpleAttendee = RustPB.Calendar_V1_EventSimpleAttendee
    public typealias ResourceSimpleAttendee = RustPB.Calendar_V1_ResourceSimpleAttendee
    public typealias GroupSimpleAttendee = RustPB.Calendar_V1_GroupSimpleAttendee

    public typealias GetEventAttendeesForCopyV2Request = RustPB.Calendar_V1_GetEventAttendeesForCopyV2Request
    public typealias GetEventAttendeesForCopyV2Response = RustPB.Calendar_V1_GetEventAttendeesForCopyV2Response

    public typealias PullDepartmentChatterIDsRequest = RustPB.Calendar_V1_PullDepartmentChatterIDsRequest
    public typealias PullDepartmentChatterIDsResponse = RustPB.Calendar_V1_PullDepartmentChatterIDsResponse

    public typealias GetChatLimitInfoRequest = RustPB.Im_V1_GetChatLimitInfoRequest
    public typealias GetChatLimitInfoResponse = RustPB.Im_V1_GetChatLimitInfoResponse

}

// MARK: VideoMeeting

extension Rust {
    // 日程关联的视频会议
    public typealias VideoMeeting = RustPB.Calendar_V1_VideoMeeting
    public typealias VideoMeetingStatus = RustPB.Calendar_V1_VideoMeeting.Status
    public typealias VideoMeetingIconType = RustPB.Calendar_V1_EventVideoMeetingConfig.OtherVideoMeetingConfigs.IconType
    // 视频会议信息 change 的通知
    public typealias VideoMeetingChangeNotiPayload = RustPB.Calendar_V1_PushCalendarEventVideoMeetingChange
    public typealias VideoMeetingNotiInfo = VideoMeetingChangeNotiPayload.EventVideoMeetingInfo

    public typealias VideoChatStatusNotiPayload = RustPB.Videoconference_V1_GetAssociatedVideoChatStatusResponse
    public typealias AssociatedLiveStatus = RustPB.Videoconference_V1_AssociatedLiveStatus
    public typealias ZoomVideoMeetingConfigs = RustPB.Calendar_V1_EventVideoMeetingConfig.ZoomVideoMeetingConfigs
}

extension Server {
    public typealias CalendarVideoChatStatus = ServerPB.ServerPB_Videochat_CalendarVideoChatStatus
    public typealias PullGroupChatterCalendarIDsRequest = ServerPB.ServerPB_Calendars_PullGroupChatterCalendarIDsRequest
    public typealias PullGroupChatterCalendarIDsResponse = ServerPB.ServerPB_Calendars_PullGroupChatterCalendarIDsResponse
    public typealias ChatChatterIds = ServerPB.ServerPB_Calendars_ChatChatterIds
}

// MARK: Zoom 会议
extension Server {
    public typealias ZoomAccountResponse = ServerPB.ServerPB_Calendar_external_GetZoomAccountResponse
    public typealias RevokeZoomAccountResponse = ServerPB.ServerPB_Calendar_external_RevokeZoomAccountResponse
    public typealias ZoomSetting = ServerPB_Calendar_external_ZoomMeetingSettings
    public typealias UpdateZoomSettingsResponse = ServerPB_Calendar_external_UpdateZoomMeetingSettingsResponse
    public typealias ZoomVideoMeetingConfigs = ServerPB.ServerPB_Entities_EventVChatConfig.ZoomVideoMeetingConfigs
    public typealias ZoomPhoneNums = ServerPB_Calendar_external_ZoomPhoneNums
    public typealias ZoomMeetingSettings = ServerPB_Calendar_external_ZoomMeetingSettings
}

// MARK: 日历自定义

extension Rust {
    public typealias SchemaExtraData = RustPB.Calendar_V1_SchemaExtraData
    public typealias SchemaEntity = Calendar_V1_EntitySchema
    public typealias SchemaCollection = RustPB.Calendar_V1_CalendarSchemaCollection
    public typealias IncompatibleLevel = Calendar_V1_IncompatibleLevel
}

// MARK: MeetingRoom

extension Rust {
    public typealias Building = RustPB.Calendar_V1_CalendarBuilding
    public typealias MeetingRoom = RustPB.Calendar_V1_CalendarResource
    public typealias Equipment = RustPB.Calendar_V1_MeetingRoomEquipment
    public typealias MeetingRoomFilter = RustPB.Calendar_V1_MeetingRoomFilter

    public typealias GetBuildingsRequest = RustPB.Calendar_V1_GetBuildingsRequest
    public typealias GetBuildingsResponse = RustPB.Calendar_V1_GetBuildingsResponse

    public typealias GetResourceEquipmentsRequest = RustPB.Calendar_V1_GetResourceEquipmentsRequest
    public typealias GetResourceEquipmentsResponse = RustPB.Calendar_V1_GetResourceEquipmentsResponse

    public typealias GetMeetingRoomsInBuildingRequest = RustPB.Calendar_V1_GetMeetingRoomsInBuildingRequest
    public typealias GetMeetingRoomsInBuildingResponse = RustPB.Calendar_V1_GetMeetingRoomsInBuildingResponse

    public typealias SearchMeetingRoomsRequest = RustPB.Calendar_V1_SearchMeetingRoomsRequest
    public typealias SearchMeetingRoomsResponse = RustPB.Calendar_V1_SearchMeetingRoomsResponse

    // 获取全部会议室
    public typealias GetAllMeetingRoomRequest = RustPB.Calendar_V1_PullAllMeetingRoomsInTenantRequest
    public typealias GetAllMeetingRoomResponse = RustPB.Calendar_V1_PullAllMeetingRoomsInTenantResponse

    // 会议室审批
    public typealias ApprovalRequest = RustPB.Calendar_V1_SchemaExtraData.ApprovalRequest
    public typealias ApprovalInfo = RustPB.Calendar_V1_SchemaExtraData.ResourceApprovalInfo

    // 会议室限时预定
    public typealias ResourceStrategy = RustPB.Calendar_V1_SchemaExtraData.ResourceStrategy
    public typealias UnusableReasons = RustPB.Calendar_V1_GetUnusableMeetingRoomsResponse.UnusableReasons
    public typealias ResourceStatusInfo = RustPB.Calendar_V1_GetUnusableMeetingRoomsRequest.ResourceInfo
    public typealias ResourceStrategyMap = [String: ResourceStrategy]
    public typealias UnusableReasonMap = [String: Rust.UnusableReasons]
    public typealias GetUnusableMeetingRoomsRequest = RustPB.Calendar_V1_GetUnusableMeetingRoomsRequest
    public typealias GetUnusableMeetingRoomsResponse = RustPB.Calendar_V1_GetUnusableMeetingRoomsResponse
    // 会议室限时禁用
    public typealias ResourceRequisition = Calendar_V1_SchemaExtraData.ResourceRequisition
    public typealias ResourceRequisitionsMap = [String: ResourceRequisition]

    // 会议室自定义信息 包含表单和联系人
    public typealias ResourceCustomization = Calendar_V1_SchemaExtraData.ResourceCustomization
    // 表单中的问题
    public typealias CustomizationQuestion = Calendar_V1_SchemaExtraData.CustomizationData
    // 表单本质就是问题的数组
    public typealias CustomizationForm = [CustomizationQuestion]
    // 表单中问题的选项
    public typealias CustomizationOption = Calendar_V1_SchemaExtraData.CustomizationOption
    // 用户已选择的选项 是key为问题id value为选项id数组的 dict
    public typealias CustomizationFormSelections = [String: Calendar_V1_ParseCustomizedConfigurationRequest.SelectedKeys]
    // 用户的输入 是key为问题id value为输入内容的 dict
    public typealias CustomizationFormUserInputs = [String: String]

    public typealias RoomViewFilterConfig = Calendar_V1_RoomViewFilterConfigs

    public typealias HierarchicalRoomViewFilterConfigs = Calendar_V1_HierarchicalRoomViewFilterConfigs

    /// 会议室筛选结果
    struct MeetingRoomViewFilterResult {
        /// 筛选设置
        var filterConfig: Rust.RoomViewFilterConfig

        /// 选择的层级ID:
        var selectedLevelIds: [String] = []

        /// 筛选后得到的会议室
        var meetingRooms: [String: Rust.MeetingRoom]

        /// 筛选后得到的建筑
        var buildings: [String: Rust.Building]

        func transformToHierarchicalRoomViewFilterConfig() -> Rust.HierarchicalRoomViewFilterConfigs {
            var config = HierarchicalRoomViewFilterConfigs()
            config.selectedLevelIds = self.selectedLevelIds
            config.meetingRoomFilter = filterConfig.meetingRoomFilter
            return config
        }
    }

    struct PinLevelRelatedInfo {
        /// 自动展开路径
        let autoDisplayPathMap: [String: Calendar_V1_AutoDisplayPath]
        /// 需要打标签的 levelID
        let recentlyUsedNodeList: [String]
    }

    // applink
    public typealias EventByUniqueField = Calendar_V1_GetAuthorizedEventByUniqueFieldResponse
}

extension Server {
    public typealias UnusableReasons = [ServerPB_Entities_MeetingRoomUnusableReasonType]
    public typealias UnusableReasonMap = [String: [ServerPB_Entities_MeetingRoomUnusableReasonType]]
    public typealias CalendarEventUniqueField = ServerPB_Entities_CalendarEventUniqueField
    public typealias MeetingRoomUnusableReasonType = ServerPB_Entities_MeetingRoomUnusableReasonType
    public typealias FileRiskTag = ServerPB_Compliance_MGetRiskTagByTokenResponse.FileRiskTag
}

extension Server {
    public typealias CalendarShareInfo = ServerPB_Calendars_GetCalendarShareInfoResponse
    public typealias CalendarMemberCommit = ServerPB_Entities_CalendarMemberCommit
}

extension Rust {
    typealias PatchCalendarsRequest = Calendar_V1_PatchCalendarRequest
    typealias PatchCalendarsResponse = Calendar_V1_PatchCalendarResponse
    typealias CalendarMemberCommits = Calendar_V1_CalendarMemberCommits
    typealias CalendarMemberCommit = Calendar_V1_CalendarMemberCommit
    typealias FetchCalendarsRequest = Calendar_V1_FetchCalendarsRequest
    typealias FetchCalendarsResponse = Calendar_V1_FetchCalendarsResponse
    typealias CalendarWithMembers = Calendar_V1_CalendarWithMembers
    typealias CalendarShareInfo = Calendar_V1_Calendar.CalendarShareInfo
    typealias CalendarShareOptions = Calendar_V1_Calendar.CalendarShareOptions
    typealias CalendarSaveInfo = Calendar_V1_CalendarSaveInfo
    typealias ShareOption = Calendar_V1_Calendar.ShareOption
    typealias CalendarAccessRole = RustPB.Calendar_V1_Calendar.AccessRole
    typealias CalendarTenantInfo = RustPB.Calendar_V1_CalendarTenantInfo
    public typealias CalendarMember = Calendar_V1_CalendarMember
    typealias LevelAdjustTimeInfo = RustPB.Calendar_V1_LevelAdjustTimeInfo
}

struct RoomViewInstance: CalendarEventInstanceEntity {
    var pb: Calendar_V1_RoomViewInstance
    let buildingName: String
    init(pb: Calendar_V1_RoomViewInstance) {
        self.init(pb: pb, buildingName: "")
    }

    init(pb: Calendar_V1_RoomViewInstance,
         buildingName: String) {
        self.pb = pb
        self.buildingName = buildingName
    }

    var id: String { UUID().uuidString }
    var eventId: String {
        return ""
    }
    var calendarId: String { pb.resourceCalendarID }
    var key: String { pb.eventKey }
    var organizerId: String {
        return ""
    }
    var selfAttendeeStatus: CalendarEventAttendee.Status {
        return pb.reservationStatus
    }

    var isFree: Bool {
        return false
    }

    var isCreatedByMeetingRoom: (strategy: Bool, requisition: Bool) {
        return (false, false)
    }
    var calAccessRole: AccessRole {
        return .unknownAccessRole
    }
    var eventServerId: String {
        return ""
    }
    var isEditable: Bool {
        if pb.category == .resourceRequisition || pb.category == .resourceStrategy { return false }
        if pb.currentUserAccessibility == .eventVisibile || pb.currentUserAccessibility == .joined { return true }
        return false
    }

    var location: String {
        return ""
    }

    var address: String {
        return ""
    }

    var displayType: CalendarEvent.DisplayType {
        .limited
    }

    var meetingRomes: [String] {
        return []
    }

    var eventColor: ColorIndex {
        return .neutral
    }

    var calColor: ColorIndex {
        return .neutral
    }

    var isSyncFromLark: Bool {
        return false
    }

    var source: CalendarEvent.Source { .iosApp }

    var startDate: Date {
        Date(timeIntervalSince1970: TimeInterval(startTime))
    }

    var endDate: Date {
        Date(timeIntervalSince1970: TimeInterval(endTime))
    }

    var startTime: Int64 { pb.startTime }

    var endTime: Int64 { pb.endTime }

    var startDay: Int32 { pb.startDay }

    var endDay: Int32 { pb.endDay }

    var startMinute: Int32 { pb.startMinute }

    var endMinute: Int32 { pb.endMinute }

    var originalTime: Int64 { pb.originalTime }

    var summary: String { pb.summary }

    var isAllDay: Bool { pb.isAllDay }

    var currentUserAccessibleCalendarID: String { pb.currentUserAccessibleCalendarID }

    var startTimezone: String { pb.startTimezone }

    var isOverOneDay: Bool {
        false
    }

    var importanceScore: String {
        return ""
    }

    var uniqueId: String {
        return ""
    }

    func isDisplayFull() -> Bool {
        return false
    }

    func displaySummary() -> String {
        if isFakeInstance {
            if let meetingRoom = meetingRoom {
                let summary = "\(pb.summary.isEmpty ? BundleI18n.Calendar.Calendar_Common_NoTitle : pb.summary)"
                let needApproval = meetingRoom.needsApproval || meetingRoom.shouldTriggerApproval(duration: endTime - startTime)
                return needApproval ? "\(BundleI18n.Calendar.Calendar_Approval_InReview) \(summary)" : "\(BundleI18n.Calendar.Calendar_Detail_ReservingMobile) \(summary)"
            } else {
                assertionFailure("虚假日程必须有会议室信息")
                return "\(summary.isEmpty ? BundleI18n.Calendar.Calendar_Common_NoTitle : summary)"
            }
        }

        if pb.category == .resourceStrategy {
            return BundleI18n.Calendar.Calendar_MeetingView_MeetingRoomCantReservePeriod
        } else if pb.category == .resourceRequisition {
            return BundleI18n.Calendar.Calendar_Edit_MeetingRoomInactiveCantReserve
        }

        switch pb.currentUserAccessibility {
        case .eventVisibile, .joined, .summaryVisible:
            return "\(summary.isEmpty ? BundleI18n.Calendar.Calendar_Common_NoTitle : summary) \(pb.resourceContactPerson.contactPerson.name)"
        case .limited:
            return BundleI18n.Calendar.Calendar_Edit_ReservedByNane(name: pb.resourceContactPerson.contactPerson.name)
        @unknown default:
            return summary
        }
    }

    func canEdit() -> Bool {
        true
    }

    func getDataSource() -> DataSource {
        return .sdk
    }

    // 暂时这里仅用到 category 字段，后期需要其他字段再加
    func toPB() -> CalendarEventInstance {
        var toPb = CalendarEventInstance()
        toPb.category = pb.category
        return toPb
    }

    func originalModel() -> Any {
        self
    }

    var isMeetingRoomViewInstance: Bool { true }

    /// 是否是 SDK 的虚假占位日程
    var isFakeInstance: Bool { pb.reservationStatus == .needsAction }

    var meetingRoom: Rust.MeetingRoom?
}

extension RoomViewInstance: CustomDebugStringConvertible, CustomStringConvertible {

    var description: String {
        return "\(pb.debugDescription) + meetingRoom: \(meetingRoom?.debugDescription ?? "no meetingRoom")"
    }

    var debugDescription: String {
        return "\(pb.debugDescription) + meetingRoom: \(meetingRoom?.debugDescription ?? "no meetingRoom")"
    }
}

extension Rust {
    struct EquipmentExpand {
        let equipment: Rust.Equipment
        let id: String
    }
}

// 会议室多层级相关
extension Rust {
    // 当前层级下的字层级与子会议室信息
    public typealias MeetingRoomLevelInfo = RustPB.Calendar_V1_LevelRelatedInfo

    // 层级的 name, id 信息
    public typealias MeetingRoomLevelContent = RustPB.Calendar_V1_LevelContent
}

// MARK: TimeZone

extension Rust {

    /// 获取最近时区
    public typealias GetRecentTimeZonesRequest = RustPB.Calendar_V1_GetRecentTimezonesRequest
    public typealias GetRecentTimeZonesResponse = RustPB.Calendar_V1_GetRecentTimezonesResponse

    ///
    public typealias UpdateRecentTimeZonesRequest = RustPB.Calendar_V1_UpdateRecentTimezonesRequest
    public typealias UpdateRecentTimeZonesResponse = RustPB.Calendar_V1_UpdateRecentTimezonesResponse

    public typealias GetMobileNormalViewTimeZoneRequest = RustPB.Calendar_V1_GetMobileNormalViewTimezoneRequest
    public typealias GetMobileNormalViewTimeZoneResponse = RustPB.Calendar_V1_GetMobileNormalViewTimezoneResponse

    public typealias SetMobileNormalViewTimeZoneRequest = RustPB.Calendar_V1_SetMobileNormalViewTimezoneRequest
    public typealias SetMobileNormalViewTimeZoneResponse = RustPB.Calendar_V1_SetMobileNormalViewTimezoneResponse

    public typealias GetTimeZoneByCityRequest = RustPB.Calendar_V1_GetTimezoneByCityRequest
    public typealias GetTimeZoneByCityResponse = RustPB.Calendar_V1_GetTimezoneByCityResponse

    public typealias TimeZone = RustPB.Calendar_V1_Timezone
    public typealias CityTimeZone = GetTimeZoneByCityResponse.CityTimezone
}

extension CalendarEventAttendee.Status {
    var rsvpSelectedToast: String {
        switch self {
        case .accept:
            return I18n.Calendar_RsvpToast_Accept
        case .decline:
            return I18n.Calendar_RsvpToast_Decline
        case .tentative:
            return I18n.Calendar_RsvpToast_OnHold
        @unknown default:
            return I18n.Calendar_Detail_ResponseSuccessed
        }
    }
}

// MARK: 日程签到
extension Rust {
    public typealias CheckInConfig = RustPB.Calendar_V1_EventCheckInConfig
}

extension Rust.CheckInConfig {
    static var initialValue: Self {
        var config = Self()
        config.checkInStartTime.duration = 15
        config.checkInStartTime.type = .beforeEventStart
        config.checkInEndTime.duration = 0
        config.checkInEndTime.type = .afterEventEnd
        return config
    }
}

// MARK: 会议链接优化
extension Rust {
    public typealias ParseEventMeetingLinksRequest = RustPB.Calendar_V1_ParseEventMeetingLinksRequest
    public typealias ParseEventMeetingLinksResponse = RustPB.Calendar_V1_ParseEventMeetingLinksResponse
    public typealias ParsedMeetingLinkVCType = ParseEventMeetingLinksResponse.VcType
    public typealias ParsedEventLocationItem = ParseEventMeetingLinksResponse.LocationItem
}

// MARK: RSVP新卡片
extension Rust {
    
    public typealias ReplyCalendarEventRsvpCardRequest = RustPB.Calendar_V1_ReplyCalendarEventRsvpCardRequest
    public typealias ReplyCalendarEventRsvpCardResponse = RustPB.Calendar_V1_ReplyCalendarEventRsvpCardResponse
    public typealias EventCreateRsvpCardInfo = RustPB.Calendar_V1_EventCreateRsvpCardInfo
}

extension Rust.AttendeeDisplayInfo {
    var relationTagStr: String {
        if self.hasRelationTag,
           !self.relationTag.tagDataItems.isEmpty,
           let tagDataItem = self.relationTag.tagDataItems.first(where: { $0.respTagType != .relationTagUnset }) {
            return tagDataItem.textVal
        }
        return ""
    }
}

extension Rust.Attendee {
    var relationTagStr: String {
        if self.hasRelationTag,
           !self.relationTag.tagDataItems.isEmpty,
           let tagDataItem = self.relationTag.tagDataItems.first(where: { $0.respTagType != .relationTagUnset }) {
            return tagDataItem.textVal
        }
        return ""
    }
}

extension Rust.Event {
    var relationTagStr: String {
        if self.hasRelationTag,
           !self.relationTag.tagDataItems.isEmpty,
           let tagDataItem = self.relationTag.tagDataItems.first(where: { $0.respTagType != .relationTagUnset }) {
            return tagDataItem.textVal
        }
        return ""
    }
}

extension Rust.CalendarMember {
    var relationTagStr: String {
        if self.hasRelationTag,
           !self.relationTag.tagDataItems.isEmpty,
           let tagDataItem = self.relationTag.tagDataItems.first(where: { $0.respTagType != .relationTagUnset }) {
            return tagDataItem.textVal
        }
        return ""
    }
}

extension Basic_V1_TagData {
    var relationTagStr: String {
        if !self.tagDataItems.isEmpty,
           let tagDataItem = self.tagDataItems.first(where: { $0.respTagType != .relationTagUnset }) {
            return tagDataItem.textVal
        }
        return ""
    }
}

// MARK: 有效会议
extension Rust {
    public typealias NotesInfo = RustPB.Calendar_V1_NotesInfo
    public typealias InstanceRelatedData = RustPB.Calendar_V1_InstanceRelatedData
    public typealias NotesEventPermission = RustPB.Calendar_V1_NotesEventPermission
    public typealias MeetingNotesConfig = RustPB.Calendar_V1_MeetingNotesConfig
    public typealias CreateNotesPermission = MeetingNotesConfig.CreateNotesPermission
}

extension Rust.CreateNotesPermission {
    /// 有效会议创建权限的默认值
    static func defaultValue() -> Self {
        return .all
    }
}

extension Rust.MeetingNotesConfig {
    /// 默认所有人权限，null 视为使用默认值（版本兼容问题）
    func createNotesPermissionRealValue() -> Rust.CreateNotesPermission {
        return self.createNotesPermission == .unknown ? .defaultValue() : self.createNotesPermission
    }
}

extension Server {
    public typealias NotesTitleForm = ServerPB_Calendarevents_NotesTitleForm
    public typealias MeetingNotesUpdateInfo = ServerPB_Entities_MeetingNotesUpdateInfo
    public typealias NotesEventPermission = ServerPB_Calendar_entities_NotesEventPermission
    public typealias BatchDelNotesDocRequest = ServerPB_Calendarevents_BatchDelNotesDocRequest
    public typealias BatchDelNotesDocResponse = ServerPB_Calendarevents_BatchDelNotesDocResponse
    public typealias NotesDocInfo = ServerPB_Calendarevents_NotesDocInfo
}

// MARK: 参与者默认权限
extension CalendarSetting {
    var guestPermission: GuestPermission? {
        if !self.hasCalendarEventEditSetting {
            return nil
        }
        return self.calendarEventEditSetting.guestPermission
    }
}

extension CalendarTenantSetting {
    var guestPermission: GuestPermission? {
        if !self.hasCalendarEventEditSetting {
            return nil
        }
        return self.calendarEventEditSetting.guestPermission
    }
}

extension Calendar_V1_CalendarEventEditSetting {
    var guestPermission: GuestPermission {
        if self.guestCanModify {
            return .guestCanModify
        } else if self.guestCanInvite {
            return .guestCanInvite
        } else if self.guestCanSeeOtherGuests {
            return .guestCanSeeOtherGuests
        } else {
            return .none
        }
    }
}

// MARK: MyAI INLINE浮窗组件
extension Server {
    public typealias FetchQuickActionRequest = ServerPB_Office_ai_inline_FetchQuickActionRequest
    public typealias FetchQuickActionResponse = ServerPB_Office_ai_inline_FetchQuickActionResponse
    public typealias AIEngineDebugInfoRequest = ServerPB_Ai_engine_DebugInfoRequest
    public typealias AIEngineDebugInfoResponse = ServerPB_Ai_engine_DebugInfoResponse
    public typealias CalendarMyAIInlineStage = ServerPB_Calendar_entities_CalendarMyAIInlineStage
    public typealias CalendarMyAIInlineStageInfo = ServerPB_Calendarevents_PushCalendarMyAIInlineStage
    public typealias AIInlineQuickAction = ServerPB_Office_ai_inline_QuickAction
    public typealias MyAIUserQueryRequest = ServerPB_Calendarevents_GetCalendarMyAIUserQueryRequest
    public typealias MyAIUserQueryResponse = ServerPB_Calendarevents_GetCalendarMyAIUserQueryResponse
    public typealias MyAIInlineInputType = ServerPB_Calendar_entities_CalendarMyAIInlineInputType
    public typealias GetCalendarMyAIInlineEventRequest = ServerPB_Calendarevents_GetCalendarMyAIInlineEventRequest
    public typealias GetCalendarMyAIInlineEventResponse = ServerPB_Calendarevents_GetCalendarMyAIInlineEventResponse
    public typealias MyAICalendarEventInfo = ServerPB_Calendarevents_MyAICalendarEventInfo
}


extension Rust {
    public typealias InlineAICreateTaskRequest = Space_Doc_V1_InlineAICreateTaskRequest
    public typealias InlineAICreateTaskResponse = Space_Doc_V1_InlineAICreateTaskResponse
    public typealias InlineAICancelTaskRequest = Space_Doc_V1_InlineAICancelTaskRequest
    public typealias InlineAICancelTaskResponse = Space_Doc_V1_InlineAICancelTaskResponse
    public typealias InlineAITaskStatusPushResponse = Space_Doc_V1_InlineAITaskStatusPushResponse
}

// MARK: Zoom Push
extension Server {
    public typealias PushBindZoomSuccess = ServerPB.ServerPB_Calendar_external_PushBindZoomSuccessNotification
}


// MARK: MyAI 蓝牙会议室
extension Server {
    public typealias GetCalendarDevicePermissionBleRequest = ServerPB_Calendarevents_GetCalendarDevicePermissionBleRequest
    public typealias GetCalendarDevicePermissionBleResponse = ServerPB_Calendarevents_GetCalendarDevicePermissionBleResponse
    public typealias UploadNearbyMeetingRoomInfoRequest = ServerPB_Calendarevents_UploadNearbyMeetingRoomInfoRequest
    public typealias UploadNearbyMeetingRoomInfoResponse = ServerPB_Calendarevents_UploadNearbyMeetingRoomInfoResponse
}

extension Rust {
    public typealias TimeContainer = Calendar_V1_TimeContainer
}
