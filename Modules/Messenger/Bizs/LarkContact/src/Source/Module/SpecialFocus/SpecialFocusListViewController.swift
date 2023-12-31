//
//  SpecialFocusListViewController.swift
//  LarkContact
//
//  Created by panbinghua on 2021/10/22.
//

import Foundation
import UIKit
import LarkUIKit
import RxSwift
import RxCocoa
import RxDataSources
import LarkMessengerInterface
import LarkAlertController
import UniverseDesignEmpty
import UniverseDesignDialog
import UniverseDesignToast
import LarkSDKInterface
import EENavigator
import LarkModel
import LKCommonsTracker
import LKCommonsLogging
import Homeric
import LarkRustClient
import LarkFeatureGating
import LarkContainer

struct SpecialFocusListCellModel: IdentifiableType, Equatable {

    var id: String
    var chatter: Chatter
    var isSupportAnotherName: Bool

    init(chatter: Chatter, isSupportAnotherName: Bool) {
        self.id = chatter.id
        self.chatter = chatter
        self.isSupportAnotherName = isSupportAnotherName
    }

    typealias Identity = String
    var identity: Identity { return id }
    static func == (lhs: SpecialFocusListCellModel, rhs: SpecialFocusListCellModel) -> Bool {
        return lhs.id == rhs.id
    }

    func transformToCellProp() -> ContactTableViewCellProps {
        var props = ContactTableViewCellProps(user: self.chatter, isSupportAnotherName: isSupportAnotherName)
        props.medalKey = self.chatter.medalKey
        return props
    }
}

struct SpecialFocusSection {
    var items: [Item]
}

extension SpecialFocusSection: SectionModelType {
    typealias Item = SpecialFocusListCellModel
    init(original: SpecialFocusSection, items: [Item]) {
        self = original
        self.items = items
    }
}

final class SpecialFocusListViewController: BaseUIViewController, UITableViewDelegate, UserResolverWrapper {
    // 别名 FG
    @FeatureGating("lark.chatter.name_with_another_name_p2") private var isSupportAnotherNameFG: Bool

    static let logger = Logger.log(SpecialFocusListViewController.self, category: "contact.specialFocus")
    private let disposeBag = DisposeBag()
    private let viewModel: ISpecialFocusListViewModel
    var userResolver: LarkContainer.UserResolver

