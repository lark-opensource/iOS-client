//
//  UDLoadingImageViewController.swift
//  EEAtomic
//
//  Created by Miaoqi Wang on 2020/10/19.
//

import Foundation
import UIKit
import UniverseDesignColor
import SnapKit

class UDLoadingImageViewController: UIViewController {

    let loadingImage: UDLoadingImageView

    init(lottieResource: String?) {
        self.loadingImage = UDLoadingImageView(lottieResource: lottieResource)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UDLoadingColorTheme.loadingImageVCBgColor

        let topSpaceView = UIView()
        view.addSubview(topSpaceView)

        topSpaceView.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(UDLoadingImageView.Layout.topHeightRatio)
        }

        view.addSubview(loadingImage)
        loadingImage.snp.makeConstraints { (make) in
            make.top.equalTo(topSpaceView.snp.bottom)
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview()
            make.trailing.bottom.lessThanOrEqualToSuperview()
        }
    }
}
