//
//  LarkLocationPickerView.swift
//  LarkLocationPicker
//
//  Created by Fangzhou Liu on 2019/7/9.
//

import UIKit
import Foundation
import SnapKit
import MapKit
#if canImport(MAMapKit)
import MAMapKit
#endif
import Reachability
import RxSwift
import RxCocoa
import RxDataSources
import LKCommonsTracker
import Homeric
import LKCommonsLogging
import UniverseDesignToast
import LarkPrivacySetting
import LarkCoreLocation
import LarkSetting
import LarkSensitivityControl

public final class LocationPickerView: UIView {
    private static let logger = Logger.log(LocationPickerView.self, category: "LocationPicker.LocationPickerView")

    private let disposeBag = DisposeBag()
    /* 搜索框 */
    private let topPanel: LocationTopPanel
    /* 地图 */
    private let mapView: LarkMapView
    /* 地图下方的地址列表 */
    private let tableView = UITableView()
    /* 顶部加载 */
    private var loadingHeader = LoadingProgressView(frame: .zero)
    /* 底部加载 */
    private var loadingFooter = LoadingProgressView(frame: .zero)
    /* 无结果 */
    private let emptyIndicator = UILabel(frame: .zero)
    /* 没有更多结果 */
    private let noMoreResultIcon = UILabel(frame: .zero)
    /* 回到当前位置按钮 */
    private lazy var currentLocationButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(BundleResources.LarkLocationPicker.location_center, for: .normal)
        button.setImage(BundleResources.LarkLocationPicker.location_center_clicked, for: .highlighted)
        return button
    }()
    /* 开启定位权限 按钮 */
    private lazy var openLocationPermissionButton = OpenLocationPermissionView(frame: .zero)

    /// 地图中心点对应的location数据
    private var userCoordinate: CLLocationCoordinate2D?
    /// 用户选择的位置
    private var userSelectedLocation: LocationData?

    private let locationManager = CLLocationManager()

    private var useDefaultAnnotation: Bool = false

    private var isMapViewRegionChangedFromTableView: Bool = false
    private var isMapViewRegionChangedFromScroll: Bool = false

    /// 保证只在第一次更新地图位置的时候更新用户当前位置
    private var didUpdateInitLocation: Bool = false

    private let viewModel = LocationPickerViewModel()
    /* 防止多次刷新 */
    private var isRefreshing: Bool = false

#if canImport(MAMapKit)
    private var mapType: MapType = .amap
    private var mapDataSource: MapType = .amap
#else
    private var mapType: MapType = .apple
    private var mapDataSource: MapType = .apple
