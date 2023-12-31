//
//  OpenLocationPickerController.swift
//  OPPlugin
//
//  Created by yi on 2019/2/17.
//

import Foundation
import SnapKit
import MapKit
import EENavigator
import LarkUIKit
import OPFoundation
import UniverseDesignColor
import UniverseDesignTheme
import UniverseDesignIcon
import LarkPrivacySetting
import OPFoundation
import LKCommonsLogging

final class OpenLocationModel: NSObject {
    @objc public var name: String
    @objc public var address: String
    @objc public var location: CLLocationCoordinate2D

    init(name: String, address: String, location: CLLocationCoordinate2D) {
        self.name = name
        self.address = address
        self.location = location
    }

    init(mapItem: MKMapItem) {
        self.name = mapItem.name ?? ""
        self.address = mapItem.placemark.title ?? ""
        self.location = mapItem.placemark.coordinate
    }
}

final class OpenLocationPickerController: BaseUIViewController,
                                           UITableViewDelegate, UITableViewDataSource,
                                           MKMapViewDelegate,
                                           UITextFieldDelegate {
    private static let logger = Logger.log(OpenLocationPickerController.self, category: "OpenLocationPickerController")
    private static let locationCellID = "EMALocationCell"

    public var locationPickerFinishSelect: ((OpenLocationPickerController, OpenLocationModel) -> Void)?
    public var locationPikcerCancelSelect: ((OpenLocationPickerController) -> Void)?
    public var locationPickerFinishError: ((OpenLocationPickerController, Error) -> Void)?

    /// 周边POI结果
    private var roundPoiSearchResults: [OpenLocationModel] = []
    /// 关键词搜索结果
    private var keyWordPoiSearchResults: [OpenLocationModel] = []
    /// 当前选择地址
    private var currentSelectedLocation: OpenLocationModel?
    private var currentSelectedLocationError: Error?
    /// 当前用户地址
    private var userLocationInited: Bool = false
    private let locationManager = CLLocationManager()
    private var isViewHasAppear: Bool = false

    private lazy var mapView = { () -> MKMapView in
        let mapView = MKMapView()
        mapView.delegate = self
        mapView.clipsToBounds = true
        mapView.showsCompass = false
        mapView.showsScale = false
        return mapView
    }()

    private var mapSearchAPI: MKLocalSearch?

    private lazy var tableView = { () -> UITableView in
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UDColor.bgBase
        tableView.separatorStyle = .none
        tableView.register(OpenLocationCell.self, forCellReuseIdentifier: OpenLocationPickerController.locationCellID)
        return tableView
    }()

    private lazy var searchResultTableView = { () -> UITableView in
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UDColor.bgBase
        tableView.separatorStyle = .none
        tableView.register(OpenLocationCell.self, forCellReuseIdentifier: OpenLocationPickerController.locationCellID)
        return tableView
    }()

    private lazy var searchTextField = { () -> UITextField in
        let searchTextField = UITextField()
        searchTextField.backgroundColor = UDColor.bgBody
        searchTextField.delegate = self
        searchTextField.textColor = UDColor.textTitle
        searchTextField.font = UIFont.op_title(withSize: 22)
        searchTextField.clearButtonMode = .whileEditing
        searchTextField.returnKeyType = .done
        searchTextField.addTarget(self, action: #selector(textFiledTextChanged), for: .editingChanged)
        searchTextField.addTarget(searchTextField, action: #selector(resignFirstResponder), for: .editingDidEndOnExit)

        let wrapperView = UIView(frame: CGRect(x: 0, y: 0, width: 46, height: 24))
        let iconView = UIImageView(image: UDIcon.searchOutlineOutlined.ud.withTintColor(UDColor.iconN1))
        iconView.contentMode = .scaleAspectFit
        iconView.frame = CGRect(x: 12, y: 0, width: 24, height: 24)
        wrapperView.addSubview(iconView)
        searchTextField.leftView = wrapperView
        searchTextField.leftViewMode = .always

        // 设置搜索栏placeholder
        let attributedString = NSMutableAttributedString(
            string: BundleI18n.OPPlugin.LittleApp_OpenLocation_SearchPlacePlaceholder,
            attributes: [.kern: 0.0])
        attributedString.addAttribute(
            .foregroundColor,
            value: UDColor.textPlaceholder,
            range: NSRange(location: 0, length: BundleI18n.OPPlugin.LittleApp_OpenLocation_SearchPlacePlaceholder.count)
        )

        searchTextField.attributedPlaceholder = attributedString

        return searchTextField
    }()

    override public func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UDColor.bgBase
        addCloseItem()
        navigationController?.navigationBar.tintColor = UDColor.textTitle
        updateNavigationBar(backgroundImage: UIImage.ud.fromPureColor(UDColor.bgBody))

        let locationImageView = UIImageView(image: UIImage.op_imageNamed("ema_location_pin"))
        let locationButton = UIButton(type: .custom)

        view.addSubview(mapView)
        view.addSubview(locationImageView)
        view.addSubview(locationButton)
        view.addSubview(searchTextField)
        view.addSubview(tableView)
        view.addSubview(searchResultTableView)

        searchTextField.snp.makeConstraints { (make) in
            make.left.top.right.equalToSuperview()
            make.height.equalTo(71.0)
        }

        mapView.snp.makeConstraints { (make) in
            make.top.equalTo(searchTextField.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(tableView.snp.top)
        }

        tableView.snp.makeConstraints { (make) in
            make.left.bottom.right.equalToSuperview()
            make.height.equalTo(211)
        }

        searchResultTableView.isHidden = true
        searchResultTableView.snp.makeConstraints { (make) in
            make.top.equalTo(searchTextField.snp.bottom)
            make.left.bottom.right.equalToSuperview()
        }

        locationImageView.snp.makeConstraints { (make) in
            make.width.equalTo(22)
            make.height.equalTo(34)
            make.centerX.equalTo(mapView.snp.centerX)
            make.bottom.equalTo(mapView.snp.centerY)
        }

        locationButton.backgroundColor = UDColor.bgFiller
        locationButton.layer.ud.setShadowColor(UDColor.shadowDefaultSm)
        locationButton.layer.shadowOffset = CGSize(width: 0, height: 5)
        locationButton.layer.shadowOpacity = 1
        locationButton.layer.shadowRadius = 10
        locationButton.layer.cornerRadius = 23
        locationButton.setImage(UDIcon.localOutlined.ud.withTintColor(UDColor.iconN1), for: .normal)
        locationButton.addTarget(self, action: #selector(locationButtonTapped), for: .touchUpInside)
        locationButton.snp.makeConstraints { (make) in
            make.bottom.right.equalTo(mapView).offset(-13)
            make.width.equalTo(46)
            make.height.equalTo(46)
        }
        // https://meego.feishu.cn/larksuite/story/detail/4520991
        // lark 租户级别gps关闭时 地图上不再展示用户的位置
        if LarkLocationAuthority.checkAuthority() {
            mapView.showsUserLocation = true
            do {
                try OPSensitivityEntry.requestWhenInUseAuthorization(forToken: .openLocationPickerControllerViewDidLoad, manager: locationManager)
            } catch let error {
                Self.logger.error("requestWhenInUseAuthorization", error: error)
            }
        } else {
            mapView.showsUserLocation = false
        }
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: BundleI18n.OPPlugin.done, style: .plain, target: self, action: #selector(done))
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !isViewHasAppear, !LarkLocationAuthority.checkAuthority() {
            LarkLocationAuthority.showDisableTip(on: self.view)
        }
        isViewHasAppear = true
    }

    func userDidSelectLocation(_ locationData: OpenLocationModel, _ resetRegin: Bool) {
        currentSelectedLocation = locationData
        self.tableView.reloadSections(IndexSet(integer: 0), with: .none)

        self.searchTextField.text = self.currentSelectedLocation?.name

        if resetRegin {
            let span = MKCoordinateSpan(latitudeDelta: 0.013, longitudeDelta: 0.025)
            let viewRegin = MKCoordinateRegion(center: locationData.location, span: span)
            mapView.setRegion(viewRegin, animated: true)
        }

        self.view.window?.endEditing(true)
    }

    deinit {
        mapSearchAPI?.cancel()
    }

    func pioSearch(query: String, region: MKCoordinateRegion?, completionHandler: @escaping ([OpenLocationModel]?, Error?) -> Void) {
        self.mapSearchAPI?.cancel()

        // 获取地图中心点
        let centerCoor = mapView.centerCoordinate
        let location = CLLocation(latitude: centerCoor.latitude, longitude: centerCoor.longitude)

        let request = MKLocalSearch.Request()
        if let region = region {
            request.region = region
        }
        request.naturalLanguageQuery = query
        let localSearch = MKLocalSearch(request: request)
        self.mapSearchAPI = localSearch
        localSearch.start { [weak self] (response, error) in
            if let response = response, let `self` = self {

                var mapSortItems = response.mapItems
                mapSortItems.sort(by: { (mapItem0, mapItem1) -> Bool in
                    let distance0 = location.distance(from: mapItem0.placemark.location ?? location)
                    let distance1 = location.distance(from: mapItem1.placemark.location ?? location)
                    return distance0 < distance1
                })

                let poiSearchResults = mapSortItems.map({ (mapItem) -> OpenLocationModel in
                    var model = OpenLocationModel(mapItem: mapItem)
                    return model
                })

                completionHandler(poiSearchResults, nil)
            }
            completionHandler(nil, error)
        }
    }

    public override func closeBtnTapped() {
        super.closeBtnTapped()
        if let locationPikcerCancelSelect = locationPikcerCancelSelect {
            locationPikcerCancelSelect(self)
        }
    }

    @objc
    fileprivate func locationButtonTapped() {
        guard LarkLocationAuthority.checkAuthority() else {
            LarkLocationAuthority.showDisableTip(on: self.view)
            return
        }

        let userCoor = mapView.userLocation.coordinate
        // userCoor.isValid: Fix Invalid Region <center:-180.00000000 error
        if userCoor.latitude != 0 && userCoor.longitude != 0, userCoor.isValid {
            let span = MKCoordinateSpan(latitudeDelta: 0.013, longitudeDelta: 0.025)
            let viewRegin = MKCoordinateRegion(center: userCoor, span: span)
            mapView.setRegion(viewRegin, animated: true)
        }
    }

    @objc
    func done() {
        self.dismiss(animated: true, completion: nil)
        if let currentSelectedLocation = currentSelectedLocation {
            locationPickerFinishSelect?(self, currentSelectedLocation)
        } else if let error = currentSelectedLocationError {
            locationPickerFinishError?(self, error)
        }
    }

    private func updateNavigationBar(backgroundImage: UIImage,
                                     shadowImage: UIImage = UIImage()) {
        // https://developer.apple.com/forums/thread/682420
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundImage = backgroundImage
            appearance.shadowImage = shadowImage
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        } else {
            navigationController?.navigationBar.shadowImage = shadowImage
            navigationController?.navigationBar.setBackgroundImage(backgroundImage, for: .default)
        }
    }

    // MARK: - UITableViewDelegate, UITableViewDataSource
    public func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == searchResultTableView {
            return 1
        } else {
            return 2
        }
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellData = data(in: tableView, at: indexPath)

        if let cell = tableView.dequeueReusableCell(withIdentifier: OpenLocationPickerController.locationCellID) as? OpenLocationCell,
            let cellData = cellData {
            if let currentSelectedLocation = currentSelectedLocation {
                let sameLocation = currentSelectedLocation.location.latitude == cellData.location.latitude && currentSelectedLocation.location.longitude == cellData.location.longitude
                cell.setContent(location: cellData, isCurrent: sameLocation)
            } else {
                cell.setContent(location: cellData)
            }

            return cell
        }

        return UITableViewCell()
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == searchResultTableView {
            return keyWordPoiSearchResults.count
        } else {
            if section == 0 {
                return (currentSelectedLocation == nil) ? 0 : 1
            } else if section == 1 {
                return roundPoiSearchResults.count
            }
            return 0
        }
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        if let selectedLocation = data(in: tableView, at: indexPath) {
            userDidSelectLocation(selectedLocation, true)
            searchResultTableView.isHidden = true
        }
    }

    private func data(in tableView: UITableView, at indexPath: IndexPath) -> OpenLocationModel? {
        let cellData: OpenLocationModel?
        if tableView == searchResultTableView {
            cellData = keyWordPoiSearchResults[indexPath.row]
        } else {
            if indexPath.section == 0 {
                cellData = currentSelectedLocation
            } else {
                cellData = roundPoiSearchResults[indexPath.row]
            }
        }
        return cellData
    }
    // MARK: - MKMapViewDelegate

    public func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        let userCoor = mapView.userLocation.coordinate
        
        // userCoor.isValid: Fix Invalid Region <center:-180.00000000 error
        if userCoor.latitude != 0 && userCoor.longitude != 0, userCoor.isValid {
            if !userLocationInited {
                let span = MKCoordinateSpan(latitudeDelta: 0.013, longitudeDelta: 0.025)
                let viewRegin = MKCoordinateRegion(center: userCoor, span: span)
                mapView.setRegion(viewRegin, animated: false)
            }
            userLocationInited = true
        }
    }

    public func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // 获取地图中心点
        let centerCoor = mapView.centerCoordinate
        let location = CLLocation(latitude: centerCoor.latitude, longitude: centerCoor.longitude)

        let currentSelectedCoor = self.currentSelectedLocation?.location
        if let currentSelectedCoor = currentSelectedCoor,
            location.distance(from: CLLocation(latitude: currentSelectedCoor.latitude, longitude: currentSelectedCoor.longitude)) < 1 {

        } else {
            let geocodeCompletionHandler: CLGeocodeCompletionHandler = {[weak self] (placemarks, error) in
                self?.currentSelectedLocationError = error
                guard let placemarks = placemarks, let placemark = placemarks.first, let `self` = self else {
                    print("\(String(describing: error))")
                    return
                }
                DispatchQueue.main.async {
                    guard let name = placemark.name, let address = placemark.thoroughfare, let location = placemark.location else {
                        return
                    }
                    self.userDidSelectLocation(OpenLocationModel(name: name, address: address, location: location.coordinate), false)
                    self.tableView.reloadSections(IndexSet(integer: 0), with: .none)
                }
            }
            
            do {
                //请求地图中心点逆地理信息
                try OPSensitivityEntry.reverseGeocodeLocation(forToken: .openLocationPickerControllerMapViewRegionDidChangeAnimated,
                                                       geocoder: CLGeocoder(),
                                                       location: location,
                                                       completionHandler: geocodeCompletionHandler)
            } catch {
                geocodeCompletionHandler(nil, error)
            }

        }

        // 这个自然语言搜索很坑啊，多国语言怎么适配...考虑使用其他的支持全部附近地点pio搜索的api
        pioSearch(query: "餐饮|购物|交通|文体娱乐|医疗|房产|旅游|金融服务|生活服务|汽车服务|企事业单位|学校|商场|写字楼", region: mapView.region) { [weak self] (result, error) in
            guard let result = result, let `self` = self else {
                print(error as Any)
                return
            }

            UIView.performWithoutAnimation {
                self.roundPoiSearchResults = result.filter({ (model) -> Bool in
                    if let currentSelectedLocation = self.currentSelectedLocation {
                        let sameLocation = currentSelectedLocation.location.latitude == model.location.latitude && currentSelectedLocation.location.longitude == model.location.longitude
                        return !sameLocation
                    } else {
                        return true
                    }
                })
                self.tableView.reloadSections(IndexSet(integer: 1), with: .none)
            }

        }
    }
    // MARK: - UITextFieldDelegate

    public func textFieldDidBeginEditing(_ textField: UITextField) {
        self.searchResultTableView.isHidden = false
        textFiledTextChanged()
    }

    @objc
    public func textFiledTextChanged() {
        if self.searchResultTableView.isHidden {
            return
        }
        let keyWord = searchTextField.text
        if let keyWord = keyWord, (keyWord.count ?? 0) > 0 {
            pioSearch(query: keyWord, region: mapView.region) { [weak self] (result, error) in
                guard let result = result, let `self` = self else {
                    print(error as Any)
                    return
                }

                UIView.performWithoutAnimation {
                    self.keyWordPoiSearchResults = result
                    self.searchResultTableView.reloadData()
                }
            }
        } else {
            self.keyWordPoiSearchResults = [OpenLocationModel]()
            self.searchResultTableView.reloadData()
        }
    }

}

extension CLLocationCoordinate2D {
    var isValid: Bool {
        return (-180.0...180.0).contains(longitude) && (-90.0...90.0).contains(latitude)
    }
}
