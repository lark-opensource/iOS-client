//
//  I18nKeyInfo.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/11/29.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Videoconference_V1_I18nKeyInfo
public struct I18nKeyInfo: Equatable, Codable {
    public init(key: String, params: [String: String], type: TypeEnum, jumpScheme: String,
                newKey: String, i18NParams: [String: I18nParam]) {
        self.key = key
        self.params = params
        self.type = type
        self.jumpScheme = jumpScheme
        self.newKey = newKey
        self.i18NParams = i18NParams
    }

    /// 3.6以下版本用的i18n key
    public var key: String

    /// i18n消息占位符实参
    public var params: [String: String]

    /// 新增类型参数
    public var type: TypeEnum

    /// 新增跳转scheme参数
    public var jumpScheme: String

    /// 3.6以上版本都用这个i18n key
    public var newKey: String

    /// >=3.34可以使用，客户端渲染i18n占位符场景
    public var i18NParams: [String: I18nParam]

    public enum TypeEnum: Int, Hashable, Codable {

        case unknown // = 0

        /// 不带跳转的tips
        case normal // = 1

        /// 支持scheme跳转的tips
        case schemeJump // = 2

        /// 支持应用升级跳转的tips
        case upgradeJump // = 3

        /// 支持我的客服跳转的tips
        case customerJump // = 4

        /// 支持字幕设置跳转的tips
        case subtitleSettingJump // = 5

        /// 支持自动录制合规推送设置跳转的tips
        case autoRecordSettingJump // = 6

        ///面试官测tips不展示
        case interviewerTipsAddDisappear // = 7
    }

    public struct I18nParam: Equatable, Codable {
        public var type: I18nParam.TypeEnum
        public var val: String

        public enum TypeEnum: Int, Hashable, Codable {
            case unknown // = 0
            case rawText // = 1
            case userID // = 2
            case deviceID // = 3
            case userType // = 4
        }

        public init(type: I18nParam.TypeEnum, val: String) {
            self.type = type
            self.val = val
        }
    }
}

extension I18nKeyInfo: CustomStringConvertible {
    public var description: String {
        String(indent: "I18nKeyInfo",
               "key: \(key)",
               "type: \(type)",
               "newKey: \(newKey)",
               "params: \(params)",
               "i18NParams: \(i18NParams.mapValues({ "(type=\($0.type), val=\($0.val))" }))"
        )
    }
}
