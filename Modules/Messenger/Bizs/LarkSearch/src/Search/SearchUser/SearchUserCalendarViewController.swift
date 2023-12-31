//
//  SearchUserCalendarViewController.swift
//  LarkSearch
//
//  Created by heng zhu on 2019/2/18.
//

import UIKit
import Foundation
import Homeric
import SnapKit
import RxSwift
import LarkModel
import LarkCore
import LarkUIKit
import LKCommonsLogging
import LKCommonsTracker
import UniverseDesignToast
import LarkAccountInterface
import LarkSDKInterface
import LarkSearchCore
import LarkContainer

public final class SearchUserCalendarViewController: BaseUIViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, SearchResultViewListBindDelegate {
    static let logger = Logger.log(SearchUserCalendarViewController.self, category: "Module.IM.Search")

    private let searchNaviBar = SearchNaviBar(style: .search)
    private var searchField: UITextField!
    private lazy var defaultView: SearchDefaultView = {
        return SearchDefaultView(hasSearchItems: false, text: BundleI18n.LarkSearch.Calendar_Transfer_SearchOrganizer)
    }()
    //Dependcy
    private let searchAPI: SearchAPI
    private let doTransfer: ((String, String) -> Void)?
    private let eventOrganizerId: String

    private var currentTenantId: String = ""

    private let disposeBag = DisposeBag()

    public let userResolver: UserResolver
    public init(userResolver: UserResolver,
                searchAPI: SearchAPI,
                eventOrganizerId: String,
                doTransfer: ((String, String) -> Void)?) {
        self.userResolver = userResolver
        self.searchAPI = searchAPI
        self.doTransfer = doTransfer
        self.eventOrganizerId = eventOrganizerId
        do {
            self.currentTenantId = (try userResolver.resolve(assert: PassportUserService.self)).userTenant.tenantID
        } catch {
            Self.logger.info("revole passport failed")
        }

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: SearchResultViewListBindDelegate
    public typealias Item = SearchResultType

    public var searchLocation: String { "contact" }
    public var listState: SearchListStateCases?
    public var results: [Item] = []
    public var listvm: ListVM { vm.result }
    public let resultView: SearchResultView = SearchResultViewSpec()

    private lazy var vm: SearchSimpleVM<Item> = {
        func makeSource(searchAPI: SearchAPI) -> SearchSource {
            var maker = RustSearchSourceMaker(resolver: self.userResolver, scene: .rustScene(.searchUsers))
            maker.needSearchOuterTenant = true
            maker.authPermissions = [.inviteSameChat, .checkBlock]
            maker.doNotSearchResignedUser = true
            return maker.makeAndReturnProtocol()
        }
        let source = makeSource(searchAPI: self.searchAPI)
        let listvm = SearchListVM(
            source: source, compactMap: { [weak self] (item: SearchItem) -> Item? in
                guard let self = self, let result = item as? Search.Result else { return nil }
                return self.filter(result: result) ? result : nil
            })
        return SearchSimpleVM(result: listvm)
    }()
    private func filter(result: SearchResultType) -> Bool {
        // NOTE: run on sub serial queue
        var isExternal = false
        switch result.meta {
        case .chatter(let meta):
            if meta.tenantID != self.currentTenantId, !isCustomer(tenantId: self.currentTenantId) {
                isExternal = true
            }
        default:
            isExternal = false
        }
        return self.eventOrganizerId != result.id && !isExternal
    }

    public func showPlaceholder(state: ListVM.State) {
        defaultView.isHidden = false
        resultView.isHidden = true
    }
    public func hidePlaceholder(state: ListVM.State) {
        defaultView.isHidden = true
        resultView.isHidden = false
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.ud.bgBody
        isNavigationBarHidden = true

        initSearchBar()
        initSearchResultView()
        initSearchDefaultView()

        self.bindResultView().disposed(by: disposeBag)
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setSwipeBack(enabled: false)
    }

    fileprivate func initSearchBar() {
        searchBar.searchTextField.autocorrectionType = .no
        view.addSubview(searchNaviBar)
        searchNaviBar.snp.makeConstraints { (make) in
            make.left.top.right.equalToSuperview()
        }

        let searchArea = searchNaviBar.searchbar
        searchArea.cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        searchArea.searchTextField.placeholder = BundleI18n.LarkSearch.Lark_Legacy_Search

        searchField = searchArea.searchTextField
        searchField.delegate = self
        searchField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)
        searchField.becomeFirstResponder()
    }

    fileprivate func initSearchResultView() {
        resultView.tableview.delegate = self
        resultView.tableview.dataSource = self
        resultView.isHidden = true
        view.addSubview(resultView)
        resultView.snp.makeConstraints({ make in
            make.top.equalTo(searchNaviBar.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        })

        resultView.tableview.lu.register(cellSelf: SearchUserTableViewCell.self)

        // 点击取消输入
        let tap = UITapGestureRecognizer(target: self, action: #selector(backgroundTapHandler))
        tap.cancelsTouchesInView = false
        resultView.addGestureRecognizer(tap)
    }

    fileprivate func initSearchDefaultView() {
        view.addSubview(defaultView)
        defaultView.snp.makeConstraints({ make in
            make.top.equalTo(searchNaviBar.snp.bottom)
            make.left.right.equalToSuperview()
        })
    }

    @objc
    fileprivate func searchTextChanged() {
        guard self.searchField.markedTextRange == nil else { return }
        vm.query.text.accept(searchField.text ?? "")
    }

    @objc
    fileprivate func cancelButtonTapped() {
        if navigationController?.viewControllers.count ?? 0 > 1 {
            navigationController?.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }

    @objc
    fileprivate func backgroundTapHandler() {
        searchField.resignFirstResponder()
    }

    func setSwipeBack(enabled: Bool) {
        self.naviPopGestureRecognizerEnabled = enabled
    }
    // MARK: - UITableViewDelegate, UITableViewDataSource
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = String(describing: SearchUserTableViewCell.self)
        if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? SearchUserTableViewCell,
           let userType = try? userResolver.resolve(assert: PassportUserService.self).user.type {
            let user = results[indexPath.row]
            if case let .chatter(chatterMeta) = user.meta,
               !chatterMeta.deniedPermissions.isEmpty {
                cell.contentView.alpha = 0.5
            } else {
                cell.contentView.alpha = 1
            }
            cell.setContent(searchResult: user,
                            searchText: searchField.text,
                            currentTenantId: currentTenantId,
                            hideCheckBox: true,
                            currentUserType: userType)
            return cell
        }
        return UITableViewCell()
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        tableView.deselectRow(at: indexPath, animated: true)
        let row = indexPath.row
        let result = results[row]

        if case let .chatter(chatterMeta) = result.meta,
                       !chatterMeta.deniedPermissions.isEmpty {
            UDToast.showTips(with: BundleI18n.LarkSearch.Calendar_G_CreateEvent_UserList_CantInvite_Hover, on: self.view)
                       return
                   }
        doTransfer?(result.title.string, result.id)
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }

    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 68
    }
    // MARK: - UITextFieldDelegate
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
// 修复iPad视图约束问题补丁,ipad下noResultView的约束不能和window绑定
open class SearchResultViewSpec: SearchResultView {
    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if Display.pad {
            self.noResultView.snp.remakeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.top.equalToSuperview()
                make.width.equalToSuperview()
            }
        }
    }
}

extension SearchUserCalendarViewController: SearchBarTransitionTopVCDataSource {
    public var searchBar: SearchBar { return searchNaviBar.searchbar }
    public var bottomView: UIView { return UIView() }
}
