//
//  MemberInviteLarkSplitViewController.swift
//  LarkContact
//
//  Created by shizhengyu on 2020/6/8.
//

import UIKit
import Foundation
import LarkUIKit
import SnapKit
import LarkAlertController
import RxSwift
import UniverseDesignToast
import LKCommonsLogging
import LKMetric
import LarkMessengerInterface
import LarkSnsShare
import LarkTraitCollection
import LarkEnv
import LarkAccountInterface
import LarkContainer

/// 海外版成员邀请分流页
final class MemberInviteLarkSplitViewController: BaseUIViewController, UITableViewDataSource, UITableViewDelegate {
    private let viewModel: MemberInviteLarkSplitViewModel
    var rightButtonTitle: String?
    var rightButtonClickHandler: (() -> Void)?
    private var isPresented: Bool = false
    private var tableViewHeaderHeight: CGFloat = 0.0
    private let disposeBag = DisposeBag()
    static let logger = Logger.log(MemberInviteLarkSplitViewController.self,
                                   category: "LarkContact.MemberInviteLarkSplitViewController")
    private let userResolver: UserResolver
    private let passportService: PassportService

    private lazy var needDisablePopSource: Bool = {
        return viewModel.sourceScenes == .newGuide
            || (viewModel.sourceScenes == .upgrade && passportService.isOversea)
    }()
    private lazy var showSkipNavItem: Bool = {
        return viewModel.sourceScenes == .newGuide
            || viewModel.sourceScenes == .upgrade
    }()

    init(viewModel: MemberInviteLarkSplitViewModel, resolver: UserResolver) throws {
        self.viewModel = viewModel
        self.userResolver = resolver
        self.passportService = try resolver.resolve(assert: PassportService.self)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = BundleI18n.LarkContact.Lark_Invitation_InviteTeamMembers_TitleBar
        view.backgroundColor = UIColor.ud.bgBase
        isPresented = !hasBackPage && presentingViewController != nil
        layoutPageSubviews()
        // override traitCollection observe
        RootTraitCollection.observer
            .observeRootTraitCollectionDidChange(for: view)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [unowned self] _ in
                self.setSpecialNavBarIfOnOnboardingProcess()
            }).disposed(by: disposeBag)
        Tracer.trackAddMemberChannelShow(source: viewModel.sourceScenes)
        retryLoadingView.retryAction = { [unowned self] in
            self.loadHeaderCover()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        loadHeaderCover()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setSpecialNavBarIfOnOnboardingProcess()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage.ud.fromPureColor(UIColor.ud.bgBase), for: .default)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        pushGroupNameSettingPageIfSimpleB()
    }

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = UIColor.ud.bgBase
        tableView.bounces = true
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = UIColor.ud.lineDividerDefault
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        tableView.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 0, right: 0)
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        tableView.lu.register(cellSelf: SplitChannelCell.self)
        if !Display.pad {
            tableView.setTableHeaderView(headerView: headerView)
            tableView.sendSubviewToBack(headerView)
        }
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 58
        return tableView
    }()

    private lazy var headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private lazy var illustrationView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = UIColor.ud.bgBase
        view.contentMode = .scaleAspectFit
        return view
    }()

    private lazy var guideLabel: InsetsLabel = {
        let label = InsetsLabel(frame: .zero, insets: .zero)
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .center
        label.numberOfLines = 0
        let htmlStr = BundleI18n.LarkContact.Lark_Invitation_AddMembersIntro(viewModel.tenantName)
            .replacingOccurrences(of: "&lt;b&gt;", with: "<b>", options: .regularExpression)
            .replacingOccurrences(of: "&lt;/b&gt;", with: "</b>", options: .regularExpression)
        label.setHtml(
            htmlStr,
            forceLineSpacing: 6
        )
        return label
    }()

    private lazy var bottomView: NoDirectionalBottomView = {
        let view = NoDirectionalBottomView { [weak self] (entrance) in
            switch entrance {
            case .qrcode:
                self?.routeToNonDirectedInvite(.qrCode)
            case .teamCode:
                self?.routeToTeamCodeInvite()
            }
        }
        return view
    }()

    @objc
    func skipStep() {
        Tracer.trackAddMemberSkip(source: viewModel.sourceScenes)
        if let handler = rightButtonClickHandler {
            handler()
        } else {
            if isPresented {
                dismiss(animated: true)
            } else {
                navigationController?.popViewController(animated: true)
            }
        }
    }

    // MARK: - UITableViewDataSource, UITableViewDelegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.channelContexts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: SplitChannelCell.lu.reuseIdentifier) as? SplitChannelCell {
            cell.bindModel(viewModel.channelContexts[indexPath.row])
            return cell
        }
        return UITableViewCell()
    }

    // swiftlint:disable did_select_row_protection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let channelContext = viewModel.channelContexts[indexPath.row]
        switch channelContext.channelFlag {
        case .directed: routeToDirectedInvite()
        case .nonDirectedLink: routeToNonDirectedInvite(.inviteLink)
        case .larkInvite: routeToLarkInvite()
        case .addressbookImport: routeToAddressBookImport()
        case .unknown: break
        default: break
        }
    }
    // swiftlint:enable did_select_row_protection

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}

