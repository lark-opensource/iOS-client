//
//  OpenRedPacketViewController.swift
//  Lark
//
//  Created by ChalrieSu on 2018/10/18.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import Homeric
import LarkUIKit
import SnapKit
import Lottie
import LarkModel
import RxSwift
import EENavigator
import LarkNavigator
import LKCommonsLogging
import LKCommonsTracker
import LarkFoundation
import LarkExtensions
import UniverseDesignToast
import LarkSDKInterface
import LarkMessengerInterface
import LarkCore
import ByteWebImage
import LarkReleaseConfig
import LarkAccountInterface
import LarkBizAvatar
import LarkContainer

let redPacketRed = UIColor.ud.functionDangerContentDefault
let redPacketYellow = UIColor.ud.Y600.alwaysLight

final class OpenRedPacketViewController: BaseUIViewController, UIViewControllerTransitioningDelegate, UserResolverWrapper {
    // data
    struct Config {
        static let descriptionLabelHeight: CGFloat = 24
        static let descriptionBackgroundViewHeight: CGFloat = 30
    }
    private static let logger = Logger.log(OpenRedPacketViewController.self, category: "open.red.packet.vc")
    var userResolver: LarkContainer.UserResolver
    var passportUserService: PassportUserService?
    private let currentChatterID: String
    private let messageID: String
    private let chatID: String?
    private let redPacketInfo: RedPacketInfo
    private let redPacketAPI: RedPacketAPI
    private let payManager: PayManagerService
    private let shadowColor = UIColor.ud.staticBlack.withAlphaComponent(0.2)
    private var lastFrame: CGRect = .null
    private var isCustomCover: Bool {
        redPacketInfo.cover?.hasID == true
    }
    private let disposeBag = DisposeBag()

    // UI
    private lazy var shadow: NSShadow = {
        let shadow = NSShadow()
        shadow.shadowBlurRadius = 4
        shadow.shadowOffset = CGSize(width: 0, height: 2)
        shadow.shadowColor = self.shadowColor
        return shadow
    }()
    let topContainerView = ByteImageView(image: Resources.hongbao_open_top)
    let bottomContainerView = UIImageView(image: Resources.hongbao_open_bottom)
    private let avatarViewSize: CGFloat
    private let avatarView: OpenRedPacketAvatarView
    private let nameLabel = UILabel()
    private let subLabel = UILabel()
    private let mainLabel = UILabel()
    // 用来显示企业名
    var descriptionLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.Y200.alwaysLight
        label.numberOfLines = 1
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()
    var descriptionBackgroundView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    private lazy var exclusiveTipView: OpenRedPacketExclusiveTipView = {
        let exclusiveTipView = OpenRedPacketExclusiveTipView()
        return exclusiveTipView
    }()
    private let openButton = UIButton()
    private let detailButton = UIButton()
    let contentView = UIView()
    var contentViews: [UIView] {
        return [avatarView, nameLabel, subLabel, mainLabel, openButton, detailButton, descriptionLabel, descriptionBackgroundView]
    }
    private let openAnimationView: LOTAnimationView = {
        let jsonPath = LarkFinanceBundle.path(forResource: "data",
                                              ofType: "json",
                                              inDirectory: "lottie/open_red_packet")
        let view = jsonPath.flatMap { LOTAnimationView(filePath: $0) } ?? LOTAnimationView()
        return view
    }()

