//
//  CustomerContactController.swift
//  LarkContact
//
//  Created by lichen on 2018/9/11.
//

import Foundation
import UIKit
import LarkActionSheet
import LarkUIKit
import LarkFoundation
import LarkModel
import LarkContainer
import RxSwift
import RxCocoa
import LKCommonsLogging
import EENavigator
import UniverseDesignActionPanel
import LarkFeatureGating

final class CustomerContactController: BaseUIViewController, LarkContactTabProtocol, UITableViewDelegate, UITableViewDataSource, UserResolverWrapper {
    // 别名 FG
    @FeatureGating("lark.chatter.name_with_another_name_p2") private var isSupportAnotherNameFG: Bool

    static let logger = Logger.log(CustomerContactController.self, category: "Module.Contact.CustomerContactController")
    var userResolver: LarkContainer.UserResolver
    // NaviBar
    private lazy var normalNaviBar: TitleNaviBar = {
        return TitleNaviBar(titleString: BundleI18n.LarkContact.Lark_Legacy_Contact)
    }()
    private lazy var largeNaviBar: LargeTitleNaviBar = {
        return LargeTitleNaviBar(titleString: BundleI18n.LarkContact.Lark_Legacy_Contact)
    }()

    var contactTab: LarkContactTab?
    let viewModel: CustomerContactViewModel
    let router: CustomerContactRouter
    private let _firstScreenDataReady = BehaviorRelay<Bool>(value: false)

    fileprivate let searchView = SearchUITextField()
    fileprivate var tableView: UITableView = UITableView(frame: CGRect.zero, style: .grouped)

    fileprivate let disposeBag = DisposeBag()

    fileprivate var applicationBadge: Int = 0

    init(viewModel: CustomerContactViewModel, router: CustomerContactRouter, resolver: UserResolver) {
        self.viewModel = viewModel
        self.router = router
        self.userResolver = resolver
        super.init(nibName: nil, bundle: nil)
    }

    required  init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override  var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        isToolBarHidden = true
        self.view.backgroundColor = UIColor.ud.bgBase

