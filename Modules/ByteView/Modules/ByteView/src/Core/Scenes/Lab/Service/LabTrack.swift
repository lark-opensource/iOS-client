//
//  LabTrack.swift
//  ByteView
//
//  Created by wangpeiran on 2021/3/14.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewTracker
import ByteViewNetwork

private struct LabTrackValue {
    static let BACKGROUND = "background"
    static let EFFECT = "effect"
    static let MOJI = "moji"
    static let FILTER_MAKEUP = "filter_makeup"
    static let TOUCHUP = "touch_up"
    static let FILTER = "filter"
}

final class LabTrack {
    // MARK: - 一些静态方法 埋点
    static func trackLabSelectedEffect(source: LabFromSource, model: ByteViewEffectModel) {
        var typeStr = ""
        var keyStr: TrackParamKey = ""
        var name = model.title

        let sourceStr: TrackEventName
        switch source {
        case .preview:
            sourceStr = .vc_meeting_page_preview
        case .inMeet:
            sourceStr = .vc_labs_setting_page
        case .preLobby:
            sourceStr = .vc_pre_waitingroom
        case .inLobby:
            sourceStr = .vc_meeting_page_waiting_rooms
        }

        switch model.labType {
        case .animoji:
            typeStr = "choose_avatar"
            keyStr = "avatar_name"
            name = model.resourceId
            if model.bgType == .none {
                name = "no_avatar"
            }
        case .filter:
            typeStr = "choose_filter"
            keyStr = "filter_name"
            if model.bgType == .none {
                name = "no_filter"
            }
        default:
            typeStr = "other"
            keyStr = ""
        }

        VCTracker.post(name: sourceStr, params: [.action_name: typeStr, keyStr: name])
    }

    static func trackLabSelectedVirtualBg(source: LabFromSource, model: VirtualBgModel) {
        let (name, type) = Self.virtualBgNameType(model: model)
        let sourceStr: TrackEventName
        switch source {
        case .preview:
            sourceStr = .vc_meeting_page_preview
        case .inMeet:
            sourceStr = .vc_labs_setting_page
        case .preLobby:
            sourceStr = .vc_pre_waitingroom
        case .inLobby:
            sourceStr = .vc_meeting_page_waiting_rooms
        }
        VCTracker.post(name: sourceStr, params: [.action_name: "virtual_background", "picture_name": name, "type": type])
    }

    static func trackLabSliderEffect(source: LabFromSource, model: ByteViewEffectModel, applyType: EffectSettingType) {
        var actionName = ""

        let sourceStr: TrackEventName
        switch source {
        case .preview:
            sourceStr = .vc_meeting_page_preview
        case .inMeet:
            sourceStr = .vc_labs_setting_page
        case .preLobby:
            sourceStr = .vc_pre_waitingroom
        case .inLobby:
            sourceStr = .vc_meeting_page_waiting_rooms
        }

        var currentValue = model.currentValue
        switch model.labType {
        case .filter:
            actionName = "filter_change_value"
        case .retuschieren:
            currentValue = model.applyValue(for: applyType)
            actionName = "touch_up_change_value"
        default:
            actionName = "other"
        }

        let dic: [String: Any] = ["id": model.resourceId, "value": currentValue ?? "", "is_default": currentValue == model.defaultValue ? 1 : 0]
        VCTracker.post(name: sourceStr, params: [.action_name: actionName, .extend_value: dic])
    }

    static func trackOnTheCall(meetType: MeetingType, effectManger: MeetingEffectManger) {
        let pageName: TrackEventName = meetType == .meet ? .vc_meeting_page_onthecall : .vc_call_page_onthecall
        self.trackOnTheCallFilterBeauty(pageName: pageName, effectManger: effectManger)
        self.trackOnTheCallAvatar(pageName: pageName, effectManger: effectManger)
        self.trackOnTheCallVirtualBg(pageName: pageName, effectManger: effectManger)
    }

