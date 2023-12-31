//
//  AtListViewController.swift
//  Moment
//
//  Created by zc09v on 2021/3/23.
//

import UIKit
import Foundation
import LarkUIKit
import LarkSearchCore
import LarkContainer
import RxSwift
import LKCommonsLogging
import LarkSDKInterface

final class AtListViewController: BaseUIViewController, PickerDelegate, UITableViewDelegate, UITableViewDataSource, UserResolverWrapper {
    let userResolver: UserResolver
    static let logger: Log = Logger.log(AtListViewController.self, category: "Module.Moments.AtList")
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero)
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 64
        tableView.tableFooterView = UIView()
        tableView.register(AtListTableViewCell.self, forCellReuseIdentifier: AtListTableViewCell.indentify)
        return tableView
    }()

    private let chatterPicker: ChatterPicker
    private let disposeBag: DisposeBag = DisposeBag()
    private var users: [MomentUser] = []
    var selectedCallback: ((String) -> Void)?

    @ScopedInjectedLazy private var userAPI: UserApiService?
    @ScopedInjectedLazy private var momentsAccountService: MomentsAccountService?

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        let param = ChatterPicker.InitParam()
        param.includeOuterTenant = false
        self.chatterPicker = ChatterPicker(resolver: self.userResolver, frame: .zero, params: param)
        super.init(nibName: nil, bundle: nil)
        self.chatterPicker.defaultView = tableView
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = BundleI18n.Moment.Lark_Community_PleaseSelectMentionPerson
        self.view.addSubview(chatterPicker)
        chatterPicker.searchPlaceholder = BundleI18n.Moment.Lark_Community_MentionMemberByName
        chatterPicker.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        chatterPicker.delegate = self
        // Do any additional setup after loading the view.
        self.userAPI?
            .getSuggestAtUser(useMock: false)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] (users) in
                self?.users = users
                self?.tableView.reloadData()
            } onError: { [weak self] (error) in
                AtListViewController.logger.error("getSuggestAtUser error", error: error)
                self?.momentsAccountService?.handleOfficialAccountErrorIfNeed(error: error, from: self)
            }.disposed(by: self.disposeBag)
    }
    func picker(_ picker: Picker, didSelected option: Option, from: Any?) {
        self.selectedCallback?(option.optionIdentifier.id)
    }

    func unfold(_ picker: Picker) {
        return
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: AtListTableViewCell.indentify) as? AtListTableViewCell {
            cell.set(user: self.users[indexPath.row])
            return cell
        }
        return UITableViewCell(frame: .zero)
    }

    // swiftlint:disable did_select_row_protection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedCallback?(self.users[indexPath.row].userID)
    }
    // swiftlint:enable did_select_row_protection
}
