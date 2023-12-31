//
//  File.swift
//  SpaceKit
//
//  Created by xurunkang on 2019/3/25.
// swiftlint:disable file_length

import Foundation
import EENavigator
import SKCommon
import SKUIKit
import SKFoundation
import SKResource
import UniverseDesignToast
import LarkEmotionKeyboard
import SpaceInterface

class DriveCommentAdapter {
    var permission: CommentPermission
    var permissionService: UserPermissionService?
    // drive是否有copy权限
    private var canCopy = false {
        didSet {
            feedPanelViewController?.reloadTableViewData()
            if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
                // FG 开时，CAC 已经算在 canCopy 里了
                feedPanelViewController?.setCaptureAllowed(canCopy)
            } else {
                let newCanCopy = canCopy && CCMSecurityPolicyService.syncValidate(entityOperate: .ccmCopy, fileBizDomain: .ccm, docType: .file, token: nil).allow
                feedPanelViewController?.setCaptureAllowed(newCanCopy)
            }
        }
    }
    
    // drive是否有查看权限
    private var canRead = true {
        didSet {
            if oldValue == true, canRead == false { // 由'可阅读'变为'不可阅读',需要关掉评论&通知
                feedPanelViewController?.dismissPanel(animated: false)
            }
        }
    }
    
    // drive是否有预览权限
    private var canPreviewProvider: () -> Bool
    
    /// 评论过滤器
    /// 返回值：
    ///     RNCommentData：过滤后的RNCommentData
    ///     [String]：局部评论(有选区的评论)commentId数组
    var commentFilter: ((RNCommentData) -> (RNCommentData, [String])) = { ($0, []) }
    var commentVCDismissed: (() -> Void)?
    var commentVCDidSwitchToPage: ((Int, String) -> Void)?
    // 处理点击评论中的链接，返回 true 说明需要拦截，adapter 不做处理；返回 false 说明不做特殊处理，adapter 会直接打开链接
    var commentLinkInterceptor: ((URL) -> Bool)?

    var messageFilter: ((Any) -> (data: [String: Any], messages: [NewMessage]))?
    var messageDidRead: (([String]) -> Void)?
    var messageDidClickComment: ((String, FeedMessageType) -> Void)?
    var messageWillDismiss: (() -> Void)?
    
    var commentUpdate: ((CommentData, [String]) -> Void)?

    // 由于发送评论时先通过updateComment回调全量，再走resonse返回单条，先保存，等创建commentVC的时候再带过去
    var latestRNCommentData: RNCommentData?
    
    weak var followAPIDelegate: SpaceFollowAPIDelegate?

    private(set) var rnCommentDataManager: RNCommentDataManager
    private(set) var rnCommonDataManager: RNCommonDataManager
    
    private(set) weak var feedPanelViewController: FeedPanelViewController?
    
    var feedVC: FeedPanelViewControllerType? {
        return feedPanelViewController
    }

    private(set) var currentEditCommentItem: CommentItem? // 当前编辑的 item

    private(set) var fileType: DocsType
    private(set) var fileToken: String
    private(set) var docsInfo: DocsInfo

    private(set) var countChangeClosure: ((Int) -> Void)?
    private var retainClosure: (() -> Void)?
    weak var hostController: UIViewController?
    // 评论vc，点击back按钮，设置此标志位
    var isClickCommentVCBackButton = false

    var canManageMetaGetter: (() -> Bool)?
    var canEditGetter: (() -> Bool)?

    let decodeQueue = DispatchQueue(label: "drive.feed.decode")

    init(docsInfo: DocsInfo,
         permission: CommentPermission,
         permissionService: UserPermissionService?,
         canCopy: Bool, canRead: Bool, canPreviewProvider: @escaping () -> Bool) {

        self.fileType = docsInfo.type
        self.fileToken = docsInfo.objToken
        self.permission = permission
        self.permissionService = permissionService
        self.canCopy = canCopy
        self.canRead = canRead
        self.canPreviewProvider = canPreviewProvider
        self.docsInfo = docsInfo

        self.rnCommonDataManager = RNCommonDataManager(fileToken: fileToken, type: fileType.rawValue)

        self.rnCommentDataManager = RNCommentDataManager(fileToken: fileToken, type: fileType.rawValue)
        self.rnCommentDataManager.needEndSync = false
        self.rnCommentDataManager.beginSync()
        self.rnCommentDataManager.delegate = self
    }

    deinit {
        rnCommentDataManager.endSync()
    }

    // 发送新的评论 V3
    func createNewCommentV3(_ comment: MountComment, extranInfo: [String: Any]? = nil, callback: @escaping (RNCommentData) -> Void) {
        rnCommentDataManager.publishCommentV2(comment: comment, extranInfo: extranInfo) { [weak self] response in
            if let code = response.code, code == 0 {
                let res = self?.latestRNCommentData ?? response
                res.currentCommentID = response.currentCommentID
                self?.handelPublishData(res, callback: callback)
            } else {
                self?.showFailToast(response.code)
            }
        }
    }

    private func showFailToast(_ code: Int?) {
        guard let hostWindow = hostController?.view.window else {
            return
        }
        if code == DocsNetworkError.Code.reportError.rawValue || code == DocsNetworkError.Code.auditError.rawValue {
            UDToast.showFailure(with: BundleI18n.SKResource.Doc_Review_Fail_Notify_Member(), on: hostWindow)
        } else {
            UDToast.showFailure(with: BundleI18n.SKResource.Doc_Doc_CommentSendFailed, on: hostWindow)
        }
    }

    // Fetch Comment
    func fetchCommentCount() {
        rnCommentDataManager.fetchComment { [weak self] (response) in
            guard let self = self else { return }
            let (commentData, ids) = self.constructComment(response)
            self.commentUpdate?(commentData, ids)
            self.countChangeClosure?(commentData.comments.count)
        }
    }

    // 监听评论数字实时改变
    func observeCommentCount(_ countChangeClosure: @escaping (Int) -> Void) {
        self.countChangeClosure = countChangeClosure

        // 主动拉一次评论数字
        fetchCommentCount()
    }

    // For Extension
    func updateCommentViewController(_ response: RNCommentData) {
        _updateCommentVC(response, needFilter: true)
    }
    
    /// 更新CommentViewController的数据，并传递局部评论commentId数组
    func updateCommentViewControllerNoFilter(_ response: RNCommentData, partCommentIds: [String]) {
        _updateCommentVC(response, needFilter: false)
    }
    
    private func _updateCommentVC(_ response: RNCommentData, needFilter: Bool) {
        // 1. 构建评论数据
        let constructResult = constructComment(response, needFilter: needFilter)
        let commentData = constructResult.0

        // 2. 更新评论数字
        countChangeClosure?(commentData.comments.count)
        
        commentUpdate?(commentData, constructResult.1)
    }

    func disposeCommentViewController() {
//        if let presentedVC = commentViewController?.presentedViewController, presentedVC.view.window != nil {
//            // commentViewController上面弹了一个二次确认的弹框时，要先dismiss掉
//            presentedVC.dismiss(animated: false, completion: { [weak self] in
//                self?.commentViewController?.dismiss(animated: true, completion: nil)
//            })
//        } else {
//            commentViewController?.dismiss(animated: true, completion: nil)
//        }
    }

    func update(_ docsInfo: DocsInfo, permission: CommentPermission, canCopy: Bool, canRead: Bool?) {
        self.docsInfo = docsInfo
        self.fileType = docsInfo.type
        self.permission = permission
        self.canCopy = canCopy
        if let can_read = canRead {
            self.canRead = can_read
        }

        self.rnCommentDataManager.update(fileType.rawValue)
    }
}

