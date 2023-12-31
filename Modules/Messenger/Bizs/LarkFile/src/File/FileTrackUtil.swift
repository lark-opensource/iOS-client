//
//  FileTrackUtil.swift
//  LarkFile
//
//  Created by ChalrieSu on 2018/6/29.
//  Copyright © 2018 liuwanlin. All rights reserved.
//

import Foundation
import Homeric
import LarkModel
import LKCommonsTracker
import LarkCore
import AppReciableSDK
import LarkMessengerInterface
import LarkStorage

public struct FileTrackUtil {
    // do not remove, will crash when `BUILD_LIBRARY_FOR_DISTRIBUTION = YES;` if remove this.
    var ignore: Int = 0

    //点击保存到云盘
    func trackAttachedFileSaveToCloudDisk(fileType: String, chatType: String?, chatID: String?, messageId: String) {
        Tracker.post(TeaEvent(Homeric.CLICK_SAVE_CLOUDDISK, category: "driver", params: [
            "file_type": fileType,
            "chat_type": chatType ?? "",
            "chat_id": chatID ?? "",
            "message_id": messageId
        ]))
    }

    //保存完成
    func trackAttachedFileCloudDiskSaveFinish(fileType: String, isSuccess: Bool, fileSize: Int) {
        let statusString = isSuccess ? "success" : "fail"
        Tracker.post(TeaEvent(Homeric.SAVE_CLOUDDISK_FINISH, category: "driver", params: [
            "file_type": fileType,
            "status": statusString,
            "file_size": fileSize
            ])
        )
    }

    //点击发送键
    func trackAttachedFileSendButtonClicked(numberOfFiles: Int, localNumberOfFiles: Int, cloudDiskNumberOfFiles: Int, totalFileSize: Int) {
        Tracker.post(TeaEvent(Homeric.CLICK_ATTACH_SEND_BUTTON, category: "driver", params: [
            "file_num": numberOfFiles,
            "cloud_num": cloudDiskNumberOfFiles,
            "local_num": localNumberOfFiles
            ])
        )
        Tracker.post(TeaEvent(Homeric.IM_SEND_FILE_CONFIRMED, params: [
            "file_size": ByteCountFormatter.string(fromByteCount: Int64(totalFileSize), countStyle: .binary)
            ])
        )
    }

    // 文件大小超限
    func trackAttachedFileExceedLimit(fileSize: Int) {
        Tracker.post(TeaEvent(Homeric.IM_SEND_FILE_REJECTED, params: [
            "file_size": ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .binary)
            ])
        )
    }

    //点击文件项
    func trackAttachedFileSelected(type: String, isSelected: Bool, isFromLocal: Bool) {
        let selectedString = isSelected ? "select" : "select_cancel"
        let diskType = isFromLocal ? "local" : "cloud"
        Tracker.post(TeaEvent(Homeric.CLICK_DRIVER_LIST_FILE, category: "driver", params: [
            "file_type": type,
            "type": selectedString,
            "disk_type": diskType
            ])
        )
    }

    //本地文件主页展现
    func trackAttachedFileLocalDiskShown() {
        Tracker.post(TeaEvent(Homeric.SHOW_ATTACH_LOCALDISK, category: "driver"))
    }

    // 下载文件可感知埋点
    static func trackAppreciableDownload(task: FileDownloadTask, status: FileDownloadTaskStatus) {
        switch status {
        case .finish(let useCache, _):
            guard !useCache else { return }
            AppReciableSDK.shared.timeCost(
                params: TimeCostParams(
                    biz: .Messenger,
                    scene: .Chat,
                    event: .fileDownload,
                    cost: Int((Date().timeIntervalSince1970 - task.startTime) * 1000),
                    page: nil,
                    extra: Extra(metric: ["resource_content_length": task.file.fileSize],
                                 category: ["had_been_paused": task.hadBeenPaused])
                )
            )
        case .fail(let error):
            let errorType: ErrorType
            let errorCode: Int
            var errorMsg: String?
            switch error {
            case .createDirFail:
                (errorType, errorCode) = (.Other, 2)

            case .sourceFileBurned, .sourceFileWithdrawn:
                (errorType, errorCode) = (.Other, 3)

            case .downloadRequestFail(let code),
                    .sourceFileForzenByAdmin(let code),
                    .sourceFileShreddedByAdmin(let code),
                    .sourceFileDeletedByAdminScript(let code):
                (errorType, errorCode) = (.SDK, code)

            case .downloadFail(let code, let msg),
                    .securityControlDeny(let code, let msg),
                    .strategyControlDeny(let code, let msg):
                (errorType, errorCode, errorMsg) = (.SDK, code, msg)
            case .clientErrorRiskFileDisableDownload:
                /// TODO: @qihongye，确认是否需要加埋点，加什么。
                return
            }
            AppReciableSDK.shared.error(
                params: ErrorParams(
                    biz: .Messenger,
                    scene: .Chat,
                    event: .fileDownload,
                    errorType: errorType,
                    errorLevel: .Fatal,
                    errorCode: errorCode,
                    userAction: nil,
                    page: nil,
                    errorMessage: errorMsg,
                    extra: Extra(category: [:])
                )
            )
        default:
            break
        }
    }
}

extension FileTrackUtil {
    struct DecompressFail {}
}

extension FileTrackUtil.DecompressFail {
    static func timeOutView() {
        Tracker.post(TeaEvent("im_file_decompress_fail_time_out_view",
                              params: [:]))
    }

    static func timeOutClick() {
        var params: [AnyHashable: Any] = [:]
        params["click"] = "retry"
        params["target"] = "none"
        Tracker.post(TeaEvent("im_file_decompress_fail_time_out_click",
                              params: params))
    }

