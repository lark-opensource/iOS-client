//
//  MeetingNotesModel.swift
//  Calendar
//
//  Created by huoyunjie on 2023/6/9.
//
import ServerPB
import RxSwift
import RustPB

struct MeetingNotesModel: Equatable {
    static func == (lhs: MeetingNotesModel, rhs: MeetingNotesModel) -> Bool {
        return lhs.type == rhs.type && lhs.token == rhs.token && lhs.url == rhs.url
    }

    /// 当前用户对这篇文档的权限
    enum DocPermission: Int, Equatable {
        /// 阅读
        case view // = 0
        /// 编辑
        case edit // = 1
        /// 删除
        case delete // = 2
    }

    /// 日程协作人对这篇文档的权限
    enum EventPermission: Int, Equatable {
        case unknown = 0
        case canView = 1
        case canEdit = 2

        static func defaultValue() -> Self {
            return .canEdit
        }

        var desc: String {
            switch self {
            case .canEdit: return I18n.Calendar_G_TheyEdit_Options
            case .canView: return I18n.Calendar_G_TheyRead_Options
            default: return I18n.Calendar_G_TheyEdit_Options
            }
        }
    }

    // doc url 链接
    let url: String
    // doc 标题
    let title: String
    // doc token
    let token: String
    // doc type
    let type: Int
    // doc 权限
    var permission: [DocPermission]
    // 是否可以对外授权
    let canUserOpen: Bool
    // 是否已开启对外分享
    let needShowTip: Bool
    // doc 缩略图信息
    var thumbnail: Thumbnail?
    // 日程参与人权限
    var eventPermission: EventPermission = .defaultValue()
    // 是否可进行日程协作人权限编辑操作
    var showEventPermission: Bool
    // 文档类型，nil 表示是以关联日程的文档，不进行 type 区分
    var notesType: NotesType?

    var docOwnerId: Int64?
    var docBotId: Int64?

    struct Thumbnail {
        var image: UIImage?
        var rxImage: Observable<UIImage>?
        let url: String
        let thumbnailURL: String
        let decryptKey: String
        let cipherType: Int
    }

    init(fromRust pb: Rust.NotesInfo) {
        url = pb.meta.url
        title = pb.meta.title
        token = pb.meta.docToken
        type = pb.meta.docType.rawValue
        permission = []
        if pb.permission.contains(.view) {
            permission.append(.view)
        }
        if pb.permission.contains(.edit) {
            permission.append(.edit)
        }
        if pb.permission.contains(.delete) {
            permission.append(.delete)
        }
        canUserOpen = pb.showPermSetting
        needShowTip = pb.showPermTip
        if pb.hasThumbnail {
            let thumbnail = pb.thumbnail
            self.thumbnail = Thumbnail(url: thumbnail.url,
                                       thumbnailURL: thumbnail.thumbnailURL,
                                       decryptKey: thumbnail.decryptKey,
                                       cipherType: Int(thumbnail.cipherType))
        }
        if pb.hasNotesEventPermission,
            let permission = EventPermission(rawValue: pb.notesEventPermission.rawValue) {
            self.eventPermission = permission
        }

        self.showEventPermission = pb.showEventPermission
    }

    init(fromServer pb: ServerPB_Calendar_entities_NotesInfo) {
        url = pb.meta.url
        title = pb.meta.title
        token = pb.meta.docToken
        type = pb.meta.docType.rawValue
        permission = []
        typealias ServerPermission = ServerPB_Calendar_entities_NotesInfo.NotesPermission
        if pb.notePermission.contains(ServerPermission.view) {
            permission.append(.view)
        }
        if pb.notePermission.contains(ServerPermission.edit) {
            permission.append(.edit)
        }
        if pb.notePermission.contains(ServerPermission.delete) {
            permission.append(.delete)
        }
        canUserOpen = pb.showPermSetting
        needShowTip = pb.showPermTip
        if pb.hasThumbnail {
            let thumbnail = pb.thumbnail
            self.thumbnail = Thumbnail(url: thumbnail.url,
                                       thumbnailURL: thumbnail.thumbnailURL,
                                       decryptKey: thumbnail.decryptKey,
                                       cipherType: Int(thumbnail.cipherType))
        }
        if pb.hasNotesEventPermission,
            let permission = EventPermission(rawValue: pb.notesEventPermission.rawValue) {
            self.eventPermission = permission
        }
        self.showEventPermission = pb.showEventPermission
    }
}

extension MeetingNotesModel {
    func transformToViewData() -> MeetingNotesViewData {
        MeetingNotesViewData(
            docTitle: self.title.isEmpty ? url : title,
            isDocReadable: !self.title.isEmpty,
            isDocDeletable: self.permission.contains(.delete),
            showPermissionTip: self.needShowTip,
            permissionTipStr: I18n.Calendar_Notes_DocExternalOffNoAuthorize,
            permissionSettingStr: self.canUserOpen ? I18n.Calendar_Notes_Setting_Click : "",
            rxThumbnailImage: self.thumbnail?.rxImage,
            eventPermission: self.showEventPermission ? self.eventPermission : nil
        )
    }
}

/// 文档类型
enum NotesType: Int, Equatable {
    case unknown = 0
    case createNotes = 1 // 新建notes文档
    case bindNotes = 2 // 关联已有文档

    func toServerPB() -> ServerPB_Calendar_entities_NotesType {
        return ServerPB_Calendar_entities_NotesType(rawValue: self.rawValue) ?? .createNotes
    }

    func toRustPB() -> Calendar_V1_NotesType {
        return Calendar_V1_NotesType(rawValue: self.rawValue) ?? .createNotes
    }
}