    private var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.rowHeight = 68
        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        tableView.separatorStyle = .none
        tableView.separatorColor = UIColor.ud.lineDividerDefault
        tableView.backgroundColor = UIColor.ud.bgBody
        return tableView
    }()

    private let emptyView: UDEmptyView = {
        let text = BundleI18n.LarkContact.Lark_IM_NoStarredContactsAdd_EmptyState
        let config = UDEmptyConfig(description: UDEmptyConfig.Description(descriptionText: text),
                                   type: .noContact)
        let view = UDEmptyView(config: config)
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }()

    private func setupView() {
        title = BundleI18n.LarkContact.Lark_IM_StarredContacts_FeatureName
        let rightButton = LKBarButtonItem(title: BundleI18n.LarkContact.Lark_Legacy_Add)
        rightButton.button.tintColor = UIColor.ud.primaryContentDefault
        rightButton.setProperty(font: UIFont.systemFont(ofSize: 16), alignment: .center)
        rightButton.button.rx.tap
            .withLatestFrom(viewModel.idsOfSelfAndFocusing)
            .subscribe(onNext: { [weak self] ids in
                self?.openChatterPicker(idsOfSelfAndFocusing: ids)
            }).disposed(by: disposeBag)
        navigationItem.rightBarButtonItem = rightButton

        view.backgroundColor = UIColor.ud.bgBody
        view.addSubview(emptyView)
        view.addSubview(tableView)

        tableView.register(ContactTableViewCell.self, forCellReuseIdentifier: "ContactTableViewCell")
        tableView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalToSuperview()
        }
        emptyView.useCenterConstraints = true
        emptyView.snp.remakeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalToSuperview()
        }
        loadingPlaceholderView.isHidden = false
    }

    lazy var dataSource = RxTableViewSectionedReloadDataSource<SpecialFocusSection>(
        configureCell: { _, tableView, indexPath, item in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ContactTableViewCell",
                                                           for: indexPath) as? ContactTableViewCell else {
                return UITableViewCell()
            }
            cell.setProps(item.transformToCellProp())
            return cell
        }
    )

    private func bindModel() {
        let memberList = viewModel.memberList.compactMap { $0 }
        let numberOfItem = memberList.map { list in list.count }.asObservable()
        // loading 、 empty 、 tableView
        numberOfItem.take(1)
            .subscribe(onNext: { [weak self] _ in
                self?.loadingPlaceholderView.isHidden = true
            }).disposed(by: disposeBag)
        memberList.map { $0.isEmpty }
            .drive { [weak self] isEmpty in
                self?.tableView.isHidden = isEmpty
                self?.emptyView.isHidden = !isEmpty
            }.disposed(by: disposeBag)
        // table view
        tableView.rx.setDelegate(self).disposed(by: disposeBag)
        let isSupportAnotherName = self.isSupportAnotherNameFG
        memberList.map { list in list.map { chatter in SpecialFocusListCellModel(chatter: chatter, isSupportAnotherName: isSupportAnotherName) } }
            .map { [SpecialFocusSection(items: $0)] }
            .drive(tableView.rx.items(dataSource: dataSource)).disposed(by: disposeBag)
        // 点击
        tableView.rx.modelSelected(SpecialFocusListCellModel.self)
            .subscribe(onNext: { [weak self] item in
                guard let self = self else { return }
                let body = PersonCardBody(chatterId: item.id, source: .specialFocus)
                self.navigator.presentOrPush(body: body,
                                               wrap: LkNavigationController.self,
                                               from: self,
                                               prepareForPresent: { (vc) in
                                                   vc.modalPresentationStyle = .formSheet
                })
            }).disposed(by: disposeBag)
        dataSource.canEditRowAtIndexPath = { _, _ in return true }
        // 埋点
        numberOfItem.take(1).subscribe(onNext: { number in
            var params: [AnyHashable: Any] = [:]
            params["starred_contact_num"] = number
            Tracker.post(TeaEvent(Homeric.CONTACT_STARRED_CONTACT_VIEW, params: params))
        }).disposed(by: disposeBag)
        tableView.rx.modelSelected(SpecialFocusListCellModel.self)
            .subscribe(onNext: { [weak self] _ in
                guard self != nil else { return }
                var params: [AnyHashable: Any] = [:]
                params["click"] = "icon"
                params["target"] = "profile_main_view"
                Tracker.post(TeaEvent(Homeric.CONTACT_STARRED_CONTACT_CLICK, params: params))
            }).disposed(by: disposeBag)
    }

    private func openChatterPicker(idsOfSelfAndFocusing: [String]) {
        var body = ChatterPickerBody()
        body.selectStyle = .singleMultiChangeable
        body.title = BundleI18n.LarkContact.Lark_IM_StarredContactSelectFromContacts_Title
        body.dataOptions = [.external]
        body.disabledSelectedChatterIds = idsOfSelfAndFocusing // 不能选自己和已关注的人
        body.enableRelatedOrganizations = true
        body.selectedCallback = { [weak self] pickerVC, contactPickerResult in
            guard let self = self, let pickerVC = pickerVC else { return }
            let chatterIDs = contactPickerResult.chatterInfos.map { $0.ID }
            self.trackSubscribe(contactPickerResult.chatterInfos)
            self.viewModel.subscribeChatters(ids: chatterIDs)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak pickerVC, weak self] _ in
                    guard let self = self else { return }
                    pickerVC?.dismiss(animated: true, completion: nil)
                    UDToast.showSuccess(with: BundleI18n.LarkContact.Lark_IM_AddToStarredConact_SuccessToast, on: self.view)
                }, onError: { [weak pickerVC, weak self] error in
                    guard let self = self else { return }
                    pickerVC?.dismiss(animated: true, completion: nil)
                    UDToast.showFailure(with: BundleI18n.LarkContact.Lark_IM_AddToStarredConact_FailureToast, on: self.view, error: error)
                    Self.logger.warn("subscribe failed", error: error)
                }).disposed(by: self.disposeBag)
        }
        navigator.present(
            body: body,
            from: self,
            prepare: { $0.modalPresentationStyle = .formSheet }
        )
    }

    private func unsubscribe(id: String) {
        trackUnsubscribe()
        self.viewModel.unsubscribeChatters(ids: [id])
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                UDToast.showSuccess(with: BundleI18n.LarkContact.Lark_IM_RemoveFromStarredContact_SuccessToast, on: self.view)
            }, onError: { [weak self] error in
                guard let self = self else { return }
                UDToast.showFailure(with: BundleI18n.LarkContact.Lark_IM_AddToStarredConact_FailureToast, on: self.view, error: error)
                Self.logger.warn("unsubscribe failed", error: error)
            }).disposed(by: self.disposeBag)
    }

    // MARK: - Tableview Delegate
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .normal,
                                        title: BundleI18n.LarkContact.Lark_IM_RemoveVIPContacts_RemoveButton,
                                        handler: { [weak self] (_, _, completionHandler) in
            guard let self = self else {
                completionHandler(true)
                Self.logger.error("delet false self no exist")
                return
            }
            let id = self.dataSource.sectionModels[indexPath.section].items[indexPath.row].id
            let dialog = UDDialog()
            dialog.setTitle(text: BundleI18n.LarkContact.Lark_IM_RemoveVIPContacts_Title)
            dialog.addSecondaryButton(text: BundleI18n.LarkContact.Lark_Legacy_Cancel, dismissCompletion: {
                completionHandler(true)
            })
            dialog.addPrimaryButton(text: BundleI18n.LarkContact.Lark_IM_RemoveVIPContacts_RemoveButton,
                             dismissCompletion: { [weak self] in
                self?.unsubscribe(id: id)
                completionHandler(true)
            })
            self.navigator.present(dialog, from: self)
          })
        action.backgroundColor = UIColor.ud.colorfulRed
        let configuration = UISwipeActionsConfiguration(actions: [action])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }

    // MARK: - 埋点
    private func trackSubscribe(_ chatterInfos: [SelectChatterInfo]) {
        let chatterIDs = chatterInfos.map { $0.ID }
        let contactTypes = chatterInfos.map { (info: SelectChatterInfo) -> String in
            if !info.isExternal {
                return "internal" // 同一租户
            } else if info.isNotFriend {
                return "external_nonfriend" // 非同一租户的非好友用户
            } else {
                return "external_friend" // 非同一租户的好友用户
            }
        }
        var params: [AnyHashable: Any] = [:]
        params["click"] = "starred_contact_add"
        params["target"] = "none"
        params["contact_type"] = contactTypes
        params["to_user_id"] = chatterIDs
        Tracker.post(TeaEvent(Homeric.CONTACT_STARRED_CONTACT_CLICK, params: params, md5AllowList: ["to_user_id"]))
    }

    private func trackUnsubscribe() {
        var params: [AnyHashable: Any] = [:]
        params["click"] = "starred_contact_cancel"
        params["target"] = "none"
        Tracker.post(TeaEvent(Homeric.CONTACT_STARRED_CONTACT_CLICK, params: params))
    }

    // MARK: - Life Circle
    init(viewModel: ISpecialFocusListViewModel, resolver: UserResolver) {
        self.viewModel = viewModel
        self.userResolver = resolver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        bindModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.fetchMemberList()
    }
}
