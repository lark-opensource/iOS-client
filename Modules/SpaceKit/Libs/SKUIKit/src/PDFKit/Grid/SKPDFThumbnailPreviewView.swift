//
//  SKPDFThumbnailPreviewView.swift
//  Alamofire
//
//  Created by liweiye on 2019/5/30.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignColor

public final class SKPDFThumbnailPreviewView: UIView {

    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.layer.cornerRadius = 4
        view.layer.masksToBounds = true
        view.layer.ud.setBorderColor(UIColor.ud.N300)
        view.contentMode = .scaleAspectFill
        return view
    }()

    private lazy var hintBackgroundView: UIView = {
        let view = UIView()
        view.alpha = 0.3
        view.backgroundColor = UIColor.ud.N900.nonDynamic
        view.layer.cornerRadius = 4
        view.layer.masksToBounds = true
        return view
    }()

    private lazy var indicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .gray)
        view.backgroundColor = .white
        return view
    }()

    private lazy var hintLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.N50.nonDynamic
        label.font = UIFont.ct.systemMedium(ofSize: 14)
        label.adjustsFontSizeToFitWidth = true
        label.textAlignment = .center
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        addSubview(indicator)
        indicator.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        addSubview(hintBackgroundView)
        hintBackgroundView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.height.equalTo(30)
            make.width.equalTo(80)
            make.bottom.equalToSuperview().offset(-8)
        }

        addSubview(hintLabel)
        hintLabel.snp.makeConstraints { (make) in
            make.center.equalTo(self.hintBackgroundView.snp.center)
            make.height.equalTo(16)
        }
    }

    func startLoading() {
        indicator.isHidden = false
        indicator.startAnimating()
    }

    func stopLoading() {
        indicator.isHidden = true
        indicator.stopAnimating()
    }

    public func update(thumbnailImage: UIImage) {
        stopLoading()
        imageView.image = thumbnailImage
    }

    public func update(hintContent: String) {
        hintLabel.text = hintContent
    }

    public func reset() {
        startLoading()
        imageView.image = nil
    }
}
