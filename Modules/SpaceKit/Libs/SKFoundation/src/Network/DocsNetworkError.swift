//  Created by weidong fu on 27/11/2017.

import Foundation
import SKResource

extension DocsNetworkError: CustomNSError {
    public var errorCode: Int {
        code.rawValue
    }

    public static var errorDomain: String {
        "docsNetworkError"
    }

    public var errorUserInfo: [String: Any] {
        ["code": code.rawValue, "msg": errorMsg]
    }
}

public struct DocsNetworkError: Error {
    public enum HTTPStatusCode: Int {
        
        /// HTTP Status Code，目前先放到这里，后续如果有冲突可以考虑放到其他位置，具体定义见https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
        ///
        case Continue = 100
        case RequestSucceed = 200
        case MovedPermanently = 301
        case MovedTemporarily = 302
        case NotModified = 304
        case BadRequest = 400
        case Unauthorized = 401
        case Forbidden = 403
        case NotFound = 404
        case InternalServerError = 500
        case NotImplemented = 501
        case BadGateway = 502
        case ServiceUnavailable = 503
        

    }
    public enum Code: Int {
        // MARK: - 0 ~ 999

        case success = 0
        case fail = 1
        case invalidParams = 2
        case notFound = 3

        /// 无权限
        case forbidden = 4
        case loginRequired = 5
        /// 文件夹被删除
        case folderDeleted = 7
        case featureTurnOff = 10 /// 无权限（需要管理员打开该计费功能）

        case parseError = 110
        case invalidData = 111
        case tooFrequent = 429
        case coldDocument = 600 /// 混合部署冷文档操作（目前包括，clientvar获取，创建副本）
        


        // MARK: - 1000 ~ 999999

        /// 本体被删除
        case entityDeleted = 1002
        case networkError = 1007

        case cacPermissonBlocked = 2002 // cac管控 权限业务错误码

        
        case workspaceExceedLimited = 4001 // 创建副本跨域
        
        case copyFileError = 4007 // 创建副本跨域
        /// 数据迁移期间，内容被锁定
        case dataLockDuringUpgrade = 4202

        /// 用户已离职
        case userResign = 4203
        /// 没有满足权限的审批人（移动到文档审批）
        case noProperReviewer = 4204

        case reachMetionNotifyLimit = 9100 /// 反馈文档过期操作限频

        /// 允许申诉
        case appealEnable = 10000
        /// 申诉中
        case appealing = 10001

        case templateNotPermission = 10002 /// 缺少模板权限

        /// 编辑时间小于上次申诉时间
        case timeShort = 10003

        /// 当日申诉到达上限
        case dailyLimit = 10004

        /// 申诉到达总上限
        case allLimit = 10005

        case templateLimited = 10006 /// 模板达到上限

        /// 存在未删除的封禁版本，禁止申诉；与「模板达到上限」错误吗冲突
        public static var forbidLimit: Self { return .templateDeleted }

        case templateDeleted = 10007 /// 模板已删除

        /// 上次申诉被驳回，可以重新发起申诉
        case appealRejected = 10008

        /// 机器审核不过
        case auditError = 10009

        /// 人工审核不过 或者被举报
        case reportError = 10013

        /// 高管屏蔽
        case executivesBlock = 10015
        /// 需要输入密码，属于无权限的一种
        case passwordRequired = 10016

        /// 密码错误
        case wrongPassword = 10017
        /// 错误达上限
        case errorReachedLimit = 10018
        /// 被动屏蔽
        case passiveBlock = 10022

        /// 收紧页面权限时，需同时调整子页面权限
        case restrictPageError = 10033

        case permissionLockDuringUpgrade = 10040
        
        /// 同步块请求源文档token错误
        case syncedBlockError = 10051

        /// 未打开对外分享就设置自定义密码
        case customPasswordError = 10052

        /// 下游服务端错误
        case serviceError = 10800

        case createLimited = 11001

        /// rust上传文件超限错误码
        case uploadLimited = 13001
        
        /// 保存文档密码失败
        case saveDocsPasswordFailed = 14005

