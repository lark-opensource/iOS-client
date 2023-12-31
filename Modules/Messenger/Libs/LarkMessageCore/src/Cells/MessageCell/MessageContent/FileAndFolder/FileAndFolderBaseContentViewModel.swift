//
//  FileAndFolderBaseContentViewModel.swift
//  LarkMessageCore
//
//  Created by 赵家琛 on 2021/4/15.
//

import UIKit
import Foundation
import LarkModel
import LarkContainer
import LarkAccountInterface
import LarkSDKInterface
import LarkSendMessage
import LarkMessengerInterface
import LarkMessageBase
import RxSwift
import RxRelay
import LarkCore
import LarkSetting
import LKCommonsLogging
import UniverseDesignToast
import RustPB
import LarkAlertController
import LarkUIKit

public protocol FileAndFolderContentContext: PageContext {
    func progressValue(key: String) -> Observable<Progress>
    //速率
    func rateValue(key: String) -> Observable<Int64>
    var scene: ContextScene { get }
    var downloadFileScene: RustPB.Media_V1_DownloadFileScene? { get }
    func checkPermissionPreview(chat: Chat, message: Message) -> (Bool, ValidateResult?)
    func checkPreviewAndReceiveAuthority(chat: Chat, message: Message) -> PermissionDisplayState
    func handlerPermissionPreviewOrReceiveError(receiveAuthResult: DynamicAuthorityEnum?,
                                                previewAuthResult: ValidateResult?,
                                                resourceType: SecurityControlResourceType)
    var fileAPI: SecurityFileAPI? { get }
    var currentChatterId: String { get }
    var fileUtilService: FileUtilService? { get }
    var fileMessageInfoService: FileMessageInfoService? { get }
    var chatSecurityService: ChatSecurityControlService? { get }
}

extension PageContext: FileAndFolderContentContext {
    public var fileAPI: LarkSDKInterface.SecurityFileAPI? {
        return try? resolver.resolve(assert: SecurityFileAPI.self, cache: true)
    }

    //速率
    public func rateValue(key: String) -> Observable<Int64> {
        return (try? resolver.resolve(assert: ProgressService.self, cache: true))?
            .rateValue(key: key) ?? .empty()
    }

    public var fileUtilService: FileUtilService? {
        return try? resolver.resolve(assert: FileUtilService.self)
    }

    public var fileMessageInfoService: FileMessageInfoService? {
        return try? resolver.resolve(assert: FileMessageInfoService.self)
    }

    public var chatSecurityService: ChatSecurityControlService? {
        return try? resolver.resolve(assert: ChatSecurityControlService.self)
    }
}

public struct FileAndFolderConfig {
    public let showBottomBorder: Bool?
    // 消息链接化场景使用内存中的chat，否则无权限场景可能拉超时
    public var useLocalChat: Bool
    public var canViewInChat: Bool
    public var canForward: Bool
    public var canSearch: Bool
    public var canSaveToDrive: Bool
    // Office文件类型的鉴权涉及其他业务，消息链接化场景暂时屏蔽Office文件类型的点击事件（三端对齐）
    public var canOfficeClick: Bool

    public init(showBottomBorder: Bool? = nil,
                useLocalChat: Bool = false,
                canViewInChat: Bool = true,
                canForward: Bool = true,
                canSearch: Bool = true,
                canSaveToDrive: Bool = true,
                canOfficeClick: Bool = true) {
        self.showBottomBorder = showBottomBorder
        self.useLocalChat = useLocalChat
        self.canViewInChat = canViewInChat
        self.canForward = canForward
        self.canSearch = canSearch
        self.canSaveToDrive = canSaveToDrive
        self.canOfficeClick = canOfficeClick
    }
}

private let logger = Logger.log(NSObject(), category: "LarkMessageCore.cell.FileAndFolderBaseContentViewModel")

// 文件/文件夹基类，需被子类继承使用
public class FileAndFolderBaseContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: FileAndFolderContentContext>: NewAuthenticationMessageSubViewModel<M, D, C> {

    let disposeBag = DisposeBag()

    public init(metaModel: M, metaModelDependency: D, context: C, fileAndFolderConfig: FileAndFolderConfig = .init()) {
        self.fileAndFolderConfig = fileAndFolderConfig
        super.init(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context)
    }

    // MARK: need be override
    var key: String {
        assertionFailure("need be override")
        return ""
    }

    var name: String {
        assertionFailure("need be override")
        return ""
    }

    var sizeValue: Int64 {
        assertionFailure("need be override")
        return 0
    }

    var lastEditInfo: (time: Int64, userName: String)? {
        assertionFailure("need be override")
        return nil
    }

    var fileSource: RustPB.Basic_V1_File.Source {
        assertionFailure("need be override")
        return .unknown
    }

    public var icon: UIImage {
        assertionFailure("need be override")
        return UIImage()
    }

    // MARK: Public Property
    public var size: String {
        // 局域网文件/文件夹不显示size
        if isLan {
            return ""
        }
        // 枚举文件/文件夹状态
        switch message.fileDeletedStatus {
            // 正常，未被删除
        case .normal:
            break
        case .recalled:
            return BundleI18n.LarkMessageCore.Lark_Legacy_FileStatusSourceDelete
            // 被删除，管理员可恢复
        case .recoverable:
            return BundleI18n.LarkMessageCore.Lark_ChatFileStorage_ChatFileNotFoundDialogWithin90Days
            // 被删除，不可恢复
        case .unrecoverable:
            return BundleI18n.LarkMessageCore.Lark_ChatFileStorage_ChatFileNotFoundDialogOver90Days
        case .freedUp:
            return BundleI18n.LarkMessageCore.Lark_IM_ViewOrDownloadFile_FileDeleted_Text
        @unknown default:
            assertionFailure("unknown enum")
        }

        return self.sizeStringFromSize(sizeValue)
    }

