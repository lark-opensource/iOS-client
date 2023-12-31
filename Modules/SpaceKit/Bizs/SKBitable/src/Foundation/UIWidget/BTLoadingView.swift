//
//  BTLoadingView.swift
//  SKBitable
//
//  Created by zoujie on 2022/10/21.
//  


import Foundation
import SKResource
import UniverseDesignLoading
import UniverseDesignColor
import UniverseDesignEmpty

final class BTLaodingViewManager {
    private let udloadingViewHeight: CGFloat = 124
    private lazy var udloadingView = UDLoading.loadingImageView()
    private lazy var udloadingLable = UILabel().construct { it in
        it.font = .systemFont(ofSize: 14)
        it.textColor = UDColor.textCaption
        it.textAlignment = .center
        it.text = BundleI18n.SKResource.Bitable_Common_Loading_Mobile
    }
    
    
    /// 显示loading
    /// - Parameters:
    ///   - superView: loadingView的宿主view
    ///   - minTop: loadingView到宿主view顶部的最小距离
    ///   - centeryOffset: loadingView centerY相对于宿主view的偏移
    func showLoading(superView: UIView, minTop: CGFloat = 0, centeryOffset: CGFloat = 0) {
        superView.addSubview(udloadingView)
        superView.addSubview(udloadingLable)
        
        var currentCenteryOffset: CGFloat = 0
        let superViewHeight = superView.bounds.height
        if (centeryOffset + udloadingViewHeight / 2 + minTop) > superViewHeight / 2 {
            //udloadingView会被遮挡
            currentCenteryOffset = superViewHeight / 2 - minTop - udloadingViewHeight / 2
        }

        udloadingView.snp.makeConstraints { (make) in
            make.height.equalTo(udloadingViewHeight)
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-currentCenteryOffset)
        }

        udloadingLable.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(udloadingView.snp.bottom).offset(16)
            make.left.right.lessThanOrEqualToSuperview()
        }
        
        superView.bringSubviewToFront(udloadingView)
        superView.bringSubviewToFront(udloadingLable)
    }

    func hideLoading() {
        udloadingView.removeFromSuperview()
        udloadingLable.removeFromSuperview()
    }
    
    func updateLoadingViewBottomOffset(_ offset: CGFloat) {
        guard udloadingView.superview != nil else {
            return
        }
        
        self.udloadingView.snp.updateConstraints { make in
            make.centerY.equalToSuperview().offset(-offset)
        }
    }

    func getTryAgainEmptyConfig(description: String, type: UDEmptyType, tryAgainBlock: (() -> Void)? = nil) -> UDEmptyConfig {
        var emptyConfig = UDEmptyConfig(type: type)
        emptyConfig.description = .init(descriptionText: description)
        emptyConfig.primaryButtonConfig = (BundleI18n.SKResource.Bitable_Common_ButtonRetry, { _ in
            tryAgainBlock?()
        })
        
        return emptyConfig
    }
}
