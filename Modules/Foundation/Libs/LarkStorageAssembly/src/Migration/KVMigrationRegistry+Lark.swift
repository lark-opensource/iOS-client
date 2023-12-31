//
//  KVMigrationRegistry+Lark.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation
import LarkStorage
import LarkEnv

/// KeyValue 的注册迁移
extension KVMigrationRegistry {
    @_silgen_name("Lark.LarkStorage_KeyValueMigrationRegistry.LarkStorage")
    public static func registerLarkMigration() {
        KVMigrationRegistry.logger.info("registerLarkMigration invoked")

        KVMigrationRegistry.registerFeed()
        KVMigrationRegistry.registerCalendar()
        KVMigrationRegistry.registerMail()
        KVMigrationRegistry.registerByteView()
        KVMigrationRegistry.registerCore()
        KVMigrationRegistry.registerInfra()
        KVMigrationRegistry.registerTodo()
        KVMigrationRegistry.registerMessenger()
        KVMigrationRegistry.registerMeego()
        KVMigrationRegistry.registerMinutes()
        KVMigrationRegistry.registerOpenPlatform()
    }

    private static func registerFeed() {
        registerMigration(forDomain: Domain.biz.feed, strategy: .move) { space in
            switch space {
            case .global:
                return [
                    .from(userDefaults: .standard, items: [
                        "Feed.Loadmessenger_feed_load_count" ~> "messenger_feed_load_count"
                    ])
                ]
            case .user(let userId):
                let newKeys = [
                    "feed", "feed.badge", "shortcut", "feed.showMute",
                    "feed.label.expand", "feed.filter.expand", "feed.team.expand"
                ]
                let items = newKeys.map { (newKey: String) -> KVMigrationConfig.KeyMatcher.SimpleItem in
                    let oldKey = "\(userId).larkFeed.feedKVStorage.v2.\(newKey)"
                    return oldKey ~> newKey
                }
                return [.from(userDefaults: .standard, items: items)]
            }
        }

        registerMigration(forDomain: Domain.biz.feed.child("Banner"), strategy: .move) { space in
            guard case .user(let uid) = space, let passport = Dependencies.passport else { return [] }
            guard let tenantId = passport.tenantId(forUser: uid) else {
                KVStores.assertionFailure("cannot get tenantId for with userId: \(uid)")
                return []
            }
            return [
                .from(userDefaults: .suiteName("ActivityMember"), items: [
                    "\(tenantId)_activityBannerAlreadyClosedFlagName" ~> "activityBannerAlreadyClosedFlag",
                    "\(tenantId)_upgradeTeamBannerAlreadyClosedFlagName" ~> "upgradeTeamBannerAlreadyClosedFlag"
                ]),
                .from(userDefaults: .suiteName("LarkFeed"), items: [
                    "\(tenantId)_kNotifyReminderLastCheckTime" ~> "kNotifyReminderLastCheckTime"
                ])
            ]
        }
    }

    private static func registerCalendar() {
        registerMigration(forDomain: Domain.biz.calendar, strategy: .move) { space in
            switch space {
            case .global:
                return [
                    .from(userDefaults: .standard, items: [
                        "KV.Calendar.VISIBLECALSOURCEKEY" ~> "VISIBLECALSOURCEKEY",
                        "KV.Calendar.VISIBLECALKEY" ~> "VISIBLECALKEY"
                    ])
                ]
            case .user(let userId):
                var ret = [KVMigrationConfig]()
                ret.append(.from(userDefaults: .standard, items: [
                    "KV.Calendar.calendar_last_used_entry" ~> "calendar_last_used_entry",
                    "KV.Calendar.hasCalendarCache" ~> "hasCalendarCache",
                    "calendar_has_shown_oauth_dialog"
                ]))
                guard let passport = Dependencies.passport, let tenantId = passport.tenantId(forUser: userId) else {
                    KVStores.assertionFailure("cannot match tenantId with userId: \(userId)")
                    return ret
                }
                ret.append(.from(userDefaults: .suiteName(tenantId), items: [
                    "KV.Calendar.CalendarDayViewMode" ~> "CalendarDayViewMode",
                    "KV.Calendar.ExternalCalendarVisibleKey" ~> "ExternalCalendarVisibleKey"
                ]))
                return ret
            }
        }
    }

