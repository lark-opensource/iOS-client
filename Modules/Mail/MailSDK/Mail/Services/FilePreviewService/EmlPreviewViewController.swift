//
// Created by NewPan on 2021/7/27.
//

import UIKit
import RxSwift
import RustPB
import WebKit
import LarkUIKit
import UniverseDesignActionPanel
import EENavigator

class EmlPreviewViewController: MailMessageListController {
    private var emlMailItem: MailItem?
    private let disposedBag = DisposeBag()

    override var isEML: Bool {
        return true
    }

    init(accountContext: MailAccountContext,
         driveFile dataSource: [MailMessageListPageViewModel],
         threadId: String,
         labelId: String,
         statInfo: MessageListStatInfo,
         fileToken: String,
         name: String,
         fileSize: Int64,
         isLarge: Bool) {
        super.init(accountContext: accountContext,
                   dataSource: dataSource,
                   threadId: threadId,
                   labelId: labelId,
                   statInfo: statInfo,
                   viewModelConfig: { (render, info) in
            EmlPreviewTrackSource.attachment.track()

            let desc = DriveFileDesc(fileToken: fileToken, name: name, fileSize: fileSize, isLarge: isLarge)

            return EmlPreviewViewModel(shitThreadID: threadId,
                                       fileSource: .drive(desc),
                                       templateRender: render,
                                       forwardInfo: info,
                                       sharedServices: accountContext.sharedServices)
        }, externalDelegate: nil)
    }

    init(accountContext: MailAccountContext,
         provider: EMLFileProvider,
         dataSource: [MailMessageListPageViewModel],
         threadId: String,
         labelId: String,
         statInfo: MessageListStatInfo) {
        EmlPreviewTrackSource.localFile.track()

        super.init(accountContext: accountContext,
                   dataSource: dataSource,
                   threadId: threadId,
                   labelId: labelId,
                   statInfo: statInfo,
                   viewModelConfig: { (render, info) in

            EmlPreviewViewModel(shitThreadID: threadId,
                                fileSource: .imFile(provider),
                                templateRender: render,
                                forwardInfo: info,
                                sharedServices: accountContext.sharedServices)
        }, externalDelegate: nil)
    }

    init(accountContext: MailAccountContext,
         localEml dataSource: [MailMessageListPageViewModel],
         threadId: String,
         labelId: String,
         statInfo: MessageListStatInfo,
         localEmlPath: URL) {
        EmlPreviewTrackSource.localFile.track()

        super.init(accountContext: accountContext,
                   dataSource: dataSource,
                   threadId: threadId,
                   labelId: labelId,
                   statInfo: statInfo,
                   viewModelConfig: { (render, info) in

            EmlPreviewViewModel(shitThreadID: threadId,
                                fileSource: .eml(localEmlPath),
                                templateRender: render,
                                forwardInfo: info,
                                sharedServices: accountContext.sharedServices)
        }, externalDelegate: nil)
    }

