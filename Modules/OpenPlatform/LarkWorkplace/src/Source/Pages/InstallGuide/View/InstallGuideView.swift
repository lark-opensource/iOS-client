//
//  InstallGuideView.swift
//  LarkWorkplace
//
//  Created by tujinqiu on 2020/3/13.
//

import UIKit

typealias OnboardingInstallObserver = (Bool) -> Void

// 同时被AppCenter和WorkPlace依赖
// 工作台 onboarding 的页面，包括上方的header，中间的tableView和下面的footer
final class InstallGuideView: UIView {
    private static let cellIdentifier = "InstallGuideCell"

    private let viewWidth: CGFloat // 用于LKLabel富文本在渲染的时候指定preferredMaxLayoutWidth
    private lazy var header: InstallGuideHeader = {
        let v = InstallGuideHeader(
            hasSafeArea: self.viewModel.hasSafeArea,
            isFromOperation: isFromOperation
        )
        v.backgroundColor = UIColor.ud.bgBody
        return v
    }()
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.register(InstallGuideCell.self, forCellReuseIdentifier: InstallGuideView.cellIdentifier)
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.estimatedRowHeight = InstallGuideCell.cellHeight
        tableView.rowHeight = UITableView.automaticDimension
        return tableView
    }()
    private lazy var footer: InstallGuideFooter = {
        let v = InstallGuideFooter(viewWidth: viewWidth)
        return v
    }()
    private lazy var tableHeader: InstallGuideTableViewHeader = {
        let header = InstallGuideTableViewHeader()
        let placeholder = viewModel.isAdmin ?
            BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_GuideAdminTitlePlaceholder :
            BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_GuideUserTitlePlaceholder
        let allStr = viewModel.isAdmin ?
            BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_GuideAdminTitleAll(placeholder) :
            BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_GuideUserTitleAll(placeholder)
        if let range = allStr.range(of: placeholder) {
            let nsRange = NSRange(range, in: allStr)
            header.attributedText = InstallGuideTableViewHeader.getAttributedText(allStr, nsRange)
        }
        return header
    }()

    private let viewModel: InstallGuideViewModel
    /// 是否来自于运营位入口
    let isFromOperation: Bool
    var installHandler: ((Bool, InstallGuideViewModel, @escaping OnboardingInstallObserver) -> Void)
    /// 完成回调，Bool --> 是否是跳过
    var completion: ((Bool) -> Void)

    let context: WorkplaceContext

    init(
        context: WorkplaceContext,
        isFromOperation: Bool,
        viewModel: InstallGuideViewModel,
        viewWidth: CGFloat,
        installHandler: @escaping (Bool, InstallGuideViewModel, @escaping OnboardingInstallObserver) -> Void,
        completion: @escaping (Bool) -> Void
    ) {
        self.context = context
        self.isFromOperation = isFromOperation
        self.viewModel = viewModel
        self.installHandler = installHandler
        self.completion = completion
        self.viewWidth = viewWidth
        super.init(frame: .zero)
        setupSubviews()
        registerActions()
    }

    private func setupSubviews() {
        backgroundColor = UIColor.ud.bgBody
        addSubview(header)
        header.snp.makeConstraints { (make) in
            let height = viewModel.hasSafeArea ? 91 : 75
            make.height.equalTo(height)
            make.left.right.top.equalToSuperview()
        }
        addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.top.equalTo(header.snp.bottom)
            make.left.right.equalToSuperview()
        }
        let rect = tableHeader.attributedText.boundingRect(
            with: CGSize(width: viewWidth - 16 * 2, height: CGFloat(MAXFLOAT)),
            options: .usesLineFragmentOrigin,
            context: nil
        )
        let numberOfLines = Int(rect.height / 20.0)
        // swiftlint:disable line_length
        let tableHeaderHeight = numberOfLines > 1 ? InstallGuideTableViewHeader.multiLinesHeight : InstallGuideTableViewHeader.singleLineHeight
        // swiftlint:enable line_length
        tableHeader.frame = CGRect(
            x: 0,
            y: 0,
            width: 0,
            height: tableHeaderHeight
        )
        tableView.tableHeaderView = tableHeader

        addSubview(footer)
        footer.snp.makeConstraints { (make) in
            make.top.equalTo(tableView.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom)
        }
        footer.seletctedCount = 0
        footer.isAllSelected = false
    }

    private func updateViews() {
        footer.seletctedCount = viewModel.onboardingApps.reduce(0, { (count, model) -> Int in
            return count + (model.isSelected ? 1 : 0)
        })
        footer.isAllSelected = (footer.seletctedCount == viewModel.onboardingApps.count)
        self.tableView.reloadData()
    }

    private func registerActions() {
        // 点击跳过 / 关闭
        header.skipHandler = { [weak self] in
            self?.removeFromSuperview()
            // 业务埋点上报
            // 是否来自于运营活动打开
            if self?.isFromOperation ?? false {
                self?.completion(false) // 认为是「关闭」
                self?.context.tracker
                    .start(.appcenter_operation_installapp_skip)
                    .post()
            } else {
                self?.completion(true)  // 认为是「跳过」
                self?.context.tracker
                    .start(.appcenter_onboardinginstall_skip)
                    .post()
            }
        }

        let observer = { [weak self] (success: Bool) in
            if success { // 安装成功移除引导页
                self?.removeFromSuperview()
                self?.completion(false)
            } else { // 安装失败继续
                self?.footer.isReinstall = true
            }
        }
        footer.actionHandler = { [weak self] action in
            guard let `self` = self else {
                return
            }
            switch action {
            case .selectAll(let selected): // 全选
                self.viewModel.onboardingApps.forEach { (model) in
                    model.isSelected = selected
                }
                self.updateViews()
            case .install: // 安装
                self.installHandler(self.isFromOperation, self.viewModel, observer)
            case .gotoClause: // 跳转权限条款页面
                self.viewModel.gotoClausePage()
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension InstallGuideView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.onboardingApps.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: InstallGuideView.cellIdentifier, for: indexPath)
        if let installCell = cell as? InstallGuideCell {
            let model = viewModel.onboardingApps[indexPath.row]
            installCell.update(model: model)
            installCell.actionHandler = { [weak self] action in
                switch action {
                case .tapIconOrName(let item):
                    item.gotoDetail() // 跳转商店详情页面
                    if self?.isFromOperation ?? true {
                        self?.context.tracker
                            .start(.appcenter_operation_installapp_viewdetail)
                            .setValue(item.app.appId, for: .appid)
                            .post()
                    } else {
                        self?.context.tracker
                            .start(.appcenter_onboardinginstall_viewdetail)
                            .setValue(item.app.appId, for: .appid)
                            .post()
                    }
                case .select(let isSelected, let item):
                    item.isSelected = isSelected
                    self?.updateViews()
                }
            }
        }
        return cell
    }
}
