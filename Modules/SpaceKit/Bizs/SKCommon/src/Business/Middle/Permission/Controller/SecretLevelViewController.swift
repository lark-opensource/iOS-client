//
//  SecretLevelViewController.swift
//  SKCommon
//
//  Created by guoqp on 2021/10/15.
//  swiftlint:disable file_length line_length type_body_length

import UIKit
import SKUIKit
import SnapKit
import SKResource
import RxSwift
import EENavigator
import LarkUIKit
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignCheckBox
import RxCocoa
import SKFoundation
import SwiftyJSON
import UniverseDesignNotice
import UniverseDesignToast
import UniverseDesignEmpty
import UniverseDesignTag
import SpaceInterface

private enum Layout {
    static var headerHeight: CGFloat { 48 }
    static var itemHeight: CGFloat { 48 }
    static var itemHorizontalSpacing: CGFloat { 13 }
    static var buttonHeight = 48
    static let loadingViewHeight = 330
}

public protocol SecretLevelSelectDelegate: AnyObject {
    func didClickConfirm(_ view: UIViewController, viewModel: SecretLevelViewModel,
                         didUpdate: Bool, showOriginalView: Bool)
    func didClickCancel(_ view: UIViewController, viewModel: SecretLevelViewModel)
    func didSelectRow(_ view: UIViewController, viewModel: SecretLevelViewModel)
    /// 展示审批前置alert
    func shouldApprovalAlert(_ view: UIViewController, viewModel: SecretLevelViewModel)
}

public final class SecretLevelViewController: SKTranslucentPanelController {
    public weak var delegate: SecretLevelSelectDelegate?
    public weak var followAPIDelegate: BrowserVCFollowDelegate?
    public var supportOrientations: UIInterfaceOrientationMask = .portrait
    
    private let disposeBag: DisposeBag = DisposeBag()
    public private(set) var viewModel: SecretLevelViewModel
    private var loadingView: UIView?
    private var itemViews: [SecretLevelItemView] = []

    private var emptyView: UDEmptyView = {
        let emptyView = UDEmptyView(config: .init(title: .init(titleText: ""),
                                                  description: .init(descriptionText: BundleI18n.SKResource.CreationMobile_Common_Placeholder_FailedToLoad),
                                                  imageSize: 100,
                                                  type: .loadingFailure,
                                                  labelHandler: nil,
                                                  primaryButtonConfig: nil,
                                                  secondaryButtonConfig: nil))
        return emptyView
    }()

