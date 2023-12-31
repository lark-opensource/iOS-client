//
//  PickerTrackUtil.swift
//  LarkSearchCore
//
//  Created by chenziyue on 2021/10/20.
//

import Foundation
import ServerPB
import LarkModel
import LKCommonsTracker
import Homeric
import RxSwift
import LarkSDKInterface
import LarkSearchFilter
import CommonCrypto

extension SearchTrackUtil {

    public enum PickerClickType {
        case select(target: String, selectType: PickerSearchSelectType, listNumber: Int, id: String)
        case remove(target: String)
        case chatDetail(target: String)
        case searchBar
        case architectureMember
        case emailMemeber
        case associatedOrganizations
        case external
        case manageGroup
        case viewProfile
        case navigationBar(target: String)
        case nextLevel(target: String)
        case userGroup

        var target: String {
            switch self {
            case .select(let target, _, _, _): return target
            case .remove(let target): return target
            case .chatDetail(let target): return target
            case .searchBar: return "public_picker_select_search_member_view"
            case .architectureMember: return "public_picker_select_architecture_member_view"
            case .emailMemeber: return "public_picker_select_email_member_view"
            case .associatedOrganizations: return "public_picker_select_associated_organizations_view"
            case .external: return "public_picker_select_external_view"
            case .manageGroup: return "public_picker_select_manage_group_view"
            case .viewProfile: return "profile_main_view"
            case .navigationBar(let target): return target
            case .nextLevel(let target): return target
            case .userGroup: return "public_picker_select_user_group_view"
            }
        }

        var click: String {
            switch self {
            case .select: return "select"
            case .remove: return "remove"
            case .chatDetail: return "chat_detail"
            case .searchBar: return "search_bar"
            case .architectureMember: return "architecture_member"
            case .emailMemeber: return "email_member"
            case .associatedOrganizations: return "associated_organizations"
            case .external: return "external"
            case .manageGroup: return "manage_group"
            case .viewProfile: return "view_profile"
            case .navigationBar: return "navigation_bar"
            case .nextLevel: return "next_level"
            case .userGroup: return "user_group"
            }
        }
    }

    public static func trackPickerClick(
        event: String,
        clickType: PickerClickType
    ) {
        track(event, params: pickerTrackInfo(clickType: clickType))
    }

    public static func trackPickerSelectView(
        scene: String?
    ) {
        track(Homeric.PUBLIC_PICKER_SELECT_VIEW, params: pickerTrackInfo(scene: scene))
    }

    public static func trackPickerSelectClick(
        scene: String?,
        clickType: PickerClickType
    ) {
        track(Homeric.PUBLIC_PICKER_SELECT_CLICK, params: pickerTrackInfo(scene: scene, clickType: clickType))
    }

    public static func trackPickerSelectArchitectureView() {
        track(Homeric.PUBLIC_PICKER_SELECT_ARCHITECTURE_MEMBER_VIEW, params: [String: Any]())
    }

    public static func trackPickerSelectArchitectureClick(
        clickType: PickerClickType
    ) {
        track(Homeric.PUBLIC_PICKER_SELECT_ARCHITECTURE_MEMBER_CLICK, params: pickerTrackInfo(clickType: clickType))
    }

    public static func trackPickerSelectEmailMemberView() {
        track(Homeric.PUBLIC_PICKER_SELECT_EMAIL_MEMBER_VIEW, params: [String: Any]())
    }

    public static func trackPickerSelectEmailMemberClick(
        clickType: PickerClickType
    ) {
        track(Homeric.PUBLIC_PICKER_SELECT_EMAIL_MEMBER_CLICK, params: pickerTrackInfo(clickType: clickType))
    }

    public static func trackPickerSelectSearchMemberView() {
        track(Homeric.PUBLIC_PICKER_SELECT_SEARCH_MEMBER_VIEW, params: [String: Any]())
    }

    public static func trackPickerSelectSearchMemberClick(
        clickType: PickerClickType
    ) {
        track(Homeric.PUBLIC_PICKER_SELECT_SEARCH_MEMBER_CLICK, params: pickerTrackInfo(clickType: clickType))
    }

    public static func trackPickerManageGroupView() {
        track(Homeric.PUBLIC_PICKER_SELECT_MANAGE_GROUP_VIEW, params: [String: Any]())
    }

    public static func trackPickerSelectExternalView() {
        track(Homeric.PUBLIC_PICKER_SELECT_EXTERNAL_VIEW, params: [String: Any]())
    }

    public static func trackPickerUserGroupView() {
        track(Homeric.PUBLIC_PICKER_SELECT_USER_GROUP_VIEW, params: [String: Any]())
    }

    public static func trackPickerSelectAssociatedOrganizationsView() {
        track(Homeric.PUBLIC_PICKER_SELECT_ASSOCIATED_ORGANIZATIONS_VIEW, params: [String: Any]())
    }

    public static func trackPickerSelectAssociatedOrganizationsClick(
        clickType: PickerClickType
    ) {
        track(Homeric.PUBLIC_PICKER_SELECT_ASSOCIATED_ORGANIZATIONS_CLICK, params: pickerTrackInfo(clickType: clickType))
    }

    private static func pickerTrackInfo(
        scene: String? = nil
    ) -> [String: Any] {
        var trackInfo = [String: Any]()
        if let scene = scene {
            trackInfo["scene"] = scene
        } else {
            trackInfo["scene"] = "others"
        }
        return trackInfo
    }

    private static func pickerTrackInfo(
        clickType: PickerClickType
    ) -> [String: Any] {
        var trackInfo = [String: Any]()
        trackInfo["target"] = clickType.target
        trackInfo["click"] = clickType.click
        if case let .select(_, selectType, listNumber, entityId) = clickType {
            trackInfo["list_number"] = listNumber
            trackInfo["entity_id"] = encrypt(id: entityId)
            trackInfo["select_type"] = selectType.description
        }
        return trackInfo
    }

    private static func pickerTrackInfo(
        scene: String? = nil,
        clickType: PickerClickType
    ) -> [String: Any] {
        var trackInfo = [String: Any]()
        trackInfo["target"] = clickType.target
        trackInfo["click"] = clickType.click
        if let scene = scene {
            trackInfo["scene"] = scene
        } else {
            trackInfo["scene"] = "others"
        }
        if case let .select(_, selectType, listNumber, entityId) = clickType {
            trackInfo["list_number"] = listNumber
            trackInfo["entity_id"] = encrypt(id: entityId)
            trackInfo["select_type"] = selectType.description
        }
        return trackInfo
    }

}