private extension MemberInviteLarkSplitViewController {
    func setSpecialNavBarIfOnOnboardingProcess() {
        if needDisablePopSource {
            // clear left back button
            navigationItem.setHidesBackButton(true, animated: false)
            navigationItem.leftBarButtonItem = nil
        }
        if showSkipNavItem {
            // add right skip button
            let skipItem = LKBarButtonItem(image: nil, title: rightButtonTitle ?? BundleI18n.LarkContact.Lark_Guide_VideoSkip)
            skipItem.button.setTitleColor(UIColor.ud.N900, for: .normal)
            skipItem.button.addTarget(self, action: #selector(skipStep), for: .touchUpInside)
            navigationItem.rightBarButtonItem = skipItem
        }
    }

    func pushGroupNameSettingPageIfSimpleB() {
        if viewModel.currentTenantIsSimpleB {
            MemberInviteLarkSplitViewController.logger.info("current tenant is simple B")
            Tracer.trackGuideUpdateDialogShow()
            let alertController = LarkAlertController()
            alertController.setTitle(text: BundleI18n.LarkContact.Lark_Guide_UpgradeTeamDialogTitle)
            alertController.setContent(text: BundleI18n.LarkContact.Lark_Guide_UpgradeTeamDialogContent())
            alertController.addCancelButton(dismissCompletion: { [weak self] in
                guard let `self` = self else { return }
                Tracer.trackGuideUpdateDialogSkip()
                if self.isPresented {
                    self.dismiss(animated: true, completion: nil)
                } else {
                    self.navigationController?.popViewController(animated: true)
                }
            })
            alertController.addPrimaryButton(text: BundleI18n.LarkContact.Lark_Guide_UpgradeTeamYes, dismissCompletion: {
                Tracer.trackGuideUpdateDialogClick()
                self.viewModel.router.pushToGroupNameSettingController(baseVc: self) { [weak self] (isSuccess) in
                    guard let `self` = self else { return }
                    if isSuccess {
                        self.navigationController?.popViewController(animated: true)
                    } else {
                        if self.isPresented {
                            self.dismiss(animated: true, completion: nil)
                        } else {
                            self.popSelf(dismissPresented: false)
                        }
                    }
                }
            })
            present(alertController, animated: true)
        } else {
            MemberInviteLarkSplitViewController.logger.info("current tenant is not simple B")
        }
    }

    func loadHeaderCover() {
        guard !Display.pad else {
            return
        }
        loadingPlaceholderView.isHidden = false
        guard let headerCoverURL = viewModel.headerCoverURL else {
            self.loadingPlaceholderView.isHidden = true
            return
        }
        illustrationView.bt.setLarkImage(with: .default(key: headerCoverURL),
                                         completion: { [weak self] result in
                                            guard let `self` = self else { return }
                                            if let image = try? result.get().image {
                                                let size = image.size
                                                let scale = size.width / size.height
                                                let imageWidth = self.view.frame.width
                                                self.illustrationView.snp.remakeConstraints({ (make) in
                                                    make.top.equalToSuperview()
                                                    make.centerX.equalToSuperview()
                                                    make.width.equalTo(imageWidth)
                                                    make.height.equalTo(imageWidth / scale)
                                                })
                                                self.loadingPlaceholderView.isHidden = true
                                                self.tableView.reloadData()
                                                self.tableView.setNeedsLayout()
                                                self.tableView.layoutIfNeeded()
                                            } else {
                                                self.loadingPlaceholderView.isHidden = true
                                                self.retryLoadingView.isHidden = false
                                            }
                                         })
    }

    func layoutPageSubviews() {
        tableView.contentInsetAdjustmentBehavior = .never
        view.addSubview(tableView)
        headerView.addSubview(illustrationView)
        headerView.addSubview(guideLabel)
        view.addSubview(bottomView)
        tableView.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(bottomView.snp.top)
        }
        if !Display.pad {
            tableView.tableHeaderView?.snp.makeConstraints { (make) in
                make.width.equalToSuperview()
                make.top.equalToSuperview()
            }
            illustrationView.snp.makeConstraints { (make) in
                make.leading.top.trailing.equalToSuperview()
            }
            guideLabel.snp.makeConstraints { (make) in
                make.top.equalTo(illustrationView.snp.bottom).offset(-24)
                make.leading.trailing.equalToSuperview().inset(44)
                make.bottom.equalToSuperview().offset(-24)
            }
        }
        bottomView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(Display.iPhoneXSeries ? 30 : 0)
            make.height.equalTo(120)
        }
    }
}