    static func notSupportView() {
        Tracker.post(TeaEvent("im_file_decompress_fail_not_support_view",
                              params: [:]))
    }

    static func notSupportClick() {
        var params: [AnyHashable: Any] = [:]
        params["click"] = "open_with_other_app"
        params["target"] = "none"
        Tracker.post(TeaEvent("im_file_decompress_fail_not_support_click",
                              params: params))
    }
}

// MARK: - 文件管理器

extension IMTracker {
    struct FileManage {}
}

// MARK: - 文件管理器页面 View & Click

/// 文件管理器页面展示
extension IMTracker.FileManage {
    static func View(extra: [AnyHashable: Any],
                     sourceScene: FileSourceScene) {
        var params: [AnyHashable: Any] = extra
        switch sourceScene {
        case .chat:
            params["source"] = "from_msg_folder"
        case .fileTab:
            params["source"] = "from_file_tab"
        case .search:
            params["source"] = "from_search_folder"
        default:
            params["source"] = "other"
        }

        let defaultStyle = KVStores.file.value(forKey: KVKeys.FileManagement.defaultStyle)
        params["view_type"] = defaultStyle ? "square" : "list"
        params["page_type"] = "folder_view"
        Tracker.post(TeaEvent(Homeric.IM_CHAT_FILE_LIST_VIEW,
                              params: params))
    }
}

//仅埋点用
enum FileType: String {
    case file
    case compress_file
    case folder
}

/// 在文件管理器页，发生动作事件
extension IMTracker.FileManage {
    struct Click {
        public static func close(extra: [AnyHashable: Any]) {
            var params: [AnyHashable: Any] = extra
            params["click"] = "close"
            params["target"] = "im_chat_main_view"
            Tracker.post(TeaEvent(Homeric.IM_CHAT_FILE_MANAGE_CLICK,
                                  params: params))
        }
        // 搜索
        static func search(extra: [AnyHashable: Any]) {
            var params: [AnyHashable: Any] = extra
            params["click"] = "search"
            params["target"] = "none"
            Tracker.post(TeaEvent(Homeric.IM_CHAT_FILE_LIST_CLICK,
                                  params: params))
        }

        // 切换视图
        static func changeViewType(extra: [AnyHashable: Any]) {
            var params: [AnyHashable: Any] = extra
            params["click"] = "change_view_type"
            params["target"] = "none"
            Tracker.post(TeaEvent(Homeric.IM_CHAT_FILE_LIST_CLICK,
                                  params: params))
        }
        // 点击单个文件
        static func singleFile(extra: [AnyHashable: Any],
                               fileType: FileType) {
            var params: [AnyHashable: Any] = extra
            params["click"] = "single_file"
            params["file_type"] = fileType.rawValue
            params["target"] = "none"
            Tracker.post(TeaEvent(Homeric.IM_CHAT_FILE_LIST_CLICK,
                                  params: params))
        }
        // 跳回至会话
        static func jumpToChat(extra: [AnyHashable: Any],
                               fileType: FileType) {
            var params: [AnyHashable: Any] = extra
            params["click"] = "jump_to_chat"
            params["file_type"] = fileType.rawValue
            params["target"] = "im_chat_main_view"
            Tracker.post(TeaEvent(Homeric.IM_CHAT_FILE_LIST_CLICK,
                                  params: params))
        }
        // 点击"更多"进入
        static func more(extra: [AnyHashable: Any],
                         fileType: FileType) {
            var params: [AnyHashable: Any] = extra
            params["click"] = "more"
            params["file_type"] = fileType.rawValue
            params["target"] = "im_chat_file_list_more_view"
            Tracker.post(TeaEvent(Homeric.IM_CHAT_FILE_LIST_CLICK,
                                  params: params))
        }
    }
}

// MARK: - 文件管理器更多页面 View & Click

extension IMTracker.FileManage {
    struct More {}
}

/// 文件管理器更多页面展示
extension IMTracker.FileManage.More {
    static func View(extra: [AnyHashable: Any], fileType: FileType) {
        var params = extra
        params["file_type"] = fileType.rawValue
        Tracker.post(TeaEvent(Homeric.IM_CHAT_FILE_MANAGE_MORE_VIEW,
                              params: params))
    }
}

/// 在文件管理器更多页，发生动作事件
extension IMTracker.FileManage.More {
    struct Click {
        // 转发副本
        static func forwardCopy(extra: [AnyHashable: Any], fileType: FileType) {
            var params: [AnyHashable: Any] = extra
            params["file_type"] = fileType.rawValue
            params["click"] = "forward"
            params["target"] = "none"
            Tracker.post(TeaEvent(Homeric.IM_CHAT_FILE_LIST_MORE_CLICK,
                                  params: params))
        }
        // 跳转至会话
        static func jumpToChat(extra: [AnyHashable: Any], fileType: FileType) {
            var params: [AnyHashable: Any] = extra
            params["file_type"] = fileType.rawValue
            params["click"] = "to_chat"
            params["target"] = "im_chat_main_view"
            Tracker.post(TeaEvent(Homeric.IM_CHAT_FILE_LIST_MORE_CLICK,
                                  params: params))
        }

        static func openWithOtherApp(extra: [AnyHashable: Any], fileType: FileType) {
            var params: [AnyHashable: Any] = extra
            params["file_type"] = fileType.rawValue
            params["click"] = "open_with_other_app"
            params["target"] = "none"
            Tracker.post(TeaEvent(Homeric.IM_CHAT_FILE_MANAGE_MORE_CLICK,
                                  params: params))
        }
    }
}
