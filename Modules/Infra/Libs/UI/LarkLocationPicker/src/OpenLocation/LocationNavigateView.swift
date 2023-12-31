//
//  LocationNavigateView.swift
//  LarkChat
//
//  Created by Fangzhou Liu on 2019/6/10.
//

import UIKit
import Foundation
import MapKit
#if canImport(MAMapKit)
import MAMapKit
#endif
import SnapKit
import LarkButton
import LarkLocationPicker
import LarkPrivacySetting
import LarkUIKit
import LKCommonsLogging
import UniverseDesignToast
import RxCocoa
import RxSwift
import CoreLocation
import LarkCoreLocation
import LarkSetting
import LarkSensitivityControl

typealias LocationResources = BundleResources.LarkLocationPicker

protocol LocationNavigateViewDelegate: AnyObject {
    func navigateClicked()
    func leftItemClicked()
    func rightItemClicked(sender: UIControl)
    func locationAccessDenied()
}

final class LocationNavigateView: UIView {

    private static let logger = Logger.log(LocationNavigateView.self, category: "LarkLocationPicker.LocationNavigateView")

    private lazy var header: LocationHeaderView = {
        let view = LocationHeaderView(frame: .zero, backgroundColor: .clear)
        return view
    }()

    private lazy var footerView: LocationFooterView = {
        let view = LocationFooterView(frame: .zero, backgroundColor: UIColor.ud.bgBody)
        return view
    }()

    private lazy var centerButton: UIButton = {
        let button = TypeButton(type: .custom)
        button.setImage(LocationResources.location_center, for: .normal)
        button.setImage(LocationResources.location_center_clicked, for: .highlighted)
        return button
    }()
    /* 开启定位权限 按钮 */
    private lazy var openLocationPermissionButton = OpenLocationPermissionView(frame: .zero)

    private var leftNavItemButton: UIButton?
    private var rightNavItemButton: UIButton?
    private let disposeBag = DisposeBag()
    private var mapDataSource: MapType = .apple

    private lazy var mapView: LarkMapView = LarkMapView(frame: .zero)
    /// 定位服务FG开关
    private lazy var systemLocationFG: Bool = {
        Self.logger.info(self.locationAuth == nil ? "LocationAuthIsNil" : "LocationAutNotNil")
        return FeatureGatingManager.shared.featureGatingValue(with: "messenger.location.force_original_system_location") || self.locationAuth == nil //Global UI相关，改动成本比较高，先不修改
    }()
    /// 用LocationManager为了保证每次进入这个View
    /// 都会将中心点对准目的地位置并获取当前用户位置坐标
    private let locationManager = CLLocationManager()

    weak var delegate: LocationNavigateViewDelegate?

    private var destinationName: String
    private var destinationDescription: String
    private var destinationCoord: CLLocationCoordinate2D
    private var currentCoord: CLLocationCoordinate2D?
    private var zoomLevel: Double = 14.0

    private var isLocated: Bool = false
    /// 是否用系统默认的用户当前位置标识
    private var useDefaultAnnotation: Bool = false
    /// 根据用户当前位置判断地图服务用的是哪里的数据源，默认为苹果地图
    /// 该信息决定了是否需要进行坐标转化
    private var isAppleMap: Bool?
    private var isInternalDestination: Bool = true
    private var locationAuth: LocationAuthorization?
    private let sensitivityToken: Token
    init(frame: CGRect,
         setting: LocationSetting,
         forToken: Token = Token("LARK-PSDA-LocationNavigate-requestLocationAuthorization", type: .location),
         authorization: LocationAuthorization? = nil) {
        self.destinationName = setting.name
        self.destinationDescription = setting.description
        self.destinationCoord = setting.center
        self.zoomLevel = setting.zoomLevel
        self.useDefaultAnnotation = setting.defaultAnnotation
        self.isInternalDestination = setting.isInternal
        self.locationAuth = authorization
        sensitivityToken = forToken
        super.init(frame: frame)
        Self.logger.info("init, token \(forToken.identifier) \(forToken.type)")
        addSubview(mapView)
        self.addSubview(footerView)

        mapView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(footerView.snp.top)
            make.width.equalToSuperview()
        }
        // 如果是海外地址，切换到苹果地图
        if !self.isInternalDestination {
            mapView.switchMapToMKMapView()
        }
        mapView.delegate = self
        mapView.clipsToBounds = true
        mapView.showsCompass = false
        mapView.showsScale = false
        mapView.addSubview(header)
        header.snp.makeConstraints { make in
            make.top.equalTo(self.safeAreaLayoutGuide.snp.top)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(LocationUtils.HeaderHeight)
        }

