//
//  ImportFromContactListController.swift
//  LarkContact
//
//  Created by mochangxing on 2020/7/13.
//

import UIKit
import Foundation
import LarkUIKit
import LarkSegmentedView
import RxSwift
import RxCocoa
import LarkContainer
import LarkSDKInterface

// 联系人类型
enum ContactType: String {
    case using
    case notYet
}

enum AddContactScene {
    case importFromContact
    case newContact
    case onBoarding
}

typealias ContactSkipCallback = ((AddrBookContactListController) -> Void)

final class AddrBookContactListController: BaseUIViewController,
    JXSegmentedListContainerViewDataSource, JXSegmentedViewDelegate, UITextFieldDelegate {

    private let disposeBag = DisposeBag()
    private let configration: Configration
    private let viewModel: AddrBookContactListViewModel
    private let addContactScene: AddContactScene
    private let importPresenter: ContactImportPresenter?
    private let showSkipButton: Bool
    private lazy var searchWrapper: SearchUITextFieldWrapperView = {
        let searchWrapper = SearchUITextFieldWrapperView()
        searchWrapper.searchUITextField.delegate = self
        return searchWrapper
    }()

    private lazy var segmentedDataSource: JXSegmentedTitleDataSource = {
        let segmentedDataSource = JXSegmentedTitleDataSource()
        segmentedDataSource.isTitleColorGradientEnabled = false
        segmentedDataSource.titleNormalFont = UIFont.systemFont(ofSize: 14, weight: .medium)
        segmentedDataSource.titleNormalColor = UIColor.ud.N500
        segmentedDataSource.titleSelectedColor = UIColor.ud.primaryContentDefault
        // 去除item之间的间距
        segmentedDataSource.itemWidthIncrement = 0
        segmentedDataSource.itemSpacing = 0
        return segmentedDataSource
    }()

    private lazy var segmentedView: JXSegmentedView = {
        let segmentedView = JXSegmentedView()
        let indicator = JXSegmentedIndicatorLineView()
        indicator.indicatorHeight = Layout.indicatorHeight
        indicator.indicatorColor = UIColor.ud.primaryContentDefault

        segmentedView.backgroundColor = UIColor.ud.bgBody
        segmentedView.indicators = [indicator]
        segmentedView.isContentScrollViewClickTransitionAnimationEnabled = false
        // 去除整体内容的左右边距
        segmentedView.contentEdgeInsetLeft = 0
        segmentedView.contentEdgeInsetRight = 0
        segmentedView.delegate = self
        return segmentedView
    }()

    private lazy var listContainerView: JXSegmentedListContainerView = {
        return JXSegmentedListContainerView(dataSource: self)
    }()

    private let pushCenter: PushNotificationCenter
    private let userResolver: UserResolver
    private let skipCallback: ((_ viewController: AddrBookContactListController) -> Void)?

    init(addContactScene: AddContactScene,
         resolver: UserResolver,
         importPresenter: ContactImportPresenter? = nil,
         pushCenter: PushNotificationCenter,
         showSkipButton: Bool = false,
         skipCallback: ContactSkipCallback? = nil) {
        self.addContactScene = addContactScene
        self.userResolver = resolver
        self.importPresenter = importPresenter
        self.pushCenter = pushCenter
        self.showSkipButton = showSkipButton
        self.skipCallback = skipCallback
        self.viewModel = AddrBookContactListViewModel(addContactScene: addContactScene, resolver: resolver)
        switch addContactScene {
        case .importFromContact, .newContact:
            self.configration = Configration(canSearch: true,
                                             title: BundleI18n.LarkContact.Lark_NewContacts_PhoneContactsGeneral)
        case .onBoarding:
            self.configration = Configration(canSearch: false,
                                             title: BundleI18n.LarkContact.Lark_NewContacts_PhoneContactsGeneral)
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - life cycle
    fileprivate func setupSubViews() {
        var curOffsetY: CGFloat = 0

        if configration.canSearch {
            view.addSubview(searchWrapper)
            searchWrapper.snp.makeConstraints { make in
                make.left.right.top.equalToSuperview()
                make.height.equalTo(Layout.searchWrapperHeight)
            }
            curOffsetY += Layout.searchWrapperHeight
        }

        if viewModel.contactTypes.count > 1 {
            view.addSubview(segmentedView)
            segmentedView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalToSuperview().offset(curOffsetY)
                make.height.equalTo(Layout.segmentedViewHeight)
            }
            curOffsetY += Layout.segmentedViewHeight
        }

        view.addSubview(listContainerView)
        segmentedView.dataSource = segmentedDataSource
        segmentedView.listContainer = listContainerView
        listContainerView.snp.makeConstraints { (make) in
            make.left.bottom.right.equalToSuperview()
            make.top.equalToSuperview().offset(curOffsetY)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.bgBody
        self.titleString = configration.title
        setupSubViews()
        retryLoadingView.retryAction = { [weak self] in
            self?.viewModel.fetchContactList()
        }
        bindViewModel()
        viewModel.fetchContactList()
        AddressBookAppReciableTrack.addressBookPageFirstRenderCostTrack(isNeedNet: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationItems()
    }

    func setupNavigationItems() {
        guard showSkipButton else {
            return
        }

        navigationItem.setHidesBackButton(true, animated: false)
        navigationItem.leftBarButtonItem = nil

        let skipItem = LKBarButtonItem(image: nil, title: BundleI18n.LarkContact.Lark_Guide_VideoSkip)
        skipItem.button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        skipItem.button.addTarget(self, action: #selector(skipStep), for: .touchUpInside)
        navigationItem.rightBarButtonItem = skipItem
    }

    @objc
    func skipStep() {
        guard let callback = skipCallback else {
            return
        }
        callback(self)
    }

    // MARK: - JXSegmentedListContainerViewDataSource
    func numberOfLists(in listContainerView: JXSegmentedListContainerView) -> Int {
        return viewModel.subViewModels.count
    }

    func listContainerView(_ listContainerView: JXSegmentedListContainerView, initListAt index: Int) -> JXSegmentedListContainerViewListDelegate {
        let subViewController = AddrBookContactListSubViewController(viewModel: viewModel.subViewModels[index],
                                                                           importPresenter: importPresenter,
                                                                     resolver: userResolver)
        subViewController.onCellButtonClick = { [weak self] (_, contactType) in
            switch contactType {
            case .using:
                self?.trackAddFriend()
            case .notYet:
                Tracer.trackAddressbookInvite()
            }

        }
        return subViewController
    }

    // MARK: - JXSegmentedViewDelegate
    func segmentedView(_ segmentedView: JXSegmentedView, didClickSelectedItemAt index: Int) {
        guard viewModel.contactTypes.count > index else {
            return
        }
        switch viewModel.contactTypes[index] {
        case .using:
            Tracer.trackAddressbookUsingClick()
        case .notYet:
            Tracer.trackAddressbookUnusingClick()

        }
    }
    // MARK: UITextFieldDelegate
    func textFieldDidBeginEditing(_ textField: UITextField) {
        Tracer.trackAddressbookSearchClick()
    }

    // MARK: - private
    private func title(_ contactType: ContactType) -> String {
        switch contactType {
        case .using:
            return BundleI18n.LarkContact.Lark_NewContacts_MobileContactsUsingLark()
        case .notYet:
            return BundleI18n.LarkContact.Lark_NewContacts_MobileContactsInviteToLark()
        }
    }

    func trackAddFriend() {
        switch addContactScene {
        case .newContact:
            Tracer.trackNewContactAddClick()
        case .importFromContact, .onBoarding:
            Tracer.trackAddressbookAdd()
        }
    }

    func bindViewModel() {
        self.searchWrapper.searchUITextField.rx.text
            .asDriver()
            .distinctUntilChanged()
            .debounce(.milliseconds(500))
            .drive(onNext: { [weak self] (searchKey) in
                self?.viewModel.searchContact(searchKey ?? "")
            }).disposed(by: disposeBag)

        viewModel.reloadDriver.drive(onNext: { [weak self] (reloadIndex) in
            guard let self = self,
                !self.viewModel.subViewModels.isEmpty else {
                    return
            }
            self.reloadData(reloadIndex)

        }).disposed(by: disposeBag)

        viewModel.statusDirver.drive(onNext: { [weak self] (viewStatus) in
            self?.updateViewStatus(viewStatus)
        }).disposed(by: disposeBag)

        pushCenter.driver(for: PushAddContactSuccessMessage.self)
            .drive(onNext: { [weak self] (messgae) in
                self?.viewModel.addContactSuccess(userId: messgae.userId)
        }).disposed(by: disposeBag)

        pushCenter.driver(for: PushChatApplicationGroup.self)
            .drive(onNext: { [weak self] (chatApplicationGroup) in
                let userIDs = chatApplicationGroup.applications
                    .filter { $0.status == .agreed }
                    .map { $0.contactSummary.userId }
                self?.viewModel.updateUsingContact(userIDs)
        }).disposed(by: disposeBag)
    }

    func updateViewStatus(_ viewStatus: AddrBookContactListViewModel.ViewStatus) {
        switch viewStatus {
        case .loading:
            retryLoadingView.isHidden = true
            loadingPlaceholderView.isHidden = false
        case .loadFinish:
            retryLoadingView.isHidden = true
            loadingPlaceholderView.isHidden = true
        case .meetError:
            retryLoadingView.isHidden = false
            loadingPlaceholderView.isHidden = true
        }
    }

    func reloadData(_ reloadIndex: Int) {
        let viewWidth = view.bounds.size.width
        let itemWidth = viewWidth / CGFloat(viewModel.subViewModels.count)
        segmentedDataSource.itemContentWidth = itemWidth
        segmentedDataSource.titles = viewModel.contactTypes.map { title($0) }
        segmentedView.defaultSelectedIndex = reloadIndex
        segmentedView.reloadData()
    }
}

extension AddrBookContactListController {
    enum Layout {
        static let segmentedViewHeight: CGFloat = 54
        static let searchWrapperHeight: CGFloat = 58
        static let indicatorHeight: CGFloat = 2
        static let listContainerViewTop: CGFloat = 8
    }

    struct Configration {
        let canSearch: Bool
        let title: String
    }
}