extension DriveCommentAdapter: CommentDataDelegate {
    func didReceiveUpdateFeedData(response: Any) {
        DocsLogger.driveInfo("DriveCommentAdapter didReceiveUpdateFeedData")
        updateMessageController(response, isRecieved: true)
    }

    func didReceiveCommentData(response: RNCommentData, eventType: RNCommentDataManager.CommentReceiveOperation) {
        latestRNCommentData = response
        updateCommentViewController(response)
    }
}

private extension DriveCommentAdapter {

    /// 不知道有什么用，只是用来接收数据？
    private func handelPublishData(_ response: RNCommentData, callback: @escaping (RNCommentData) -> Void ) {
        let constructResult = constructComment(response)
        let commentData = constructResult.0
        callback(response)

        self.countChangeClosure?(commentData.comments.count)
    }
    
    // needFilter为false时，调用方不关心返回值中的[String]
    public func constructComment(_ rnCommentData: RNCommentData, needFilter: Bool = true) -> (CommentData, [String]) {
        
        let new_rnCommentData: RNCommentData
        let partCommentIds: [String]
        if needFilter {
            let filterResult = commentFilter(rnCommentData)
            new_rnCommentData = filterResult.0
            partCommentIds = filterResult.1
        } else {
            new_rnCommentData = rnCommentData
            partCommentIds = []
        }

        // 1. 处理原始数据
        let comments = new_rnCommentData.comments

        // 2. 拼接数据
        // 2.1 暂时处理 docs info 的问题
        let docsInfo = DocsInfo(type: fileType, objToken: fileToken)
        // 2.2 暂时处理权限问题

        // 2.3 处理页数
        var currentPage:Int?
        if let currentCommentID = new_rnCommentData.currentCommentID, let page = comments.firstIndex(where: { $0.commentID == currentCommentID }) {
            currentPage = page
        }

        let commentData = CommentData(comments: comments, currentPage: currentPage, style: .normal, docsInfo: docsInfo, nPercentScreenHeight: nil, commentType: .card, commentPermission: permission)
        let canManage = self.canManageMetaGetter?() ?? false
        let canEdit = self.canEditGetter?() ?? false
        for comment in commentData.comments {
            CommentConstructor.updatePermission(comment: comment, canManageDocs: canManage, canEdit: canEdit)
        }
        return (commentData, partCommentIds)
    }
}

