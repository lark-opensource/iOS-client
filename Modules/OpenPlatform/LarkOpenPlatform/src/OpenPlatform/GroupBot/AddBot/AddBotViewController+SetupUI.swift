//
//  AddBotViewController+SetupUI.swift
//  LarkOpenPlatform
//
//  Created by houjihu on 2021/3/10.
//

import LarkUIKit
import SnapKit
import LarkMessengerInterface
import EENavigator
import RxSwift
import RxCocoa

// MARK: 视图相关
extension AddBotViewController {
    /// 设置视图
    func setupViews() {
        setNaviBarInfo()
        view.backgroundColor = UIColor.ud.bgBody
        view.addSubview(loadingView)
        view.addSubview(loadFailedView)
        view.addSubview(loadEmptyView)
        view.addSubview(searchEmptyView)
        view.addSubview(textFieldWrap)
        view.addSubview(tableView)
        setViewConstraint()
        loadingView.isHidden = true
        loadFailedView.isHidden = true
        loadEmptyView.isHidden = true
        searchEmptyView.isHidden = true
        textFieldWrap.isHidden = true
        tableView.isHidden = true
    }
    /// 设置视图约束关系
    func setViewConstraint() {
        textFieldWrap.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.height.equalTo(50)
            make.leading.trailing.equalToSuperview()
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(textFieldWrap.snp.bottom)
            make.left.right.bottom.equalToSuperview()
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
        searchEmptyView.snp.makeConstraints { make in
            make.edges.equalTo(tableView)
        }
        loadingView.snp.makeConstraints { make in
            make.edges.equalTo(tableView)
        }
    }
    /// 设置导航栏页面配置信息
    func setNaviBarInfo() {
        addBackItem()
        title = BundleI18n.GroupBot.Lark_GroupBot_AddBot
    }

    /// 添加右导航按钮
    func setNavigationBarRightItem() {
        let rightItem = LKBarButtonItem(image: BundleResources.LarkOpenPlatform.icon_robot_help, title: nil)
        rightItem.addTarget(self, action: { [weak self] in self?.navigationBarRightItemTapped() }, for: .touchUpInside)
        navigationItem.rightBarButtonItem = rightItem
    }

    /// 右导航按钮点击事件
    func navigationBarRightItemTapped() {
        guard let helpURL = helpURL else {
            return
        }
        self.resolver.navigator.push(helpURL, from: self)
    }

    /// 页面重新加载事件
    func reloadPage() {
        Self.logger.info("start to reload page")
        dataProduce(isSearching: false)
    }

    /// 获取数据
    func dataProduce(isSearching: Bool, isSearchTextChanged: Bool = false, query: String = "") {
        onRequestStart(shouldNotShowLoading: !isSearchTextChanged)
        // 针对加号菜单，进入导索页时，不再刷新缓存
        dataProvider.updateRemoteItems(
            isSearching: isSearching,
            query: query
        ) { [weak self] (error, model) in
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
            self.viewModel = AddBotPageViewModel(dataModel: validModel)
            DispatchQueue.main.async {
                self.onRequestSuccess(isSearching: isSearching)
            }
        }
    }

    /// 开始请求时，显示search和loading
    func onRequestStart(shouldNotShowLoading: Bool) {
        if viewModel != nil, shouldNotShowLoading {
            return
        }
        loadingView.isHidden = false
        loadFailedView.isHidden = true
        loadEmptyView.isHidden = true
        searchEmptyView.isHidden = true
        textFieldWrap.isHidden = false
        tableView.isHidden = true
    }

    /// 请求成功
    func onRequestSuccess(isSearching: Bool) {
        loadingView.isHidden = true
        loadFailedView.isHidden = true
        textFieldWrap.isHidden = false
        if isDataEmpty() {
            loadEmptyView.isHidden = isSearching
            searchEmptyView.isHidden = !isSearching
            tableView.isHidden = true
            // 非搜索场景下，如果内容为空，则隐藏搜索框
            if !isSearching {
                textFieldWrap.isHidden = true
            }
        } else {
            loadEmptyView.isHidden = true
            searchEmptyView.isHidden = true
            tableView.isHidden = false
        }
        tableView.reloadData()

        if let model = viewModel {
            let botsNum: Int = model.availableList?.count ?? 0
            let recommendBotsNum: Int = model.unavailableList?.count ?? 0

            let (isSearching, text) = isSearchingMode()
            let eventKey = isSearching ? TeaReporter.key_groupbot_vist_searchresult : TeaReporter.key_groupbot_visit_addbot
            TeaReporter(eventKey: eventKey)
                .withDeviceType()
                .withUserInfo(resolver: resolver)
                .withInfo(params: [
                    .isExternal: isCrossTenant,
                    .botsNum: botsNum,
                    .recommendBotsNum: recommendBotsNum,
                    .query: text
                ])
                .report()
        }
    }

