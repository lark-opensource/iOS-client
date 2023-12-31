//
//  AvatarPreivewViewController.swift
//  LarkAvatar
//
//  Created by 姚启灏 on 2020/3/5.
//

import UIKit
import Foundation
import LarkUIKit
import LarkAssetsBrowser
import LKCommonsLogging
import EENavigator
import RxSwift
import ByteWebImage
import AppReciableSDK
import LarkRustClient
import ServerPB
import LarkContainer
import LarkLocalizations
import LarkAlertController

public typealias UploadImageViewControllerProvider = (@escaping UploadImageViewController.FinishCallback) -> UploadImageViewController

extension AvatarPreviewNavigationController: LKAssetBrowserVCProtocol {}

// 由于VC包装成NAV会覆盖VC自定义的转场动画, 因此这里需要重新设置动画
public final class AvatarPreviewNavigationController: LkNavigationController, UIViewControllerTransitioningDelegate {

    public var currentThumbnail: UIImageView? {
        return (self.topViewController as? LKAssetBrowserViewController)?.currentThumbnail
    }
    public var currentPageView: LKAssetPageView? {
        return (self.topViewController as? LKAssetBrowserViewController)?.currentPageView
    }
    public var backScrollView: UIScrollView! {
        return (self.topViewController as? LKAssetBrowserViewController)?.backScrollView
    }

    public override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        self.transitioningDelegate = self
        self.modalPresentationStyle = .custom
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.update(style: .clear)
    }

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var transition = LKAssetBrowserTransition()

    public func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return transition.present
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return transition.dismiss
    }
}

// 头像个性化设置页面
public final class AvatarPersonalizedViewController: AvatarSettingViewController {
    var getAvatarChoreButtonObservable: Observable<AvatarProcessItem?>
    var pushAvatarKey: Observable<String>
    static private let logger = Logger.log(AvatarPersonalizedViewController.self, category: "Module.LarkAvatar")
    private let disposeBag = DisposeBag()
    private let rustService: RustService

    public init(
        assets: [LKDisplayAsset],
        pageIndex: Int,
        labelText: String = "",
        getAvatarChoreButtonObservable: Observable<AvatarProcessItem?>,
        pushAvatarKey: Observable<String>,
        entityId: String,
        provider: UploadImageViewControllerProvider? = nil,
        actionHandler: LKAssetBrowserActionHandler = LKAssetBrowserActionHandler(),
        rustService: RustService,
        navigator: Navigatable
    ) {
        self.getAvatarChoreButtonObservable = getAvatarChoreButtonObservable
        self.pushAvatarKey = pushAvatarKey
        self.rustService = rustService
        super.init(
            assets: assets,
            pageIndex: pageIndex,
            labelText: labelText,
            provider: provider,
            navigator: navigator,
            actionHandler: actionHandler
        )
        self.entityId = entityId
        loadAuthorityForChangeAvatar()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        self.isNavigationBarHidden = true
        // 头像个性化按钮的监听
        getAvatarChoreButtonObservable.observeOn(MainScheduler.instance)
            .take(1)
            .subscribe(onNext: { [weak self] (item) in
                if let item = item {
                    self?.stackView.addArrangedSubview(item)
                }
            }, onError: { (error) in
                Self.logger.error("getAvatarChoreButtonObservable error: \(error)")
            }).disposed(by: self.disposeBag)
        // 头像更改的监听
        pushAvatarKey.observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (avatarKey) in
                self?.updateCurrentImageByKey(avatarKey)
            }, onError: { (error) in
                Self.logger.error("avatarPush error: \(error)")
            }).disposed(by: self.disposeBag)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }

    private func loadAuthorityForChangeAvatar() {
        var request = ServerPB_Users_PullUserUpdateFieldPermissionRequest()
        request.userUpdatePermissions = [.avatar]
        rustService.sendPassThroughAsyncRequest(request, serCommand: .pullUserUpdateFieldPermission)
            .subscribe(onNext: { [weak self] (res: ServerPB_Users_PullUserUpdateFieldPermissionResponse) in
                let info = res.userUpdatePermissionInfos.first
                self?.authorityForChangeAvatar = info?.enable ?? true
                self?.cannotChangeAvatarReason = self?.getI18NValString(info?.denyDescription)
            }, onError: { error in
                Self.logger.error("loadUpdateAvatarAuthority error: \(error)")
            }).disposed(by: disposeBag)
    }

    private func getI18NValString(_ i18Names: ServerPB_Users_I18nVal?) -> String? {
        guard let i18NVal = i18Names?.i18NVals else { return nil }
        let currentLocalizations = LanguageManager.currentLanguage.rawValue.lowercased()
        if let result = i18NVal[currentLocalizations],
            !result.isEmpty {
            return result
        } else {
            return i18Names?.defaultVal
        }
    }
}