    private static func registerMail() {
        registerMigration(forDomain: Domain.biz.mail, strategy: .sync) { space in
            switch space {
            case .global:
                let existKeys: KVMigrationConfig = .from(userDefaults: .standard, items: [
                    .key("kMailLoadLocalTemplate"),
                    .key("kMailDelayLoadTemplate"),
                    .key("kMailEditorDebug"),
                    .key("kMailEditorIP"),
                    .key("Mail_remoteConfigKeyForCarrierNetworkTimeOut"),
                    .key("Mail_remoteConfigKeyForWifiNetworkTimeOut")])
                return [existKeys]
            case .user:
                return []
            }
        }
    }

    private static func registerByteView() {
        registerMigration(forDomain: Domain.biz.byteView.child("Core"), strategy: .move) { space in
            let deviceId = Dependencies.passport?.deviceId ?? ""
            switch space {
            case .global:
                return [.from(userDefaults: .standard, items: [
                    "byteview.displayfps" ~> "displayFPS",
                    "byteview.displaycodec" ~> "displayCodec",
                    "byteview.meeting.hdvideo" ~> "meetingHDVideo",
                    "ByteView.DisableiPadMicphoneSpeaker_\(deviceId.hash)" ~> "micSpeakerDisabled",
                    "byteview_kUserKilledKey" ~> "userKilled",
                    "byteview_kAppLaunchKey" ~> "appLaunch",
                    "byteview_kAppEnterBackgroundKey" ~> "appEnterBackground",
                    "ByteView_BreakoutRoomHostControl_Tapped" ~> "tapToolbarForBreakoutRoom",
                    "ByteView_CountDownLastSetMinute" ~> "dbLastSetMinute",
                    "ByteView_CountDownEnableEndAuido" ~> "dbEndAudio",
                    "ByteView_CountDownLastRemindMinute" ~> "dbLastRemind",
                    "EnterpriseKeyPadViewModel.kLastCalledPhoneNumber" ~> "lastCalledPhoneNumber",
                    "ByteView_ignoreHowlingCount" ~> "howlingDate",
                    "vc_center_stage_used" ~> "centerStageUsed",
                    "videoconference|scene|share_content" ~> "shareScene",
                    "vc_keyboard_mute_enabled" ~> "keyboardMute",
                    "user_default_vc_lab_red_key" ~> "labRed",
                    "breakoutRoomGuideMeetingID" ~> "breakoutRoomGuide",
                    "user_default_vc_switchAudio_guide_key" ~> "switchAudioGuide",
                    "VoiceModeLastBatteryToastTime" ~> "lastBatteryToastTime",
                    "ByteView.TrackContext.Storage" ~> "storagePersist"
                ])]
            case .user(let userId):
                let identifier: String = "\(userId)_1_\(deviceId)"
                return [.from(userDefaults: .standard, items: [
                    "byteview.cellularnetworkimproveaudioquality|\(userId.hash)" ~> "improveAudioQuality",
                    "byteview.isFeedbackSettingGuideEnabled|toolbar|\(userId.hash)|\(deviceId.hash)" ~> "feedbackGuideForToolBar",
                    "byteview.isFeedbackSettingGuideEnabled|inMeetSetting|\(userId.hash)|\(deviceId.hash)" ~> "feedbackGuideForInMeet",
                    "byteview.presenterallowfreetobrowsehint\(deviceId)" ~>  "presenterAllowFree",
                    "byteview.doubletaptofreetobrowse\(deviceId)" ~> "doubleTapToFree",
                    "\(userId.hash)|rtcFeatureGating" ~> "rtcFG",
                    "\(userId.hash)|adminMediaServerSettings" ~> "adminMediaServer",
                    "ByteView|callmeAdminKey|\(identifier.hash)" ~> "callmeAdmin",
                    "ByteView|EnterprisePhoneConfig|isAuthorized|\(identifier.hash)" ~> "phoneAuthorized",
                    "ByteView|EnterprisePhoneConfig|isScopeAny|\(identifier.hash)" ~> "phoneScopeAny",
                    "ByteView|EnterprisePhoneConfig|canCallOversea|\(identifier.hash)" ~> "phoneCallOversea",
                    "ByteView|EnterprisePhoneConfig|enterpriseCallType|\(identifier.hash)" ~> "phoneCallType",
                    "byteview_kLastlyMeetingId" ~> "lastlyMeetingId",
                    "ByteView_\(userId.hash)\(deviceId.hash)" ~> "micCameraSetting",
                    "ByteView_userReadMessageKey|\(identifier.hash)" ~> "readMessage",
                    "ByteView_userLastReadMessageKey|\(identifier.hash)" ~> "scanningMessage",
                    "ByteView_sentPositionsKey|\(identifier.hash)" ~> "sentPositions",
                    "ByteView_FoldCountDownBoard|\(identifier.hash)" ~> "dbFoldBoard",
                    "byteview.autoHideToolStatusBar|\(userId.hash)" ~> "autoHideToolStatusBar",
                    "ByteView_isFlowShrunkenKey|\(identifier.hash)" ~> "isFlowShrunken",
                    "keyUltrawaveAllowed\(identifier.hash)" ~> "ultrawave"
                ])]
            }
        }

        registerMigration(forDomain: Domain.biz.byteView.child("ByteViewTab"), strategy: .move) { space in
            guard case .user(let userId) = space else { return [] }
            let deviceId = Dependencies.passport?.deviceId ?? ""
            return [.from(userDefaults: .standard, items: [
                "byteview.isFeedbackSettingGuideEnabled|tab|\(userId.hash)|\(deviceId.hash)" ~> "feedbackGuideForTab",
                "byteview.isFeedbackSettingGuideEnabled|preSetting|\(userId.hash)|\(deviceId.hash)" ~> "feedbackGuideForPre"
            ])]
        }

        registerMigration(forDomain: Domain.biz.byteView.child("ByteViewDebug"), strategy: .move) { space in
            guard case .global = space else { return [] }
            return [.from(userDefaults: .standard, items: [
                "meetingWindowEnableUserDefaultKey" ~> "meetingWindow"
            ])]
        }
    }