// message
extension DriveCommentAdapter {
    func updateMessageController(_ response: Any, isRecieved: Bool) {
        newMessageHandler(response)
    }
    
    func newMessageHandler(_ response: Any, filterCompletion: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            let result = self.messageFilter?(response)
            if let filteredData = result?.data {
                self.feedPanelViewController?.udpate(param: filteredData)
            }
            filterCompletion?()
        }

    }
    
    func constructMessageViewController(_ feedFromInfo: FeedFromInfo?) -> DraggableViewController {
        let from = feedFromInfo ?? FeedFromInfo()
        from.record(.openPanel)
        let vc = FeedPanelViewController(api: self, from: from, docsInfo: self.docsInfo)
        vc.permissionDataSource = self
        self.feedPanelViewController = vc
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            // FG 开时，CAC 已经算在 canCopy 里了
            vc.setCaptureAllowed(canCopy)
        } else {
            vc.setCaptureAllowed(canCopy && CCMSecurityPolicyService.syncValidate(entityOperate: .ccmCopy, fileBizDomain: .ccm, docType: .file, token: nil).allow)
        }
        return vc
    }

    func fetchMessageData() {
        DocsLogger.driveInfo("🐦comment：open panel to fetch info")
        rnCommentDataManager.fetchFeedData(docInfo: docsInfo) { (response) in
            self.updateMessageController(response, isRecieved: false)
        }
    }
}


// MARK: - CCMCopyPermissionDataSource
extension DriveCommentAdapter: CCMCopyPermissionDataSource {
    func getCopyPermissionService() -> UserPermissionService? {
        permissionService
    }

    public func ownerAllowCopy() -> Bool {
        return self.canCopy
    }
    
    func canPreview() -> Bool {
        canPreviewProvider()
    }
}
