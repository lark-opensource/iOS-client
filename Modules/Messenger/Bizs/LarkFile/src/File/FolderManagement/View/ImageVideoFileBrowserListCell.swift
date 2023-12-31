//
//  ImageOrVideoFileListCell.swift
//  LarkFile
//
//  Created by liluobin on 2021/10/19.
//

import Foundation
import UIKit
import ByteWebImage
import LKCommonsLogging

final class ImageVideoFileBrowserListCell: FolderAndFileBrowserListCell {
    static let logger = Logger.log(ImageVideoFileBrowserListCell.self, category: "ImageVideoFileBrowserListCell")
    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.layer.cornerRadius = 4
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.layer.borderWidth = 0.5
        imageView.layer.borderColor = UIColor.ud.lineBorderCard.cgColor
        return imageView
    }()

    private lazy var videoTagView: VideoFileTagView = {
        let tagView = VideoFileTagView(type: .small)
        return tagView
    }()

    override func setupView() {
        super.setupView()
        contentView.addSubview(iconImageView)
        iconImageView.addSubview(videoTagView)
        iconImageView.snp.makeConstraints { make in
            make.edges.equalTo(browserInfoView.avatarView)
        }
        videoTagView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(20)
        }
        videoTagView.isHidden = true
    }

    override func setContent(props: FolderAndFileBrowserCellPropsProtocol) {
        if let imageKey = props.previewImageKey {
            iconImageView.bt.setLarkImage(with: .default(key: imageKey), completion: { [weak self] result in
                switch result {
                case .success(let imageRes):
                    if imageRes.image == nil {
                        self?.iconImageView.image = props.image
                    }
                case .failure(let error):
                    /// 失败了使用默认的图片
                    self?.iconImageView.image = props.image
                    Self.logger.error("cell load previewImageKey fail", error: error)
                }
            })
            browserInfoView.avatarView.image = nil
            iconImageView.isHidden = false
        } else {
            iconImageView.bt.setLarkImage(with: .default(key: ""))
            browserInfoView.avatarView.image = props.image
            iconImageView.isHidden = true
        }
        videoTagView.isHidden = !props.isVideo
        setDescribeInfo(props: props)
    }
}
