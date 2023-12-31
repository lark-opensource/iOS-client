//
//  AppSettingViewController.swift
//  LarkAppCenter
//
//  Created by yuanping on 2019/4/19.
//

import LarkUIKit
import RxSwift
import SnapKit
import Swinject
import EEMicroAppSDK
import ECOProbe
import LarkSplitViewController
import UniverseDesignIcon
import LKCommonsLogging
import UniverseDesignEmpty
import LarkOPInterface
import LarkContainer

class AppSettingViewController: BaseUIViewController, UITableViewDataSource, UITableViewDelegate {
    static let logger = Logger.oplog(AppSettingViewController.self, category: "app_setting")

    private lazy var contentView: UIView = {
        let contentView = UIView()
        contentView.backgroundColor = UIColor.ud.bgBase
        return contentView
    }()

    private lazy var errorView: UIView = {
        let errorView = UIView()
        errorView.backgroundColor = UIColor.ud.bgBody
        return errorView
    }()

    private lazy var titleNaviBar: TitleNaviBar = {
        let titleNaviBar = TitleNaviBar(titleString: BundleI18n.AppDetail.AppDetail_H5_About_PageName)
        titleNaviBar.backgroundColor = UIColor.ud.bgBody
        return titleNaviBar
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.estimatedRowHeight = 0
        tableView.separatorStyle = .none
        return tableView
    }()

