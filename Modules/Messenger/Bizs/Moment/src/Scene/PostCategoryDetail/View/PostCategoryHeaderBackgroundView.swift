//
//  PostCategoryHeaderBackgroundView.swift
//  Moment
//
//  Created by liluobin on 2021/5/5.
//

import Foundation
import UIKit
import LKCommonsLogging
import AvatarComponent
import LarkBizAvatar

final class PostCategoryHeaderBackgroundView: UIView {
    static let logger = Logger.log(PostCategoryHeaderBackgroundView.self, category: "Module.Moments.PostCategoryHeaderBackgroundView")

    private lazy var effectView: UIVisualEffectView = {
        let maskEffect = UIBlurEffect(style: .light)
        let view = UIVisualEffectView(effect: maskEffect)
        return view
    }()

    public lazy var backgroundImageView: BizAvatar = {
        let view = BizAvatar()
        var config = AvatarComponentUIConfig(style: .square)
        config.backgroundColor = UIColor.clear
        config.contentMode = .scaleAspectFill
        view.setAvatarUIConfig(config)
        view.isUserInteractionEnabled = false
        view.isHidden = true
        return view
    }()

    private lazy var colorImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.alpha = 0.8
        imageView.clipsToBounds = true
        return imageView
    }()

    init() {
        super.init(frame: .zero)
        setupView()
    }
    private func setupView() {
        self.clipsToBounds = true
        self.backgroundColor = MomentsPirmaryColorManager.defaultColor
        addSubview(backgroundImageView)
        addSubview(effectView)
        addSubview(colorImageView)
        backgroundImageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        effectView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        colorImageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func setHeaderBackGroundImageWithOriginImage(_ originImage: UIImage, key: String, entityId: String, finish: ((UIImage) -> Void)?) {
        // 这里和UI确认过 gif不支持播放
        backgroundImageView.setAvatarByIdentifier(entityId,
                                                  avatarKey: key,
                                                  avatarViewParams: .defaultMiddle,
                                                  backgroundColorWhenError: .clear,
                                                  completion: nil)
        MomentsPirmaryColorManager.getPrimaryColorImageBy(image: originImage, avatarKey: key, size: originImage.size) { [weak self] (image, error) in
            if let image = image {
                self?.colorImageView.image = image
                self?.backgroundColor = .clear
                self?.backgroundImageView.isHidden = false
                finish?(image)
            } else {
                Self.logger.error("setHeaderBackGroundImageWithOriginImage -----key: \(key) ---- error: \(error)")
            }
        }
    }
}