    private static func registerCore() {
        let core = Domain.biz.core
        registerMigration(forDomain: core.child("Version"), strategy: .move) { space in
            guard case .global = space else { return [] }
            return [
                .from(userDefaults: .standard, items: [
                    "mine_user_setting_last_update_urgent_tap_later_time" ~> "last_update_urgent_tap_later_time",
                    "mine_user_setting_last_remove_update_notice_version" ~> "last_remove_update_notice_version",
                    "mine_user_setting_last_inhouse_update_alert_time" ~> "last_inhouse_update_alert_time"
                ])
            ]
        }

        registerMigration(forDomain: core.child("UserGrowth"), strategy: .move) { space in
            guard case .global = space else { return [] }
            return [
                .from(userDefaults: .suiteName("LarkUserGrowth"), items: [
                    "ug_ad_install_source" ~> "ad_install_source",
                    "ug_ad_user_source" ~> "ad_user_source",
                    "ug_ad_install_source_config" ~> "ad_install_source_config"
                ])
            ]
        }

        registerMigration(forDomain: core.child("Splash"), strategy: .move) { space in
            guard case .global = space else { return [] }
            return [
                .from(userDefaults: .standard, items: [
                    "LarkSplash.hasSplashData" ~> "hasSplashData",
                    "LarkSplash.lastSplashDataTime" ~> "lastSplashDataTime",
                    "LarkSplash.lastSplashAdID" ~> "lastSplashAdID"
                ])
            ]
        }

        registerMigration(forDomain: core.child("OCR"), strategy: .move) { space in
            guard case .global = space else { return [] }
            return [
                .from(userDefaults: .standard, items: [
                    "KV.OCR.showTapGuideKey" ~> "showTapGuideKey",
                    "KV.OCR.showScrollGuide" ~> "showScrollGuide"
                ])
            ]
        }

        registerMigration(forDomain: core.child("WaterMark"), strategy: .move) { space in
            guard case .user(let userId) = space, !userId.isEmpty else { return [] }
            return [
                .from(userDefaults: .suiteName(userId), items: [
                    // origin
                    "KV.waterMark.contactKey" ~> "origin.contactKey",
                    "KV.waterMark.userNameKey" ~> "origin.userNameKey",
                    "KV.waterMark.needShowWaterKey" ~> "origin.needShowWaterKey",
                    // new
                    "KV.newWaterMark.contentKey" ~> "contentKey",
                    "KV.newWaterMark.contentURLKey" ~> "contentURLKey",
                    "KV.newWaterMark.needShowWaterKey" ~> "needShowWaterKey",
                    "KV.newWaterMark.needShowImageWaterKey" ~> "needShowImageWaterKey",
                    "KV.newWaterMark.customPattern" ~> "customPattern"
                ])
            ]
        }

        registerMigration(forDomain: core.child("Suspendable"), strategy: .move) { space in
            switch space {
            case .global:
                return [
                    .from(userDefaults: .standard, items: [
                        "KV.LarkSuspendable.bubble_rect_for_client_default2" ~> "bubble_rect",
                        "KV.LarkSuspendable.suspend_items_for_client_default2" ~> "suspend_items"
                    ])
                ]
            case .user(let userId):
                return [
                    .from(userDefaults: .standard, items: [
                        "KV.LarkSuspendable.bubble_rect_for_client_\(userId)" ~> "bubble_rect",
                        "KV.LarkSuspendable.suspend_items_for_client2_\(userId)" ~> "suspend_items"
                    ])
                ]
            }
        }

        registerMigration(forDomain: core.child("AssetsPicker"), strategy: .move) { space in
            guard case .global = space else { return [] }
            return [
                .from(userDefaults: .standard, items: [
                    "KV.AssetPickerSuiteView.hasShowPrevent" ~> "hasShowPrevent"
                ])
            ]
        }

        registerMigration(forDomain: core.child("Mine"), strategy: .move) { space in
            guard case .user(let uid) = space, !uid.isEmpty else { return [] }
            return [
                .from(userDefaults: .suiteName("LarkUser_\(uid)_v3"), items: [
                    "mine_user_department" ~> "user_department",
                    "mine_user_organization" ~> "user_organization",
                    "mine_user_city" ~> "user_city",
                    "mine_user_description" ~> "user_description",
                    "mine_user_description_type" ~> "user_description_type",
                    "mine_sticker_last_sync_time" ~> "sticker_last_sync_time",
                    "enable_another_name",
                    "another_name",
                    "onboarding_upgrade_team_mine_badge_showed",
                    "activity_award_banner_summary",
                    "activity_award_banner_summary_url",
                    "activity_award_already_enter"
                ])
            ]
        }

        registerMigration(forDomain: core.child("LeanMode"), strategy: .move) { space in
            guard case .user(let uid) = space else { return [] }
            return [
                .from(userDefaults: .standard, items: [
                    "kLeanMode_TimeInterval_\(uid)" ~> "TimeInterval",
                    "kLeanMode_SecurityPwdStatus_\(uid)" ~> "SecurityPwdStatus",
                    "kLeanMode_StatusAndAuthority_\(uid)" ~> "StatusAndAuthority"
                ])
            ]
        }

        registerMigration(forDomain: core.child("Theme"), strategy: .move) { space in
            guard space == .global else { return [] }
            return [
                .from(userDefaults: .standard, items: ["UDThemeManager.store"])
            ]
        }

        registerMigration(forDomain: Domain.biz.setting, strategy: .move) { space in
            switch space {
            case .global:
                return [
                    .from(userDefaults: .standard, items: [
                        "ChatSupportAvatarLeftRight"
                    ])
                ]
            case .user(let uid):
                guard !uid.isEmpty else { return [] }
                return [
                    .from(userDefaults: .suiteName("LarkUser_\(uid)_v3"), items: [
                        "smart_reply_enabled",
                        "smart_action_enable",
                        "smart_compose_message_enable",
                        "smart_compose_mail_enable",
                        "smart_compose_doc_enable",
                        "enterprise_entity_word_tenant_switch_enable",
                        "enterprise_entity_word_message_enable",
                        "enterprise_entity_word_doc_enable",
                        "smart_correct_enable"
                    ])
                ]
            }
        }

        registerMigration(forDomain: Domain.biz.ai, strategy: .move) { space in
            switch space {
            case .global:
                return [
                    .from(userDefaults: .standard, items: [
                        "smartCorrectDefaultesKey",
                        "lark_larkweb_webAutoTranslateGuideKey" ~> "webAutoTranslateGuideKey"
                    ])
                ]
            case .user(let uid):
                guard !uid.isEmpty else { return [] }
                return [
                    .from(userDefaults: .suiteName("LarkUser_\(uid)_v3"), items: [
                        "ai_translation_main_language",
                        "ai_translation_last_selected_target_language",
                        "ai_translation_message_char_threshold"
                    ]),
                ]
            }
        }

        registerMigration(forDomain: core.child("Navigation"), strategy: .move) { space in
            switch space {
            case .global:
                return [
                    .from(userDefaults: .standard, items: [
                        "lark_navigation_edit_guide_showed" ~> "edit_guide_showed",
                        "lark_debug_locoalTab" ~> "debugLocalTabs"
                    ])
                ]
            case .user(let uid):
                return [
                    .from(userDefaults: .standard, items: [
                        "\(uid)firstTab" ~> "firstTab"
                    ]),
                    .from(userDefaults: .suiteName("\(uid)_SideBarViewController"), items: ["cachedHeight"]),
                    .from(userDefaults: .suiteName("\(uid)_SideBarFilterListViewController"), items: ["filterCachedHeight"]),
                    .from(userDefaults: .suiteName("LarkUser_\(uid)_v3"), items: [
                        "navigation_info_v3",
                        "navigation_info_v2",
                        "navigation_main_tab_order_v2" ~> "main_tab_order_v2"
                    ])
                ]
            }
        }

        registerMigration(forDomain: core.child("Contact"), strategy: .move) { space in
            switch space {
            case .global:
                return [
                    .from(userDefaults: .standard, items: [
                        "contact_permission_banner_closed" ~> "permission_banner_closed"
                    ])
                ]
            case .user(let uid):
                var confs = [KVMigrationConfig]()
                if let passport = Dependencies.passport, let tenantID = passport.tenantId(forUser: uid) {
                    confs.append(.from(userDefaults: .standard, items: [
                        "\(tenantID)_\(uid)_firstLoginStatus" ~> "firstLoginStatus"
                    ]))
                    confs.append(.from(
                        userDefaults: .suiteName("invite_storage"),
                        items: [
                            "hasDisplayExternalInviteGuide_\(uid)" ~> "hasDisplayExternalInviteGuide",
                            "\(tenantID)_member_invite_permission" ~> "member_invite_permission",
                            "\(tenantID)_member_invite_banner_status" ~> "member_invite_banner_status",
                            "\(tenantID)_member_invite_is_admin" ~> "member_invite_is_admin"
                        ]
                    ))
                }
                confs.append(.from(userDefaults: .suiteName("LarkUser_\(uid)_v3"), items: [
                    "contacts_upload_server_timelinemark" ~> "upload_server_timelinemark",
                    "upload_contacts_max_num",
                    "upload_contacts_cd_mins",
                    "contact_application_badge" ~> "application_badge",
                    "onboarding_team_conversion_contact_entry_showed",
                    "onboarding_upload_contacts_max_num",
                ]))
                return confs
            }
        }

        registerMigration(forDomain: core.child("LaunchGuide"), strategy: .move) { space in
            guard space == .global else { return [] }
            return [
                .from(userDefaults: .suiteName("LarkLaunchGuide"), items: [
                    "LaunchGuideShowKey" ~> "show"
                ])
            ]
        }

        registerMigration(forDomain: core.child("Privacy"), strategy: .move) { space in
            guard space == .global else { return [] }
            return [
                .from(userDefaults: .standard, items: [
                    "HasShownPrivacyAlertKey" ~> "OldHasShownPrivacyAlert"
                ]),
                .from(userDefaults: .suiteName("LarkPrivacyAlert"), items: [
                    "HasShownPrivacyAlertKey" ~> "HasShownPrivacyAlert"
                ])
            ]
        }

        registerMigration(forDomain: core.child("AnimatedTabBar"), strategy: .move) { space in
            guard space == .global else { return [] }
            return [.from(userDefaults: .standard, items: [
                "globalShowEdgeTabbarKey" ~> "showEdgeTabbar"
            ])]
        }

        registerMigration(forDomain: core.child("LocationPicker"), strategy: .move) { space in
            guard space == .global else { return [] }
            return [
                .from(userDefaults: .standard, items: ["defaultUserLocation"])
            ]
        }

        registerMigration(forDomain: core.child("Focus"), strategy: .move) { space in
            switch space {
            case .global:
                return [.from(userDefaults: .standard, items: ["focus_onboarding_4"])]
            case .user(let uid):
                guard let tenantId = Dependencies.passport?.tenantId(forUser: uid) else {
                    KVStores.assertionFailure("cannot get tenantId for userId: \(uid)")
                    return []
                }
                return [
                    .from(userDefaults: .standard, items: [
                        "expand_status_\(tenantId)" ~> "expand_status"
                    ])
                ]
            }
        }

        registerMigration(forDomain: core.child("Notify"), strategy: .move) { space in
            guard space == .global else { return [] }
            return [
                .from(userDefaults: .standard, items: [
                    "notifyConfig.notifySounds" ~> "notifySounds"
                ])
            ]
        }

        registerMigration(forDomain: core.child("Chatter"), strategy: .move) { space in
            guard case .user(let uid) = space else { return [] }

            let keyBase = "Cached.Account.Key"
            let envTypes = Env.TypeEnum.allCases.map(\.domainKey)

            // 计算生成要迁移的 key
            var keys = [keyBase] + envTypes.map { "\(keyBase)_\($0)" }
            #if DEBUG
            keys = keys.map { "\($0)_debug" }
            #endif

            return [
                .from(userDefaults: .standard, items: keys.map {
                    .init(oldKey: "\($0)_\(uid)", newKey: $0)
                })
            ]
        }

        registerMigration(forDomain: core.child("Guide"), strategy: .move) { space in
            switch space {
            case .global:
                var configs: [KVMigrationConfig] = [
                    .from(userDefaults: .suiteName("GuideUserDefaults"), items: ["GUIDELIST"]),
                    .from(userDefaults: .suiteName("GuideUserDefaults"), prefixPattern: "lark_guide_"),
                    .from(userDefaults: .suiteName("GuideDataManager"), prefixPattern: "lk_guide_"),
                ]
                #if DEBUG
                configs.append(
                    .from(userDefaults: .standard, items: ["DISABLE_POPUP"])
                )
                #endif
                return configs
            case .user(let uid):
                return [
                    .from(userDefaults: .suiteName("GuideDataManager"), items: [
                        "GUIDE_DATA_KEY_\(uid)" ~> "GUIDE_DATA_KEY"
                    ])
                ]
            }
        }
 
        registerMigration(forDomain: core.child("SceneManager"), strategy: .move) { space in
            guard space == .global else { return [] }
            return [
                .from(userDefaults: .standard, items: ["supportsMultipleScenes"])
            ]
        }

        registerMigration(forDomain: core.child("SuiteAppConfig"), strategy: .move) { space in
            guard case .user(let uid) = space else { return [] }
            return [
                .from(userDefaults: .standard, items: [
                    "kSuiteAppConfig_LeanModeStatus_\(uid)" ~> "LeanModeStatus"
                ])
            ]
        }
    }

