//
//  LarkViewComponent.swift
//  LarkLocationPicker
//
//  Created by Fangzhou Liu on 2019/7/23.
//

import UIKit
import Foundation
import LarkUIKit
import MapKit
import RxCocoa
import SnapKit
import CoreLocation
import LKCommonsLogging
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignShadow
import UniverseDesignEmpty

/// 截图的默认区域范围，由经纬度的变化值来确定（zoomLevel = 14.5)
struct MapConsts {
    static let deltaLatitude = 0.013
    static let deltaLongitude = 0.025
    static let defaultZoomLevel = 14.5
}

// MARK: - 加载页
final class LoadingProgressView: UIView {
    private lazy var hintLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.N500
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        return label
    }()

    private let loadingView = UIImageView(image: BundleResources.LarkLocationPicker.loading)

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(loadingView)
        self.addSubview(hintLabel)
        loadingView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.centerY.equalTo(hintLabel.snp.centerY)
            make.size.equalTo(CGSize(width: 12, height: 12))
        }
        hintLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(12)
            make.left.equalTo(loadingView.snp.right).offset(6)
            make.bottom.right.equalToSuperview()
        }
        self.isHidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func showLoadingProgressLayer() {
        self.isHidden = false
        hintLabel.text = BundleI18n.LarkLocationPicker.Lark_Legacy_LoadingTip
        loadingView.lu.addRotateAnimation()
    }

    public func hideLoadingPorgressLayer() {
        self.isHidden = true
    }

    public func showLoadingFailedLayer() {
        hintLabel.text = BundleI18n.LarkLocationPicker.Lark_Legacy_LoadingFailed
        loadingView.lu.removeRotateAnimation()
    }
}

final class NoSearchResultIconView: UIView {

    private let iconView = UIImageView(image: EmptyBundleResources.image(named: "emptyNeutralSearchFailed"))

    public lazy var hintLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.LarkLocationPicker.Lark_Core_MapServicesErrorMessage_NoLocationsFound
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = UIColor.ud.N600
        return label
    }()

    init(frame: CGRect, showIcon: Bool = true, showHint: Bool = true) {
        super.init(frame: frame)
        self.addSubview(iconView)
        self.addSubview(hintLabel)
        iconView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(
                -(iconView.frame.size.height / 2)
            )
        }
        iconView.isHidden = !showIcon

        hintLabel.snp.makeConstraints { (make) in
            make.top.equalTo(iconView.snp.bottom).offset(10)
            make.centerX.equalToSuperview()
        }
        hintLabel.isHidden = !showHint
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setLabelProperty(
        text: String = BundleI18n.LarkLocationPicker.Lark_Core_MapServicesErrorMessage_NoLocationsFound,
        fontSize: CGFloat = 16,
        color: UIColor = UIColor.ud.N600) {
        self.hintLabel.text = text
        self.hintLabel.font = UIFont.systemFont(ofSize: fontSize, weight: .regular)
        self.hintLabel.textColor = color
    }
}

public final class OpenLocationPermissionView: UIControl {
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.text = BundleI18n.LarkLocationPicker.Lark_Core_EnableLocationAccess_Button
        return label
    }()
    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.primaryContentDefault
        layer.cornerRadius = 14
        layer.ud.setShadow(type: .s5Down)
        let rightIcon = UDIcon.getIconByKey(.rightBoldOutlined,
                                            iconColor: UIColor.ud.primaryContentDefault,
                                            size: CGSize(width: 12, height: 12))
        let iconView = UIImageView(image: rightIcon)
        let iconBackgroundView = UIView()
        iconBackgroundView.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        iconBackgroundView.layer.cornerRadius = 9

        iconBackgroundView.addSubview(iconView)
        addSubview(iconBackgroundView)
        addSubview(titleLabel)

        iconView.snp.makeConstraints {
            $0.width.height.equalTo(12)
            $0.center.equalToSuperview()
        }
        iconBackgroundView.snp.makeConstraints {
            $0.trailing.equalTo(-5)
            $0.top.equalTo(5)
            $0.bottom.equalTo(-5)
            $0.leading.equalTo(titleLabel.snp.trailing).offset(4)
            $0.width.height.equalTo(18)
        }
        titleLabel.snp.makeConstraints {
            $0.centerY.equalTo(iconBackgroundView)
            $0.leading.equalTo(12)
        }
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
