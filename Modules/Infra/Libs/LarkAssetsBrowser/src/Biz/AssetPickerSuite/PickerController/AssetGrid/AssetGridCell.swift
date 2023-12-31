//
//  AssetGridCell.swift
//  LarkImagePicker
//
//  Created by ChalrieSu on 2018/8/28.
//  Copyright © 2018 ChalrieSu. All rights reserved.
//

import Foundation
import UIKit
import Photos
import SnapKit
import LarkUIKit

final class AssetGridCell: UICollectionViewCell {
    var assetIdentifier: String? {
        return currentAsset?.localIdentifier
    }

    // only for UI Automation Test
    var checkBoxIdentifier: String? {
        didSet {
            numberBox.accessibilityIdentifier = checkBoxIdentifier
        }
    }

    var showCheckButton: Bool = true {
        didSet {
            numberBox.isHidden = !showCheckButton
        }
    }

    var selectIndex: Int? {
        didSet {
            // 这里需要外界传入的index + 1表示选中的数量
            if let index = selectIndex {
                numberBox.number = index + 1
            } else {
                numberBox.number = nil
            }
        }
    }

    var showMask: Bool = false {
        didSet {
            imageCoverView.isHidden = !showMask
        }
    }

    var videoDuration: TimeInterval = 0 {
        didSet {
            if videoDuration != 0 {
                videoInfoView.isHidden = false
                let minutes: Int = Int(round(videoDuration)) / 60
                let seconds: Int = Int(round(videoDuration)) % 60
                videoDurationLabel.text = String(format: "\(minutes):%02d", seconds)
            } else {
                videoInfoView.isHidden = true
            }
        }
    }

    var numberButtonDidClickBlock: ((AssetGridCell) -> Void)?

    var currentImage: UIImage? {
        return thumbnailImageView.image
    }

    weak var currentAsset: PHAsset?

    let numberBox = NumberBox(number: nil)
    private let thumbnailImageView = UIImageView()
    private let imageCoverView = UIView()
    private let videoInfoView = UIImageView()
    private let videoDurationLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(thumbnailImageView)
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        numberBox.autoTapBounceAnimation = false
        numberBox.hitTestEdgeInsets = UIEdgeInsets(top: -9, left: -9, bottom: -9, right: -9)
        numberBox.delegate = self
        addSubview(numberBox)
        numberBox.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 30, height: 30))
            make.right.equalToSuperview().offset(-5)
            make.top.equalToSuperview().offset(5)
        }

        // 图片遮罩的位置 位于复选框之上
        imageCoverView.backgroundColor = UIColor.ud.N00.withAlphaComponent(0.6)
        addSubview(imageCoverView)
        imageCoverView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        imageCoverView.isHidden = true
        imageCoverView.isUserInteractionEnabled = false

        videoInfoView.isHidden = true
        videoInfoView.contentMode = .scaleToFill
        videoInfoView.image = Resources.image_picker_video_time_bg
        addSubview(videoInfoView)
        videoInfoView.snp.makeConstraints { (make) in
            make.left.bottom.right.equalToSuperview()
            make.height.equalTo(20)
        }

        let videoIcon = UIImageView(image: Resources.image_picker_small_video_icon)
        videoInfoView.addSubview(videoIcon)
        videoIcon.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(5)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(12)
        }

        videoDurationLabel.textAlignment = .right
        videoDurationLabel.font = UIFont.systemFont(ofSize: 12)
        videoDurationLabel.textColor = UIColor.white
        videoInfoView.addSubview(videoDurationLabel)
        videoDurationLabel.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-5)
            make.centerY.equalToSuperview()
        }
    }

    func setImage(_ image: UIImage?) {
        thumbnailImageView.image = image
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.image = nil
        videoDuration = 0
        imageCoverView.isHidden = true
    }
}

extension AssetGridCell: NumberBoxDelegate {
    func didTapNumberbox(_ numberBox: NumberBox) {
        numberButtonDidClickBlock?(self)
    }
}
