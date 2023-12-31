//
//  CollaborationSearchViewController.swift
//  LarkContact
//
//  Created by Nix Wang on 2022/11/28.
//

import Foundation
import UIKit
import SnapKit
import RustPB
import LarkContainer
import LarkSDKInterface
import LarkMessengerInterface
import RxSwift
import RxCocoa
import LarkSearchCore
import LarkModel
import LKCommonsLogging
import LarkSetting

protocol CollaborationSearchViewControllerRouter: AnyObject {
    func collaborationSearchViewController(_ vc: CollaborationSearchViewController, didSelect chatter: Chatter)
}

class CollaborationSearchViewController: UIViewController, ContactSearchable, UserResolverWrapper {
    static let logger = Logger.log(CollaborationSearchViewController.self, category: "Module.IM.Message")

    var isPublic: Bool = false

    let associationContactType: AssociationContactType?

    var userResolver: LarkContainer.UserResolver
    @ScopedProvider private var chatAPI: ChatAPI?

    private lazy var searchView = CollaborationSearchView(frame: .zero, rootViewController: searchResultViewController)
    private let searchResultViewController: CollaborationSearchResultViewController
    private let departmentAPI: CollaborationDepartmentAPI
    private let chatterDriver: Driver<PushChatters>
    private let router: CollaborationSearchViewControllerRouter

    init(
        searchResultViewController: CollaborationSearchResultViewController,
        departmentAPI: CollaborationDepartmentAPI,
        chatterDriver: Driver<PushChatters>,
        router: CollaborationSearchViewControllerRouter,
        associationContactType: AssociationContactType?,
        resolver: UserResolver
    ) {
        self.searchResultViewController = searchResultViewController
        self.departmentAPI = departmentAPI
        self.chatterDriver = chatterDriver
        self.router = router
        self.associationContactType = associationContactType
        self.userResolver = resolver
        super.init(nibName: nil, bundle: nil)
        self.searchResultViewController.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func search(text: String) {
        searchView.popToRoot()
        searchResultViewController.search(text: text)
    }

    func reloadData() {
        Self.logger.info("n_action_reload_data")
        searchResultViewController.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(searchView)
        searchView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

extension CollaborationSearchViewController: CollaborationSearchResultDelegate {
    private func openDepartmentStructure(tenantID: String?, department: Department, departmentPath: [Department]) {

        Self.logger.info("n_action_open_depeartment: id \(tenantID ?? "")")

        guard let chatAPI else { return }

        let viewModel = CollaborationDepartmentViewModel(
            tenantId: tenantID,
            department: department,
            departmentAPI: departmentAPI,
            chatAPI: chatAPI,
            fgService: userResolver.fg,
            chatterDriver: chatterDriver,
            filterChatter: nil,
            chatId: nil,
            showContactsTeamGroup: false,
            checkInvitePermission: false,
            isCryptoModel: false,
            checkHasLeaderPermission: false,
            disableTags: [],
            associationContactType: associationContactType
        )

        let departmentVC = DepartmentVC(
            viewModel: viewModel,
            config: DepartmentVC.Config(
                showNameStyle: ShowNameStyle.nameAndAlias,
                routeSubDepartment: { [weak self](_, tenantID, department, _) in
                    guard let self = self else { return }
                    let newDepartmentPath = departmentPath + [department]
                    self.openDepartmentStructure(tenantID: tenantID, department: department, departmentPath: newDepartmentPath)
                },
                departmenSupportSelect: false,
                selectedHandler: nil),
            selectionSource: self,
            selectChannel: .collaboration,
            resolver: userResolver)
        departmentVC.targetPreview = false
        departmentVC.fromVC = nil
        searchView.push(source: departmentVC)
    }

    func searchResult(_ searchResult: CollaborationSearchResultViewController, didSelect tenant: Contact_V1_CollaborationTenant) {
        var department = Department()
        department.id = "0" // id为 0 表示直接查看大组织架构
        department.name = tenant.tenantName

        openDepartmentStructure(tenantID: tenant.tenantID, department: department, departmentPath: [])
    }
}

extension CollaborationSearchViewController: SelectionDataSource {

    var isMultiple: Bool {
        return false
    }

    var selected: [LarkSDKInterface.Option] {
        return []
    }

    var isMultipleChangeObservable: RxSwift.Observable<Bool> {
        return .just(false)
    }

    var selectedChangeObservable: RxSwift.Observable<LarkSearchCore.SelectionDataSource> {
        return .just(self)
    }

    func state(for option: LarkSDKInterface.Option, from: Any?) -> LarkSearchCore.SelectState {
        return state(for: option, from: from, category: .unknown)
    }

    func state(for option: Option, from: Any?, category: PickerItemCategory) -> SelectState {
        return .normal
    }

    func select(option: LarkSDKInterface.Option, from: Any?) -> Bool {
        guard let chatter = option as? Chatter else {
            assertionFailure("Invalid option")
            return false
        }

        Self.logger.info("n_action_select_chatter: id \(chatter.id ?? "")")

        router.collaborationSearchViewController(self, didSelect: chatter)
        return true
    }

    func deselect(option: LarkSDKInterface.Option, from: Any?) -> Bool {

        Self.logger.info("n_action_deselect_chatter")

        return select(option: option, from: from)
    }

}