#endif

    private var useWGS84: Bool = false
    /// 定位服务FG开关
    private lazy var systemLocationFG: Bool = {
        Self.logger.info(self.locationAuth == nil ? "LocationAuthIsNil" : "LocationAutNotNil")
        return FeatureGatingManager.shared.featureGatingValue(with: "messenger.location.force_original_system_location") || self.locationAuth == nil //Global UI相关，改动成本比较高，先不修改
    }()
    /// 定位服务提示优化关闭FG
    private lazy var closeFailLocationToastOptimizeFG: Bool = {
        return FeatureGatingManager.shared.featureGatingValue(with: "ios.location.close.fail.location.toast.optimize") //Global UI相关，改动成本比较高，先不修改
    }()
    /// 点击搜索栏后右上的发送按钮需要消失
    public var locationSearchTappedCallBack: (() -> Void)?
    public var locationDidSelectedFromSearchCallBack: (() -> Void)?
    public var locationServiceDisabledCallBack: (() -> Void)?
    public var locationAuth: LocationAuthorization?
    private let sensitivityToken: Token
    /// 地图服务定位失败提示内容
    private let failToLocateToastText: String
    @available(*, deprecated, message: "numCells varialbe will be deprecated")
    public init(
        forToken: Token = Token("LARK-PSDA-LocationPicker-requestLocationAuthorization", type: .location),
        location: String = "",
        allowCustomLocation: Bool,
        customLocationName: String = "",
        numCells: Double = 5.0,
        defaultAnnotation: Bool = false,
        useWGS84: Bool = false,
        authorization: LocationAuthorization? = nil,
        failLocateToastText: String = Cons.mapViewFailedLocateToast
        ) {
        sensitivityToken = forToken
        locationAuth = authorization
        failToLocateToastText = failLocateToastText
        topPanel = LocationTopPanel(location: location, allowCustomLocation: allowCustomLocation, useWGS84: useWGS84)
        didUpdateInitLocation = true
        mapView = LarkMapView(frame: .zero, centerPinImage: BundleResources.LarkLocationPicker.location_icon)
        super.init(frame: CGRect.zero)
        LocationPickerView.logger.info("init, allowCustomLocation: \(allowCustomLocation),token \(forToken.identifier) \(forToken.type)")
        addSubview(tableView)
        addSubview(mapView)
        addSubview(topPanel)

        /* 搜索框 */
        topPanel.locationSearchTappedBlock = { [weak self] in
            Tracker.post(TeaEvent(Homeric.MESSAGE_LOCATION_SEARCH_BAR_CLICK, params: [:]))
            self?.loadingHeader.isHidden = true     // 防止在主页面没有加载完成的时候点击搜索框，如果不隐藏会在底部显示出小菊花
            self?.locationSearchTappedCallBack?()
        }
        topPanel.locationPanelDidSelectLocationBlock = { [weak self] (locationData) in
            self?.viewModel.searchedLocation = locationData
            if locationData.isSelected {
                self?.viewModel.selectedType = .search
            }
            LocationPickerView.logger.info("Selected Search Result")
            // 搜索点击后，中心点跳转没有动画
            self?.userDidSelectLocation(locationData, animated: false)
            self?.locationDidSelectedFromSearchCallBack?()
        }
        topPanel.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        /* 地图下方的地址列表 */
        tableView.delegate = self
        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: LarkLocationPickerUtils.mapMaxHeight, left: 0, bottom: 0, right: 0)
        tableView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(52.5)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().priority(.low)
        }
        tableView.register(LarkLocationCell.self, forCellReuseIdentifier: LarkLocationPickerUtils.locationCellID)

        /* 地图 */
        mapView.delegate = self
        mapView.clipsToBounds = true
        mapView.distanceFilter = kCLLocationAccuracyKilometer
        mapView.showsCompass = false
        mapView.showsScale = false
        mapView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.width.equalToSuperview()
            make.top.equalTo(tableView.snp.top)
            make.height.equalTo(LarkLocationPickerUtils.mapMaxHeight)
        }

        if self.useGPSEnable() {
            mapView.showsUserLocation = true
            if systemLocationFG {
                Self.logger.info("LocationPickerView,UseSystemLocation")
                locationManager.delegate = self
                useSystemRequestLocationAuthorization(manager: locationManager)
            }
        } else {
            mapView.showsUserLocation = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.showGPSDisableToast()
            }
        }

        /* 回到当前位置按钮 */
        mapView.addSubview(currentLocationButton)
        currentLocationButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-8.5)
            make.bottom.equalToSuperview().offset(-6)
            make.size.equalTo(CGSize(width: 64, height: 69))
        }
        currentLocationButton.addTarget(self, action: #selector(handleClickLocateButton), for: .touchUpInside)
        /* 开启定位权限按钮 */
        mapView.addSubview(openLocationPermissionButton)
        openLocationPermissionButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(16)
        }
        openLocationPermissionButton.addTarget(self, action: #selector(handleClickGoToSetting), for: .touchUpInside)
        openLocationPermissionButton.isHidden = true
        /* 加载中... 小菊花 */
        initLoadingHeader()
        initLoadingFooter()

        /* 没有结果Label */
        tableView.addSubview(emptyIndicator)
        emptyIndicator.text = BundleI18n.LarkLocationPicker.Lark_Core_MapServicesErrorMessage_NoPlacemarksFound
        emptyIndicator.textColor = UIColor.ud.N500
        emptyIndicator.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        emptyIndicator.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(12)
            make.centerX.equalToSuperview()
        }
        self.useDefaultAnnotation = defaultAnnotation

        self.useWGS84 = useWGS84
        viewModel.setCoordinateSystem(useWGS84: useWGS84)

        if allowCustomLocation, !customLocationName.isEmpty {
            viewModel.searchedLocation = MKMapItemModel(name: customLocationName)
        }

        bindViewModel()
        observeOnBecomeActive()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        if systemLocationFG {
            locationManager.delegate = nil
        }
        mapView.showsUserLocation = false
    }

    /// 开始请求定位权限
    public func startRequestWhenInUseAuthorization() {
        if systemLocationFG {
            return
        }
        Self.logger.info("LocationPickerView,UseLocationModule")
        locationAuth?.requestWhenInUseAuthorization(forToken: sensitivityToken, complete: didChangeAuthorization)
    }

    private func showGPSDisableToast() {
        LarkLocationAuthority.showDisableTip(on: self)
    }

    private func useGPSEnable() -> Bool {
        return LarkLocationAuthority.checkAuthority()
    }

    private func initLoadingHeader() {
        /* 加载中... 小菊花 */
        addSubview(loadingHeader)
        loadingHeader.snp.makeConstraints { (make) in
            make.top.equalTo(mapView.snp.bottom)
            make.centerX.equalToSuperview()
        }
    }

    private func initLoadingFooter() {
        /* 加载更多... 小菊花 */
        let view = UIView(
            frame: CGRect(x: 0, y: 0, width: 0, height: LarkLocationPickerUtils.footerHeight)
        )
        view.addSubview(loadingFooter)
        view.addSubview(noMoreResultIcon)
        loadingFooter.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
        }
        noMoreResultIcon.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        noMoreResultIcon.text = BundleI18n.LarkLocationPicker.Lark_Legacy_SearchNoMoreResult
        noMoreResultIcon.textColor = UIColor.ud.N500
        noMoreResultIcon.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        tableView.tableFooterView = view
    }

    private func bindViewModel() {
        // 创建数据源
        let dataSource = RxTableViewSectionedReloadDataSource
            <SectionModel<Int, UILocationData>>(configureCell: { [weak self] (_, tableView, indexPath, element) in
                let cell = tableView.dequeueReusableCell(withIdentifier: LarkLocationPickerUtils.locationCellID)
                if let cell = cell as? LarkLocationCell, let `self` = self {
                    cell.setContent(location: element, distance: LarkLocationPickerUtils.calculateDistance(
                        from: self.userCoordinate,
                        to: element.location), isSelect: (self.viewModel.selectedIndexPath == indexPath), isCurrent: (indexPath.section == 0)
                    )
                    return cell
                }
                return LarkLocationCell()
            })

        // 搜索结果变化后更新列表
        viewModel.searchResult
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)

        /*  绑定点击事件 */
        tableView.rx
            .itemSelected
            .map { [weak self] (indexPath) -> (IndexPath?, LocationData?) in
                guard let dataSource = self?.viewModel.searchResult.value,
                    dataSource.count > indexPath.section,
                    dataSource[indexPath.section].items.count > indexPath.row
                    else { return (nil, nil) }
                return (indexPath, dataSource[indexPath.section].items[indexPath.row])
            }
            .subscribe(onNext: { [weak self] (indexPath, model) in
                guard let indexPath = indexPath else { return }
                Tracker.post(TeaEvent(Homeric.MESSAGE_LOCATION__SUGG_CLICK, params: [:]))
                LocationPickerView.logger.info("Selected Around Result")
                self?.didSelectCell(in: indexPath, model: model)
            })
            .disposed(by: disposeBag)

        viewModel.state.asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] state in
                self?.updateUI(state: state)
            }, onError: { (error) in
                print(String(describing: error))
            }).disposed(by: disposeBag)

        observeOnMapDataSource()
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
        /* 坐标系更新后，重新设置地图中心 */
        mapView.getVendorDriver().drive(onNext: { [weak self] (datasource: MapType) in
            /* 如果数据源没有改变，则不对UI进行更新 */
            self?.updateCoordinateSystem(type: datasource)
            if self?.mapDataSource == datasource {
                return
            }
            self?.mapDataSource = datasource
        }).disposed(by: disposeBag)
    }

    private func updateUI(state: StateWrapper) {
        switch state.state {
        case .initial:
            emptyIndicator.isHidden = true
            noMoreResultIcon.isHidden = true
            loadingHeader.hideLoadingPorgressLayer()
            footerEndRefreshing()
            LocationPickerView.logger.info("Update UI By initial")
        case .search:
            emptyIndicator.isHidden = true
            noMoreResultIcon.isHidden = true
            loadingHeader.showLoadingProgressLayer()
            footerEndRefreshing()
            LocationPickerView.logger.info("Update UI By search")
        case .result:
            emptyIndicator.isHidden = true
            noMoreResultIcon.isHidden = true
            loadingHeader.hideLoadingPorgressLayer()
            footerEndRefreshing()
            LocationPickerView.logger.info("Update UI By result")
        case .resultMore:
            emptyIndicator.isHidden = true
            noMoreResultIcon.isHidden = true
            footerStartRefreshing()
            LocationPickerView.logger.info("Update UI By resultMore")
        case .empty:
            if state.isFirstPage {
                emptyIndicator.isHidden = true
                noMoreResultIcon.isHidden = true
            } else {
                emptyIndicator.isHidden = true
                noMoreResultIcon.isHidden = false
            }
            loadingHeader.hideLoadingPorgressLayer()
            footerEndRefreshing()
            LocationPickerView.logger.info("Update UI By empty")
        case .error:
            var toast: String = BundleI18n.LarkLocationPicker.Lark_Core_MapServicesErrorMessage_UnableToFetchLocationsRetry
            let reach = Reachability()
            if reach?.connection == .none {
                // network problem
                toast = BundleI18n.LarkLocationPicker.Lark_Core_MapServicesErrorMessage_NetworkErrorRetry
            }
            UDToast.showFailure(with: toast, on: self)
            if state.isFirstPage {
                emptyIndicator.isHidden = true
                noMoreResultIcon.isHidden = true
            } else {
                emptyIndicator.isHidden = true
                noMoreResultIcon.isHidden = false
            }
            loadingHeader.hideLoadingPorgressLayer()
            footerEndRefreshing()
            LocationPickerView.logger.info("Update UI By error")
        case .hint, .hintResult:    // 只有关键字搜索才需要这两个状态，POI搜索不需要
            break
        }
    }

    /* 数据源更新，更新坐标系 */
    private func updateCoordinateSystem(type: MapType) {
        self.mapView.showsUserLocation = false
        /// 通过mapView获取的坐标是已经根据国内国际做了坐标系转化的，可以直接使用
        /// 通过CoreLocation定位获得的坐标是WGS-84坐标，需要转化
        let center = self.mapView.centerCoordinate
        self.mapView.setCenter(center, animated: false)
        self.mapView.showsUserLocation = self.useGPSEnable()
        self.updateMapType(type)
        switch type {
        case .amap:
            LocationPickerView.logger.info("Update Coordinate System By Amap")
        case .apple:
            LocationPickerView.logger.info("Update Coordinate System By apple")
        }
    }

    private func userDidSelectLocation(_ locationData: LocationData, animated: Bool = true) {
        self.viewModel.defaultUserLocation = locationData
        /* 不是自定义位置才允许中心点跳转 */
        if locationData.location.latitude != CLLocationDegrees(360.0)
            && locationData.location.longitude != CLLocationDegrees(360.0) {
            /*
            定位转化开关打开 （所有地理位置坐标统一为WGS-84坐标）
            1. 地图数据源为高德（国内GCJ, 国外WGS）：
                1. 国内的地理位置需要进行WGS-84 -> GCJ-02转化
                2. 国外的地理位置直接显示
            2. 地图数据源为TomTom（国内国外都为WGS）：
                1. 地理位置直接显示
            定位转化开关关闭（国外为WGS-84坐标，国内为GCJ-02坐标）
            1. 地图数据源为高德（国内GCJ, 国外WGS）：
                1. 国内的地理位置直接显示
                2. 国外的地理位置直接显示
            2. 地图数据源为TomTom（国内国外都为WGS）：
                1. 国内地理位置需要进行GC-02 -> WGS-84转化
                2. 国外地理位置直接显示

            对应的变量：
             数据源:        self.mapDataSource  (.apple: TomTom, .amap: 高德)
             用户位置:      self.mapType        (.apple: 国外, .amap: 国内)
             地理位置:      isInternal          (false: 国外, true: 国内)
             定位转化开关:   useWGS              (false: 不转化, true: 转化)
            */
            var center: CLLocationCoordinate2D?
            if useWGS84 && self.mapDataSource == .amap && locationData.isInternal {
                center = locationData.location
            } else if self.mapDataSource == .apple && locationData.isInternal && !useWGS84 {
                // GCJ-02 -> WGS-84
                // center = CoordinateConverter.convertGCJ02ToWGS84(coordinate: locationData.location)
                // Note: 由于合规问题，这里不能再使用转化算法！之所以不删代码，是为了警示！原地址展示，已告知PM影响！
                center = locationData.location
            }
            self.mapView.setCenter(center ?? locationData.location, animated: animated)
        }
        self.locationDidSelectedFromSearchCallBack?()
    }

    private func jumpToLastLocation() {
        if let center = LarkLocationPickerUtils.getStatshUserLocation() {
            self.mapView.setZoomLevel(zoom: MapConsts.defaultZoomLevel, center: center, animated: false)
        }
    }

    // 从地理数据列表中选中一个位置
    private func didSelectCell(in index: IndexPath, model: LocationData?) {
        if let locationData = model {
            let isCustomized = locationData.location.latitude != CLLocationDegrees(360.0)
                && locationData.location.longitude != CLLocationDegrees(360.0)
            if self.isMapViewRegionChangedFromTableView == true, !isCustomized {
                return
            }
            if index.section == 0 {
                self.viewModel.selectedType = .defaultType
            } else {
                self.viewModel.selectedType = .list
            }
            self.isMapViewRegionChangedFromTableView = true
            viewModel.setSelectItem(index: index)
            userDidSelectLocation(locationData)
        }
    }

    private func updateMapType(_ type: MapType) {
        switch type {
        case .amap:
            LocationPickerView.logger.info("Update Amap MapType")
        case .apple:
            LocationPickerView.logger.info("Update apple MapType")
        }
        self.mapType = type
        self.viewModel.updateMapType(type)
        self.topPanel.updateMapType(type)
    }

    private func updateUserLocation(_ coordinate: CLLocationCoordinate2D) {
        userCoordinate = coordinate
        self.topPanel.updateUserLocation(coordinate)
        LocationPickerView.logger.info("Update User Location")
    }

    private func footerStartRefreshing() {
        isRefreshing = true
        loadingFooter.showLoadingProgressLayer()
    }

    private func footerEndRefreshing() {
        isRefreshing = false
        loadingFooter.hideLoadingPorgressLayer()
    }

    private func isCurrentLocation() -> Bool {
        guard let user = userCoordinate else {
            return false
        }
        let center = self.mapView.centerCoordinate
        let userStr = String(format: "(%.5f, %.4f)", user.latitude, user.longitude)
        let centerStr = String(format: "(%.5f, %.4f)", center.latitude, center.longitude)
        return userStr == centerStr
    }

    public func getVendorInfo() -> String {
        return mapType.rawValue
    }

    // 从关键字搜索中选择一项后隐藏搜索结果列表
    public func hideSearchTable() {
        self.topPanel.hideFromSuperview()
        self.locationDidSelectedFromSearchCallBack?()
    }

    // 获取用户想要发送的地理位置信息
    public func selectedLocation() -> LocationData? {
        if let location = self.userSelectedLocation {
            LocationPickerView.logger.info("Selected userSelectedLocation")
            return location
        } else if let defaultLocation = self.viewModel.defaultUserLocation {
            LocationPickerView.logger.info("Selected defaultUserLocation")
            return defaultLocation
        } else {
            return nil
        }
    }

    public func getMapType() -> MapType {
        return self.mapType
    }

    public func getSelectionType() -> SelectedType {
        return self.viewModel.selectedType
    }

    // 获取地图截图
    public func doScreenShot(size: CGSize, screenShotHandler: @escaping (UIImage?) -> Void) {
        LocationPickerView.logger.info("Do Screen Shot")
        self.mapView.doScreenShot(size: size, screenShotHandler: { (img) in
            LocationPickerView.logger.info("Return Screen Shot Image")
            screenShotHandler(img)
        })
    }

    public func getZoomLevel() -> Double {
        return self.mapView.getZoomLevel()
    }

    private func setButtonImage(isLocated: Bool) {
        if !isLocated {
            self.currentLocationButton.setImage(
                BundleResources.LarkLocationPicker.location_center, for: .normal
            )
            self.currentLocationButton.setImage(
                BundleResources.LarkLocationPicker.location_center_clicked, for: .highlighted
            )
        } else {
            self.currentLocationButton.setImage(
                BundleResources.LarkLocationPicker.location_center_selected, for: .normal
            )
            self.currentLocationButton.setImage(
                BundleResources.LarkLocationPicker.location_center_selected_clicked, for: .highlighted
            )
        }
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
        func useSystemLocation() {
            switch CLLocationManager.authorizationStatus() {
            case .notDetermined:
                useSystemRequestLocationAuthorization(manager: locationManager)
            case .denied:
                locationServiceDisabledCallBack?()
            default:
                backToCurrentLocation()
            }
        }

        func useLocationModule() {
            switch locationAuth?.authorizationStatus() {
            case .notDetermined:
                locationAuth?.requestWhenInUseAuthorization(forToken: sensitivityToken, complete: didChangeAuthorization)
            case .denied:
                locationServiceDisabledCallBack?()
            default:
                backToCurrentLocation()
            }
        }

        if self.useGPSEnable() {
            if systemLocationFG {
                Self.logger.info("LocationPickerView,ClickLocate,UseSystemLocation")
                useSystemLocation()
            } else {
                Self.logger.info("LocationPickerView,ClickLocate,UseLocationModule")
                useLocationModule()
            }
        } else {
            self.showGPSDisableToast()
        }
    }

    private func backToCurrentLocation() {
        self.mapView.setZoomLevel(
            zoom: getZoomLevel(),
            center: self.mapView.userLocation.location
        )
        /* 重新进行一次搜索 */
        self.loadingHeader.showLoadingProgressLayer()
        self.mapView.centerAnnotationAnimimate(bounceHeight: 20, duration: 0.5)
        if self.mapType == .amap && self.mapDataSource == .apple {
            let newLocation = FeatureUtils.convertWGS84ToGCJ02(coordinate: self.mapView.userLocation.location)
            self.viewModel.searchPOI(center: newLocation)
        } else {
            self.viewModel.searchPOI(center: self.mapView.userLocation.location)
        }
    }

    @objc
    private func handleClickGoToSetting() {
        if let appSettings = URL(string: UIApplication.openSettingsURLString),
           UIApplication.shared.canOpenURL(appSettings) {
            UIApplication.shared.open(appSettings)
        }
    }
}