    init(accountContext: MailAccountContext,
         localEml dataSource: [MailMessageListPageViewModel],
         threadId: String,
         labelId: String,
         statInfo: MessageListStatInfo,
         instanceCode: String) {
        EmlPreviewTrackSource.localFile.track()

        super.init(accountContext: accountContext,
                   dataSource: dataSource,
                   threadId: threadId,
                   labelId: labelId,
                   statInfo: statInfo,
                   viewModelConfig: { (render, info) in

            EmlPreviewViewModel(shitThreadID: threadId,
                                fileSource: .approval(instanceCode),
                                templateRender: render,
                                forwardInfo: info,
                                sharedServices: accountContext.sharedServices)
        }, externalDelegate: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if statInfo.from == .emailReview {
            // 邮件审核场景，打点
            MailTracker.log(event: "email_mail_audit_mail_content_view", params: nil)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func driveEmlPreview(accountContext: MailAccountContext, fileToken: String, name: String, fileSize: Int64, isLarge: Bool, needBanner: Bool) -> EmlPreviewViewController {
        let threadID = EmlPreviewViewModel.genShitThreadID()
        let info = MessageListStatInfo(from: .emlPreview, newCoreEventLabelItem: Mail_LabelId_Unknow)
        let vm = MailMessageListPageViewModel(accountContext: accountContext, threadId: threadID, labelId: EmlPreviewViewModel.fakeLabelId, isFlag: false, needBanner: needBanner)

        return EmlPreviewViewController(accountContext: accountContext,
                                        driveFile: [vm],
                                        threadId: threadID,
                                        labelId: EmlPreviewViewModel.fakeLabelId,
                                        statInfo: info,
                                        fileToken: fileToken,
                                        name: name,
                                        fileSize: fileSize,
                                        isLarge: isLarge)
    }

    static func localEmlPreview(accountContext: MailAccountContext, localPath: URL) -> EmlPreviewViewController {
        let threadID = EmlPreviewViewModel.genShitThreadID()
        let info = MessageListStatInfo(from: .emlPreview, newCoreEventLabelItem: Mail_LabelId_Unknow)
        let vm = MailMessageListPageViewModel(accountContext: accountContext, threadId: threadID, labelId: EmlPreviewViewModel.fakeLabelId, isFlag: false)

        return EmlPreviewViewController(accountContext: accountContext,
                                        localEml: [vm],
                                        threadId: threadID,
                                        labelId: EmlPreviewViewModel.fakeLabelId,
                                        statInfo: info,
                                        localEmlPath: localPath)
    }

    static func approvalReview(accountContext: MailAccountContext, instanceCode: String) -> EmlPreviewViewController {
        let threadID = EmlPreviewViewModel.genShitThreadID()
        let info = MessageListStatInfo(from: .emailReview, newCoreEventLabelItem: Mail_LabelId_Unknow)
        let vm = MailMessageListPageViewModel(accountContext: accountContext, threadId: threadID, labelId: EmlPreviewViewModel.fakeLabelId, isFlag: false)
        return EmlPreviewViewController(accountContext: accountContext,
                                        localEml: [vm],
                                        threadId: threadID,
                                        labelId: EmlPreviewViewModel.fakeLabelId,
                                        statInfo: info,
                                        instanceCode: instanceCode)
    }

    static func emlPreviewFromIM(accountContext: MailAccountContext, provider: EMLFileProvider) -> EmlPreviewViewController {
        let threadID = EmlPreviewViewModel.genShitThreadID()
        let info = MessageListStatInfo(from: .imFile, newCoreEventLabelItem: Mail_LabelId_Unknow)
        let vm = MailMessageListPageViewModel(accountContext: accountContext, threadId: threadID, labelId: EmlPreviewViewModel.fakeLabelId, isFlag: false)
        return EmlPreviewViewController(accountContext: accountContext,
                                        provider: provider,
                                        dataSource: [vm],
                                        threadId: threadID,
                                        labelId: EmlPreviewViewModel.fakeLabelId,
                                        statInfo: info)
    }

    override func hideFlagButton() -> Bool {
        return true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func checkNeedDismissSelf(newMailItem: MailItem) -> Bool {
        false
    }

    /// 点击用户头像没反应.
    override func onAvatarClicked(args: [String: Any], in webView: WKWebView?) { }

    /// iPad 不显示分屏按钮.
    override func shouldDisplaySceneButton() -> Bool {
        false
    }

    /// EML读信不展示底部操作栏
    override func bottomActionItemsFor(_ idx: Int) -> [MailActionItem] {
        return []
    }

    override func getRightNavActionItems(mailItem: MailItem) -> [TitleNaviBarItem] {
        return []
    }
}

enum EmlPreviewTrackSource {
    case localFile
    case attachment
}

extension EmlPreviewTrackSource {
    func toString() -> String {
        switch self {
        case .localFile:
            return "local_file"
        case .attachment:
            return "eml_attachment"
        }
    }

    func track() {
        let newEvent = NewCoreEvent(event: .email_message_list_view)
        newEvent.params = ["open_type": self.toString(),
                           "mail_service_type": Store.settingData.getMailAccountListType()]

        newEvent.post()
    }
}