    init(currentChatterID: String,
         messageID: String,
         chatID: String?,
         redPacketInfo: RedPacketInfo,
         redPacketAPI: RedPacketAPI,
         payManager: PayManagerService,
         userResolver: UserResolver) {
        self.currentChatterID = currentChatterID
        self.messageID = messageID
        self.chatID = chatID
        self.redPacketInfo = redPacketInfo
        self.redPacketAPI = redPacketAPI
        self.payManager = payManager
        self.userResolver = userResolver
        self.passportUserService = try? userResolver.resolve(assert: PassportUserService.self)
        if redPacketInfo.type == .exclusive {
            avatarViewSize = 74
            avatarView = OpenRedPacketAvatarView(backgroundImage: Resources.hongbao_result_avatar_border)
        } else {
            avatarViewSize = 48
            avatarView = OpenRedPacketAvatarView()
        }
        super.init(nibName: nil, bundle: nil)
        self.transitioningDelegate = self
        self.modalPresentationStyle = .overFullScreen
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.clear.withAlphaComponent(0.3)
        contentView.lu.addTapGestureRecognizer(action: #selector(backgroundDidTapped(gesture:)), target: self)
        contentView.frame = view.bounds
        view.addSubview(contentView)

        topContainerView.clipsToBounds = true
        topContainerView.layer.cornerRadius = 12

        if isCustomCover, let cover = redPacketInfo.cover {
            var passThrough = ImagePassThrough()
            passThrough.key = cover.mainCover.key
            passThrough.fsUnit = cover.mainCover.fsUnit
            topContainerView.bt.setLarkImage(with: .default(key: cover.mainCover.key ?? ""),
                                             placeholder: Resources.hongbao_open_top,
                                             passThrough: passThrough)
        } else {
            topContainerView.bt.setLarkImage(with: .default(key: ""),
                                             placeholder: Resources.hongbao_open_top)
        }

        contentView.addSubview(topContainerView)
        bottomContainerView.clipsToBounds = true
        bottomContainerView.layer.cornerRadius = 12
        contentView.addSubview(bottomContainerView)

        let avatarSize: CGFloat = 48
        /// 专属红包
        if redPacketInfo.type == .exclusive {
            avatarView.avatarView.avatarType = .user(identifier: userResolver.userID,
                                                     avatarKey: passportUserService?.user.avatarKey ?? "",
                                                     avatarViewParams: .init(sizeType: .size(avatarSize)))
            avatarView.avatarInset = 13
        /// 企业红包(b2c)
        } else if redPacketInfo.isB2C {
            setCompanyLogoForB2C()
        } else {
            if let chatter = redPacketInfo.chatter {
                avatarView.avatarView.avatarType = .user(identifier: chatter.id,
                                                         avatarKey: chatter.avatarKey,
                                                         avatarViewParams: .init(sizeType: .size(avatarSize)))
            }
        }
        if isCustomCover {
            avatarView.layer.shadowRadius = shadow.shadowBlurRadius
            avatarView.layer.shadowOffset = shadow.shadowOffset
            avatarView.layer.shadowColor = shadowColor.cgColor
        }
        contentView.addSubview(avatarView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(descriptionBackgroundView)
        contentView.addSubview(descriptionLabel)
        nameLabel.textAlignment = .center
        nameLabel.attributedText = NSAttributedString(string: getNameLabelText(),
                                                      attributes: getNameLabelAttributes())
        contentView.addSubview(mainLabel)
        mainLabel.attributedText = NSAttributedString(string: redPacketInfo.subject,
                                                      attributes: getMainLabelAttributes())
        mainLabel.numberOfLines = 2
        mainLabel.textAlignment = .center

        if redPacketInfo.type == .exclusive {
            contentView.addSubview(exclusiveTipView)
            if isCustomCover {
                exclusiveTipView.avatarView.layer.shadowRadius = shadow.shadowBlurRadius
                exclusiveTipView.avatarView.layer.shadowOffset = shadow.shadowOffset
                exclusiveTipView.avatarView.layer.shadowColor = shadowColor.cgColor
            }
        }

        contentView.addSubview(openButton)
        openButton.setImage(Resources.red_packet_open, for: .normal)
        openButton.setImage(Resources.red_packet_open_highlight, for: .highlighted)
        openButton.addTarget(self, action: #selector(openRedPacketButtonDidClick), for: .touchUpInside)

        openAnimationView.isHidden = true
        contentView.addSubview(openAnimationView)

        contentView.addSubview(detailButton)
        detailButton.setTitleColor(UIColor.ud.Y200.alwaysLight, for: .normal)
        detailButton.addTarget(self, action: #selector(detailButtonDidClick), for: .touchUpInside)
        detailButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)

        contentView.addSubview(openAnimationView)
        openAnimationView.isHidden = true

        setUpStyle()
    }

    func setUpStyle() {
        let mainText: String
        if redPacketInfo.grabAmount != nil {
            //已领取
            openButton.isHidden = true
            mainText = BundleI18n.LarkFinance.Lark_Legacy_HongbaoOpened
        } else if redPacketInfo.isExpired {
            //已过期
            openButton.isHidden = true
            mainText = BundleI18n.LarkFinance.Lark_Legacy_HongbaoExpired
        } else if redPacketInfo.isGrabbedFinish {
            //已领完
            openButton.isHidden = true
            mainText = BundleI18n.LarkFinance.Lark_Legacy_HongbaoNoneLeft
        } else if redPacketInfo.canGrab {
            //可以抢
            openButton.isHidden = false
            mainText = redPacketInfo.subject
        } else {
            mainText = ""
            assertionFailure("红包状态出错")
        }
        mainLabel.attributedText = NSAttributedString(string: mainText,
                                                      attributes: getMainLabelAttributes())
        if let displayName = redPacketInfo.hongbaoCoverDisplayName, displayName.displayName.isEmpty == false, !redPacketInfo.isB2C {
            descriptionLabel.text = displayName.displayName
            descriptionLabel.isHidden = false
            descriptionBackgroundView.isHidden = false
            var pass = ImagePassThrough()
            pass.key = displayName.backgroundImg.key
            pass.fsUnit = displayName.backgroundImg.fsUnit
            let placeholder = self.processImage(Resources.hongbao_card_background,
                                                scale: 1,
                                                bgBorderWidth: CGFloat(10))
            self.descriptionBackgroundView.bt.setLarkImage(with: .default(key: displayName.backgroundImg.key ?? ""),
                                                           placeholder: placeholder,
                                                           passThrough: pass,
                                                           options: [.disableAutoSetImage],
                                                           completion: { [weak self] result in
                guard let icon = try? result.get().image, !displayName.backgroundImg.key.isEmpty else { return }
                let scale = Self.Config.descriptionBackgroundViewHeight / icon.size.height
                let processImage = self?.processImage(icon, scale: scale, bgBorderWidth: CGFloat(displayName.bgBorderWidth) * scale) ?? icon
                self?.descriptionBackgroundView.image = processImage
            })
        } else {
            descriptionLabel.isHidden = true
            descriptionBackgroundView.isHidden = true
        }

        if redPacketInfo.type == .exclusive {
            detailButton.setTitle(BundleI18n.LarkFinance.Lark_DesignateRedPacket_ViewMoreButton + " >", for: .normal)
        } else if needShowDetailPageInfo() {
            detailButton.setTitle(BundleI18n.LarkFinance.Lark_Legacy_PreviewHongbaoViewDetails + " >", for: .normal)
        }

        if redPacketInfo.type == .exclusive, let chatter = redPacketInfo.chatter {
            exclusiveTipView.update(chatter, tipAttributes: getExclusiveTipLabelAttributes())
        }
    }

    private func needShowDetailPageInfo() -> Bool {
        return redPacketInfo.type != .p2P && redPacketInfo.type != .commercial && !redPacketInfo.isB2C
    }

    private func processImage(_ image: UIImage,
                              scale: CGFloat,
                              bgBorderWidth: CGFloat) -> UIImage? {
        // 缩放
        let scaledIcon = image.ud.scaled(by: scale)
        // 控制可拉伸范围
        let inset = UIEdgeInsets(top: 0, left: bgBorderWidth, bottom: 0, right: bgBorderWidth)
        let resizableImage = scaledIcon.resizableImage(withCapInsets: inset,
                                                       resizingMode: .stretch)
        return resizableImage
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        guard view.frame != lastFrame else { return }
        lastFrame = view.frame

        let topBgViewSize = Resources.hongbao_open_top.size
        let bottomBgViewSize = Resources.hongbao_open_bottom.size
        let bottomOverlayHeight: CGFloat = 74

        let totalHeight = topBgViewSize.height + bottomBgViewSize.height - bottomOverlayHeight
        let overHeight = view.bounds.height - totalHeight
        let verticalMarginY = overHeight / 2 - 40

        let horizontalMargin = (view.bounds.width - topBgViewSize.width) / 2

        topContainerView.frame = CGRect(x: horizontalMargin, y: verticalMarginY, width: topBgViewSize.width, height: topBgViewSize.height)

        bottomContainerView.frame = CGRect(x: horizontalMargin,
                                           y: topContainerView.frame.maxY - bottomOverlayHeight,
                                           width: bottomBgViewSize.width,
                                           height: bottomBgViewSize.height)

        let multiplier: CGFloat = 0.20
        let contentTop = topContainerView.frame.top

        avatarView.bounds = CGRect(x: 0, y: 0, width: avatarViewSize, height: avatarViewSize)
        avatarView.frame.top = contentTop + (redPacketInfo.type == .exclusive ? 50 : 64)
        avatarView.frame.centerX = topContainerView.frame.centerX

        nameLabel.sizeToFit()
        if redPacketInfo.type == .exclusive {
            nameLabel.frame.top = avatarView.frame.bottom
        } else {
            nameLabel.frame.top = avatarView.frame.bottom + 7
        }
        if nameLabel.frame.size.width > Resources.hongbao_open_top.size.width - 16 {
            nameLabel.frame.size = CGSize(width: Resources.hongbao_open_top.size.width - 16, height: nameLabel.frame.size.height)
        }
        nameLabel.frame.centerX = topContainerView.frame.centerX

        mainLabel.bounds.size = mainLabel.sizeThatFits(CGSize(width: topContainerView.bounds.width - 48,
                                                              height: CGFloat.greatestFiniteMagnitude))
        mainLabel.frame.centerX = topContainerView.frame.centerX
        mainLabel.frame.top = nameLabel.frame.bottom + (redPacketInfo.type == .exclusive ? 2 : 14)

        let descriptionLabelWidth = descriptionLabel.sizeThatFits(CGSize(width: topContainerView.bounds.width - 48, height: 24)).width
        descriptionLabel.bounds.size = CGSize(width: descriptionLabelWidth, height: Self.Config.descriptionLabelHeight)
        descriptionLabel.frame.centerX = topContainerView.frame.centerX
        descriptionBackgroundView.frame.left = descriptionLabel.frame.left - 10
        descriptionBackgroundView.frame.size = CGSize(width: descriptionLabel.frame.size.width + 20, height: Self.Config.descriptionBackgroundViewHeight)

        let descriptionBgViewVerticalPadding = (Self.Config.descriptionBackgroundViewHeight - Self.Config.descriptionLabelHeight) / 2
        if redPacketInfo.type == .exclusive {
            var tipSize: CGSize = exclusiveTipView.tipLabel.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: OpenRedPacketExclusiveTipView.contentHeight))
            /// 整体超出封面宽度特殊处理，缩略显示
            if tipSize.width + OpenRedPacketExclusiveTipView.labelMarginLeft > Resources.hongbao_open_top.size.width - 16 {
                tipSize.width = Resources.hongbao_open_top.size.width - 16 - OpenRedPacketExclusiveTipView.labelMarginLeft
            }
            exclusiveTipView.bounds.size = CGSize(width: tipSize.width + OpenRedPacketExclusiveTipView.labelMarginLeft, height: OpenRedPacketExclusiveTipView.contentHeight)
            exclusiveTipView.tipLabel.bounds.size = tipSize

            exclusiveTipView.frame.centerX = topContainerView.frame.centerX
            exclusiveTipView.frame.top = mainLabel.frame.bottom + 14
            exclusiveTipView.tipLabel.frame.origin.x = OpenRedPacketExclusiveTipView.labelMarginLeft
            exclusiveTipView.tipLabel.frame.centerY = OpenRedPacketExclusiveTipView.contentHeight / 2
            exclusiveTipView.avatarView.frame = CGRect(x: 0, y: 0, width: OpenRedPacketExclusiveTipView.avatarSize, height: OpenRedPacketExclusiveTipView.avatarSize)

            descriptionLabel.frame.top = exclusiveTipView.frame.bottom + 14
            descriptionBackgroundView.frame.top = descriptionLabel.frame.top - descriptionBgViewVerticalPadding
        } else {
            descriptionLabel.frame.top = mainLabel.frame.bottom + 14
            descriptionBackgroundView.frame.top = descriptionLabel.frame.top - descriptionBgViewVerticalPadding
        }

        let openButtonWidth = 100
        openButton.frame.size = CGSize(width: openButtonWidth, height: openButtonWidth)
        openButton.frame.centerX = topContainerView.frame.centerX
        openButton.frame.centerY = topContainerView.frame.bottom - 6

        openAnimationView.frame = openButton.frame

        detailButton.sizeToFit()
        detailButton.frame.centerX = bottomContainerView.frame.centerX
        detailButton.frame.bottom = bottomContainerView.frame.bottom - 14
    }

    @objc
    private func backgroundDidTapped(gesture: UITapGestureRecognizer) {
        let taplocation = gesture.location(in: view)
        if !topContainerView.frame.contains(taplocation), !bottomContainerView.frame.contains(taplocation) {
            dismiss(animated: Display.phone, completion: nil)
        }
    }

    @objc
    private func closeRedPacketButtonDidClick() {
        dismiss(animated: Display.phone, completion: nil)
    }

    @objc
    private func openRedPacketButtonDidClick() {
        FinanceTracker.imHongbaoReceiveClick(click: "open",
                                             target: "im_hongbao_receive_detail_view",
                                             hongbaoType: self.redPacketInfo.type,
                                             hongbaoId: self.redPacketInfo.redPacketID)
        openButton.isHidden = true
        openAnimationView.isHidden = false
        openAnimationView.loopAnimation = true
        openAnimationView.play()
        grabRedPacket()
    }

    private func getNameLabelAttributes() -> [NSAttributedString.Key: Any] {
        let nameAttributes: [NSAttributedString.Key: Any]
        if isCustomCover {
            nameAttributes = [
                .shadow: shadow,
                .font: UIFont.systemFont(ofSize: 16, weight: .medium),
                .foregroundColor: UIColor.ud.Y200.alwaysLight
            ]
        } else {
            nameAttributes = [
                .font: UIFont.systemFont(ofSize: 16, weight: .medium),
                .foregroundColor: UIColor.ud.Y200.alwaysLight
            ]
        }
        return nameAttributes
    }

    private func getMainLabelAttributes() -> [NSAttributedString.Key: Any] {
        let nameAttributes: [NSAttributedString.Key: Any]
        if isCustomCover {
            nameAttributes = [
                .shadow: shadow,
                .font: UIFont.systemFont(ofSize: 24, weight: .medium),
                .foregroundColor: UIColor.ud.Y200.alwaysLight
            ]
        } else {
            nameAttributes = [
                .font: UIFont.systemFont(ofSize: 24, weight: .medium),
                .foregroundColor: UIColor.ud.Y200.alwaysLight
            ]
        }
        return nameAttributes
    }

    private func getExclusiveTipLabelAttributes() -> [NSAttributedString.Key: Any] {
        let tipAttributes: [NSAttributedString.Key: Any]
        if isCustomCover {
            tipAttributes = [
                .shadow: shadow,
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.ud.Y200.alwaysLight
            ]
        } else {
            tipAttributes = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.ud.Y200.alwaysLight
            ]
        }
        return tipAttributes
    }