        if self.useGPSEnable() {
            if systemLocationFG {
                Self.logger.info("LocationNavigateView,UseSystemLocation")
                locationManager.delegate = self
                useSystemRequestLocationAuthorization(manager: locationManager)
            }
            mapView.showsUserLocation = true
        } else {
            mapView.showsUserLocation = false
        }

        navButtonSetup(isCrypto: setting.isCrypto, needRightBtn: setting.needRightBtn)

        footerView.updateContent(name: destinationName, address: destinationDescription)
        footerView.navigateButton.addTarget(self, action: #selector(navigateButtonClicked), for: .touchUpInside)
        footerView.snp.makeConstraints { make in
            make.left.bottom.width.equalToSuperview()
        }

        mapView.addSubview(centerButton)
        centerButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-8.5)
            make.bottom.equalToSuperview().offset(-10)
            make.size.equalTo(LocationUtils.centerButtonSize)
        }
        centerButton.addTarget(self, action: #selector(handleClickLocateButton), for: .touchUpInside)
        /* 开启定位权限按钮 */
        mapView.addSubview(openLocationPermissionButton)
        openLocationPermissionButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(header.snp.bottom).offset(16)
        }
        openLocationPermissionButton.addTarget(self, action: #selector(handleClickGoToSetting), for: .touchUpInside)
        openLocationPermissionButton.isHidden = true
        observeOnMapDataSource()
        observeOnBecomeActive()
    }

    private func showGPSDisableToast() {
        LarkLocationAuthority.showDisableTip(on: self)
    }

    private func useGPSEnable() -> Bool {
        return LarkLocationAuthority.checkAuthority()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        mapView.removeAllannotion()
        mapView.showsUserLocation = false
        mapView.delegate = nil
        if systemLocationFG {
            locationManager.delegate = nil
        }
    }

    /// 开始请求定位权限
    public func startRequestWhenInUseAuthorization() {
        if systemLocationFG {
            return
        }
        Self.logger.info("LocationNavigateView,UseLocationModule")
        self.locationAuth?.requestWhenInUseAuthorization(forToken: sensitivityToken, complete: didChangeAuthorization)
    }

    private func observeOnBecomeActive() {
        NotificationCenter.default.rx.notification(UIApplication.didBecomeActiveNotification)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                self.startRequestWhenInUseAuthorization()
            })
            .disposed(by: disposeBag)
    }

    private func observeOnMapDataSource() {
        mapView.getMapDataSource().drive(onNext: { [weak self] (type) in
            /* 如果地图数据源为改变，则不更新UI */
            if type == self?.mapDataSource {
                return
            }
            self?.mapDataSource = type
            self?.updateAnnotation(map: type)
        }, onCompleted: nil, onDisposed: nil).disposed(by: disposeBag)
    }

    // 当地图数据源发生变化时，更新Annotation和user location
    private func updateAnnotation(map: MapType) {
        // 移除现在已有的annotation
        mapView.removeAllannotion()
        mapView.showsUserLocation = false
        let destination = self.destinationCoord
        LocationNavigateView.logger.debug(
            "[Location Navigate] Map DataSource update \(map == .amap ? "GAODE" : "TomTom") ")
        mapView.addAnnotation(annotation: LarkAnnotion(coordinate: destination, title: nil, subTitle: nil))
        mapView.setZoomLevel(zoom: self.zoomLevel, center: destination, animated: false)
        mapView.showsUserLocation = self.useGPSEnable()
    }

    private func navButtonSetup(isCrypto: Bool, needRightBtn: Bool) {
        leftNavItemButton = header.addLeftNavItem(
            icon: LocationResources.location_nav_back,
            highlighted: LocationResources.location_nav_back_highlight
        )
        if let leftBtn = leftNavItemButton {
            leftBtn.addTarget(self, action: #selector(leftNavItemClicked), for: .touchUpInside)
        }
        guard !isCrypto && needRightBtn else {
            return
        }
        rightNavItemButton = header.addRightNavItem(
            icon: LocationResources.location_more,
            highlighted: LocationResources.location_more_highlight
        )
        if let rightBtn = rightNavItemButton {
            rightBtn.addTarget(self, action: #selector(rightNavItemClicked(sender:)), for: .touchUpInside)
        }
    }

    @objc
    private func navigateButtonClicked() {
        self.delegate?.navigateClicked()
    }

    @objc
    private func leftNavItemClicked() {
        self.delegate?.leftItemClicked()
    }

    @objc
    private func rightNavItemClicked(sender: UIControl) {
        self.delegate?.rightItemClicked(sender: sender)
    }

    fileprivate func useSystemRequestLocationAuthorization(manager: CLLocationManager) {
        do {
            try LocationEntry.requestWhenInUseAuthorization(forToken: sensitivityToken, manager: manager)
        } catch let error {
            if let checkError = error as? CheckError {
                Self.logger.info("requestLocationAuthorization for locationEntry error \(checkError.description)")
            }
        }
    }

    @objc
    private func handleClickLocateButton() {
        if LarkLocationAuthority.checkAuthority() {
            func useSystemLocation() {
                switch CLLocationManager.authorizationStatus() {
                case .notDetermined:
                    useSystemRequestLocationAuthorization(manager: locationManager)
                case .denied:
                    self.delegate?.locationAccessDenied()
                default:
                    backToCurrentLocation()
                }
            }

            func useLocationModule() {
                switch locationAuth?.authorizationStatus() {
                case .notDetermined:
                    locationAuth?.requestWhenInUseAuthorization(forToken: sensitivityToken, complete: didChangeAuthorization)
                case .denied:
                    self.delegate?.locationAccessDenied()
                default:
                    backToCurrentLocation()
                }
            }

            if systemLocationFG {
                Self.logger.info("LocationNavigateView,ClickLocate,UseSystemLocation")
                useSystemLocation()
            } else {
                Self.logger.info("LocationNavigateView,ClickLocate,UseLocationModule")
                useLocationModule()
            }

        } else {
            self.showGPSDisableToast()
        }
    }

    private func backToCurrentLocation() {
        if self.mapView.userTrackingMode == .follow {
            self.mapView.setUserTrackingMode(.none, animated: true)
        } else {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(0.5 * Double(NSEC_PER_SEC)) / Double(NSEC_PER_SEC), execute: {() -> Void in
                // 因为下面这句的动画有bug，所以要延迟0.5s执行，动画由上一句产生
                self.mapView.setUserTrackingMode(.follow, animated: true)
            })
        }
        guard let currentLocation = self.currentCoord else {
            return
        }
        self.mapView.setZoomLevel(zoom: Double(self.zoomLevel), center: currentLocation)
    }

    @objc
    private func handleClickGoToSetting() {
        if let appSettings = URL(string: UIApplication.openSettingsURLString),
           UIApplication.shared.canOpenURL(appSettings) {
            UIApplication.shared.open(appSettings)
        }
    }
}

