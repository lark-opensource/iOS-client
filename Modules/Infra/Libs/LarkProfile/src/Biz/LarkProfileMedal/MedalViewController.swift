//
//  MedalViewController.swift
//  LarkProfile
//
//  Created by 姚启灏 on 2021/9/2.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import ByteWebImage
import EENavigator
import FigmaKit
import LarkBizAvatar
import UniverseDesignToast
import LarkContainer

public final class MedalViewController: BaseUIViewController, UserResolverWrapper {
    public var userResolver: LarkContainer.UserResolver

    private let viewModel: MedalViewModel

    private var disposeBag = DisposeBag()

    private var isViewFirstLoad: Bool = true

    private lazy var navigationBar: MedalNaviBar = {
        let bar = MedalNaviBar()
        bar.avatarView.isHidden = true
        bar.backButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)
        return bar
    }()

    private lazy var headerView: UIView = {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.ud.bgBody
        return headerView
    }()

    private lazy var naviHeight: CGFloat = {
        let barHeight = ProfileNaviBar.Cons.barHeight
        if Display.pad {
            return barHeight
        } else {
            return UIApplication.shared.statusBarFrame.height + barHeight
        }
    }()

    /// 列表容器，包含 Header，Tabs，VCs
    private lazy var segmentedView: SegmentedTableView = {
        let tableView = SegmentedTableView()
        return tableView
    }()

    private lazy var bizView: LarkMedalAvatar = {
        let bizView = LarkMedalAvatar()
        bizView.updateBorderSize(CGSize(width: 113, height: 113))
        bizView.border.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        bizView.border.isHidden = false
        bizView.border.layer.cornerRadius = 113 / 2
        bizView.layer.shadowOpacity = 0.1
        bizView.layer.shadowRadius = 8
        bizView.layer.shadowOffset = CGSize(width: 0, height: 4)
        return bizView
    }()

    private lazy var backgroundBlurView: UIView = {
        let blurView = VisualBlurView()
        blurView.blurRadius = 30
        blurView.fillColor = UIColor.ud.primaryOnPrimaryFill
        blurView.fillOpacity = 0.1
        return blurView
    }()

    /// 可拉伸背景图
    private lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = true
        imageView.image = BundleResources.LarkProfile.default_bg_image
        imageView.layer.masksToBounds = true
        imageView.clipsToBounds = true
        return imageView
    }()

    private lazy var infoContentView: UIView = {
        let infoContentView = UIView()
        infoContentView.backgroundColor = UIColor.ud.bgBody
        return infoContentView
    }()

    private lazy var medalListView = MedalCollectionViewController(resolver: self.userResolver, userID: self.viewModel.userID)

    private var currentStatusBarStyle: UIStatusBarStyle = .lightContent {
        didSet {
            guard currentStatusBarStyle != oldValue else { return }
            navigationBar.setNaviButtonStyle(currentStatusBarStyle)
            setNeedsStatusBarAppearanceUpdate()
        }
    }

    public override var preferredStatusBarStyle: UIStatusBarStyle {
        Display.pad ? .default : currentStatusBarStyle
    }

    public override var navigationBarStyle: NavigationBarStyle {
        return .none
    }

    public init(resolver: LarkContainer.UserResolver, viewModel: MedalViewModel) {
        self.viewModel = viewModel
        self.userResolver = resolver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
        setupConstraints()
        bindViewModel()
        // 隐藏原有导航栏，使用 Profile 自定义导航栏
        self.isNavigationBarHidden = true
        // 导航栏初始状态
        navigationBar.setAppearance(byProgress: 0)
        navigationBar.setNaviButtonStyle(.lightContent)
        // 导航栏名称
        navigationBar.titleLabel.text = self.viewModel.isMe ? BundleI18n.LarkProfile.Lark_Profile_MyBadges : BundleI18n.LarkProfile.Lark_Profile_BadgeWallet_PageTitle
        bizView.ud.setLayerShadowColor(UIColor.ud.rgb(0x1F2329))
    }

    private func bindViewModel() {
        self.viewModel
            .refreshObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let `self` = self else { return }

                var passThrough = ImagePassThrough()
                passThrough.key = self.viewModel.backgroundImageKey
                passThrough.fsUnit = self.viewModel.backgroundImageFsUnit

                self.backgroundImageView.bt.setLarkImage(with: .default(key: self.viewModel.backgroundImageKey),
                                                         placeholder: BundleResources.LarkProfile.default_bg_image,
                                                         passThrough: passThrough)
                self.medalListView.setMedals(self.viewModel.dataSource, isViewFirstLoad: self.isViewFirstLoad)
                self.isViewFirstLoad = false

                self.medalListView.showButton(self.viewModel.isMe)

                self.bizView.setAvatarByIdentifier(self.viewModel.userID,
                                                   avatarKey: self.viewModel.avatarKey,
                                                   medalKey: self.viewModel.medalKey,
                                                   medalFsUnit: self.viewModel.medalFsUnit,
                                                   scene: .Profile,
                                                   avatarViewParams: .init(sizeType: .size(108)),
                                                   backgroundColorWhenError: UIColor.ud.textPlaceholder)
            }).disposed(by: self.disposeBag)
    }

    private func setupSubviews() {
        self.view.addSubview(segmentedView)
        self.view.addSubview(navigationBar)
        self.view.backgroundColor = UIColor.ud.bgBody
        headerView.addSubview(backgroundImageView)
        headerView.addSubview(infoContentView)
        headerView.addSubview(bizView)
        backgroundImageView.addSubview(backgroundBlurView)
        segmentedView.setHeaderView(headerView)
        segmentedView.hoverHeight = naviHeight
        segmentedView.tabsTitleView.isHidden = true
        segmentedView.backgroundColor = UIColor.ud.bgBody
        segmentedView.delegate = self
        medalListView.delegate = self
    }

    private func setupConstraints() {
        navigationBar.snp.remakeConstraints { make in
            make.top.left.trailing.equalToSuperview()
        }
        segmentedView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        backgroundImageView.snp.remakeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(infoContentView.snp.top).offset(Cons.infoCornerRadius)
        }
        infoContentView.snp.remakeConstraints { make in
            make.height.equalTo(Cons.infoContentViewHeight)
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalToSuperview().offset(Cons.bgImageHeight - Cons.infoCornerRadius)
        }
        bizView.snp.remakeConstraints { make in
            make.centerY.equalTo(backgroundImageView.snp.bottom)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(108)
        }
        backgroundBlurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        segmentedView.updateHeaderViewFrame()
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.headerView.btd_height > self.naviHeight else {
                return
            }
            /// 添加缓冲距离，防止上划抖动
            self.segmentedView.hoverHeight = self.headerView.btd_height - Cons.scrollBufferDistanceHeight
        }
    }

    @objc
    private func dismissSelf() {

        if hasBackPage {
            navigationController?.popViewController(animated: true)
        } else if presentingViewController != nil {
            dismiss(animated: true, completion: nil)
        }
        let isMedalPutOn = self.viewModel.medalKey.isEmpty ? "false" : "true"
        LarkProfileTracker.trackerAvatarMedalWallClick("back",
                                                       extra: ["target": "profile_main_view",
                                                               "is_medal_put_on": isMedalPutOn,
                                                               "to_user_id": self.viewModel.userID])
    }

}