        /// 密级升级，不应该创建审批
        case securityUpgradeShouldNotApproval = 16001

        /// 撤回失败
        case securityWithdrawApprovalFailed = 16002

        /// 撤回成功，创建失败
        case securityCreateApprovalFailed = 16003

        /// 密级降级，应该走审批
        case securityDowngradeRequiresApproval = 17001

        // MARK: - 999999 以上

        /// 文档已删除
        case resourceDeleted = 4_000_007
        /// 创建副本中
        case copyingFile = 4_000_080
        /// 文档无访问权限
        case docsForbidden = 4_030_004

        /// 缺少使用自定义模板的权限，但是还在协作者列表中，提示用户向owner申请权限
        case templateCollaboratorNotPermission = 210_020_001

        /// 管理员的安全设置，无法使用模板
        case templateUnableToPreviewSecurityReason = 210_020_002

        /// 用户容量超限
        ///
        /// drive保存到云盘用户容量超限
        case driveUserStorageLimited = 90_001_061
        /// rust上传用户容量超限错误码
        case rustUserUploadLimited = 90_003_061
        /// 模板创建，创建副本，保存为模板用户容量超限
        case spaceUserStorageLimited = 900_011_002
        /// 保存到云空间，创建副本文件大小超过上限
        case spaceFileSizeLimited = 90_001_043
        /// 文件秘钥被删除
        case secretKeyDeleted = 900_021_001
        /// 数据迁移中，内容被锁定
        case dataLockedForMigration = 900_004_230
        /// 合规-同品牌的跨租户跨Geo
        case unavailableForCrossTenantGeo = 900_004_510
        /// 合规-跨品牌不允许
        case unavailableForCrossBrand = 900_004_511
        /// 内部租户DLP检测中
        case dlpSameTenatDetcting = 900_099_001
        /// 外部租户DLP检测中
        case dlpExternalDetcting = 900_099_002
        /// 内部租户DLP拦截
        case dlpSameTenatSensitive = 900_099_003
        /// 外部租户dlp拦截
        case dlpExternalSensitive = 900_099_004

        /// cac管控 删除业务错误码
        case cacDeleteBlocked = 900_099_011
        /// TNS 跨租户预览管控
        case tnsCrossBrandBlocked = 900_099_021
        /// 发起申请移动到，申请处理人没权限
        case requestMoveToNoPermission = 920_004_105
        /// 发起申请 MoveTo ，已达到申请上限
        case requestMoveToOutOfLimit = 920_004_106
        /// 不允许发起申请移动到（高管限制）
        case requestMoveToBanForSeniorExecutive = 920_004_107
        /// 文档 owner 已离职
        case requestMoveToOwnerResign = 920_003_005

        /// 适合 UI 展示的默认报错文案，没有配置则为 nil
        public var errorMessage: String? {
            switch self {
            case .success:
                return BundleI18n.SKResource.Doc_Normal_Success
            case .fail:
                return BundleI18n.SKResource.Doc_AppUpdate_FailRetry
            case .invalidParams:
                return BundleI18n.SKResource.Doc_AppUpdate_URLOrParameterNotCorrect
            case .notFound:
                return BundleI18n.SKResource.Doc_AppUpdate_FailRetry
            case .forbidden:
                return BundleI18n.SKResource.Doc_Facade_OperateFailedNoPermission
            case .loginRequired:
                return BundleI18n.SKResource.Doc_Normal_Authorized + BundleI18n.SKResource.Doc_AppUpdate_FailRetry
            case .parseError, .invalidData:
                return BundleI18n.SKResource.Doc_Normal_PhraseData + BundleI18n.SKResource.Doc_AppUpdate_FailRetry
            case .auditError:
                return BundleI18n.SKResource.Doc_Review_Fail_Rename
            case .reportError:
                return BundleI18n.SKResource.Drive_Drive_DiscardedFileHint()
            case .copyingFile:
                return BundleI18n.SKResource.CreationMobile_Docs_duplicate_inProgress_toast
            case .dataLockDuringUpgrade, .permissionLockDuringUpgrade:
                return BundleI18n.SKResource.CreationMobile_DataUpgrade_Locked_toast
            case .secretKeyDeleted:
                return BundleI18n.SKResource.CreationDoc_Docs_KeyInvalidCanNotOperate
            case .dataLockedForMigration:
                return BundleI18n.SKResource.CreationMobile_MultiGeo_900004230
            case .unavailableForCrossTenantGeo:
                return BundleI18n.SKResource.CreationMobile_MultiGeo_900004510
            case .unavailableForCrossBrand:
                return BundleI18n.SKResource.CreationMobile_MultiGeo_900004511
            case .restrictPageError:
                return BundleI18n.SKResource.LarkCCM_Wiki_LinkShare_RestrictPageFail_Toast
            default:
                return nil
            }
        }
    }

