//
//  MailProfileViewController.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/12/27.
//

import Foundation
import RxSwift
import RichLabel
import LarkUIKit
import UniverseDesignIcon
import EENavigator
import LarkFocus
import Homeric
import LKCommonsTracker
import LarkSDKInterface
import UIKit
import UniverseDesignActionPanel
import LarkAlertController
import LarkActionSheet
import UniverseDesignToast
import LarkButton
import LarkContainer

protocol ProfileData { }

enum ProfileStatus {
    case error
    case empty
    case normal
    case noPermission
}

final class MailProfileViewController: BaseUIViewController, UserResolverWrapper {

    var userResolver: LarkContainer.UserResolver
    // MARK: UI Components
    var profileView: MailProfileView {
        if let profileView = view as? MailProfileView {
            return profileView
        } else {
            let profileView = MailProfileView(frame: CGRect.zero, resolver: userResolver)
            view = profileView
            return profileView
        }
    }

    lazy var naviHeight: CGFloat = {
        let barHeight = MailProfileNaviBar.Cons.barHeight
        if Display.pad {
            return barHeight
        } else {
            return UIApplication.shared.statusBarFrame.height + barHeight
        }
    }()

    /// 添加名片夹联系人按钮
    private lazy var namecardAddButton: LarkButton.TypeButton = {
        let applyButton = LarkButton.TypeButton(style: .largeA)
        applyButton.addTarget(self, action: #selector(addNamecardTap), for: .touchUpInside)
        applyButton.setTitle(BundleI18n.LarkContact.Lark_Contacts_AddToContactCardsButton, for: .normal)
        applyButton.layer.cornerRadius = 6.0
        return applyButton
    }()

    override var navigationBarStyle: NavigationBarStyle {
        return .none
    }

    let profileUIBuilder = MailProfileUIBuilder()

    private var viewModel: MailProfileViewModel

    private let disposeBag = DisposeBag()

    private var isNaviBarHidden: Bool = true

    private var currentStatusBarStyle: UIStatusBarStyle = .lightContent {
        didSet {
            guard currentStatusBarStyle != oldValue else { return }
            profileView.navigationBar.setNaviButtonStyle(currentStatusBarStyle)
            setNeedsStatusBarAppearanceUpdate()
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        Display.pad ? .default : currentStatusBarStyle
    }

    override func loadView() {
        view = MailProfileView(frame: CGRect.zero, resolver: userResolver)
    }

    init(viewModel: MailProfileViewModel, resolver: UserResolver) {
        self.viewModel = viewModel
        self.userResolver = resolver
        super.init(nibName: nil, bundle: nil)

        // 隐藏原有导航栏，使用 Profile 自定义导航栏
        self.isNavigationBarHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        debugPrint("ProfileController deinit")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        profileView.detailInfoView.targetViewController = self
        profileView.innerTableView.delegate = self
        profileView.innerTableView.hoverHeight = naviHeight
        profileView.innerTableView.setHeaderView(profileView.headerView)
        profileView.navigationBar.backButton.addTarget(self, action: #selector(close), for: .touchUpInside)

        if Display.pad {
            self.preferredContentSize = MailProfileView.Cons.iPadViewSize
            self.modalPresentationControl.dismissEnable = true
        }

        // 导航栏初始状态
        profileView.navigationBar.setAppearance(byProgress: 0)
        profileView.navigationBar.setNaviButtonStyle(.lightContent)

        // 添加联系人按钮
        view.addSubview(self.namecardAddButton)
        var bottom: Float
        if Display.iPhoneXSeries {
            bottom = 16 + 26
        } else {
            bottom = 16
        }
        self.namecardAddButton.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-bottom)
            make.height.equalTo(48)
        }
        self.namecardAddButton.isHidden = true

        bindViewModel()

        viewModel.loadProfileInfo()
        viewModel.fetchAccountTypeAndTrack()
    }

    // MARK: binding
    func bindViewModel() {
        viewModel.state.drive(onNext: { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .loading:
                // TODO
                break
            case .infoData(userProfile: let value):
                self.loadContent(userProfile: value)
                break
            case .error:
                self.profileView.setInfoStatus(.error(reload: { [weak self] in
                    self?.viewModel.loadProfileInfo()
                }))
                break
            }
        }).disposed(by: disposeBag)
    }