extension LocationNavigateView: CLLocationManagerDelegate {
    /// 当定位权限改变时调用
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        openLocationPermissionButton.isHidden = status != .denied
        if self.useGPSEnable() {
            switch status {
            case .denied:
                self.delegate?.locationAccessDenied()
            case .notDetermined:
                useSystemRequestLocationAuthorization(manager: locationManager)
            default: break
            }
        }
    }
}

extension LocationNavigateView {
    public func didChangeAuthorization(error: LocationAuthorizationError?) {
        guard let error = error else {
            openLocationPermissionButton.isHidden = true
            return
        }
        openLocationPermissionButton.isHidden = error != .denied
        if self.useGPSEnable() {
            switch error {
            case .denied:
                self.delegate?.locationAccessDenied()
            case .notDetermined:
                locationAuth?.requestWhenInUseAuthorization(forToken: sensitivityToken, complete: didChangeAuthorization)
            default: break
            }
        }
    }
}

extension LocationNavigateView: LarkMapViewDelegate {
    public func mapViewWillStartLocatingUser(_ mapView: LarkMapView) {
        self.mapView.setZoomLevel(zoom: Double(self.zoomLevel), center: self.destinationCoord, animated: false)
    }

    public func mapView(_ mapView: LarkMapView, failedLocate error: Error) {}

