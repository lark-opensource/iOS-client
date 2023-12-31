//
//  GroupedExternalContactsViewModel.swift
//  LarkContact
//
//  Created by zhenning on 2021/03/20.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import LarkModel
import LarkUIKit
import LarkContainer
import LKCommonsLogging
import LarkSDKInterface
import ThreadSafeDataStructure
import LarkFeatureGating
import LarkAccountInterface
import LarkMessengerInterface
import RustPB
import LarkLocalizations

final class GroupedExternalContactsViewModel: UserResolverWrapper {
    private static let logger = Logger.log(GroupedExternalContactsViewModel.self, category: "ExternalContacts")

    private let externalContactsAPI: ExternalContactsAPI
    var externalInviteEnable: Bool {
        return userResolver.fg.staticFeatureGatingValue(with: "invite.union.enable")
            && userResolver.fg.staticFeatureGatingValue(with: "invite.external.enable")
    }

    private let disposeBag = DisposeBag()
    // 分组后的
    private var datasource: [ContactsGroupInfo] = [] {
        didSet {
            self.datasourceSubject.onNext(datasource)
        }
    }
    // 首次加载本地数据是否完成
    private(set) var localRequestFinished: Bool = false
    // 首次加载服务端数据是否完成
    private(set) var serverRequestFinished: Bool = false

    private var allContactData: [ContactInfo] = [] {
        didSet {
            self.allGroupedContactData = self.handleContactInfosIntoSortedGroups(contactInfos: allContactData)
        }
    }

    // 特殊语种下不分组
    var diableGroup: Bool {
        let enableGroup = LanguageManager.currentLanguage == .zh_CN || LanguageManager.currentLanguage == .en_US
        return !enableGroup
    }

    private var allGroupedContactData: [ContactsGroupInfo] = []

    private let datasourceSubject = BehaviorSubject<[ContactsGroupInfo]>(value: [])
    private var isLoading = false

    var datasourceObservable: Observable<[ContactsGroupInfo]> {
        // 跳过默认值
        return datasourceSubject.skip(1).asObservable().observeOn(MainScheduler.instance)
    }
    private let pushDriver: Driver<PushNewExternalContacts>
    private let passportUserService: PassportUserService
    private var inviteService: UnifiedInvitationService
    @ScopedInjectedLazy private var chatterAPI: ChatterAPI?

    var isCurrentAccountInfoSimple: Bool {
        return passportUserService.user.type == .simple
    }
    var hasInviteEntry: Bool {
        return inviteService.hasExternalContactInviteEntry()
    }

    private var apprecibleTrackFlag = true
    var userResolver: LarkContainer.UserResolver

    init(externalContactsAPI: ExternalContactsAPI,
         pushDriver: Driver<PushNewExternalContacts>,
         resolver: UserResolver) throws {
        self.externalContactsAPI = externalContactsAPI
        self.pushDriver = pushDriver
        self.userResolver = resolver
        self.passportUserService = try resolver.resolve(assert: PassportUserService.self)
        self.inviteService = try resolver.resolve(assert: UnifiedInvitationService.self)
    }

    /// 1. preload all data in cache
    /// @params strategy: 拉取策略，支持本地local和server
    /// @params ignoreLoading: 是否忽略loading拦截
    func loadData() {
        // fetch for server
        fetchNewExternalData(strategy: .forceServer, ignoreLoading: true)
        // fetch SDK data first
        fetchNewExternalData(strategy: .local, ignoreLoading: true)
    }

