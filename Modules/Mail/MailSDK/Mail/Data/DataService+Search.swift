//
//  DataService+Search.swift
//  MailSDK
//
//  Created by tefeng liu on 2021/9/24.
//

import Foundation
import RustPB
import RxSwift
import LarkModel

struct MailRemoteSearchResponse {
    let vms: [MailSearchResultCellViewModel]
    var hasMore: Bool
    let nextBegin: Int64
    var containTrashOrSpam: Bool = false
    var searchSession: String = ""
    var state: Email_Client_V1_MixedSearchState = .abort
}

extension DataService {

    func simpleRemoteSearch(keyword: String,
                            searchSession: String,
                            begin: Int64,
                            isOffline: Bool) -> Observable<Email_Client_V1_MailSimpleSearchResponse> {
        var request = Email_Client_V1_MailSimpleSearchRequest()
        request.keyword = keyword
        request.searchSession = searchSession
        request.begin = begin
        request.isOffline = isOffline

        return sendAsyncRequest(request)
    }

    private func advancedSearch(keyword: String, filters: [MailSearchFilter], searchSession: String, isOffline: Bool, pageSize: Int64 = 10, fromLabel: String = Mail_LabelId_SEARCH_TRASH_AND_SPAM) -> Observable<Email_Client_V1_MailAdvancedSearchResponse> {
        MailLogger.info("[mail_search] data-request advancedSearch keyword: \(keyword.hashValue) filter: \(filters.count) fromLabel: \(fromLabel)")
        var request = Email_Client_V1_MailAdvancedSearchRequest()
        if !keyword.isEmpty {
            request.keyword = keyword
        }
        if !searchSession.isEmpty {
            request.searchSession = searchSession
        }
        request.offset = UInt64(pageSize)
        request.isOffline = isOffline
        request.startDate = 0
        for filter in filters {
            switch filter {
            case .general(let generalFilter):
                switch generalFilter {
                case let .multiple(lInfo, _):
                    if case let .general(.multiple(rInfo, _)) = filter {
                        break
                    }
                case let .single(lInfo, _):
                    if case let .general(.single(rInfo, _)) = filter {
                        switch rInfo {
                        case .labels(let labelModel):
                            if let label = labelModel {
                                request.label = label.labelId
                            }
                        case .folders(let folderModel):
                            if let folder = folderModel {
                                request.folder = folder.labelId
                            }
                        case .hasAttach(_):
                            request.hasAttachment_p = true
                        default: break
                        }
                    }
                case let .date(lInfo, _):
                    if case let .general(.date(rInfo, _)) = filter {
                        break
                    }
                case let .mailUser(lInfo, pickers):
                    switch lInfo {
                    case .fromSender:
                        request.fromList = converPickerItemToAddress(pickers)
                    case .toSender:
                        request.toList = converPickerItemToAddress(pickers)
                    default: break
                    }
                case let .inputTextFilter(lInfo, stringList):
                    if case let .general(.inputTextFilter(rInfo, _)) = filter {
                        switch rInfo {
                        case .subjectText(_):
                            request.subjectList = stringList
                        case .notContain(_):
                            request.excludedKeywordList = stringList
                        default: break
                        }
                    }
                }
            case .date(let date, let source):
                request.startDate = Int64(date?.startDate?.timeIntervalSince1970 ?? 0) * 1000
                request.endDate = Int64(date?.endDate?.timeIntervalSince1970 ?? 0) * 1000
            }
        }

        if fromLabel == Mail_LabelId_SEARCH_TRASH_AND_SPAM {
            request.searchScene = .searchTrashAndSpam
        } else {
            request.searchScene = .defaultVersion2
        }
//        request.hasAttachment_p = true
        return sendAsyncRequest(request)
    }

    func converPickerItemToAddress(_ pickers: [LarkModel.PickerItem]) -> [String] {
        var address: [String] = []
        for picker in pickers {
            switch picker.meta {
            case .chat(let chatMate):
                if let chatAddress = chatMate.enterpriseMailAddress {
                    address.append(chatAddress)
                }
            case .chatter(let chatterMate):
                if let chatterAddress = chatterMate.enterpriseMailAddress {
                    address.append(chatterAddress)
                } else if let chatterMail = chatterMate.email {
                    address.append(chatterMail)
                }
            case .mailUser(let mailUserMate):
                if let mailAddress = mailUserMate.mailAddress {
                    address.append(mailAddress)
                }
            default: break
            }
        }
        return address
    }

