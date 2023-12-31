//
//  AddrBookContactSubViewModel.swift
//  LarkContact
//
//  Created by mochangxing on 2020/7/14.
//

import Foundation
import RxSwift
import RxCocoa
import LarkSDKInterface
import LarkContainer
import LarkModel
import LarkExtensions
import RustPB

typealias ContactListSectionData = (AddrBookContactSectionHeaderModel, [AddrBookContactCellViewModel])

final class AddrBookContactSubViewModel: UserResolverWrapper {
    static let MAX_LENGHT = 1000
    enum ViewStyle {
        case multiSection
        case singleSection
    }

    enum ViewStatus {
        case reloadData
        case showEmpty
        case showNoMatch
    }

    /// 串行队列
    lazy var serialQueue: DispatchQueue = {
        let queue = DispatchQueue(label: "Lark.Contact.serialQueue")
        return queue
    }()

    var userResolver: LarkContainer.UserResolver
    private var lastSearchWorkItem: DispatchWorkItem?

    let viewStyle: ViewStyle
    private let sectionDataList: [ContactListSectionData]
    private let disPlaySectionsVariable: BehaviorRelay<[ContactListSectionData]>

    var sectionDatas: [ContactListSectionData] {
        return disPlaySectionsVariable.value
    }

    private let userDict: [String: AddrBookContactCellViewModel]

    @ScopedProvider var chatterAPI: ChatterAPI?
    @ScopedProvider var chatApplicationAPI: ChatApplicationAPI?

    var reloadDataDriver: Driver<ViewStatus> {
        return disPlaySectionsVariable.asDriver().map { [weak self] in
            guard let self = self, !self.isEmpty() else {
                return ViewStatus.showEmpty
            }
            return $0.isEmpty ? ViewStatus.showNoMatch : ViewStatus.reloadData
        }
    }

    init(viewStyle: ViewStyle, sectionDataList: [ContactListSectionData], resolver: UserResolver) {
        self.viewStyle = viewStyle
        self.sectionDataList = sectionDataList
        self.userResolver = resolver
        self.disPlaySectionsVariable = BehaviorRelay<[ContactListSectionData]>(value: sectionDataList)
        let flatArray = sectionDataList.reduce([], { $0 + $1.1 })
        var userDict: [String: AddrBookContactCellViewModel] = [:]
        flatArray.forEach { (cellVM) in
            guard let userId = cellVM.contactModel.usingContact?.userInfo.userID else {
                return
            }
            userDict[userId] = cellVM
        }
        self.userDict = userDict
    }

    func searchContact(_ searchkey: String) {
        if let lastSearchItem = lastSearchWorkItem {
            lastSearchItem.cancel()
        }
        lastSearchWorkItem = DispatchWorkItem { [weak self] in
            self?.search(searchkey)
        }
        lastSearchWorkItem.flatMap { serialQueue.async(execute: $0) }
    }

    func refreshData() {
        disPlaySectionsVariable.accept(disPlaySectionsVariable.value)
    }

    func isEmpty() -> Bool {
        return sectionDataList.isEmpty
    }

    func getCellViewModel(indexPath: IndexPath) -> AddrBookContactCellViewModel? {
        let sections = disPlaySectionsVariable.value
        guard sections.count > indexPath.section,
            sections[indexPath.section].1.count > indexPath.row else {
            return nil
        }

        return sections[indexPath.section].1[indexPath.row]
    }

    func getContactPoint(section: Int) -> AddrBookContactSectionHeaderModel? {
        let sections = disPlaySectionsVariable.value
        guard sections.count > section else {
            return nil
        }
        return sections[section].0
    }

    func addContactSuccess(userId: String) {
        guard let cellVM = userDict[userId] else {
            return
        }
        cellVM.finishInviteOrAddFriend()
        refreshData()
    }

    private func search(_ searchkey: String) {
        guard !sectionDataList.isEmpty else {
            return
        }

        guard !searchkey.isEmpty else {
            disPlaySectionsVariable.accept(sectionDataList)
            return
        }

        guard searchkey.count < AddrBookContactSubViewModel.MAX_LENGHT else {
            disPlaySectionsVariable.accept([])
            return
        }

        let filterDatas = sectionDataList
            .map { searchInSection(searchkey: searchkey, sectionData: $0) }
            .filter { (_, vmList) -> Bool in return !vmList.isEmpty }

        disPlaySectionsVariable.accept(filterDatas)
    }

    private func searchInSection(searchkey: String, sectionData: ContactListSectionData) -> ContactListSectionData {
        // 命中userName 全部返回
        if checkStringContains(lowercasedKey: searchkey.lowercased(),
                               originalStr: sectionData.0.userName.lowercased()) {
            return sectionData
        }

        // 命中cp 全部返回
        if checkStringContains(lowercasedKey: searchkey.lowercased(),
                               originalStr: sectionData.0.cp.lowercased()) {
            return sectionData
        }

        // 过滤联系人列表
        let cellVMList = sectionData.1.filter { checkCellViewModel(searchkey: searchkey, cellVM: $0) }
        return (sectionData.0, cellVMList)
    }

    private func checkCellViewModel(searchkey: String, cellVM: AddrBookContactCellViewModel) -> Bool {
        switch cellVM.contactModel.contactType {
        case .using:
            return checkUsingContact(searchkey: searchkey, usingContact: cellVM.contactModel.usingContact)
        case .notYet:
            return checkNotYetContact(searchkey: searchkey, notYetContact: cellVM.contactModel.notYetContact)
        }
    }

    private func checkUsingContact(searchkey: String, usingContact: ContactPointUserInfo?) -> Bool {
        guard let usingContact = usingContact else {
            return false
        }
        let searchkey = searchkey.lowercased()
        let userInfo = usingContact.userInfo

        let userName = userInfo.userName
        if checkStringContains(lowercasedKey: searchkey, originalStr: userName) {
            return true
        }

        let tenantName = userInfo.tenantName
        if checkStringContains(lowercasedKey: searchkey, originalStr: tenantName) {
            return true
        }

        return false
    }

    private func checkNotYetContact(searchkey: String, notYetContact: NotYetUsingContact?) -> Bool {
        guard let notYetContact = notYetContact else {
            return false
        }

        let contact = notYetContact.addressBookContact
        let fullName = contact.fullName.lowercased()
        let searchkey = searchkey.lowercased()

        if checkStringContains(lowercasedKey: searchkey, originalStr: fullName) {
            return true
        }

        switch contact.contactPointType {
        case .email:
            return contact.email?.lowercased().contains(searchkey) ?? false
        case .phone:
            return contact.phoneNumber?.contains(searchkey) ?? false
        }
    }

    private func checkStringContains(lowercasedKey: String, originalStr: String) -> Bool {
        if originalStr.contains(lowercasedKey) {
            return true
        }
        if originalStr.lf.isIncludeChinese, originalStr.lf.transformToPinyin().contains(lowercasedKey) {
            return true
        }
        return false
    }

    func agreeApplication(_ userId: String) -> Observable<Void> {
        guard let chatApplicationAPI = self.chatApplicationAPI else { return .just(Void()) }
         return chatApplicationAPI
             .processChatApplication(userId: userId, result: .agreed)
    }

    func agreedApplication(_ userIds: [String]) {
        userIds.forEach { (userId) in
            guard let cellVM = userDict[userId] else {
                return
            }
            cellVM.updateUsingContactStatus(.contactPointFriend)
        }
        refreshData()
    }
}