    // loading策略：默认开始loading
    // 1.1 server 先到 - server接口成功 - 隐藏loading，显示空提示页
    // 1.2 server 先到 - server接口报错 - 隐藏loading，显示报错
    // 2.  local 先到 - local接口成功，并有数据 - 隐藏loading，并显示
    // 3.  其他，不处理
    func fetchNewExternalData(strategy: RustPB.Basic_V1_SyncDataStrategy,
                                   ignoreLoading: Bool = false) {
        GroupedExternalContactsViewModel.logger.debug("get Grouped ExternalContacts",
                                                  additionalData: [
                                                    "isServer": "\(strategy == .forceServer)",
                                                    "ignoreLoading": "\(ignoreLoading)"
                                                  ])

        if isLoading && (!ignoreLoading) { return }
        isLoading = true
        Tracer.trackStartExternalFetchTimingMs()
        let disposeKey = Tracer.trackStartAppReciableExternalFetchTimingMs()
        let startTime = CACurrentMediaTime()
        // 请求API
        self.externalContactsAPI.getNewExternalContactList(strategy: strategy, offset: nil, limitCount: nil)
            .subscribe(onNext: { [weak self] newExternalContacts in
                guard let self = self else { return }
                var shouldReloadData: Bool = false
                // 更新请求状态
                switch strategy {
                case .forceServer:
                    self.serverRequestFinished = true
                    // 如果server请求成功，需要刷新数据
                    shouldReloadData = true
                case .local:
                    self.localRequestFinished = true
                    // 如果server还未返回,local先请求成功，local数据不为空，则刷新
                    if !self.serverRequestFinished,
                       !newExternalContacts.contactInfos.isEmpty {
                        shouldReloadData = true
                    }
                @unknown default: break
                }

                self.allContactData = newExternalContacts.contactInfos
                if shouldReloadData {
                    // transform into group data
                    self.datasource = self.allGroupedContactData
                }
                self.tryToTrackAppreciblePoint(cost: CACurrentMediaTime() - startTime,
                                               memberCount: self.datasource.count)
                Tracer.trackFetchExternalUserCount(count: self.allContactData.count)
                GroupedExternalContactsViewModel.logger.debug("获取 contact 成功",
                                                          additionalData: [
                                                            "allContactData count": "\(self.allContactData.count)",
                                                            "isServer": "\(strategy == .forceServer)"
                                                          ])
                Tracer.trackEndExternalFetchTimingMs()
                Tracer.trackEndAppReciableExternalFetchTimingMs(disposeKey: disposeKey)
                }, onError: { [weak self] (error) in
                    guard let self = self else { return }

                    // 更新请求状态
                    switch strategy {
                    case .forceServer:
                        self.serverRequestFinished = true
                        // server接口报错, 如果本地还未完成 / 数据为空，隐藏loading，显示报错
                        if !self.localRequestFinished || self.allContactData.isEmpty {
                            self.datasourceSubject.onError(error)
                        }
                    case .local:
                        self.localRequestFinished = true
                        // local接口报错, 等server处理
                    @unknown default: break
                    }

                    if let error = error.underlyingError as? APIError {
                        Tracer.trackFetchExternalFailed(errorCode: error.code, errorMsg: error.debugDescription)
                        ExternalContactsAppReciableTrack.externalContactsPageError(isNewPage: true, errorCode: Int(error.code))
                    } else {
                        ExternalContactsAppReciableTrack.externalContactsPageError(isNewPage: true,
                                                                   errorCode: (error as NSError).code,
                                                                   errorMessage: (error as NSError).localizedDescription)
                    }
                    GroupedExternalContactsViewModel.logger.error("拉取外部联系人失败",
                                                              additionalData: [
                                                                "localRequestFinished": "\(self.localRequestFinished)",
                                                                "serverRequestFinished": "\(self.serverRequestFinished)"],
                                                              error: error)
                    Tracer.trackEndExternalFetchTimingMs()
            }).disposed(by: self.disposeBag)
    }