private extension MemberInviteLarkSplitViewController {
    func routeToDirectedInvite() {
        if viewModel.hasEmailInvitation && viewModel.hasPhoneInvitation {
            Tracer.trackAddMemberAddByPhoneOrEmailClick(source: viewModel.sourceScenes)
        } else if viewModel.hasEmailInvitation {
            Tracer.trackAddMemberAddByEmailClick(source: viewModel.sourceScenes)
        } else if viewModel.hasPhoneInvitation {
            Tracer.trackAddMemberAddByPhoneClick(source: viewModel.sourceScenes)
        }

        viewModel.router.pushToDirectedInviteController(
            baseVc: self,
            sourceScenes: viewModel.sourceScenes,
            departments: viewModel.departments) { [weak self] in
                self?.popSelf(animated: true, dismissPresented: false, completion: {
                    if let handler = self?.rightButtonClickHandler {
                        self?.navigationController?.popViewController(animated: true)
                        handler()
                    } else {
                        self?.popSelf(dismissPresented: false)
                    }
                })
        }
    }

    func routeToNonDirectedInvite(_ displayPriority: MemberNoDirectionalDisplayPriority) {
        switch displayPriority {
        case .qrCode:
            Tracer.trackAddMemberQrcodeInviteClick(source: viewModel.sourceScenes)
        case .inviteLink:
            Tracer.trackAddMemberLinkInviteClick(source: viewModel.sourceScenes)
        }
        viewModel.router.pushToNonDirectedInviteController(baseVc: self,
                                                           priority: displayPriority,
                                                           sourceScenes: viewModel.sourceScenes,
                                                           departments: viewModel.departments)
    }

    func routeToLarkInvite() {
        viewModel.forwordInviteLinkInLark(from: self) { [weak self] in
            if let handler = self?.rightButtonClickHandler {
                self?.navigationController?.popViewController(animated: true)
                handler()
            } else {
                self?.popSelf(dismissPresented: false)
            }
        }
    }

    func routeToAddressBookImport() {
        Tracer.trackAddMemberContactBatchInviteClick(scenes: .addMemberChannel)
        viewModel.router.pushToAddressBookImportController(baseVc: self,
                                                           sourceScenes: viewModel.sourceScenes,
                                                           presenter: viewModel.batchInvitePresenter)
    }

    func routeToTeamCodeInvite() {
        Tracer.trackAddMemberViewTeamCodeClick(source: viewModel.sourceScenes)
        viewModel.router.pushToTeamCodeInviteController(baseVc: self,
                                                        sourceScenes: viewModel.sourceScenes,
                                                        departments: viewModel.departments)
    }
}
