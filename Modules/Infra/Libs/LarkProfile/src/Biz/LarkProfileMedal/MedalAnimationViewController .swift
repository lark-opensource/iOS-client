//
//  MedalAnimationViewController .swift
//  LarkProfile
//
//  Created by 姚启灏 on 2021/9/7.
//

import Foundation
import LarkContainer
import ByteWebImage
import RxCocoa
import RxSwift
import LarkBizAvatar
import UIKit

class MedalAnimationViewController: UIViewController, UserResolverWrapper {
    public var userResolver: LarkContainer.UserResolver
    final class Layout {

        static var buttonEdgeInset: UIEdgeInsets {
            UIEdgeInsets(top: 7, left: 16, bottom: 7, right: 16)
        }

        static var buttonContainerSpaing: CGFloat = 14.0

        static var contentPadding: CGFloat = 74.0

        static var avatarBorderSize: CGFloat = 113
    }
    private var transitioning: MedalAnimationransitioningDelegate = MedalAnimationransitioningDelegate()

    private let medal: LarkMedalItem
    private let userID: String
    private let avatarKey: String
    private var completion: (() -> Void)?

    private var disposeBag = DisposeBag()

    @ScopedInjectedLazy var profileAPI: LarkProfileAPI?

    private lazy var alphaBgView: UIView = {
        alphaBgView = UIView()
        alphaBgView.backgroundColor = .white
        alphaBgView.alpha = 0.1
        return alphaBgView
    }()

    private lazy var bgImageView: UIImageView = {
        let bgImageView = UIImageView()
        bgImageView.contentMode = .scaleAspectFill
        bgImageView.image = BundleResources.LarkProfile.background_image
        return bgImageView
    }()

    class  CircleCGView: UIView {

         override  init (frame: CGRect ) {
             super . init(frame: frame)
             // 设置背景色为透明，否则是黑色背景
             self .backgroundColor =  UIColor .clear
         }

         required  init ?(coder aDecoder: NSCoder ) {
             fatalError( "init(coder:) has not been implemented" )
         }