    // 监听推送
    func observePushData() {
        pushDriver
            .drive(onNext: { [weak self] (push) in
                guard let self = self else { return }
                var tmpAllContacts = self.allContactData
                // update datasouce
                push.contactPushInfos.forEach { (contactPushInfo) in
                    let contactInfo = contactPushInfo.contactInfo
                    if let index = tmpAllContacts.firstIndex(where: {
                        $0.userID == contactInfo.userID
                    }) {
                        if contactPushInfo.isDeleted {
                            tmpAllContacts.remove(at: index)
                        } else {
                            tmpAllContacts[index] = contactInfo
                        }
                    } else if !contactPushInfo.isDeleted {
                        // 添加联系人
                        if self.diableGroup {
                            // 特殊语种插入到队列前面
                            tmpAllContacts.insert(contactInfo, at: 0)
                        } else {
                            // 添加后重新排序
                            tmpAllContacts.append(contactInfo)
                        }
                    }
                }
                self.allContactData = tmpAllContacts
                self.datasource = self.allGroupedContactData
                let pushUserId = push.contactPushInfos.first?.contactInfo.userID ?? ""
                let isPushUserDeleted: Bool = push.contactPushInfos.first?.isDeleted ?? false
                GroupedExternalContactsViewModel.logger.debug("new externals push",
                                                          additionalData: [
                                                            "pushUserId": "\(pushUserId)",
                                                            "isPushUserDeleted": "\(isPushUserDeleted)"
                                                          ])
            }).disposed(by: disposeBag)
        // 星标联系人状态时，及时更新星标
        chatterAPI?.pushFocusChatter
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] msg in
                guard let self = self else { return }
                var tmpAllContacts = self.allContactData
                let updateSpecialFocus = { (isSpecialFocus: Bool) in
                    return { (id: String) in
                        guard let index = tmpAllContacts.firstIndex(where: { $0.userID == id }) else { return }
                        var contactInfo = tmpAllContacts[index]
                        contactInfo.isSpecialFocus = isSpecialFocus
                        tmpAllContacts[index] = contactInfo
                    }
                }
                msg.deleteChatterIds.forEach(updateSpecialFocus(false))
                msg.addChatters.map { $0.id }.forEach(updateSpecialFocus(true))
                self.allContactData = tmpAllContacts
                self.datasource = self.allGroupedContactData
            }).disposed(by: disposeBag)
    }

    func removeData(deleteContactInfo: ContactInfo) {
        let userID = deleteContactInfo.userID
        let disposeKey = Tracer.trackStartAppReciableDeleteExternal()
        self.externalContactsAPI
            .deleteContact(userId: userID)
            .subscribe(onNext: { _ in
                Tracer.trackDeleteExternalSuccess()
                Tracer.trackEndAppReciableDeleteExternal(disposeKey: disposeKey)
            }, onError: { (error) in
                Tracer.trackEndAppReciableDeleteExternal(disposeKey: disposeKey)
                if let error = error.underlyingError as? APIError {
                    Tracer.trackDeleteExternalFailed(errorCode: error.code, errorMsg: error.debugDescription)
                }
                GroupedExternalContactsViewModel.logger.error("删除好友失败 userID = \(userID)", error: error)
            }).disposed(by: self.disposeBag)
    }
}

// MARK: - Sort Name Pinyin
extension GroupedExternalContactsViewModel {
    // 排序类型
    enum ContactNameSortType {
        // 内容为空
        case null
        // 空格
        case blank
        // 26个字母顺序
        case a2z(Character)
        // 数字排序
        case number(Int)
        // 特殊字符（除以上字符外的其他字符）
        case specialChar

        // init
        init(rawValue: Character?) {
            if let rawValue = rawValue {
                if rawValue == " " {
                    self = .blank
                } else if let number = Int(String(rawValue)) {
                    self = .number(number)
                } else if rawValue >= "A" && rawValue <= "z" {
                    self = .a2z(rawValue)
                } else {
                    self = .specialChar
                }
            } else {
                self = .null
            }
        }
    }

    // 排序结果
    enum CompareTypeResult {
        case equal
        // [1,2]
        case forward
        // [2,1]
        case backward
    }