    private var failView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.bgBody
        return view
    }()

    private lazy var headerView: SKPanelHeaderView = {
        let view = SKPanelHeaderView()
        view.setTitle(BundleI18n.SKResource.CreationMobile_SecureLabel_Edit_PanelTitle)
        view.setCloseButtonAction(#selector(didClickMask), target: self)
        view.backgroundColor = UDColor.bgBody
        return view
    }()

    private lazy var questionButton: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.maybeOutlined, withColorsForStates: [
            (UDColor.iconN1, .normal),
            (UDColor.iconN3, .highlighted),
            (UDColor.iconDisabled, .disabled)
        ])
        button.isHidden = true
        button.hitTestEdgeInsets = UIEdgeInsets(edges: -10)
        button.addTarget(self, action: #selector(didClickQuestion), for: .touchUpInside)
        return button
    }()

    private lazy var notice: UDNotice = {
        let attributedText = NSAttributedString(string: "",
                                                attributes: [.font: UIFont.systemFont(ofSize: 14),
                                                             .foregroundColor: UIColor.ud.textTitle])
        return UDNotice(config: UDNoticeUIConfig(type: .warning, attributedText: attributedText))
    }()

    private lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.backgroundColor = UDColor.bgBodyOverlay
        view.layer.cornerRadius = 10
        view.clipsToBounds = true

        view.axis = .vertical
        view.distribution = .fill
        view.alignment = .fill
        view.spacing = 0

        return view
    }()

    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.layer.cornerRadius = 10
        scrollView.clipsToBounds = true
        scrollView.isPagingEnabled = false
        scrollView.isScrollEnabled = true
        scrollView.alwaysBounceHorizontal = false
        return scrollView
    }()

    private lazy var resetButton: UIButton = {
        let button = UIButton()
        button.setTitle(BundleI18n.SKResource.Doc_Facade_Cancel, for: .normal)
        button.setTitleColor(UDColor.textTitle, for: .normal)
        button.setTitleColor(UDColor.textDisabled, for: .disabled)
        button.setBackgroundImage(UIImage.ud.fromPureColor(UDColor.bgBody), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.layer.borderWidth = 1
        button.layer.ud.setBorderColor(UDColor.lineBorderComponent)
        button.layer.cornerRadius = 6
        button.clipsToBounds = true
        button.docs.addStandardLift()
        button.addTarget(self, action: #selector(didClickReset), for: .touchUpInside)
        return button
    }()

    private lazy var confirmButton: UIButton = {
        let button = UIButton()
        button.setTitle(BundleI18n.SKResource.LarkCCM_Workspace_Security_BtnConfirm_mob, for: .normal)
        button.setTitleColor(UDColor.primaryOnPrimaryFill, for: .normal)
        button.setBackgroundImage(UIImage.ud.fromPureColor(UDColor.iconDisabled), for: .disabled)
        button.setBackgroundImage(UIImage.ud.fromPureColor(UDColor.primaryContentDefault), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.layer.cornerRadius = 6
        button.clipsToBounds = true
        button.docs.addStandardLift()
        button.addTarget(self, action: #selector(didClickConfirm), for: .touchUpInside)
        return button
    }()
    
    // 邀请协作者入口
    private lazy var accessSecretPermissionPanel: AccessSecretPermissionPanel = {
        let panel = AccessSecretPermissionPanel(frame: .zero)
        panel.layer.cornerRadius = 6
        panel.titleLabel.text = BundleI18n.SKResource.LarkCCM_Workspace_SecLevil_PermDetails_Title
        panel.addTarget(self, action: #selector(didClickAccessSecretPermission), for: .touchUpInside)
        panel.isEnabled = true
        return panel
    }()

    public init(viewModel: SecretLevelViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        dismissalStrategy = [.viewSizeChanged]
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if SKDisplay.pad {
            return [.all]
        }
        return supportOrientations
    }

    public override func setupUI() {
        super.setupUI()
        containerView.addSubview(headerView)
        headerView.addSubview(questionButton)
        headerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(containerView.safeAreaLayoutGuide.snp.top)
            make.height.equalTo(Layout.headerHeight)
        }
        questionButton.snp.makeConstraints { make in
            make.top.equalTo(14)
            make.right.equalToSuperview().inset(16)
            make.height.width.equalTo(22)
        }
        request()
    }
    
    public override func transitionToOverFullScreen() {
        super.transitionToOverFullScreen()
        // 适配 iPhone 横屏样式
        if SKDisplay.phone && LKDeviceOrientation.isLandscape() {
            containerView.snp.remakeConstraints { make in
                make.bottom.centerX.equalToSuperview()
                make.width.equalToSuperview().multipliedBy(0.7)
                make.top.greaterThanOrEqualTo(view.safeAreaLayoutGuide.snp.top).inset(14)
            }
        }
    }

    private func reloadViewByItems() {
        failView.removeFromSuperview()

        headerView.backgroundColor = .clear
        containerView.addSubview(notice)
        containerView.addSubview(scrollView)
        scrollView.addSubview(stackView)
        containerView.addSubview(resetButton)
        containerView.addSubview(confirmButton)
        if UserScopeNoChangeFG.TYP.permissionSecretDetail {
            containerView.addSubview(accessSecretPermissionPanel)
        }
        
        showQuestionButtionIfNeed()
        let hideNoticeBanner = hideNoticeBanner(level: viewModel.level)
        notice.isHidden = hideNoticeBanner
        notice.updateConfigAndRefreshUI(noticeConfig(level: viewModel.level))
        notice.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(viewModel.isForcible ? 6 : 0)
            make.left.right.equalToSuperview()
            if hideNoticeBanner {
                make.height.equalTo(0)
            }
        }

        scrollView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(notice.snp.bottom).offset(viewModel.isForcible ? 6 : 16)
            make.height.equalTo(scrollView.contentLayoutGuide.snp.height).priority(.low)
            make.width.equalTo(scrollView.contentLayoutGuide.snp.width)
//            make.height.lessThanOrEqualTo(500).priority(.high)
            make.height.lessThanOrEqualTo(min(view.bounds.size.height * 0.6, 500))
        }

        stackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(scrollView.contentLayoutGuide.snp.top)
            make.bottom.equalTo(scrollView.contentLayoutGuide.snp.bottom)
        }
        if UserScopeNoChangeFG.TYP.permissionSecretDetail {
            accessSecretPermissionPanel.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(16)
                make.top.equalTo(scrollView.snp.bottom).offset(12)
                make.height.equalTo(Layout.buttonHeight)
            }
            resetButton.snp.makeConstraints { make in
                make.leading.equalToSuperview().inset(16)
                make.top.equalTo(accessSecretPermissionPanel.snp.bottom).offset(24)
                make.bottom.equalTo(containerView.safeAreaLayoutGuide.snp.bottom).inset(24)
                make.height.equalTo(40)
            }
        } else {
            resetButton.snp.makeConstraints { make in
                make.leading.equalToSuperview().inset(16)
                make.top.equalTo(scrollView.snp.bottom).offset(24)
                make.bottom.equalTo(containerView.safeAreaLayoutGuide.snp.bottom).inset(24)
                make.height.equalTo(Layout.buttonHeight)
            }
        }
        confirmButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.left.equalTo(resetButton.snp.right).offset(Layout.itemHorizontalSpacing)
            make.width.height.top.bottom.equalTo(resetButton)
        }
        reloadItems()
        updateConfirmButtonState()
        if UserScopeNoChangeFG.TYP.permissionSecretDetail {
            updateAccessSecretPermissionButton()
        }
        viewModel.reportPermissionSecuritySettingView()
    }

    private func updateConfirmButtonState() {
        //默认密级未确认,且当前默认选中了
        if viewModel.level.isDefaultLevel, viewModel.selectedLevelLabel == viewModel.level.label {
            confirmButton.isEnabled = true
        } else {
            confirmButton.isEnabled = (viewModel.selectedLevelLabel != nil) && viewModel.selectedLevelLabel != viewModel.level.label
        }
    }
    
    private func updateAccessSecretPermissionButton() {
        //是否是Full Access用户
        if let canModifySecretLevel = viewModel.userPermission?.canModifySecretLevel(), canModifySecretLevel {
            accessSecretPermissionPanel.panelEnabled = true
        } else {
            accessSecretPermissionPanel.panelEnabled = false
            accessSecretPermissionPanel.snp.remakeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(16)
                make.top.equalTo(scrollView.snp.bottom).offset(12)
                make.bottom.equalTo(containerView.safeAreaLayoutGuide.snp.bottom).inset(24)
            }
            updateResetButtonAndConfirmButton()
        }
    }
    
    private func updateResetButtonAndConfirmButton() {
        confirmButton.isHidden = true
        resetButton.isHidden = true
        itemViews.forEach { SecretLevelItemView in
            SecretLevelItemView.isEnableTap = false
            guard !SecretLevelItemView.item.selected else { return }
            SecretLevelItemView.panelEnabled = false
        }
    }

    private func hideNoticeBanner(level: SecretLevel) -> Bool {
        if viewModel.isForcible {
            return false
        }
        switch level.secretVCBannerStyle {
        case .none, .fail, .tips:
            return true
        case .getDefaultLevelFail:
            return false
        }
    }
    
    private func showQuestionButtionIfNeed() {
        guard let link = viewModel.labelList?.helpLink, !link.isEmpty else {
            DocsLogger.info("secretLevelVC ---- can not show question Button with no help link")
            questionButton.isHidden = true
            return
        }
        questionButton.isHidden = false
    }
    
    private func noticeConfig(level: SecretLevel) -> UDNoticeUIConfig {
        if viewModel.isForcible {
            let attributedText = NSAttributedString(string: BundleI18n.SKResource.LarkCCM_Workspace_SecLeviI_Requir_Banner,
                                                    attributes: [.font: UIFont.systemFont(ofSize: 14),
                                                                 .foregroundColor: UIColor.ud.textTitle])
            return UDNoticeUIConfig(backgroundColor: UIColor.clear, attributedText: attributedText)
        }
        switch level.secretVCBannerStyle {
        case .getDefaultLevelFail:
            let attributedText = NSAttributedString(string: BundleI18n.SKResource.CreationMobile_SecureLabel_GetDefaultFailed_Alert,
                                                    attributes: [.font: UIFont.systemFont(ofSize: 14),
                                                                 .foregroundColor: UIColor.ud.textTitle])
            return UDNoticeUIConfig(type: .warning, attributedText: attributedText)
        case .tips, .none, .fail:
            let attributedText = NSAttributedString(string: BundleI18n.SKResource.CreationMobile_SecureLabel_Prompt,
                                                    attributes: [.font: UIFont.systemFont(ofSize: 14),
                                                                 .foregroundColor: UIColor.ud.textTitle])
            return UDNoticeUIConfig(type: .info, attributedText: attributedText)
        }
    }
    private func reloadItems() {
        viewModel.reloadDataSoure()
        viewModel.dataSource.enumerated().forEach { (offset, sortItem) in
            if offset > 0 {
                let seperatorView = UIView()
                seperatorView.backgroundColor = UDColor.lineDividerDefault
                stackView.addArrangedSubview(seperatorView)
                seperatorView.snp.makeConstraints { make in
                    make.height.equalTo(0.5)
                    make.left.equalToSuperview().offset(16)
                    make.right.equalToSuperview()
                }
            }
            let nextItemView = itemView(for: sortItem, at: offset)
            itemViews.append(nextItemView)
            stackView.addArrangedSubview(nextItemView)
            nextItemView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
            }
        }
    }

    private func itemView(for item: SecretLevelItem, at index: Int) -> SecretLevelItemView {
        let itemView = SecretLevelItemView(item: item)
        itemView.updateNumber(count: viewModel.approvalList?.instances(with: item.levelLabel.id).count ?? 0)
        itemView.selectTap = { currentItem in
            let canModifySecretLevel = self.viewModel.userPermission?.canModifySecretLevel()
            guard !currentItem.selected else {
                
                self.viewModel.reportPermissionSecuritySettingClickModify(isHaveChangePerm: canModifySecretLevel ?? false)
                self.viewModel.reportPermissionSecuritySettingClick(click: .clickSecurityLevel, target: DocsTracker.EventType.noneTargetView.rawValue, securityId: "", isOriginalLevel: true)
                return
            }
            self.viewModel.reportPermissionSecuritySettingClickModify(isHaveChangePerm: canModifySecretLevel ?? false)
            self.viewModel.reportPermissionSecuritySettingClick(click: .clickSecurityLevel, target: DocsTracker.EventType.noneTargetView.rawValue, securityId: "", isOriginalLevel: false)
            self.didClick(index: index)
        }
        itemView.approvalCountTagViewTap = { currentItem in
            self.showApprovalList(item: currentItem)
            self.viewModel.reportPermissionSecuritySettingClick(click: .checking, target: DocsTracker.EventType.ccmPermissionSecurityResubmitToastView.rawValue, securityId: "")
        }
        return itemView
    }

    private func didClick(index: Int) {
        viewModel.dataSource.enumerated().forEach { (offset, item) in
            item.selected = (offset == index)
            let view = itemViews[offset]
            view.updateState(selected: item.selected)
        }
        guard viewModel.selectedLevelLabel != nil else {
            DocsLogger.error("no selected LevelLabel")
            return
        }
        delegate?.didSelectRow(self, viewModel: viewModel)
        updateConfirmButtonState()
    }

    private func showApprovalList(item: SecretLevelItem) {
        guard let list = viewModel.labelList else {
            DocsLogger.error("list is nil")
            return
        }
        let l = list.labels.first {
            item.levelLabel.id == $0.id
        }
        guard let label = l, let approvalList = viewModel.approvalList else {
            DocsLogger.error("label is nil or approvalList is nil")
            return
        }
        let viewModel = SecretApprovalListViewModel(label: label, instances: approvalList.instances(with: label.id), wikiToken: viewModel.wikiToken, token: viewModel.token, type: viewModel.type, permStatistic: viewModel.permStatistic, viewFrom: .settingView)
        let vc = SecretLevelApprovalListViewController(viewModel: viewModel, needCloseBarItem: false, followAPIDelegate: followAPIDelegate)
        self.navigationController?.pushViewController(vc, animated: true)
    }

    @objc
    private func didClickConfirm() {
        guard let label = viewModel.selectedLevelLabel else {
            DocsLogger.error("label is nil")
            return
        }
        var didUpdate: Bool = label.id != viewModel.level.label.id

        ///无密级，第一次选中默认密级的情况
        if viewModel.level.isDefaultLevel, label == viewModel.level.label {
            didUpdate = true
        }
        /// 密级降级的情况
        let downgrade: Bool = label.level < viewModel.level.label.level

        viewModel.reportPermissionSecuritySettingClick(click: .apply,
                                 target: downgrade ? DocsTracker.EventType.ccmPermissionSecurityDemotionView.rawValue : DocsTracker.EventType.noneTargetView.rawValue, securityId: DocsTracker.encrypt(id: label.id))
        dismiss(animated: false) { [self] in
            guard downgrade else {
                delegate?.didClickConfirm(self, viewModel: viewModel,
                                          didUpdate: didUpdate, showOriginalView: false)
                return
            }
            switch viewModel.approvalType {
            case .SelfRepeatedApproval, .OtherRepeatedApproval:
                delegate?.shouldApprovalAlert(self, viewModel: viewModel)
            default:
                delegate?.didClickConfirm(self, viewModel: viewModel,
                                          didUpdate: didUpdate, showOriginalView: true)
            }
        }
    }

    @objc
    private func didClickQuestion() {
        guard let link = viewModel.labelList?.helpLink else {
            DocsLogger.error("secret level VC: can not get help doc link")
            return
        }
        guard let url = URL(string: link) else {
            DocsLogger.error("secret level VC: can not convert url from help doc link")
            return
        }
        Navigator.shared.docs.showDetailOrPush(url, wrap: LkNavigationController.self, from: self)
    }
    
    @objc
    private func didClickAccessSecretPermission() {
        let viewModel = SecretPermissionInfoViewModel(level: viewModel.level, wikiToken: viewModel.wikiToken, token: viewModel.token, type: viewModel.type, permStatistic: viewModel.permStatistic, viewFrom: .banner)
        let vc = SecretPermissionDetailViewController(viewModel: viewModel)
        self.viewModel.reportPermissionSecuritySettingClick(click: PermissionStatistics.SecurityClickAction.viewSecurityInfo, target: DocsTracker.EventType.noneTargetView.rawValue, securityId: "")
        Navigator.shared.docs.showDetailOrPush(vc, wrap: LkNavigationController.self, from: self)
    }

    @objc
    private func didClickReset() {
        delegate?.didClickCancel(self, viewModel: viewModel)
        viewModel.reportPermissionSecuritySettingClick(click: .cancel, target: DocsTracker.EventType.noneTargetView.rawValue, securityId: "")
        self.dismiss(animated: true)
    }

    func request() {
        guard DocsNetStateMonitor.shared.isReachable else {
            showToast(text: BundleI18n.SKResource.Doc_Facade_NetworkInterrutedRetry, type: .failure)
            return
        }
        showLoading()
        viewModel.request { [weak self] success in
            guard let self = self else { return }
            self.hideLoading()
            if success {
                self.reloadViewByItems()
            } else {
                self.showFailView()
            }
        }
    }

    @objc
    private func didClickFailView() {
        request()
    }

    private func showFailView() {
        containerView.addSubview(failView)
        containerView.bringSubviewToFront(failView)
        failView.snp.remakeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(headerView.snp.bottom)
            make.height.equalTo(Layout.loadingViewHeight)
        }
        failView.addSubview(emptyView)
        emptyView.snp.remakeConstraints { make in
            make.width.equalTo(300)
            make.height.equalTo(150)
            make.center.equalToSuperview()
        }
        emptyView.clickHandler = { [weak self] in
            self?.didClickFailView()
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didClickFailView))
        failView.addGestureRecognizer(tapGesture)
    }
}

