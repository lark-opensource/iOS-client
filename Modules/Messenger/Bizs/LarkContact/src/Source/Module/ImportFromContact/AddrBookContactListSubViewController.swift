//
//  AddrBookContactRouter.swift
//  LarkContact
//
//  Created by mochangxing on 2020/7/13.
//

import UIKit
import Foundation
import LarkUIKit
import LarkSegmentedView
import RxCocoa
import RxSwift
import LarkAddressBookSelector
import LarkContainer
import LarkModel
import UniverseDesignToast
import LarkSDKInterface
import LKCommonsLogging
import EENavigator
import UniverseDesignEmpty

protocol AddrBookContactRouter {
    /// 个人信息详情页
    func pushPersonalCardVC(from: UIViewController,
                            userId: String)
    /// 添加好友
    func pushApplyFriendsVC(from: UIViewController,
                          userId: String,
                          userName: String,
                          completionHandler: @escaping (String?) -> Void)
}

final class AddrBookContactListSubViewController: BaseUIViewController,
    JXSegmentedListContainerViewListDelegate,
    UITableViewDataSource,
    UITableViewDelegate, UserResolverWrapper {

    static let logger = Logger.log(AddrBookContactListSubViewController.self, category: "Contact")
    private let disposeBag = DisposeBag()
    var userResolver: LarkContainer.UserResolver
    private let viewModel: AddrBookContactSubViewModel
    private let importPresenter: ContactImportPresenter?
    @ScopedProvider var router: AddrBookContactRouter?
    private lazy var emptyResultView: UDEmptyView = {
        let desc = UDEmptyConfig.Description(descriptionText: BundleI18n.LarkContact.Lark_UserGrowth_InviteMemberImportContactsNoMatch)
        let emptyDataView = UDEmptyView(config: UDEmptyConfig(description: desc, type: .noSearchResult))
        emptyDataView.isHidden = true
        emptyDataView.isUserInteractionEnabled = false
        emptyDataView.useCenterConstraints = true
        return emptyDataView
    }()

    private var sectionHeaderLineNumber = [String: Int]()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = Layout.rowHeight
        tableView.sectionHeaderHeight = sectionHeaderHeight()
        tableView.sectionFooterHeight = 0
        tableView.contentInset = contentInset()
        tableView.separatorStyle = .none
        tableView.contentOffset = contentOffset()
        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.register(AddrBookContactTableViewCell.self,
                           forCellReuseIdentifier: NSStringFromClass(AddrBookContactTableViewCell.self))
        tableView.register(AddrBookContactSectionHeader.self,
                                 forHeaderFooterViewReuseIdentifier: NSStringFromClass(AddrBookContactSectionHeader.self))
        return tableView
    }()

    var onCellButtonClick: ((IndexPath, ContactType) -> Void)?

    func sectionHeaderHeight() -> CGFloat {
        switch viewModel.viewStyle {
        case .multiSection:
            return Layout.multiSectionHeaderSingleLineHeight
        case .singleSection:
            return CGFloat.leastNonzeroMagnitude
        }
    }

    func contentOffset() -> CGPoint {
        switch viewModel.viewStyle {
        case .multiSection:
            return Layout.multiSectionContentOffset
        case .singleSection:
            return Layout.singleSectionContentOffset
        }
    }

    func contentInset() -> UIEdgeInsets {
        switch viewModel.viewStyle {
        case .multiSection:
            return Layout.multiSectionContentInset
        case .singleSection:
            return Layout.singleSectionContentInset
        }
    }

    init(viewModel: AddrBookContactSubViewModel,
         importPresenter: ContactImportPresenter?,
         resolver: UserResolver) {
        self.viewModel = viewModel
        self.importPresenter = importPresenter
        self.userResolver = resolver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        view.addSubview(emptyResultView)
        emptyResultView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        bindViewModel()
    }

    func bindViewModel() {
        viewModel.reloadDataDriver.drive(onNext: { [weak self] (status) in
            guard let self = self else { return }

            self.tableView.isHidden = status != .reloadData
            switch status {
            case .reloadData:
                self.emptyResultView.isHidden = true
                self.tableView.reloadData()
            case .showEmpty:
                self.showEmpty()
            case .showNoMatch:
                self.showNoMatch()
            }
        }).disposed(by: disposeBag)
    }

    func showEmpty() {
        let desc = UDEmptyConfig.Description(descriptionText: BundleI18n.LarkContact.Lark_Legacy_ContactEmpty)
        emptyResultView.update(config: UDEmptyConfig(description: desc, type: .noContact))
        emptyResultView.isHidden = false
    }

    func showNoMatch() {
        emptyResultView.update(
            config: UDEmptyConfig(description: UDEmptyConfig.Description(descriptionText: BundleI18n.LarkContact.Lark_UserGrowth_InviteMemberImportContactsNoMatch),
            type: .noSearchResult)
        )
        emptyResultView.isHidden = false
    }

    // MARK: - JXSegmentedListContainerViewListDelegate
    func listView() -> UIView {
        return view
    }

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard viewModel.sectionDatas.count > section else {
            return .zero
        }
        return viewModel.sectionDatas[section].1.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(AddrBookContactTableViewCell.self)) as? AddrBookContactTableViewCell,
            let cellVM = self.viewModel.getCellViewModel(indexPath: indexPath) else {
            return UITableViewCell()
        }
        cell.rightButtonTappedAction = { [weak self] in
            guard let self = self,
                let cellVM = self.viewModel.getCellViewModel(indexPath: indexPath) else {
                return
            }
            switch cellVM.contactModel.contactType {
            case .notYet:
                self.inviteFriend(cellVM: cellVM)
            case .using:
                self.addFriendDirectly(cellVM: cellVM)
            }
            self.onCellButtonClick?(indexPath, cellVM.contactModel.contactType)
        }
        cell.updateCell(viewModel: cellVM)
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard viewModel.viewStyle == .multiSection,
            let sectionHeader = tableView.dequeueReusableHeaderFooterView(withIdentifier:
                NSStringFromClass(AddrBookContactSectionHeader.self)) as? AddrBookContactSectionHeader,
            let sectionHeaderModel = self.viewModel.getContactPoint(section: section) else {
                    return nil
        }
        if canDisplayInSingleLine(sectionHeaderModel) {
            sectionHeader.setTitle(title: BundleI18n.LarkContact.Lark_NewContacts_FromMobileContacts
                + sectionHeaderModel.userName
                + sectionHeaderModel.cp)
            sectionHeader.setSubTitle(subTitle: "")
        } else {
            sectionHeader.setTitle(title: BundleI18n.LarkContact.Lark_NewContacts_FromMobileContacts
                + sectionHeaderModel.userName)
            sectionHeader.setSubTitle(subTitle: sectionHeaderModel.cp)
        }
        return sectionHeader
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard viewModel.viewStyle == .multiSection, let sectionHeaderModel = self.viewModel.getContactPoint(section: section) else {
            return CGFloat.leastNonzeroMagnitude
        }

        return canDisplayInSingleLine(sectionHeaderModel) ? Layout.multiSectionHeaderSingleLineHeight : Layout.multiSectionHeaderMultiLineHeight
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sectionDatas.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil,
            let cellVM = self.viewModel.getCellViewModel(indexPath: indexPath) else {
                return
        }
        switch cellVM.contactModel.contactType {
        case .notYet:
            self.inviteFriend(cellVM: cellVM)
        case .using:
            self.pushPersonalCardVC(cellVM: cellVM)
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    // MARK: - UITableViewDelegate
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollView.window?.endEditing(true)
    }

    private func inviteFriend(cellVM: AddrBookContactCellViewModel) {
        guard let importPresenter = importPresenter, let contact = cellVM.contactModel.notYetContact else {
            return
        }
        importPresenter.inviteFriend(contact: contact.addressBookContact,
                                     type: contact.addressBookContactType,
                                     from: self) { [weak self, weak cellVM] in
                                        cellVM?.finishInviteOrAddFriend()
                                        self?.viewModel.refreshData()
        }
    }

    private func addFriendDirectly(cellVM: AddrBookContactCellViewModel) {
        guard let usingContact = cellVM.contactModel.usingContact else {
            return
        }

        switch usingContact.contactStatus {
        case .contactStatusNotFriend, .contactStatusRequestExpired:
            self.router?.pushApplyFriendsVC(from: self,
                                           userId: usingContact.userInfo.userID,
                                           userName: usingContact.userInfo.userName) { [weak self, weak cellVM] _ in
                cellVM?.finishInviteOrAddFriend()
                self?.viewModel.refreshData()
            }
        case .contactStatusReceive:
            self.viewModel.agreeApplication(usingContact.userInfo.userID)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self, weak cellVM] in
                    cellVM?.updateUsingContactStatus(.contactPointFriend)
                    self?.viewModel.refreshData()
                    if let window = self?.view.window {
                        UDToast.showTips(with: BundleI18n.LarkContact.Lark_NewContacts_AcceptedContactRequestToast(), on: window)
                    }
                }, onError: { [weak self] (error) in
                    guard let window = self?.view.window else {
                        return
                    }
                    var alertMessage = BundleI18n.LarkContact.Lark_Legacy_ErrorMessageTip
                    if let error = error.underlyingError as? APIError {
                        switch error.type {
                        case .targetExternalCoordinateCtl, .externalCoordinateCtl:
                            alertMessage = BundleI18n
                                .LarkContact
                                .Lark_Contacts_CantCompleteOperationNoExternalCommunicationPermission
                        @unknown default:
                            break
                        }
                    }
                    UDToast.showFailure(with: alertMessage, on: window, error: error)
                }).disposed(by: disposeBag)
        case .contactPointFriend, .contactStatusRequest:
            AddrBookContactListSubViewController.logger.info("Should not be here",
                                                             additionalData: ["contactStatus": "\(usingContact.contactStatus)"])
        }

    }

    private func pushPersonalCardVC(cellVM: AddrBookContactCellViewModel) {
        guard let usingContact = cellVM.contactModel.usingContact else {
            return
        }
        self.router?.pushPersonalCardVC(from: self,
                                       userId: usingContact.userInfo.userID)
    }

    private func canDisplayInSingleLine(_ sectionHeaderModel: AddrBookContactSectionHeaderModel) -> Bool {
        let lineNumber = getSectionHeaderLineNumber(sectionHeaderModel)
        return lineNumber <= 1
    }

    private func getSectionHeaderLineNumber(_ sectionHeaderModel: AddrBookContactSectionHeaderModel) -> Int {
        let string = BundleI18n.LarkContact.Lark_NewContacts_FromMobileContacts
            + sectionHeaderModel.userName
            + sectionHeaderModel.cp

        guard let lineNumber = sectionHeaderLineNumber[string] else {
            let font = UIFont.systemFont(ofSize: AddrBookContactSectionHeader.fontSize)
            let rect = NSString(string: string)
                .boundingRect(with: CGSize(width: self.view.frame.width - AddrBookContactSectionHeader.Layout.titleLetfOffset * 2,
                                           height: CGFloat(MAXFLOAT)),
                              options: .usesLineFragmentOrigin,
                              attributes: [NSAttributedString.Key.font: font],
                              context: nil)
            let lineNumber = Int(ceil(rect.height / font.lineHeight))
            sectionHeaderLineNumber[string] = lineNumber
            return lineNumber
        }
        return lineNumber
    }
}

extension AddrBookContactListSubViewController {
    enum Layout {
        static let rowHeight: CGFloat = 68

        static let multiSectionHeaderSingleLineHeight: CGFloat = 56
        static let multiSectionHeaderMultiLineHeight: CGFloat = 70
        static let multiSectionContentOffset: CGPoint = .zero
        static let multiSectionContentInset: UIEdgeInsets = .zero

        static let singleSectionContentOffset: CGPoint = CGPoint(x: 0, y: -8)
        static let singleSectionContentInset: UIEdgeInsets = UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)
    }
}