    public func mapView(_ mapView: LarkMapView, didUpdate userLocation: MKMapItemModel, updatingLocation: Bool) {
        guard self.useGPSEnable() else {
            LocationNavigateView.logger.info("[Location Navigate] GPS DISABLE BY ADMIN")
            return
        }
        let userCoor = mapView.userLocation.location
        self.currentCoord = userCoor
        self.isAppleMap = !FeatureUtils.AMapDataAvailableForCoordinate(userCoor)
        self.mapView.lookUpCurrentLocation(
            userLocation: CLLocation(latitude: userCoor.latitude, longitude: userCoor.longitude),
            completionHandler: { [weak self] (placemarks, error) in
                guard error == nil else {
                    return
                }
                if let placemark = placemarks?.first {
                    self?.isAppleMap = (placemark.isoCountryCode != "CN")
                }
            }
        )
        guard !isLocated, let isInternational = self.isAppleMap else {
            return
        }
        /// 添加目的地大头针，为了保证用户在地图上滑动缩放时大头针不跟随移动，
        /// 这里不使用ImageView, 而是使用Annotation

        self.mapView.userTrackingMode = .follow
        // 只有高德地图且为国内地址才需要转坐标系
        let destination = self.destinationCoord
#if DEBUG
        LocationNavigateView.logger.debug(
            "[Location Navigate] receive location: (\(self.destinationCoord.latitude), \(self.destinationCoord.longitude)) "
                + "pin location (\(destination.latitude), \(destination.longitude)) ")
        LocationNavigateView.logger.debug("[Location Navigate]"
                + (isInternational ? "open device at oversea " : "open device at internal ")
                + (isInternalDestination ? "location at internal " : "location at oversea ")
                + ((!isInternational && isInternalDestination) ? "GCJ-02 Coordinate " : "WGS-84 Coordinate ")
        )
#endif
        mapView.addAnnotation(annotation: LarkAnnotion(coordinate: destination, title: nil, subTitle: nil))
        self.mapView.setZoomLevel(zoom: Double(self.zoomLevel), center: self.destinationCoord)
        LarkLocationPickerUtils.stashUserLocation(location: userCoor)
        isLocated = true
    }

    /*  每次地图中心点刷新都重新查一下地图数据源 */
    public func mapView(_ mapView: LarkMapView, regionDidChangeAnimated animated: Bool) {
        if isLocated {
            observeOnMapDataSource()
        }
    }