extension LocationPickerView: UITableViewDelegate {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        /// 每个地理位置信息的Cell高度定为70
        return LarkLocationPickerUtils.cellHeight
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isMapViewRegionChangedFromScroll = true
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        isMapViewRegionChangedFromScroll = false
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        /// 列表向上滑动，地图尺寸缩小但最多只能缩小到110
        /// 在列表滚动的时候不允许刷新
        if scrollView.contentOffset.y < 0 {
            let mapHeight = max(abs(scrollView.contentOffset.y), LarkLocationPickerUtils.mapMinHeight)
            self.mapView.snp.updateConstraints { (make) in
                make.height.equalTo(mapHeight)
            }
            /* 更新列表内容的offset, 且只有在变化的时候更新
             这里用最小值是为了防止在列表向下拖动时，地图区域显示过大
             */
            if self.tableView.contentInset.top != min(mapHeight, LarkLocationPickerUtils.mapMaxHeight) {
                self.tableView.contentInset = UIEdgeInsets(
                    top: min(mapHeight, LarkLocationPickerUtils.mapMaxHeight),
                    left: 0,
                    bottom: 0,
                    right: 0)
            }
        } else {
            self.mapView.snp.updateConstraints { (make) in
                self.currentLocationButton.snp.updateConstraints { (make) in
                    make.bottom.equalToSuperview()
                }
                make.height.equalTo(LarkLocationPickerUtils.mapMinHeight)
            }
            /* 这里设置为false是为了当用户在列表上拖动后继续在地图上拖动大头针，仍能够进行刷新 */
            self.isMapViewRegionChangedFromScroll = false
        }
        let height = scrollView.frame.size.height
        let contentYoffset = scrollView.contentOffset.y
        let distanceFromBottom = scrollView.contentSize.height - contentYoffset
        if scrollView.isDragging {
            return
        }
        // 当没有更多结果时，即使拉到最后也不刷新
        if distanceFromBottom < height && !isRefreshing && noMoreResultIcon.isHidden {
            viewModel.loadMoreSearchResult()
        }
    }
}

