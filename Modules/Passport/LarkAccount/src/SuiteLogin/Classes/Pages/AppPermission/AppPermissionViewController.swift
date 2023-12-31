//
//  AppPermissionViewController.swift
//  LarkAccount
//
//  Created by Nix Wang on 2022/12/12.
//

import UIKit
import UniverseDesignEmpty
import SnapKit
import LarkContainer
import EENavigator
import LarkUIKit
import LKCommonsLogging
import RxSwift
import UniverseDesignToast

class AppPermissionViewController: BaseViewController {
    static let logger = Logger.plog(AppPermissionViewController.self, category: "SuiteLogin")

    @InjectedLazy private var loginService: V3LoginService

    var vm: AppPermissionViewModel

    let cellHeight: CGFloat = 72.0
    lazy var tableView: UITableView = {
        let tb = UITableView()
        tb.lu.register(cellSelf: AppPermissionTableViewCell.self)
        tb.backgroundColor = .clear
        tb.separatorStyle = .none
        tb.rowHeight = cellHeight
        tb.dataSource = self
        tb.delegate = self
        tb.showsVerticalScrollIndicator = false
        return tb
    }()

    init(viewModel vm: AppPermissionViewModel) {
        self.vm = vm

        super.init(viewModel: vm)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        tableView.reloadData()
    }

    private func setupViews() {

        // Header
        let headerView = UIView()

        let illustration = EmptyBundleResources.image(named: "emptyNeutralNoApplication")
        let imageView = UIImageView(image: illustration)
        imageView.contentMode = .scaleAspectFit
        imageView.snp.makeConstraints { make in
            make.height.equalTo(100)
        }

        let titleLabel = UILabel()
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.textAlignment = .center
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.text = vm.appPermissionInfo.title

        let subtitleLabel = LinkClickableLabel.default(with: self)
        subtitleLabel.textColor = UIColor.ud.textCaption
        subtitleLabel.textAlignment = .center
        subtitleLabel.textContainerInset = .zero
        subtitleLabel.textContainer.lineFragmentPadding = 0
        if let richText = vm.appPermissionInfo.richSubtitle {
            let links = richText.links?.compactMap({ link in
                if let url = URL(string: link.url) {
                    return (name: link.name, url: url)
                }

                return nil
            })
            subtitleLabel.attributedText = .makeLinkString(plainString: richText.plainText,
                                                           links: links ?? [],
                                                           boldTexts: richText.boldTexts ?? [],
                                                           alignment: .center,
                                                           color: .ud.textCaption)
        }
        // TableView
        tableView.layer.cornerRadius = 8.0
        tableView.layer.masksToBounds = true
        let userCount = userList?.count ?? 0
        let tableViewHeight: CGFloat
        if userCount < 5 {
            tableViewHeight = CGFloat(userCount) * cellHeight
            tableView.isScrollEnabled = false
        } else {
            tableViewHeight = 4.5 * cellHeight
        }
        tableView.snp.makeConstraints { make in
            make.height.equalTo(tableViewHeight)
        }

        // Footer
        let addAccountView = AddAccountView()
        addAccountView.actionBlock = { [weak self] in
            guard let self = self else { return }

            Self.logger.info("n_action_permssion_add_account")

            let loginVC = self.loginService.createLoginVC(fromUserCenter: true, context: UniContextCreator.create(.appPermission))
            if Display.pad {
                Navigator.shared.push(loginVC, from: self) // user:checked (navigator)
            } else {
                //iPad上 current navigation VC 已经是 passport loginNavVC；
                //因为不确定iPad为啥改成push，所以本次修改保留iPad老逻辑，只修改iPhone
                let targetVC = LoginNaviController(rootViewController: loginVC)
                targetVC.modalPresentationStyle = .fullScreen
                Navigator.shared.present(targetVC, from: self) // user:checked (navigator)
            }
        }

        let stackView = UIStackView(arrangedSubviews: [imageView, titleLabel, subtitleLabel, tableView, addAccountView])
        stackView.setCustomSpacing(8.0, after: titleLabel)
        stackView.setCustomSpacing(16.0, after: tableView)
        stackView.axis = .vertical
        stackView.spacing = 12.0
        moveBoddyView.addSubview(stackView)
        let topInset = BaseLayout.visualNaviBarHeight + CL.itemSpace
        stackView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(topInset)
            make.left.right.equalToSuperview().inset(CL.itemSpace)
            make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide.snp.bottom)
        }

        // Hide next button
        bottomView.removeFromSuperview()

    }

}

extension AppPermissionViewController: UITableViewDataSource, UITableViewDelegate {

    var userList: [V4UserItem]? {
        return vm.appPermissionInfo.groupList?.first?.userList
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userList?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "AppPermissionTableViewCell", for: indexPath) as? AppPermissionTableViewCell,
              let userList = userList,
              indexPath.row < userList.count else {
            return UITableViewCell()
        }

        let item = userList[indexPath.row]
        cell.setup(userItem: item) { [weak self] userID in
            Self.logger.info("n_action_permssion_switch_account", body: "userID: \(userID)")

            self?.vm.switchTo(userID: userID)
        }
        return cell
    }

}

extension AppPermissionViewController {
    override func handleClickLink(_ URL: URL, textView: UITextView) {
        Self.logger.info("n_action_permssion_tap_link", body: "path: \(URL.path)")

        let applyPath = "/accounts/approval/platform/form"
        if URL.path == applyPath {
            Self.logger.info("n_action_permssion_apply_form_start")
            showLoading()
            vm.applyForm()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    Self.logger.info("n_action_permssion_apply_form_succ")

                    self?.stopLoading()
                }, onError: { [weak self] error in
                    Self.logger.error("n_action_permssion_apply_form_fail", error: error)

                    self?.stopLoading()
                    self?.handle(error)

                })
                .disposed(by: disposeBag)
        } else {
            super.handleClickLink(URL, textView: textView)
        }
    }
}