// 头像设置页面
public class AvatarSettingViewController: AvatarPreivewViewController {
    private let logger = Logger.log(AvatarSettingViewController.self, category: "Module.LarkAvatar")

    private let navigator: Navigatable
    let labelText: String
    var entityId: String = ""
    let showTips: Bool

    /// 允许修改头像
    var authorityForChangeAvatar: Bool = true
    var cannotChangeAvatarReason: String?

    public var provider: UploadImageViewControllerProvider?

    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    lazy var avatarButtonBottomView: UIView = {
        let bottomView = UIView()
        bottomView.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        return bottomView
    }()

    lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        stack.axis = .vertical
        stack.alignment = .fill
        return stack
    }()
    
    lazy var tipsView: UIView = {
        func getIconTips() -> UIView {
            let tipsContainer = UIView()
            tipsContainer.backgroundColor = UIColor.black.withAlphaComponent(0.0)
            
            let tipIcon = UIImageView(image: Resources.reportFilled)
            let tipLabel = UILabel()
            tipLabel.text = BundleI18n.LarkAvatar.Lark_IM_Profile_CoverSafetyReminder_Title
            tipLabel.font = UIFont.systemFont(ofSize: 16)
            tipLabel.textColor = UIColor.ud.textPlaceholder
            tipLabel.textAlignment = .center
            tipLabel.lineBreakMode = .byTruncatingTail
            
            tipsContainer.addSubview(tipIcon)
            tipsContainer.addSubview(tipLabel)
            tipIcon.snp.makeConstraints { (make) in
                make.leading.equalToSuperview()
                make.width.height.equalTo(18)
                make.centerY.equalToSuperview()
            }
            tipLabel.snp.makeConstraints { (make) in
                make.leading.equalTo(tipIcon.snp.trailing).offset(8)
                make.trailing.equalToSuperview()
                make.centerY.equalToSuperview()
            }
            return tipsContainer
        }
        func  getTextTips() -> UIView {
            let tipsContainer = UIView()
            tipsContainer.backgroundColor = UIColor.black.withAlphaComponent(0.0)
            let tipLabel = UILabel()
            tipLabel.text = BundleI18n.LarkAvatar.Lark_IM_Profile_CoverSafetyReminder_Desc
            tipLabel.font = UIFont.systemFont(ofSize: 14)
            tipLabel.textColor = UIColor.ud.textPlaceholder
            tipLabel.textAlignment = .center
            tipLabel.numberOfLines = 0
            tipLabel.lineBreakMode = .byTruncatingTail
            tipsContainer.addSubview(tipLabel)
            tipLabel.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            return tipsContainer
        }
        
        let containerView = UIView()
        containerView.backgroundColor = UIColor.black.withAlphaComponent(0.0)
        let iconView = getIconTips()
        let textView = getTextTips()
        containerView.addSubview(iconView)
        containerView.addSubview(textView)
        iconView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.height.equalTo(22)
            make.centerX.equalToSuperview()
        }
        textView.snp.makeConstraints { (make) in
            make.top.equalTo(iconView.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }
        return containerView
    }()

    public init(
        assets: [LKDisplayAsset],
        pageIndex: Int,
        labelText: String = "",
        provider: UploadImageViewControllerProvider? = nil,
        showTips: Bool = false,
        navigator: Navigatable,
        actionHandler: LKAssetBrowserActionHandler = LKAssetBrowserActionHandler()
    ) {
        self.labelText = labelText.isEmpty ? BundleI18n.LarkAvatar.Lark_Legacy_ChangeAvatar : labelText
        self.provider = provider
        self.showTips = showTips
        self.navigator = navigator
        super.init(
            assets: assets,
            pageIndex: pageIndex,
            actionHandler: actionHandler
        )
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(stackView)
        self.view.addSubview(avatarButtonBottomView)

        stackView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }

        avatarButtonBottomView.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.top.equalTo(stackView.snp.bottom)
            make.bottom.equalToSuperview()
        }

        let changeAvatorButton = AvatarProcessItem(labelText: labelText) { [weak self] (sender) in
            guard let strongSelf = self else { return }
            guard strongSelf.authorityForChangeAvatar else {
                guard let reason = strongSelf.cannotChangeAvatarReason else {
                    return
                }
                let alertController = LarkAlertController()
                alertController.setTitle(text: reason)
                alertController.addPrimaryButton(text: BundleI18n.LarkAvatar.Lark_Legacy_IKnow())
                strongSelf.navigator.present(alertController, from: strongSelf)
                return
            }
            if let vc = strongSelf.provider?({ [weak self] (_, _, imageResources) in
                if let image = imageResources.first?() {
                    self?.updateCurrentImage(image)
                }
            }) {
                vc.sourceView = sender
                vc.isNavigationBarHidden = true
                vc.navigationController?.setNavigationBarHidden(true, animated: false)
                self?.view.insertSubview(vc.view, at: 0)
                self?.addChild(vc)
            }
        }
        stackView.addArrangedSubview(changeAvatorButton)
        if showTips, let currentPage = currentPageView as? LKPhotoZoomingScrollView {
            backgroundView.addSubview(tipsView)
            backgroundView.sendSubviewToBack(tipsView)
            tipsView.snp.makeConstraints { (make) in
                make.leading.equalToSuperview().offset(40)
                make.trailing.equalToSuperview().offset(-40)
                make.top.equalToSuperview().offset(0.5 * (self.view.bounds.height + currentPage.imageViewContainer.btd_height) + 30).priority(.low)
                make.bottom.lessThanOrEqualTo(stackView.snp.top).priority(.high)
                make.centerX.equalToSuperview()
            }
        }
    }

    public override func onCurrentDragStatusChangeTo(_ status: LKAssetBrowserViewController.DragStaus) {
        switch status {
        case .drag, .endDragToDismiss:
            stackView.isHidden = true
        case .endDragToNormal:
            stackView.isHidden = false
        }
    }

    public override func updateCurrentImageByKey(_ key: String) {
        guard let currentPage = currentPageView as? LKPhotoZoomingScrollView else {
            return
        }
        currentPage.photoImageView.backgroundColor = UIColor.clear
        // currentPage.updateNotUseHugeImage()
        currentPage.photoImageView.bt.setLarkImage(
            with: .avatar(key: key, entityID: entityId, params: .defaultBig),
            trackStart: {
                // return TrackInfo(scene: .ImageViewer, fromType: .avatar)
                return TrackInfo(scene: .Chat, fromType: .avatar)
            },
            completion: { [weak self] result in
                switch result {
                case .success(let imageResult):
                    guard let image = imageResult.image else { return }
                    func task() {
                        currentPage.imageViewContainer.transform = .identity
                        currentPage.imageViewContainer.bounds = CGRect(origin: .zero, size: image.size)
                        currentPage.setMaxMinZoomScalesForCurrentBounds(image.size)
                    }
                    if Thread.isMainThread {
                        task()
                    } else {
                        DispatchQueue.main.async {
                            task()
                        }
                    }
                case .failure(let error):
                    currentPage.photoImageView.backgroundColor = UIColor.ud.N300
                    self?.logger.error("photoImageView setFace error: \(error)")
                }
            }
        )
    }

    /// PAD屏幕旋转更新显示
    func padTransitionUpdateDisplay() {
        guard Display.pad else { return }
        if showTips, let currentPage = currentPageView as? LKPhotoZoomingScrollView {
            tipsView.snp.updateConstraints { (make) in
                make.top.equalToSuperview().offset(0.5 * (self.view.bounds.height + currentPage.imageViewContainer.btd_height) + 30).priority(.low)
            }
            backgroundView.layoutIfNeeded()
        }
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self] (_) in
            guard let `self` = self else { return }
            self.padTransitionUpdateDisplay()
        }, completion: nil)
    }
}

// 头像预期页面
public class AvatarPreivewViewController: LKAssetBrowserViewController {
    public override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            self.overrideUserInterfaceStyle = .light
        }
    }
}

public final class AvatarProcessItem: UIButton {
    lazy var label: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()

    var action: (UIButton) -> Void

    public init(labelText: String,
         action: @escaping (UIButton) -> Void
         ) {
        self.action = action
        super.init(frame: .zero)
        self.backgroundColor = UIColor.black.withAlphaComponent(0.5)

        let wrapper = UIView()
        wrapper.isUserInteractionEnabled = false
        self.addSubview(wrapper)
        wrapper.snp.makeConstraints { (make) in
            make.top.bottom.centerX.equalToSuperview()
            make.height.equalTo(58)
        }

        label.text = labelText
        wrapper.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.centerX.centerY.equalToSuperview()
        }
        self.lu.addTopBorder(color: UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.25))
        self.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func buttonTapped(_ sender: UIButton) {
        self.action(sender)
    }
}