extension LocationPickerView {
    public func didChangeAuthorization(error: LocationAuthorizationError?) {
        guard let error = error else {
            openLocationPermissionButton.isHidden = true
            return
        }
        openLocationPermissionButton.isHidden = error != .denied
        if self.useGPSEnable() {
            switch error {
            case .denied:
                locationServiceDisabledCallBack?()
            case .notDetermined:
                locationAuth?.requestWhenInUseAuthorization(forToken: sensitivityToken, complete: didChangeAuthorization)
            default: break
            }
        }
    }
}

extension LocationPickerView: CLLocationManagerDelegate {
    /// 当定位权限改变时调用
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        openLocationPermissionButton.isHidden = status != .denied
        if self.useGPSEnable() {
            switch status {
            case .denied:
                locationServiceDisabledCallBack?()
            case .notDetermined:
                useSystemRequestLocationAuthorization(manager: locationManager)
            default: break
            }
        }
    }
}

extension LocationPickerView: LarkMapViewDelegate {
    public func mapViewWillStartLocatingUser(_ mapView: LarkMapView) {
//        jumpToLastLocation()
    }

    public func mapView(_ mapView: LarkMapView, failedLocate error: Error) {
        if !closeFailLocationToastOptimizeFG {
            guard viewModel.currentPOIDataIsEmpty else {
                Self.logger.info("mapView failedLocate: \(closeFailLocationToastOptimizeFG)")
                return
            }
        }
        UDToast.showFailure(with: failToLocateToastText, on: self)
    }