extension MedalViewController: SegmentedTableViewDelegate {
    public func numberOfTabs(in segmentedView: SegmentedTableView) -> Int {
        1
    }

    public func titleOfTabs(in segmentedView: SegmentedTableView) -> [String] {
        []
    }

    public func identifierOfTabs(in segmentedView: SegmentedTableView) -> [String] {
        []
    }

    public func segmentedView(_ segmentedView: SegmentedTableView, contentableForIndex: Int) -> SegmentedTableViewContentable {
        return medalListView
    }

    /// SegmentedView 滚动代理
    public func segmentedViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        // Header Image 吸顶效果
        backgroundImageView.snp.updateConstraints { update in
            update.top.equalToSuperview().offset(min(0, offsetY))
        }
        // 根据下滑进度改变导航栏样式
        let minThreshold = bizView.frame.minY - naviHeight
        let maxThreshold = bizView.frame.maxY - naviHeight
        var progress = (offsetY - minThreshold) / (maxThreshold - minThreshold)
        progress = min(max(0, progress), 1)
        currentStatusBarStyle = progress < 0.5 ? .lightContent : .default
        navigationBar.setAppearance(byProgress: progress)
    }
}

extension MedalViewController: MedalCollectionViewDelegate {
    public func changeMedalStatusBy(_ medal: LarkMedalItem) {
        switch medal.status {
        case .invalid:
            break
        case .taking:
            self.viewModel.setMedalBy(medal: medal)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { _ in
                    UDToast.showSuccess(with: BundleI18n.LarkProfile.Lark_Profile_TakenOffBadge, on: self.view)
                }).disposed(by: self.disposeBag)
            LarkProfileTracker.trackerAvatarMedalWallClick("medal_put_off",
                                                           extra: ["target": "none",
                                                                   "medal_id": medal.medalShowImage.key,
                                                                   "to_user_id": self.viewModel.userID])
        case .valid:
            let vc = MedalAnimationViewController(resolver: self.userResolver,
                                                  userID: self.viewModel.userID,
                                                  avatarKey: self.viewModel.avatarKey,
                                                  medal: medal) { [weak self] in
                self?.viewModel.getUserMedalInfo()
            }
            self.userResolver.navigator.present(vc, from: self)
            LarkProfileTracker.trackerAvatarMedalWallClick("medal_put_on",
                                                           extra: ["target": "profile_avatar_medal_put_on_confirm_view",
                                                                   "medal_id": medal.medalShowImage.key,
                                                                   "to_user_id": self.viewModel.userID])
        @unknown default:
            break
        }
    }

    public func showDetailMedalBy(_ medal: LarkMedalItem) {
        let vc = MedalDetailViewController(resolver: userResolver, userID: self.viewModel.userID, medal: medal)
        self.userResolver.navigator.push(vc, from: self)
        LarkProfileTracker.trackerAvatarMedalWallClick("medal_icon",
                                                       extra: ["target": "profile_avatar_medal_detail_view",
                                                               "medal_id": medal.medalShowImage.key,
                                                               "to_user_id": self.viewModel.userID])
    }
}

extension MedalViewController {

    enum Cons {
        static var infoCornerRadius: CGFloat { 0 }
        static var bgAspectRatio: CGFloat { 1.875 }
        static var iPadViewSize: CGSize { CGSize(width: 420, height: 650) }
        static var bgImageHeight: CGFloat {
            if Display.pad {
                return ceil(iPadViewSize.width / bgAspectRatio)
            } else {
                return ceil(UIScreen.main.bounds.width / bgAspectRatio)
            }
        }
        static var infoContentViewHeight: CGFloat { 58 }
        static var scrollBufferDistanceHeight: CGFloat { 10 }
    }
}