    private static func registerInfra() {
        let infra = Domain.biz.infra

        registerMigration(forDomain: infra.child("AppLog"), strategy: .move) { space in
            guard space == .global else { return [] }
            return [
                .from(userDefaults: .standard, items: [
                    "tracer.manager.custom.header.key" ~> "tracer.manager.custom.header"
                ])
            ]
        }

        registerMigration(forDomain: infra.child("ColdStartup"), strategy: .move) { space in
            guard space == .global else { return [] }
            return [
                .from(userDefaults: .standard, items: ["first_login_flag"])
            ]
        }

        registerMigration(forDomain: infra.child("LarkCache"), strategy: .move) { space in
            guard space == .global else { return [] }
            return [
                .from(userDefaults: .standard, items: [
                    "lark.cache.manager.larst_clean_time" ~> "last_clean_time",
                    "lark.cache.manager.clean_record" ~> "clean_record",
                    "lark.cache.manager.cache_path_to_clean_identifier_map" ~> "cache_path_to_clean_identifier_map"
                ])
            ]
        }
    }

    private static func registerTodo() {
        registerMigration(forDomain: Domain.biz.todo, strategy: .move) { space in
            guard case .user(let uid) = space else { return [] }
            return [
                .from(userDefaults: .suiteName("LarkUser_\(uid)_v3"), items: [
                    "todo_guide_in_chat_displayed" ~> "guide_in_chat_displayed"
                ])
            ]
        }
    }

