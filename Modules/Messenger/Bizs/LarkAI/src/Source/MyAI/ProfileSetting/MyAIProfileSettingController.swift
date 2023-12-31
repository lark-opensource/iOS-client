//
//  MyAIProfileSettingController.swift
//  LarkAI
//
//  Created by Hayden on 2023/5/29.
//

import RxSwift
import RxCocoa
import FigmaKit
import LarkUIKit
import LKCommonsLogging
import LKCommonsTracker
import LarkMessengerInterface

final class MyAIProfileSettingController: BaseUIViewController, UITableViewDataSource, UITableViewDelegate {
    enum CellType {
        /// 头像
        case avatar(String)
        /// 别名
        case alias(String)
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    static let logger = Logger.log(MyAIProfileSettingController.self, category: "Module.LarkMine.MyAI")

    private lazy var tableView: UITableView = {
        let tableView = InsetTableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 50
        tableView.tableHeaderView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 0.1, height: 8)))
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        tableView.separatorColor = UIColor.ud.lineDividerDefault
        tableView.backgroundColor = UIColor.ud.bgFloatBase
        tableView.lu.register(cellWithClass: MyAIAvatarSettingCell.self)
        tableView.lu.register(cellWithClass: MyAINameSettingCell.self)
        return tableView
    }()
    private var viewModel: MyAISettingViewModel

    private var myAISettingDataSource: [[CellType]] = [
        // Section 0
        [
            .avatar(BundleI18n.LarkAI.MyAI_IM_AISettings_Avatar_Tab),
            .alias(BundleI18n.LarkAI.MyAI_IM_AISettings_Name_Tab)
        ]
    ]

    init(viewModel: MyAISettingViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        titleString = BundleI18n.LarkAI.MyAI_IM_AISettings_Title
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.bottom.top.left.right.equalToSuperview()
        }
        // 监听 MyAI 信息变化，在修改头像、名称后及时更新
        viewModel.myAIService?.info
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.tableView.reloadData()
            }).disposed(by: viewModel.disposeBag)

        // AI Profile 设置页面埋点
        viewModel.reportSettingShown()
    }

    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return myAISettingDataSource.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < myAISettingDataSource.count else {
            return 0
        }
        return myAISettingDataSource[section].count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        48
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section < myAISettingDataSource.count,
                indexPath.row < myAISettingDataSource[indexPath.section].count else {
            return UITableViewCell()
        }
        switch myAISettingDataSource[indexPath.section][indexPath.row] {
        case .avatar:
            let avatarCell = tableView.lu.dequeueReusableCell(withClass: MyAIAvatarSettingCell.self, for: indexPath)
            if let aiAvatar = viewModel.myAIService?.info.value.avatarImage {
                avatarCell.setAvatar(aiAvatar)
            } else {
                avatarCell.setAvatar(viewModel.myAiAvatarKey, entityId: viewModel.myAiId)
            }
            return avatarCell
        case .alias:
            let nameCell = tableView.lu.dequeueReusableCell(withClass: MyAINameSettingCell.self, for: indexPath)
            if let aiName = viewModel.myAIService?.info.value.name {
                nameCell.setName(aiName)
            } else {
                nameCell.setName(viewModel.myAiName)
            }
            return nameCell
        }
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        tableView.deselectRow(at: indexPath, animated: true)
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else {
            return
        }
        guard indexPath.section < myAISettingDataSource.count,
                indexPath.row < myAISettingDataSource[indexPath.section].count else {
            return
        }
        let item = myAISettingDataSource[indexPath.section][indexPath.row]
        switch item {
        case .avatar:
            let avatarSettingController = MyAIAvatarSettingController(viewModel: viewModel)
            let naviVC = LkNavigationController(rootViewController: avatarSettingController)
            // iPad 上 Onboarding 页面大小
            naviVC.preferredContentSize = AICons.iPadModalSize
            naviVC.modalPresentationStyle = .formSheet
            self.present(naviVC, animated: true)
            viewModel.reportAvatarClicked()
        case .alias:
            let nameSettingController = MyAINameSettingController(viewModel: viewModel)
            let naviVC = LkNavigationController(rootViewController: nameSettingController)
            // iPad 上 Onboarding 页面大小
            naviVC.preferredContentSize = AICons.iPadModalSize
            naviVC.modalPresentationStyle = .formSheet
            self.present(naviVC, animated: true)
            viewModel.reportNameClicked()
        }
    }
}