    static func trackOnTheCallFilterBeauty(pageName: TrackEventName, effectManger: MeetingEffectManger) {
        var params: TrackParams = [:]
        params[.action_name] = "display_touch_up_and_filters"

        let filterArray = effectManger.pretendService.filterArray
        let beautyArray = effectManger.pretendService.retuschierenArray

        if !filterArray.isEmpty {
            var filterName = "no_filter"
            for item in filterArray where (item.isSelected && item.bgType == .set) {
                filterName = item.title
            }
            params["filter_name"] = filterName
        }

        if !beautyArray.isEmpty {
            var beautyParams: [String: Any] = [:]
            var valueSum = 0
            var defaultSum = 0
            var array: [[String: Any]] = []

            let applyType = effectManger.pretendService.beautyCurrentStatus

            for item in beautyArray {
                if item.effectModel.downloaded, let currentValue = item.applyValue(for: applyType) { // 只统计点击过的
                    valueSum += currentValue
                    if currentValue == item.defaultValue { // 是不是等于默认值
                        defaultSum += 1
                    }
                    let dic: [String: Any] = ["id": item.resourceId, "value": currentValue, "is_default": currentValue == item.defaultValue ? 1 : 0]
                    array.append(dic)
                }
            }

            if valueSum == 0 {
                beautyParams["touch_up_state"] = "close"
            } else if defaultSum == beautyArray.count {
                beautyParams["touch_up_state"] = "default"
            } else {
                beautyParams["touch_up_state"] = "custom"
                beautyParams["custom_value"] = array
            }

            if !beautyParams.isEmpty {
                params[.extend_value] = beautyParams
            }
        }

        VCTracker.post(name: pageName, params: params)
    }

    static func trackOnTheCallAvatar(pageName: TrackEventName, effectManger: MeetingEffectManger) {
        var params: TrackParams = [.action_name: "display_avatar"]
        let avatarArray = effectManger.pretendService.animojiArray
        if !avatarArray.isEmpty {
            var avatarName = "no_avatar"
            for item in avatarArray where (item.isSelected && item.bgType == .set) {
                avatarName = item.title
            }
            params["avatar_name"] = avatarName
        }
        VCTracker.post(name: pageName, params: params)
    }

    static func trackOnTheCallVirtualBg(pageName: TrackEventName, effectManger: MeetingEffectManger) {
        let virtualBgsArray = effectManger.virtualBgService.virtualBgsArray
        if !virtualBgsArray.isEmpty {
            var params: TrackParams = [.action_name: "display_virtual_background"]
            for item in virtualBgsArray where item.isSelected {
                let (name, type) = Self.virtualBgNameType(model: item)
                params["picture_name"] = name
                params["type"] = type
            }
            VCTracker.post(name: pageName, params: params)
        }
    }

    static func trackClickDecorate() {
        let params: TrackParams = [.click: "third_background",
                                   "setting_tab": "effect",
                                   "labs_tab": "background",
                                   .target: TrackEventName.vc_meeting_popup_view]
        VCTracker.post(name: .vc_meeting_setting_click, params: params)
    }

    static func trackShowDecorate() {
        VCTracker.post(name: .vc_meeting_popup_view, params: [.content: "third_background"])
    }

    static func trackDecorateClick(isComfirm: Bool) {
        VCTracker.post(name: .vc_meeting_popup_click, params: [.content: "third_background", .click: isComfirm ? "confirm" : "cancel"])
    }

    static func trackClickAddd(source: LabFromSource) {
        var params: TrackParams = [.click: "upload_virtual_background", "setting_tab": "effect", "labs_tab": "background"]
        let sourceStr: TrackEventName
        switch source {
        case .preview:
            sourceStr = .vc_meeting_pre_click
            params[.is_starting_auth] = false
        case .inMeet:
            sourceStr = .vc_meeting_setting_click
        case .preLobby:
            sourceStr = .vc_meeting_pre_click
            params[.is_starting_auth] = true
        case .inLobby:
            sourceStr = .vc_meeting_waiting_click
        }

        VCTracker.post(name: sourceStr, params: params)
    }

    static func trackTapDeleteVirtual(source: LabFromSource, model: VirtualBgModel) {
        var target = ""
        var params: TrackParams = [.click: "delete", .content: "delete_virtual_background"]

        let (name, type) = Self.virtualBgNameType(model: model)

        switch source {
        case .preview:
            target = "meeting_page_preview"
        case .inMeet:
            target = "labs_setting_page"
        case .preLobby:
            target = "pre_waitingroom"
        case .inLobby:
            target = "meeting_page_waiting_rooms"
        }
        params[.target] = target
        params["picture_name"] = name
        params["type"] = type
        VCTracker.post(name: .vc_meeting_popup_click, params: params)
    }

