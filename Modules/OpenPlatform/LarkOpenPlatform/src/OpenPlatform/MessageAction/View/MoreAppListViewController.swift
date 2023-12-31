//
//  MoreAppListViewController.swift
//  LarkOpenPlatform
//
//  Created by houjihu on 2021/5/7.
//

import LKCommonsLogging
import LarkUIKit
import EENavigator
import Foundation
import Swinject
import RxSwift
import LarkAccountInterface
import LarkAlertController
import LarkOPInterface
import LarkMessengerInterface
import LarkAppLinkSDK
import RustPB
import LarkRustClient
import LarkModel
import EEMicroAppSDK
import UniverseDesignDialog
import RoundedHUD
import LarkContainer

/// Message Action和加号菜单更多应用列表页
class MoreAppListViewController: BaseUIViewController, UICollectionViewDelegateFlowLayout,
                                 UICollectionViewDataSource, UICollectionViewDelegate,
                                 UICollectionViewDragDelegate, UICollectionViewDropDelegate,
                                 UITextViewDelegate {
    let resolver: UserResolver
    let disposeBag = DisposeBag()
    /// 业务场景
    var bizScene: BizScene
    var chatId: String
    /// 小程序打开的场景值
    var fromScene: FromScene
    /// 数据model
    var viewModel: MoreAppListViewModel?
    /// 跟随用户操作的常用应用列表
    /// 点击+/-按钮时，先保存操作后的常用列表到此属性，然后请求更新配置，通过block来持有原有列表，在失败时将当前显示时用的数据列表覆盖此属性，而不需要更新界面。鉴于可能短时间点击多次+/-，在请求成功后判断block持有的列表与此属性是否完全相等，在相等时用此属性更新界面
    /// 拖动常用列表项时，先保存操作后的常用列表到此属性，然后请求更新配置，通过block来持有原有项移动前后的索引，在失败时回退
    var userActionBasedExternalItemList: [MoreAppItemModel]?
    /// Message Action或加号菜单 的上下文
    var actionContext: CommonActionContextItem?
    var firstInit: Bool = true
    /// 数据提供
    var dataProvider: MoreAppListDataProvider
    /// 配置跳转的Url
    var instructionUrl: GuideIndexInstructionUrl?
    /// 如果某个应用安装成功，提示用户使用的时候，使用该应用的逻辑
    var openInstalledApp: ((MoreAppItemModel, _ sourceViewController: UIViewController) -> Bool)
    /// 如果+号列表存在刷新，则周知外部
    var chatActionListUpdateCallback: (() -> Void)
    /// 正常展示数据的collectionView
    lazy var collectionView: UICollectionView = {
        /// collectionView的layout配置
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = CGFloat.leastNonzeroMagnitude
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.ud.bgBody
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(MoreAppCollectionViewCell.self, forCellWithReuseIdentifier: MoreAppCollectionViewCell.cellIdentifier)
        collectionView.register(
            MoreAppExternalItemListHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: MoreAppExternalItemListHeaderView.identifier
        )
        collectionView.register(
            MoreAppAvailableItemListHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: MoreAppAvailableItemListHeaderView.identifier
        )
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.dataSource = self
        collectionView.delegate = self
        // 支持拖拽排序
        // 规避苹果实现beginInteractiveMovementForItem时的bug，在cell高度随内容变化时，在拖动时的cell高度会使用estimatedItemSize，导致拖动时cell高度异常。参考自：https://stackoverflow.com/questions/52001918/ui-issues-while-reordering-uicollectionview-with-full-width-and-dynamic-height-c
        collectionView.dragInteractionEnabled = true
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        return collectionView
    }()
    /// 加载态视图
    let loadingCellNum: Int = 3
    lazy var loadingView: LoadingView = LoadingView(frame: .zero, cellNum: loadingCellNum)
    /// 加载失败的视图
    lazy var loadFailedView: LoadFailView = LoadFailView(frame: .zero, reload: { [weak self] in
        self?.reloadPage()
    })
    /// 加载为空的视图
    lazy var loadEmptyView = GuideIndexPageEmptyView(frame: view.bounds, bizScene: bizScene, delegate: self)
    ///查询对应信息
    var getMessageObservable: Observable<[String: Message]>?

    init(
        resolver: UserResolver,
        bizScene: BizScene,
        fromScene: FromScene,
        chatId: String,
        actionContext: CommonActionContextItem,
        chatActionListUpdateCallback: @escaping (() -> Void),
        openAvailableApp: @escaping ((MoreAppItemModel, UIViewController) -> Bool)
    ) {
        self.resolver = resolver
        self.bizScene = bizScene
        self.fromScene = fromScene
        self.chatId = chatId
        self.actionContext = actionContext
        self.openInstalledApp = openAvailableApp
        self.chatActionListUpdateCallback = chatActionListUpdateCallback
        self.dataProvider = MoreAppListDataProvider(
            resolver: resolver,
            locale: OpenPlatformAPI.curLanguage(),
            scene: bizScene
        )
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        dataProduce()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !firstInit {
            dataProduce()
        } else {
            // show onboarding
            showOnboardingModalVCIfNeed()
        }
        firstInit = false
        MoreAppTeaReport.imChatMoreAppView(bizScene: bizScene)
    }
    /// 适配iPad分/转屏
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil, completion: { [weak self](_) in
            self?.collectionView.collectionViewLayout.invalidateLayout()
        })
    }

    /// 设置视图
    private func setupViews() {
        setNaviBarInfo()
        view.backgroundColor = UIColor.ud.bgBody
        view.addSubview(loadingView)
        view.addSubview(loadFailedView)
        view.addSubview(loadEmptyView)
        view.addSubview(collectionView)
        setViewConstraint()
        loadingView.isHidden = true
        loadFailedView.isHidden = true
        loadEmptyView.isHidden = true
        collectionView.isHidden = true
    }
    /// 设置视图约束关系
    private func setViewConstraint() {
        loadingView.snp.makeConstraints { (make) in
            make.width.equalToSuperview()
            make.top.centerX.equalToSuperview()
        }
        loadFailedView.snp.makeConstraints { (make) in
            make.left.greaterThanOrEqualToSuperview().offset(4)
            make.right.lessThanOrEqualToSuperview().offset(-4)
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-40)
        }
        loadEmptyView.snp.makeConstraints { (make) in
            //https://www.figma.com/file/FY8KFZj9GqC2c5D42oBcVK/20201202-msg-action-及加号菜单无推荐应用时入口可见并展示引导内容?node-id=21%3A857 适配设计稿
            make.edges.equalToSuperview()
        }
        collectionView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        let safeAreaBottomInsets = UIApplication.shared.delegate?.window??.safeAreaInsets.bottom ?? 0
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: safeAreaBottomInsets, right: 0)
    }
    /// 设置导航栏页面配置信息
    private func setNaviBarInfo() {
        addBackItem()
        if bizScene == .addMenu {
            //文案按照产品要求改为“更多” https://bytedance.feishu.cn/docs/doccnVNthkJKElFhcY9CGPtvDBe#
            title = BundleI18n.MessageAction.Lark_OpenPlatform_InputScMoreBttn
        } else if bizScene == .msgAction {
            title = BundleI18n.MessageAction.Lark_OpenPlatform_MsgScBttn
        }
    }

    /// 页面重新加载事件
    func reloadPage() {
        GuideIndexPageVCLogger.info("start to reload page")
        dataProduce()
    }
