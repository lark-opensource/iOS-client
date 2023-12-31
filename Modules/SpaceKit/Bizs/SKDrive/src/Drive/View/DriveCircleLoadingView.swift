//
//  DriveCircleLoadingView.swift
//  SpaceKit
//
//  Created by bupozhuang on 2019/8/25.
//

import UIKit
import SnapKit
import UniverseDesignColor
import UniverseDesignLoading
import SKCommon

class DriveCircleLoadingView: UIView {
    lazy var activity = UDLoading.spin(config: UDSpinConfig(indicatorConfig: UDSpinIndicatorConfig(size: 50, color: UDColor.primaryOnPrimaryFill), textLabelConfig: nil))

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }

    func showLoading(on view: UIView) {
        self.removeFromSuperview()
        view.addSubview(self)
        self.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        activity.reset()
    }
    func dismiss() {
        removeFromSuperview()
    }

    private func setupUI() {
        backgroundColor = .clear
        addSubview(activity)
        activity.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
    }
}


class DriveFileBlockLoadingView: UIView, DriveFileBlockLoadingProtocol {
    lazy var activity = UDLoading.spin(config: UDSpinConfig(indicatorConfig: UDSpinIndicatorConfig(size: 20, color: UDColor.N400), textLabelConfig: nil))
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }
    private func setupUI() {
        backgroundColor = UDColor.N100
        addSubview(activity)
        activity.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
    }
    
    func startAnimate() {
        activity.reset()
    }
}
