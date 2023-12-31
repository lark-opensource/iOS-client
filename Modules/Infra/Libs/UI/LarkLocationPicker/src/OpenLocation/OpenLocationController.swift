//
//  OpenLocationController.swift
//  LarkLocationPicker
//
//  Created by aslan on 2022/3/25.
//

import UIKit
import Foundation
import CoreLocation
import LarkUIKit
import LKCommonsLogging
import EENavigator
import RxSwift
import SnapKit
import UniverseDesignToast
import UniverseDesignDialog
import LarkCoreLocation
import LarkSensitivityControl

typealias I18N = BundleI18n.LarkLocationPicker

open class OpenLocationController: BaseUIViewController, LocationNavigateViewDelegate {
    private lazy var locationView: LocationNavigateView = {
        return LocationNavigateView(
            frame: .zero,
            setting: self.setting,
            forToken: self.sensitivityToken,
            authorization: self.locationAuth
        )
    }()
    private let disposeBag: DisposeBag = DisposeBag()
    private static let logger = Logger.log(OpenLocationController.self, category: "LarkLocationPicker.OpenLocationController")
    private let setting: LocationSetting
    private var locationAuth: LocationAuthorization?
    private let sensitivityToken: Token
    public init(
        forToken: Token = Token("LARK-PSDA-LocationNavigate-requestLocationAuthorization", type: .location),
        setting: LocationSetting,
        authorization: LocationAuthorization? = nil) {
        self.sensitivityToken = forToken
        self.setting = setting
        self.locationAuth = authorization
        super.init(nibName: nil, bundle: nil)
        Self.logger.info("init, token \(forToken.identifier) \(forToken.type)")
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.isNavigationBarHidden = true
        self.view.addSubview(locationView)
        locationView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        locationView.delegate = self
        locationView.startRequestWhenInUseAuthorization()
    }

    // MARK: - 屏幕旋转适配
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        locationView.viewWillRotated(to: size)
        coordinator.animate(alongsideTransition: { [weak self] (_) in
            self?.locationView.viewWillRotated(to: size)
        }) { [weak self] (_) in
            self?.locationView.viewDidRotated(to: size)
        }
    }

    func locationAccessDenied() {
        let dialog = UDDialog.noPermissionDialog(title: I18N.Lark_Core_LocationAccess_Title,
                                                 detail: I18N.Lark_Core_LocationAccess_Desc())
        Navigator.shared.present(dialog, from: self) //Global 基础组件，成本有些高，风险不大，先不迁移
    }

    open func leftItemClicked() {
        self.navigationController?.popViewController(animated: true)
    }

    open func rightItemClicked(sender: UIControl) {}

    open func navigateClicked() {
        LarkLocationPickerUtils.showMapSelectionSheet(from: self,
                                                      isInternal: self.setting.isInternal,
                                                      locationName: self.setting.name,
                                                      latitude: self.setting.center.latitude,
                                                      longitude: self.setting.center.longitude)
    }
}
