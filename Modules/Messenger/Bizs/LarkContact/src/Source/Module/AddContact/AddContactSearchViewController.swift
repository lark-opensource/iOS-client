//
//  AddContactSearchViewController.swift
//  LarkContact
//
//  Created by ChalrieSu on 2018/9/13.
//

import Foundation
import UIKit
import LarkUIKit
import LarkModel
import RxSwift
import RxCocoa
import LarkCore
import LarkSDKInterface

protocol AddContactSearchViewControllerDelegate: AnyObject {
    func searchViewController(_ vc: AddContactSearchViewController, didSelect userProfile: UserProfile)
    func searchViewController(_ vc: AddContactSearchViewController, didClickInviteOtherWith content: String)
}

final class AddContactSearchViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

    enum State {
        case none
        case loading
        case showSearchButton(String)
        case showSearchResult([UserProfile])
    }

    private let applicationAPI: ChatApplicationAPI
    private let enableInviteFriends: Bool
    weak var delegate: AddContactSearchViewControllerDelegate?

    // DATA
    private let currentState = BehaviorRelay<State>(value: .none)
    private let disposeBag = DisposeBag()
    private var isFirstShow: Bool = true

    // UI
    let searchBar = SearchBar(style: .search)
    private var searchTextField: UITextField { return searchBar.searchTextField }
    private let noResultView: AddContactNoResultView
    private let searchResultView: SearchResultView
    private var tableview: UITableView { return searchResultView.tableview }

    init(chatApplicationAPI: ChatApplicationAPI, enableInviteFriends: Bool) {
        self.applicationAPI = chatApplicationAPI
        self.enableInviteFriends = enableInviteFriends
        // 邀请朋友需要响应FG Key配置
        self.noResultView = AddContactNoResultView(enableInviteFriends: self.enableInviteFriends)
        self.searchResultView = SearchResultView(tableStyle: .plain, noResultView: noResultView)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        isNavigationBarHidden = true

        view.addSubview(searchBar)
        searchBar.snp.makeConstraints { (make) in
            make.top.equalTo(viewTopConstraint)
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-8)
            make.height.equalTo(44)
        }
        searchTextField.placeholder = BundleI18n.LarkContact.Lark_Legacy_PhoneOrEmail
        searchTextField.returnKeyType = .search
        searchTextField.delegate = self
        searchBar.cancelButton.addTarget(self, action: #selector(cancelButtonDidClick), for: .touchUpInside)

        noResultView.bottomButtonClickedBlock = { [weak self] (_ ) in
            guard let `self` = self else { return }
            Tracer.trackFailSearchThenInvite()
            self.delegate?.searchViewController(self, didClickInviteOtherWith: self.searchTextField.text ?? "")
        }
        searchResultView.isHidden = true
        searchResultView.noResultView.lu.addTapGestureRecognizer(action: #selector(bgViewTapped), target: self)
        view.addSubview(searchResultView)
        tableview.lu.register(cellSelf: AddContactTableViewCell.self)
        tableview.lu.register(cellSelf: AddContactSearchTableViewCell.self)
        tableview.rowHeight = 68
        tableview.separatorStyle = .none
        tableview.delegate = self
        tableview.dataSource = self
        tableview.separatorStyle = .none
        tableview.keyboardDismissMode = .onDrag
        searchResultView.snp.makeConstraints { (make) in
            make.top.equalTo(searchBar.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }

        currentState.subscribe(onNext: { [weak self] (state) in
            guard let `self` = self else { return }
            switch state {
            case .none:
                self.searchResultView.isHidden = true
            case .loading:
                self.searchResultView.isHidden = false
                self.searchResultView.status = .loading
            case .showSearchButton:
                self.searchResultView.isHidden = false
                self.searchResultView.status = .result
                self.tableview.reloadData()
            case .showSearchResult(let userInfos):
                self.searchResultView.isHidden = false
                if userInfos.isEmpty {
                    self.searchResultView.status = .noResult("")
                } else {
                    self.searchResultView.status = .result
                    self.tableview.reloadData()
                }
            }
        })
        .disposed(by: disposeBag)

        searchTextField.rx
            .text
            .map { $0 ?? "" }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] (text) in
                guard let `self` = self else { return }
                if text.isEmpty {
                    self.currentState.accept(.none)
                } else {
                    self.currentState.accept(.showSearchButton(text))
                }
            })
            .disposed(by: disposeBag)

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isFirstShow {
            searchTextField.becomeFirstResponder()
            isFirstShow = false
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchTextField.resignFirstResponder()
    }

    @objc
    private func cancelButtonDidClick() {
        navigationController?.popViewController(animated: false)
    }

    @objc
    private func bgViewTapped() {
        searchTextField.resignFirstResponder()
    }

    private func searchResult(text: String) {
        currentState.accept(.loading)
        applicationAPI.searchUser(contactContent: text)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (userInfos) in
                guard let `self` = self else { return }
                self.currentState.accept(.showSearchResult(userInfos))
            }, onError: { [weak self] (_) in
                self?.currentState.accept(.showSearchResult([]))
            })
            .disposed(by: disposeBag)
    }
    // MARK: - UITableViewDelegate, UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch currentState.value {
        case .none, .loading:
            return 0
        case .showSearchButton:
            return 1
        case .showSearchResult(let userInfos):
            return userInfos.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch currentState.value {
        case .showSearchButton(let text):
            let reuseID = String(describing: AddContactSearchTableViewCell.self)
            if let cell = tableview.dequeueReusableCell(withIdentifier: reuseID) as? AddContactSearchTableViewCell {
                cell.setSearchText(text)
                return cell
            }
        case .showSearchResult(let userInfos):
            let reuseID = String(describing: AddContactTableViewCell.self)
            if let cell = tableview.dequeueReusableCell(withIdentifier: reuseID) as? AddContactTableViewCell {
                let userInfo: UserProfile = userInfos[indexPath.row]
                cell.set(entityId: userInfo.userId, avatarKey: userInfo.avatarKey,
                         name: userInfo.displayNameForSearch, detail: userInfo.company.tenantName)
                return cell
            }
        case .none, .loading:
            break
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        tableView.deselectRow(at: indexPath, animated: false)
        searchTextField.resignFirstResponder()
        switch currentState.value {
        case .showSearchButton(let text):
            searchResult(text: text)
        case .showSearchResult(let userInfos):
            let userInfo = userInfos[indexPath.row]
            delegate?.searchViewController(self, didSelect: userInfo)
        case .none, .loading:
            break
        }
    }
    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.searchResult(text: self.searchTextField.text ?? "")
        return true
    }
}