    public func mapView(_ mapView: LarkMapView, didUpdate userLocation: MKMapItemModel, updatingLocation: Bool) {
        guard self.useGPSEnable() else {
            LocationPickerView.logger.info("[Location Picker] GPS DISABLE BY ADMIN")
            return
        }
        let requireStatus = systemLocationFG ? CLLocationManager.authorizationStatus() : locationAuth?.authorizationStatus()
        if requireStatus == .denied ||
            requireStatus == .notDetermined {
            /// gps开关打开且还未授权不更新数据
            return
        }
        self.updateUserLocation(userLocation.location)
        // only the first locate used.
        if self.didUpdateInitLocation {
            self.didUpdateInitLocation = false
            LarkLocationPickerUtils.stashUserLocation(location: self.mapView.getUserLocation())
            self.loadingHeader.showLoadingProgressLayer()
            self.updateMapType(FeatureUtils.AMapDataAvailableForCoordinate(userLocation.location) ? .amap : .apple)
            Self.logger.info("didUpdate mapType \(self.mapType),mapDataSource \(self.mapDataSource)")
            if self.mapType == .amap && self.mapDataSource == .apple {
                /// 如果定位在中国境内, 但是数据源加载的是苹果(即港澳坐标)，需要做坐标转化
                let newCenter = FeatureUtils.convertWGS84ToGCJ02(coordinate: userLocation.location)
                Self.logger.info("didUpdate searchPOI usingConvertWGS84ToGCJ02Data")
                self.viewModel.searchPOI(center: newCenter)
            } else {
                Self.logger.info("didUpdate searchPOI usingRawData")
                self.viewModel.searchPOI(center: userLocation.location)
            }
            self.mapView.setZoomLevel(
                zoom: MapConsts.defaultZoomLevel,
                center: userLocation.location,
                animated: false)
            self.mapView.centerAnnotationAnimimate(bounceHeight: 20, duration: 0.5)
        }
    }

