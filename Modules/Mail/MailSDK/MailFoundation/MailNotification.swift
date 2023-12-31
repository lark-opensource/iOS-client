//
//  MailNotification.swift
//  MailSDK
//
//  Created by tefeng liu on 2020/7/14.
//

import Foundation

public extension Notification.Name {
    public struct Mail {
        /// when switch user or logout out . MailSDK need to clean data of user
        public static let MAIL_SDK_CLEAN_DATA = Notification.Name(rawValue: "MAIL_SDK_CLEAN_DATA")

        // 各种状态刷新的通知名字
        public static let MAIL_MESSAGE_DRAFT_REFRESHED = Notification.Name(rawValue: "MAIL_MESSAGE_DRAFT_REFRESHED")
        public static let MAIL_THREAD_LIST_REFRESHED = Notification.Name(rawValue: "MAIL_THREAD_LIST_REFRESHED")

        public static let MAIL_DOWNLOAD_DRIVE_IMAGE = Notification.Name(rawValue: "MAIL_DOWNLOAD_DRIVE_IMAGE")
        public static let MAIL_UPLOAD_DRIVE_IMAGE = Notification.Name(rawValue: "MAIL_UPLOAD_DRIVE_IMAGE")

        public static let MAIL_UPDATEDRAFT_CHANGELOG = Notification.Name(rawValue: "MAIL_UPDATEDRAFT_CHANGELOG")
        public static let MAIL_UPDATEDRAFT_CHANGELOG_DATA_KEY = "MAIL_UPDATEDRAFT_CHANGELOG_DATA_KEY"

        public static let MAIL_RESET_THREADLISTLABEL = Notification.Name(rawValue: "MAIL_RESET_THREADLISTLABEL")

        public static let MAIL_SETTING_CHANGED_BYSELF = Notification.Name(rawValue: "MAIL_SETTING_CHANGED_BYSELF")
        public static let MAIL_SETTING_UPDATE_RESP = Notification.Name(rawValue: "MAIL_SETTING_UPDATE_RESP")
        public static let MAIL_SETTING_CHANGED_BYPUSH = Notification.Name(rawValue: "MAIL_SETTING_CHANGED_BYPUSH")

        public static let MAIL_LOADING_VIEW_FAILED = Notification.Name(rawValue: "MAIL_LOADING_VIEW_FAILED")

        public static let MAIL_SETTING_DATA_KEY = "MAIL_SETTING_DATA_KEY"

        /// the push from server that the mail client state has been changed
        public static let MAIL_SETTING_AUTH_STATUS_CHANGED = Notification.Name(rawValue: "MAIL_SETTING_AUTH_STATUS_CHANGED")
        public static let MAIL_OAUTH_IS_SUCCESS_KEY = "MAIL_OAUTH_IS_SUCCESS_KEY"

        /// Mail service recover action. when enter mail page. you should do some recover action for sync data
        public static let MAIL_SERVICE_RECOVER_ACTION = Notification.Name(rawValue: "MAIL_SERVICE_RECOVER_ACTION")

        public static let MAIL_CACHED_CURRENT_SETTING_CHANGED = Notification.Name(rawValue: "MAIL_CACHED_CURRENT_SETTING_CHANGED")

        public static let MAIL_DID_SHOW_SHARED_ACCOUNT_ALERT = Notification.Name(rawValue: "MAIL_DID_SHOW_SHARED_ACCOUNT_ALERT")
        public static let MAIL_SWITCH_ACCOUNT = Notification.Name(rawValue: "MAIL_SWITCH_ACCOUNT")
        public static let MAIL_HIDE_API_ONBOARDING_PAGE = Notification.Name(rawValue: "MAIL_HIDE_API_ONBOARDING_PAGE")
        public static let MAIL_ADDRESS_NAME_CHANGE = Notification.Name(rawValue: "MAIL_ADDRESS_NAME_MAP_CHANGE")
    }
}