    // MARK: action handler

    @objc
    private func close() {
        dismissSelf()
    }

    @objc
    private func handleMoreActionDidClick(sender: UIView) {
        namecardNavigationBarRightItemTapped(sender)
    }

    @objc
    private func addNamecardTap() {
        /// 添加名片夹联系人
        let namecardEditBody = NameCardEditBody(email: self.viewModel.displayEmail, name: self.viewModel.userName, source: "profile",
                                                accountID: self.viewModel.accountID, callback: self.viewModel.callback)
        navigator.push(body: namecardEditBody, from: self)

        MailProfileStatistics.action(.add, accountType: viewModel.accountType)
    }
}

// MARK: handler
extension MailProfileViewController {
    func namecardNavigationBarRightItemTapped(_ sender: UIView) {
        // 5.0先实现效果这样写。
        if UIDevice.current.userInterfaceIdiom == .pad {
            ipadRightItemTapped(sender)
            return
        }

        /// 名片夹下右上角点击
        let actionSheet = UDActionSheet(config: UDActionSheetUIConfig(style: .autoAlert, isShowTitle: false))
        actionSheet.addDefaultItem(text: BundleI18n.LarkContact.Lark_Contacts_Edit) { [weak self] in
            guard let self = self else { return }
            // edit action
            let namecardEditBody = NameCardEditBody(id: self.viewModel.namecardId,
                                                    email: self.viewModel.displayEmail,
                                                    source: "profile",
                                                    accountID: self.viewModel.accountID)
            self.navigator.push(body: namecardEditBody, from: self)
            MailProfileStatistics.action(.edit, accountType: self.viewModel.accountType)
        }
        actionSheet.addDestructiveItem(text: BundleI18n.LarkContact.Lark_Legacy_DeleteIt) { [weak self] in
            guard let self = self else { return }
            // delete action
            let alertController = LarkAlertController()
            alertController.setTitle(text: BundleI18n.LarkContact.Lark_Contacts_DeleteContactCardConfirmation)
            alertController.addCancelButton()
            alertController.addPrimaryButton(text: BundleI18n.LarkContact.Lark_Contacts_Delete, dismissCompletion: { [weak self] in
                guard let self = self else { return }
                self.viewModel.removeNameCard()
                if let window = self.view.window {
                    UDToast.showTips(with: BundleI18n.LarkContact.Lark_Contacts_DeletedToast, on: window)
                }
                MailProfileStatistics.action(.delete, accountType: self.viewModel.accountType)
                self.dismissSelf()
            })
            self.navigator.present(alertController, from: self)
        }
        actionSheet.setCancelItem(text: BundleI18n.LarkContact.Lark_Legacy_Cancel)
        navigator.present(actionSheet, from: self)
    }

