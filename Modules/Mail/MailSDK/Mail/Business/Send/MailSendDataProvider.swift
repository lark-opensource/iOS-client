//
//  MailMockData.swift
//  LarkMailTokenInputView
//
//  Created by majx on 2019/5/28.
//

import Foundation
import RxSwift
import UIKit
import Reachability
import RustPB
import Homeric

private typealias SearchFilterParam = RustPB.Search_V1_IntegrationSearchRequest.FilterParam
public typealias SearchQueryState = RustPB.Search_V1_IntegrationSearchRequest.QueryState

struct MailSendAddressModel {
    let avatar: String
    let name: String
    // 用于搜索显示的带多语言的名字
    let searchName: String
    let address: String
    let titleHitTerms: [String]
    let emailHitTerms: [String]
    let departmentHitTerms: [String]
    let subtitle: String
    var avatarKey: String?
    var tags: [ContactTagType]?
    var type: ContactType?
    var larkID: String?
    var groupType: MailClientGroupType?
    var tenantID: String?
    var chatGroupMembersCount: Int64?
    var displayName: String?

    init(avatar: String, name: String, searchName: String, address: String, subtitle: String, titleHitTerms: [String], emailHitTerms: [String], departmentHitTerms: [String]) {
        self.avatar = avatar
        self.name = name
        self.searchName = searchName
        self.address = address
        self.subtitle = subtitle
        self.titleHitTerms = titleHitTerms
        self.emailHitTerms = emailHitTerms
        self.departmentHitTerms = departmentHitTerms
    }
}

enum ContactAddType: String {
    case picker
    case contact_search
    case copy_mail_address
    case mail_to
}

enum ContactAddPosition: String {
    case to
    case cc
    case bcc
    case separately
}

enum ContactSearchRequestType: String {
    case keyboard_input
    case copy_input
}

enum ContactSearchFinishType: String {
   case hit
   case abort
}

protocol MailSendDataProvider {
    /// search recommand emaill adresses with key word
    ///
    /// - Parameters:
    ///   - key: key word to search
    var searchKey: String { get set }
    var searchBegin: Int32 { get set }
    var searchPageSize: Int32 { get }    // 默认每页10条数据
    var searchSession: MailSearchSession { get }
    func recommandListWith(key: String, groupEmailAccount: Email_Client_V1_GroupEmailAccount?) -> Observable<(list: [MailSendAddressModel], isRemote: Bool)>
    func recommandListWith(key: String, begin: Int32, end: Int32, groupEmailAccount: Email_Client_V1_GroupEmailAccount?) -> Observable<(list: [MailSendAddressModel], isRemote: Bool)>
    func trackAddMailContact(contactType: ContactType?, contactTag: ContactTagType?, addType: ContactAddType, addPosition: ContactAddPosition)
    func trackDraftContactSearch(event: MailAPMEvent.DraftContactSearch)
    func trackContactSearchRequest(inputType: ContactSearchRequestType, queryId: String, startTime: Int)
    func trachContactSearchResult(queryId: String, resultTime: Int, result: [MailSendAddressModel])
    func trackContactSearchFinish(type: ContactSearchFinishType, resultCount: Int, selectRank: Int, contactVM: MailAddressCellViewModel?, fromAddress: MailAddress?)
    func atRecommandListWith(key: String) -> Observable<(list: [MailSendAddressModel], isRemote: Bool)>
    func atRecommandListWith(key: String, begin: Int32, end: Int32) -> Observable<(list: [MailSendAddressModel], isRemote: Bool)>
    func addressInfoSearch(address: String) -> Observable<MailSendAddressModel?>
    func addressInfoSearchAppend(address: String,
                                 item: MailAddressHelper.AddressItem,
                                 addPosition: ContactAddPosition) -> Observable<(MailSendAddressModel?, MailAddressHelper.AddressItem, ContactAddPosition)>
    func addressInfoSearchAppend(address: String) -> Observable<(MailSendAddressModel?)>
}

class MailSendDataSource: MailSendDataProvider {
    var searchKey: String = ""
    var searchBegin: Int32 = 0
    var searchedText: String = ""
    private var lastSearchedText: String = ""
    let searchPageSize: Int32 = 20
    var searchSession: MailSearchSession = MailSearchSession()
    var searchHitSession: String?
    private var addressListSubject: PublishSubject<(list: [MailSendAddressModel], isRemote: Bool)> = PublishSubject<(list: [MailSendAddressModel], isRemote: Bool)>()
    private var searchBag = DisposeBag()
    private var hasMore: Bool = true
    private var fromLocal: Bool = false