    /// 请求失败
    func onRequestFailed() {
        loadingView.isHidden = true
        loadFailedView.isHidden = false
        loadEmptyView.isHidden = true
        searchEmptyView.isHidden = true
        textFieldWrap.isHidden = true
        tableView.isHidden = true
    }

    /// 判断业务数据是否为空
    func isDataEmpty() -> Bool {
        guard let model = self.viewModel else {
            Self.logger.error("view model is empty")
            return true
        }
        // 判断是否拥有「可用应用」，「获取更多」列表
        return (model.availableList?.count ?? 0) == 0 && (model.unavailableList?.count ?? 0) == 0
    }

    /// 当搜索框文本内容变化时触发事件
    func searchTextFieldEditChanged() {
        let text = textFieldWrap.searchUITextField.text ?? ""
        let tips = BundleI18n.GroupBot.Lark_GroupBot_NoSearchBots(name: text)
        searchEmptyView.updateViews(tips: tips)

        updateDataConsideringSearchText(isSearchTextChanged: true)
    }

    /// 判断当前数据请求是否是搜索模式
    func isSearchingMode() -> (Bool, String) {
        let text = textFieldWrap.searchUITextField.text ?? ""
        // 当搜索文本不为空时进行搜索，否则请求显示全部数据
        let isSearching = !(text.isEmpty)
        return (isSearching, text)
    }

    /// 根据当前搜索框文本内容，更新数据
    func updateDataConsideringSearchText(isSearchTextChanged: Bool = false) {
        // 当搜索文本不为空时进行搜索，否则请求显示全部数据
        let (isSearching, text) = isSearchingMode()
        dataProduce(isSearching: isSearching, isSearchTextChanged: isSearchTextChanged, query: text)
    }

    /// 隐藏键盘
    func dismissKeyboard() {
        if textFieldWrap.searchUITextField.canResignFirstResponder == true {
            textFieldWrap.searchUITextField.resignFirstResponder()
        }
    }

    // MARK: - Router

    /// 跳转到会话
    func gotoChat(chatID: String) {
        let body = ChatControllerByIdBody(chatId: chatID)
        self.resolver.navigator.push(body: body, from: self)
    }

    /// 跳转「应用目录详情页」
    func openAppTableDetail(botModel: AbstractBotModel) {
        guard let botModel = botModel as? RecommendBotModel else {
            Self.logger.error("botModel is not RecommendBotModel")
            return
        }
        let detailMicroAppURL: String? = botModel.detailMicroAppURL
        guard let url = detailMicroAppURL?.possibleURL() else {
            Self.logger.error("addBot page open appTable detail page failed because url is empty")
            return
        }
        Self.logger.info("addBot page open appTable detail page: \(url)")
        self.resolver.navigator.present(url, from: self)
    }

    /// 跳转「应用目录安装页」
    func openAppTableInstall(botModel: AbstractBotModel) {
        guard let botModel = botModel as? RecommendBotModel else {
            Self.logger.error("botModel is not RecommendBotModel")
            return
        }
        let getMicroAppURL: String? = botModel.getMicroAppURL
        guard let url = getMicroAppURL?.possibleURL() else {
            Self.logger.error("addBot page open appTable install page failed because url is empty")
            return
        }
        Self.logger.info("addBot page open appTable install page: \(url)")
        self.resolver.navigator.present(url, from: self)

        TeaReporter(eventKey: TeaReporter.key_groupbot_click_addbot_get)
            .withDeviceType()
            .withUserInfo(resolver: resolver)
            .withInfo(params: [
                .appName: botModel.name ?? "",
                .appID: botModel.appID,
                .botType: botModel.botType.rawValue
            ])
            .report()
    }
}
