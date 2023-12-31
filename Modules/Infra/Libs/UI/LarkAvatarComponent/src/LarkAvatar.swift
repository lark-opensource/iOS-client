//
//  LarkAvatar.swift
//  LarkAvatarComponent
//
//  Created by 姚启灏 on 2020/6/17.
//

import UIKit
import Foundation
import AvatarComponent
import ByteWebImage
import LKCommonsLogging
import RxSwift
import EEAtomic
import AppReciableSDK
import LarkSetting
import UniverseDesignColor
import UniverseDesignTheme
#if DEBUG
import UniverseDesignToast
#endif

public final class LarkAvatar: AvatarComponent {

    public static let logger = Logger.log(LarkAvatar.self, category: "LarkComponent.LarkAvatar")

    public var lastingColor: UIColor = UIColor.ud.N50
    /// 当前显示的 avatarKey
    public var lastAvatarKey: String {
        get {
            lastParams.avatarKey
        }
    }

    struct AvatarParams {
        var avatarKey: String = ""
        var entiryID: String = ""
        var params: AvatarViewParams = .defaultMiddle
        var placeholder: UIImage?
        var options: ImageRequestOptions?
        var completion: ImageRequestCompletion?
        var backgroundColorWhenError: UIColor = UIColor.ud.N300
        var scene: Scene = .Chat
    }

    // 监听到AvatarKey变更的时候，将上一次AvatarParams中的AvatarKey更新，再次设置图片
    @AtomicObject
    private var lastParams: AvatarParams = AvatarParams()
    // 上一次的Image请求。每次设置新的图片需要将上一次的ImageRequest cancel
    private var lastRequest: ImageRequest?

    private lazy var avatarConfig: AvatarImageConfig = {
        LarkImageService.shared.avatarConfig
    }()

    private var avatarSize: AvatarImageConfig.AvatarImageSize = .thumb

    private var disposeBag = DisposeBag()

    /// Set the avatarKey corresponding to the identifier
    /// The identifier will be registered in AvatarService
    /// identifier cannot be empty
    /// - Parameters:
    ///   - identifier:
    ///   - avatarKey:
    ///   - backgroundColorWhenError: backgroundColor when set image error
    ///   - completion: 当size超过阈值(98)时，会先下载middle，再下载big的image，此时completion会回调多次
    public func setAvatarKeyByIdentifier(_ identifier: String,
                                         avatarKey: String,
                                         placeholder: UIImage? = nil,
                                         options: ImageRequestOptions? = nil,
                                         avatarViewParams: AvatarViewParams,
                                         backgroundColorWhenError: UIColor = UIColor.ud.N300,
                                         completion: ImageRequestCompletion? = nil) {

        self.setAvatarKeyByIdentifier(identifier,
                                      avatarKey: avatarKey,
                                      scene: .Chat,
                                      placeholder: placeholder,
                                      options: options,
                                      avatarViewParams: avatarViewParams,
                                      backgroundColorWhenError: backgroundColorWhenError,
                                      completion: completion)
    }

    /// Set the avatarKey corresponding to the identifier
    /// The identifier will be registered in AvatarService
    /// identifier cannot be empty
    /// - Parameters:
    ///   - identifier:
    ///   - avatarKey:
    ///   - scene: TrakcScene
    ///   - backgroundColorWhenError: backgroundColor when set image error
    ///   - completion: 当size超过阈值(98)时，会先下载middle，再下载big的image，此时completion会回调多次
    public func setAvatarKeyByIdentifier(_ identifier: String,
                                         avatarKey: String,
                                         scene: Scene,
                                         placeholder: UIImage? = nil,
                                         options: ImageRequestOptions? = nil,
                                         avatarViewParams: AvatarViewParams,
                                         backgroundColorWhenError: UIColor = UIColor.ud.N300,
                                         completion: ImageRequestCompletion? = nil) {
        let oldIdentifier = self.lastParams.entiryID
        lastParams = AvatarParams(avatarKey: avatarKey,
                                  entiryID: identifier,
                                  params: avatarViewParams,
                                  placeholder: placeholder,
                                  options: options,
                                  completion: completion,
                                  backgroundColorWhenError: backgroundColorWhenError,
                                  scene: scene)
        #if DEBUG
        if identifier.isEmpty, let displayWindow = self.window {
            let config = UDToastConfig(toastType: .info,
                                       text: "entityID is empty, please check the paramters",
                                       operation: nil)
            UDToast.showToast(with: config, on: displayWindow)
        }
        #endif
        self.setAvatar(parmas: self.lastParams)

        guard !identifier.isEmpty else { return }

        let tuple = AvatarTuple(identifier: self.lastParams.entiryID, avatarKey: avatarKey)

        AvatarService.setAvatarTupleByIdentifier(self.lastParams.entiryID, tuple: tuple)

        if oldIdentifier != lastParams.entiryID {
            let observer = AvatarService.getObserverByIdentifier(identifier)
            self.observePublish(observer)
        }
    }