    func remoteSearch(keyword: String, filters: [MailSearchFilter],
                      searchSession: String, begin: Int64,
                      isOffline: Bool, fromLabel: String, pageSize: Int64 = 10) -> Observable<MailRemoteSearchResponse> {
        if (FeatureManager.open(.searchTrashSpam, openInMailClient: true) && !isOffline) ||
            (FeatureManager.open(.searchFilter, openInMailClient: false) && !filters.isEmpty) {
            var lastResp: Email_Client_V1_MailAdvancedSearchResponse?
            let needBlockTrashAndSpam = {
                if let tagID = filters.first(where: { $0.tagID != nil })?.tagID {
                    return tagID != Mail_FolderId_Root
                } else {
                    return false
                }
            }()
            return advancedSearch(keyword: keyword, filters: filters, searchSession: searchSession,
                                  isOffline: isOffline, pageSize: pageSize, fromLabel: fromLabel)
                .flatMap({ [weak self] (res) -> Observable<Email_Client_V1_MailAdvancedSearchResponse> in
                    if res.hasMore_p || fromLabel == Mail_LabelId_SEARCH_TRASH_AND_SPAM {
                        return Observable.just(res)
                    } else {
                        /// 最后一页普通邮件的请求完毕后，需要发起last req检查是否包含已删除和垃圾邮件
                        MailLogger.info("[mail_search] data-request last req hasMore: \(res.hasMore_p) msgCount: \(res.msgSummary.count) fromLabel: \(fromLabel)")
                        lastResp = res
                        return self?.advancedSearch(keyword: keyword, filters: filters, searchSession: "", isOffline: isOffline) ?? .empty()
                    }
                })
                .map({ (res) -> Email_Client_V1_MailAdvancedSearchResponse in /// 合并请求回调数据
                    if let lastResp = lastResp {
                        var resp = Email_Client_V1_MailAdvancedSearchResponse()
                        resp.msgSummary = lastResp.msgSummary
                        resp.hasMore_p = !res.msgSummary.isEmpty && !needBlockTrashAndSpam // 代表包含更多搜索结果（trash or spam）
                        MailLogger.info("[mail_search] data-request combine data, mark trash or spam flag, hasMore: \(res.hasMore_p) res.msgSummary: \(res.msgSummary.count)")
                        return resp // Observable.just(resp)
                    } else {
                        return res // Observable.just(res)
                    }
                })
                .map({ (response) -> MailRemoteSearchResponse in
                    var heightlight = keyword.split(separator: " ").map{ return String($0) }
                    var highlightSubject = [String]()
                    if !filters.filter({ $0.needHightLight }).isEmpty {
                        highlightSubject.append(contentsOf: filters.map({ $0.content }))
                    }
                    let vms = response.msgSummary.map({ (summary) -> MailSearchResultCellViewModel in
                        let inCustomFolder = !summary.folder.isEmpty
                        var folders = inCustomFolder ? [summary.folder] : summary.labels
                        if !inCustomFolder {
                            folders.append(summary.folder)
                        }
                        if let setting = Store.settingData.getCachedCurrentAccount()?.mailSetting,
                           fromLabel == Mail_LabelId_SEARCH_TRASH_AND_SPAM,
                           setting.enableConversationMode {
                            folders = summary.messageLabels
                        }
                        // label颜色过滤
                        var filteredLabels = MailTagDataManager.shared.getTagModels(summary.labels).filter({ $0.modelType == .label })
                        filteredLabels = filteredLabels.map({ label in
                            var newLabel = label
                            let config = MailLabelTransformer.transformLabelColor(backgroundColor: label.bgColor)
                            newLabel.fontColor = config.fontToHex(alwaysLight: false)
                            newLabel.bgColor = config.bgToHex(alwaysLight: false)
                            newLabel.colorType = config.colorType
                            return newLabel
                        })
                        let vm = MailSearchResultCellViewModel(threadId: summary.threadID,
                                                               messageId: summary.messageID,
                                                               from: summary.from,
                                                               msgSummary: summary.bodyPlaintextSummary,
                                                               subject: summary.subjectSummary,
                                                               createTimestamp: summary.createdTimestamp,
                                                               lastMessageTimestamp: summary.lastMessageTimestamp,
                                                               highlightString: heightlight,
                                                               highlightSubject: highlightSubject,
                                                               replyTagType: summary.displayReplyType,
                                                               hasDraft: summary.hasDraft_p,
                                                               priorityType: summary.messageLabels.toMailPriorityType(),
                                                               msgNum: Int(summary.messageCount),
                                                               messageIds: summary.messageIds,
                                                               labels: filteredLabels,
                                                               fullLabels: summary.labels,
                                                               isFlagged: summary.labels.contains(Mail_LabelId_FLAGGED),
                                                               isExternal: summary.isExternal,
                                                               senderAddresses: [summary.from],
                                                               folders: folders,
                                                               headFroms: summary.allHeaderfroms,
                                                               unauthorizedHeadFroms: summary.unauthorizedHeaderfroms,
                                                               currentLabelID: fromLabel,
                                                               addressList: summary.addressList)
                        vm.isRead = !summary.labels.contains(Mail_LabelId_UNREAD)
                        vm.hasAttachment = summary.hasAttachment_p
                        vm.attachmentNameList = summary.attachmentNameList
                        if !summary.attachmentNameList.isEmpty,
                           let targetAttachmentTitle = summary.attachmentNameList.first(where: { $0.contains(keyword) }) {
                            vm.msgSummary = targetAttachmentTitle
                        }
//                        vm.delegate = self
                        return vm
                    })
                    var resp = MailRemoteSearchResponse(vms: vms, hasMore: response.hasMore_p, nextBegin: begin + Int64(vms.count))
                    if let lastResp = lastResp, response.hasMore_p { // !lastResp.hasMore_p {
                        // contains trash or spam msg in search result
                        MailLogger.info("[mail_search] data-request contains trash or spam msg in search result")
                        resp.containTrashOrSpam = true
                        resp.hasMore = false
                    }
                    MailLogger.info("[mail_search] data-request response count: \(vms.count) nextBegin: \(resp.nextBegin) hasMore: \(resp.hasMore) containTrashOrSpam: \(resp.containTrashOrSpam)")
//                    // mock
//                    resp.containTrashOrSpam = true
                    return resp //Observable.just(resp)
                })
        } else {

            return simpleRemoteSearch(keyword: keyword, searchSession: searchSession, begin: begin, isOffline: isOffline)
                .map({ [weak self] (response) -> MailRemoteSearchResponse in
									self?.simpleSearchRespHandler(keyword: keyword, fromLabel: fromLabel, response: response) ?? MailRemoteSearchResponse(vms: [], hasMore: true, nextBegin: 0)
                })
        }
    }