    func ipadRightItemTapped(_ sender: UIView) {
        /// 名片夹下右上角点击
        let actionSheetAdapter = ActionSheetAdapter()
        let actionSheet = actionSheetAdapter.create(level: .normal(source: sender.defaultSource))
        actionSheetAdapter.addItem(title: BundleI18n.LarkContact.Lark_Contacts_Edit) { [weak self] in
            guard let self = self else { return }
            // edit action
            let namecardEditBody = NameCardEditBody(id: self.viewModel.namecardId,
                                                    email: self.viewModel.displayEmail,
                                                    source: "profile",
                                                    accountID: self.viewModel.accountID)
            self.navigator.push(body: namecardEditBody, from: self)
            MailProfileStatistics.action(.edit, accountType: self.viewModel.accountType)
        }
        actionSheetAdapter.addItem(title: BundleI18n.LarkContact.Lark_Contacts_Delete, textColor: UIColor.ud.functionDangerContentDefault) { [weak self] in
            guard let self = self else { return }
            // delete action
            let alertController = LarkAlertController()
            alertController.setTitle(text: BundleI18n.LarkContact.Lark_Contacts_DeleteContactCardConfirmation)
            alertController.addCancelButton()
            alertController.addPrimaryButton(text: BundleI18n.LarkContact.Lark_Contacts_Delete, dismissCompletion: { [weak self] in
                guard let self = self else { return }
                self.viewModel.removeNameCard()
                if let window = self.view.window {
                    UDToast.showTips(with: BundleI18n.LarkContact.Lark_Contacts_DeletedToast, on: window)
                }
                MailProfileStatistics.action(.delete, accountType: self.viewModel.accountType)
                self.dismissSelf()
            })
            self.navigator.present(alertController, from: self)
        }
        actionSheetAdapter.addCancelItem(title: BundleI18n.LarkContact.Lark_Legacy_Cancel)
        navigator.present(actionSheet, from: self)
    }
}

// MARK: namecard -> UI
extension MailProfileViewController {
    private func loadContent(userProfile: NameCardUserProfile) {
        profileUIBuilder.defaultName = viewModel.userName

        let friend = userProfile.userInfo.friendStatus ?? .forward
        if friend == .none {
            self.namecardAddButton.isHidden = false
            profileView.setBarButtons([])
        } else {
            self.namecardAddButton.isHidden = true
            // NaviBar 右侧按钮（转发、更多）
            if let more = profileUIBuilder.getNavigationButton() {
                more.addTarget(self, action: #selector(handleMoreActionDidClick(sender: )), for: .touchUpInside)
                profileView.setBarButtons([more])
            }
        }

        profileUIBuilder.userProfile = userProfile
        profileUIBuilder.email = viewModel.displayEmail
        profileUIBuilder.accountType = viewModel.accountType

        profileUIBuilder.getAvtarView { [weak self] avatarView in
            self?.profileView.setAvatarView(avatarView)
        }

        profileView.setUserInfo(profileUIBuilder.getUserInfo())
        profileView.setNavigationBarAvatarView(profileUIBuilder.getNavigationBarAvatarView())
        let details = profileUIBuilder.getDetailInfos()
        profileView.setDetailInfo(datas: details)
        if !details.isEmpty || profileUIBuilder.getUserInfo().companyView != nil {
            profileView.setInfoStatus(.normal)
        } else {
            profileView.setInfoStatus(.empty)
        }
        profileView.setBackgroundImageView(profileUIBuilder.getBackgroundView())

        profileView.navigationBar.setNaviButtonStyle(currentStatusBarStyle)

        profileView.setupConstraints()

        profileView.innerTableView.updateHeaderViewFrame()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.profileView.innerTableView.updateHeaderViewFrame()
        }
    }
}

extension MailProfileViewController: MailProfileTableViewDelegate {
    /// SegmentedView 滚动代理
    public func profileTableViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        // Header Image 吸顶效果
        profileView.backgroundImageView.snp.updateConstraints { update in
            update.top.equalToSuperview().offset(min(0, offsetY))
        }

        // 根据下滑进度改变导航栏样式
        let minThreshold = profileView.avatarWrapperView.frame.minY - naviHeight
        let maxThreshold = profileView.avatarWrapperView.frame.maxY - naviHeight
        var progress = (offsetY - minThreshold) / (maxThreshold - minThreshold)
        progress = min(max(0, progress), 1)
        currentStatusBarStyle = progress < 0.5 ? .lightContent : .default
        profileView.navigationBar.setAppearance(byProgress: progress)
    }

    func dismissSelf() {
        if hasBackPage {
            navigationController?.popViewController(animated: true)
        } else if presentingViewController != nil {
            dismiss(animated: true, completion: nil)
        }
    }
}
