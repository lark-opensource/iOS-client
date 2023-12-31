//
//  IndicatorLoadingView.swift
//  Calendar
//
//  Created by heng zhu on 2019/1/14.
//  Copyright © 2019 EE. All rights reserved.
//

import Foundation
import CalendarFoundation
import UIKit

public final class IndicatorLoadingView: UIView {
    private let loadingWrapper: UIView = UIView()
    private var indicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView()
        view.style = .gray
        view.color = UIColor.ud.primaryContentDefault
        return view
    }()

    private var infoLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.Calendar.Calendar_Common_LoadingCommon
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private func layout(wrapper: UIView, in superView: UIView) {
        // 容器
        superView.addSubview(wrapper)
        wrapper.snp.makeConstraints({ make in
            make.centerX.equalToSuperview()
            make.top.bottom.equalToSuperview()
        })
    }

    private func layout(indicator: UIView, in superView: UIView) {
        superView.addSubview(indicator)
        indicator.snp.makeConstraints({ make in
            make.left.equalToSuperview()
            make.top.bottom.equalTo(6)
        })
    }

    private func layout(infoLabel: UIView, in superView: UIView) {
        superView.addSubview(infoLabel)
        infoLabel.snp.makeConstraints({ make in
            make.left.equalTo(indicator.snp.right).offset(4)
            make.right.equalToSuperview()
            make.centerY.equalTo(indicator)
        })
    }

    public init() {
        super.init(frame: CGRect.zero)
        layout(wrapper: loadingWrapper, in: self)
        layout(indicator: indicator, in: loadingWrapper)
        layout(infoLabel: infoLabel, in: loadingWrapper)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func show() {
        self.isHidden = false
        self.indicator.startAnimating()
    }

    public func hide() {
        self.indicator.stopAnimating()
        self.isHidden = true
    }
}
