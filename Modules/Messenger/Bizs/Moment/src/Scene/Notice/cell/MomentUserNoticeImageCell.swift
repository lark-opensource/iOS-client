//
//  MomentUserNoticeImageCell.swift
//  Moment
//
//  Created by bytedance on 2021/2/22.
//

import Foundation
import UIKit
import ByteWebImage

final class MomentUserNoticeImageCell: MomentUserNotieBaseCell {
    let showImageView = ByteImageView()
    let videoImageView = UIImageView()
    let imageMaskView = UIView()
    override func configRightView() -> UIView {
        /// 视频的背景遮罩
        imageMaskView.backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.4)
        showImageView.addSubview(imageMaskView)
        imageMaskView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        showImageView.animateRunLoopMode = .default
        showImageView.addSubview(videoImageView)
        videoImageView.image = Resources.iconVideoFilled
        videoImageView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 24, height: 24))
            make.center.equalToSuperview()
        }

        showImageView.contentMode = .scaleAspectFill
        showImageView.layer.cornerRadius = 4
        showImageView.clipsToBounds = true
        showImageView.layer.borderWidth = 0.5
        showImageView.layer.borderColor = UIColor.ud.N900.withAlphaComponent(0.15).cgColor
        return showImageView
    }

    override class func getCellReuseIdentifier() -> String {
        return "MomentUserNoticeImageCell"
    }

    override func updateRightViewWithVM(_ vm: MomentsNoticeBaseCellViewModel) {
        let isVideo = vm.rightImageInfo?.isVideo ?? false
        videoImageView.isHidden = !isVideo
        imageMaskView.isHidden = videoImageView.isHidden
        showImageView.bt.setLarkImage(with: .default(key: vm.rightImageInfo?.key ?? ""),
                                      trackStart: {
                                        return TrackInfo(scene: .Moments, fromType: isVideo ? .media : .image)
                                      })
    }
}
