//
//  OfficialCoverPhotoCell.swift
//  SpaceKit
//
//  Created by lizechuang on 2020/2/10.
//

import Foundation
import SKCommon
import SKResource
import SkeletonView
import SKUIKit
import RxSwift
import SKFoundation
import UniverseDesignIcon
import UniverseDesignColor

class OfficialCoverPhotoCell: UICollectionViewCell {
    
    private var resumeBag = DisposeBag()
    lazy var coverPhotoImageView: UIImageView = {
        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFill
        imgView.layer.cornerRadius = 4
        imgView.clipsToBounds = true
        imgView.isSkeletonable = true
        return imgView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        // 复用时重新赋值
        self.resumeBag = DisposeBag()
        coverPhotoImageView.showAnimatedGradientSkeleton()
        coverPhotoImageView.startSkeletonAnimation()
        coverPhotoImageView.image = nil
    }

    private func setupSubViews() {
        contentView.addSubview(coverPhotoImageView)
        coverPhotoImageView.frame = CGRect(x: 0, y: 0, width: self.contentView.bounds.width, height: self.contentView.bounds.height)
        coverPhotoImageView.center = self.contentView.center
        coverPhotoImageView.showAnimatedGradientSkeleton()
        coverPhotoImageView.startSkeletonAnimation()
    }

    public func setupWithDataAPI(_ dataAPI: OfficialCoverPhotoDataAPI,
                                 photoInfo: OfficialCoverPhotoInfo,
                                 coverSize: CGSize) {
        dataAPI.fetchOfficialCoverPhotoDataWith(photoInfo,
                                                coverSize: coverSize,
                                                resumeBag: self.resumeBag) { [weak self] (image, _, error) in
            guard let self = self else { return }
            func setupImage(_ image: UIImage) {
                DispatchQueue.main.async {
                    self.updateDisplayImage(image)
                }
            }
            guard let image = image, error == nil else {
                DocsLogger.info("OfficialCoverPhotosSelectView, download drive pic data empty")
                setupImage(UDIcon.imageFailOutlined)
                return
            }
            setupImage(image)
        }
    }

    public func updateDisplayImage(_ image: UIImage) {
        coverPhotoImageView.hideSkeleton()
        coverPhotoImageView.image = image
    }
}

class OfficialCoverPhotoHeaderView: UICollectionReusableView {
    lazy var headerTitleLabel: UILabel = {
        let header = UILabel()
        header.font = UIFont.systemFont(ofSize: 14)
        header.textColor = UDColor.textCaption
        return header
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(headerTitleLabel)
        headerTitleLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setHeaderTitle(_ title: String) {
        headerTitleLabel.text = title
    }
}
