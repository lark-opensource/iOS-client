//
//  BlockPreviewController.swift
//  OPBlock
//
//  Created by yinyuan on 2021/2/22.
//

import Foundation
import LarkUIKit
import LKCommonsLogging
import LarkOPInterface
import SwiftyJSON
import EENavigator
import OPSDK
import RoundedHUD
import UniverseDesignTabs
import UniverseDesignFont
import UniverseDesignIcon
import UniverseDesignToast
import EEMicroAppSDK
import LarkEMM
import LarkSetting
import LarkStorage
import LarkAccountInterface
import LarkNavigator
import LarkContainer

/// collecitonview 中所有用到的 ReuseIdentifier
enum ReuseIdentifier: String {
    /// 异常情况下未知类型（正常情况不会出现）
    case unknown
    /// 图标 类型 cell
    case icon
    // section header
    case header
    // section space
    case space
    // section fill
    case fill
    // section footer
    case footer
}

/// Block 预览
///
/// 主要复用了工作台主页的布局逻辑，但也有差异：
/// 差异1: 固定的布局模式，数据来源于本地组装
/// 差异2: 特有的预览模式图标
/// 差异3: 固定的 Block 预览组件
public final class BlockPreviewController: BaseUIViewController,
                                           UICollectionViewDelegateFlowLayout,
                                           UICollectionViewDataSource,
                                           BlockCellDelegate,
                                           UIViewControllerTransitioningDelegate {

    private static let logger = Logger.log(BlockPreviewController.self)

    /// 预览链接
    private let url: URL

    private var previewSetting: BlockPreviewSetting?

    private var blockAutoHeight: CGFloat = 200

    /// 预览界面的 ViewModel
    private var previewViewModle: WorkPlaceViewModel?

    private var uniqueID: OPAppUniqueID?

    private var floatButtonInitCenter = CGPoint()

    /// 调试面板的VC
    private var logConsoleController = LogConsoleController()

    // WPBlockView 使用，依赖太深，后续改造
    private let userResolver: UserResolver
    private let navigator: UserNavigator
    private let openService: WorkplaceOpenService
    private let dataManager: AppCenterDataManager
    let userId: String
    private let configService: WPConfigService

    /// 浮窗的label
    private var floatButtonTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "vConsole"
        label.textAlignment = .center
        // swiftlint:disable init_font_with_token
        label.font = UIFont.systemFont(ofSize: 15)
        // swiftlint:enable init_font_with_token
        label.textColor = .white
        label.backgroundColor = UIColor.clear
        return label
    }()

    /// 三角形icon，点击触发调试面板
    private var triangleIconView: UIView = {
        let triangleIcon = UIView()
        /// 绘制三角形
        let trianglePath = UIBezierPath()
        let triangleLayer = CAShapeLayer()
        trianglePath.move(
            to: CGPoint.zero
        )
        trianglePath.addLine(
            to: CGPoint(x: 10, y: 0)
        )
        trianglePath.addLine(
            to: CGPoint(x: 5, y: 8)
        )
        trianglePath.addLine(
            to: CGPoint.zero
        )
        triangleLayer.path = trianglePath.cgPath
        triangleLayer.fillColor = UIColor.white.cgColor
        triangleIcon.layer.addSublayer(triangleLayer)
        return triangleIcon
    }()

    /// 浮窗的view
    // swiftlint:disable closure_body_length
    private lazy var floatButton: UIButton = {
        let buttonView = UIButton()
        let greenDot = UIView()
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let floatActionButtonWidth = screenWidth / 3
        let floatActionButtonHeight = screenHeight / 20
        buttonView.addSubview(triangleIconView)
        buttonView.addSubview(floatButtonTitleLabel)
        buttonView.addSubview(greenDot)

        triangleIconView.frame = CGRect(
            x: floatActionButtonWidth - 30,
            y: 2 * floatActionButtonHeight / 5,
            width: 30,
            height: 30
        )

        floatButtonTitleLabel.frame = CGRect(
            x: floatActionButtonWidth / 5,
            y: floatActionButtonHeight / 4,
            width: floatActionButtonWidth / 2,
            height: 2 * floatActionButtonHeight / 5
        )

        greenDot.frame = CGRect(
            x: floatActionButtonWidth / 8,
            y: 2 * floatActionButtonHeight / 5,
            width: 8, height: 8
        )
        greenDot.layer.cornerRadius = 4
        greenDot.backgroundColor = .systemGreen

        buttonView.layer.cornerRadius = 8
        buttonView.clipsToBounds = true
        buttonView.backgroundColor = .darkGray
        buttonView.frame = CGRect(
            x: screenWidth - floatActionButtonWidth,
            y: 200,
            width: floatActionButtonWidth,
            height: floatActionButtonHeight
        )

        return buttonView
    }()
    // swiftlint:enable closure_body_length

    @objc
    func onSettingItemTapped(_ sender: UIBarButtonItem) {
        let vc = BlockPreviewSettingVC(cache: previewSetting)
        vc.transitioningDelegate = self
        vc.modalPresentationStyle = .custom
        vc.onSettingComplete = { [weak self] obj in
            guard let self = self, let setting = obj else {
                return
            }
            self.previewSetting = setting
            self.savePreviewSetting(by: self.uniqueID?.identifier ?? "")
            self.collectionView.collectionViewLayout.invalidateLayout()
        }
        present(vc, animated: true, completion: nil)
    }

    @objc
    func copyPreviewURL(_ sender: UIBarButtonItem) {
        let pasteboardConfig = PasteboardConfig(token: OPSensitivityEntryToken.BlockPreviewControllerCopyPreviewURL.psdaToken)
        SCPasteboard.general(pasteboardConfig).string = url.absoluteString
        UDToast.showSuccess(with: "success", on: view)
    }

    @objc func tapButton() {
        logConsoleController.transitioningDelegate = self
        logConsoleController.modalPresentationStyle = .custom
        present(logConsoleController, animated: true, completion: nil)
    }

    @objc func dragButton(gesture: UIPanGestureRecognizer) {

        guard gesture.view != nil else { return }

        // swiftlint:disable force_unwrapping
        let button = gesture.view!
        // swiftlint:enable force_unwrapping
        let translation = gesture.translation(in: self.view)

        switch gesture.state {
        case .began:
            self.floatButtonInitCenter = button.center
        case .cancelled:
            button.center = self.floatButtonInitCenter
        case .ended: /// 浮窗拖动越界处理
            if floatButton.frame.midX < 0 {
                UIView.animate(withDuration: 0.2, animations: {
                    button.frame.origin.x = 0
                }, completion: nil)
            } else if floatButton.frame.midX > self.view.frame.width {
                UIView.animate(withDuration: 0.2, animations: {
                    button.frame.origin.x = self.view.bounds.width - button.bounds.width
                }, completion: nil)
            }

            if floatButton.frame.midY < 0 {
                UIView.animate(withDuration: 0.2, animations: {
                    button.frame.origin.y = 0
                }, completion: nil)
            } else if floatButton.frame.midY > self.view.frame.height {
                UIView.animate(withDuration: 0.2, animations: {
                    button.frame.origin.y = self.view.bounds.height - button.bounds.height
                }, completion: nil)
            }
        default:
            let newCenter = CGPoint(
                x: floatButtonInitCenter.x + translation.x,
                y: floatButtonInitCenter.y + translation.y
            )
            button.center = newCenter
        }
    }

    // swiftlint:disable closure_body_length
    private lazy var collectionView: UICollectionView = {
        /// layout
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = WorkPlaceViewModel.itemMinSpace
        layout.sectionHeadersPinToVisibleBounds = true

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self

        // 注册重用 Cell 组件
        collectionView.register(BlockPreviewIconCell.self, forCellWithReuseIdentifier: ReuseIdentifier.icon.rawValue)
        collectionView.register(EmptySpaceViewCell.self, forCellWithReuseIdentifier: ReuseIdentifier.space.rawValue)
        collectionView.register(FillEmptySpaceCell.self, forCellWithReuseIdentifier: ReuseIdentifier.fill.rawValue)
        collectionView.register(EmptySpaceViewCell.self, forCellWithReuseIdentifier: ReuseIdentifier.unknown.rawValue)

        // 注册重用的 header 和 footer
        collectionView.register(
            PreviewGroupHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: ReuseIdentifier.header.rawValue
        )
        collectionView.register(
            EmptyFooterView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: ReuseIdentifier.footer.rawValue
        )

        // 设定基础样式
        collectionView.backgroundColor = UIColor.ud.bgBody

        return collectionView
    }()
    // swiftlint:enable closure_body_length

    init(
        url: URL,
        userResolver: UserResolver,
        navigator: UserNavigator,
        openService: WorkplaceOpenService,
        dataManager: AppCenterDataManager,
        userId: String,
        configService: WPConfigService
    ) {
        self.url = url
        self.userResolver = userResolver
        self.navigator = navigator
        self.openService = openService
        self.dataManager = dataManager
        self.userId = userId
        self.configService = configService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // 适配iPad分/转屏，collectionview需要刷新布局（仅刷新布局的地方不要用reloadData）
    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        Self.logger.info("WorkPlace viewWillTransition, are U ready")
        super.viewWillTransition(to: size, with: coordinator)
        // 执行分/转屏
        coordinator.animate(alongsideTransition: nil, completion: { [weak self](_) in
            guard let `self` = self else { return }
            self.collectionView.collectionViewLayout.invalidateLayout()
        })
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // collectionView 宽度调整时，计算列表视图布局，重新加载
        // 原实现在 viewWillTransition 中
        // 修复 ios16 & iphone mini 屏幕旋转时，viewWillTransition to size 存在负值的情况
        // 将 previewViewModle 数据刷新移到该处
        let collectionViewWidth = self.collectionView.bounds.width
        if let needRefresh = self.previewViewModle?.refreshDisplayIfNeeded(with: collectionViewWidth), needRefresh {
            Self.logger.info("WorkPlace's width changed, display views need refresh")
            self.collectionView.reloadData()
        }
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        preview()
    }

    private func preview() {
        let appID = url.queryParameters["app_id"] ?? ""
        let blockTypeID = url.queryParameters["block_type_id"] ?? ""
        let previewToken = url.queryParameters["token"]

        uniqueID = OPAppUniqueID(
            appID: appID,
            identifier: blockTypeID,
            versionType: previewToken == nil ? .current : .preview,
            appType: .block,
            instanceID: previewToken
        )

        previewViewModle = BlockPreviewViewModel.generatePreviewModel(
            containerWidth: self.parent?.view.bdp_width ?? view.bdp_width,
            appID: appID,
            blockTypeID: blockTypeID,
            previewToken: previewToken,
            dataManager: dataManager
        )
        previewSetting = loadPreviewSetting(by: blockTypeID)
        collectionView.reloadData()
    }

    /// 初始化视图
    private func setupView() {
        title = BundleI18n.LarkWorkplace.OpenPlatform_WidgetPreview_PageTtl

        view.addSubview(collectionView)
        view.addSubview(floatButton)

        floatButton.addTarget(self, action: #selector(tapButton), for: .touchUpInside)
        floatButton.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(dragButton)))

        let settingItem = UIBarButtonItem(
            image: UDIcon.settingOutlined,
            style: .plain,
            target: self,
            action: #selector(onSettingItemTapped(_:))
        )
        navigationItem.rightBarButtonItem = settingItem
        let blockPreviewDebugSwitch = EMADebugUtil.sharedInstance()?
            .debugConfig(forID: kEMADebugConfigIDShowBlockPreviewUrl)?.boolValue ?? false
        if blockPreviewDebugSwitch {
            let copyPreviewwURLItem = UIBarButtonItem(
                image: UDIcon.sharelinkOutlined,
                style: .plain,
                target: self,
                action: #selector(copyPreviewURL(_:))
            )
            navigationItem.rightBarButtonItems = [settingItem, copyPreviewwURLItem]
        }
        setupConstraint()

        /// 设置导航栏左侧的关闭按钮
        addCloseItem()
    }

    /// 初始化布局约束
    private func setupConstraint() {
        collectionView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    /// 关闭page的点击事件
    override public func closeBtnTapped() {
        // ipad下，如果是唯一一个VC，则展示Default来关闭VC
        if Display.pad, navigationController?.viewControllers.first == self {
            navigator.showDetail(DefaultDetailController(), from: self)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    // MARK: - UICollectionViewDelegateFlowLayout
    /// 设置section的header高度（来自于工作台主页逻辑，请尽量保持一致）
    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        /// 获取相应sectionModel
        guard let sectionModel = previewViewModle?.getSectionModel(index: section) else {
            Self.logger.error("get sectionModel at \(section) faild!")
            return .zero
        }
        /// 获取当前section的header大小，返回.zero则不展示
        return sectionModel.getHeaderSize(superViewWidth: collectionView.bdp_width)
    }
    /// 设置section的footer高度（来自于工作台主页逻辑，请尽量保持一致）
    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForFooterInSection section: Int
    ) -> CGSize {
        /// 获取相应sectionModel
        guard let sectionModel = previewViewModle?.getSectionModel(index: section) else {
            Self.logger.error("get sectionModel at \(section) faild!")
            return .zero
        }
        /// 获取当前section的header大小，返回.zero则不展示
        let itemsPerRow = WorkPlaceViewModel.appsCountPerRow
        return sectionModel.getFooterSize(
            collectionview: collectionView,
            section: section,
            itemsPerRow: itemsPerRow
        )
    }
    /// 设置每个item大小（来自于工作台主页逻辑，请尽量保持一致）
    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        guard let sectionModel = previewViewModle?.getSectionModel(index: indexPath.section),
        let itemModel = sectionModel.getItemAtIndex(index: indexPath.item) else {
            Self.logger.error("get itemSize at section-\(indexPath.section) item-\(indexPath.item) failed!")
            return .zero
        }
        var size = itemModel.getItemLayoutSize(superViewWidth: collectionView.bdp_width)
        if itemModel.itemType == .block {
            if previewSetting?.previewHeight == TMPLBlockStyles.autoHightValue {
                size.height = blockAutoHeight
            } else if let str = previewSetting?.previewHeight, !str.isEmpty, let val = Float(str), val > 0 {
                size.height = CGFloat(val)
            }
        }
        return size
    }
    /// 设置item之间的行间距（来自于工作台主页逻辑，请尽量保持一致）
    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        return ItemModel.miniLineSpace
    }
    // MARK: - UICollectionViewDataSource

    /// 根据UIModel获取section数量（缺省值：0）
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return previewViewModle?.getSectionsCount() ?? 0
    }

    /// 每个section的item数量（缺省值：0）
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let sectionModel = previewViewModle?.getSectionModel(index: section) else {
            Self.logger.error("get sectionModel at section-\(section) failed on getNumofSection")
            return 0
        }
        return sectionModel.getDisplayItemCount()
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        /// model检查，获取相应位置的itemModel
        guard let sectionModel = previewViewModle?.getSectionModel(index: indexPath.section),
            let itemModel = sectionModel.getItemAtIndex(index: indexPath.row) else {
            Self.logger.error("getUIModel for cell at section-\(indexPath.section) failed")
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: ReuseIdentifier.unknown.rawValue,
                for: indexPath
            )
        }

        switch itemModel.itemType {
        case ItemType.block:
            guard let blockModel = itemModel.getBlockModel() else {
                assertionFailure("block data missing")
                return collectionView.dequeueReusableCell(
                    withReuseIdentifier: ReuseIdentifier.unknown.rawValue,
                    for: indexPath
                )
            }
            let cellId = blockModel.uniqueId.fullString
            collectionView.register(BlockCell.self, forCellWithReuseIdentifier: cellId)
            guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: cellId,
                    for: indexPath
            ) as? BlockCell else {
                assertionFailure("cell type error")
                return collectionView.dequeueReusableCell(
                    withReuseIdentifier: ReuseIdentifier.unknown.rawValue,
                    for: indexPath
                )
            }
            cell.delegate = self
			cell.updateData(blockModel, hostVCShow: true, trace: nil, userResolver: userResolver)
            return cell
        case ItemType.icon:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ReuseIdentifier.icon.rawValue,
                for: indexPath
            )
            return cell
        case ItemType.verticalSpace:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ReuseIdentifier.space.rawValue,
                for: indexPath
            )
            return cell
        case ItemType.fillItem:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ReuseIdentifier.fill.rawValue,
                for: indexPath
            )
            return cell
        default:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ReuseIdentifier.unknown.rawValue,
                for: indexPath
            )
            return cell
        }
    }

    /// 设置section的附加视图（分组title）
    public func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            return self.heraderForCollectionView(collectionView, at: indexPath)
        case UICollectionView.elementKindSectionFooter:
            return self.footerForCollectionView(collectionView, at: indexPath)
        default:
            return UICollectionReusableView(frame: .zero)
        }
    }
    /// 获取对应的header
    private func heraderForCollectionView(
        _ collectionView: UICollectionView,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard let uimodel = previewViewModle else {
            Self.logger.error("previewViewModle is nil")
            return UICollectionReusableView(frame: .zero)
        }
        guard let sectionModel = uimodel.getSectionModel(index: indexPath.section) else {
            Self.logger.error("sectionModel is nil, index is \(indexPath)")
            return UICollectionReusableView(frame: .zero)
        }

        switch sectionModel.type {
        case .normalSection, .favorite:
            let headerView = collectionView.dequeueReusableSupplementaryView(
                ofKind: UICollectionView.elementKindSectionHeader,
                withReuseIdentifier: ReuseIdentifier.header.rawValue,
                for: indexPath
            )
            if let headerView = headerView as? PreviewGroupHeaderView {
                headerView.updateData(groupTitle: sectionModel.sectionName)
                return headerView
            }
        case .allAllsSection:
            break
        }

        return UICollectionReusableView(frame: .zero)
    }
    /// 获取对应的footer
    private func footerForCollectionView(
        _ collectionView: UICollectionView,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        let footer = collectionView.dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: ReuseIdentifier.footer.rawValue,
            for: indexPath
        )
        guard let uimodel = previewViewModle else {
            Self.logger.error("previewViewModle is nil")
            return footer
        }
        guard let sectionModel = uimodel.getSectionModel(index: indexPath.section) else {
            Self.logger.error("sectionModel is nil, index is \(indexPath)")
            return footer
        }
        (footer as? EmptyFooterView)?.hasMore = sectionModel.hasMoreData()
        return footer
    }
    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        return UIEdgeInsets(
            top: 2.5,
            left: ItemModel.horizontalCellMargin,
            bottom: 0,
            right: ItemModel.horizontalCellMargin
        )
    }
    public func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        guard let sectionModel = previewViewModle?.getSectionModel(index: indexPath.section),
            let itemModel = sectionModel.getItemAtIndex(index: indexPath.row) else {
            Self.logger.error("getUIModel for cell at section-\(indexPath.section) failed")
            return true
        }
        /// 状态的cell不能够选中，否则样式会出现问题
        if itemModel.itemType == .stateItem {
            return false
        }
        return true
    }

    // MARK: - BlockCellDelegate
    func onTitleClick(_ cell: BlockCell, link: String?) {
        guard let indexPath = collectionView.indexPath(for: cell),
              let model = previewViewModle,
              let section = model.getSectionModel(index: indexPath.section),
              let item = section.getItemAtIndex(index: indexPath.row) else {
            return
        }
        // 同 widget 跳转逻辑
        if let url = link {
            openService.openAppLink(url, from: self)
        } else if item.getSingleAppInfo() != nil {
            // 没有此功能
        } else {
            // 无法打开
        }
    }
    func onActionClick(_ cell: BlockCell) {
        // 无此功能
    }
    func onLongPress(_ cell: BlockCell, gesture: UIGestureRecognizer) {
        // 无此功能
    }

    func blockDidFail(_ cell: BlockCell, error: OPError) {
        Self.logger.error("fecth meta failed", tag: "Preview", additionalData: nil, error: error)
        // 加载失败
        if error.monitorCode == OPSDKMonitorCodeLoader.get_meta_biz_error {
            // meta 请求的业务错误
            if let codeRawValue = error.userInfo["code"] as? Int,
               let code = OPAppMetaResponseCode(rawValue: codeRawValue) {
                Self.logger.error("preview get_meta_biz_error code:\(codeRawValue)")
                // 针对该特定的后端错误码进行提示 10251:preview
                switch code {
                case .preview_token_has_expired:
                    // 预览 Token 已失效，提示
                    if let view = self.view {
                        RoundedHUD.showFailure(
                            with: BundleI18n.LarkWorkplace.OpenPlatform_WorkplaceBlock_PreviewTokenExpireMsg,
                            on: view
                        )
                    }
                default:
                    // 什么也不做
                    break
                }
            }
        }
    }

    func blockRenderSuccess(_ cell: BlockCell) {
    }

    func blockDidReceiveLogMessage(_ cell: BlockCell, message: WPBlockLogMessage) {
        logConsoleController.appendLog(logItem: message)
    }

    func blockContentSizeDidChange(_ cell: BlockCell, newSize: CGSize) {
        Self.logger.info("blockContentSizeDidChange: \(newSize)")
        guard newSize.height > 0 else {
            return
        }
        blockAutoHeight = newSize.height
        if previewSetting?.previewHeight == TMPLBlockStyles.autoHightValue {
            Self.logger.info("apply auto block height: \(blockAutoHeight)")
            collectionView.collectionViewLayout.invalidateLayout()
        }
    }

    // MARK: - UIViewControllerTransitioningDelegate
    public func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {
        LogConsolePresentationController(presentedViewController: presented, presenting: presenting)
    }
}

// MARK: - Block Setting Cache
extension BlockPreviewController {
    private func loadPreviewSetting(by blockTypeID: String) -> BlockPreviewSetting? {
        let store = KVStores.in(space: .user(id: userId), domain: Domain.biz.workplace).mmkv()
        let model: BlockPreviewSetting? = store.value(forKey: WPCacheKey.blockPreviewSettings(blockTypeId: blockTypeID))
        Self.logger.info("[\(WPCacheKey.blockPreviewSettings(blockTypeId: blockTypeID))] cache \(model == nil ? "miss" : "hit").")
        return model
    }

    private func savePreviewSetting(by blockTypeID: String) {
        let store = KVStores.in(space: .user(id: userId), domain: Domain.biz.workplace).mmkv()
        store.set(previewSetting, forKey: WPCacheKey.blockPreviewSettings(blockTypeId: blockTypeID))
        Self.logger.info("[\(WPCacheKey.blockPreviewSettings(blockTypeId: blockTypeID))] cache data.")
    }
}