    private static func registerMessenger() {
        let messenger = Domain.biz.messenger

        registerMigration(forDomain: messenger.child("Audio"), strategy: .move) { space in
            guard space == .global else { return [] }
            return [
                .from(userDefaults: .standard, items: [
                    "chat.audio.recognition.language" ~> "recognition.language",
                    "chat.audio.recognition.type" ~> "recognition.type"
                ])
            ]
        }

        registerMigration(forDomain: messenger.child("Chat"), strategy: .move) { space in
            guard case .user(let uid) = space else { return [] }
            return [
                .from(userDefaults: .suiteName("LarkUser_\(uid)_v3"), items: [
                    "custom_service_chat_id"
                ])
            ]
        }

        registerMigration(forDomain: messenger.child("ChatSetting"), strategy: .move) { space in
            guard case .user = space else { return [] }
            return [
                .from(userDefaults: .standard, dropPrefixPattern: "Lark_ChatSetting_")
            ]
        }

        registerMigration(forDomain: messenger.child("Edu"), strategy: .move) { space in
            guard space == .global else { return [] }
            return [
                .from(userDefaults: .standard, dropPrefixPattern: "Lark_Edu_")
            ]
        }

        registerMigration(forDomain: messenger.child("Emotion"), strategy: .move) { space in
            guard space == .global else { return [] }
            return [.from(userDefaults: .standard, items: ["CustomEmotionKey"])]
        }

        registerMigration(forDomain: messenger.child("File"), strategy: .move) { space in
            guard space == .global else { return [] }
            return [
                .from(userDefaults: .standard, items: [
                    "folder.management.default.style" ~> "default.style"
                ])
            ]
        }

        registerMigration(forDomain: messenger.child("Finance"), strategy: .move) { space in
            guard case .user(let uid) = space else { return [] }
            return [
                .from(userDefaults: .standard, items: [
                    "KV.Finance.phone\(uid)" ~> "phone"
                ])
            ]
        }

        registerMigration(forDomain: messenger.child("Flag"), strategy: .move) { space in
            guard space == .global else { return [] }
            return [.from(userDefaults: .standard, items: ["FlagSortingRule"])]
        }

        registerMigration(forDomain: messenger.child("Forward"), strategy: .move) { space in
            guard space == .global else { return [] }
            return [
                .from(userDefaults: .standard, items: [
                    "Forward.ForwardSetupTask.defaultOpenShare" ~> "ForwardSetupTask.defaultOpenShare"
                ])
            ]
        }

        registerMigration(forDomain: messenger.child("Search"), strategy: .move) { space in
            guard space == .global else { return [] }
            return [
                .from(userDefaults: .standard, items: [
                    "KV.Search.mainTab" ~> "mainTab"
                ])
            ]
        }

        registerMigration(forDomain: messenger.child("SecretChat"), strategy: .move) { space in
            guard space == .global else { return [] }
            return [
                .from(userDefaults: .suiteName("SecretChatDefaults"), items: [
                    "lark_secretChat_not_first" ~> "notFirst"
                ])
            ]
        }

        registerMigration(forDomain: messenger.child("SendMessage"), strategy: .move) { space in
            guard space == .global else { return [] }
            return [
                .from(userDefaults: .standard, items: [
                    "lastCheckPreprocessTime",
                    "predictedRecord"
                ])
            ]
        }

        registerMigration(forDomain: messenger.child("Tangram"), strategy: .move) { space in
            guard case .user(let uid) = space else { return [] }
            return [.allValuesFromUserDefaults(named: "URLPreview_Close_\(uid)")]
        }

        registerMigration(forDomain: messenger.child("Thread"), strategy: .move) { space in
            guard space == .global else { return [] }
            return [
                .from(userDefaults: .standard, prefixPattern: "LarkThread.AllTabItem.OnBoardingClosed.")
            ]
        }

        registerMigration(forDomain: messenger.child("Urgent"), strategy: .move) { space in
            guard space == .global else { return [] }
            return [
                .allValuesFromUserDefaults(named: "EM", to: .udkv)
            ]
        }
    }