    // nolint: long_function - 后续治理
    private func grabRedPacket() {
        let chatType: String
        switch redPacketInfo.type {
        case .groupFix, .groupRandom:
            chatType = "group"
        case .p2P, .commercial:
            chatType = "single"
        case .exclusive:
            chatType = "exclusive"
        case .b2CFix:
            chatType = "company_normal"
        case .b2CRandom:
            chatType = "company_random"
        case .unknown:
            chatType = ""
        @unknown default:
            assert(false, "new value")
            chatType = ""
        }
        Tracker.post(TeaEvent(Homeric.HONGBAO_RECEIVE, params: ["chatType": chatType]))

        let observable = Observable<Void>.create { (observer) -> Disposable in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                observer.onNext(())
                observer.onCompleted()
            })
            return Disposables.create()
        }

        let redPacketAPI = self.redPacketAPI
        let redPacketID = redPacketInfo.redPacketID
        let redPacketType = self.redPacketInfo.type
        let financeSdkVersion = self.payManager.getCJSDKConfig()
        let timeStamp = CACurrentMediaTime()
        RedPacketReciableTrack.receiveRedPacketLoadTimeStart()
        let grabObservable = redPacketAPI.grabRedPacket(redPacketID: redPacketID, chatId: self.chatID, type: redPacketType, financeSdkVersion: financeSdkVersion)
            // 抢完红包以后，直接发info和detail请求，进入详情页
            .flatMap({ [weak self] (response) -> Observable<(RedPacketInfo, RedPacketReceiveInfo)> in
                let networkCost = CACurrentMediaTime() - timeStamp
                RedPacketReciableTrack.updateReceiveRedPacketEndNetworkCost(networkCost)
                RedPacketReciableTrack.receiveRedPacketLoadTimeEnd(key: RedPacketReciableTrack.getReceiveRedPacketKey())
                if response.isRealNameAuthed {
                    /// 已经认证走获取红包信息流程
                    return redPacketAPI.getRedPacketInfoAndReceiveDetail(redPacketID: redPacketID, type: redPacketType)
                } else if ReleaseConfig.isFeishu {
                    /// 没有认证走认证流程
                    DispatchQueue.main.async {
                        if let `self` = self {
                            let payManager = self.payManager
                            let topmost = WindowTopMostFrom(vc: self)
                            // 这个是由于 安卓和 iOS 视图层级不同 导致的区别，iOS 显示的 UI 层级无法支持和安卓一致
                            // 当时讨论，iOS 先关闭红包再跳转实名页面
                            self.dismiss(animated: false, completion: {
                                guard let from = topmost.fromViewController else {
                                    assertionFailure("cannot find topmostFrom befor present auth vc")
                                    return
                                }
                                let authURL = response.authURL
                                var isLynxURL = false
                                #if canImport(CJPay)
                                if let regexp = try? NSRegularExpression(pattern: FinancePayManager.lynxRegExpPattern, options: []) {
                                    let matches = regexp.matches(in: authURL, options: [], range: NSRange(location: 0, length: authURL.count))
                                    if !matches.isEmpty {
                                        isLynxURL = true
                                    }
                                }
                                #endif
                                if isLynxURL {
                                    // 如果是 lynx 页面，则使用路由跳转
                                    guard let url = URL(string: authURL) else {
                                        return
                                    }
                                    if Display.pad {
                                        self.userResolver.navigator.present(url, wrap: LkNavigationController.self, from: from, prepare: { vc in
                                            vc.modalPresentationStyle = .formSheet
                                        })
                                    } else {
                                        self.userResolver.navigator.push(url, from: from)
                                    }
                                } else {
                                    payManager.open(
                                        url: authURL, referVc: from, closeCallBack: nil)
                                }
                            })
                        }
                    }
                    return Observable<(RedPacketInfo, RedPacketReceiveInfo)>.empty()
                } else {
                    /// 未认证且是海外 Lark 版本 直接返回错误
                    let error = NSError(domain: "cjpay.authed", code: 0, userInfo: nil)
                    return Observable<(RedPacketInfo, RedPacketReceiveInfo)>.error(error)
                }
            })
            .do(onError: { (error) in
                if let error = (error as? WrappedError)?.underlyingError as? APIError {
                    RedPacketReciableTrack.receiveRedPacketLoadNetworkError(errorCode: Int(error.errorCode), errorMessage: error.errorDescription ?? "")
                } else {
                    RedPacketReciableTrack.receiveRedPacketLoadNetworkError(errorCode: 0, errorMessage: "")
                }
            })

        Observable.zip(grabObservable, observable)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (response, _) in
                let info = response.0
                let detail = response.1
                guard let self = self else { return }
                self.openAnimationView.stop()
                self.openAnimationView.isHidden = true

                let currentChatterID = self.currentChatterID
                if !detail.details.contains(where: { $0.chatter.id == currentChatterID }) {
                    OpenRedPacketViewController.logger.error("抢完红包之后，receiveDetail中不包括自己",
                                                             additionalData: ["redPacketID": redPacketID,
                                                                              "currentChatterID": currentChatterID])
                }

                //进入详情页
                let from = WindowTopMostFrom(vc: self)
                let openResult: (RedPacketResultBody, WindowTopMostFrom) -> Void = {
                    self.userResolver.navigator.present(
                        body: $0,
                        wrap: LkNavigationController.self,
                        from: $1,
                        prepare: { vc in
                            vc.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
                            vc.transitioningDelegate = self
                        }
                    )
                }
                if Display.phone {
                    // 在 iPhone 上，直接进入详情页
                    let body = RedPacketResultBody(
                        redPacketInfo: info,
                        receiveInfo: detail,
                        dismissBlock: { [weak self] (vc) in
                            self?.view.alpha = 0
                            vc.dismiss(animated: true, completion: nil)
                            self?.dismiss(animated: false, completion: nil)
                        }
                    )
                    openResult(body, from)
                } else {
                    // 在 iPad 上，先关掉自己，再打开结果页
                    let body = RedPacketResultBody(
                        redPacketInfo: info,
                        receiveInfo: detail
                    )
                    self.dismiss(animated: false, completion: {
                        openResult(body, from)
                    })
                }

                //更新点击状态
                let messageID = self.messageID
                redPacketAPI
                    .updateRedPacket(messageID: messageID,
                                     type: redPacketType,
                                     isClicked: true,
                                     isGrabbed: (info.grabAmount != nil),
                                     isGrabbedFinish: info.isGrabbedFinish,
                                     isExpired: info.isExpired)
                    .subscribe()
                    .disposed(by: self.disposeBag)
            }, onError: { [weak self] (error) in
                guard let self = self else { return }

                // 恢复点击之前的状态
                self.openAnimationView.stop()
                self.openAnimationView.isHidden = true
                self.openButton.isHidden = false

                if let error = (error as? WrappedError)?.underlyingError as? APIError {
                    switch error.type {
                    case .redPacketZeroLeft(let message):
                        // 如果红包已经被抢完，则跳转到红包抢完的UI
                        UDToast.showFailure(with: message, on: self.view, error: error)
                        self.openButton.isHidden = true
                        self.mainLabel.text = BundleI18n.LarkFinance.Lark_Legacy_DialogTakeOverTips
                        self.mainLabel.bounds.size = self.mainLabel.sizeThatFits(CGSize(width: self.topContainerView.bounds.width - 60,
                                                                                        height: CGFloat.greatestFiniteMagnitude))
                    case .redPacketGrabbedAlready(let message):
                        // 如果已经抢过该红包，则直接进入详情页
                        UDToast.showFailure(with: message, on: self.view, error: error)
                        self.dismissAndGoToRedPacketResultViewController()
                    case .redPacketOverDue(message: let message):
                        // 红包已经过期
                        UDToast.showFailure(with: message, on: self.view, error: error)
                        self.openButton.isHidden = true
                        self.mainLabel.text = BundleI18n.LarkFinance.Lark_Legacy_HongbaoExpired
                        self.mainLabel.bounds.size = self.mainLabel.sizeThatFits(CGSize(width: self.topContainerView.bounds.width - 60,
                                                                                        height: CGFloat.greatestFiniteMagnitude))
                    case .cjPayAccountNeedUpgrade(message: let message):
                        //财经账号需要升级
                        Self.logger.info("cjpay account need upgrade message:\(message)")
                        self.payManager.payUpgrade(businessScene: .receiveRedPacket)
                    default:
                        UDToast.showFailure(with: BundleI18n.LarkFinance.Lark_Legacy_UnknownError, on: self.view, error: error)
                    }
                } else {
                    UDToast.showFailure(
                        with: BundleI18n.LarkFinance.Lark_Legacy_UnknownError,
                        on: self.view,
                        error: error
                    )
                }
            })
            .disposed(by: disposeBag)
    }

    @objc
    private func detailButtonDidClick() {
        if needShowDetailPageInfo() {
            dismissAndGoToRedPacketResultViewController()
        }
    }

    /// 消失自己，并且进入红包结果页面
    private func dismissAndGoToRedPacketResultViewController() {
        guard let window = view.window else {
            assertionFailure()
            return
        }
        let hud = UDToast.showLoading(on: window, disableUserInteraction: true)
        let redPacketAPI = self.redPacketAPI
        let redPacketID = redPacketInfo.redPacketID
        let redPacketType = self.redPacketInfo.type
        let from = WindowTopMostFrom(vc: self)
        let userResolver = self.userResolver
        self.dismiss(animated: false) {
            _ = redPacketAPI.getRedPacketInfoAndReceiveDetail(redPacketID: redPacketID, type: redPacketType)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { (info, detail) in
                    let body = RedPacketResultBody(redPacketInfo: info, receiveInfo: detail)
                    userResolver.navigator.presentOrPush(body: body, wrap: LkNavigationController.self, from: from, prepareForPresent: {
                        $0.modalPresentationStyle = .formSheet
                    })
                    hud.remove()
                }, onError: { (_) in
                    hud.remove()
                })
        }
    }
    // MARK: - UIViewControllerTransitioningDelegate
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard Display.phone else { return nil } // iPad 上关闭动画
        if presented.transitionViewController is RedPacketResultViewController {
            return OpenRedPacketResultTransition()
        } else if presented.transitionViewController is OpenRedPacketViewController {
            return OpenRedPacketPresentTransition()
        }
        return nil
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard Display.phone else { return nil } // iPad 上关闭动画
        if dismissed.transitionViewController is OpenRedPacketViewController {
            return OpenRedPacketDismissTransition()
        }
        return nil
    }

    private func setCompanyLogoForB2C() {
        if let companyLogo = redPacketInfo.cover?.companyLogo {
            var passThrough = ImagePassThrough()
            passThrough.key = companyLogo.key
            passThrough.fsUnit = companyLogo.fsUnit
            avatarView.avatarView.avatarType = .company(passThrough: passThrough)
        } else {
            avatarView.isHidden = true
            Self.logger.error("companyLogo is nil")
        }
    }
    private func getNameLabelText() -> String {
        if redPacketInfo.type == .exclusive {
            return passportUserService?.user.localizedName ?? ""
        } else if redPacketInfo.type == .b2CFix || redPacketInfo.type == .b2CRandom {
            if let companyName = redPacketInfo.hongbaoCoverCompanyName, !companyName.isEmpty {
                return BundleI18n.LarkFinance.Lark_DesignateRedPacket_RedPacketSentByName_CardText(companyName)
            }
            return ""
        } else {
           return BundleI18n.LarkFinance.Lark_DesignateRedPacket_RedPacketSentByName_CardText(redPacketInfo.chatter?.localizedName ?? "")
        }
    }
}

/// 专属红包提示
final class OpenRedPacketExclusiveTipView: UIView {
    var avatarView: BizAvatar = {
        let avatarView = BizAvatar()
        return avatarView
    }()

    let tipLabel: UILabel = {
        let label = UILabel()
        label.lineBreakMode = .byTruncatingMiddle
        return label
    }()

    static let avatarSize: CGFloat = 20
    static let labelMarginLeft: CGFloat = 28
    static let contentHeight: CGFloat = 20

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(avatarView)
        addSubview(tipLabel)
    }

    func update(_ chatter: Chatter, tipAttributes: [NSAttributedString.Key: Any]) {
        tipLabel.attributedText = NSAttributedString(string: BundleI18n.LarkFinance.Lark_DesignateRedPacket_RedPacketFromSender_RPCoverText(chatter.localizedName ?? ""),
                                                     attributes: tipAttributes)
        avatarView.setAvatarByIdentifier(chatter.id,
                                         avatarKey: chatter.avatarKey,
                                         avatarViewParams: .init(sizeType: .size(Self.avatarSize)))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