    func recommandListWith(key: String, groupEmailAccount: Email_Client_V1_GroupEmailAccount?) -> Observable<(list: [MailSendAddressModel], isRemote: Bool)> {
        self.hasMore = true
        return newRecommandListWith(key: key, begin: 0, end: 0 + searchPageSize, groupEmailAccount: groupEmailAccount)
    }

    func atRecommandListWith(key: String) -> Observable<(list: [MailSendAddressModel], isRemote: Bool)> {
        self.hasMore = true
        return atRecommandListWith(key: key, begin: 0, end: 0 + searchPageSize)
    }

    func recommandListWith(key: String, begin: Int32, end: Int32, groupEmailAccount: Email_Client_V1_GroupEmailAccount?) -> Observable<(list: [MailSendAddressModel], isRemote: Bool)> {
        return newRecommandListWith(key: key, begin: begin, end: end, groupEmailAccount: groupEmailAccount)
    }

    func trackAddMailContact(contactType: ContactType?, contactTag: ContactTagType?, addType: ContactAddType, addPosition: ContactAddPosition) {
        let event = NewCoreEvent(event: .email_email_edit_click)
        event.params = ["click": "add_mail_contact",
                        "target": "none",
                        "contact_type": genSelectContactType(tag: contactTag),
                        "add_type": addType.rawValue,
                        "add_position": addPosition.rawValue]
        event.post()
    }

    func trackDraftContactSearch(event: MailAPMEvent.DraftContactSearch) {
        let param = fromLocal ? MailAPMEvent.DraftContactSearch.EndParam.from_local_local : MailAPMEvent.DraftContactSearch.EndParam.from_local_network
        event.endParams.append(param)
        event.postEnd()
    }

    func trackContactSearchRequest(inputType: ContactSearchRequestType, queryId: String, startTime: Int) {
        let event = NewCoreEvent(event: .email_search_contact_request_click)
        event.params = ["click": "search_request",
                        "target": "none",
                        "query_id": queryId,
                        "search_session_id": searchSession.session,
                        "input_type": inputType.rawValue,
                        "start_timestamp": startTime]
        event.post()
    }

    func trachContactSearchResult(queryId: String, resultTime: Int, result: [MailSendAddressModel]) {
        let event = NewCoreEvent(event: .email_search_contact_result_view)
        event.params = ["search_session_id": searchSession.session,
                        "query_id": queryId,
                        "is_result": result.count > 0 ? "true" : "false",
                        "result_timestamp": String(resultTime)]
        var chatterCount = 0
        var namecardCount = 0
        var chatGroupCount = 0
        var mailGroupCount = 0
        var sharedCount = 0
        var externalCount = 0
        var noneTypeCount = 0
        var contactTypeList = ""

        for item in result {
            switch item.type {
            case .chatter:
                if chatterCount == 0 {
                    contactTypeList += "inner_contact;"
                }
                chatterCount += 1
            case .nameCard:
                if namecardCount == 0 {
                    contactTypeList += "mail_contact;"
                }
                namecardCount += 1
            case .group:
                if chatGroupCount == 0 {
                    contactTypeList += "chat_group;"
                }
                chatGroupCount += 1
            case .enterpriseMailGroup:
                if mailGroupCount == 0 {
                    contactTypeList += "mail_group;"
                }
                mailGroupCount += 1
            case .sharedMailbox:
                if sharedCount == 0 {
                    contactTypeList += "public_mail_address;"
                }
                sharedCount += 1
            case .externalContact:
                if externalCount == 0 {
                    contactTypeList += "address_history;"
                }
                externalCount += 1
            @unknown default:
                noneTypeCount += 1
                if noneTypeCount == 0 {
                    contactTypeList += "unknown;"
                }
            }
        }
        if contactTypeList.last == ";" {
            contactTypeList = String(contactTypeList.dropLast())
        }
        event.params["contact_type_list"] = contactTypeList
        event.post()
    }