//}
//
// MARK: 数据相关
//extension MoreAppListViewController {
    /// 获取数据
    /// 服务于两个场景：
    /// 1. 进入当前页面时，刷新页面数据
    /// 2. 返回当前页面时，刷新页面数据，比如进入应用目录申请应用成功需要刷新和重新排序当前数据，将刚申请的应用排在首部
    private func dataProduce() {
        if viewModel == nil {
            onRequestStart()
        }
        dataProvider.updateRemoteAllItemList {  [weak self] (error, model) in
            guard let self = self else {
                GuideIndexPageVCLogger.warn("request guideIndex list self released")
                return
            }
            guard error == nil else {
                GuideIndexPageVCLogger.error("request guideIndex list failed with backEnd-Error: \(error?.localizedDescription ?? "")")
                DispatchQueue.main.async {
                    self.onRequestFailed()
                }
                return
            }
            guard let validModel = model else {
                GuideIndexPageVCLogger.error("request guideIndex list model exception not valid")
                DispatchQueue.main.async {
                    self.onRequestFailed()
                }
                return
            }
            self.viewModel = MoreAppListViewModel(bizScene: self.bizScene, fromScene: self.fromScene, data: validModel)
            DispatchQueue.main.async {
                self.onRequestSuccess()
                self.chatActionListUpdateCallback()
            }
        }
        fetchInstruction()
    }

    private func onRequestStart() {
        loadingView.isHidden = false
        loadFailedView.isHidden = true
        loadEmptyView.isHidden = true
        collectionView.isHidden = true
    }

    private func onRequestSuccess() {
        loadingView.isHidden = true
        loadFailedView.isHidden = true
        loadEmptyView.updateViews(linkTipsHidden: !jumpUrlValid())
        if isDataEmpty() {
            loadEmptyView.isHidden = false
            collectionView.isHidden = true
        } else {
            loadEmptyView.isHidden = true
            collectionView.isHidden = false
            collectionView.reloadData()
        }
    }

    private func onRequestFailed() {
        loadingView.isHidden = true
        loadFailedView.isHidden = false
        loadEmptyView.isHidden = true
        collectionView.isHidden = true
    }

    /// 判断业务数据是否为空
    func isDataEmpty() -> Bool {
        guard let model = self.viewModel else {
            GuideIndexPageVCLogger.error("view model is empty")
            return true
        }
        return model.isDataEmpty()
    }

    /// 同步本地外露常用应用列表到后端
    /// 出错后会toast报错
    func updateRemoteExternalItemListData(externalItemList: [MoreAppItemModel], completion: ((_ isSuccess: Bool) -> Void)? = nil) {
        let sortedAppIDs = externalItemList.map { $0.appId ?? "" }
        dataProvider.updateLocalExternalItemListToRemote(
            bizScene: bizScene,
            appIDs: sortedAppIDs
        ) { (isSuccess, _) in
            completion?(isSuccess)
            // 操作失败提示
            if !isSuccess {
                let tip = BundleI18n.MessageAction.Lark_OpenPlatform_ScFailLoadMsg
                if let window = self.view.window {
                    RoundedHUD.showFailure(with: tip, on: window)
                }
                return
            }
        }
    }

    /// 重新排序数据并刷新界面
    func reorderDataAndRefreshUI(newExternalItemList: [MoreAppItemModel], shouldUpdateAvailableIteList: Bool = false, newAvailableItemList: [MoreAppItemModel] = [], shouldReloadData: Bool = true) {
        guard let model = viewModel else {
            GuideIndexPageVCLogger.error("GuideIndexPageView viewModel is empty, move row failed")
            return
        }
        model.data.externalItemListModel.externalItemList = newExternalItemList
        userActionBasedExternalItemList = newExternalItemList
        if shouldUpdateAvailableIteList {
            model.data.availableItemListModel.availableItemList = newAvailableItemList
        }
        model.reorderData()
        if (shouldReloadData) {
            collectionView.reloadData()
            // 避免拖动后有异常cell缩小动画
            collectionView.layoutIfNeeded()
        }
    }

    /// 跳转「Message Action」
    func openAppMessageAction(viewModel: MoreAppListCellViewModel) {
        guard let applinkUrl = viewModel.data.mobileApplinkUrl else {
            GuideIndexPageVCLogger.error("guideIndex page open message action failed because mobileApplinkUrl is empty")
            return
        }
        guard let op = try? resolver.resolve(assert: OpenPlatformService.self) else {
            GuideIndexPageVCLogger.error("guideIndex page open message action failed because get OpenPlatformService failed")
            return
        }
        GuideIndexPageVCLogger.info("guideIndex page open message action \(viewModel.data.appId ?? "") \(applinkUrl)")
        op.getTriggerCode { [weak self] (triggerCode) in
            guard let self = self else {
                GuideIndexPageVCLogger.warn("guideIndex page open message action self release")
                return
            }
            var addAbilityUrl = applinkUrl
            if let ability = viewModel.data.requiredLaunchAbility {
                addAbilityUrl = addAbilityUrl.urlStringAddParameter(parameters: [launchAbilityKey: ability])
            }
            if let targetUrl = op.urlAppendTriggerCode(addAbilityUrl, triggerCode, appendOnlyForMiniProgram: false),
               let target = targetUrl.possibleURL() {
                GuideIndexPageVCLogger.info("guideIndex page open message action page: \(target)")
                /// 记录本次Action的上下文
                if self.actionContext is MessageActionContextItem, let context = self.actionContext as? MessageActionContextItem {
                    let newContext = MessageActionContextItem(chatId: context.chatId,
                                                              messageIds: context.messageIds,
                                                              user: context.owner,
                                                              ttCode: triggerCode)
                    MessageCardSession.shared().recordOpenMessageAction(context: newContext)
                    /// 业务埋点上报
                    self.reportOpenMessageAction(resolver: self.resolver,
                                                 messageIds: context.messageIds,
                                                 appid: viewModel.data.appId)
                }
                if self.actionContext is ChatActionContextItem, let context = self.actionContext as? ChatActionContextItem {
                    let newContext = ChatActionContextItem(
                        chat: context.chat,
                        i: context.item,
                        user: context.owner,
                        ttCode: triggerCode
                    )
                    MessageCardSession.shared().recordOpenChatAction(context: newContext)
                }
                /// 准备打开Message Action的上下文
                self.prepareMessageAction(appModel: viewModel, triggerCode: triggerCode)
                /// 打开应用
                self.resolver.navigator.push(target, context: ["from": self.fromScene.rawValue], from: self, animated: true, completion: nil)
                MoreAppTeaReport.imChatMoreAppClick(bizScene: self.bizScene, appID: viewModel.data.appId)
            } else {
                GuideIndexPageVCLogger.error("guideIndex page open message action targetUrl append triggercode fail")
            }
        }
    }
    /// 上报点击message action 打开App
    private func reportOpenMessageAction(
        resolver: Resolver,
        messageIds: [String],
        appid: String?
    ) {
        self.getMessageObservable = try? resolver.resolve(assert: MessageContentService.self).getMessageContent(messageIds: messageIds)
        self.getMessageObservable?
            .subscribe(onNext: { (messageMap) in
                let typeArray = messageIds.map { (messageId) -> Int in
                    return (messageMap[messageId]?.type ?? .unknown).rawValue
                }
                let params = [ParamKey.message_type: typeArray.description, ParamKey.appId: appid ?? ""]
                TeaReporter(eventKey: TeaReporter.key_action_click_app)
                    .withDeviceType()
                    .withUserInfo(resolver: self.resolver)
                    .withInfo(params: params)
                    .report()
            }, onError: { (err) in
                GuideIndexPageVCLogger.error("MessageContentService get Message",
                                             tag: "guideIndex",
                                             additionalData: nil,
                                             error: err)
            }, onCompleted: {
                GuideIndexPageVCLogger.info("reportOpenMessageAction complete")
            }).disposed(by: self.disposeBag)
    }

    private func prepareMessageAction(appModel: MoreAppListCellViewModel, triggerCode: String) {
        /// 提前请求Message详情的内容
        GetMessageDetailHandler.shared.getBlockActionDetail(resolver: resolver,
                                                            appID: appModel.data.appId ?? "",
                                                            triggerCode: triggerCode,
                                                            extraInfo: nil,
                                                            complete: nil)
    }