    private static func registerMeego() {
        registerMigration(forDomain: Domain.biz.meego, strategy: .move) { space in
            guard case .user(let uid) = space, !uid.isEmpty else { return [] }
            return [
                .from(userDefaults: .suiteName("meego_kv_storage"), items: [
                    "meego_pay_enable/\(uid)" ~> "pay_enable"
                ])
            ]
        }
    }

    private static func registerMinutes() {
        registerMigration(forDomain: Domain.biz.minutes, strategy: .move) { space in
            switch space {
            case .global:
              return [
                    .from(userDefaults: .standard, items: [
                        "minutes_pid" ~> "pid",
                        "minutes_pidx" ~> "pidx",
                        "minutes_playtime" ~> "playtime"
                    ])
                ]
            case .user(let userId):
                return [
                    .from(userDefaults: .standard, items: [
                        "minutes.filter" ~> "filter",
                        "com.minutes.podcast.root.is.first.\(userId)" ~> "com.minutes.podcast.root.is.first"
                    ])
                ]
            }
        }
    }
    
    private static func registerOpenPlatform() {
        registerMigration(forDomain: Domain.biz.microApp, strategy: .sync) { space in
            switch space {
            case .global:
              return [
                    .from(userDefaults: .standard, items: [
                        "addMenu_message_action_cache_onboarding",
                        "msgAction_message_action_cache_onboarding",
                        "gadget.cookie.migration.from.AppIsolate.to.UserAndAppIsolate",
                        "debug_disable_network",
                        "KSSCommonLogicImageTransitionAnimationEnableKey",
                        "kBDPOriginUserAgentKey",
                        "TMA_Local_AnonymousID",
                        "kTMANetworkConnectOptimize",
                        "isBotBadgeShowed",
                    ])
                ]
            case .user(let userId):
                return [
                    .from(userDefaults: .standard, items: [
                    ])
                ]
            }
        }
    }
}
