//
//  DrivePDFViewModel.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2020/1/6.
//  

import Foundation
import SKUIKit
import RxSwift
import RxCocoa
import PDFKit
import SKCommon
import SKFoundation
import SpaceInterface

class DrivePDFViewModel: SKPDFViewModel {

    let originFileType: String
    var additionalStatisticParameters: [String: String]?

    // MARK: - VC Follow State
    // 负责处理 Follow 内容加载流程的事件
    weak var followAPIDelegate: DriveFollowAPIDelegate?
    // 负责处理 PDF 的状态变化事件
    weak var followContentDelegate: FollowableContentDelegate?
    // 同层 Follow 所在文档的挂载 mountToken
    var followMountToken: String?
    // 存储当前的state
    let pdfStateRelay = BehaviorRelay<State>(value: .default)
    // 存储演讲者的 state，用于计算相对位置
    let presenterStateRelay = BehaviorRelay<State?>(value: nil)
    // 接收来自 follow 的 state
    let pdfFollowStateSubject = PublishSubject<State>()
    // VCFollow 角色变化
    let followRoleChangeSubject = PublishSubject<FollowRole>()

    var pdfInlineAIAction: PublishRelay<DKPDFInlineAIAction>?

    // MARK: - Permission
    /// 复制权限变化
    let canCopyRelay: BehaviorRelay<Bool>

    /// 复制权限变更
    var canCopyUpdated: Driver<Bool> {
        return canCopyRelay.asDriver()
    }
    
    // copy controll
    let copyManager: DriveCopyMananger
    
    // MARK: - security copy
    private let enableCopySecurity: Bool
    private let canEditRelay: BehaviorRelay<Bool>
    var needSecurityCopyDriver: Driver<String?> {
        let encryptId = ClipboardManager.shared.getEncryptId(token: self.hostToken) ?? self.fileToken
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            return copyManager.monitorCopyPermission(token: encryptId, allowSecurityCopy: enableCopySecurity).map { token, _ in
                return token
            }
        } else {
            return Observable.combineLatest(self.canEditRelay, self.canCopyRelay)
                .map {[weak self] (canEdit, canCopy) in
                    guard let self = self else { return nil }
                    if canEdit && !canCopy && self.enableCopySecurity {
                        DocsLogger.driveInfo("need copy security")
                        return encryptId
                    } else {
                        DocsLogger.driveInfo("need copy security")
                        return nil
                    }
                }.asDriver(onErrorJustReturn: nil)
        }
    }
    
    var copyPermission: Observable<Bool> {
        let encryptId = ClipboardManager.shared.getEncryptId(token: self.hostToken) ?? self.fileToken
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            return copyManager.monitorCopyPermission(token: encryptId, allowSecurityCopy: enableCopySecurity).map { _, canCopy in
                return canCopy
            }.asObservable()
        } else {
            return copyManager.needSecurityCopyAndCopyEnable(token: encryptId, canEdity: self.canEditRelay, canCopy: self.canCopyRelay, enableSecurityCopy: enableCopySecurity).map { (_, canCopy) in
                return canCopy
            }.asObservable()
        }
    }

    /// 是否有复制权限
    var canCopy: Bool {
        return canCopyRelay.value
    }

    var fileToken: String?
    var hostToken: String? // 附件宿主token, 用于单文档复制保护
    
    // MyAI相关
    private(set) var initPageNumber: Int?
    let pageNumberChangedRelay: BehaviorRelay<Int>?
    
    
    /// 供 PDF VCFollow 下状态信号使用，便于刷新时重置
    var followStateDisposeBag = DisposeBag()

    init(fileURL: SKFilePath,
         hostToken: String?,
         canCopy: BehaviorRelay<Bool>,
         canEdit: BehaviorRelay<Bool>,
         config: Config,
         originFileType: String,
         fileToken: String?,
         enableCopySecurity: Bool = LKFeatureGating.securityCopyEnable,
         copyManager: DriveCopyMananger,
         pageNumer: Int?,
         pageNumberChangedReleay: BehaviorRelay<Int>?,
         pdfInlineAIAction: PublishRelay<DKPDFInlineAIAction>?) {
        canCopyRelay = canCopy
        canEditRelay = canEdit
        self.hostToken = hostToken
        self.copyManager = copyManager
        self.originFileType = originFileType
        self.fileToken = fileToken
        self.enableCopySecurity = enableCopySecurity
        self.pdfInlineAIAction = pdfInlineAIAction
        self.initPageNumber = pageNumer
        self.pageNumberChangedRelay = pageNumberChangedReleay
                
        super.init(fileURL: fileURL.pathURL, config: config)
    }
    
    deinit {
        DocsLogger.driveInfo("drive.pdf.state --- DrivePDFViewModel deinit")
    }

    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    func needCopyIntercept() -> DriveCopyMananger.InterceptCopyResult {
        return copyManager.interceptCopy(token: fileToken,
                                         canEdit: canEditRelay.value,
                                         canCopy: canCopy,
                                         enableSecurityCopy: enableCopySecurity)
    }

    func checkCopyPermission() -> DriveCopyMananger.DriveCopyResponse {
        return copyManager.checkCopyPermission(allowSecurityCopy: enableCopySecurity)
    }
}