        if !viewModel.isUsingNewNaviBar && !viewModel.showNormalNavigationBar {
            let searchBgView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 44))
            searchBgView.backgroundColor = UIColor.ud.bgBase
            searchView.canEdit = false
            searchView.frame = CGRect(x: 16, y: 0, width: view.frame.width - 32, height: 32)
            searchView.tapBlock = { [weak self] (_) in
                self?.clickSearchButton()
            }
            searchBgView.addSubview(searchView)
            tableView.tableHeaderView = searchBgView
        }

        // 表格
        tableView.backgroundColor = UIColor.ud.bgBase
        tableView.separatorStyle = .none
        tableView.rowHeight = 68
        tableView.delegate = self
        tableView.dataSource = self
        tableView.showsHorizontalScrollIndicator = false
        tableView.showsVerticalScrollIndicator = false
        tableView.sectionIndexBackgroundColor = UIColor.clear
        tableView.sectionIndexColor = UIColor.ud.textTitle
        var identifier = String(describing: DataItemViewCell.self)
        tableView.register(DataItemViewCell.self, forCellReuseIdentifier: identifier)
        identifier = String(describing: ContactTableViewCell.self)
        tableView.register(ContactTableViewCell.self, forCellReuseIdentifier: identifier)
        identifier = String(describing: EmptyContactCell.self)
        tableView.register(EmptyContactCell.self, forCellReuseIdentifier: identifier)

        self.viewModel.updateDriver.drive(onNext: { [weak self] (_) in
            self?._firstScreenDataReady.accept(true)
            self?.tableView.reloadData()
        }).disposed(by: self.disposeBag)

        if self.viewModel.showNormalNavigationBar {
            isNavigationBarHidden = false
            self.title = BundleI18n.LarkContact.Lark_Legacy_Contact
            self.view.addSubview(tableView)
            tableView.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
                make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
            }
        } else if !viewModel.isUsingNewNaviBar {
            isNavigationBarHidden = true
            let searchItem = TitleNaviBarItem(image: Resources.search, action: { [weak self] _ in
                guard let `self` = self else { return }
                self.clickSearchButton()
            })
            normalNaviBar.rightItems = [searchItem]
            NaviBarAnimator.setUpAnimatorWith(
                scrollView: tableView,
                normalNaviBar: normalNaviBar,
                largeNaviBar: largeNaviBar,
                toVC: self
            )
        } else {
            isNavigationBarHidden = true
            self.view.addSubview(tableView)
            self.view.sendSubviewToBack(tableView)
            tableView.snp.makeConstraints({ make in
                make.left.right.equalToSuperview()
                make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(naviHeight)
                make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
            })
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        searchView.frame = CGRect(x: 16, y: 0, width: view.frame.width - 32, height: 32)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.viewModel.loadContactIfNeeded()
        searchView.frame = CGRect(x: 16, y: 0, width: view.frame.width - 32, height: 32)
    }

    private func clickSearchButton() {
        CustomerContactController.logger.info("click search button")
        self.router.openSearchController(vc: self)
    }

    var firstScreenDataReady: BehaviorRelay<Bool>? {
        return _firstScreenDataReady
    }

    func contactTabApplicationBadgeUpdate(_ applicationBadge: Int) {
        self.applicationBadge = applicationBadge
        CustomerContactController.logger.info("applicationBadge update \(applicationBadge)")
        if self.isViewLoaded {
            self.tableView.reloadData()
        }
    }
    func contactTabRootController() -> UIViewController {
        return self
    }
    // MARK: - UITableViewDelegate, UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        if self.viewModel.chatters.isEmpty {
            return 2
        } else {
            return self.viewModel.chatters.count + 1
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { return self.viewModel.dataInFirstSection.count }
        if self.viewModel.chatters.isEmpty { return 1 }
        return self.viewModel.chatters[section - 1].elements.count
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 { return nil }
        if self.viewModel.chatters.isEmpty { return UIView() }
        let view = UIView()
        let text = self.viewModel.chatters[section - 1].key
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textTitle

        view.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(36)
            make.centerY.equalToSuperview()
        }

        return view
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 { return 0.01 }
        if self.viewModel.chatters.isEmpty { return 0.01 }
        return 24
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section != 0 && self.viewModel.chatters.isEmpty {
            return 220
        }
        if indexPath.section == 0 {
            return 51
        }
        return 68
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            return self.tableView(tableView, rowInSectionZero: indexPath.row)
        } else if self.viewModel.chatters.isEmpty {
            return self.tableViewEmptyContact(tableView)
        } else {
            return self.tableView(tableView, contactInIndex: IndexPath(row: indexPath.row, section: indexPath.section - 1))
        }
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == 0 {
            let data = self.viewModel.dataInFirstSection[indexPath.row]
            switch data.type {
            case .contactApplication:
                CustomerContactController.logger.info("click contactApplication section button")
                self.router.openContactApplicationViewController(self)
            case .group:
                CustomerContactController.logger.info("click group section button")
                self.router.openMyGroups(self)
            default:
                break
            }
            return
        } else if self.viewModel.chatters.isEmpty { return }

        let contact = self.viewModel.chatters[indexPath.section - 1].elements[indexPath.row]
        CustomerContactController.logger.info("click cell chatter \(contact.id)")
        self.router.openChatterDetail(chatter: contact, self)
    }

    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        if indexPath.section == 0 { return nil }
        if self.viewModel.chatters.isEmpty { return nil }
        return BundleI18n.LarkContact.Lark_Legacy_DeleteIt
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if indexPath.section == 0 { return }
        if self.viewModel.chatters.isEmpty { return }
        let contact = self.viewModel.chatters[indexPath.section - 1].elements[indexPath.row]
        self.delete(contact: contact)
        tableView.setEditing(false, animated: false)
    }

    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if indexPath.section == 0 { return UISwipeActionsConfiguration(actions: []) }
        if self.viewModel.chatters.isEmpty { return UISwipeActionsConfiguration(actions: []) }

        let contact = self.viewModel.chatters[indexPath.section - 1].elements[indexPath.row]

        let delete = UIContextualAction(style: .destructive, title: BundleI18n.LarkContact.Lark_Legacy_DeleteIt) { [weak self] (_, _, completionHandler) in
            self?.delete(contact: contact)
            tableView.setEditing(false, animated: false)
            completionHandler(false)
        }

        let configuration = UISwipeActionsConfiguration(actions: [delete])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if self.viewModel.chatters.isEmpty { return nil }
        return self.viewModel.chatters.map { $0.key }
    }

    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index + 1
    }

    func delete(contact: Chatter) {
        let actionSheet = UDActionSheet(config: UDActionSheetUIConfig(style: .autoAlert, isShowTitle: true))
        actionSheet.setTitle(BundleI18n.LarkContact.Lark_Legacy_DialogDeleteExternalContactTitle)
        actionSheet.addDestructiveItem(text: BundleI18n.LarkContact.Lark_Legacy_DeleteIt) { [weak self] in
            guard let `self` = self else { return }
            self.viewModel.delete(chatter: contact)
        }
        actionSheet.setCancelItem(text: BundleI18n.LarkContact.Lark_Legacy_Cancel)
        navigator.present(actionSheet, from: self)
    }

    private func tableView(_ tableView: UITableView, rowInSectionZero row: Int) -> UITableViewCell {
        let identifier = String(describing: DataItemViewCell.self)
        if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? DataItemViewCell {
            let data = self.viewModel.dataInFirstSection[row]
            cell.dataItem = data
            if data.type == .contactApplication {
                if self.applicationBadge == 0 {
                    cell.updateBadge(isHidden: true, badge: self.applicationBadge)
                } else {
                    cell.updateBadge(isHidden: false, badge: self.applicationBadge)
                }
            }
            return cell
        }
        return UITableViewCell(frame: .zero)
    }

    private func tableViewEmptyContact(_ tableView: UITableView) -> UITableViewCell {
        let identifier = String(describing: EmptyContactCell.self)
        if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? EmptyContactCell {
            return cell
        }
        return UITableViewCell(frame: .zero)
    }

    private func tableView(_ tableView: UITableView, contactInIndex index: IndexPath) -> UITableViewCell {
        let identifier = String(describing: ContactTableViewCell.self)
        if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? ContactTableViewCell {
            let chatter = self.viewModel.chatters[index.section].elements[index.row]
            var item = ContactTableViewCellProps(user: chatter, isSupportAnotherName: isSupportAnotherNameFG)
            item.description = self.viewModel.tenantMap[chatter.tenantId]
            cell.setProps(item)
            return cell
        }
        return UITableViewCell(frame: .zero)
    }
}

