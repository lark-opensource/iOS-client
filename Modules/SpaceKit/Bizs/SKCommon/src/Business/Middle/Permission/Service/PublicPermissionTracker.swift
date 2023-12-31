//
//  PublicPermissionTracker.swift
//  SpaceKit
//
//  Created by chenjiahao.gill on 2019/7/2.
//  

import SKFoundation

// https://bytedance.feishu.cn/space/doc/doccnhpULumVCntoO5xrnCO4BXc
public final class PublicPermissionTracker {

    public struct FileModel {
        var objToken: String
        var type: ShareDocsType
        var ownerID: String
        var tenantID: String
        var createTime: TimeInterval
        var createDate: String
        var createID: String
        public init(objToken: String,
                    type: ShareDocsType,
                    ownerID: String,
                    tenantID: String,
                    createTime: TimeInterval,
                    createDate: String,
                    createID: String) {
            self.objToken = objToken
            self.type = type
            self.ownerID = ownerID
            self.tenantID = tenantID
            self.createTime = createTime
            self.createDate = createDate
            self.createID = createID
        }
    }

    private var fileModel: FileModel
    public init(fileModel: FileModel) {
        self.fileModel = fileModel
    }

    /// 快速迭代，没时间解释了
     public func getReportingAction(indexPath: IndexPath) -> Action {
        let section = indexPath.section
        let row = indexPath.row
        if section == 0, row == 0 {
            return .visitWithPermissionReadable
        } else if section == 0, row == 1 {
            return .visitWithPermissionEditable
        } else if section == 0, row == 2 {
            return .visitWithPermissionAnyReadable
        } else if section == 0, row == 3 {
            return .visitWithPermissionAnyEditable
        } else if section == 1, row == 0 {
            return .publicPermissionCommentReadableUser
        } else if section == 1, row == 1 {
            return .publicPermissionCommentEditableUser
        } else if section == 2, row == 0 {
            return .publicPermissionShareReadableUser
//        } else if section == 2, row == 1 {
//            return .publicPermissionShareInviteOnlyInside
//        } else if section == 2, row == 2 {
//            return .publicPermissionShareInviteAnyone
        } else if section == 2, row == 1 {
            return .publicPermissionSharePrivate
        } else if section == 3, row == 0 {
            return .publicPermissionUseFileReadableUser
        } else if section == 3, row == 1 {
            return .publicPermissionUseFileEditableUser
        } else {
            return .unknown
        }
    }

     public func report(_ action: Action) {
        var params: [String: Any] = [String: Any]()
        params["action"] = action.rawValue
        params["eventType"] = "click"
        params["file_id"] = DocsTracker.encrypt(id: fileModel.objToken)
        params["file_tenant_id"] = DocsTracker.encrypt(id: fileModel.tenantID)
        let isCrossTenant = fileModel.tenantID == User.current.info?.tenantID ? "false" : "true"
        params["file_is_cross_tenant"] = isCrossTenant
        params["file_type"] = fileModel.type.name
        params["owner_id"] = fileModel.ownerID
        params["is_owner"] = fileModel.ownerID == User.current.info?.userID ? "true" : "false"
        params["create_time"] = fileModel.createTime
        params["create_date"] = fileModel.createDate
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        if !fileModel.createDate.isEmpty, let date = dateFormatter.date(from: fileModel.createDate) {
            let sinceNow = date.timeIntervalSinceNow
            params["from_create_date"] = Int(ceil(sinceNow / 60 / 60 / 24))
        }
        params["module"] = fileModel.type.name
        params["source"] = "click_public_permission_setting_items"
        DocsTracker.log(enumEvent: .shareOperation, parameters: params)
    }

     public func shareLinkReport(_ event: DocsTracker.EventType, permissionCount: Int, whetherRemind: Bool) {
        var params: [String: Any] = [String: Any]()
        params["permission_num"] = permissionCount
        params["no_more_remind"] = whetherRemind ? "true" : "false"
        DocsTracker.log(enumEvent: event, parameters: params)
    }

    public func reportShowPermissionPage() {
        var params: [String: Any] = [String: Any]()
        params["file_id"] = DocsTracker.encrypt(id: fileModel.objToken)
        params["file_type"] = fileModel.type.name
        params["create_time"] = String(fileModel.createTime)
        params["create_date"] = fileModel.createDate
        params["create_uid"] = DocsTracker.encrypt(id: fileModel.createID)
        params["is_owner"] = fileModel.ownerID == User.current.info?.userID ? "true" : "false"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        if !fileModel.createDate.isEmpty, let date = dateFormatter.date(from: fileModel.createDate) {
            let sinceNow = date.timeIntervalSinceNow
            let fromCreateDate = Int(ceil(sinceNow / 60 / 60 / 24))
            params["from_create_date"] = String(fromCreateDate)
        }
        DocsTracker.log(enumEvent: .showPermmisionPage, parameters: params)
    }
    
    public enum Action: String {
        case outsideVisitSwtichOpen = "outside_visit_swtich:open"
        case outsideVisitSwtichClose = "outside_visit_swtich:close"
        case urlVisitSwtichOpen = "url_visit_swtich:open"
        case urlVisitSwtichClose = "url_visit_swtich:close"
        case visitWithPermissionReadable = "visit_with_permission:readable"
        case visitWithPermissionEditable = "visit_with_permission:editable"
        case visitWithPermissionAnyReadable = "visit_with_permission:any_readable"
        case visitWithPermissionAnyEditable = "visit_with_permission:any_editable"
        case publicPermissionCommentReadableUser = "public_permission_comment:readable_user"
        case publicPermissionCommentEditableUser = "public_permission_comment:editable_user"
        case publicPermissionShareReadableUser = "public_permission_share:readable_user"
        case publicPermissionShareInviteOnlyInside = "public_permission_share:invite_only_inside"
        case publicPermissionShareInviteAnyone = "public_permission_share:invite_anyone"
        case publicPermissionSharePrivate = "public_permission_share:private"
        case publicPermissionUseFileReadableUser = "public_permission_use_file:readable_user"
        case publicPermissionUseFileEditableUser = "public_permission_use_file:editable_user"
        case unknown = "unknown"
    }
}