    private lazy var appShareButton: UIButton = {
        let button = UIButton(type: .custom)
        let image = UDIcon.getIconByKey(UDIconType.shareOutlined, iconColor: UIColor.ud.iconN1)
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(appShareClick), for: .touchUpInside)
        return button
    }()

    private let disposeBag = DisposeBag()
    private var appSettingModel: AppSettingViewModel
    private var versionModel: AppSettingVersionViewModel
    private let cellIdentifier = "AppSettingCellIdentifier"
    private let resolver: UserResolver

    init(botId: String = "",
         appId: String = "",
         params: [String: String]? = nil,
         scene: AppSettingOpenScene,
         resolver: UserResolver) throws {
        appSettingModel = try AppSettingViewModel(botId: botId,
                                              appId: appId,
                                              params: params,
                                              scene: scene,
                                              resolver: resolver)
        self.resolver = resolver
        versionModel = AppSettingVersionViewModel(appID: appId, scene: scene, resolver: resolver)
        super.init(nibName: nil, bundle: nil)
        appSettingModel.delegate = self
        versionModel.delegate = self
        appSettingModel.isShowShare = isShowShare(appId: appId)
        versionModel.isShowMarginInset = true
        appSettingModel.superViewSize = { [weak self] in
            var size: CGSize?
            if Thread.isMainThread {
                size = self?.navigationController?.view.bounds.size ?? self?.view.bounds.size
            } else {
                DispatchQueue.main.sync {
                    size = self?.navigationController?.view.bounds.size ?? self?.view.bounds.size
                }
            }
            return size ?? .zero
        }
        versionModel.fetchMeta()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        isNavigationBarHidden = true
        view.backgroundColor = UIColor.ud.bgBase
        appSettingModel.containerWidth = larkSplitViewController?.secondaryViewController?.view.bounds.size.width ?? UIScreen.main.bounds.size.width
        setupLoading()
        setupRetryView()
        setupContentView()
        setupViewModel()
        fetchSettingInfo()
        
        // 产品埋点：分享链路 https://bytedance.feishu.cn/sheets/shtcnxrXP8G9GjHbZ7qE9FGAG0b?sheet=196nOL
        OPMonitor("openplatform_application_about_view")
            .addCategoryValue("app_type", appTypeString())
            .addCategoryValue("application_id", appSettingModel.appId.isEmpty ? "none" : appSettingModel.appId)
            .addCategoryValue("scene_type", "none")
            .addCategoryValue("solution_id", "none")
            .setPlatform([.tea, .slardar])
            .flush()
        
        
        // 当前页面支持 detail 全屏
        self.supportSecondaryOnly = true
        // 当前页面支持 全屏手势
        self.supportSecondaryPanGesture = true
        self.fullScreenSceneBlock = {
            return "appsetting"
        }    

    }

    private func setupLoading() {
        loadingPlaceholderView.snp.remakeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        loadingPlaceholderView.isHidden = true
    }

    private func setupRetryView() {
        view.addSubview(errorView)
        errorView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        errorView.lu.addTapGestureRecognizer(action: #selector(retry), target: self)

        let errorImg = UIImageView(frame: .zero)
        errorImg.image = UDEmptyType.loadingFailure.defaultImage()
        errorImg.clipsToBounds = true
        errorImg.contentMode = UIView.ContentMode.scaleAspectFit
        errorView.addSubview(errorImg)
        errorImg.snp.makeConstraints { (make) in
            make.width.height.equalTo(125)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(appSettingModel.superViewSize().height / 3.0)
        }

        let errorLabel = UILabel(frame: .zero)
        errorLabel.text = BundleI18n.AppDetail.AppDetail_Card_Load_Fail
        errorLabel.textColor = UIColor.ud.textPlaceholder
        errorLabel.textAlignment = .center
        errorLabel.font = UIFont.systemFont(ofSize: 14.0)
        errorLabel.numberOfLines = 0
        errorView.addSubview(errorLabel)
        errorLabel.snp.makeConstraints { (make) in
            make.top.equalTo(errorImg.snp.bottom).offset(4)
            make.leading.equalToSuperview().offset(40)
            make.trailing.equalToSuperview().offset(-40)
        }

        let titleNaviBar = TitleNaviBar(titleString: "")
        titleNaviBar.backgroundColor = .clear
        errorView.addSubview(titleNaviBar)
        titleNaviBar.snp.makeConstraints { (make) in
            make.leading.trailing.top.equalToSuperview()
        }
        let backButton = UIButton(type: .custom)
        let image = UDIcon.leftOutlined.ud.withTintColor(UIColor.ud.iconN1)
        backButton.setImage(image, for: .normal)
        backButton.rx.tap.asDriver().drive(onNext: { [weak self] in
            guard let `self` = self else { return }
            self.navigationController?.popViewController(animated: true)
        }).disposed(by: disposeBag)
        titleNaviBar.contentview.addSubview(backButton)
        backButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(17)
            make.height.width.equalTo(24)
        }
        errorView.isHidden = true
    }

    private func setupContentView() {
        view.addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        contentView.addSubview(titleNaviBar)
        titleNaviBar.snp.makeConstraints { (make) in
            make.leading.trailing.top.equalToSuperview()
        }
        let backButton = UIButton(type: .custom)
        let image = UDIcon.leftOutlined.ud.withTintColor(UIColor.ud.iconN1)
        backButton.setImage(image, for: .normal)
        backButton.rx.tap.asDriver().drive(onNext: { [weak self] in
            guard let `self` = self else { return }
            self.navigationController?.popViewController(animated: true)
        }).disposed(by: disposeBag)
        titleNaviBar.contentview.addSubview(backButton)
        backButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(17)
            make.height.width.equalTo(24)
        }
        titleNaviBar.contentview.addSubview(appShareButton)
        appShareButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
            make.height.width.equalTo(24)
        }
        appShareButton.isHidden = true

        contentView.addSubview(tableView)
        tableView.register(AppSettingCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.register(AppSettingVersionCell.self, forCellReuseIdentifier: AppSettingVersionCell.identifier)
        tableView.snp.makeConstraints { (make) in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(titleNaviBar.snp.bottom)
        }
        contentView.isHidden = true
    }

    private func setupViewModel() {
        appSettingModel.appInfoUpdate
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] (fetchError) in
                guard let `self` = self else { return }
                if fetchError, self.appSettingModel.appDetailInfo != nil { return }
                self.updateContentView(fetchError: fetchError)
            }).disposed(by: disposeBag)
    }

    private func updateContentView(fetchError: Bool = false) {
        if !fetchError, appSettingModel.appDetailInfo != nil {
            tableView.reloadData()
        }
        appShareButton.isHidden = !appSettingModel.isShowShare
        loadingPlaceholderView.isHidden = true
        errorView.isHidden = !fetchError
        contentView.isHidden = fetchError
    }

    /// 是否展示分享入口
    private func isShowShare(appId: String) -> Bool {
        return !appId.isEmpty
    }

    private func fetchSettingInfo() {
        loadingPlaceholderView.isHidden = false
        errorView.isHidden = true
        contentView.isHidden = true
        appSettingModel.fetchAppInfo()
    }

    @objc
    private func retry() {
        fetchSettingInfo()
    }

    @objc
    private func report() {
        appSettingModel.openReport(from: self)
    }

    @objc
    private func appShareClick() {
        appSettingModel.openShare(from: self)
                
        // 产品埋点：分享链路 https://bytedance.feishu.cn/sheets/shtcnxrXP8G9GjHbZ7qE9FGAG0b?sheet=196nOL
        OPMonitor("openplatform_application_about_click")
            .addCategoryValue("app_type", appTypeString())
            .addCategoryValue("click", "app_share")
            .addCategoryValue("target", "openplatform_application_share_view")
            .addCategoryValue("application_id", appSettingModel.appId.isEmpty ? "none" : appSettingModel.appId)
            .addCategoryValue("scene_type", "none")
            .addCategoryValue("solution_id", "none")
            .setPlatform([.tea, .slardar])
            .flush()
    }
    
    private func appTypeString() -> String {
        let appType: String
        switch appSettingModel.scene {
        case .H5:
            appType = "web_app"
        case .MiniApp:
            appType = "mp"
        }
        return appType
    }
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        var index = indexPath.row
        
        if indexPath.row == 1 {
            return
        }
        if indexPath.row > 1 {
            index = indexPath.row - 1
        }
        tableView.deselectRow(at: indexPath, animated: false)
        guard let type = appSettingModel.cellTypeAt(index: index) else { return }
        switch type {
        case .UserAgreement:
            appSettingModel.openUserAgreement(from: self)
        case .PrivacyPolicy:
            appSettingModel.openPrivacyPolicy(from: self)
        case .Developer:
            appSettingModel.openDeveloperChat(from: self)
        default:
            return
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return appSettingModel.heightForCurCell(index: indexPath.row)
        } else if indexPath.row == 1 {  // 这就是这段代码的可怕之处,缺乏统一规划的技术债务
            return versionModel.getCellHeight()
        } else {
            return appSettingModel.heightForCurCell(index: indexPath.row - 1)
        }
    }
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return appSettingModel.cellCount() + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = newGetCell(tableView: tableView, cellForRowAt: indexPath)
        cell.clipsToBounds = true
        return cell
    }

    private func oldGetCell(tableView: UITableView, cellForRowAt indexPath: IndexPath, index: Int) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? AppSettingCell else {
            return UITableViewCell(frame: .zero)
        }
        guard let cellType = appSettingModel.cellTypeAt(index: index) else {
            return UITableViewCell(frame: .zero)
        }
        cell.updateCellType(model: appSettingModel, type: cellType, index: index)
        if cellType == .ReportApp {
            cell.reportAppLabel.lu.addTapGestureRecognizer(action: #selector(report), target: self)
        }
        return cell
    }

    private func newGetCell(tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            return oldGetCell(tableView: tableView, cellForRowAt: indexPath, index: 0)
        } else if indexPath.row == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: AppSettingVersionCell.identifier, for: indexPath)
            if let c = cell as? AppSettingVersionCell {
                c.viewModel = versionModel
            }
            return cell
        } else {
            return oldGetCell(tableView: tableView, cellForRowAt: indexPath, index: indexPath.row - 1)
        }
    }

    func updateAppVersion(){
        Self.logger.info("app setting update versionViewModel version,scene:\(self.versionModel.scene)")
        switch self.versionModel.scene {
        case .MiniApp:
            if let service = try? self.resolver.resolve(assert: MicroAppService.self) {
                let appVersion = service.getAppVersion(appID: self.versionModel.appID)
                Self.logger.info("app setting update versionViewModel version:\(appVersion)")
                if appVersion.isEmpty {
                    // 应用版本为空，如果返回是最新版，说明本地的小程序包是最新的，只是没有缓存的版本号，属于覆盖安装场景，可以直接使用最新版本号
                    if self.versionModel.state == .newest, let version = self.appSettingModel.appDetailInfo?.version, !version.isEmpty {
                        self.versionModel.version = version
                    } else {
                        Self.logger.error("app setting update versionViewModel version is empty")
                    }
                } else {
                    self.versionModel.version = appVersion
                }
            } else {
                Self.logger.error("app setting update versionViewModel version,MicroAppService DI fail")
            }
        case .H5:
            if let version = self.appSettingModel.appDetailInfo?.version, !version.isEmpty {
                self.versionModel.version = version
            } else {
                Self.logger.error("app setting update versionViewModel h5 version is empty")
            }
        }
    }
}

extension AppSettingViewController: AppSettingViewModelDelegate {
    func viewModelChanged() {
        DispatchQueue.main.async { [weak self] in
            if let wself = self {
                wself.updateAppVersion()
            }
        }
    }
}

extension AppSettingViewController: AppSettingVersionViewModelDelegate {
    func versionViewModelChanged() {
        DispatchQueue.main.async { [weak self] in
            if let wself = self {
                Self.logger.info("app setting viewmodel version change delegate execute")
                wself.tableView.reloadData()
            }
        }
    }
    
    func versionViewModelVersionStateChanged(){
        Self.logger.info("app setting viewmodel state change delegate execute")
        DispatchQueue.main.async { [weak self] in
            if let wself = self {
                wself.updateAppVersion()
            } else {
                Self.logger.error("app setting viewmodel state change delegate execute have not self")
            }
        }
    }

    func restartApp(appID: String) {
        if let microappService = try? resolver.resolve(assert: MicroAppService.self) {
            if microappService.canRestartApp(appID: appID) {
                popSelf(animated: true, dismissPresented: false, completion: {
                    microappService.restartApp(appID: appID)
                })
            }
        } else {
            Self.logger.error("app setting viewmodel microappService is nil")
        }
    }
}