    static func trackShowPopupView(_ content: String) {
        VCTracker.post(name: .vc_meeting_popup_view, params: [.content: content])
    }

    static func trackVirtualBgSelected(model: VirtualBgModel) {
        let (name, type) = Self.virtualBgNameType(model: model)
        VCTracker.post(name: .vc_meeting_page_onthecall,
                       params: [.action_name: "virtual_background",
                                .from_source: "vc_labs",
                                "picture_name": name,
                                "type": type])
    }

    static func trackBeautify(retouchEffect: Int) {
        VCTracker.post(name: .vc_meeting_page_onthecall,
                       params: [.action_name: "beautify",
                                .from_source: "vc_labs",
                                .extend_value: ["retouch_effect": retouchEffect]])
    }

    static func trackTapVideoMirrorSetting(on: Bool, settingTab: String = "effect") {
        VCTracker.post(name: .vc_meeting_setting_click,
                       params: [.click: "is_mirror",
                                "is_check": on,
                                "setting_tab": settingTab])
    }
}

extension LabTrack {
    static func virtualBgNameType(model: VirtualBgModel) -> (String, String) {
        var picture_name = model.name
        var type = ""

        switch model.bgType {
        case .setNone:
            picture_name = "no_background"
        case .blur:
            picture_name = "blur_my_background"
            type = "settings"
        case .add:
            picture_name = "add"
        default:
            ()
        }
        if model.bgType == .virtual {
            switch model.imageSource {
            case .appSettings:
                type = "settings"
            case .appAdmin:
                type = "admin_background"
            case .appWin, .appMac, .appAndroid, .appIos, .appIpad:
                picture_name = "customized_background"
                type = "customized"
            case .isvUploadFromVc:
                picture_name = "customized_background"
                type = "isv_customized_background"
            case .isvUpload:
                type = "isv_background_uploaded_in_linchan"
                picture_name = "isv_background_uploaded_in_linchan"
            case .isvUploadFromPreset:
                type = "isv_system"
            default:
                ()
            }
        }
        return (picture_name, type)
    }
}

// MARK: - CPU打分与静态检测

extension LabTrack {

    static func trackVirtualBg(_ model: VirtualBgModel, isVirtualBgEffective: Bool = true) {
        guard model.bgType != .add else { // 代表“+”和“修饰”的两个View，它们不应被处理
            return
        }
        var curBgType = model.name
        switch model.bgType {
        case .setNone: // 不设置背景
            curBgType = "none"
        case .blur: // 背景虚化
            curBgType = "blur_my_background"
        case .virtual: // 虚拟背景
            switch model.imageSource {
            case .appAdmin:
                curBgType = "admin_background"
            case .appWin, .appMac, .appAndroid, .appIos, .appIpad, // 用户上传的背景
                    .isvUploadFromVc, // 从飞书同步到ISV的图，通过ISV编辑后上传
                    .isvUpload: // 用户通过ISV本地添加上传
                curBgType = "customized_background"
            default: // 默认传model的名字，如预置在ISV里面的图片（通过ISV编辑后上传）
                break
            }
        default: // 默认传model的名字
            break
        }
        VCTracker.post(name: .vc_meeting_onthecall_status,
                       params: ["background_status": isVirtualBgEffective,
                                "type": isVirtualBgEffective ? curBgType : "none"])
    }

    static func trackAnimoji(_ model: ByteViewEffectModel, isAnimojiEffective: Bool = true) {
        VCTracker.post(name: .vc_meeting_onthecall_status,
                       params: ["avatar_status": isAnimojiEffective,
                                "type": isAnimojiEffective ? model.resourceId : "none"])
    }

    static func trackFilter(_ model: ByteViewEffectModel, isFilterEffective: Bool = true) {
        let filter_name = isFilterEffective ? model.title : "none"
        VCTracker.post(name: .vc_meeting_onthecall_status,
                       params: ["filter_status": isFilterEffective,
                                "type": ["filter_name": filter_name,
                                         "filter_value": model.currentValue ?? 0]
                               ])
    }

