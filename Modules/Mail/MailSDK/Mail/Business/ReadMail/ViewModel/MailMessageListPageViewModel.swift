//
//  MailMessageListViewModel.swift
//  MailSDK
//
//  Created by majx on 2020/3/10.
//

import Foundation
import RustPB
import RxSwift

enum LoadFailType {
    /// 正常加载错误
    case normal
    ///  邮件审核，没权限场景
    case noPermission
    /// 无网加载失败
    case offline
    /// 获取 bot label 错误
    case botLabelError
    /// 获取 bot label 超时
    case botLabelNetworkError
    /// 陌生人卡片特定错误码
    case strangerError
    /// Feed场景加载为空
    case feedEmpty
}

protocol MailMessageListPageVMDelegate: AnyObject {
    func callJavaScript(jsString: String)
    func viewModelMailItemDidChange(viewModel: MailMessageListPageViewModel)
}

/// 代表单个Mail Thread页面的ViewModel
class MailMessageListPageViewModel {
    var feedCardId: String = ""
    var threadId: String
    var labelId: String
    /// notification、bot等场景需要记录具体messageId的读信
    /// 用于 bot 跳转、notification 读信
    let messageId: String?
    var importantContactsAddresses: [String] = []
    var mailItem: MailItem? {
        didSet {
            if let mailItem = mailItem {
                /// if is full read message, remove other messages
                if isFullReadMessage && !(fullReadMessageId?.isEmpty ?? true) {
                    var newMailItem = mailItem
                    newMailItem.messageItems = newMailItem.messageItems.filter {
                        $0.message.id == fullReadMessageId
                    }
                    self.mailItem = newMailItem
                }
                subject = getOldestSubject(messageItems: mailItem.messageItems)
                showLoading = false
                loadErrorType = nil
                let isFeedCard = !self.feedCardId.isEmpty && threadId.isEmpty && self.accountContext.featureManager.open(FeatureKey(fgKey: .mailToFeed, openInMailClient: false))
                if isFeedCard {
                    if mailItem.messageItems.isEmpty {
                        loadErrorType = .feedEmpty
                    }
                }
                labels = mailItem.labels
                isFlag = mailItem.isFlagged
                if originalIsRead == nil {
                    originalIsRead = mailItem.isRead
                }
            }
            if mailItem?.threadId != oldValue?.threadId {
                delegate?.viewModelMailItemDidChange(viewModel: self)
            }
            showLoading = false
            updateCidImageMap()
        }
    }

    // key改为{cid}_msgToken{token},避免thread有重复cid的情况
    var cidImageMap: [String: MailClientDraftImage] = [:]

    var isFullReadMessage: Bool = false
    var fullReadMessageId: String?

    var bodyHtml: String?
    var lastmessageTime: Int64?
    /// 失败类型，若为空，代表没有加载错误
    var loadErrorType: LoadFailType?
    var showLoading: Bool = true
    var displaySubject: String {
        guard let subject = subject else { return "" }
        let joinedSubject = subject.components(separatedBy: .newlines).joined(separator: " ")
        return joinedSubject.isEmpty ? BundleI18n.MailSDK.Mail_ThreadList_TitleEmpty : joinedSubject
    }
    var subject: String?
    var hasBigMessage: Bool {
        guard let mailItem = mailItem else {
            return false
        }
        return mailItem.messageItems.contains(where: { $0.message.isBodyClipped == true })
    }
    var isFlag: Bool
    var labels: [MailClientLabel]?
    var deliveryState: MailClientMessageDeliveryState? = nil

    /// 是否开启首屏优化
    let enableFirstScreenOptimize: Bool
    let imageMonitor = MailMessageListImageMonitor()
    /// 原始已读状态
    var originalIsRead: Bool?
    var keyword = ""
    var subjects: [String] = []

    /// 附件风险标签
    var fileRiskTags: [String: FileRiskTag] = [:]
    /// 附件封禁状态&删除状态
    var fileBannedInfos: [String: FileBannedInfo] = [:]

    var spamMailTip: String {
        mailItem?.spamMailTip ?? ""
    }
    var needBanner: Bool = false
    var messageLabels: [String: String] = [:]

    /// WebView 重复被杀后，进入保护模式，不执行某些前端耗时方法
    var openProtectedMode = false

    let disposeBag = DisposeBag()

    // TODO: @zhaoxiongbin
    weak var delegate: MailMessageListPageVMDelegate?

    private var _mailSubjectCover: MailSubjectCover?
    func mailSubjectCover() -> MailSubjectCover? {
        if let mailItem = mailItem {
            return mailItem.mailSubjectCover()
        } else {
            return _mailSubjectCover
        }
    }