    /// 名字拼音排序.返回顺序是否是A>B
    // 先按首字母分组，每组内字符优先级：内容为空 > 空格 > 26个字母顺序 > 数字排序 > 特殊字符（除以上字符外的其他字符）；
    private func sortContactsByNamePy(contactA: ContactInfo, contactB: ContactInfo) -> Bool {
        // 默认正序 A > B
        var isOrderAB = true
        // 统一处理小写
        let namePyA = contactA.namePy.lowercased()
        let namePyB = contactB.namePy.lowercased()
        var sortTypesA = transformNamePyToSortTypes(namePy: namePyA)
        var sortTypesB = transformNamePyToSortTypes(namePy: namePyB)

        let maxCount = max(sortTypesA.count, sortTypesB.count)
        let nullType = ContactNameSortType.null
        for _ in 0..<(maxCount - sortTypesA.count) {
            sortTypesA.append(nullType)
        }
        for _ in 0..<(maxCount - sortTypesB.count) {
            sortTypesB.append(nullType)
        }

        guard sortTypesA.count == sortTypesB.count else {
            return true
        }
        let ocSortTypeResult = sortTypesA as NSArray
        ocSortTypeResult.enumerateObjects { (_typeA, idx, stop) in
            guard let typeA = _typeA as? ContactNameSortType else {
                Self.logger.error("typeA is not ContactNameSortType! _typeA = \(_typeA)")
                return
            }
            let typeB = sortTypesB[idx]
            let compareTypeResult = compareCharTypes(typeA: typeA, typeB: typeB)
            Self.logger.debug("[UGDebug]: name sort compareTypeResult = \(compareTypeResult)")
            if case .backward = compareTypeResult {
                // 逆序
                isOrderAB = false
                stop.pointee = true
                return
            } else if case .forward = compareTypeResult {
                stop.pointee = true
                return
            }
            // 前面未return情况: 排序结果是equal
            // 遍历到末尾，都是一样的, 则比较agreeTime, 越大越靠前
            if idx == ocSortTypeResult.count - 1,
               contactA.agreeTime < contactB.agreeTime {
                isOrderAB = false
            }
        }

        Self.logger.debug("[UGDebug]: name sort isOrderAB = \(isOrderAB), namePyA = \(namePyA), namePyB = \(namePyB)")
        return isOrderAB
    }

    /// 比较两个字符的优先级, 返回值CompareTypeResult
    /// 字符优先级：内容为空 > 空格 > 26个字母顺序 > 数字排序 > 特殊字符（除以上字符外的其他字符）；
    /// 两个字符串内字符优先级完全相同情况下，则按照指定排序规则进行排序（当前排序规则为按照成为好友时间倒序）。
    private func compareCharTypes(typeA: ContactNameSortType, typeB: ContactNameSortType) -> CompareTypeResult {
        // default typeA == typeB
        var compareType: CompareTypeResult = .equal
        switch typeA {
        case .null:
            if case .null = typeB {
                compareType = .equal
            } else {
                compareType = .forward
            }
        case .blank:
            if case .null = typeB {
                compareType = .backward
            } else if case .blank = typeB {
                compareType = .equal
            } else {
                compareType = .forward
            }
        case let .a2z(letterA):
            switch typeB {
            case .null, .blank:
                compareType = .backward
            case let .a2z(letterB):
                let lA = letterA.lowercased()
                let lB = letterB.lowercased()
                // 越小越靠前
                if lA < lB {
                    compareType = .forward
                } else if lA > lB {
                    compareType = .backward
                } else {
                    compareType = .equal
                }
            case .number, .specialChar:
                compareType = .forward
            }
        case let .number(numA):
            switch typeB {
            case .null, .blank, .a2z:
                compareType = .backward
            case let .number(numB):
                // 越小越靠前 a-z > 0 > ... > 9
                if numA < numB {
                    compareType = .forward
                } else if numA > numB {
                    compareType = .backward
                } else {
                    compareType = .equal
                }
            case .specialChar:
                compareType = .forward
            }
        case .specialChar:
            // typeB不为specialChar
            if case .specialChar = typeB { } else {
                compareType = .backward
            }
        }
        Self.logger.debug("[UGDebug]: name sort compareType = \(compareType)")
        return compareType
    }