    //文件传输速率
    public var rate: Int64 {
        return 0
    }

    public var rateText: String {
        //当速率大于0的时候才显示
        if rate > 0 {
            return " " + BundleI18n.LarkMessageCore.Lark_Legacy_Uploading + " " + String(format: "%.1f", Double(rate) / Double((1024 * 1024))) + "MB/s"
        } else {
            return ""
        }
    }

    public var lastEditInfoString: String? {
        guard self.context.getDynamicFeatureGating("messenger.message.online_edit_excel"),                 //excel支持在线编辑的fg
              !self.context.getDynamicFeatureGating("messenger.message.online_edit_excel_hide_last_edit"),  //excel支持在线编辑时，把编辑信息隐藏掉的fg
              let (time, userName) = lastEditInfo else {
            return nil
        }
        let timeString = (time / 1000).lf.cacheFormat("editFile", formater: {
            $0.lf.formatedTime_v2(accurateToSecond: true)
        })
        //当前size、rate、lastEditInfo都在同一个label里，所以前面带个空格
        return " \(BundleI18n.LarkMessageCore.Lark_IM_SheetsLastUpdated_Text(timeString)) \(userName)"
    }

    public var statusText: String {
        // 局域网文件/文件夹显示特定的文案
        if isLan {
            return message.isMeSend(userId: currentChatterId) ? BundleI18n.LarkMessageCore.Lark_Message_file_lan_sendreceived :
                BundleI18n.LarkMessageCore.Lark_Message_file_lan_mobilereceived
        }
        let isNutStore = (fileSource == .nutStore)
        let text = isNutStore ? BundleI18n.LarkMessageCore.Lark_Legacy_FileFromDrive : ""
        switch message.fileDeletedStatus {
            // 正常，未被删除
        case .normal:
            return text
        case .recalled, .recoverable, .unrecoverable, .freedUp:
            return ""
        @unknown default:
            assertionFailure("unknown enum")
            return ""
        }
    }

    public var progress: Float {
        return -1
    }

    // 是否是局域网文件/文件夹
    public var isLan: Bool {
        return fileSource == .lanTrans
    }
    // 是否有预览权限
    public var permissionPreview: (Bool, ValidateResult?) {
        return (true, nil)
    }

    public var progressAnimated: Bool {
        return false
    }

    private lazy var currentChatterId: String = {
        return self.context.currentChatterId
    }()

    // MARK: Private Method
    /// 删除末尾的0
    private func deleteLastZero(str: String) -> String {
        let splitStrs = str.split(separator: ".")
        // 如果没有小数位/入参str不合理，不进行处理
        if splitStrs.count != 2 { return str }

        var folatStr = splitStrs[1]
        // 去掉folatStr末尾的0，folatStr全为0则folatStr会变为""
        while !folatStr.isEmpty, folatStr.last == "0" {
            folatStr.removeLast()
        }

        // 如果folatStr变为空，则说明小数位全为0，则只需要展示整数部分
        if folatStr.isEmpty { return String(splitStrs[0]) }

        return splitStrs[0] + "." + folatStr
    }

    /// 把size转成 "296.5MB" 这种格式
    private func sizeStringFromSize(_ size: Int64) -> String {
        let tokens = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"]

        var size: Float = Float(size)
        var mulitiplyFactor = 0
        while size > 1024 {
            size /= 1024
            mulitiplyFactor += 1
        }
        if mulitiplyFactor < tokens.count {
            return deleteLastZero(str: String(format: "%.2f", size)) + " " + tokens[mulitiplyFactor]
        }
        return deleteLastZero(str: String(format: "%.2f", size))
    }

    // MARK: UI
    public override var contentConfig: ContentConfig? {
        var contentConfig = ContentConfig(
            hasMargin: false,
            backgroundStyle: .white,
            maskToBounds: true,
            supportMutiSelect: true,
            hasPaddingBottom: false,
            hasBorder: true
        )
        contentConfig.isCard = true
        return contentConfig
    }

    public var contentPreferMaxWidth: CGFloat {
        return metaModelDependency.getContentPreferMaxWidth(message)
    }

    public var showTopBorder: Bool {
        return !message.rootId.isEmpty
    }

    public var showBottomBorder: Bool {
        if let showBottomBorder = self.fileAndFolderConfig.showBottomBorder {
            return showBottomBorder
        }
        if (self.context.scene == .newChat || self.context.scene == .mergeForwardDetail), message.showInThreadModeStyle {
            return false
        }
        return !message.reactions.isEmpty
    }

    public var hasPaddingTop: Bool {
        return !message.rootId.isEmpty
    }

    public let fileAndFolderConfig: FileAndFolderConfig

    public var useLocalChat: Bool {
        return fileAndFolderConfig.useLocalChat
    }

    public var canViewInChat: Bool {
        return fileAndFolderConfig.canViewInChat
    }

    public var canForward: Bool {
        return fileAndFolderConfig.canForward
    }

    public var canSearch: Bool {
        return fileAndFolderConfig.canSearch
    }

    public var canSaveToDrive: Bool {
        return fileAndFolderConfig.canSaveToDrive
    }

    public var canOfficeClick: Bool {
        return fileAndFolderConfig.canOfficeClick
    }
}