    private let accountContext: MailAccountContext
    
    init(accountContext: MailAccountContext, feedCardId: String) {
        self.accountContext = accountContext
        self.feedCardId = feedCardId
        self.threadId = ""
        self.labelId = ""
        self.messageId = ""
        self.enableFirstScreenOptimize = false
        self.isFlag = false
        self.needBanner = false
        bindPush()
    }

    init(accountContext: MailAccountContext, threadId: String, labelId: String, isFlag: Bool, messageId: String = "", needBanner: Bool = false) {
        self.accountContext = accountContext
        self.threadId = threadId
        self.labelId = labelId
        self.messageId = messageId
        self.enableFirstScreenOptimize = false
        self.isFlag = isFlag
        self.needBanner = needBanner

        bindPush()
    }

    init(accountContext: MailAccountContext, threadModel: MailThreadListCellViewModel, labelId: String) {
        self.accountContext = accountContext
        self.threadId = threadModel.threadID
        self.labelId = labelId
        self.lastmessageTime = threadModel.lastmessageTime
        self.subject = threadModel.title
        self.deliveryState = threadModel.deliveryState
        self.messageId = nil
        self.labels = MailMessageListLabelsFilter.filterLabels(threadModel.readMailDisplayUnsortedLabels,
                                                               atLabelId: threadModel.currentLabelID,
                                                               permission: threadModel.permissionCode,
                                                               useCssColor: false)
        self.isFlag = threadModel.isFlagged
        if accountContext.featureManager.open(.mailCover) {
            self._mailSubjectCover = threadModel.subjectCover
        }
        self.enableFirstScreenOptimize = accountContext.featureManager.open(FeatureKey(fgKey: .readMailFirstScreen, openInMailClient: true)) && MailMessageListTemplateRender.enableNativeRender && !(threadModel.convCount > 3 || (threadModel.subjectCover != nil && threadModel.convCount > 1))
        bindPush()
    }

    init(accountContext: MailAccountContext, searchModel: MailSearchCellViewModel, labelId: String) {
        self.accountContext = accountContext
        self.threadId = searchModel.threadId
        self.subject = searchModel.subject
        self.labelId = labelId
        self.isFlag = searchModel.isFlagged
        self.labels = searchModel.labels
        self.subjects = searchModel.highlightSubject
        self.messageId = nil
        self.enableFirstScreenOptimize = accountContext.featureManager.open(FeatureKey(fgKey: .readMailFirstScreen, openInMailClient: true)) && MailMessageListTemplateRender.enableNativeRender && searchModel.msgNum < 3

        bindPush()
    }

    private func bindPush() {
        // 初始化工作
    }

    private func updateCidImageMap() {
        var map: [String: MailClientDraftImage] = [:]
        if let mailItem = mailItem {
            for messageItem in mailItem.messageItems {
                for image in messageItem.message.images {
                    let key = "\(image.cid)_msgToken\(image.fileToken)"
                    map[key] = image
                }
            }
        }
        cidImageMap = map
    }

    private func getOldestSubject(messageItems: [MailMessageItem]) -> String {
        if messageItems.isEmpty { return "" }
        var oldest: MailMessageItem = messageItems.first!
        for item in messageItems where
            item.message.createdTimestamp <
            oldest.message.createdTimestamp {
                oldest = item
        }
        return oldest.message.subject
    }

    static func getListFromThreadList(_ list: [MailThreadListCellViewModel], accountContext: MailAccountContext, labelId: String) -> [MailMessageListPageViewModel] {
        if list.isEmpty {
            return []
        }
        let newList = list.filter({ (model) -> Bool in
            if model.convCount == 0 || (model.convCount == 1 && (model.draft != nil && !model.draft!.isEmpty)) {
                return false
            }
            return true
        }).map({ (model) -> MailMessageListPageViewModel in
            let viewModel = MailMessageListPageViewModel(accountContext: accountContext, threadModel: model, labelId: labelId)
            return viewModel
        })
        return newList
    }

    static func getListFromSearchList(_ list: [MailSearchCellViewModel], accountContext: MailAccountContext, labelId: String) -> [MailMessageListPageViewModel] {
        if list.isEmpty {
            return []
        }
        let newList = list.map({ (model) -> MailMessageListPageViewModel in
            let viewModel = MailMessageListPageViewModel(accountContext: accountContext, searchModel: model, labelId: labelId)
            return viewModel
        })
        return newList
    }
}
