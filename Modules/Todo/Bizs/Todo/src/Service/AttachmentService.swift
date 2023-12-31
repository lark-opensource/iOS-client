//
//  AttachmentService.swift
//  Todo
//
//  Created by baiyantao on 2022/12/27.
//

import Foundation
import RxSwift
import RxCocoa
import TodoInterface

/// 集中管理附件相关的逻辑，包含上传、预览等能力
protocol AttachmentService: AnyObject {
    var updateNoti: PublishRelay<(scene: AttachmentScene, info: TaskUploadInfo)> { get }

    func upload(scene: AttachmentScene, fileInfo: TaskFileInfo)
    func resumeUpload(scene: AttachmentScene, key: String)
    func cancelUpload(key: String, onSuccess: @escaping () -> Void, onError: @escaping (Error) -> Void)
    func getInfos(by scene: AttachmentScene) -> [AttachmentInfo]
    func batchRemoveFromDic(_ scene: AttachmentScene, _ infos: [AttachmentInfo])
    func selectLocalFiles(
        vc: BaseViewController,
        sourceView: UIView,
        sourceRect: CGRect,
        enableCount: Int,
        callbacks: SelectLocalFilesCallbacks
    )
}

typealias AttachmentInfo = (fileInfo: TaskFileInfo, uploadInfo: TaskUploadInfo)

enum AttachmentScene: Hashable {
    case taskCreate
    case taskEdit(taskGuid: String)
    case comment(taskGuid: String)
}

extension AttachmentScene: LogConvertible {
    var logInfo: String {
        switch self {
        case .taskCreate:
            return "create"
        case .taskEdit(let guid):
            return "task edit, guid: \(guid)"
        case .comment(let guid):
            return "comment, guid: \(guid)"
        }
    }
}

struct SelectLocalFilesCallbacks {
    var selectCallback: (([String]) -> Void)?
    var finishCallback: (([(String, TaskFileInfo?)]) -> Void)?
    var cancelCallback: (() -> Void)?
}