    public func setAvatarKeyByIdentifier(_ identifier: String,
                                         avatarKey: String,
                                         medalKey: String,
                                         scene: Scene,
                                         placeholder: UIImage? = nil,
                                         options: ImageRequestOptions? = nil,
                                         avatarViewParams: AvatarViewParams,
                                         backgroundColorWhenError: UIColor = UIColor.ud.N300,
                                         completion: ImageRequestCompletion? = nil) {
        let oldIdentifier = self.lastParams.entiryID
        #if DEBUG
        if identifier.isEmpty, let displayWindow = self.window {
            let config = UDToastConfig(toastType: .info,
                                       text: "entityID is empty, please check the paramters",
                                       operation: nil)
            UDToast.showToast(with: config, on: displayWindow)
        }
        #endif
        lastParams = AvatarParams(avatarKey: avatarKey,
                                  entiryID: identifier,
                                  params: avatarViewParams,
                                  placeholder: placeholder,
                                  options: options,
                                  completion: completion,
                                  backgroundColorWhenError: backgroundColorWhenError,
                                  scene: scene)
        self.setAvatar(parmas: self.lastParams)

        guard !identifier.isEmpty else { return }

        let tuple = AvatarTuple(identifier: identifier, avatarKey: avatarKey, medalKey: medalKey)

        AvatarService.setAvatarTupleByIdentifier(identifier, tuple: tuple)

        if oldIdentifier != lastParams.entiryID {
            let observer = AvatarService.getObserverByIdentifier(identifier)
            self.observePublish(observer)
        }
    }

    /// Update avatar
    /// - Parameter avatarKey:
    public func updateAvatarKey(_ avatarKey: String = "",
                                scene: Scene = .Chat,
                                options: ImageRequestOptions?,
                                avatarViewParams: AvatarViewParams,
                                completion: ImageRequestCompletion? = nil) {

        self.lastParams.avatarKey = avatarKey
        self.lastParams.options = options
        self.lastParams.params = avatarViewParams
        self.lastParams.completion = completion
        self.lastParams.scene = scene

        self.setAvatar(parmas: self.lastParams)

        guard !self.lastParams.entiryID.isEmpty else { return }

        let tuple = AvatarTuple(identifier: self.lastParams.entiryID, avatarKey: avatarKey)

        AvatarService.setAvatarTupleByIdentifier(self.lastParams.entiryID, tuple: tuple)
    }

    public override func draw(_ rect: CGRect) {
        lastingColor.setFill()
        UIRectFill(rect)
        super.draw(rect)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        // layout时若size超过阈值，需要检查是否升级策略
        upgradeStrategyIfNeed(size: self.frame.size)
    }

    public override var description: String {
        "\(super.description); entityID: \(lastParams.entiryID)"
    }

    /// Observe publish to update avatar
    /// - Parameter publish:
    private func observePublish(_ observer: Observable<AvatarTuple>) {
        self.disposeBag = DisposeBag()
        observer
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (tuple) in
                guard let `self` = self,
                      tuple.identifier == self.lastParams.entiryID,
                      tuple.avatarKey != self.lastParams.avatarKey else { return }
                self.lastParams.avatarKey = tuple.avatarKey
                self.setAvatar(parmas: self.lastParams)
            }, onError: { [weak self] (error) in
                guard let `self` = self else { return }
                LarkAvatar.logger.error("LarkAvatar set avatar error, avatar key: \(self.lastParams.avatarKey), identifier: \(self.lastParams.entiryID)")
            }).disposed(by: self.disposeBag)
    }
}

