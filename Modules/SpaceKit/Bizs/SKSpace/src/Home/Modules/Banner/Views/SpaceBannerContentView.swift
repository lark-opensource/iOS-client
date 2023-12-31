//
//  SpaceBannerContentView.swift
//  SKECM
//
//  Created by Weston Wu on 2020/12/2.
//

import Foundation
import SKUIKit

protocol SpaceBannerContentView: UIView {
    func calculateEstimateHeight(containerWidth: CGFloat) -> CGFloat
}


/// 用于遵守SpaceBannerContentView协议，并且封装LarkBanner模块传入的view
class SpaceBannerContainerView: UIView, SpaceBannerContentView {

    var contentHeight: CGFloat = 0
    init(contentView: UIView, contentHight: CGFloat) {
        super.init(frame: .zero)
        self.contentHeight = contentHight
        addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            make.left.top.right.bottom.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func calculateEstimateHeight(containerWidth: CGFloat) -> CGFloat {
        return contentHeight
    }
}