    public func mkMapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            if !useDefaultAnnotation {
                let pin = mapView.view(for: annotation) as? MKPinAnnotationView ?? MKAnnotationView(annotation: annotation, reuseIdentifier: nil)
                pin.image = LocationResources.user_location
                return pin
            }
            return nil
        }

        let annotationIdentifier = LocationUtils.centerAnnotationIdentifier
        var annotationView: MKAnnotationView?
        if let dequeuedAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) {
            annotationView = dequeuedAnnotationView
            annotationView?.annotation = annotation
        } else {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }

        if let annotationView = annotationView {
            let pinImage = LocationResources.location_icon
            annotationView.canShowCallout = false
            annotationView.image = pinImage
            annotationView.centerOffset = CGPoint(x: 0, y: -(pinImage.size.height / 2))
        }
        return annotationView
    }

    public func mkMapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        for view in views {
            let annotation = view.annotation
            if annotation is MKUserLocation {
                view.superview?.sendSubviewToBack(view)
            }
        }
    }

    public func mkMapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
        if mode == .none {
            self.centerButton.setImage(LocationResources.location_center, for: .normal)
            self.centerButton.setImage(LocationResources.location_center_clicked, for: .highlighted)
        } else {
            self.centerButton.setImage(LocationResources.location_center_selected, for: .normal)
            self.centerButton.setImage(LocationResources.location_center_selected_clicked, for: .highlighted)
        }
    }
#if canImport(MAMapKit)
    public func maMapView(_ mapView: MAMapView, viewFor annotation: MAAnnotation) -> MAAnnotationView? {
        if annotation is MAUserLocation {
            if !useDefaultAnnotation {
                let pin = mapView.view(for: annotation) as? MAPinAnnotationView ?? MAAnnotationView(annotation: annotation, reuseIdentifier: nil)
                pin?.image = LocationResources.user_location
                return pin
            }
            return nil
        }

        let annotationIdentifier = LocationUtils.centerAnnotationIdentifier
        var annotationView: MAAnnotationView?
        if let dequeuedAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) {
            annotationView = dequeuedAnnotationView
            annotationView?.annotation = annotation
        } else {
            annotationView = MAAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }

        if let annotationView = annotationView {
            let pinImage = LocationResources.location_icon
            annotationView.canShowCallout = false
            annotationView.image = pinImage
            annotationView.centerOffset = CGPoint(x: 0, y: -(pinImage.size.height / 2))
        }
        return annotationView
    }

    public func maMapView(_ mapView: MAMapView, didAdd views: [MAAnnotationView]) {
        for view in views {
            let annotation = view.annotation
            if annotation is MAUserLocation {
                view.superview?.sendSubviewToBack(view)
            }
        }
    }

    public func maMapView(_ mapView: MAMapView, didChange mode: MAUserTrackingMode, animated: Bool) {
        if mode == .none {
            self.centerButton.setImage(LocationResources.location_center, for: .normal)
            self.centerButton.setImage(LocationResources.location_center_clicked, for: .highlighted)
        } else {
            self.centerButton.setImage(LocationResources.location_center_selected, for: .normal)
            self.centerButton.setImage(LocationResources.location_center_selected_clicked, for: .highlighted)
        }
    }
#endif
}

extension LocationNavigateView {
    public func viewWillRotated(to size: CGSize) {
        mapView.removeAllannotion()
        mapView.showsUserLocation = false
    }

    public func viewDidRotated(to size: CGSize) {
        self.mapView.showsUserLocation = self.useGPSEnable()
        // 只有高德地图且为国内地址才需要转坐标系
        guard let isInternational = self.isAppleMap else {
            return
        }
//        let destination = (!isInternational && isInternalDestination) ? FeatureUtils.convertWGS84ToGCJ02(coordinate: self.destinationCoord) : self.destinationCoord
        let destination = self.destinationCoord
        let annotationPin = LarkAnnotion(coordinate: destination, title: nil, subTitle: nil)
        self.mapView.addAnnotation(annotation: annotationPin)
        self.mapView.setZoomLevel(zoom: Double(self.zoomLevel), center: destination, animated: false)
    }
}