    public let code: DocsNetworkError.Code
    private func message(extraStr _: String? = nil) -> String {
        code.errorMessage ?? ""
    }

    /// 错误文案，支持根据 Code 码配置 && 主动 set
    public private(set) var errorMsg: String = ""

    public init?(_ int: Int?, extraStr: String? = nil) {
        guard let int = int,
              let code = DocsNetworkError.Code(rawValue: int),
              code != .success
        else {
            return nil
        }
        self.code = code
        errorMsg = message(extraStr: extraStr)
    }

    private init(code: Code, extraStr: String? = nil) {
        self.code = code
        errorMsg = message(extraStr: extraStr)
    }

    /// 某些接口可能文案从接口返回，这里支持自定义
    public mutating func set(msg: String?) {
        // fix [DM-10107] IOS对sheet表格重命名为敏感字符后，出现英文提示
        // 根据Code能匹配到相应的errorMsg，则不使用后端返回的errorMsg
        guard errorMsg.isEmpty, let msg = msg else { return }
        errorMsg = msg
    }

    /// 判断错误码
    public static func error(_ err: Error?, equalTo code: DocsNetworkError.Code) -> Bool {
        if let realError = err as? DocsNetworkError, realError.code == code {
            return true
        }
        return false
    }

    public static func isSuccess(_ code: Int?) -> Bool {
        guard let code = code else {
            return false
        }
        return code == DocsNetworkError.Code.success.rawValue
    }
}

extension DocsNetworkError: LocalizedError {
    public var errorDescription: String? { return errorMsg }
    public var failureReason: String? { return errorMsg }
    public var recoverySuggestion: String? { return "请检查" }
    public var helpAnchor: String? { return "升级最新版本" }
}

public extension DocsNetworkError {
    static let parse = DocsNetworkError(code: .parseError)
    static let invalidData = DocsNetworkError(code: .invalidData)
    static let invalidParams = DocsNetworkError(code: .invalidParams)
    static let loginRequired = DocsNetworkError(code: .loginRequired)
    static let createLimited = DocsNetworkError(code: .createLimited)
    static let auditError = DocsNetworkError(code: .auditError)
    static let reportError = DocsNetworkError(code: .reportError)
    static let passwordRequired = DocsNetworkError(code: .passwordRequired)
    static let wrongPassword = DocsNetworkError(code: .wrongPassword)
    static let errorReachedLimit = DocsNetworkError(code: .errorReachedLimit)
    static let forbidden = DocsNetworkError(code: .forbidden)
    static let secretKeyDeleted = DocsNetworkError(code: .secretKeyDeleted)
    static let entityDeleted = DocsNetworkError(code: .entityDeleted)
}

/// DocsNetworkError as NSError code 失真问题
public extension DocsNetworkError {
    func convertToNSError() -> NSError {
        return NSError(domain: "docsNetworkError", code: code.rawValue, userInfo: ["code": code.rawValue, "msg": errorMsg])
    }
}

// MARK: - - 权限相关错误

public struct PermissionError: Error {
    /// 获取申诉结果，只有当「申诉状态」为成功时，才可以获取到申诉结果
    public enum ComplaintResultCode: Int {
        /// 申诉中
        case inProgress = 0

        /// 申诉通过
        case pass = 1

        /// 申诉出错
        case noPass = 2
    }
}
