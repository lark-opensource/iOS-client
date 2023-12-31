//
//  AIAnimatedAvatarView.swift
//  LarkAI
//
//  Created by Hayden on 2023/5/28.
//

import UIKit
import Lottie
import FigmaKit
import ByteWebImage
import UniverseDesignColor

class AIAnimatedAvatarView: UIView {

    var avatarInfo: AvatarInfo? {
        didSet {

        }
    }

    /// 外面的光圈边框
    lazy var haloView: LOTAnimationView = {
        let path = BundleConfig.LarkAIBundle.path(forResource: "onboarding", ofType: "json")
        let view = LOTAnimationView(filePath: path ?? "")
        return view
    }()

    /// 深色模式下头像背后的渐变阴影
    lazy var gradientBackground: FKGradientView = {
        let view = FKGradientView()
        view.direction = .topToBottom
        view.colors = [
            // swiftlint:disable init_color_with_token
            UIColor.clear & UIColor(red: 71 / 255, green: 82 / 255, blue: 230 / 255, alpha: 0.0),
            UIColor.clear & UIColor(red: 71 / 255, green: 82 / 255, blue: 230 / 255, alpha: 0.2),
            UIColor.clear & UIColor(red: 208 / 255, green: 95 / 255, blue: 208 / 255, alpha: 0.5)
            // swiftlint:enable init_color_with_token
        ]
        view.locations = [0.25, 0.75, 1]
        return view
    }()

    lazy var avatarView: UIImageView = {
        let view = ByteImageView()
        return view
    }()

    private let avatarViewRatio: CGFloat = 0.79 //头像的宽/高 占整个view的比例

    var avatarImage: UIImage? {
        return avatarView.image
    }

    init(avatarInfo: AvatarInfo?, isDynamic: Bool, placeholder: UIImage? = nil) {
        self.avatarInfo = avatarInfo
        super.init(frame: .zero)
        addSubview(gradientBackground)
        addSubview(avatarView)
        addSubview(haloView)
        setData(avatarInfo: avatarInfo, isDynamic: isDynamic, placeholder: placeholder)
        gradientBackground.snp.makeConstraints { make in
            make.edges.equalTo(avatarView)
        }
        avatarView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(haloView).multipliedBy(avatarViewRatio)
            make.height.equalTo(haloView).multipliedBy(avatarViewRatio)
        }
        haloView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func setData(avatarInfo: AvatarInfo?, isDynamic: Bool, placeholder: UIImage? = nil) {
        if let avatarInfo = avatarInfo, avatarInfo != .default {
            // 使用虚拟人物 AI 头像
            setToPortraitAvatarHalo()
            // NOTE: 加载动态图的时候传的是一个完整 http URL 而不是一个 key，需要注意一下
            let avatarKey = isDynamic ? avatarInfo.dynamicImageKey : avatarInfo.dynamicImagePlaceholderKey
            avatarView.isHidden = false
            gradientBackground.isHidden = false
            avatarView.bt.cancelImageRequest()
            avatarView.bt.setLarkImage(.default(key: avatarKey), placeholder: placeholder)
        } else {
            // 使用默认 AI 头像
            setToDefaultAvatarHalo()
            avatarView.isHidden = true
            gradientBackground.isHidden = true
            avatarView.bt.cancelImageRequest()
            avatarView.image = nil
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let avatarCornerRadius = avatarView.bounds.width / 2
        avatarView.clipsToBounds = true
        avatarView.layer.cornerRadius = avatarCornerRadius
        gradientBackground.clipsToBounds = true
        gradientBackground.layer.cornerRadius = avatarCornerRadius
    }

    // MARK: Animation

    /// 一个完整的 Lottie 文件，要截成多个片段分不同场景使用，此处是片段的开始、结束帧，共 355 帧
    /// https://app.lottiefiles.com/animation/1c88a4b2-0072-4039-90d0-21ffa4057960
    enum LottieTiming {
        static var startOfIntro: NSNumber { 0 }
        static var endOfIntro: NSNumber { 145 }
        static var startOfConversion: NSNumber { 146 }
        static var endOfConversion: NSNumber { 175 }
        static var startOfPortraitAvatar: NSNumber { 176 }
        static var endOfPortraitAvatar: NSNumber { 250 }
        static var startOfDefaultAvatar: NSNumber { 251 }
        static var endOfDefaultAvatar: NSNumber { 355 }
    }

    func stopAnimation() {
        haloView.stop()
    }

    /// 播放 MyAI 默认头像的初始化的动画
    func playIntroDefault(completion: ((Bool) -> Void)? = nil) {
        haloView.play(fromFrame: LottieTiming.startOfIntro,
                      toFrame: LottieTiming.endOfIntro,
                      withCompletion: completion)
    }

    /// 播放默认头像边框转换为人物头像边框的动画
    func playConvert(completion: ((Bool) -> Void)? = nil) {
        haloView.play(fromFrame: LottieTiming.startOfConversion,
                      toFrame: LottieTiming.endOfConversion,
                      withCompletion: completion)
    }

    /// 播放默认头像边框动画
    func playFinishDefault(completion: ((Bool) -> Void)? = nil) {
        haloView.play(fromFrame: LottieTiming.startOfDefaultAvatar,
                      toFrame: LottieTiming.endOfDefaultAvatar,
                      withCompletion: completion)
    }

    /// 播放人物头像边框动画
    func playFinishAvatar(completion: ((Bool) -> Void)? = nil) {
        haloView.play(fromFrame: LottieTiming.startOfPortraitAvatar,
                      toFrame: LottieTiming.endOfPortraitAvatar,
                      withCompletion: completion)
    }

    /// 将边框设置为默认头像状态
    func setToDefaultAvatarHalo() {
        haloView.setProgressWithFrame(LottieTiming.startOfDefaultAvatar)
    }

    /// 将边框设置为人物头像状态
    func setToPortraitAvatarHalo() {
        haloView.setProgressWithFrame(LottieTiming.startOfPortraitAvatar)
    }
}
