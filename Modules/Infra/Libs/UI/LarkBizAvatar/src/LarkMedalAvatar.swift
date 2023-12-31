//
//  LarkMedalAvatar.swift
//  LarkBizAvatar
//
//  Created by 姚启灏 on 2021/9/13.
//

import UIKit
import Foundation
import LarkAvatarComponent
import AvatarComponent
import LarkBadge
import ByteWebImage
import UniverseDesignColor
import UniverseDesignTheme
import LarkExtensions
import AppReciableSDK
import RxSwift
import LarkFeatureGating
import LKCommonsLogging

public final class LarkMedalAvatar: BizAvatar {
    
    //用于重置ob
    private var reuseBag = DisposeBag()

    public lazy var medalImageView: UIImageView = {
        let medalImageView = UIImageView()
        medalImageView.isUserInteractionEnabled = false
        return medalImageView
    }()

    private var disposeBag = DisposeBag()
    private static let logger = Logger.log(LarkMedalAvatar.self, category: "LarkMedalAvatar")
    private var identifier = "" {
        didSet {
            let observer = AvatarService.getObserverByIdentifier(identifier)
            self.observePublish(observer)
        }
    }

    public private(set) var medalKey = "" {
        didSet {
            let setImageCompletion: ImageRequestCompletion = { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let imageResult):
                    guard let resultImage = imageResult.image else { return }
                    self.border.isHidden = true
                    Self.logger.info("medal wear success medalKey: \(self.medalKey)")
                case .failure:
                    self.border.isHidden = false
                    Self.logger.info("medal dropoff success medalKey: \(self.medalKey))")
                default:
                    break
                }
            }
            if !medalFsUnit.isEmpty {
                var passThrough = ImagePassThrough()
                passThrough.key = self.medalKey
                passThrough.fsUnit = self.medalFsUnit

                self.medalImageView.bt.setLarkImage(with: .default(key: self.medalKey),
                                                    passThrough: passThrough, completion: setImageCompletion)
            } else {
                self.medalImageView.bt.setLarkImage(with: .default(key: self.medalKey), completion: setImageCompletion)
            }
        }
    }

    private var medalFsUnit = ""

    public override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(medalImageView)
        
        self.bringSubviewToFront(self.topBadge)
        self.bringSubviewToFront(self.bottomBadge)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        medalImageView.bounds = bounds
        medalImageView.center = self.avatar.center
    }

    public func setAvatarByIdentifier(_ identifier: String,
                                    avatarKey: String,
                                    medalKey: String,
                                    medalFsUnit: String,
                                    scene: Scene,
                                    placeholder: UIImage? = nil,
                                    options: ImageRequestOptions? = nil,
                                    avatarViewParams: AvatarViewParams = .defaultMiddle,
                                    backgroundColorWhenError: UIColor = UIColor.ud.N300,
                                    completion: ImageRequestCompletion? = nil) {
        self.identifier = identifier
        self.medalFsUnit = medalFsUnit
        Self.logger.info("LarkMedalAvatar,setAvatarByIdentifier,\(medalKey)")
        self.medalKey = medalKey
        reuseBag = DisposeBag()
        avatar.setAvatarKeyByIdentifier(identifier,
                                        avatarKey: avatarKey,
                                        medalKey: medalKey,
                                        scene: scene,
                                        placeholder: placeholder,
                                        options: options,
                                        avatarViewParams: avatarViewParams,
                                        backgroundColorWhenError: backgroundColorWhenError,
                                        completion: completion)
    }
    
    public func setCustomAvatar(model: LarkAvatarCustommModelProtocol) {
        
        //处理复用的问题
        reuseBag = DisposeBag()
        setAvatarByIdentifier("", avatarKey: "", completion: { [weak self] _ in
              self?.backgroundColor = UIColor.clear
        })
        
        let binder = LarkAvatarCustomBinder.shared.getBinder(model: model)

        guard let binder = binder else {
            self.image = nil
            assertionFailure("Custom Avatar has not regist")
            return
        }
        
        binder.binder(model: model)
            .asDriver(onErrorJustReturn: UIImage()) //placeholder
            .drive(onNext: { [weak self] (image) in
                self?.image = image
            })
            .disposed(by: reuseBag)
    }

    private func observePublish(_ observer: Observable<AvatarTuple>) {
        self.disposeBag = DisposeBag()
        observer
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (tuple) in
                guard let `self` = self,
                      tuple.identifier == self.identifier,
                      tuple.medalKey != self.medalKey else { return }
                self.medalKey = tuple.medalKey
                self.medalFsUnit = tuple.medalFsUnit
            }).disposed(by: self.disposeBag)
    }
}
