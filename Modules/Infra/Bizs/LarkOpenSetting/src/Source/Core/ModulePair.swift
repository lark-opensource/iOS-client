//
//  ModulePair.swift
//  LarkOpenSetting
//
//  Created by panbinghua on 2022/9/1.
//

import Foundation

public struct ModulePair {
    public struct NotificationDiagnose {
        public static let diagnoseTips = PatternPair("diagnosising", "diagnoseTips")
        public static let diagnoseMain = PatternPair("diagnosising", "diagnoseMain")
        public static let customService = PatternPair("customService", "CustomService")
    }

    public struct SpecialFocus {
        public static let specialFocusNumber = PatternPair("specialFocusNumber", "")
        public static let specialFocusSetting = PatternPair("specialFocusSetting", "")
    }

    public struct MultiUserNotification {
        public static let multiUserSwitch = PatternPair("multiUser", "multiUserSwitch")
        public static let multiUserList = PatternPair("multiUser", "multiUserList")
    }

    public struct Main {
        public static let accountEntry = PatternPair("accountEntry", "")
        public static let generalEntry = PatternPair("generalEntry", "")

        public static let notificationEntry = PatternPair("notificationEntry", "")

        public static let privacyEntry = PatternPair("privacyEntry", "")
        public static let ccmEntry = PatternPair("ccmEntry", "")
        public static let calendarEntry = PatternPair("calendarEntry", "")
        public static let mailEntry = PatternPair("mailEntry", "")
        public static let videoConferenceEntry = PatternPair("videoConferenceEntry", "")
        public static let todoEntry = PatternPair("todoEntry", "")
        public static let momentEntry = PatternPair("momentEntry", "")
        public static let efficiencyEntry = PatternPair("efficiencyEntry", "")

        public static let thirdPartySDKListEntry = PatternPair("thirdPartySDKListEntry", "")
        public static let personalInfoEntry = PatternPair("personalInfoEntry", "")

        public static let innerSettingEntry = PatternPair("innerSettingEntry", "")
        public static let aboutLarkEntry = PatternPair("aboutLarkEntry", "")

        public static let mainVersion = PatternPair("mainVersion", "")
        public static let mainLogout = PatternPair("mainLogout", "")
    }

    public struct AboutLark {
        public static let featureIntro = PatternPair("aboutLark", "featureIntro")
        public static let whitePaper = PatternPair("aboutLark", "whitePaper")
        public static let privacy = PatternPair("aboutLark", "privacy")
    }

    public struct InnerSetting {
        public static let innerSetting = PatternPair("innerSetting", "")
    }

    public struct Notification {
        public static let main = PatternPair("notificationSettingMain", "main")
        public static let specialFocus = PatternPair("notificationSettingMain", "specialFocus")
        public static let inStartCallIntent = PatternPair("notificationSettingVC", "INStartCallIntent")
        public static let useSystemCall = PatternPair("notificationSettingVC", "useSystemCall")
        public static let includesCallsInRecents = PatternPair("notificationSettingVC", "includesCallsInRecents")
        public static let offDuringCalls = PatternPair("notificationSettingMain", "offDuringCalls")
        public static let indisturbEntry = PatternPair("notificationSettingIndisturbEntry", "")
        public static let whenPCOnline = PatternPair("notificationSettingWhenPCOnline", "")
        public static let showDetail = PatternPair("notificationSettingShowDetail", "")
        public static let addUrgentNum = PatternPair("notificationSettingAddUrgentNum", "")
        public static let diagnose = PatternPair("notificationSettingDiagnose", "")
        public static let voice = PatternPair("notificationSettingVoice", "")
        public static let customizeRingtone = PatternPair("notificationSettingCustomizeRingtone", "customizeRingtone")
        public static let multiUserNotification = PatternPair("notificationSettingMain", "multiUserNotification")
    }

    public struct NotificationSpecific {
        public static let specific = PatternPair("notificationSettingSpecific", "")
    }

    public struct CapabilityPermission {
        public static let cameraAndPhoto = PatternPair("capabilityPermission", "cameraAndPhoto")
        public static let location = PatternPair("capabilityPermission", "location")
        public static let contactAndMicrophone = PatternPair("capabilityPermission", "contactAndMicrophone")
        public static let calendar = PatternPair("capabilityPermission", "calendar")
    }

    public struct General {
        public static let appearance = PatternPair("appearance", "")
        public static let messageAlignment = PatternPair("messageAlignment", "")

        public static let language = PatternPair("language", "")
        public static let profileMultiLanguage = PatternPair("profileMultiLanguage", "")
        public static let translation = PatternPair("translation", "")

        public static let font = PatternPair("font", "")
        public static let basicFunction = PatternPair("basicFunction", "")
        public static let timeFormat = PatternPair("timeFormat", "")
        public static let ipadSingleColumnMode = PatternPair("ipadSingleColumnMode", "")
        public static let wifiSwich4G = PatternPair("wifiSwich4G", "")
        public static let networkDiagnose = PatternPair("networkDiagnose", "")
        public static let cache = PatternPair("cache", "")
        public static let EMManager = PatternPair("EMManager", "")
    }

    public struct Efficiency {
        public static let feedSetting = PatternPair("feedSetting", "")
        public static let audioToText = PatternPair("audioToText", "")
        public static let enterChatLocationEntry = PatternPair("enterChatLocationEntry", "")
        public static let smartComposeMessenger = PatternPair("smartComposeMessenger", "")
        public static let enterpriseEntity = PatternPair("enterpriseEntity", "")
        public static let smartCorrection = PatternPair("smartCorrection", "")
        public static let focusStatus = PatternPair("focusStatus", "")
        public static let feedActionSetting = PatternPair("feedActionSetting", "")
    }

    public struct Privacy {
        public static let waysToReachMeEntry = PatternPair("waysToReachMeEntry", "")
        public static let chatAuthEntry = PatternPair("chatAuthEntry", "")
        public static let timeZoneEntry = PatternPair("timeZoneEntry", "")
        public static let whenPhoneCheckedSetting = PatternPair("whenPhoneCheckedSetting", "")
        public static let blocklistEntry = PatternPair("blocklistEntry", "")
        public static let leaderLinkShareEntry = PatternPair("leaderLinkShareEntry", "")
    }

    public struct WaysToReachMe {
        public static let canModify = PatternPair("waysToReachMeSetting", "canModify")
        public static let findMeVia = PatternPair("waysToReachMeSetting", "findMeVia")
        public static let addMeVia = PatternPair("waysToReachMeSetting", "addMeVia")
        public static let addMeFrom = PatternPair("waysToReachMeSetting", "addMeFrom")
    }

    public struct CCM {
        public static let imShareLeader = PatternPair("imShareLeader", "")
        public static let linkShareType = PatternPair("linkShareType", "")
    }
}
