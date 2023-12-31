//
//  ZoomCommonPlaceholderView.swift
//  Calendar
//
//  Created by pluto on 2022/11/1.
//

import UIKit
import Foundation
import UniverseDesignEmpty
import LarkUIKit

// 通用加载页
final class ZoomCommonPlaceholderView: UIView {

    private lazy var loadingView: LoadingPlaceholderView = {
        let view = LoadingPlaceholderView(frame: .zero)
        view.isHidden = false
        view.text = I18n.Calendar_Edit_FindTimeLoading
        view.backgroundColor = .clear
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = EventEditUIStyle.Color.viewControllerBackground

        addSubview(loadingView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func layoutNaviOffsetStyle() {
        loadingView.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview().offset(-56)
            maker.height.equalTo(150)
            maker.width.centerX.equalToSuperview()
        }
    }

    func layoutFullScreenStyle() {
        loadingView.snp.makeConstraints { maker in
            maker.height.equalTo(150)
            maker.center.equalToSuperview()
            maker.width.equalToSuperview()
        }
    }

}
