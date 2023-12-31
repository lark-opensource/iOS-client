//
//  ChooseLocationViewController.swift
//  LarkLocationPicker
//
//  Created by aslan on 2022/3/25.
//

import UIKit
import Foundation
import LarkUIKit
import LarkContainer
import LKCommonsLogging
import EENavigator
import SnapKit
import UniverseDesignToast
import UniverseDesignDialog
import CoreLocation
import LarkCoreLocation
import LarkSensitivityControl
import LarkSetting

open class ChooseLocationViewController: BaseUIViewController {
    private static let logger = Logger.log(ChooseLocationViewController.self, category: "LarkLocationPicker.ChooseLocationViewController")

    private(set) lazy var locationPicker: LocationPickerView = {
        let view = LocationPickerView(forToken: self.sensitivityToken,
                                      location: "", allowCustomLocation: false,
                                      defaultAnnotation: true, useWGS84: true,
                                      authorization: self.authorization,
                                      failLocateToastText: self.failToLocateToastText)
        return view
    }()

    private lazy var sendItem: UIBarButtonItem = {
        let btnItem = LKBarButtonItem(
            title: BundleI18n.LarkLocationPicker.Lark_Legacy_SendToUser,
            fontStyle: .medium
        )
        btnItem.setProperty(alignment: .right)
        btnItem.setBtnColor(color: UIColor.ud.primaryContentDefault)
        btnItem.button.setTitleColor(UIColor.ud.primaryContentDefault.withAlphaComponent(0.4), for: .disabled)
        btnItem.button.addTarget(self, action: #selector(sendBtnClicked), for: .touchUpInside)
        return btnItem
    }()

    private lazy var backItem: UIBarButtonItem = {
        let btnItem = LKBarButtonItem(image: BundleResources.LarkLocationPicker.nav_back)
        btnItem.setProperty(font: UIFont.systemFont(ofSize: 16))
        btnItem.setBtnColor(color: UIColor.ud.N900)
        btnItem.button.addTarget(self, action: #selector(backBtnClicked), for: .touchUpInside)
        return btnItem
    }()

    // 发送回调，第一个String是地图Type，第二个String是选择地址的位置（这两个String都用于打点需求）
    public var sendLocationCallBack: ((ChooseLocation) -> Void)?
    public var cancelCallBack: (() -> Void)?
    public var authorization: LocationAuthorization?
    private let sensitivityToken: Token
    /// 地图服务定位失败提示内容
    private let failToLocateToastText: String
    public init(
        forToken: Token = Token("LARK-PSDA-LocationPicker-requestLocationAuthorization", type: .location),
        authorization: LocationAuthorization? = nil,
        failLocateToastText: String = LocationPickerView.Cons.mapViewFailedLocateToast) {
        self.authorization = authorization
        self.sensitivityToken = forToken
        self.failToLocateToastText = failLocateToastText
        super.init(nibName: nil, bundle: nil)
        Self.logger.info("init, token \(forToken.identifier) \(forToken.type)")
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        self.addCancelItem()
        self.navigationItem.rightBarButtonItem = self.sendItem
        self.view.addSubview(locationPicker)
        locationPicker.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.locationPicker.locationSearchTappedCallBack = { [weak self] in
            self?.navigationItem.leftBarButtonItem = self?.backItem
            self?.navigationItem.rightBarButtonItem = nil
        }
        self.locationPicker.locationDidSelectedFromSearchCallBack = { [weak self] in
            self?.addCancelItem()
            self?.sendItem.isEnabled = (self?.getCurrentLocationData() != nil)
            self?.navigationItem.rightBarButtonItem = self?.sendItem
        }
        self.locationPicker.locationServiceDisabledCallBack = { [weak self] in
            guard let self = self else {
                assertionFailure()
                return
            }
            let dialog = UDDialog.noPermissionDialog(title: BundleI18n.LarkLocationPicker.Lark_Core_LocationAccess_Title,
                                                     detail: BundleI18n.LarkLocationPicker.Lark_Core_LocationAccess_Desc())
            Navigator.shared.present(dialog, from: self) //Global 基础组件，成本有些高，风险不大，先不迁移
        }
        self.locationPicker.startRequestWhenInUseAuthorization()
    }

    private func getCurrentLocationData() -> LocationData? {
        return self.locationPicker.selectedLocation()
    }

    @objc
    open override func closeBtnTapped() {
        if FeatureGatingManager.shared.featureGatingValue(with: "core.location.choose.callback.optimize") { //Global UI相关，改动成本比较高，先不修改
            Self.logger.info("choose location callback optimize")
            self.dismiss(animated: true, completion: { [weak self] in
                self?.cancelCallBack?()
            })
        } else {
            super.closeBtnTapped()
            self.cancelCallBack?()
            self.dismiss(animated: true, completion: nil)
        }
    }

    @objc
    private func backBtnClicked() {
        self.locationPicker.hideSearchTable()
    }

    @objc
    private func sendBtnClicked() {
        /// 显示Toast
        let hud = UDToast.showLoading(
            with: BundleI18n.LarkLocationPicker.Lark_Chat_MessageLocationSending,
            on: self.view,
            disableUserInteraction: true
        )
        self.sendItem.isEnabled = false
        self.locationPicker.doScreenShot(size: LocationUtils.screenShotImageSize, screenShotHandler: { [weak self] (image) -> Void in
            guard let `self` = self else { return }
            let zoom = self.locationPicker.getZoomLevel()

            guard let location = self.getCurrentLocationData() else {
                Self.logger.error("[Choose location]：failed, could not get current location")
                hud.showFailure(with: BundleI18n.LarkLocationPicker.Lark_Chat_MessageLocationSendFailed, on: self.view)
                self.sendItem.isEnabled = true
                return
            }

            guard let screenshot = image else {
                Self.logger.error("[Choose location]：failed, could not get current location screeshot")
                hud.showFailure(with: BundleI18n.LarkLocationPicker.Lark_Chat_MessageLocationSendFailed, on: self.view)
                self.sendItem.isEnabled = true
                return
            }

            let model = ChooseLocation(
                name: location.name,
                address: location.address,
                location: location.location,
                zoomLevel: zoom,
                isInternal: location.isInternal,
                image: screenshot,
                mapType: self.locationPicker.getMapType().rawValue,
                selectType: self.locationPicker.getSelectionType().rawValue
            )
            self.sendLocationCallBack?(model)
            hud.showSuccess(with: BundleI18n.LarkLocationPicker.Lark_Legacy_ApplicationPhoneCallTimeCardSendSuccess, on: self.view)
            self.dismiss(animated: true, completion: nil)
        })
    }

    // MARK: - 屏幕旋转适配
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self] (_) in
            self?.locationPicker.viewWillRotated(to: size)
        }) { [weak self] (_) in
            self?.locationPicker.viewDidRotated(to: size)
        }
    }
}
