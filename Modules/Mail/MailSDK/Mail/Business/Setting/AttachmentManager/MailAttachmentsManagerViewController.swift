//
//  MailAttachmentsManagerViewController.swift
//  MailSDK
//
//  Created by ByteDance on 2023/4/19.
//

import Foundation
import LarkUIKit
import Reachability
import LKCommonsLogging
import RxSwift
import Homeric
import LarkAlertController
import RustPB
import ServerPB
import EENavigator
import LarkLocalizations
import LarkFoundation
import ESPullToRefresh
import RxRelay
import LarkGuideUI
import LarkInteraction
import LarkTraitCollection
import LarkSplitViewController
import LarkAppLinkSDK
import LarkSwipeCellKit
import UniverseDesignIcon
import UniverseDesignShadow
import UniverseDesignToast
import AnimatedTabBar
import LarkCache

private typealias mailAttachmentsConst = MailAttachmentsControllerConst
struct MailAttachmentsControllerConst {
    static let CellHeight: CGFloat = 68
}

class MailAttachmentsManagerViewController:MailBaseViewController,
                                            UITableViewDelegate,
                                            UITableViewDataSource,
                                            MailAttachmentsListCellDelegate,
                                            AttachmentslLongPressDelegate {
    let accountContext: MailAccountContext
    let accountID: String
    var viewModel: MailAttachmentsViewModel
    static let logger = Logger.log(MailAttachmentsManagerViewController.self, category: "Module.MailAttachmentsManagerViewController")
    var disposeBag = DisposeBag()
    lazy var tableView: UITableView = self.makeTabelView()
    let sortedView = UIView(frame: .zero)
    let hasChosenFile = Bool() // 有已选择文件
    lazy var sortedBtn: UIButton = self.makeSortedBtn()
    lazy var memmoryLabel: UILabel = self.makeMemmoryLabel(isSeleted: false, fileNum: 0, capacity: FileSizeHelper.memoryFormat(UInt64(0), useAbbrByte: true, spaceBeforeUnit: true))
    var edgePanGesture = UIScreenEdgePanGestureRecognizer()
    var status: MailHomeEmptyCell.EmptyCellStatus = .emptyAttachment
    lazy var attachmentPreviewRouter = AttachmentPreviewRouter(accountContext: accountContext, source: .attachMentManager)
    weak var navbarBridge: MailNavBarBridge?
    var previewIndex: Int
    // Refresh
    let header = MailRefreshHeaderAnimator.init(frame: CGRect.zero)
    var esHeaderView: ESRefreshHeaderView?
    let footer = MailLoadMoreRefreshAnimator.init(frame: CGRect.zero)
    var transferFolderKey: String = ""
    var timer: Timer? = Timer()
    var loadingInterval = 0.0
    var didAppear: Bool = false
    enum capacityType {
        case delete
    }
    var sortedState: [Bool] = [true, false, false, false] // 维护排序弹窗数据
    
    @DataManagerValue<capacityType> var capacityChange
    
    var fetcher: DataService? {
        return MailDataServiceFactory.commonDataService
    }
    
    var sortedViewHeight: CGFloat {
        return 52
    }
    
    var statusAndNaviHeight: CGFloat {
        return statusHeight + naviHeight
    }
    
    var statusHeight: CGFloat {
        if Display.isDynamicIsland() {
            return UIApplication.shared.statusBarFrame.height + 5
        } else {
            return UIApplication.shared.statusBarFrame.height
        }
    }
    
    private lazy var _mailBaseLoadingView: MailBaseLoadingView = {
        let loading = MailBaseLoadingView()
        loading.isHidden = true
        self.mailLayoutPlaceHolderView(placeholderView: loading)
        return loading
    }()

    var mailLoadingPlaceholderView: MailBaseLoadingView {
        guard let larkNavibar = navbarBridge?.getLarkNaviBar() else {
            return _mailBaseLoadingView
        }
        self.view.insertSubview(_mailBaseLoadingView, belowSubview: larkNavibar)
        return _mailBaseLoadingView
    }
    
    // 多选项cell待删除组(存对应cellindex与token)
    var selectedAttachmentsIds = [Int64:String]() {
        didSet {
            if selectedAttachmentsIds.isEmpty {
                addDeleteItem()
            } else {
                addEnableDeleteItem()
            }
        }
    }
    
    // 多选cell 容量数组
    var selectedAttachmentsCapacity = [Int64]() {
        didSet {
            if selectedAttachmentsCapacity.isEmpty {
                self.memmoryLabel.text = self.memmoryStr(isSeleted: true, fileNum: 0, capacity:FileSizeHelper.memoryFormat(UInt64(0), useAbbrByte: true, spaceBeforeUnit: true))
            } else {
                self.memmoryLabel.text = self.memmoryStr(isSeleted: true, fileNum: Int32(selectedAttachmentsIds.count), capacity: FileSizeHelper.memoryFormat(UInt64(selectedAttachmentsCapacity.reduce(0, +)), useAbbrByte: true, spaceBeforeUnit: true))
            }
        }
    }
    
    var isMultiSelecting: Bool = false {
        didSet {
            MailLogger.info("[mail_attach_mannager] isMultiSelecting: \(isMultiSelecting)")
            if isMultiSelecting == false {
                selectedAttachmentsIds = [:]
                selectedAttachmentsCapacity = []
                memmoryLabel.text = self.memmoryStr(isSeleted: false, fileNum: viewModel.fileTotal ,capacity: FileSizeHelper.memoryFormat(UInt64(viewModel.capacity), useAbbrByte: true, spaceBeforeUnit: true))
            }
            self.tableView.reloadData()
        }
    }
    
    override var navigationBarTintColor: UIColor {
        return UIColor.ud.bgBody
    }
    
    // MARK: Life Circle
    init(accountContext: MailAccountContext, accountID:String, transferFolderKey: String) {
        self.previewIndex = 0
        self.accountContext = accountContext
        self.accountID = accountID
        self.transferFolderKey = transferFolderKey
        self.viewModel = MailAttachmentsViewModel.init(transferFolderKey: transferFolderKey, accountID: accountID)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: LifeCircle
    override func viewDidLoad() {
        self.title = BundleI18n.MailSDK.Mail_Shared_Settings_LargeAttachmentStorage_Title
        super.viewDidLoad()
        setupNativeView()
        bindViewModel(VM: self.viewModel)
        // 首次刷新
        self.viewModel.firstRefresh()
        updateNavAppearanceIfNeeded()
        let event = NewCoreEvent(event: .email_large_attachment_management_view)
        event.params = ["mail_account_type":Store.settingData.getMailAccountType()]
        event.post()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !didAppear {
            configTabelViewRefresh() // 延迟做这个
            didAppear = true
        }
        updateNavAppearanceIfNeeded()
    }

    // MARK: - MailAttachmentsListCellDelegate
    func didClickFlag(_ cell: MailAttachmentsListCell, cellModel: MailAttachmentsListCellViewModel) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            return
        }
        let popoverSourceView = rootSizeClassIsSystemRegular ? cell.flagButton : nil
        var moreSections = [MoreActionSection]()
        if let headerTitle = cellModel.fileName,
           let subtitle = cellModel.desc,
           let fileToken = cellModel.fileToken,
           let fileSize = cellModel.fileSize,
           let messageID = cellModel.mailMessageBizID,
           let threadID = cellModel.mailThreadID {
            let headerConfig = MoreActionHeaderConfig(iconType: .imageWithoutCorner(_image:  UIImage.fileLadderIcon(with: headerTitle)),
                                                      title: headerTitle,
                                                      subtitle: subtitle)
            // 删除
            moreSections = generateMoreSections(title: BundleI18n.MailSDK.Mail_Shared_LargeAttachmentStorageDetails_Delete_Button,
                                 icon: UDIcon.deleteTrashOutlined.withRenderingMode(.alwaysTemplate),
                                 sections: moreSections,
                                 actionCallBack: { [weak self] _ in
                guard let `self` = self else { return }
                let alert = LarkAlertController()
                alert.setTitle(text:BundleI18n.MailSDK.Mail_Shared_LargeAttachment_DeleteAttachment_Title)
                alert.setContent(text:BundleI18n.MailSDK.Mail_Shared_LargeAttachment_DeleteAttachment_Desc(headerTitle))
                alert.addSecondaryButton(text:BundleI18n.MailSDK.Mail_Shared_LargeAttachment_DeleteAttachment_Cancel)
                alert.addDestructiveButton(text:BundleI18n.MailSDK.Mail_Shared_LargeAttachment_DeleteAttachment_Delete,
                                           dismissCompletion:  { [weak self] in
                    guard let self = self else { return }
                    let dic = [Int64(indexPath.row):fileToken]
                    self.viewModel.deleteData(deleteList: dic, indexPath: indexPath)
                    let event = NewCoreEvent(event: .email_large_attachment_management_click)
                    event.params = ["click": "delete",
                                    "target": "none",
                                    "num": "single",
                                    "mail_account_type":Store.settingData.getMailAccountType()]
                    event.post()
                    self.accountContext.securityAudit.audit(type:.largeAttachmentDelete(mailInfo: AuditMailInfo(smtpMessageID: cellModel.mailSmtpID ?? "",subject: "",sender: "", ownerID: nil, isEML: false), fileID: fileToken, fileSize: Int(fileSize), fileName: headerTitle))
                })
                self.accountContext.navigator.present(alert, from: self)
            })
            // 下载
            moreSections = generateMoreSections(title: BundleI18n.MailSDK.Mail_Shared_LargeAttachmentStorageDetails_Download_Button,
                                 icon: UDIcon.downloadOutlined.withRenderingMode(.alwaysTemplate),
                                 sections: moreSections,
                                 actionCallBack: { [weak self] _ in
                guard let `self` = self else { return }
                if cellModel.status == .highRisk {
                    let alert = self.riskAlert(title: BundleI18n.MailSDK.Mail_Shared_LargeAttachment_UnableToDownload_Title, fileToken: fileToken)
                    self.accountContext.navigator.present(alert, from:self)
                } else if cellModel.status == .banned {
                    let alert = LarkAlertController()
                    alert.setTitle(text:BundleI18n.MailSDK.Mail_Shared_LargeAttachment_DangerousContent_Title)
                    alert.setContent(text:BundleI18n.MailSDK.Mail_Shared_LargeAttachment_DangerousContent_Desc)
                    alert.addSecondaryButton(text:BundleI18n.MailSDK.Mail_Shared_LargeAttachment_DangerousContent_DownloadBttn,
                                             dismissCompletion:  { [weak self] in
                        guard let self = self else { return }
                        let event = NewCoreEvent(event: .email_large_attachment_management_click)
                        event.params = ["click": "download",
                                        "target": "none",
                                        "mail_account_type":Store.settingData.getMailAccountType()]
                        event.post()
                        self.attachmentPreviewRouter.saveToLocal(fileSize: UInt64(fileSize), fileObjToken: fileToken, fileName: headerTitle, sourceController: self)
                    })
                    alert.addButton(text: BundleI18n.MailSDK.Mail_Shared_LargeAttachment_DangerousContent_CancelBttn)
                    self.accountContext.navigator.present(alert, from: self)
                } else {
                    let event = NewCoreEvent(event: .email_large_attachment_management_click)
                    event.params = ["click": "download",
                                    "target": "none",
                                    "mail_account_type":Store.settingData.getMailAccountType()]
                    event.post()
                    self.attachmentPreviewRouter.saveToLocal(fileSize: UInt64(fileSize), fileObjToken: fileToken, fileName: headerTitle, sourceController: self)
                }
            })
            // 用其他应用打开
            moreSections = generateMoreSections(title: BundleI18n.MailSDK.Mail_Shared_LargeAttachmentStorageDetails_Open_Button,
                                 icon: UDIcon.appDefaultOutlined.withRenderingMode(.alwaysTemplate),
                                 sections: moreSections,
                                 actionCallBack: { [weak self] _ in
                guard let `self` = self else { return }
                if cellModel.status == .highRisk {
                    let alert = self.riskAlert(title: BundleI18n.MailSDK.Mail_Shared_LargeAttachment_UnableToOpen_Title, fileToken: fileToken)
                    self.accountContext.navigator.present(alert, from:self)
                } else if cellModel.status == .banned {
                    let alert = LarkAlertController()
                    alert.setContent(text:BundleI18n.MailSDK.Mail_Shared_LargeAttachment_RiskyContentDownload_Notice)
                    alert.addSecondaryButton(text:BundleI18n.MailSDK.Mail_Shared_LargeAttachment_RiskyContentDownload_Cancel)
                    alert.addButton(text: BundleI18n.MailSDK.Mail_Shared_LargeAttachment_RiskyContentDownload_Download, dismissCompletion: { [weak self] in
                        guard let `self` = self else { return }
                        let nextAlert = LarkAlertController()
                        nextAlert.setTitle(text:BundleI18n.MailSDK.Mail_Shared_LargeAttachment_DangerousContent_Title)
                        nextAlert.setContent(text:BundleI18n.MailSDK.Mail_Shared_LargeAttachment_DangerousContent_Desc)
                        nextAlert.addSecondaryButton(text:BundleI18n.MailSDK.Mail_Shared_LargeAttachment_DangerousContent_DownloadBttn, dismissCompletion:  { [weak self] in
                            guard let self = self else { return }
                            let event = NewCoreEvent(event: .email_large_attachment_management_click)
                            event.params = ["click": "local_open",
                                            "target": "none",
                                            "mail_account_type":Store.settingData.getMailAccountType()]
                            event.post()
                            self.attachmentPreviewRouter.openDriveFileWithOtherApp(fileSize: UInt64(fileSize), fileObjToken:fileToken, fileName:headerTitle, sourceController: self)
                        })
                        nextAlert.addButton(text: BundleI18n.MailSDK.Mail_Shared_LargeAttachment_DangerousContent_CancelBttn)
                        self.accountContext.navigator.present(nextAlert, from: self)
                    })
                    self.accountContext.navigator.present(alert, from: self)
                } else {
                    let event = NewCoreEvent(event: .email_large_attachment_management_click)
                    event.params = ["click": "local_open",
                                    "target": "none",
                                    "mail_account_type":Store.settingData.getMailAccountType()]
                    event.post()
                    self.attachmentPreviewRouter.saveToLocal(fileSize: UInt64(fileSize), fileObjToken: fileToken, fileName: headerTitle, sourceController: self)
                }
            })
            
            if cellModel.infoListType == .fileInfo { // 离职转移不展示查看原始邮件
                // "查看原始邮件"
                moreSections = generateMoreSections(title: BundleI18n.MailSDK.Mail_Shared_LargeAttachmentStorageDetails_ViewOriginalMail_Button,
                                                    icon: UDIcon.mailOutlined.withRenderingMode(.alwaysTemplate),
                                                    sections: moreSections,
                                                    actionCallBack: { [weak self] _ in
                    guard let `self` = self else { return }
                    let event = NewCoreEvent(event: .email_large_attachment_management_click)
                    event.params = ["click": "open_email",
                                    "target": "none",
                                    "mail_account_type":Store.settingData.getMailAccountType()]
                    event.post()
                    self.jumpToMail(messageID: messageID, threadID: threadID, isDraft: cellModel.isDraft)
                })
            }
            // "保存到“我的空间”"
            moreSections = generateMoreSections(title: BundleI18n.MailSDK.Mail_Shared_LargeAttachmentStorageDetails_SaveToMySpace_Button,
                                 icon: UDIcon.cloudUploadOutlined.withRenderingMode(.alwaysTemplate),
                                 sections: moreSections,
                                 actionCallBack: { [weak self] _ in
                guard let `self` = self else { return }
                let event = NewCoreEvent(event: .email_large_attachment_management_click)
                event.params = ["click": "save_to_space",
                                "target": "none",
                                "mail_account_type":Store.settingData.getMailAccountType()]
                event.post()
                self.attachmentPreviewRouter.saveToSpace(fileSize: UInt64(fileSize), fileObjToken:fileToken, fileName: headerTitle, sourceController: self)
            })
            // "分享至会话"
            moreSections = generateMoreSections(title: BundleI18n.MailSDK.Mail_Shared_LargeAttachmentStorageDetails_ShareToChat_Button,
                                 icon: UDIcon.shareOutlined.withRenderingMode(.alwaysTemplate),
                                 sections: moreSections,
                                 actionCallBack: { [weak self] _ in
                guard let `self` = self else { return }
                let event = NewCoreEvent(event: .email_large_attachment_management_click)
                event.params = ["click": "share",
                                "target": "none",
                                "mail_account_type":Store.settingData.getMailAccountType()]
                event.post()
                self.attachmentPreviewRouter.forwardShareMailAttachement(fileSize: UInt64(fileSize), fileObjToken:fileToken, fileName: headerTitle, sourceController: self, isLargeAttachment:true)
            })
            // Thread
            presentMoreActionVC(headerConfig: headerConfig,
                                sectionData: moreSections,
                                popoverSourceView: popoverSourceView,
                                popoverRect: cell.convert(cell.frame, to: nil))
        }
    }
    // 高危文件弹窗
    func riskAlert(title: String, fileToken: String) -> UIViewController {
        let alert = LarkAlertController()
        alert.setTitle(text: title)
        alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_Shared_LargeAttachment_UnableToDownload_AppealBttn, dismissCompletion: { [weak self] in
            guard let `self` = self else { return }
            let domain = self.accountContext.provider.configurationProvider?.getDomainSetting(key: .securityWeb).first ?? ""
            let locale = LanguageManager.currentLanguage.languageIdentifier
            let urlString = "https://\(domain)/document-security-inspection/appeal?obj_token=\(fileToken)&locale=\(locale)&version=0&file_type=12"
            guard let url = URL(string: urlString) else { return }
            self.accountContext.navigator.push(url, from: self)
        })
        alert.addButton(text: BundleI18n.MailSDK.Mail_Shared_LargeAttachment_UnableToDownload_GotIt, dismissCompletion: {
        })
        let text = BundleI18n.MailSDK.Mail_UnableToDownloadHighRiskSingular_Desc(BundleI18n.MailSDK.Mail_FeishuFileSecurityPolicy_Text)
        let actionableText = BundleI18n.MailSDK.Mail_FeishuFileSecurityPolicy_Text
        let textView = ActionableTextView.alertWithLinkTextView(text: text,
                                                                actionableText: actionableText,
                                                                action: { [weak self] in
            let domain = self?.accountContext.provider.configurationProvider?.getDomainSetting(key: .securityWeb).first ?? ""
            let locale = LanguageManager.currentLanguage.languageIdentifier
            let urlString = "https://\(domain)/document-security-inspection/file-security-policy/\(locale)"
            guard let url = URL(string: urlString) else { return }
            UIApplication.shared.open(url)
        })
        alert.setContent(view: textView, padding: UIEdgeInsets(top: 12, left: 20, bottom: 24, right: 20))
        return alert
    }
    
    func generateMoreSections(title: String, icon: UIImage, sections: [MoreActionSection], actionCallBack:@escaping MailActionCallBack) -> [MoreActionSection] {
        let actionItem = MailActionItem(title:title,
                                        icon:icon,
                                        udGroupNumber: 999,
                                        actionCallBack:actionCallBack)
        var newSections = sections
        newSections.append(MoreActionSection(layout: .vertical, items: [actionItem]))
        return newSections
    }
    
    func presentMoreActionVC(headerConfig: MoreActionHeaderConfig?, sectionData: [MoreActionSection], popoverSourceView: UIView?, popoverRect: CGRect?) {
        let callback = { [weak self] (headerConfig: MoreActionHeaderConfig?, sectionData: [MoreActionSection], popoverSourceView: UIView?) -> Void in
            guard let `self` = self else { return }
            let moreVC = MoreActionViewController(headerConfig: headerConfig, sectionData: sectionData)
            if let popoverSourceView = popoverSourceView {
                moreVC.needAnimated = false
                moreVC.modalPresentationStyle = .popover
                moreVC.popoverPresentationController?.sourceView = popoverSourceView
                moreVC.popoverPresentationController?.sourceRect = popoverSourceView.bounds
                if let rect = popoverRect {
                    if rect.origin.y > UIScreen.main.bounds.height / 3 * 2 {
                        moreVC.popoverPresentationController?.permittedArrowDirections = .down
                        moreVC.arrowUp = false
                    } else {
                        moreVC.popoverPresentationController?.permittedArrowDirections = .up
                        moreVC.arrowUp = true
                    }
                }
            }
            self.accountContext.navigator.present(moreVC, from: self, animated: false, completion: nil)
        }
        callback(headerConfig, sectionData, popoverSourceView)
    }
    
    func mailLayoutPlaceHolderView(placeholderView: UIView) {
        self.view.addSubview(placeholderView)
        placeholderView.snp.makeConstraints { (make) in
            make.center.width.height.equalToSuperview()
        }
    }
    
    @discardableResult
    open func addManagerItem(color:UIColor, enable:Bool) -> UIBarButtonItem {
        let barItem = LKBarButtonItem(image: nil, title:BundleI18n.MailSDK.Mail_LargeAttachmentMobile_ManageStorage_Bttn)
        barItem.button.addTarget(self, action: #selector(managerBtnTapped), for: .touchUpInside)
        barItem.setBtnColor(color: color)
        barItem.isEnabled = enable
        self.navigationItem.rightBarButtonItem = barItem
        return barItem
    }
    
    @discardableResult
    open func addEnableDeleteItem() -> UIBarButtonItem {
        let title = BundleI18n.MailSDK.Mail_LargeAttachmenMobile_DeleteBttn(selectedAttachmentsIds.count)
        let barItem = LKBarButtonItem(image: nil, title:title)
        barItem.setBtnColor(color: UIColor.ud.functionDanger500)

        barItem.button.addTarget(self, action: #selector(deleteBtnTapped), for: .touchUpInside)
        barItem.isEnabled = true
        self.navigationItem.rightBarButtonItem = barItem
        return barItem
    }
    
    @discardableResult
    open func addDeleteItem() -> UIBarButtonItem { // 灰色不可点击删除按钮
        let barItem = LKBarButtonItem(image: nil, title:BundleI18n.MailSDK.Mail_Shared_LargeAttachment_DeleteMultiple_Delete)
        barItem.button.addTarget(self, action: #selector(deleteBtnTapped), for: .touchUpInside)
        barItem.isEnabled = false
        self.navigationItem.rightBarButtonItem = barItem
        return barItem
    }
    
    @discardableResult
    open override func addCancelItem() -> UIBarButtonItem {
        let barItem = LKBarButtonItem(image: nil, title:BundleI18n.MailSDK.Mail_Shared_LargeAttachment_DeleteMultiple_Cancel)
        barItem.button.addTarget(self, action: #selector(cancelBtnTapped), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = barItem
        return barItem
    }
    
    // MARK: operation
    @objc
    open func managerBtnTapped() {
        isMultiSelecting = true
        addDeleteItem()
        addCancelItem()
        self.title = BundleI18n.MailSDK.Mail_LargeAttachmentMobile_SelectFile_Title
        memmoryLabel.text = self.memmoryStr(isSeleted: true, fileNum:0, capacity: FileSizeHelper.memoryFormat(UInt64(0), useAbbrByte: true, spaceBeforeUnit: true))
        sortedBtn.setImage(UDIcon.getIconByKey(UDIconType.sortOutlined).ud.withTintColor(UIColor.ud.iconDisabled), for: .normal)
        sortedBtn.isEnabled = false
        tableView.es.removeRefreshHeader()
    }
    
    @objc
    open func deleteBtnTapped() {
        let alert = LarkAlertController()
        alert.setTitle(text: BundleI18n.MailSDK.Mail_Shared_LargeAttachment_DeleteMultiple_Title(selectedAttachmentsIds.count))
        alert.setContent(text:BundleI18n.MailSDK.Mail_Shared_LargeAttachment_DeleteMultiple_Desc)
        alert.addSecondaryButton(text:BundleI18n.MailSDK.Mail_Shared_LargeAttachment_DeleteMultiple_Cancel)

        let second: Int64 = 5
        let btn = alert.addButton(text: BundleI18n.MailSDK.Mail_Shared_LargeAttachment_DeleteMultiple_DeleteCountdown(second),
                                  dismissCompletion: { [weak self] in
            guard let self = self else { return }
            // 安全审计打点
            let deleteValues: [String] = self.selectedAttachmentsIds.values.map({$0})
            let deletedModelInfo = self.viewModel.dataSource.filter( {deleteValues.contains($0.fileToken ?? "")})
            for deletedModel in deletedModelInfo {
                self.accountContext.securityAudit.audit(type:.largeAttachmentDelete(mailInfo: AuditMailInfo(smtpMessageID: deletedModel.mailSmtpID ?? "",subject: "",sender: "", ownerID: nil, isEML: false), fileID: deletedModel.fileToken ?? "", fileSize: Int(deletedModel.fileSize ?? 0), fileName: deletedModel.fileName ?? ""))
            }
            let event = NewCoreEvent(event: .email_large_attachment_management_click)
            event.params = ["click": "delete",
                            "target": "none",
                            "num": "multi",
                            "mail_account_type":Store.settingData.getMailAccountType()]
            event.post()
            self.viewModel.multiDeleteData(deleteList: self.selectedAttachmentsIds)
        })
        let text = NSAttributedString(string: BundleI18n.MailSDK.Mail_Shared_LargeAttachment_DeleteMultiple_DeleteCountdown(5),
                                      attributes: [.foregroundColor: UIColor.ud.textDisabled])
        btn.setAttributedTitle(text, for: .disabled)
        btn.isEnabled = false
        MailCountdownTaskManager.default.initTask(timeSecond: Int64(5)) { timeLeave in
            let text = NSAttributedString(string: BundleI18n.MailSDK.Mail_Shared_LargeAttachment_DeleteMultiple_DeleteCountdown(timeLeave),
                                          attributes: [.foregroundColor: UIColor.ud.textDisabled])
            btn.setAttributedTitle(text, for: .disabled)
        } onComplete: {
            let text = NSAttributedString(string: BundleI18n.MailSDK.Mail_Shared_LargeAttachment_DeleteMultiple_Delete, attributes: [.foregroundColor:UIColor.ud.functionDanger500])
            btn.setAttributedTitle(text, for: .normal)
            btn.isEnabled = true
        }
        self.accountContext.navigator.present(alert, from: self)
    }
    
    @objc
    open func cancelBtnTapped() {
        exitMulti()
    }
    
    @objc
    open func backItem() {
        self.dismiss(animated: true, completion: nil)
    }
    
    // 退出多选
    func exitMulti() {
        isMultiSelecting = false
        addManagerItem(color:UIColor.ud.iconN1, enable: true)
        let barItem = LKBarButtonItem(image: UDIcon.leftOutlined)
        barItem.button.addTarget(self, action: #selector(backItem), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = barItem
        self.title = BundleI18n.MailSDK.Mail_Shared_LargeAttachmentStorage_ManageStorage_Title
        memmoryLabel.text = self.memmoryStr(isSeleted: false, fileNum: viewModel.fileTotal,capacity:FileSizeHelper.memoryFormat(UInt64(viewModel.capacity), useAbbrByte: true, spaceBeforeUnit: true))
        sortedBtn.isEnabled = true
        sortedBtn.setImage(UDIcon.getIconByKey(UDIconType.sortOutlined).ud.withTintColor(UIColor.ud.iconN2), for: .normal)
        configHeaderRefresh()
    }
    
    func hiddenLoading() {
        // 关闭等待计时
        asyncRunInMainThread {
            MailLogger.info("[mail_settings] [mail_attachment] mail hide loading")
            self.mailLoadingPlaceholderView.stop()
        }
    }
    
    @objc
    open func presentSortedSheetClick() {
        
        let timeFromNewToOld = SortedActionSection.init(title:BundleI18n.MailSDK.Mail_LargeAttachmentMobile_SortFromNewToOld, isSeleted:sortedState[0]) { [weak self] _ in
            guard let `self` = self else { return }
            self.viewModel.orderFiled = .createdTime
            self.viewModel.orderType = .desc
            self.viewModel.refreshData(orderFiled: .createdTime, orderType: .desc, sessionId: String(0), transferFolderKey:self.transferFolderKey)
            self.sortedState = [true, false, false, false]
            let event = NewCoreEvent(event: .email_large_attachment_management_click)
            event.params = ["click": "order_by_create_time",
                            "target": "none",
                            "order": "desc",
                            "mail_account_type":Store.settingData.getMailAccountType()]
            event.post()
        }
        
        let timeFromOldToNew = SortedActionSection.init(title:BundleI18n.MailSDK.Mail_LargeAttachmentMobile_SortFromOldToNew, isSeleted:sortedState[1]) { [weak self] _ in
            guard let `self` = self else { return }
            self.viewModel.orderFiled = .createdTime
            self.viewModel.orderType = .asc
            self.viewModel.refreshData(orderFiled: .createdTime, orderType: .asc, sessionId: String(0), transferFolderKey:self.transferFolderKey)
            self.sortedState = [false, true, false, false]
            let event = NewCoreEvent(event: .email_large_attachment_management_click)
            event.params = ["click": "order_by_create_time",
                            "target": "none",
                            "order": "asc",
                            "mail_account_type":Store.settingData.getMailAccountType()]
            event.post()
        }
        let filesFromLargeToSmall = SortedActionSection.init(title: BundleI18n.MailSDK.Mail_LargeAttachmentMobile_SortFromBigToSmall, isSeleted:sortedState[2]) { [weak self] _ in
            guard let `self` = self else { return }
            self.viewModel.orderFiled = .fileSize
            self.viewModel.orderType = .desc
            self.viewModel.refreshData(orderFiled: .fileSize, orderType: .desc, sessionId: String(0), transferFolderKey:self.transferFolderKey)
            self.sortedState = [false, false, true, false]
            let event = NewCoreEvent(event: .email_large_attachment_management_click)
            event.params = ["click": "order_by_file_byte",
                            "target": "none",
                            "order": "desc",
                            "mail_account_type":Store.settingData.getMailAccountType()]
            event.post()
        }
        let filesFromSmallToLarge = SortedActionSection.init(title:BundleI18n.MailSDK.Mail_LargeAttachmentMobile_SortFromSmallToBig, isSeleted:sortedState[3]) { [weak self] _ in
            guard let `self` = self else { return }
            self.viewModel.orderFiled = .fileSize
            self.viewModel.orderType = .asc
            self.viewModel.refreshData(orderFiled: .fileSize, orderType: .asc, sessionId: String(0), transferFolderKey:self.transferFolderKey)
            self.sortedState = [false, false, false, true]
            let event = NewCoreEvent(event: .email_large_attachment_management_click)
            event.params = ["click": "order_by_file_byte",
                            "target": "none",
                            "order": "asc",
                            "mail_account_type":Store.settingData.getMailAccountType()]
            event.post()
        }
        let sections = [timeFromNewToOld, timeFromOldToNew, filesFromLargeToSmall, filesFromSmallToLarge]
        let sortedSheetVC = SortedActionViewController.makeSortedActionVC(headerTitle:BundleI18n.MailSDK.Mail_LargeAttachmentMobile_SortBy, sectionData: sections, popoverSourceView: nil)
        accountContext.navigator.present(sortedSheetVC, from: self, animated: false, completion: nil)
    }
    
    func setupNativeView() {
        let barItem = LKBarButtonItem(image: UDIcon.leftOutlined)
        barItem.button.addTarget(self, action: #selector(backItem), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = barItem
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.tintColor = UIColor.ud.iconN1
        view.backgroundColor = UIColor.ud.bgBody
        view.addSubview(tableView)
        view.addSubview(sortedView)
        
        sortedView.backgroundColor = UIColor.ud.bgBody
                
        sortedView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(sortedViewHeight)
        }
        
        tableView.snp.makeConstraints { (make) in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(sortedView.snp.bottom)
        }
        
        sortedView.addSubview(memmoryLabel)
        sortedView.addSubview(sortedBtn)
        
        memmoryLabel.snp.makeConstraints { make in
            make.top.equalTo(sortedView.snp.top).offset(20)
            make.left.equalTo(sortedView).offset(16)
            make.bottom.equalTo(sortedView.btd_bottom).offset(-12)
        }
        
        sortedBtn.snp.makeConstraints { make in
            make.centerY.equalTo(memmoryLabel)
            make.right.equalTo(sortedView.btd_right).offset(-16)
            make.height.width.equalTo(16)
        }
    }
    
    // MARK: - getter
    func memmoryStr(isSeleted: Bool, fileNum: Int32, capacity: String) -> String {
        var str = ""
        if (!isSeleted) { //未进入多选
            str = BundleI18n.MailSDK.Mail_Shared_LargeAttachmentStorage_ManageStorage_Desc(fileNum, capacity)
        } else {
            str = BundleI18n.MailSDK.Mail_LargeAttachmentMobile_SelectedFile(fileNum, capacity)
        }
        return str
    }
    
    func makeMemmoryLabel(isSeleted: Bool, fileNum: Int32, capacity: String) -> UILabel {
        let memmoryLabel = UILabel(frame: CGRect.zero)
        if (!isSeleted) { //未进入多选
            memmoryLabel.text = BundleI18n.MailSDK.Mail_Shared_LargeAttachmentStorage_ManageStorage_Desc(fileNum, capacity)
        } else {
            memmoryLabel.text = BundleI18n.MailSDK.Mail_LargeAttachmentMobile_SelectNumberAndSize(fileNum, capacity)
        }
        memmoryLabel.textColor = UIColor.ud.textCaption
        memmoryLabel.font =  UIFont.systemFont(ofSize: 14.0)
        return memmoryLabel
    }
    
    func makeSortedBtn() -> UIButton {
        let sortedBtn = UIButton(frame: CGRect.zero)
        sortedBtn.setImage(UDIcon.getIconByKey(UDIconType.sortOutlined).ud.withTintColor(UIColor.ud.iconN2), for: .normal)
        sortedBtn.isEnabled = true
        sortedBtn.addTarget(self, action: #selector(presentSortedSheetClick), for: .touchUpInside)
        return sortedBtn
    }

    func makeTabelView() -> UITableView {
        let tableView = UITableView(frame: CGRect.zero)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.ud.bgBody
        let footerView = UIView()
        footerView.backgroundColor = .systemTeal
        tableView.tableFooterView = footerView
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        tableView.separatorStyle = .none
        tableView.allowsMultipleSelection = true
        
        tableView.lu.register(cellSelf: MailAttachmentsListCell.self)
        tableView.lu.register(cellSelf: MailHomeEmptyCell.self)
        tableView.contentInsetAdjustmentBehavior = .never
        return tableView
    }
    
    // MARK: - Bind
    func bindViewModel(VM: MailAttachmentsViewModel) {
        VM.dataState
            .observeOn(MainScheduler.instance)
            .subscribe(onNext:{ [weak self] (state) in
                guard let self = self else { return }
                switch state {
                case .firstRefresh:
                    self.handleRefreshedDatas()
                case .refreshed:
                    self.handleRefreshedDatas()
                case .loadMore:
                    self.handleLoadMore()
                case .empty:
                    self.handleDatasEmpty()
                case .failed:
                    self.handleDatasErrors()
                case .loading:
                    self.handleLoading()
                case .multiDelete:
                    self.handleMultiDelete()
                case .delete(indexPath: let indexPath):
                    self.handleDataDelete(indexPath: indexPath)
                case .loadMoreFailure:
                    UDToast.showFailure(with: BundleI18n.MailSDK.Mail_Shared_LargeAttachment_LoadFailWait_Error, on: self.view)
                case .deleteFailed:// 多选删除&删除
                    UDToast.showFailure(with: BundleI18n.MailSDK.Mail_Shared_LargeAttachment_ProcessFailed, on: self.view)
                }
            }).disposed(by: disposeBag)
    }
    
    // loading页面
    func handleLoading() {
        mailLoadingPlaceholderView.play()
        mailLoadingPlaceholderView.isHidden = false
    }
    
    // 刷新数据页面
    func handleRefreshedDatas() {
        addManagerItem(color:UIColor.ud.iconN1, enable: true)
        self.sortedView.isHidden = false
        memmoryLabel.text = self.memmoryStr(isSeleted: false, fileNum: viewModel.fileTotal,capacity: FileSizeHelper.memoryFormat(UInt64(viewModel.capacity), useAbbrByte: true, spaceBeforeUnit: true))
        self.hiddenLoading()
        tableView.es.stopPullToRefresh(ignoreDate: true)
        tableView.es.resetNoMoreData()
        self.tableView.es.stopLoadingMore()
        self.tableView.reloadData()
    }
    
    // 加载更多数据
    func handleLoadMore() {
        // seletedIndexes
        var selectedIndexes = [Int]()
        if let indexPaths = tableView.indexPathsForSelectedRows {
            selectedIndexes = indexPaths.map { $0.row }
        }
        hiddenLoading()
        tableView.es.stopLoadingMore()
        if !viewModel.hasMore {
            tableView.es.noticeNoMoreData()
        }
        tableView.reloadData()
        // 恢复之前已选中的行或项的选择状态
        for index in selectedIndexes {
            let indexPath = IndexPath(row: index, section: 0)
                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
    }
    // 错误页面
    func handleDatasErrors() {
        addManagerItem(color:UIColor.ud.textDisabled, enable:false)
        hiddenLoading()
        status = .canRetry
        viewModel.hasMore = false
        tableView.reloadData()
    }
    
    // 空页面处理
    func handleDatasEmpty() {
        sortedView.isHidden = true
        addManagerItem(color:UIColor.ud.textDisabled, enable:false)
        hiddenLoading()
        status = .emptyAttachment
        viewModel.hasMore = false
        tableView.reloadData()
    }
    
    // 单选删除
    func handleDataDelete(indexPath: IndexPath) {
        self.$capacityChange.accept(.delete)
        if viewModel.dataSource.isEmpty {
            tableView.reloadRows(at: [indexPath], with: .left)
        } else {
            UDToast.showSuccess(with: BundleI18n.MailSDK.Mail_Shared_LargeAttachment_AttachmentDeleted_Toast, on: self.view)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        memmoryLabel.text = self.memmoryStr(isSeleted: false, fileNum: viewModel.fileTotal,capacity:FileSizeHelper.memoryFormat(UInt64(viewModel.capacity), useAbbrByte: true, spaceBeforeUnit: true))
    }
    
    // 多选删除
    func handleMultiDelete() {
        self.$capacityChange.accept(.delete)
        self.selectedAttachmentsIds = [:]
        self.selectedAttachmentsCapacity = []
        exitMulti()
        self.tableView.reloadData()
        UDToast.showSuccess(with: BundleI18n.MailSDK.Mail_Shared_LargeAttachment_AttachmentDeleted_Toast, on: self.view)
    }
    
    // MARK: - UITableViewDelegate & UITableViewDataSource
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if viewModel.dataSource.isEmpty {
            tableView.isScrollEnabled = false
            return tableView.bounds.size.height
        } else {
            tableView.isScrollEnabled = true
            return MailAttachmentsControllerConst.CellHeight
        }
    }
    
    private func tableView(_ tableView: UITableView, heightForHeaderInSection indexPath: IndexPath) -> CGFloat {
        return 0
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if viewModel.dataSource.isEmpty {
            return  1
        } else {
            return viewModel.dataSource.count
        }
    }
    
    func calculteYOffset() -> CGFloat {
        return statusAndNaviHeight / 2.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if viewModel.dataSource.isEmpty {
            sortedView.isHidden = true
            if let cell = tableView.dequeueReusableCell(withIdentifier: MailHomeEmptyCell.lu.reuseIdentifier) as? MailHomeEmptyCell {
                cell.centerYOffset = calculteYOffset()
                cell.status = status
                cell.selectionStyle = .none
                cell.frame = tableView.bounds
                return cell
            }
        } else if viewModel.dataSource.count > indexPath.row {
            let cellVM = viewModel.dataSource[indexPath.row]
            
             if let cell = tableView.dequeueReusableCell(withIdentifier: MailAttachmentsListCell.lu.reuseIdentifier) as? MailAttachmentsListCell {
                 
                 // 这个可能为nil
                cell.isMultiSelecting = isMultiSelecting
                cell.cellViewModel = cellVM
                cell.delegate = self
                cell.mailDelegate = self
                cell.enableLongPress = true
                cell.longPressDelegate = self
                cell.selectedIndexPath = indexPath
                cell.rootSizeClassIsRegular = rootSizeClassIsRegular
                cell.accessibilityIdentifier = MailAccessibilityIdentifierKey.HomeCellKey + "\(indexPath.row)"
                return cell
            }
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if isMultiSelecting {
            if let fileSize = viewModel.dataSource[indexPath.row].fileSize {
                selectedAttachmentsIds.removeValue(forKey: Int64(indexPath.row))
                selectedAttachmentsCapacity.lf_remove(object: fileSize)
            }
            return
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if !isMultiSelecting, let selectedRows = tableView.indexPathsForSelectedRows {
            for selectedRow in selectedRows where selectedRow != indexPath {
                tableView.deselectRow(at: selectedRow, animated: false)
            }
        }
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        if viewModel.dataSource.count < 1 {
            if status == .canRetry {
                self.viewModel.firstRefresh()
            }
            return
        }
        let cell = tableView.cellForRow(at: indexPath)
        if isMultiSelecting {
            cell?.setSelected(true, animated: true)
            if let selectedFileToken = viewModel.dataSource[indexPath.row].fileToken,
               let fileSize = viewModel.dataSource[indexPath.row].fileSize {
                selectedAttachmentsIds[Int64(indexPath.row)] = selectedFileToken
                selectedAttachmentsCapacity.append(fileSize)
            }
            return
        } else {
            if !(cell?.isSelected ?? true) {
                cell?.setSelected(true, animated: true)
            }
        }
        enterPreView(at: indexPath.row)
    }
    
    private func jumpToMail(messageID: String, threadID: String, isDraft: Bool) {
        Store.settingData.switchMailAccount(to: self.accountContext.accountID).subscribe(onNext: { [weak self] (_) in
            guard let `self` = self else { return }
            NotificationCenter.default.post(Notification(name: Notification.Name.Mail.MAIL_SWITCH_ACCOUNT))
            if isDraft {
                self.fetcher?.getDraftItem(draftID: messageID).subscribe(onNext: { [weak self] draft in
                    guard let `self` = self else { return }
                    if let vc = MailSendController.checkMailTab_makeSendNavController(accountContext:self.accountContext,
                                                                                          threadID: threadID,
                                                                                          messageID: messageID,
                                                                                          action: .messagedraft,
                                                                                          draft: draft,
                                                                                          statInfo:MailSendStatInfo(from: .attachmentManager, newCoreEventLabelItem: "messagedraft"),
                                                                                      trackerSourceType: .inboxDraft) {
                        self.accountContext.navigator.present(vc, from: self)
                    }
                }, onError: { [weak self] error in
                    // 附件被删除
                    guard let `self` = self else { return }
                    if error.mailErrorCode == MailErrorCode.draftBeenDeleted {
                        UDToast.showFailure(with: BundleI18n.MailSDK.Mail_ReadMailBot_UnableToView_Empty, on: self.view)
                    } else {
                        UDToast.showFailure(with: BundleI18n.MailSDK.Mail_Shared_LargeAttachment_ProcessFailed, on: self.view)
                    }
                }).disposed(by: self.disposeBag)
            } else {
                // 区分会话模式与非会话模式，会话模式需要threadID & messageID， 非会话模式只需要messageID，threadID用messageID替换
                let threadID = Store.settingData.getCachedCurrentSetting()?.enableConversationMode == true ? threadID : messageID
                // 取labelID，再判断是否是草稿，根据接口结果跳转草稿/收件箱
                self.fetcher?.getMessageSuitableInfo(messageId: messageID, threadId: threadID, scene: .readMessage)
                    .subscribe(onNext: {[weak self] (resp) in
                        guard let `self` = self else { return }
                        let labelID = resp.label
                        let threadID = Store.settingData.getCachedCurrentSetting()?.enableConversationMode == true ? threadID : messageID
                        let vc = MailMessageListController.makeForRouter(accountContext: self.accountContext,
                                                                         threadId: threadID,
                                                                         labelId: labelID,
                                                                         messageId: messageID,
                                                                         statInfo: MessageListStatInfo(from: .other, newCoreEventLabelItem: labelID),
                                                                         forwardInfo: nil)
                        self.accountContext.navigator.push(vc, from:self)
                    }, onError: { (error) in
                        // 传bot屏蔽右上角的按钮
                        let vc = MailMessageListController.makeForRouter(accountContext: self.accountContext,
                                                                         threadId: "",
                                                                         labelId: "TRASH",
                                                                         messageId: "",
                                                                         keyword: "",
                                                                         statInfo: MessageListStatInfo(from: .bot, newCoreEventLabelItem: "TRASH"),
                                                                         forwardInfo: nil)
                        vc.viewModel.loadErrorType = .botLabelError
                        self.accountContext.navigator.push(vc, from:self)
                        MailLogger.info("[mail_large_attachment] mail getMessageSuitableLabel error: \(error)")
                    }).disposed(by: self.disposeBag)
                }
            })
    }
    private func enterPreView(at index: Int) {
        let attachment = viewModel.dataSource[index]
        if let fileToken = attachment.fileToken,
           let fileName = attachment.fileName,
           let fileSize = attachment.fileSize,
           let fileType = attachment.fileType,
           let messageID = attachment.mailMessageBizID,
           let threadID = attachment.mailThreadID,
           let smtpID = attachment.mailSmtpID {
            if attachment.infoListType == .fileInfo { // = 1
                // 预览附件两个自定义功能
                // 删除附件
                let deleteAction = CustomMoreActionProviderImpl(actionId: "mail_delete", text: BundleI18n.MailSDK.Mail_Shared_LargeAttachmentDetails_Action_DeleteBttn) {[weak self] _, _ in
                    guard let `self` = self else { return }
                    MailLogger.info("[mail_settings] [mail_attachment] mail action delete")
                    let alert = LarkAlertController()
                    alert.setTitle(text:BundleI18n.MailSDK.Mail_Shared_LargeAttachment_DeleteAttachment_Title)
                    alert.setContent(text:BundleI18n.MailSDK.Mail_Shared_LargeAttachment_DeleteAttachment_Desc(fileName))
                    alert.addSecondaryButton(text:BundleI18n.MailSDK.Mail_Shared_LargeAttachment_DeleteAttachment_Cancel)
                    alert.addDestructiveButton(text: BundleI18n.MailSDK.Mail_Shared_LargeAttachment_DeleteAttachment_Delete, dismissCompletion:  { [weak self] in
                        guard let self = self else { return }
                        let dic = [Int64(index):fileToken]
                        // 走多选刷新数据逻辑， 不知道排序所在索引值
                        self.viewModel.multiDeleteData(deleteList: dic)
                        let event = NewCoreEvent(event: .email_message_list_click)
                        event.params = ["click": "delete",
                                        "target": "none",
                                        "attachment_position": "attachment_preview_top"]

                        event.post()
                        self.accountContext.securityAudit.audit(type:.largeAttachmentDelete(mailInfo: AuditMailInfo(smtpMessageID: smtpID ,subject: "",sender: "", ownerID: nil, isEML: false), fileID: fileToken, fileSize: Int(fileSize), fileName: fileName))
                        self.accountContext.navigator.pop(from: self)
                    })
                    self.accountContext.navigator.present(alert, from: self)
                }
                // 查看原始邮件
                let toMail = CustomMoreActionProviderImpl(actionId: "mail_open_email", text: BundleI18n.MailSDK.Mail_Shared_LargeAttachmentStorageDetails_ViewOriginalMail_Button) { _, _ in
                    MailLogger.info("[mail_settings] [mail_attachment] mail action toMail")
                    let event = NewCoreEvent(event: .email_message_list_click)
                    event.params = ["click": "open_email",
                                    "target": "none",
                                    "attachment_position": "attachment_preview_top"]

                    event.post()

                    self.jumpToMail(messageID: messageID, threadID: threadID, isDraft: attachment.isDraft)
                }
                var customActionList:[CustomMoreActionProviderImpl] = []
                if attachment.infoListType == .fileInfo {
                    customActionList = [toMail, deleteAction]
                    customActionList = [deleteAction]
                } else {
                    customActionList = [deleteAction]
                }
                attachmentPreviewRouter.startOnlinePreview(fileToken: fileToken,
                                                           name: fileName,
                                                           fileSize: Int64(fileSize),
                                                           typeStr: fileType,
                                                           isLarge: true,
                                                           isRisk: attachment.status == .highRisk,
                                                           isOwner: true,
                                                           isBanned: attachment.status == .banned,
                                                           isDeleted: attachment.status == .deleted,
                                                           mailInfo: AuditMailInfo(smtpMessageID: smtpID, subject: "",
                                                                                   sender: "", ownerID: nil, isEML: false),
                                                           fromVC: self,
                                                           customMoreActionList: customActionList,
                                                           origin: "AttachmentManage")
            } else {
                let vc = MailAttachmentsManagerViewController(accountContext: accountContext, accountID: self.accountID, transferFolderKey: fileToken)
                accountContext.navigator.push(vc, from:self)
            }
        }
    }
    
    // MARK: - Multi-Select MailLongPressGestureRecognizer
    func cellLongPress(reconizer: MailLongPressGestureRecognizer, view: UIView) {
        enterMultiSelect(reconizer)
    }
    
    @objc
    func enterMultiSelect(_ reconizer: MailLongPressGestureRecognizer? = nil) {
        if isMultiSelecting {
            return
        }
        managerBtnTapped()
        tableView.es.stopPullToRefresh(ignoreDate: true)
        sortedBtn.setImage(UDIcon.getIconByKey(UDIconType.sortOutlined).ud.withTintColor(UIColor.ud.iconDisabled), for: .normal)
        sortedBtn.isEnabled = false
        if let reconizer = reconizer {
            let indexPath = reconizer.selectedIndexPath
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            if viewModel.dataSource.count > indexPath.row {
                let cell = tableView.cellForRow(at: indexPath)
                if let selectedFileToken = viewModel.dataSource[indexPath.row].fileToken,
                   let fileSize = viewModel.dataSource[indexPath.row].fileSize {
                    selectedAttachmentsIds[Int64(indexPath.row)] = selectedFileToken
                    selectedAttachmentsCapacity.append(fileSize)
                }
            }
        }
    }
}
