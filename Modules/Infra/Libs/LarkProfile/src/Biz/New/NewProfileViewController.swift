//
//  NewProfileViewController.swift
//  LarkProfile
//
//  Created by Yuri on 2022/8/9.
////

import Foundation
import UIKit
import RxSwift
import RichLabel
import LarkUIKit
import UniverseDesignIcon
import EENavigator
import LarkFocus
import Homeric
import LKCommonsTracker
import LarkMessengerInterface
import LarkContainer
import LKCommonsLogging

public final class NewProfileViewController: ProfileViewController {
    
    private var vm: ProfileViewModel
    private let resourcesLoader = ProfileResourceLoader()
    static let logger = Logger.log(NewProfileViewController.self, category: "NewProfileViewController")
    var descriptionText: String?
    
    public override init(resolver: UserResolver, provider: ProfileDataProvider) {
        self.vm = ProfileViewModel(resolver: resolver)
        super.init(resolver: resolver, provider: provider)
        setupProfileView()
        bindProvider()
        provider.loadUserInfo()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        bindVM()
    }
    
    override func setupProfileView() {
        profileView = NewProfileView(userResolver: vm.userResolver)
    }
    
    override func setupUI() {
        view.addSubview(profileView)
        profileView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        ProfileReciableTrack.userProfileFirstRenderViewCostTrack()
        profileView.segmentedView.delegate = self
        profileView.segmentedView.hoverHeight = naviHeight
        profileView.segmentedView.setHeaderView(profileView.headerView)
        profileView.navigationBar.backButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        profileView.addContactView.tapHandler = { [weak self] relationship in
            self?.dataProvider.changeRelationship(relationship)
        }
        profileView.applyCommunicationView.tapHandler = { [weak self] communicationPermission in
            guard let self = self else { return }
            self.dataProvider.changeCommunicationPermission(communicationPermission)
        }
        profileView.segmentedView.updateTableHeaderView()

        if Display.pad {
            self.preferredContentSize = ProfileView.Cons.iPadViewSize
            self.modalPresentationControl.dismissEnable = true
            self.modalPresentationStyle = .formSheet
        }

        // 导航栏初始状态
        profileView.navigationBar.setAppearance(byProgress: 0)
        profileView.navigationBar.setNaviButtonStyle(.lightContent)
        setupView()
        
        let statusSignal = dataProvider.status
        Observable.combineLatest(statusSignal, resourcesLoader.resources)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_, resources) in
                guard let backgroundImageView = self?.profileView.backgroundImageView as? ProfileBackgroundView else { return }
                guard let provider = self?.dataProvider as? NewProfileDataProvider else { return }
                guard let userInfo = provider.userProfile?.userInfoProtocol else { return }
                let imageKey = provider.topImageKey
                let fsUnit = userInfo.topImage.fsUnit
                let imageCache = resources.1
                backgroundImageView.update(imageKey: imageKey, fsUnit: fsUnit, placeholder: imageCache[.defaultBgImage])
                backgroundImageView.updateMedal(showSwitch: userInfo.avatarMedal.showSwitch,
                                                userInfo: userInfo, isSelf: provider.isSelf,
                                                moreIcon: imageCache[.more],
                                                pushIcon: imageCache[.rightOutlined],
                                                title: resources.0[.profileMyBadges])
            })
            .disposed(by: disposeBag)

        // 添加联系人
        profileView.addContactView.state = .none
        profileView.addContactView.isBlocked = false
        dataProvider.relationship.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self, weak dataProvider] relationship in
            guard let self = self else { return }
            guard let dataProvider = dataProvider else { return }
            self.profileView.addContactView.hideAddConnectButton = dataProvider.isHideAddContactButtonOnProfile
            self.profileView.addContactView.state = relationship
            self.profileView.addContactView.isBlocked = dataProvider.isBlocked
        }).disposed(by: disposeBag)

        profileView.focusView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapFocusView(_:))))
        if dataProvider.needToPushSetInformationViewController {
            self.dataProvider.pushSetInformationViewController()
        }
        bindResources()
    }

    private func bindResources() {
        resourcesLoader.resources
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] (strings, icons) in
            let icon = icons[.leftOutlined]
            self?.profileView.navigationBar.backButton.setImage(icon, for: .normal)
        }.disposed(by: disposeBag)
    }
    
    override func loadContent() {
        // Bind data
        profileView.setUserInfo(dataProvider.getUserInfo())
        if let provider = dataProvider as? LarkProfileDataProvider {
            provider.updateAvatar()
            provider.updateNavigationBarAvatarView()
        }
        profileView.addContactView.hideAddConnectButton = dataProvider.isHideAddContactButtonOnProfile
        profileView.addContactView.isBlocked = dataProvider.isBlocked
        profileView.setBarButtons(dataProvider.getNavigationButton())
        profileView.navigationBar.setNaviButtonStyle(currentStatusBarStyle)
        
        self.reloadData()
    }
    
    func setupView() {
        Self.logger.info("device name:\(UIDevice.current.lu.modelName())")
        guard let provider = dataProvider as? LarkProfileDataProvider else { return }
        guard let profileView = profileView as? NewProfileView else { return }
        profileView.setupAvatarView(imageView: provider.generateAvatarView())
        profileView.setNavigationBarAvatarView({ provider.barAvatarView })
        
        profileView.statusView.delegate = provider
        if let backgroundImageView = profileView.backgroundImageView as? ProfileBackgroundView {
            provider.topImageView = backgroundImageView.backgroundView
        }
        
        if let backgroundView = profileView.backgroundImageView as? ProfileBackgroundView,
           let prov = self.dataProvider as? NewProfileDataProvider {
            let tapGesture = UITapGestureRecognizer(target: prov, action: #selector(LarkProfileDataProvider.backgroundViewTapped))
            backgroundView.addGestureRecognizer(tapGesture)
            backgroundView.medalView.tapCallback = { [weak self] in
                self?.dataProvider.medalViewTapped()
            }
        }
    }
    
    private func bindProvider() {
        guard let provider = dataProvider as? NewProfileDataProvider else {
            return
        }
        provider.didUpdateUserInfoHandler = { [weak self] in
            self?.vm.update(profile: $0, isMe: $1, isLocal: $2, fromPush: $3)
        }
        provider.didFetchErrorHandler = { [weak self] in
            self?.vm.updateError()
        }
    }
    
    private func bindVM() {
        // state更新两次, desc签名一般更新四次, state通过isLocalData来去重, 本地数据不重复渲染
        let state = vm.state.filter { $0 != nil }
            .distinctUntilChanged {
                return $0?.isLocalData == true && $1?.isLocalData == true
            }
        Observable.combineLatest(state, resourcesLoader.resources)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let state = $0 else { return }
                self?.reloadData(state: state, icons: $1.1)
                self?.profileView.segmentedView.updateHeaderViewFrame()
            }).disposed(by: disposeBag)
        vm.state.map { $0?.desc }.filter { $0 != nil }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.updateDescription(desc: $0)
            }).disposed(by: disposeBag)
        vm.state.filter { $0 != nil }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.profileView.segmentedView.updateHeaderViewFrame()
            }).disposed(by: disposeBag)
    }
    
    private func reloadData(state: ProfileState, icons: ProfileResourceLoader.ImageMap) {
        guard let provider = self.dataProvider as? NewProfileDataProvider,
              let profileView = self.profileView as? NewProfileView else {
            return
        }
        var status = state.status
        // MyAI 特化逻辑：PM 觉得 AI Profile 显示“暂无个人信息”像 bug，所以 AI Profile 不展示空占位图
        if provider.isAIProfile, status == .empty {
            status = .normal
        }
        self.loadContent()
        self.profileView.setInfoStatus(status) {
            self.dataProvider.reloadData()
        }
        if status == .error {
            //error页面右上角不展示任何button
            self.profileView.setBarButtons([])
        }
        profileView.setCTAButtons(provider.getCTA(with: icons))
        profileView.didPushUserDescriptionHandler = state.isMe ? { [weak self] in
            self?.pushToEditDescription()
        } : nil
    }
    
    private func updateDescription(desc: ProfileState.UserDescription?) {
        guard let profileView = profileView as? NewProfileView else {
            return
        }
        guard let descriptionText = self.descriptionText,
              descriptionText != desc?.text else {
            Self.logger.info("update description use service data")
            profileView.updateUserDescription(desc: desc)
            return
        }
        var description = desc
        dataProvider.replaceDescriptionWithInlineTrySDK(by: descriptionText) { attr, urlRange, textRange, sourceType in
            Self.logger.info("update description use local data")
            description?.text = descriptionText
            description?.attrText = attr
            description?.urlRanges = urlRange
            description?.textRanges = textRange
            profileView.updateUserDescription(desc: description)
        }
    }
    
    // MARK: - Router
    private func pushToEditDescription() {
        self.userResolver.navigator.present(body: WorkDescriptionSetBody(completion: { [weak self] descText in
            guard let `self` = self else { return }
            Self.logger.info("edit user sign description")
            self.descriptionText = descText
            self.dataProvider.reloadData()
        }), wrap: LkNavigationController.self, from: self)
        let length = vm.currentState?.desc?.length ?? 0
        
        guard let provider = dataProvider as? NewProfileDataProvider else { return }
        provider.trackPushDescription(length: length)
    }
}