		private func simpleSearchRespHandler(keyword: String, fromLabel: String, response: Email_Client_V1_MailSimpleSearchResponse) -> MailRemoteSearchResponse {
      let heightlight = keyword.split(separator: " ").map{ return String($0) }
      let vms = response.msgSummary.map({ (summary) -> MailSearchResultCellViewModel in
          let inCustomFolder = !summary.folder.isEmpty
          var folders = inCustomFolder ? [summary.folder] : summary.labels
          if !inCustomFolder {
              folders.append(summary.folder)
          }
          // label颜色过滤
          var filteredLabels = MailTagDataManager.shared.getTagModels(summary.labels).filter({ $0.modelType == .label })
          filteredLabels = filteredLabels.map({ label in
              var newLabel = label
              let config = MailLabelTransformer.transformLabelColor(backgroundColor: label.bgColor)
              newLabel.fontColor = config.fontToHex(alwaysLight: false)
              newLabel.bgColor = config.bgToHex(alwaysLight: false)
              return newLabel
          })
          let vm = MailSearchResultCellViewModel(threadId: summary.threadID,
                                                 messageId: summary.messageID,
                                                 from: summary.from,
                                                 msgSummary: summary.msgSummary,
                                                 subject: summary.subject,
                                                 createTimestamp: summary.createTimestamp,
                                                 lastMessageTimestamp: summary.lastMessageTimestamp,
                                                 highlightString: heightlight,
                                                 highlightSubject: [],
                                                 replyTagType: summary.displayReplyType,
                                                 hasDraft: summary.hasDraft_p,
                                                 priorityType: summary.messageLabels.toMailPriorityType(),
                                                 msgNum: Int(summary.msgNum),
                                                 messageIds: summary.messageIds,
                                                 labels: filteredLabels,
                                                 fullLabels: summary.labels,
                                                 isFlagged: summary.isFlagged,
                                                 isExternal: summary.isExternal,
                                                 senderAddresses: [summary.from],
                                                 folders: folders,
                                                 headFroms: summary.allHeaderfroms,
                                                 unauthorizedHeadFroms: summary.unauthorizedHeaderfroms,
                                                 currentLabelID: fromLabel, addressList:summary.addressList)
          vm.isRead = summary.isRead
          vm.hasAttachment = summary.hasAttachment_p
          vm.attachmentNameList = summary.attachmentNameList
          if !summary.attachmentNameList.isEmpty,
             let targetAttachmentTitle = summary.attachmentNameList.first(where: { $0.contains(keyword) }) {
              vm.msgSummary = targetAttachmentTitle
          }
//                        vm.delegate = self
          return vm
      })
      var resp = MailRemoteSearchResponse(vms: vms, hasMore: response.hasMore_p, nextBegin: response.nextBegin)
//                    // mock
//                    resp.containTrashOrSpam = true
      return resp
		}

    func saveSearchKeyWord(keyword: String) -> Observable<Email_Client_V1_MailSearchHistoryResponse> {
        var request = Email_Client_V1_MailSearchHistoryRequest()
        request.action = .insert
        request.keyword = keyword

        return sendAsyncRequest(request)
    }