//}
///// show onboarding views
//extension MoreAppListViewController {
    private func showOnboardingModalVCIfNeed() {
        if (!dataProvider.hasShownBoardingStatus) {
            showOnboardingModalVC()
            dataProvider.saveHasShownBoardingStatus()
        }
        #if DEBUG
        showOnboardingModalVC()
        #endif
    }

    private func showOnboardingModalVC() {
        guard let mainWindow = Navigator.shared.mainSceneWindow else {
            assertionFailure()
            return
        }
        let alertController = MoreAppOnboardingModalController(bizScene: bizScene)
        resolver.navigator.present(alertController, from: mainWindow, animated: true)
    }

    // MARK: - UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
       _numberOfSections(in: collectionView)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        _collectionView(collectionView, numberOfItemsInSection: section)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        _collectionView(collectionView, cellForItemAt: indexPath)
    }

    // MARK: collectionView - DelegateFlowLayout
    /// 设置每个item大小
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        _collectionView(collectionView, layout: collectionViewLayout, sizeForItemAt: indexPath)
    }

    /// 设置section的header高度
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        _collectionView(collectionView, layout: collectionViewLayout, referenceSizeForHeaderInSection: section)
    }

    /// 配置section的间距
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        _collectionView(collectionView, layout: collectionViewLayout, insetForSectionAt: section)
    }

    /// item之间的水平距离
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        _collectionView(collectionView, layout: collectionViewLayout, minimumInteritemSpacingForSectionAt: section)
    }

    /// item之间的垂直距离
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        _collectionView(collectionView, layout: collectionViewLayout, minimumLineSpacingForSectionAt: section)
    }

    // MARK: - UICollectionViewDragDelegate

    /// 拖拽实现参考：https://stackoverflow.com/questions/12257008/using-long-press-gesture-to-reorder-cells-in-tableview/57225766#57225766
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        _collectionView(collectionView, itemsForBeginning: session, at: indexPath)
    }

    /// Controls whether the drag session is restricted to the source application.
    func collectionView(_ collectionView: UICollectionView, dragSessionIsRestrictedToDraggingApplication session: UIDragSession) -> Bool {
        _collectionView(collectionView, dragSessionIsRestrictedToDraggingApplication: session)
    }

    /// 拖拽时隐藏背景色
    func collectionView(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        _collectionView(collectionView, dragPreviewParametersForItemAt: indexPath)
    }

    // MARK: -UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        _collectionView(collectionView, dropSessionDidUpdate: session, withDestinationIndexPath: destinationIndexPath)
    }

    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        _collectionView(collectionView, performDropWith: coordinator)
    }
    // MARK: - UICollectionViewDelegate {
    /// cell点击事件
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        _collectionView(collectionView, didSelectItemAt: indexPath)
    }

    /// headerView
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        _collectionView(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath)
    }

    // MARK: 交互事件 -UITextViewDelegate {
    /// 跳转「获取企业自建应用」
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        _textView(textView, shouldInteractWith: URL, in: characterRange)
    }
}