/// 头像缓存收敛
// https://bytedance.feishu.cn/docs/doccnJ7qlB0MRrDa3sqPdOmNCzd
extension LarkAvatar {
    private func setAvatar(parmas: AvatarParams) {
        avatarSize = avatarConfig.transform(sizeType: parmas.params.sizeType)
        switch avatarSize {
        case .thumb:
            self.bt.setLarkImage(with: parmas)
        case .middle, .big:
            preloadAvatar(avatarParams: parmas)
        }
    }

    /// mid/big的图片需要预加载：
    /// 1. 先找原尺寸图片
    /// 2. 原尺寸图片不存在，再找thumb图片，之后拉取原图
    private func preloadAvatar(avatarParams: AvatarParams) {
        guard !avatarParams.avatarKey.isEmpty else {
            self.bt.setLarkImage(with: .default(key: ""),
                                 placeholder: avatarParams.placeholder,
                                 completion: avatarParams.completion)
            return
        }
        let originKey: LarkImageResource = .avatar(key: avatarParams.avatarKey,
                                                   entityID: avatarParams.entiryID,
                                                   params: avatarParams.params)
        var thumbParams = avatarParams
        thumbParams.params.sizeType = .thumb
        let thumbKey: LarkImageResource = .avatar(key: thumbParams.avatarKey,
                                                  entityID: thumbParams.entiryID,
                                                  params: thumbParams.params)
        let originCached = LarkImageService.shared.isCached(resource: originKey)
        if originCached {
            self.bt.setLarkImage(with: avatarParams)
        } else {
            let thumbCached = LarkImageService.shared.isCached(resource: thumbKey)
            var params = avatarParams
            if thumbCached {
                thumbParams.completion = { [weak self] result in
                    // 防止回调时 Avatar 已经被重置了：检查此时 self.params 是否仍为请求的 params
                    guard let self = self,
                          self.lastParams.avatarKey == avatarParams.avatarKey,
                          self.lastParams.entiryID == avatarParams.entiryID else { return }
                    let thumbImage = try? result.get().image
                    params.placeholder = thumbImage
                    self.bt.setLarkImage(with: params)
                }
                self.bt.setLarkImage(with: thumbParams)
            } else {
                self.bt.setLarkImage(with: params)
            }
        }
    }

    // 根据size变化，检查是否升级策略
    private func upgradeStrategyIfNeed(size: CGSize) {
        let size = max(size.width, size.height)
        guard needUpgrade(size: size) else { return }
        avatarSize = avatarConfig.transform(maxSize: size)
        let params = AvatarViewParams(sizeType: .size(size))
        var tempParam = self.lastParams
        tempParam.params = params
        setAvatar(parmas: tempParam)
    }

    private func needUpgrade(size: CGFloat) -> Bool {
        guard !lastParams.avatarKey.isEmpty else { return false }
        if avatarSize != .big, let oldSize = avatarConfig.dprConfigs[avatarSize] {
            return Int(size) > oldSize.sizeHigh // 超过上限，说明需要更大的图片
        }
        return false
    }
}

extension ByteWebImage.ImageWrapper where Base: UIImageView {
    @discardableResult
    func setLarkImage(with params: LarkAvatar.AvatarParams) -> LarkImageRequest? {
        let completion: ImageRequestCompletion = { [weak base] result in
            if case let .failure(err) = result, err.code != ByteWebImageErrorUserCancelled {
                base?.backgroundColor = params.backgroundColorWhenError
            }
            params.completion?(result)
        }

        return self.setLarkImage(.avatar(key: params.avatarKey, entityID: params.entiryID, params: params.params),
                                 placeholder: params.placeholder,
                                 options: params.options ?? [],
                                 trackInfo: { TrackInfo(scene: params.scene, fromType: .avatar) },
                                 completion: completion)
    }
}
