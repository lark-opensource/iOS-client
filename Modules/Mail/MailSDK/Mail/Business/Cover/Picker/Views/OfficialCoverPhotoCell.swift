//
//  OfficialCoverPhotoCell.swift
//  SpaceKit
//
//  Created by lizechuang on 2020/2/10.
//

import Foundation
import SkeletonView
import RxSwift
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
        imgView.backgroundColor = UDColor.bgFiller
        return imgView
    }()

    lazy var reloadImage = UIImageView(image: UDIcon.refreshOutlined.withRenderingMode(.alwaysTemplate))

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
        coverPhotoImageView.image = nil
        startSkeleton()
    }

    private func setupSubViews() {
        contentView.addSubview(coverPhotoImageView)
        coverPhotoImageView.frame = CGRect(x: 0, y: 0, width: self.contentView.bounds.width, height: self.contentView.bounds.height)
        coverPhotoImageView.center = self.contentView.center
        reloadImage.isHidden = true
        reloadImage.tintColor = .ud.iconN3
        contentView.addSubview(reloadImage)
        reloadImage.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(16)
        }
    }

    func setupWithDataAPI(_ dataAPI: OfficialCoverPhotoDataAPI, photoInfo: OfficialCoverPhotoInfo) {
        startSkeleton()
        dataAPI.fetchOfficialCoverPhotoDataWith(photoInfo,
                                                coverSize: dataAPI.defaultThumbnailSize,
                                                resumeBag: self.resumeBag) { [weak self] (image, error, _) in
            guard let self = self else { return }
            func setupImage(_ image: UIImage?) {
                DispatchQueue.main.async {
                    self.updateDisplayImage(image)
                }
            }
            guard let image = image, error == nil else {
                MailLogger.info("OfficialCoverPhotosSelectView, download drive pic data empty")
                setupImage(image)
                return
            }
            setupImage(image)
        }
    }

    func updateDisplayImage(_ image: UIImage?) {
        coverPhotoImageView.hideSkeleton()
        coverPhotoImageView.image = image
        reloadImage.isHidden = image != nil
    }

    private func startSkeleton() {
        let gradient = SkeletonGradient(baseColor: UDColor.bgFiller, secondaryColor: nil)
        coverPhotoImageView.showAnimatedGradientSkeleton(usingGradient: gradient, animation: nil)
        coverPhotoImageView.startSkeletonAnimation()
        reloadImage.isHidden = true
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

    func setHeaderTitle(_ title: String) {
        headerTitleLabel.text = title
    }
}