         override  func  draw(_ rect: CGRect ) {
             super .draw(rect)

             // 获取绘图上下文
             guard  let  context =  UIGraphicsGetCurrentContext()  else {
                 return
             }

             // 使用rgb颜色空间
             let  colorSpace =  CGColorSpaceCreateDeviceRGB()
             // 颜色数组（这里使用三组颜色作为渐变）fc6820
             let  compoents:[ CGFloat ] = [255/255, 255/255, 255/255, 0.8,
                                           255/255, 255/255, 255/255, 0.0]
             // 没组颜色所在位置（范围0~1)
             let  locations:[ CGFloat ] = [0, 1]
             // 生成渐变色（count参数表示渐变个数）
             let  gradient =  CGGradient(colorSpace: colorSpace, colorComponents: compoents,
                                       locations: locations, count: locations.count)!

             // 渐变圆心位置（这里外圆内圆都用同一个圆心）
             let  center =  CGPoint(x: self .bounds.midX, y: self .bounds.midY)
             // 外圆半径
             let  endRadius =  min( self .bounds.width, self .bounds.height)/4
             // 内圆半径
             let  startRadius = endRadius / 5
             // 绘制渐变
             context.drawRadialGradient(gradient,
                                        startCenter: center, startRadius: startRadius,
                                        endCenter: center, endRadius: endRadius,
                                        options: .drawsBeforeStartLocation)
         }
    }
    private lazy var whiteBgImageView: CircleCGView = {
        let circleCGView = CircleCGView(frame: CGRect(x: 0, y: 0, width: 977, height: 977))
        return circleCGView
    }()

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.numberOfLines = 1
        titleLabel.textColor = UIColor.ud.staticBlack
        return titleLabel
    }()

    private lazy var subTitleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = UIColor.ud.textPlaceholder
        titleLabel.numberOfLines = 2
        return titleLabel
    }()

    private lazy var cancelButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .clear
        button.layer.borderWidth = 1
        button.ud.setLayerBorderColor(UIColor.ud.primaryContentDefault)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.layer.cornerRadius = 4
        return button
    }()

    private lazy var wearButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.ud.primaryContentDefault
        button.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.layer.cornerRadius = 4
        return button
    }()

    private lazy var buttonWrapperView: UIStackView = {
        let buttonWrapperView = UIStackView()
        buttonWrapperView.axis = .horizontal
        buttonWrapperView.spacing = Layout.buttonContainerSpaing
        buttonWrapperView.distribution = .fillEqually
        return buttonWrapperView
    }()

    private lazy var bizView: LarkMedalAvatar = {
        let bizView = LarkMedalAvatar()
        bizView.updateBorderSize(CGSize(width: Layout.avatarBorderSize, height: Layout.avatarBorderSize))
        bizView.border.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        bizView.border.isHidden = false
        bizView.border.layer.cornerRadius = Layout.avatarBorderSize / 2
        bizView.layer.shadowOpacity = 1
        bizView.layer.shadowRadius = 8
        bizView.layer.shadowOffset = CGSize(width: 0, height: 4)
        bizView.layer.ud.setShadowColor(UIColor.ud.shadowDefaultMd)
        return bizView
    }()

    public init(resolver: LarkContainer.UserResolver,
                userID: String,
                avatarKey: String,
                medal: LarkMedalItem,
                completion: (() -> Void)? = nil) {
        self.userResolver = resolver
        self.medal = medal
        self.userID = userID
        self.avatarKey = avatarKey
        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = .custom
        transitioningDelegate = transitioning

        self.completion = completion
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutSubViews()
        LarkProfileTracker.trackAvatarMedalPutOnConfirmView(medalID: self.medal.medalID)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        updateButtonsLayoutDirection(viewWidth: size.width)
    }

    private func layoutSubViews() {
        self.view.addSubview(alphaBgView)
        self.view.addSubview(bgImageView)
        self.view.addSubview(whiteBgImageView)
        self.view.addSubview(bizView)
        self.view.addSubview(titleLabel)
        self.view.addSubview(subTitleLabel)
        self.view.addSubview(buttonWrapperView)
        buttonWrapperView.addArrangedSubview(cancelButton)
        buttonWrapperView.addArrangedSubview(wearButton)

        alphaBgView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalToSuperview()
        }

        whiteBgImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(977)
        }

        bizView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(self.view.snp.centerY)
            make.width.height.equalTo(108)
        }

        bgImageView.snp.makeConstraints { make in
            make.center.equalTo(bizView.snp.center)
            make.width.height.equalTo(977)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(bizView.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(Layout.contentPadding)
            make.trailing.equalToSuperview().offset(-Layout.contentPadding)
        }

        subTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().offset(Layout.contentPadding)
            make.trailing.equalToSuperview().offset(-Layout.contentPadding)
        }

        buttonWrapperView.snp.makeConstraints { make in
            make.top.equalTo(subTitleLabel.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(Layout.contentPadding)
            make.trailing.equalToSuperview().offset(-Layout.contentPadding)
            make.bottom.lessThanOrEqualToSuperview().offset(-20)
            make.centerX.equalToSuperview()
        }

        cancelButton.snp.makeConstraints { make in
            make.height.equalTo(36)
        }

        wearButton.snp.makeConstraints { make in
            make.height.equalTo(36)
        }

        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.fromValue = 0.0
        rotateAnimation.toValue = CGFloat(CGFloat.pi)
        rotateAnimation.isRemovedOnCompletion = false
        rotateAnimation.duration = 4
        rotateAnimation.repeatCount = Float.infinity
        bgImageView.layer.add(rotateAnimation, forKey: "rotateAnimation")

        titleLabel.text = BundleI18n.LarkProfile.Lark_Profile_EffectPreview
        subTitleLabel.text = BundleI18n.LarkProfile.Lark_Profile_EffectPreviewPreview
        cancelButton.setTitle(BundleI18n.LarkProfile.Lark_Profile_Cancel, for: .normal)
        wearButton.setTitle(BundleI18n.LarkProfile.Lark_Profile_WearNow, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        wearButton.addTarget(self, action: #selector(wearTap), for: .touchUpInside)
        self.bizView.setAvatarByIdentifier(self.userID,
                                           avatarKey: self.avatarKey,
                                           medalKey: self.medal.medalShowImage.key,
                                           medalFsUnit: self.medal.medalShowImage.fsUnit,
                                           scene: .Profile,
                                           avatarViewParams: .init(sizeType: .size(108)),
                                           backgroundColorWhenError: UIColor.ud.textPlaceholder)
        updateButtonsLayoutDirection(viewWidth: view.frame.width)
    }

    @objc
    private func cancel() {
        self.dismiss(animated: true, completion: nil)
        LarkProfileTracker.trackAvatarMedalPutOnConfirmClick("cancel", extra: ["target": "profile_avatar_medal_wall_view",
                                                                               "medal_id": self.medal.medalID])
    }

    @objc
    private func wearTap() {
        self.profileAPI?.setMedalBy(userID: userID,
                                   medalID: medal.medalID,
                                   grantID: medal.grantID,
                                   isTaking: true)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in

                guard let `self` = self else { return }

                self.bizView.setAvatarByIdentifier(self.userID,
                                                   avatarKey: self.avatarKey,
                                                   medalKey: self.medal.medalShowImage.key,
                                                   medalFsUnit: self.medal.medalShowImage.fsUnit,
                                                   scene: .Profile,
                                                   avatarViewParams: .init(sizeType: .size(108)),
                                                   backgroundColorWhenError: UIColor.ud.textPlaceholder)

                self.completion?()
                self.dismiss(animated: true, completion: nil)
            }).disposed(by: self.disposeBag)
        LarkProfileTracker.trackAvatarMedalPutOnConfirmClick("confirm", extra: ["target": "profile_avatar_medal_wall_view",
                                                                                "medal_id": self.medal.medalID])
    }

    private func updateButtonsLayoutDirection(viewWidth: CGFloat) {
        let size = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        let cancelButtonTitleWidth = cancelButton.titleLabel?.sizeThatFits(size).width ?? 0
        let wearButtonTitleWidth = wearButton.titleLabel?.sizeThatFits(size).width ?? 0
        let maxWidth = (viewWidth - 2 * Layout.contentPadding - Layout.buttonContainerSpaing) / 2.0 - Layout.buttonEdgeInset.left - Layout.buttonEdgeInset.right
        if cancelButtonTitleWidth > maxWidth || wearButtonTitleWidth > maxWidth {
            buttonWrapperView.axis = .vertical
        } else {
            buttonWrapperView.axis = .horizontal
        }
    }
}