    func trackContactSearchFinish(type: ContactSearchFinishType, resultCount: Int, selectRank: Int, contactVM: MailAddressCellViewModel?, fromAddress: MailAddress?) {
        if type == .hit {
            searchHitSession = searchSession.session
        } else if type == .abort, searchSession.session == searchHitSession {
            /// did track this session when hit
            return
        }
        let startTimestampMs = Int(searchSession.sessionTimeStamp() * 1000)
        let endTimestampMs = Int(Date().timeIntervalSince1970 * 1000)
        let durationMs = endTimestampMs - startTimestampMs
        let languageIdentifer = I18n.currentLanguageIdentifier()
        let event = NewCoreEvent(event: .email_search_contact_result_click)
        event.params = ["click": "finish_search",
                        "target": "none",
                        "search_session_id": searchSession.session,
                        "start_timestamp": startTimestampMs,
                        "end_timestamp": endTimestampMs,
                        "duration_ms": durationMs,
                        "client_language": languageIdentifer,
                        "search_result_count": resultCount]
        if type == .hit {
            event.params["search_finish_type"] = "click_result"
            event.params["select_contact_type"] = genSelectContactType(tag: contactVM?.tags?.first)
            event.params["select_rank"] = selectRank + 1
        } else {
            event.params["search_finish_type"] = resultCount == 0 ? "no_result" : "not_select"
            event.params["select_contact_type"] = "un_select"
            event.params["select_rank"] = 0
        }
        if let vm = contactVM {
            event.params["sender_id"] = ["user_id": fromAddress?.larkID.encriptUtils() ?? "",
                                         "mail_id": fromAddress?.address.lowercased().encriptUtils() ?? "",
                                         "mail_type": (fromAddress?.type ?? .unknown).rawValue]
            if vm.larkID.isEmpty || vm.larkID == "0" {
                event.params["result_id"] = ["user_id": vm.address.lowercased().encriptUtils(),
                                             "mail_id": vm.address.lowercased().encriptUtils(),
                                             "mail_type": (vm.type ?? .unknown).rawValue]
            } else {
                event.params["result_id"] = ["user_id": vm.larkID.encriptUtils(),
                                             "mail_id": vm.address.lowercased().encriptUtils(),
                                             "mail_type": (vm.type ?? .unknown).rawValue]
            }
            event.params["query_id"] = searchKey.encriptUtils()
        }
        event.post()
        searchSession.renewSession()
    }
    func genSelectContactType(tag: ContactTagType?) -> String {
        var selectContactType = "unknown"
        switch tag {
        case .tagChatter:
            selectContactType = "inner_contact"
        case .tagNameCard:
            selectContactType = "mail_contact"
        case .tagChatGroupNormal, .tagChatGroupDepartment,
             .tagChatGroupSuper, .tagChatGroupTenant:
            selectContactType = "chat_group"
        case .tagMailGroup:
            selectContactType = "mail_group"
        case .tagSharedMailbox:
            selectContactType = "public_mail_address"
        case .tagExternalContact:
            selectContactType = "address_history"
        @unknown default:
            break
        }
        return selectContactType
    }
}

// 因为之前的接口有local+remote的混合请求。所以这里最好分开。
// 新版本我们rust层新作的search接口
extension MailSendDataSource {
    /// 新的联系人联想接口
    func newRecommandListWith(key: String, begin: Int32, end: Int32, groupEmailAccount: Email_Client_V1_GroupEmailAccount?) -> Observable<(list: [MailSendAddressModel], isRemote: Bool)> {
        searchBag = DisposeBag()
        guard self.hasMore else {
            return Observable<(list: [MailSendAddressModel], isRemote: Bool)>.create { (observer) -> Disposable in
                observer.onCompleted()
                return Disposables.create()
            }
        }
        guard let service = MailDataServiceFactory.commonDataService else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        searchSession.renewSession()
        let session = searchSession.session
        return service
            .mailContactSearch(query: key, session: session, begin: begin, end: end, groupEmailAccount: groupEmailAccount)
            .map({ [weak self] (results: [Email_Client_V1_MailContactSearchResult], info: ContactSearchInfo) -> (list: [MailSendAddressModel], isRemote: Bool) in
                guard let `self` = self else { return ([], false) }
                let array = self.transformSearchResult(results)
                self.updateSearchInfo(info)
                return (array, true)
            })
    }

    func addressInfoSearch(address: String) -> Observable<MailSendAddressModel?> {
        guard let service = MailDataServiceFactory.commonDataService else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        let session = searchSession.session
        return service
            .mailAddressSearch(address: address, session: session)
            .map({ [weak self] (results: [Email_Client_V1_MailContactSearchResult], info: ContactSearchInfo) -> MailSendAddressModel? in
                guard let `self` = self else { return nil }
                if let item = results.first(where: { result in
                    return result.email.lowercased() == address.lowercased()
                }) {
                    let newItem = self.createAddressModel(result: item)
                    return newItem
                } else {
                    return nil
                }
            })
    }
    func addressInfoSearchAppend(address: String,
                                 item: MailAddressHelper.AddressItem,
                                 addPosition: ContactAddPosition) -> Observable<(MailSendAddressModel?, MailAddressHelper.AddressItem, ContactAddPosition)> {
        addressInfoSearch(address: address).map({ model -> (MailSendAddressModel?, MailAddressHelper.AddressItem, ContactAddPosition) in
            return (model, item, addPosition)
        }).timeout(.milliseconds(1000), scheduler: MainScheduler.instance)
            .catchError { error in
            return Observable.just((nil, item, addPosition))
        }
    }
    func addressInfoSearchAppend(address: String) -> Observable<(MailSendAddressModel?)> {
        let timeoutConst = 1000
        return addressInfoSearch(address: address).map({ model -> (MailSendAddressModel?) in
            return (model)
        }).timeout(.milliseconds(timeoutConst), scheduler: MainScheduler.instance)
            .catchError { error in
            MailLogger.error("addressInfoSearchAppend err \(error)")
            return Observable.just((nil))
        }
    }

