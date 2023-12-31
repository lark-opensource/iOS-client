//
//  SceneListLoadingView.swift
//  LarkAI
//
//  Created by 李勇 on 2023/10/9.
//

import Foundation
import UIKit
import UniverseDesignLoading // UDLoading

/// 进入我的场景时，首屏加载数据的loading
final class SceneListLoadingView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        // loadingView上下间距并不是相等的，我们这里搞一个上面的视图做比例约束
        let topLineView = UIView()
        self.addSubview(topLineView)
        topLineView.snp.makeConstraints { make in
            make.width.equalTo(1)
            make.centerX.equalTo(self)
            make.top.equalTo(self)
            make.height.equalTo(self).multipliedBy(148.0 / 596.0)
        }
        // 添加一个loadingImage
        let loadingImage = UDLoadingImageView(lottieResource: nil)
        self.addSubview(loadingImage)
        loadingImage.snp.makeConstraints { make in
            make.width.height.equalTo(125)
            make.centerX.equalTo(self)
            make.top.equalTo(topLineView.snp.bottom)
        }
        // 添加title
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = UIColor.ud.textCaption
        titleLabel.text = BundleI18n.LarkAI.MyAI_Scenario_MyScenarios_Loading_EmptyState
        self.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(loadingImage.snp.bottom).offset(16)
            make.centerX.equalTo(self)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func addTo(view: UIView) {
        view.addSubview(self)
        self.snp.makeConstraints { make in
            make.top.left.equalTo(view)
            make.width.height.equalTo(view)
        }
    }
}