    func getSearchHistory() -> Observable<Email_Client_V1_MailSearchHistoryResponse> {
        var request = Email_Client_V1_MailSearchHistoryRequest()
        request.action = .query

        return sendAsyncRequest(request)
    }

    func deleteAllSearchHistory() -> Observable<Email_Client_V1_MailSearchHistoryResponse> {
        var request = Email_Client_V1_MailSearchHistoryRequest()
        request.action = .deleteAll

        return sendAsyncRequest(request)
    }

    func remoteClientSearch(keyword: String,
                            searchSession: String,
                            begin: Int64,
                            strategy: Email_Client_V1_MailMixedSearchRequest.Strategy,
                            debounceInterval: Int64,
                            fromLabel: String) -> Observable<MailRemoteSearchResponse> {
        let labelfilter = fromLabel == Mail_LabelId_SEARCH ? "" : fromLabel
        return clientMixSearch(keyword: keyword, searchSession: searchSession, begin: begin, strategy: strategy, debounceInterval: debounceInterval, label_filter: labelfilter)
            .map({ (response) -> MailRemoteSearchResponse in
                let heightlight = keyword.split(separator: " ").map{ return String($0) }
                let vms = response.msgs.map({ (summary) -> MailSearchResultCellViewModel in
                    let inCustomFolder = !summary.folder.isEmpty
                    var folders = inCustomFolder ? [summary.folder] : summary.labels
                    if !inCustomFolder {
                        folders.append(summary.folder)
                    }
                    // label颜色过滤
                    var filteredLabels = MailTagDataManager.shared.getTagModels(summary.labels).filter({ $0.modelType == .label })
                    filteredLabels = filteredLabels.map({ label in
                        var newLabel = label
                        let config = MailLabelTransformer.transformLabelColor(backgroundColor: label.bgColor)
                        newLabel.fontColor = config.fontToHex(alwaysLight: false)
                        newLabel.bgColor = config.bgToHex(alwaysLight: false)
                        newLabel.colorType = config.colorType
                        return newLabel
                    })
                    let vm = MailSearchResultCellViewModel(threadId: summary.threadID,
                                                           messageId: summary.messageID,
                                                           from: summary.from,
                                                           msgSummary: summary.msgSummary,
                                                           subject: summary.subject,
                                                           createTimestamp: summary.createTimestamp,
                                                           lastMessageTimestamp: summary.lastMessageTimestamp,
                                                           highlightString: heightlight,
                                                           highlightSubject: [],
                                                           replyTagType: summary.displayReplyType,
                                                           hasDraft: summary.hasDraft_p,
                                                           priorityType: summary.messageLabels.toMailPriorityType(),
                                                           msgNum: Int(summary.msgNum),
                                                           messageIds: summary.messageIds,
                                                           labels: filteredLabels,
                                                           fullLabels: summary.labels,
                                                           isFlagged: summary.isFlagged,
                                                           isExternal: summary.isExternal,
                                                           senderAddresses: [summary.from],
                                                           folders: folders,
                                                           headFroms: summary.allHeaderfroms,
                                                           unauthorizedHeadFroms: summary.unauthorizedHeaderfroms,
                                                           currentLabelID: fromLabel, addressList: summary.addressList)
                    vm.isRead = summary.isRead
                    vm.hasAttachment = summary.hasAttachment_p
                    vm.attachmentNameList = summary.attachmentNameList
                    if !summary.attachmentNameList.isEmpty,
                       let targetAttachmentTitle = summary.attachmentNameList.first(where: { $0.contains(keyword) }) {
                        vm.msgSummary = targetAttachmentTitle
                    }
                    return vm
                })
                var resp = MailRemoteSearchResponse(vms: vms, hasMore: response.hasMore_p, nextBegin: response.nextBegin)
                resp.searchSession = response.searchSession
                resp.state = response.state
                return resp
            })
    }

    func clientMixSearch(keyword: String,
                         searchSession: String,
                         begin: Int64,
                         strategy: Email_Client_V1_MailMixedSearchRequest.Strategy,
                         debounceInterval: Int64,
                         label_filter: String = "") -> Observable<Email_Client_V1_MailMixedSearchResponse> {
        var request = Email_Client_V1_MailMixedSearchRequest()
        request.keyword = keyword
        request.searchSession = searchSession
        request.begin = begin
        request.strategy = strategy
        if debounceInterval != -1 { // 默认值-1 默认不设置
            request.debounceInterval = debounceInterval
        }
        if label_filter == Mail_LabelId_SEARCH_TRASH_AND_SPAM {
            request.labelFilter = label_filter
        }
        MailLogger.info("[mail_client_search] clientMixSearch strategy: \(strategy) searchSession: \(searchSession) begin: \(begin) debounceInterval: \(debounceInterval)")
        return sendAsyncRequest(request)
    }
}
