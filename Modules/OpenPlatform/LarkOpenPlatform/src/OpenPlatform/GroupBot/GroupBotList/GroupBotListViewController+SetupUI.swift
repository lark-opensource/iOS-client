//
//  GroupBotListViewController+SetupUI.swift
//  LarkOpenPlatform
//
//  Created by houjihu on 2021/3/23.
//

import LarkUIKit
import SnapKit
import EENavigator

// MARK: 视图相关
extension GroupBotListViewController {
    /// 设置视图
    func setupViews() {
        setNaviBarInfo()
        setNavigationBarRightItem()
        view.backgroundColor = UIColor.ud.bgBody
        view.addSubview(loadingView)
        view.addSubview(loadFailedView)
        view.addSubview(loadEmptyView)
        view.addSubview(tableView)
        setViewConstraint()
        loadingView.isHidden = true
        loadFailedView.isHidden = true
        loadEmptyView.isHidden = true
        tableView.isHidden = true
    }
    /// 设置视图约束关系
    func setViewConstraint() {
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        loadFailedView.snp.makeConstraints { make in
            make.height.equalTo(240)
            make.width.equalTo(248)
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-120)
        }
        loadEmptyView.snp.makeConstraints { make in
            make.left.right.equalTo(tableView)
            make.centerY.equalTo(loadFailedView)
        }
        loadingView.snp.makeConstraints { make in
            make.edges.equalTo(tableView)
        }
    }
    /// 设置导航栏页面配置信息
    func setNaviBarInfo() {
        addBackItem()
        title = BundleI18n.GroupBot.Lark_Legacy_BOTs
    }

    /// 添加右导航按钮
    func setNavigationBarRightItem() {
        // 针对外部群，因不支持添加除了webhook机器人之外的其他机器人，故本期不展示右上角添加按钮
        if isCrossTenant {
            return
        }

        let rightItem = LKBarButtonItem(title: BundleI18n.GroupBot.Lark_GroupBot_Add)
        rightItem.setBtnColor(color: UIColor.ud.textTitle)
        rightItem.addTarget(self, action: { [weak self] in self?.navigationBarRightItemTapped() }, for: .touchUpInside)
        navigationItem.rightBarButtonItem = rightItem
    }

    /// 右导航按钮点击事件
    func navigationBarRightItemTapped() {
        // 跳转到「添加机器人」页面
        let vc = AddBotViewController(resolver: resolver, chatID: chatID, isCrossTenant: isCrossTenant)
        resolver.navigator.push(vc, from: self)
    }

    /// 页面重新加载事件
    func reloadPage() {
        Self.logger.info("start to reload page")
        dataProduce()
    }

    /// 获取数据
    func dataProduce() {
        onRequestStart()
        // 针对加号菜单，进入导索页时，不再刷新缓存
        dataProvider.updateRemoteItems { [weak self] (error, model) in
            guard let `self` = self else {
                Self.logger.warn("request guideIndex list self released")
                return
            }
            guard error == nil else {
                Self.logger.error("request guideIndex list failed with backEnd-Error: \(error?.localizedDescription ?? "")")
                DispatchQueue.main.async {
                    self.onRequestFailed()
                }
                return
            }
            guard let validModel = model else {
                Self.logger.error("request guideIndex list model exception not valid")
                DispatchQueue.main.async {
                    self.onRequestFailed()
                }
                return
            }
            self.viewModel = GroupBotListPageViewModel(dataModel: validModel)
            DispatchQueue.main.async {
                self.onRequestSuccess()
                // 判断是否需要刷新群设置的机器人个数
            }
        }
    }

    /// 开始请求时，显示loading
    func onRequestStart() {
        if viewModel != nil {
            return
        }
        loadingView.isHidden = false
        loadFailedView.isHidden = true
        loadEmptyView.isHidden = true
        tableView.isHidden = true
    }

    /// 请求成功
    func onRequestSuccess() {
        loadingView.isHidden = true
        loadFailedView.isHidden = true
        if isDataEmpty() {
            loadEmptyView.isHidden = false
            tableView.isHidden = true
        } else {
            loadEmptyView.isHidden = true
            tableView.isHidden = false
        }
        tableView.reloadData()

        if let model = viewModel {
            var botsNum: Int = 0
            let groupCount = model.getDataGroupCount()
            for i in 0..<groupCount {
                botsNum = botsNum + model.getDataGroup(in: i).count
            }

            TeaReporter(eventKey: TeaReporter.key_groupbot_visit_botlist)
                .withDeviceType()
                .withUserInfo(resolver: resolver)
                .withInfo(params: [
                    .isExternal: isCrossTenant,
                    .botsNum: botsNum
                ])
                .report()
        }
    }

    /// 请求失败
    func onRequestFailed() {
        loadingView.isHidden = true
        loadFailedView.isHidden = false
        loadEmptyView.isHidden = true
        tableView.isHidden = true
    }

    /// 判断业务数据是否为空
    func isDataEmpty() -> Bool {
        guard let model = self.viewModel else {
            Self.logger.error("view model is empty")
            return true
        }
        // 判断是否拥有「可用应用」列表
        return (model.availableList?.count ?? 0) == 0
    }
}