    static func trackBeauty(_ modelArray: [ByteViewEffectModel], isBeautyEffective: Bool = true, pretendService: EffectPretendService?) {
        guard !modelArray.isEmpty, let pretendService = pretendService else {
            return
        }
        let applyType = pretendService.beautyCurrentStatus
        var isRetuschierenNeverChanged = true // 没有修改过任何美颜参数
        var isAnyBeautyEnabled = false // 有任何美颜当前值非0
        var paramsDic = [String: Any]()
        for index in 1...modelArray.count {
            let item = modelArray[index - 1]
            let currentValue = item.applyValue(for: applyType)
            if currentValue != item.defaultValue {
                isRetuschierenNeverChanged = false
            }
            paramsDic["id\(index)"] = item.resourceId
            paramsDic["value\(index)"] = currentValue ?? 0
            paramsDic["id_default\(index)"] = currentValue == item.defaultValue ? 1 : 0
            if currentValue != 0 {
                isAnyBeautyEnabled = true
            }
        }
        var state = isRetuschierenNeverChanged ? "default" : "custom"
        if applyType == .auto {
            state = "auto"
        }
        paramsDic["touch_up_state"] = state
        VCTracker.post(name: .vc_meeting_onthecall_status,
                       params: ["touch_up_status": isBeautyEffective && isAnyBeautyEnabled,
                                "type": applyType == .none || !isBeautyEffective ? "none" : paramsDic])
    }

}

// MARK: New Trackers
final class LabTrackV2 {

    /// 调节美颜效果
    static func trackLabSliderEffect(model: ByteViewEffectModel, isFromInMeet: Bool, applyType: EffectSettingType) {
        switch model.labType {
        case .retuschieren:
            guard let type = EffectResource.retuschieren[model.resourceId]?.type else {
                return
            }
            var retuschierenTrackStr: String = ""
            var valueStr: TrackParamKey = ""
            switch type {
            case .buffing:
                retuschierenTrackStr = "haul_buffing"
                valueStr = "buffing_value"
            case .eyes:
                retuschierenTrackStr = "haul_eyes"
                valueStr = "eyes_value"
            case .facelift:
                retuschierenTrackStr = "haul_facelift"
                valueStr = "facelift_value"
            case .lipstick:
                retuschierenTrackStr = "haul_lipstick"
                valueStr = "lipstick_value"
            }
            let currentValue = model.applyValue(for: applyType)
            VCTracker.post(name: .vc_meeting_setting_click,
                           params: [.click: retuschierenTrackStr,
                                    "is_default": currentValue == model.defaultValue,
                                  valueStr: currentValue ?? ""])
        case .filter:
            let defaultValue: Int = model.defaultValue ?? -1
            let currentValue: Int = model.currentValue ?? 0
            VCTracker.post(name: isFromInMeet ? .vc_meeting_setting_click : .vc_meeting_pre_click,
                           params: [.click: "haul_filter",
                                    "is_default": currentValue == defaultValue,
                                    "filter_value": currentValue])
        default:
            return
        }
    }

    /// 选择虚拟背景
    static func trackLabSelectedVirtualBg(model: VirtualBgModel, source: LabFromSource) {
        guard let eventName = source.trackEvent else { return }

        var type = ""
        var pictureName = ""
        if model.bgType != .setNone {
            let trackName = LabTrack.virtualBgNameType(model: model)
            pictureName = trackName.0
            type = trackName.1
        }
        var params: TrackParams = [.click: "choose_virtual_background",
                                   "background_type": type,
                                   "settings_tab": LabTrackValue.EFFECT,
                                   "labs_tab": LabTrackValue.BACKGROUND,
                                   "background_picture_name": pictureName]
        if source.trackFromPre {
            params[.is_starting_auth] = source.trackIsStartingAuth
        }
        VCTracker.post(name: eventName, params: params)
    }