    // 转换名字拼音成为排序类型
    private func transformNamePyToSortTypes(namePy: String) -> [ContactNameSortType] {
        var sortTypes: [ContactNameSortType] = []
        namePy.forEach {
            let sortType = ContactNameSortType(rawValue: $0)
            sortTypes.append(sortType)
        }
        return sortTypes
    }

    /// 名字拼音排序
    // 1. 按照英文字母对字符串进行排序，中文字符首先会转换为拼音，再按照英文字母排序，多个中文字符的拼音以空格分隔；
    // 2. 所有大写字母均转换为小写字母；
    // 3. 先按首字母分组，每组内字符优先级：内容为空 > 空格 > 26个字母顺序 > 数字排序 > 特殊字符（除以上字符外的其他字符）；
    // 4. 数字、特殊字符内部无优先级；
    // 5. 两个字符串内字符优先级完全相同情况下，则按照指定排序规则进行排序（当前排序规则为按照成为好友时间倒序）。
    private func handleContactInfosIntoSortedGroups(contactInfos: [ContactInfo]) -> [ContactsGroupInfo] {
        guard !self.diableGroup else {
            // 不分组case
            let onlyOneGroup = ContactsGroupInfo(groupTitle: "", contacts: contactInfos)
            return [onlyOneGroup]
        }

        var groupedContact: [ContactsGroupInfo] = []
        // 除去空&特殊字符
        let validContactInfos = contactInfos.filter { ((!$0.namePy.isEmpty) && isCharFromAToZ(char: $0.namePy.first)) }
        let validContactGroupInfo = Dictionary(grouping: validContactInfos, by: {
            ($0.namePy.first.flatMap(String.init) ?? "").uppercased()
        })
        // A~Z
        let contactNameFirstLetters = validContactGroupInfo.keys.compactMap { $0 }.sorted(by: <)
        contactNameFirstLetters.forEach {
            if var contacts = validContactGroupInfo[$0] {
                contacts.sort(by: { (contactA, contactB) -> Bool in
                    return sortContactsByNamePy(contactA: contactA, contactB: contactB)
                })
                let info = ContactsGroupInfo(groupTitle: String($0), contacts: contacts)
                groupedContact.append(info)
            }
        }

        // 处理空的
        var _contactInfos = contactInfos
        let emptyNameContactInfos = contactInfos.filter { $0.namePy.isEmpty }
        // 移除空的
        _contactInfos.lf_removeObjectsInArray(emptyNameContactInfos)
        // 处理特殊字符
        let specialNameContactInfos = _contactInfos.filter { !isCharFromAToZ(char: $0.namePy.first) }
        // #:空/特殊字符
        var otherGroup: [ContactInfo] = emptyNameContactInfos + specialNameContactInfos
        if !otherGroup.isEmpty {
            // 对#分组进行排序
            otherGroup.sort(by: { (contactA, contactB) -> Bool in
                return sortContactsByNamePy(contactA: contactA, contactB: contactB)
            })
            groupedContact.append(ContactsGroupInfo(groupTitle: "#", contacts: otherGroup))
        }
        contactInfos.forEach {
            if $0.namePy.isEmpty {
                Self.logger.error("contactInfos 存在空的! \($0.userID + "_" + $0.userName)")
            }
        }
        Self.logger.debug("[UGDebug]: name sort souremptyNameContactInfosce = \(emptyNameContactInfos)")
        return groupedContact
    }

    private func isCharFromAToZ(char: Character?) -> Bool {
        guard let char = char else {
            return false
        }
        return char >= "A" && char <= "z"
    }

    private func tryToTrackAppreciblePoint(cost: CFTimeInterval, memberCount: Int) {
        guard apprecibleTrackFlag else { return }
        apprecibleTrackFlag = false
        ExternalContactsAppReciableTrack.updateExternalContactsPageTrackData(sdkCost: cost, memberCount: memberCount)
        ExternalContactsAppReciableTrack.externalContactsPageLoadingTimeEnd()
    }
}