extension CustomerContactController: SearchBarTransitionBottomVCDataSource {

    var naviBarView: UIView {
        return self.largeNaviBar
    }

    var searchTextField: SearchUITextField {
        return self.searchView
    }

    // transform push transition to MainTabBarController
    var animationProxy: CustomNaviAnimation? {
        return viewModel.isUsingNewNaviBar
            ? self.animatedTabBarController as? CustomNaviAnimation
            : self
    }

    func pushAnimationController(for controller: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard controller.transitionViewController is SearchBarTransitionTopVCDataSource else {
            return nil
        }
        return SearchBarPresentTransition()
    }

    func popAnimationController(for controller: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard controller.transitionViewController is SearchBarTransitionTopVCDataSource else {
            return nil
        }
        return SearchBarDismissTransition()
    }
}

extension CustomerContactController: LarkNaviBarAbility { }
extension CustomerContactController: LarkNaviBarDelegate {
    func onButtonTapped(on button: UIButton, with type: LarkNaviButtonType) {
        switch type {
        case .search: self.clickSearchButton()
        default: break
        }
    }
}

extension CustomerContactController: LarkNaviBarDataSource {
    var titleText: BehaviorRelay<String> {
        return BehaviorRelay(value: BundleI18n.LarkContact.Lark_Legacy_Contact)
    }

    var isNaviBarEnabled: Bool {
        return viewModel.isUsingNewNaviBar
    }

    var isDrawerEnabled: Bool {
        return viewModel.isUsingNewNaviBar
    }
}
