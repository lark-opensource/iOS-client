//
//  AppDetailViewController.swift
//  LarkAppCenter
//
//  Created by yuanping on 2019/4/14.
//

import LarkUIKit
import SnapKit
import RxSwift
import Swinject
import LarkLocalizations
import LarkActionSheet
import EENavigator
import LKCommonsLogging
import LarkInteraction
import ECOProbe
import UniverseDesignColor
import UniverseDesignButton
import UniverseDesignIcon
import FigmaKit
import UniverseDesignEmpty
import LarkTraitCollection
import LarkOPInterface
import Foundation
import LarkContainer
import LarkInteraction

let appDetailLogCategory = "LarkAppCenter.AppDetail"
let AppDetailLog = Logger.log(AppDetailViewController.self, category: appDetailLogCategory)

class AppDetailViewController: BaseUIViewController, UIScrollViewDelegate,
                               UITableViewDataSource, UITableViewDelegate {

    struct Const {
        let topViewOfDefault: CGFloat = 84 // 标题单行时 描述单行
        let topViewOfMultNameH: CGFloat = 113 // 标题多行时 描述单行
        let topViewOfMultDescH: CGFloat = 95 // 标题单行时 描述多行
        let topViewOfNoDescMultNameH: CGFloat = 90 // 标题多行时 描述零行
        let topViewSpaceHeight: CGFloat = 24
        var topContainerHeight: CGFloat = 0
        let appLogoSideLen: CGFloat = 84
        var tableViewOffset: CGFloat = 30
    }

    private lazy var contentView: UIView = {
        let contentView = UIView(frame: .zero)
        contentView.backgroundColor = UIColor.ud.bgBody
        return contentView
    }()
    
    private lazy var operationHeaderView: AppDetailOperationHeaderView = {
        let view = AppDetailOperationHeaderView(frame: .zero)
        return view
    }()

    private lazy var loadingView: UIView = {
        return AppDetailLoadingView(frame: .zero)
    }()
    
    private lazy var errorView: UIView = {
        let errorView = UIView(frame: .zero)
        errorView.backgroundColor = UIColor.ud.bgBody
        return errorView
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.estimatedRowHeight = 0
        tableView.separatorStyle = .none
        return tableView
    }()

    // 顶部内容区，包含icon和标题、标签
    private lazy var topContentView: UIView = {
        let topView = UIView(frame: .zero)
        topView.clipsToBounds = true
        return topView
    }()

    // 顶部容器，最底层视图
    private lazy var topContainer: UIView = {
        let topBackground = UIView(frame: .zero)
        topBackground.clipsToBounds = true
        topBackground.backgroundColor = UIColor.ud.bgBody
        return topBackground
    }()
    
    // 图标背景视图
    private lazy var appLogoBgView: UIImageView = {
        let imageView: UIImageView = UIImageView(frame: .zero)
        imageView.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        imageView.alpha = 0.4
        imageView.clipsToBounds = true
        imageView.contentMode = UIView.ContentMode.scaleAspectFill
        return imageView
    }()
    
    private lazy var blurView: VisualBlurView = {
        let blurView = VisualBlurView()
        blurView.fillColor = UIColor.ud.bgBody
        blurView.fillOpacity = 0.4
        blurView.blurRadius = 150
        return blurView
    }()
    
    private lazy var gradientView: AppDetailGradientView = {
        let gradientView = AppDetailGradientView(frame: .zero)
        gradientView.backgroundColor = .clear
        return gradientView
    }()

    private lazy var appLogoImgView: UIImageView = {
        let resultImgView: UIImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: const.appLogoSideLen, height: const.appLogoSideLen))
        resultImgView.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        resultImgView.contentMode = UIView.ContentMode.scaleAspectFit
        resultImgView.layer.masksToBounds = true
        resultImgView.layer.ux.setSmoothCorner(radius: 20)
        resultImgView.layer.ux.setSmoothBorder(width: 1 / UIScreen.main.scale, color: UIColor.ud.N900.withAlphaComponent(0.15))
        
        let maskView = UIView(frame: resultImgView.frame)
        maskView.backgroundColor = UIColor.ud.fillImgMask
        resultImgView.addSubview(maskView)
        return resultImgView
    }()

    private lazy var titleNaviBar: TitleNaviBar = {
        let titleNaviBar = TitleNaviBar(titleString: "")
        titleNaviBar.backgroundColor = .clear
        return titleNaviBar
    }()

    private lazy var appName: UILabel = {
        let appName = UILabel(frame: .zero)
        appName.numberOfLines = 2
        appName.lineBreakMode = NSLineBreakMode.byTruncatingTail
        appName.textColor = UIColor.ud.textTitle
        appName.font = UIFont.systemFont(ofSize: 24.0, weight: .semibold)
        return appName
    }()

    private lazy var appDescription: UILabel = {
        let appDes = UILabel(frame: .zero)
        appDes.numberOfLines = 1
        appDes.textColor = UIColor.ud.textTitle
        appDes.font = UIFont.systemFont(ofSize: 14.0)
        return appDes
    }()

    private lazy var miniProgramTag: UIView = {
        return createTag(title: BundleI18n.AppDetail.AppDetail_Card_Mini_Program)
    }()

    private lazy var h5Tag: UIView = {
        return createTag(title: BundleI18n.AppDetail.AppDetail_Card_Web_App)
    }()

    private lazy var botTag: UIView = {
        return createTag(title: BundleI18n.AppDetail.AppDetail_Card_Bot)
    }()

    private lazy var onCallTag: UIView = {
        return createTag(title: BundleI18n.AppDetail.AppDetail_Card_HelpDesk)
    }()

    private lazy var deactivatedTag: UIView = {
        return createTag(title: BundleI18n.LarkOpenPlatform.OpenPlatform_AppCenter_Deactivated)
    }()

    private lazy var offlineTag: UIView = {
        return createTag(title: BundleI18n.LarkOpenPlatform.OpenPlatform_AppCenter_AppOfflineTag)
    }()

    private lazy var deleteTag: UIView = {
        return createTag(title: BundleI18n.LarkOpenPlatform.OpenPlatform_AppCenter_AppDeletedTag)
    }()

    private lazy var tagWrapper: UIStackView = {
        let wrapper = UIStackView()
        wrapper.axis = .horizontal
        wrapper.alignment = .center
        wrapper.distribution = .fill
        wrapper.spacing = 4
        wrapper.backgroundColor = .clear
        return wrapper
    }()

    private lazy var moreButton: UIButton = {
        let moreButton = UIButton(type: .custom)
        moreButton.setImage(UDIcon.moreOutlined.ud.withTintColor(UIColor.ud.iconN1), for: .normal)
        return moreButton
    }()

    private lazy var appShareButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UDIcon.shareOutlined.ud.withTintColor(UIColor.ud.iconN1), for: .normal)
        button.addTarget(self, action: #selector(appShareClick), for: .touchUpInside)
        return button
    }()
    
    private lazy var groupButtonContainer: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }()
    
    private lazy var addBotToGroupButton: UDButton = {
        var config = UDButtonUIConifg.primaryBlue
        config.type = .big
        let button = UDButton(config)
        button.setTitle(BundleI18n.GroupBot.Lark_GroupBot_AddToChat, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        button.addTarget(self, action: #selector(addBotToGroup(sender:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var removeBotFromGroupButton: UDButton = {
        var config = UDButtonUIConifg.secondaryRed
        config.type = .big
        let button = UDButton(config)
        button.setTitle(BundleI18n.GroupBot.Lark_GroupBot_Remove, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        button.addTarget(self, action: #selector(removeBotFromGroup(sender:)), for: .touchUpInside)
        return button
    }()

    private var const = Const()
    private let disposeBag = DisposeBag()
    private let iconSize: CGFloat = 20.0
    private let appDetailModel: AppDetailViewModel
    private let detailCellIdentifier = "AppDetailCellIdentifier"
    private var isTrack = false // 申请可见入口tea打点，一个页面只上报一次
    private var shareIconRightConstraint: Constraint?
    private var actionMorePopOver: ActionSheet?
    private weak var actionMorePresent: ActionSheet?
    private let resolver: UserResolver

    init(detailModel: AppDetailViewModel, resolver: UserResolver) {
        self.resolver = resolver
        self.appDetailModel = detailModel
        super.init(nibName: nil, bundle: nil)
        appDetailModel.superViewSize = {[weak self] in
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
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        isNavigationBarHidden = true
        view.backgroundColor = UIColor.ud.bgBody
        if Display.pad {
            self.preferredContentSize = CGSize(width: 420, height: 650)
            self.modalPresentationControl.dismissEnable = true
        }
        /// CR切换
        RootTraitCollection.observer
            .observeRootTraitCollectionWillChange(for: self)
            .subscribe(onNext: { [weak self] change in
                guard let self = self else { return }
                self.actionMorePopOver?.dismiss(animated: false)
                self.actionMorePopOver = nil
                self.actionMorePresent?.dismiss(animated: false)
                self.actionMorePresent = nil
            }).disposed(by: disposeBag)
        
        /// 感知评分变化
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name.storeAppReview,
            object: nil,
            queue: OperationQueue.main
        ) { [weak self] notification in
            guard let self = self else { return }
            self.appDetailModel.requestAppReviewInfo(fromLocal: true)
        }
        
        setupLoading()
        setupRetryView()
        setupContentView()
        setupNavigateBar()
        setupViewModel()
        fetchAppDetailInfo()

        if appDetailModel.showShare() {
            OPMonitor("openplatform_bot_profile_view")
                .addCategoryValue("application_id", appDetailModel.appDetailInfo?.appId ?? "")
                .addCategoryValue("scene_type", "none")
                .addCategoryValue("solution_id", "none")
                .setPlatform(.tea)
                .flush()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        appLogoImgView.layer.ux.removeSmoothBorder()
        appLogoImgView.layer.ux.setSmoothBorder(width: 1 / UIScreen.main.scale, color: UIColor.ud.N900.withAlphaComponent(0.15))
    }
    
    private func setupLoading() {
        loadingPlaceholderView.isHidden = true
        view.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(UIApplication.shared.statusBarFrame.size.height + titleNaviBar.naviBarHeight + const.topViewSpaceHeight)
        }
    }

    private func setupRetryView() {
        view.addSubview(errorView)
        errorView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        errorView.lu.addTapGestureRecognizer(action: #selector(retry), target: self)
        
        let container = UIView(frame: .zero)
        container.backgroundColor = .clear
        errorView.addSubview(container)
        container.snp.makeConstraints { make in
            make.leading.trailing.centerY.equalToSuperview()
        }

        let errorImg = UIImageView(frame: .zero)
        errorImg.image = UDEmptyType.loadingFailure.defaultImage()
        errorImg.clipsToBounds = true
        errorImg.contentMode = UIView.ContentMode.scaleAspectFit
        container.addSubview(errorImg)
        errorImg.snp.makeConstraints { (make) in
            make.width.height.equalTo(100)
            make.centerX.top.equalToSuperview()
        }

        let errorLabel = UILabel(frame: .zero)
        errorLabel.text = BundleI18n.AppDetail.AppDetail_Card_Load_Fail
        errorLabel.textColor = UIColor.ud.textCaption
        errorLabel.textAlignment = .center
        errorLabel.font = UIFont.systemFont(ofSize: 14.0)
        errorLabel.numberOfLines = 0
        container.addSubview(errorLabel)
        errorLabel.snp.makeConstraints { (make) in
            make.top.equalTo(errorImg.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(40)
            make.trailing.equalToSuperview().offset(-40)
            make.bottom.equalToSuperview()
        }
        errorView.isHidden = true
    }

    private func setupContentView() {
        view.addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        // 默认按单行标题计算
        const.topContainerHeight = self.calculateTopContainerHeight(const.topViewOfDefault)

        contentView.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.register(AppDetailCell.self, forCellReuseIdentifier: detailCellIdentifier)
        tableView.register(AppDetailApplyOrNoPermissionHeaderView.self, forHeaderFooterViewReuseIdentifier: AppDetailApplyOrNoPermissionHeaderView.headerReuseID)
        tableView.contentInset = UIEdgeInsets(top: const.topContainerHeight, left: 0, bottom: 0, right: 0)
        tableView.tableHeaderView = operationHeaderView

        contentView.addSubview(topContainer)
        topContainer.snp.makeConstraints { (make) in
            make.leading.trailing.top.equalToSuperview()
            make.height.equalTo(const.topContainerHeight)
        }
        
        topContainer.addSubview(appLogoBgView)
        appLogoBgView.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            make.bottom.equalToSuperview().offset(-const.topViewSpaceHeight)
        }
        
        appLogoBgView.addSubview(blurView)
        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        appLogoBgView.addSubview(gradientView)
        gradientView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        topContainer.addSubview(topContentView)
        topContentView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(const.topViewOfDefault)
            make.bottom.equalToSuperview().offset(-const.topViewSpaceHeight)
        }

        topContentView.addSubview(appLogoImgView)
        appLogoImgView.snp.makeConstraints { (make) in
            make.width.height.equalTo(const.appLogoSideLen)
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview()
        }

        topContentView.addSubview(appName)
        appName.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.trailing.equalToSuperview().offset(-16)
            make.leading.equalTo(appLogoImgView.snp.trailing).offset(12)
        }

        topContentView.addSubview(appDescription)
        appDescription.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(appName)
            make.top.equalTo(appName.snp.bottom).offset(5)
        }

        topContentView.addSubview(tagWrapper)
        tagWrapper.snp.makeConstraints { (make) in
            make.leading.equalTo(appName)
            make.top.equalTo(appDescription.snp.bottom).offset(8)
        }
        
        contentView.addSubview(groupButtonContainer)
        groupButtonContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(Display.pad ? -8 : 0)
            make.height.equalTo(64)
        }
        
        groupButtonContainer.addSubview(addBotToGroupButton)
        addBotToGroupButton.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16))
        }
        
        groupButtonContainer.addSubview(removeBotFromGroupButton)
        removeBotFromGroupButton.snp.makeConstraints { make in
            make.edges.equalTo(addBotToGroupButton)
        }

        contentView.isHidden = true
    }
    
    private func setupNavigateBar() {
        view.addSubview(titleNaviBar)
        titleNaviBar.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(Display.pad ? 8 : 0)
        }

        let iconPointerInfo = PointerInfo(effect: .highlight) { (_) -> PointerInfo.ShapeSizeInfo in
            return (CGSize(width: AppDetailLayout.highLightIconCommonHeight, height: AppDetailLayout.highLightIconCommonWidth), AppDetailLayout.highLightCorner)
        }
        let naviButton = getNaviBtn()
        titleNaviBar.contentview.addSubview(naviButton)
        naviButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
            make.height.width.equalTo(iconSize)
        }
        naviButton.addPointer(iconPointerInfo)
        titleNaviBar.contentview.addSubview(moreButton)
        moreButton.rx.tap.asDriver().drive(onNext: { [weak self] in
            guard let `self` = self else { return }
            self.moreBtnClick()
        }).disposed(by: disposeBag)
        moreButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-16)
            make.height.width.equalTo(iconSize)
        }
        titleNaviBar.contentview.addSubview(appShareButton)
        appShareButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            shareIconRightConstraint = make.right.equalTo(moreButton.snp.left).offset(-20).constraint
            make.height.width.equalTo(iconSize)
        }
        appShareButton.addPointer(iconPointerInfo)
        appShareButton.isHidden = true

        moreButton.addPointer(iconPointerInfo)
        moreButton.isHidden = true
    }

    private func getNaviBtn() -> UIButton {
        let naviButton = UIButton(type: .custom)
        if self.presentingViewController != nil {
            naviButton.setImage(UDIcon.closeOutlined.ud.withTintColor(UIColor.ud.iconN1), for: .normal)
            naviButton.rx.tap.asDriver().drive(onNext: { [weak self] in
                guard let `self` = self else { return }
                self.dismiss(animated: true, completion: nil)
            }).disposed(by: disposeBag)
        } else {
            naviButton.setImage(UDIcon.leftOutlined.ud.withTintColor(UIColor.ud.iconN1), for: .normal)
            naviButton.rx.tap.asDriver().drive(onNext: { [weak self] in
                guard let `self` = self else { return }
                self.navigationController?.popViewController(animated: true)
            }).disposed(by: disposeBag)
        }
        return naviButton
    }

    private func setupViewModel() {
        appDetailModel.appDetialInfoUpdate
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] (fetchError) in
                guard let `self` = self else { return }
                if fetchError, self.appDetailModel.appDetailInfo != nil { return }
                self.updateContentView(fetchError: fetchError)
            }).disposed(by: disposeBag)
    }

    private func createTag(title: String) -> UIView {
        let tag = UILabel(frame: .zero)
        tag.textColor = UIColor.ud.udtokenTagNeutralTextNormal
        tag.text = title
        tag.backgroundColor = .clear
        tag.font = UIFont.systemFont(ofSize: 12.0, weight: .medium)
        let wrapper = UIView(frame: .zero)
        wrapper.backgroundColor = UIColor.ud.udtokenTagNeutralBgNormal
        wrapper.layer.cornerRadius = 4
        wrapper.layer.ud.setBorderColor(UIColor.clear)
        wrapper.addSubview(tag)
        tag.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4))
        }
        return wrapper
    }

    private func updateContentView(fetchError: Bool = false) {
        if !fetchError, let appDetailInfo = appDetailModel.appDetailInfo {
            // reset
            tagWrapper.subviews.forEach {
                $0.removeFromSuperview()
            }
            appDescription.numberOfLines = 1
            appName.numberOfLines = 2
            moreButton.isHidden = !appDetailModel.showReport()
            appShareButton.isHidden = !appDetailModel.showShare()
            if !appShareButton.isHidden, moreButton.isHidden {
                shareIconRightConstraint?.update(offset: iconSize)
            } else {
                shareIconRightConstraint?.update(offset: -20)
            }

            // 1. 标题单行，无描述信息
            if appDetailModel.isSingleAppName, appDetailInfo.getLocalDescription().isEmpty {
                appName.numberOfLines = 1
                self.updateTopViewHeight(const.topViewOfDefault)
                appName.snp.updateConstraints { make in
                    make.top.equalToSuperview().offset(13)
                }
                tagWrapper.snp.updateConstraints { make in
                    make.top.equalTo(appDescription.snp.bottom).offset(3)
                }
            }
            // 2. 标题单行，有描述信息且一行
            if appDetailModel.isSingleAppName, !appDetailInfo.getLocalDescription().isEmpty, appDetailModel.isSingleDesc {
                appName.numberOfLines = 1
                self.updateTopViewHeight(const.topViewOfDefault)
                appName.snp.updateConstraints { make in
                    make.top.equalToSuperview().offset(2)
                }
                tagWrapper.snp.updateConstraints { make in
                    make.top.equalTo(appDescription.snp.bottom).offset(10)
                }
            }
            // 3. 标题单行，有描述信息且多行
            if appDetailModel.isSingleAppName, !appDetailInfo.getLocalDescription().isEmpty, !appDetailModel.isSingleDesc {
                appName.numberOfLines = 1
                appDescription.numberOfLines = 2
                self.updateTopViewHeight(const.topViewOfMultDescH)
                appName.snp.updateConstraints { make in
                    make.top.equalToSuperview().offset(0)
                }
                tagWrapper.snp.updateConstraints { make in
                    make.top.equalTo(appDescription.snp.bottom).offset(8)
                }
            }
            // 4. 标题多行，无描述信息
            if !appDetailModel.isSingleAppName, appDetailInfo.getLocalDescription().isEmpty {
                self.updateTopViewHeight(const.topViewOfNoDescMultNameH)
                appName.snp.updateConstraints { make in
                    make.top.equalToSuperview().offset(0)
                }
                tagWrapper.snp.updateConstraints { make in
                    make.top.equalTo(appDescription.snp.bottom).offset(3)
                }
            }
            // 5. 标题多行，有描述信息
            if !appDetailModel.isSingleAppName, !appDetailInfo.getLocalDescription().isEmpty {
                self.updateTopViewHeight(const.topViewOfMultNameH)
                appName.snp.updateConstraints { make in
                    make.top.equalToSuperview().offset(0)
                }
                tagWrapper.snp.updateConstraints { make in
                    make.top.equalTo(appDescription.snp.bottom).offset(8)
                }
            }

            tableView.contentInset = UIEdgeInsets(top: const.topContainerHeight, left: 0, bottom: 0, right: 0)
            tableView.contentOffset = CGPoint(x: 0, y: -const.topContainerHeight)

            let paraStyle = NSMutableParagraphStyle()
            paraStyle.maximumLineHeight = 36
            paraStyle.lineBreakMode = NSLineBreakMode.byTruncatingTail
            let attributedString = NSAttributedString(string: appDetailInfo.getLocalTitle(), attributes: [.paragraphStyle: paraStyle])
            appName.attributedText = attributedString

            appDescription.text = appDetailInfo.getLocalDescription()
            appLogoImgView.bt.setLarkImage(with: .avatar(
                key: appDetailInfo.avatar,
                entityID: appDetailInfo.appId ?? "",
                params: .init(sizeType: .size(max(const.appLogoSideLen, const.appLogoSideLen)))
            ))
            appLogoBgView.bt.setLarkImage(with: .avatar(
                key: appDetailInfo.avatar,
                entityID: "",
                params: .init(sizeType: .size(max(const.appLogoSideLen, const.appLogoSideLen)))
            ))

            /// 当应用对用户不可见时，展示提示文案
            if shouldShowApply, !isTrack {
                isTrack = true
                AppDetailUtils(resolver: resolver).internalDependency?
                    .post(eventName: "app_states_unavaliable_show", params: [:])
            }

            // 下线
            if let appStatus = appDetailInfo.curAppStatus(), appStatus == .offline {
                tagWrapper.addArrangedSubview(offlineTag)
            } else if let appStatus = appDetailInfo.curAppStatus(), appStatus == .appDeleted {
                tagWrapper.addArrangedSubview(deleteTag)
            } else if let appStatus = appDetailInfo.curAppStatus(),
                (appStatus == .tenantForbidden
                    || appStatus == .developerForbidden
                    || appStatus == .platformForbidden
                    || appStatus == .unknownState) {
                tagWrapper.addArrangedSubview(deactivatedTag)
            } else {
                if appDetailInfo.isOnCall ?? false {
                    tagWrapper.addArrangedSubview(onCallTag)
                } else {
                    if appDetailModel.hasAppType(appType: .gadget) {
                        tagWrapper.addArrangedSubview(miniProgramTag)
                    }
                    if appDetailModel.hasAppType(appType: .h5) {
                        tagWrapper.addArrangedSubview(h5Tag)
                    }
                    if appDetailModel.hasAppType(appType: .bot) {
                        tagWrapper.addArrangedSubview(botTag)
                    }
                }
            }
            updateOperationHeader()
            tableView.tableHeaderView = operationHeaderView
            configBottomButton()
            tableView.reloadData()
        }
        loadingView.isHidden = true
        errorView.isHidden = !fetchError
        contentView.isHidden = fetchError
    }
    
    private func calculateTopContainerHeight(_ topContentViewHeight: CGFloat) -> CGFloat {
        UIApplication.shared.statusBarFrame.size.height // 状态栏高度
            + titleNaviBar.naviBarHeight    // 导航栏高度
            + const.topViewSpaceHeight      // 导航栏和icon之间的间距
            + topContentViewHeight          // icon区域高度
            + const.topViewSpaceHeight      // icon区域和按钮区域的间距
    }
    
    private func updateTopViewHeight(_ topContentViewHeight: CGFloat) {
        const.topContainerHeight = self.calculateTopContainerHeight(topContentViewHeight)
        topContentView.snp.updateConstraints { make in
            make.height.equalTo(topContentViewHeight)
        }
        topContainer.snp.updateConstraints { make in
            make.height.equalTo(const.topContainerHeight)
        }
    }
    
    private func configBottomButton() {
        var visible = false
        if let appDetailInfo = appDetailModel.appDetailInfo {
            visible = (appDetailInfo.curAppStatus() == .usable)
        }
        addBotToGroupButton.isHidden = !(visible && appDetailModel.showAddBotToGroup())
        removeBotFromGroupButton.isHidden = !(appDetailModel.showRemoveBotFromGroup())
        if addBotToGroupButton.isHidden && removeBotFromGroupButton.isHidden {
            groupButtonContainer.isHidden = true
            tableView.contentInset = UIEdgeInsets(top: const.topContainerHeight, left: 0, bottom: 0, right: 0)
        } else {
            groupButtonContainer.isHidden = false
            tableView.contentInset = UIEdgeInsets(top: const.topContainerHeight, left: 0, bottom: Display.pad ? 72 : 64, right: 0)
        }
    }

    private func fetchAppDetailInfo() {
        errorView.isHidden = true
        loadingView.isHidden = false
        contentView.isHidden = true
        appDetailModel.fetchAppInfo()
    }

    @objc
    private func retry() {
        fetchAppDetailInfo()
    }

    @objc
    private func applyForUse() {
        appDetailModel.openApplyForUse()
    }

    /// 是否应该展示可见性等提示信息
    var shouldShowApply: Bool {
        guard let appDetailInfo = appDetailModel.appDetailInfo else {
            return false
        }
        let invisible = (appDetailInfo.curAppStatus() == .userInvisible)
        return invisible
    }

    /// 是否应该展示申请权限等提示信息
    var shouldShowNoPermission: Bool {
        guard let extraInfo = appDetailModel.appDetailInfo?.extraInfo else {
            return false
        }
        let noPermission = (extraInfo.noPermission == true)
        return noPermission
    }

    /// 是否应该展示申请权限等提示信息
    var shouldShowApplyOrNoPermissionFooter: Bool {
        guard appDetailModel.cellCount() > 0, shouldShowApply || shouldShowNoPermission else {
            return false
        }
        return true
    }
    
    var shouldShowOperationHeader: Bool {
        return appDetailModel.showSendMessage() || appDetailModel.showOpenApp()
    }
    
    private func updateOperationHeader() {
        if shouldShowOperationHeader {
            operationHeaderView.frame = CGRect(x: 0, y: 0, width: tableView.contentSize.width, height: 48 + 16 + 8)
        } else {
            operationHeaderView.frame = CGRect(x: 0, y: 0, width: tableView.contentSize.width, height: 8)
        }

        let chatType = appDetailModel.appDetailInfo?.curChatType() ?? .InterActiveBot
        var operateType: profileOperateType = .unKnown
        var buttons: [OperationButtonType] = []
        if appDetailModel.showSendMessage() {
            buttons.append(.sendMessage)
        }
        if appDetailModel.showOpenApp() {
            buttons.append(.openApp)
        }
        operationHeaderView.updateViews(buttons: buttons, chatType: chatType) { [weak self] type in
            guard let self = self else { return }
            switch type {
            case .sendMessage:
                self.appDetailModel.openMessageBot(from: self)   // 打开bot单聊
                operateType = .openChat
            case .openApp:
                self.appDetailModel.openLarkApp()
                operateType = .openapp
            case .feedback:
                weak var from = self
                self.appDetailModel.openFeedback(from: from)
                operateType = .feedback
            }
            
            if operateType != .unKnown, let appSceneType = self.appDetailModel.appDetailInfo?.getAppType() {
                let params = [
                    "function_name": operateType.rawValue,
                    "application_type": appSceneType.rawValue
                ] as [String: Any]
                AppDetailUtils(resolver: self.resolver).internalDependency?.post(eventName: "op_profile_click", params: params)
            }
        }
    }

    private func moreBtnClick() {
        if Display.pad, self.isWPWindowRegularSize() {
            let popOverItemHeight: CGFloat = 48
            let popOverWidth: CGFloat = 375
            let actionSheet = ActionSheet(bottomOffset: 0)
            let arrowOffset: CGFloat = 13.0
            // 上报选项配置
            let reportItem = UILabel(frame: CGRect(x: 0, y: arrowOffset, width: popOverWidth, height: popOverItemHeight))
            reportItem.font = UIFont.systemFont(ofSize: 16.0)
            reportItem.textColor = UIColor.ud.textTitle
            reportItem.text = BundleI18n.LarkOpenPlatform.OpenPlatform_AppCenter_AppReport
            reportItem.textAlignment = .center
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(popOverReportClick))
            reportItem.addGestureRecognizer(tapGestureRecognizer)
            reportItem.isUserInteractionEnabled = true
            if #available(iOS 13.4, *) {
                let action = PointerInteraction(style: PointerStyle(effect: .hover(), shape: .default))
                reportItem.addLKInteraction(action)
            }
            // popOver配置
            actionSheet.view.addSubview(reportItem)
            actionSheet.preferredContentSize = CGSize(width: popOverWidth, height: popOverItemHeight)
            let sourceRect = moreButton.convert(moreButton.bounds, to: view)
            actionSheet.modalPresentationStyle = .popover
            actionSheet.popoverPresentationController?.backgroundColor = UIColor.ud.bgBody
            actionSheet.popoverPresentationController?.sourceView = view
            actionSheet.popoverPresentationController?.sourceRect = sourceRect.insetBy(dx: -8, dy: 0)
            actionSheet.popoverPresentationController?.permittedArrowDirections = .up
            actionMorePopOver = actionSheet     // 保存引用
            resolver.navigator.present(actionSheet, from: self)
        } else {
            let actionSheet = ActionSheet()
            actionSheet.addItem(title: BundleI18n.LarkOpenPlatform.OpenPlatform_AppCenter_AppReport) {[weak self] in
                self?.appDetailModel.openReport()
            }
            actionSheet.addItem(title: BundleI18n.LarkOpenPlatform.OpenPlatform_AppCenter_Cancel) {[weak actionSheet] in
                actionSheet?.dismiss(animated: true)
            }
            actionMorePresent = actionSheet
            resolver.navigator.present(actionSheet, from: self)
        }
    }
    
    @objc
    private func addBotToGroup(sender: UDButton) {
        sender.showLoading()
        appDetailModel.addBotToGroupAndGotoChat(fromVC: self) { [weak sender] in
            sender?.hideLoading()
        }
    }
    
    @objc
    private func removeBotFromGroup(sender: UDButton) {
        appDetailModel.removeBotFromGroupAndGotoChat(fromVC: self, start: {[weak sender] in
            sender?.showLoading()
        }) {[weak sender] in
            sender?.hideLoading()
        }
    }

    @objc
    private func appShareClick() {
        OPMonitor("openplatform_bot_profile_click")
            .addCategoryValue("application_id", appDetailModel.appDetailInfo?.appId ?? "")
            .addCategoryValue("scene_type", "none")
            .addCategoryValue("solution_id", "none")
            .addCategoryValue("click", "app_share")
            .addCategoryValue("target", "openplatform_application_share_view")
            .setPlatform([.tea, .slardar])
            .flush()
        appDetailModel.openAppShare(from: self)
    }

    @objc
    private func popOverReportClick() {
        actionMorePopOver?.dismiss(animated: true, completion: { [weak self] in
            self?.appDetailModel.openReport()
        })
        actionMorePopOver = nil
    }
    private func handleTapEvent(type: AppDetailCellType) {
        var operateType: profileOperateType = .unKnown
        if type == .AppReview {
            appDetailModel.openAppReview(from: self)
        } else if type == .FeedBack {  // 反馈
            appDetailModel.openFeedback(from: self)
            operateType = .feedback
        } else if type == .Developer {
            appDetailModel.openDeveloperChat(from: self)
        } else if type == .HistoryMessage {
            appDetailModel.openMessageBot(from: self)   // 打开bot单聊
            operateType = .openChat
        } else if type == .HelpDoc {
            appDetailModel.openHelpDoc()
            operateType = .help
        } else if type == .InvitedBy {
            appDetailModel.openInviterChat(from: self)
        } else if type == .ScopeInfo {
            openScopeInfoVC()
        }
        if operateType != .unKnown, let appSceneType = appDetailModel.appDetailInfo?.getAppType() {
            let params = [
                "function_name": operateType.rawValue,
                "application_type": appSceneType.rawValue
            ] as [String: Any]
            AppDetailUtils(resolver: resolver).internalDependency?.post(eventName: "op_profile_click", params: params)
        }
    }
    
    private func openScopeInfoVC() {
        let scopeInfoVC = BotScopeInfoViewController(scopeInfoList: appDetailModel.appDetailInfo?.scopeInfo ?? [])
        resolver.navigator.push(scopeInfoVC, from: self, animated: true, completion: nil)
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        guard let type = appDetailModel.curCellType(index: indexPath.row) else { return }
        tableView.deselectRow(at: indexPath, animated: false)
        handleTapEvent(type: type)
    }
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return appDetailModel.cellCount()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return appDetailModel.curCellHeight(index: indexPath.row)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: detailCellIdentifier, for: indexPath) as? AppDetailCell else {
            return UITableViewCell(frame: .zero)
        }
        guard let type = appDetailModel.curCellType(index: indexPath.row) else {
            return UITableViewCell(frame: .zero)
        }
        cell.updateCellType(model: appDetailModel, type: type, resolver: resolver)
        return cell
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        /// 当应用对用户不可见时，展示提示文案
        if !shouldShowApplyOrNoPermissionFooter {
            return nil
        }

        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: AppDetailApplyOrNoPermissionHeaderView.headerReuseID) as? AppDetailApplyOrNoPermissionHeaderView else {
            AppDetailLog.error("no register for AppDetailApplyOrNoPermissionHeaderView")
            return nil
        }
        let canApplyAccessWhenInVisible = appDetailModel.appDetailInfo?.canApplyAccessWhenInVisible()
        headerView.updateViews(
            containerWidth: tableView.frame.width,
            showInvisibleTip: shouldShowApply,
            canApplyAccessWhenInVisible: canApplyAccessWhenInVisible,
            noPermission: shouldShowNoPermission
            ) { [weak self] in
            self?.applyForUse()
        }
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        /// 当应用对用户不可见时，展示提示文案
        if shouldShowApplyOrNoPermissionFooter {
            return UITableView.automaticDimension
        }
        return CGFloat.leastNormalMagnitude
    }
    // MARK: - UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        if offsetY <= -const.topContainerHeight, offsetY > -appDetailModel.superViewSize().height {
            topContainer.snp.updateConstraints { make in
                make.height.equalTo(abs(offsetY))
            }
        }
        if offsetY > -const.topContainerHeight {
            topContainer.snp.updateConstraints { make in
                make.height.equalTo(const.topContainerHeight)
            }
        }
    }
}

enum profileOperateType: String {
    /// 反馈
    case feedback
    /// 帮助文档
    case help
    /// 打开bot单聊
    case openChat
    /// 打开应用
    case openapp
    /// 分享
    case share
    /// 未知
    case unKnown
}