extension SecretLevelViewController {

    /// 显示loading
    /// - Parameter duration: 展示时长，默认5s；如果传0s的话，就一直loading，需要手动hideLoading()
    /// - Parameter isBehindNavBar: 是否视图层级在 navbar 之下（被 navigation bar 盖住）
    public func showLoading(hostView: UIView? = nil,
                            duration: Int = 5,
                            isBehindNavBar: Bool = false,
                            backgroundAlpha: CGFloat = 1) {
        if loadingView == nil {
            let loadingView = SKLoadingView(backgroundAlpha: backgroundAlpha)
            containerView.addSubview(loadingView)
            containerView.bringSubviewToFront(loadingView)
            loadingView.snp.makeConstraints { make in
                make.left.right.bottom.equalToSuperview()
                make.top.equalTo(headerView.snp.bottom)
                make.height.equalTo(Layout.loadingViewHeight)
            }
            self.loadingView = loadingView
        }
        self.loadingView?.isHidden = false

        if duration > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(duration), execute: { [weak self] in
                self?.hideLoading()
            })
        }
    }

    public func hideLoading() {
        DispatchQueue.main.async(execute: {
            self.loadingView?.removeFromSuperview()
            self.loadingView = nil
        })
    }
}
extension SecretLevelViewController {
    func showToast(text: String, type: DocsExtension<UDToast>.MsgType) {
        guard let view = self.view.window ?? self.view else {
            return
        }
        UDToast.docs.showMessage(text, on: view, msgType: type)
    }
}