    public func mapView(_ mapView: LarkMapView, regionDidChangeAnimated animated: Bool) {
        /* 加对isCurrentLocation的判断是为了避免在屏幕旋转后重新搜索 */
        let selectedIndexPath = viewModel.selectedIndexPath
        var isSelected = false
        if viewModel.searchResult.value.indices.contains(selectedIndexPath.section) {
            let items = viewModel.searchResult.value[selectedIndexPath.section].items
            if items.indices.contains(selectedIndexPath.row) {
                isSelected = items[selectedIndexPath.row].isSelected
            }
        }

        if !self.isMapViewRegionChangedFromTableView,
            !self.isMapViewRegionChangedFromScroll,
            !isCurrentLocation() {
            /* 每次更新位置都根据地图中心是在国内还是海外 重新更新搜索应该用的服务 */
            self.updateMapType(FeatureUtils.AMapDataAvailableForCoordinate(self.mapView.centerCoordinate) ? .amap : .apple)
            self.loadingHeader.showLoadingProgressLayer()
            self.mapView.centerAnnotationAnimimate(bounceHeight: 20, duration: 0.5)
            Self.logger.info("regionDidChangeAnimated mapType \(self.mapType),mapDataSource \(self.mapDataSource)")
            /// 如果定位在中国境内, 但是数据源加载的是苹果(即港澳坐标)，需要做坐标转化
            if self.mapType == .amap && self.mapDataSource == .apple {
                Self.logger.info("regionDidChangeAnimated searchPOI usingConvertWGS84ToGCJ02Data")
                let newCenter = FeatureUtils.convertWGS84ToGCJ02(coordinate: self.mapView.centerCoordinate)
                self.viewModel.searchPOI(center: newCenter)
            } else {
                Self.logger.info("regionDidChangeAnimated searchPOI usingRawData")
                self.viewModel.searchPOI(center: self.mapView.centerCoordinate)
            }
        }
        self.isMapViewRegionChangedFromTableView = false
        self.setButtonImage(isLocated: isCurrentLocation())
    }