    func updateSearchInfo(_ info: ContactSearchInfo) {
        hasMore = info.hasMore
        fromLocal = info.fromLocal
    }

    func transformSearchResult(_ result: [Email_Client_V1_MailContactSearchResult]) -> [MailSendAddressModel] {
        var array = result.map { (item) -> MailSendAddressModel in
            let newItem = createAddressModel(result: item)
            return newItem
        }
        // 过滤掉没有地址且非邮件组or聊天群组
        array = array.filter({ (item) -> Bool in
            let hasAddress = !item.address.isEmpty
            var hasId = false
            if let id = item.larkID, !id.isEmpty, id != "0" {
                hasId = true
            }
            let groupHasId = hasId &&
            (item.type == .group || item.type == .enterpriseMailGroup)
            return hasAddress || groupHasId
        })
        return array
    }

    private func createAddressModel(result item: Email_Client_V1_MailContactSearchResult) -> MailSendAddressModel {
        var avatarUrl = item.avatarUrls.first ?? ""
        if avatarUrl.hasSuffix(".webp") {
            avatarUrl = avatarUrl.replacingOccurrences(of: ".webp", with: ".jpg")
        }
        var newItem = MailSendAddressModel(avatar: avatarUrl, name: item.title, searchName: item.searchName, address: item.email, subtitle: item.subtitle,
                                           titleHitTerms: item.titleHitTerms, emailHitTerms: item.emailHitTerms, departmentHitTerms: item.departmentHitTerms)
        newItem.avatarKey = item.avatarKey
        newItem.type = item.type
        newItem.tags = item.tags
        newItem.larkID = item.larkID
        newItem.tenantID = item.tenantID
        newItem.displayName = item.displayName
        newItem.chatGroupMembersCount = item.chatGroupMembersCount
        return newItem
    }
}

extension MailSendDataSource {
    func atRecommandListWith(key: String, begin: Int32, end: Int32) -> Observable<(list: [MailSendAddressModel], isRemote: Bool)> {
        searchBag = DisposeBag()
        guard self.hasMore else {
            return Observable<(list: [MailSendAddressModel], isRemote: Bool)>.create { (observer) -> Disposable in
                observer.onCompleted()
                return Disposables.create()
            }
        }
        guard let service = MailDataServiceFactory.commonDataService else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        let session = searchSession.session
        return service
            .mailAtContactSearch(keyword: key, session: session)
            .map({ [weak self] (results: [Email_Client_V1_SearchMemberInfo], info: ContactSearchInfo) -> (list: [MailSendAddressModel], isRemote: Bool) in
                guard let `self` = self else { return ([], false) }
                let array = results.map { (item) -> MailSendAddressModel in
                    var avatarUrl = item.avatarUrls.first ?? ""
                    if avatarUrl.hasSuffix(".webp") {
                        avatarUrl = avatarUrl.replacingOccurrences(of: ".webp", with: ".jpg")
                    }
                    // 优先使用name
                    var user_name = item.name
                    if user_name.isEmpty {
                        user_name = item.enName
                        if BundleI18n.currentLanguage == .zh_CN {
                            user_name = item.cnName
                        } 
                        if user_name.isEmpty {
                            user_name = item.cnName
                        }
                    }
                    
                    var newItem = MailSendAddressModel(avatar: avatarUrl, name: user_name, searchName: item.searchName, address: item.emailAddress, subtitle: item.department,
                                                       titleHitTerms: item.titleHitTerms, emailHitTerms: item.emailHitTerms, departmentHitTerms: item.departmentHitTerms)
                    newItem.avatarKey = item.avatarKey
                    newItem.type = ContactType.chatter
                    newItem.larkID = String(item.id) // item.userID String(item.chatID)
                    newItem.tenantID = item.tenantID
                    return newItem
                }
                self.hasMore = info.hasMore
                self.fromLocal = info.fromLocal
                return (array, true)
            })
    }
}
