//
//  SKPDFThumbnailCell.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2019/7/9.
//  

import UIKit
import SnapKit
import UniverseDesignColor

public final class SKPDFThumbnailCell: UICollectionViewCell {

    private var imageView: UIImageView
    private var pageNumberLabel: UILabel
    private var loadingView: UIActivityIndicatorView
    private var currentPage = 0
    private(set) var isImageLoaded = false

    override init(frame: CGRect) {
        imageView = UIImageView(frame: .zero)
        pageNumberLabel = UILabel(frame: .zero)
        loadingView = UIActivityIndicatorView(style: .gray)
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        setupImageView()
        setupPageLabel()
        setupLoadingView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupImageView() {
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .clear
        imageView.layer.cornerRadius = 4
        imageView.clipsToBounds = true
        imageView.layer.ud.setBorderColor(UIColor.ud.N300)
        imageView.layer.borderWidth = 0.5
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    private func setupPageLabel() {
        pageNumberLabel.text = "-"
        pageNumberLabel.textAlignment = .center
        pageNumberLabel.font = UIFont.systemFont(ofSize: 10)
        pageNumberLabel.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.5).nonDynamic
        pageNumberLabel.layer.cornerRadius = 4
        pageNumberLabel.clipsToBounds = true
        pageNumberLabel.textColor = UDColor.primaryOnPrimaryFill
        contentView.addSubview(pageNumberLabel)
        pageNumberLabel.snp.makeConstraints { (make) in
            make.height.equalTo(16)
            make.width.greaterThanOrEqualTo(20)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-8)
        }
    }

    private func setupLoadingView() {
        loadingView.startAnimating()
        contentView.addSubview(loadingView)
        loadingView.snp.makeConstraints { (make) in
            make.height.width.equalTo(24)
            make.center.equalToSuperview()
        }
    }

    private func showLoading() {
        loadingView.startAnimating()
        loadingView.isHidden = false
    }

    private func stopLoading() {
        loadingView.stopAnimating()
        loadingView.isHidden = true
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        showLoading()
        imageView.image = nil
        isImageLoaded = false
        resetHighlightLabel()
    }

    public func update(image: UIImage, page: Int) {
        guard currentPage == page else {
            return
        }
        isImageLoaded = true
        DispatchQueue.main.async {
            self.stopLoading()
            self.imageView.image = image
        }
    }

    public func update(page: Int) {
        pageNumberLabel.text = String(page)
        currentPage = page
    }

    public func highlightLabel() {
        pageNumberLabel.backgroundColor = UDColor.primaryContentDefault
    }

    public func resetHighlightLabel() {
        pageNumberLabel.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.5).nonDynamic
    }
}
