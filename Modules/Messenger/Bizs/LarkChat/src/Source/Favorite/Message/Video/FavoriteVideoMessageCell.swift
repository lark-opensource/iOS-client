//
//  FavoriteVideoMessageCell.swift
//  LarkFavorite
//
//  Created by K3 on 2018/8/23.
//

import Foundation
import UIKit
import LarkUIKit
import SnapKit
//import Kingfisher
import LarkModel
import LarkCore
import ByteWebImage

public final class FavoriteVideoMessageCell: FavoriteMessageCell {
    override class var identifier: String {
        return FavoriteVideoMessageViewModel.identifier
    }

    var videoViewModel: FavoriteVideoMessageViewModel? {
        return self.viewModel as? FavoriteVideoMessageViewModel
    }

    private let imageViewWidth: CGFloat = 80
    private let imageViewHeight: CGFloat = 80

    private lazy var favoriteVideoView: UIImageView = {
        return UIImageView()
    }()

    private lazy var iconImageView: UIImageView = {
        return UIImageView(image: Resources.favorite_video_play)
    }()

    private var retrieveTask: ImageRequest?

    override public func setupUI() {
        super.setupUI()
        favoriteVideoView.backgroundColor = UIColor.ud.N300
        favoriteVideoView.layer.ud.setBorderColor(UIColor.ud.N300)
        favoriteVideoView.layer.borderWidth = 1.0
        favoriteVideoView.isUserInteractionEnabled = true
        favoriteVideoView.contentMode = .scaleAspectFill
        favoriteVideoView.clipsToBounds = true
        favoriteVideoView.lu.addTapGestureRecognizer(action: #selector(imageViewDidTapped(_:)), target: self)
        favoriteVideoView.layer.cornerRadius = 4

        contentWraper.addSubview(favoriteVideoView)

        iconImageView.contentMode = .scaleAspectFit
        contentWraper.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { (maker) in
            maker.width.height.equalTo(24)
            maker.center.equalTo(favoriteVideoView.snp.center)
        }

        favoriteVideoView.snp.remakeConstraints { (make) in
            make.left.top.bottom.equalToSuperview()
            make.width.equalTo(imageViewWidth)
            make.height.equalTo(imageViewHeight)
        }
    }

    override public func updateCellContent() {
        super.updateCellContent()
        guard let videoViewModel = videoViewModel else { return }
        let permissionPreview = videoViewModel.permissionPreview
        if permissionPreview.0 && videoViewModel.dynamicAuthorityEnum.authorityAllowed {
            hideNoPermissionPreviewLayer()
        } else {
            showNoPermissionPreviewLayer()
            return
        }
        guard let videoContent = videoViewModel.messageContent else { return }
        let imageSet = ImageItemSet.transform(imageSet: videoContent.image)
        let key = imageSet.generateVideoMessageKey(forceOrigin: false)
        let placeholder = imageSet.inlinePreview
        let resource = LarkImageResource.default(key: key)
        favoriteVideoView.bt.setLarkImage(with: resource,
                                          placeholder:
                                          placeholder,
                                          trackStart: {
                                              TrackInfo(scene: .Chat, fromType: .media)
                                          })
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        retrieveTask?.cancel()
    }

    @objc
    fileprivate func imageViewDidTapped(_ gesture: UIGestureRecognizer) {
        videoViewModel?.showVideo(withDispatcher: dispatcher, imageView: favoriteVideoView)
    }

    private lazy var noPermissionPreviewLayerView: NoPermissonPreviewSmallLayerView = {
        let view = NoPermissonPreviewSmallLayerView()
        view.tapAction = { [weak self] gesture in
            self?.imageViewDidTapped(gesture)
        }
        return view
    }()

    private func showNoPermissionPreviewLayer() {
        iconImageView.isHidden = true
        if noPermissionPreviewLayerView.superview == nil {
            self.favoriteVideoView.addSubview(noPermissionPreviewLayerView)
            noPermissionPreviewLayerView.snp.makeConstraints({ make in
                make.centerX.equalToSuperview()
                make.centerY.equalToSuperview()
                make.width.height.equalToSuperview()
            })
        }
        noPermissionPreviewLayerView.isHidden = false
    }

    private func hideNoPermissionPreviewLayer() {
        iconImageView.isHidden = false
        noPermissionPreviewLayerView.isHidden = true
    }
}