    /// 选择滤镜、美颜或虚拟头像
    static func trackLabSelectedEffect(model: ByteViewEffectModel, source: LabFromSource) {
        guard let eventName = source.trackEvent else { return }
        var filterName: String = model.title
        switch model.labType {
        case .animoji:
            if model.bgType == .none {
                filterName = "no_avatar"
            }
            var params: TrackParams = [.click: "choose_avatar",
                                       "settings_tab": LabTrackValue.EFFECT,
                                       "labs_tab": LabTrackValue.MOJI,
                                       "avatar_name": model.resourceId]
            if source.trackFromPre {
                params[.is_starting_auth] = source.trackIsStartingAuth
            }
            VCTracker.post(name: eventName, params: params)
        case .filter:
            if model.bgType == .none {
                filterName = "no_filter"
            }
            var params: TrackParams = [.click: "choose_filter",
                                       "labs_tab": LabTrackValue.FILTER_MAKEUP,
                                       "filter_name": filterName]
            if source.trackFromPre {
                params[.is_starting_auth] = source.trackIsStartingAuth
            }
            VCTracker.post(name: eventName, params: params)
        case .retuschieren:
            var click, labs_tab: String
            switch model.bgType {
            case .none:
                click = "touch_up_original"
                labs_tab = "touch_up"
            case .auto:
                click = "touch_up_auto"
                labs_tab = "touch_up"
            case .customize:
                click = "touch_up_customized"
                labs_tab = "touch_up"
            case .set:
                click = "touch_up"
                labs_tab = LabTrackValue.FILTER_MAKEUP
            }
            var params: TrackParams = [.click: click,
                                       "labs_tab": labs_tab,
                                       "setting_tab": LabTrackValue.EFFECT,
                                       "filter_name": EffectResource.retuschieren[model.resourceId]?.type.trackName ?? ""]
            if source.trackFromPre {
                params[.is_starting_auth] = source.trackIsStartingAuth
            }
            VCTracker.post(name: eventName, params: params)
        default:
            break
        }
    }

    /// 选择特效tab
    static func trackSelectLabTab(param: (LabFromSource, EffectType)) {
        let (source, type) = param
        guard let eventName = source.trackEvent else { return }

        var typeStr = ""
        switch type {
        case .virtualbg:
            typeStr = "tab_virtual_background"
        case .animoji:
            typeStr = "tab_avatar"
        case .filter:
            typeStr = "tab_filter"
        case .retuschieren:
            typeStr = "tab_touch_up"
        }

        var params: TrackParams = [.click: typeStr, "setting_tab": LabTrackValue.EFFECT]
        if source.trackFromPre {
            params[.is_starting_auth] = source.trackIsStartingAuth
        }
        VCTracker.post(name: eventName, params: params)
    }

    static func trackLabReload(source: LabFromSource, type: EffectType) {
        var params: TrackParams = [.click: "labs_reload",
                                   "labs_tab": type.trackLabsTab]
        if source.trackFromPre {
            params[.is_starting_auth] = source.trackIsStartingAuth
            VCTracker.post(name: .vc_meeting_pre_click, params: params)
        } else {
            params["setting_tab"] = LabTrackValue.EFFECT
            VCTracker.post(name: .vc_meeting_setting_click, params: params)
        }
    }
}

extension LabFromSource {
    var trackEvent: TrackEventName? {
        switch self {
        case .preLobby, .preview:
            return .vc_meeting_pre_click
        case .inMeet:
            return .vc_meeting_setting_click
        default:
            return nil
        }
    }

    var trackFromPre: Bool {
        switch self {
        case .preview, .preLobby:
            return true
        default:
            return false
        }
    }

    var trackIsStartingAuth: Bool {
        self == .preLobby
    }
}

extension RetuschierenType {
    var trackName: String {
        var filterName: String
        switch self {
        case .buffing:
            filterName = "buffing"
        case .eyes:
            filterName = "eyes"
        case .facelift:
            filterName = "facelift"
        case .lipstick:
            filterName = "lipstick"
        }
        return filterName
    }
}

extension EffectType {
    var trackLabsTab: String {
        switch self {
        case .virtualbg:
            return LabTrackValue.BACKGROUND
        case .animoji:
            return LabTrackValue.MOJI
        case .retuschieren:
            return LabTrackValue.TOUCHUP
        case .filter:
            return LabTrackValue.FILTER
        }
    }
}
