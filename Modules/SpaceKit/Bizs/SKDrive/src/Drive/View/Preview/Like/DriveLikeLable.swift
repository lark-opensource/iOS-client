//
//  DriveLikeLable.swift
//  SpaceKit
//
//  Created by zenghao on 2019/4/29.
//

import Foundation
import Kingfisher
import SKUIKit
import SKCommon
import SKResource
import SKFoundation
import UniverseDesignColor
import UniverseDesignIcon
import UIKit

protocol DriveLikeLableDelegate: AnyObject {
    func didClickDriveLikeLable(_ likeLable: DriveLikeLable)
    func didDriveLikeLabelAppear(_ likeLable: DriveLikeLable)
    func didDriveLikeLabelDisappear(_ likeLable: DriveLikeLable)
}

class DriveLikeLable: UIView {
    let delimit = "\u{200b}"

    var likeModel: DriveLikeDataManager?
    weak var delegate: DriveLikeLableDelegate?

    lazy private var firstImage: UIImageView = createAvatarImageView()

    lazy private var secondImage: UIImageView = createAvatarImageView()
    
    lazy var banImage: UIImageView = {
        let iv = UIImageView()
        iv.image = BundleResources.SKResource.Common.Collaborator.avatar_placeholder
        iv.layer.cornerRadius = 12
        iv.layer.masksToBounds = true
        iv.isHidden = true
        return iv
    }()

    private let tapGesture = UITapGestureRecognizer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UDColor.bgBody

        setupUI()
        setupGesture()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(secondImage)
        addSubview(firstImage)
        addSubview(banImage)

        firstImage.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.width.equalTo(24)
        }

        secondImage.snp.makeConstraints { (make) in
            make.top.left.equalTo(firstImage)
            make.height.width.equalTo(firstImage)
        }
        
        banImage.snp.makeConstraints { (make) in
            make.center.equalTo(firstImage)
            make.height.width.equalTo(firstImage)
        }
    }

    private func setupGesture() {
        tapGesture.numberOfTapsRequired = 1
        tapGesture.numberOfTouchesRequired = 1
        isUserInteractionEnabled = true
        tapGesture.addTarget(self, action: #selector(tapped))
        addGestureRecognizer(tapGesture)
    }

    @objc
    func tapped() {
        delegate?.didClickDriveLikeLable(self)
    }

    func reload() {
        guard let model = likeModel,
            model.count > 0 else {
            delegate?.didDriveLikeLabelDisappear(self)
            DocsLogger.warning("invalid like model")
            return
        }

        delegate?.didDriveLikeLabelAppear(self)
        
        if LKFeatureGating.setUserRestrictedEnable {
            if !model.canShowCollaboratorInfo {
                banImage.isHidden = false
                firstImage.isHidden = true
                secondImage.isHidden = true
                return
            } else {
                banImage.isHidden = true
                firstImage.isHidden = false
                secondImage.isHidden = false
            }
        }

        // 两个头像的显示顺序根据需求文档编写：https://bytedance.feishu.cn/space/doc/doccn6UXBYtxB4sZemQ5GQ
        var firstURL = ""
        var secondURL = ""
        if model.likeStatus == .hasLiked {
            firstURL = User.current.info?.avatarURL ?? ""
            firstImage.kf.setImage(with: URL(string: firstURL), placeholder: BundleResources.SKResource.Drive.drive_default_headPortrait)
            // 如果当前用户已点赞，且点赞数大于1，第一张图片显示当前用户的头像，第二张显示最新的点赞人的头像
            if model.count > 1 {
                if User.current.info?.userID == model.firstUserInfo?.likeThisUserId {
                    secondURL = model.secondUserInfo?.avatarURL ?? ""
                } else {
                    secondURL = model.firstUserInfo?.avatarURL ?? ""
                }
                secondImage.kf.setImage(with: URL(string: secondURL), placeholder: BundleResources.SKResource.Drive.drive_default_headPortrait)
                secondImage.snp.updateConstraints { (make) in
                    make.left.equalTo(firstImage).offset(12)
                }
            } else {
                // 如果点赞数等于1，则第二张头像被盖在第一张头像下面
                secondImage.snp.updateConstraints { (make) in
                    make.left.equalTo(firstImage)
                }
            }
        } else {
            // 如果当前用户没有点赞，则头像按照时间顺序显示，左边的是最新的，右边是次新的
            firstURL = model.firstUserInfo?.avatarURL ?? ""
            firstImage.kf.setImage(with: URL(string: firstURL), placeholder: BundleResources.SKResource.Drive.drive_default_headPortrait)
            if model.count > 1 {
                secondURL = model.secondUserInfo?.avatarURL ?? ""
                secondImage.kf.setImage(with: URL(string: secondURL), placeholder: BundleResources.SKResource.Drive.drive_default_headPortrait)
                secondImage.snp.updateConstraints { (make) in
                    make.left.equalTo(firstImage).offset(12)
                }
            } else {
                secondImage.snp.updateConstraints { (make) in
                    make.left.equalTo(firstImage)
                }
            }
        }
    }

    private func createAvatarImageView() -> UIImageView {
        let imageView = SKAvatar(configuration: .init(style: .circle,
                                               contentMode: .scaleAspectFill))
        imageView.layer.cornerRadius = 24 / 2
        imageView.layer.masksToBounds = true
        imageView.layer.ud.setBorderColor(UDColor.bgBody)
        imageView.layer.borderWidth = 1.0
        return imageView
    }
}