public final class IpadSecretLevelViewController: BaseViewController {
    public weak var delegate: SecretLevelSelectDelegate?
    public weak var followAPIDelegate: BrowserVCFollowDelegate?
    private let disposeBag: DisposeBag = DisposeBag()
    private var itemViews: [SecretLevelItemView] = []
    public private(set) var viewModel: SecretLevelViewModel
    private var loadingView: UIView?

    private var emptyView: UDEmptyView = {
           let emptyView = UDEmptyView(config: .init(title: .init(titleText: ""),
                                                     description: .init(descriptionText: BundleI18n.SKResource.CreationMobile_Common_Placeholder_FailedToLoad),
                                                     imageSize: 100,
                                                     type: .loadingFailure,
                                                     labelHandler: nil,
                                                     primaryButtonConfig: nil,
                                                     secondaryButtonConfig: nil))
           return emptyView
    }()

    private var failView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.bgBody
        return view
    }()

    private lazy var notice: UDNotice = {
        let attributedText = NSAttributedString(string: "",
                                                attributes: [.font: UIFont.systemFont(ofSize: 14),
                                                             .foregroundColor: UIColor.ud.textTitle])
        return UDNotice(config: UDNoticeUIConfig(type: .warning, attributedText: attributedText))
    }()

    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.layer.cornerRadius = 10
        scrollView.clipsToBounds = true
        scrollView.isPagingEnabled = false
        scrollView.isScrollEnabled = true
        return scrollView
    }()

    private lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.backgroundColor = UDColor.bgBody
        view.layer.cornerRadius = 10
        view.clipsToBounds = true

        view.axis = .vertical
        view.distribution = .fill
        view.alignment = .fill
        view.spacing = 0

        return view
    }()

    private lazy var resetButton: UIButton = {
        let button = UIButton()
        button.setTitle(BundleI18n.SKResource.Doc_Facade_Cancel, for: .normal)
        button.setTitleColor(UDColor.textTitle, for: .normal)
        button.setTitleColor(UDColor.textDisabled, for: .disabled)
        button.setBackgroundImage(UIImage.ud.fromPureColor(UDColor.bgBody), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.layer.borderWidth = 1
        button.layer.ud.setBorderColor(UDColor.lineBorderComponent)
        button.layer.cornerRadius = 6
        button.clipsToBounds = true
        button.docs.addStandardLift()
        button.addTarget(self, action: #selector(didClickReset), for: .touchUpInside)
        return button
    }()

    private lazy var confirmButton: UIButton = {
        let button = UIButton()
        button.setTitle(BundleI18n.SKResource.LarkCCM_Workspace_Security_BtnConfirm_mob, for: .normal)
        button.setTitleColor(UDColor.primaryOnPrimaryFill, for: .normal)
        button.setBackgroundImage(UIImage.ud.fromPureColor(UDColor.iconDisabled), for: .disabled)
        button.setBackgroundImage(UIImage.ud.fromPureColor(UDColor.primaryContentDefault), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.layer.cornerRadius = 6
        button.clipsToBounds = true
        button.docs.addStandardLift()
        button.addTarget(self, action: #selector(didClickConfirm), for: .touchUpInside)
        return button
    }()
    
    // 邀请协作者入口
    private lazy var accessSecretPermissionPanel: AccessSecretPermissionPanel = {
        let panel = AccessSecretPermissionPanel(frame: .zero)
        panel.layer.cornerRadius = 6
        panel.titleLabel.text = BundleI18n.SKResource.LarkCCM_Workspace_SecLevil_PermDetails_Title
        panel.addTarget(self, action: #selector(didClickAccessSecretPermission), for: .touchUpInside)
        panel.isEnabled = true
        return panel
    }()

    public init(viewModel: SecretLevelViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        dismiss(animated: false, completion: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupDefaultValue()
        request()
    }

    private func reloadViewByItems() {
        failView.removeFromSuperview()
        setupQuestionButton()
        view.addSubview(notice)
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        view.addSubview(resetButton)
        view.addSubview(confirmButton)
        if UserScopeNoChangeFG.TYP.permissionSecretDetail {
            view.addSubview(accessSecretPermissionPanel)
        }

        let hideNoticeBanner = hideNoticeBanner(level: viewModel.level)
        notice.isHidden = hideNoticeBanner
        notice.updateConfigAndRefreshUI(noticeConfig(level: viewModel.level))
        notice.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom).offset(viewModel.isForcible ? 6 : 0)
            make.left.right.equalToSuperview()
            if hideNoticeBanner {
                make.height.equalTo(0)
            }
        }

        scrollView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.width.equalTo(scrollView.contentLayoutGuide.snp.width)
            make.top.equalTo(notice.snp.bottom).offset(viewModel.isForcible ? 6 : 16)
        }

        stackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(scrollView.contentLayoutGuide.snp.top)
            make.bottom.equalTo(scrollView.contentLayoutGuide.snp.bottom)
        }
        if UserScopeNoChangeFG.TYP.permissionSecretDetail {
            accessSecretPermissionPanel.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(16)
                make.top.equalTo(scrollView.snp.bottom).offset(12)
            }

            resetButton.snp.makeConstraints { make in
                make.top.equalTo(accessSecretPermissionPanel.snp.bottom).offset(24)
                make.leading.equalToSuperview().inset(16)
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(24)
                make.height.equalTo(40)
            }
        } else {
            resetButton.snp.makeConstraints { make in
                make.top.equalTo(scrollView.snp.bottom).offset(24)
                make.leading.equalToSuperview().inset(16)
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(24)
                make.height.equalTo(Layout.buttonHeight)
            }
        }
        confirmButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.left.equalTo(resetButton.snp.right).offset(Layout.itemHorizontalSpacing)
            make.width.height.top.bottom.equalTo(resetButton)
        }
        reloadItems()
        updateConfirmButtonState()
        if UserScopeNoChangeFG.TYP.permissionSecretDetail {
            updateAccessSecretPermissionButton()
        }
        viewModel.reportPermissionSecuritySettingView()
    }

    private func updateConfirmButtonState() {
        //默认密级未确认,且当前默认选中了
        if viewModel.level.isDefaultLevel, viewModel.selectedLevelLabel == viewModel.level.label {
            confirmButton.isEnabled = true
        } else {
            confirmButton.isEnabled = (viewModel.selectedLevelLabel != nil) && viewModel.selectedLevelLabel != viewModel.level.label
        }
    }
    private func hideNoticeBanner(level: SecretLevel) -> Bool {
        if viewModel.isForcible {
            return false
        }
        switch viewModel.level.secretVCBannerStyle {
        case .none, .fail, .tips:
            return true
        case .getDefaultLevelFail:
            return false
        }
    }
    private func noticeConfig(level: SecretLevel) -> UDNoticeUIConfig {
        if viewModel.isForcible {
            let attributedText = NSAttributedString(string: BundleI18n.SKResource.LarkCCM_Workspace_SecLeviI_Requir_Banner,
                                                    attributes: [.font: UIFont.systemFont(ofSize: 14),
                                                                 .foregroundColor: UIColor.ud.textTitle])
            return UDNoticeUIConfig(backgroundColor: UIColor.clear, attributedText: attributedText)
        }
        switch viewModel.level.secretVCBannerStyle {
        case .getDefaultLevelFail:
            let attributedText = NSAttributedString(string: BundleI18n.SKResource.CreationMobile_SecureLabel_GetDefaultFailed_Alert,
                                                    attributes: [.font: UIFont.systemFont(ofSize: 14),
                                                                 .foregroundColor: UIColor.ud.textTitle])
            return UDNoticeUIConfig(type: .warning, attributedText: attributedText)
        case .tips, .none, .fail:
            let attributedText = NSAttributedString(string: BundleI18n.SKResource.CreationMobile_SecureLabel_Prompt,
                                                    attributes: [.font: UIFont.systemFont(ofSize: 14),
                                                                 .foregroundColor: UIColor.ud.textTitle])
            return UDNoticeUIConfig(type: .info, attributedText: attributedText)
        }
    }

    func setupDefaultValue() {
        view.backgroundColor = UDColor.bgBase
        navigationBar.title = BundleI18n.SKResource.CreationMobile_SecureLabel_Edit_PanelTitle
        let closeItem = SKBarButtonItem(image: UDIcon.closeSmallOutlined,
                                   style: .plain,
                                   target: self,
                                   action: #selector(backBarButtonItemAction))
        closeItem.id = .back
        navigationBar.leadingBarButtonItem = closeItem
        
    }
    
    func setupQuestionButton() {
        guard let link = viewModel.labelList?.helpLink, !link.isEmpty else {
            DocsLogger.info("secretLevelVC.ipad ---- can not show question Button with no help link")
            return
        }
        let questionItem = SKBarButtonItem(image: UDIcon.maybeOutlined,
                                           style: .plain,
                                           target: self,
                                           action: #selector(didClickQuestion))
        navigationBar.trailingBarButtonItem = questionItem
    }

    override public var canShowBackItem: Bool {
        return false
    }

    override public func backBarButtonItemAction() {
        viewModel.reportPermissionSecuritySettingClick(click: .cancel, target: DocsTracker.EventType.noneTargetView.rawValue, securityId: "")
        self.dismiss(animated: true, completion: nil)
    }

    private func reloadItems() {
        viewModel.reloadDataSoure()
        viewModel.dataSource.enumerated().forEach { (offset, sortItem) in
            if offset > 0 {
                let seperatorView = UIView()
                seperatorView.backgroundColor = UDColor.lineDividerDefault
                stackView.addArrangedSubview(seperatorView)
                seperatorView.snp.makeConstraints { make in
                    make.height.equalTo(0.5)
                    make.left.equalToSuperview().offset(16)
                    make.right.equalToSuperview()
                }
            }
            let nextItemView = itemView(for: sortItem, at: offset)
            itemViews.append(nextItemView)
            stackView.addArrangedSubview(nextItemView)
            nextItemView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
            }
        }
    }

    private func itemView(for item: SecretLevelItem, at index: Int) -> SecretLevelItemView {
        let itemView = SecretLevelItemView(item: item)
        itemView.updateNumber(count: viewModel.approvalList?.instances(with: item.levelLabel.id).count ?? 0)
        itemView.selectTap = { currentItem in
            guard !currentItem.selected else { return }
            self.didClick(index: index)
        }
        itemView.approvalCountTagViewTap = { currentItem in
            self.showApprovalList(item: currentItem)
            self.viewModel.reportPermissionSecuritySettingClick(click: .checking, target: DocsTracker.EventType.ccmPermissionSecurityResubmitToastView.rawValue, securityId: "")
        }
        return itemView
    }

    private func didClick(index: Int) {
        viewModel.dataSource.enumerated().forEach { (offset, item) in
            item.selected = (offset == index)
            let view = itemViews[offset]
            view.updateState(selected: item.selected)
        }
        guard viewModel.selectedLevelLabel != nil else {
            DocsLogger.error("no selected LevelLabel")
            return
        }
        delegate?.didSelectRow(self, viewModel: viewModel)
        updateConfirmButtonState()
    }

    private func showApprovalList(item: SecretLevelItem) {
        guard let list = viewModel.labelList else {
            DocsLogger.error("list is nil")
            return
        }
        let l = list.labels.first {
            item.levelLabel.id == $0.id
        }
        guard let label = l, let approvalList = viewModel.approvalList else {
            DocsLogger.error("label or approvalList is nil")
            return
        }
        let viewModel = SecretApprovalListViewModel(label: label, instances: approvalList.instances(with: label.id), wikiToken: viewModel.wikiToken, token: viewModel.token, type: viewModel.type, permStatistic: viewModel.permStatistic, viewFrom: .settingView)
        let vc = SecretLevelApprovalListViewController(viewModel: viewModel, needCloseBarItem: true)
        let navVC = LkNavigationController(rootViewController: vc)
        navVC.modalPresentationStyle = isMyWindowRegularSizeInPad ? .formSheet :.fullScreen
        self.present(navVC, animated: true, completion: nil)
    }
    
    private func updateAccessSecretPermissionButton() {
        //是否是Full Access用户
        if let canModifySecretLevel = viewModel.userPermission?.canModifySecretLevel(), canModifySecretLevel {
            accessSecretPermissionPanel.panelEnabled = true
        } else {
            accessSecretPermissionPanel.panelEnabled = false
            accessSecretPermissionPanel.snp.remakeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(16)
                make.top.equalTo(scrollView.snp.bottom).offset(12)
                make.height.equalTo(Layout.buttonHeight)
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(24)
            }
            updateResetButtonAndConfirmButton()
        }
    }
    
    private func updateResetButtonAndConfirmButton() {
        confirmButton.isHidden = true
        resetButton.isHidden = true
        itemViews.forEach { SecretLevelItemView in
            SecretLevelItemView.isEnableTap = false
            guard !SecretLevelItemView.item.selected else { return }
            SecretLevelItemView.panelEnabled = false
        }
    }

    @objc
    private func didClickConfirm() {
        guard let label = viewModel.selectedLevelLabel else {
            DocsLogger.error("label is nil")
            return
        }
        var didUpdate: Bool = label.id != viewModel.level.label.id

        ///无密级，第一次选中默认密级的情况
        if viewModel.level.isDefaultLevel, label == viewModel.level.label {
            didUpdate = true
        }
        /// 密级降级的情况
        let downgrade: Bool = label.level < viewModel.level.label.level

        viewModel.reportPermissionSecuritySettingClick(click: .apply,
                                 target: downgrade ? DocsTracker.EventType.ccmPermissionSecurityDemotionView.rawValue : DocsTracker.EventType.noneTargetView.rawValue, securityId: DocsTracker.encrypt(id: label.id))
        dismiss(animated: false) { [self] in
            guard downgrade else {
                delegate?.didClickConfirm(self, viewModel: viewModel,
                                          didUpdate: didUpdate, showOriginalView: false)
                return
            }
            switch viewModel.approvalType {
            case .SelfRepeatedApproval, .OtherRepeatedApproval:
                delegate?.shouldApprovalAlert(self, viewModel: viewModel)
            default:
                delegate?.didClickConfirm(self, viewModel: viewModel,
                                          didUpdate: didUpdate, showOriginalView: true)
            }
        }
    }
    
    
    @objc
    private func didClickAccessSecretPermission() {
        let viewModel = SecretPermissionInfoViewModel(level: viewModel.level, wikiToken: viewModel.wikiToken, token: viewModel.token, type: viewModel.type, permStatistic: viewModel.permStatistic, viewFrom: .banner)
        let vc = SecretPermissionDetailViewController(viewModel: viewModel)
        Navigator.shared.docs.showDetailOrPush(vc, wrap: LkNavigationController.self, from: self)
    }

    @objc
    private func didClickReset() {
        delegate?.didClickCancel(self, viewModel: viewModel)
        viewModel.reportPermissionSecuritySettingClick(click: .cancel, target: DocsTracker.EventType.noneTargetView.rawValue, securityId: "")
        self.dismiss(animated: true)
    }

    @objc
    private func didClickQuestion() {
        guard let link = viewModel.labelList?.helpLink else {
            DocsLogger.error("secret level VC: can not get help doc link")
            return
        }
        guard let url = URL(string: link) else {
            DocsLogger.error("secret level VC: can not convert url from help doc link")
            return
        }
        Navigator.shared.docs.showDetailOrPush(url, wrap: LkNavigationController.self, from: self)
    }

    func request() {
        guard DocsNetStateMonitor.shared.isReachable else {
            showToast(text: BundleI18n.SKResource.Doc_Facade_NetworkInterrutedRetry, type: .failure)
            return
        }
        showLoading()
        viewModel.request { [weak self] success in
            guard let self = self else { return }
            self.hideLoading()
            if success {
                self.reloadViewByItems()
            } else {
                self.showFailView()
            }
        }
    }

    @objc
    private func didClickFailView() {
        request()
    }

    private func showFailView() {
        view.addSubview(failView)
        view.bringSubviewToFront(failView)
        failView.snp.remakeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(navigationBar.snp.bottom)
//            make.height.equalTo(Layout.loadingViewHeight)
        }
        failView.addSubview(emptyView)
        emptyView.snp.remakeConstraints { make in
            make.width.equalTo(300)
            make.height.equalTo(150)
            make.center.equalToSuperview()
        }
        emptyView.clickHandler = { [weak self] in
            self?.didClickFailView()
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didClickFailView))
        failView.addGestureRecognizer(tapGesture)
    }
}
extension IpadSecretLevelViewController {
    func showToast(text: String, type: DocsExtension<UDToast>.MsgType) {
        guard let view = self.view.window ?? self.view else {
            return
        }
        UDToast.docs.showMessage(text, on: view, msgType: type)
    }
}
