//
//  ImageOrVideoFileGridCell.swift
//  LarkFile
//
//  Created by liluobin on 2021/10/19.
//

import Foundation
import UIKit
import ByteWebImage
import LKCommonsLogging
final class ImageVideoFileBrowserGridCell: FolderAndFileBrowserGridCell {
    static let logger = Logger.log(ImageVideoFileBrowserGridCell.self, category: "ImageVideoFileBrowserGridCell")
    private lazy var videoTagView: VideoFileTagView = {
        let tagView = VideoFileTagView(type: .middle)
        return tagView
    }()
    override func setupView() {
        super.setupView()
        iconImageView.layer.cornerRadius = 6
        iconImageView.clipsToBounds = true
        iconImageView.layer.borderWidth = 0.5
        iconImageView.contentMode = .scaleAspectFill
        iconImageView.layer.borderColor = UIColor.ud.lineBorderCard.cgColor
        iconImageView.addSubview(videoTagView)
        videoTagView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(24)
        }
        videoTagView.isHidden = true
    }

    override func setContent(props: FolderAndFileBrowserCellPropsProtocol) {
        /// 清空一下之前的图片，防止cell复用可能带来的问题
        iconImageView.image = nil
        let defautImage = props.image
        iconImageView.bt.setLarkImage(with: .default(key: props.previewImageKey ?? ""), completion: { [weak self] result in
            switch result {
            case .success(let imageRes):
                self?.updateIconImageViewWithRemoteImage(imageRes.image, defautImage: defautImage)
            case .failure(let error):
                self?.updateIconImageViewWithRemoteImage(nil, defautImage: defautImage)
                Self.logger.error("grid cell load previewImageKey fail", error: error)
            }
        })
        nameLabel.text = props.name
        sizeLabel.text = FileDisplayInfoUtil.sizeStringFromSize(props.size)
        videoTagView.isHidden = !props.isVideo
    }

    func updateIconImageViewWithRemoteImage(_ image: UIImage?, defautImage: UIImage?) {
        if let image = image {
            let size = FileDisplayInfoUtil.displayImageSizeWithOriginSize(image.size)
            iconImageView.snp.remakeConstraints { make in
                make.size.equalTo(size)
                make.centerX.equalToSuperview()
                make.bottom.equalToSuperview()
            }
        } else {
            iconImageView.image = defautImage
            iconImageView.snp.remakeConstraints { make in
                make.center.equalToSuperview()
                make.size.equalTo(CGSize(width: 80, height: 80))
            }
        }
    }
}