    public func mkMapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        return nil
    }

    public func mkMapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {}
    public func mkMapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {}

    #if canImport(MAMapKit)
    public func maMapView(_ mapView: MAMapView, viewFor annotation: MAAnnotation) -> MAAnnotationView? {
        return nil
    }

    public func maMapView(_ mapView: MAMapView, didAdd views: [MAAnnotationView]) {}
    public func maMapView(_ mapView: MAMapView, didChange mode: MAUserTrackingMode, animated: Bool) {}
    #endif
}

// MARK: - 屏幕翻转用
extension LocationPickerView {
    public func viewWillRotated(to size: CGSize) {
        mapView.removeAllannotion()
        mapView.showsUserLocation = false
    }

    public func viewDidRotated(to size: CGSize) {
        mapView.showsUserLocation = self.useGPSEnable()
        if let center = self.viewModel.defaultUserLocation?.location {
            self.mapView.setZoomLevel(zoom: MapConsts.defaultZoomLevel, center: center, animated: false)
        } else if let center = userCoordinate {
            self.mapView.setZoomLevel(zoom: MapConsts.defaultZoomLevel, center: center, animated: false)
        }
    }
}

extension LocationPickerView {
    public enum Cons {
        public static var mapViewFailedLocateToast: String { BundleI18n.LarkLocationPicker.Lark_Core_MapServicesErrorMessage_CheckDeviceLocationServiceRetry }
    }
}
