//
//  OpenViewLocationController.swift
//  OPPlugin
//
//  Created by yi on 2021/3/2.
//

import OPFoundation
import SnapKit
import MapKit
import LarkUIKit
import UniverseDesignColor
import UniverseDesignTheme
import UniverseDesignIcon
import LarkSplitViewController
import LarkFeatureGating
import LarkPrivacySetting
import LKCommonsLogging
/// OpenLocation使用的控制器
final class OpenViewLocationController: BaseUIViewController, MKMapViewDelegate {
    private static let logger = Logger.log(OpenViewLocationController.self, category: "OpenViewLocationController")
    private let location: CLLocationCoordinate2D
    private let scale: Int
    private let name: String?
    private let address: String?

    private lazy var mapView = { () -> MKMapView in
        let mapView = MKMapView()
        mapView.delegate = self
        mapView.clipsToBounds = true
        mapView.showsCompass = false
        mapView.isRotateEnabled = false // 禁止地图旋转，而不是禁止屏幕旋转
        mapView.showsScale = true
        return mapView
    }()

    private let locationManager = CLLocationManager()

    @objc
    public init(location: CLLocationCoordinate2D, scale: Int, name: String?, address: String?) {
        self.location = location
        self.scale = scale
        self.name = name
        self.address = address
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var navigationBarStyle: NavigationBarStyle {
        return .none
    }

    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    //  集中定义需要添加的业务子视图
    private lazy var infoBar = UIView()
    private lazy var leftEdgeControl = UIControl()   //为了支持边缘滑动返回
    private lazy var leftButton = UIButton(type: .custom)
    private lazy var locationNameLabel = UILabel()
    private lazy var locationAddressLabel = UILabel()
    private lazy var navigationButton = UIButton(type: .custom)
    private lazy var locationButton = UIButton(type: .custom)

    override public func viewDidLoad() {
        super.viewDidLoad()
        isNavigationBarHidden = true

        //  处理业务子视图
        addSubViews()
        customizeSubviews()
        layoutCustomSubviews()
        // // https://meego.feishu.cn/larksuite/story/detail/4520991
        // lark 租户级别gps关闭时 地图上不再展示用户的位置
        if LarkLocationAuthority.checkAuthority() {
            mapView.showsUserLocation = true
            do {
                try OPSensitivityEntry.requestWhenInUseAuthorization(forToken: .openViewLocationControllerViewDidLoad, manager: locationManager)
            } catch let error {
                Self.logger.error("requestWhenInUseAuthorization", error: error)
            }
        } else {
            mapView.showsUserLocation = false
        }

        if CLLocationCoordinate2DIsValid(location) {
            let viewRegin = MKCoordinateRegion(center: location, latitudinalMeters: metersForCurrentScale(), longitudinalMeters: 0)
            mapView.setRegion(viewRegin, animated: false)
            let annotation = OpenMapAnnotation()
            annotation.coordinate = location
            annotation.title = self.name
            mapView.addAnnotation(annotation)
        }
        
        //这个页面也添加支持全屏，主要理由是全屏小程序内调用openlocation，如果不支持，会导致小程序被动缩小至分栏
        // 当前页面支持 detail 全屏
        self.supportSecondaryOnly = true
        // 当前页面支持 全屏手势
        self.supportSecondaryPanGesture = true
        self.fullScreenSceneBlock = {
            return "openlocation"
        }
    
    }

    /// 添加业务子视图
    private func addSubViews() {
        view.addSubview(mapView)
        view.addSubview(leftEdgeControl)
        view.addSubview(leftButton)
        view.addSubview(locationButton)
        view.addSubview(infoBar)
        view.addSubview(locationNameLabel)
        view.addSubview(locationAddressLabel)
        view.addSubview(navigationButton)
    }

    /// 布局
    private func layoutCustomSubviews() {
        mapView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(infoBar.snp.top)
        }
        leftEdgeControl.snp.makeConstraints { (make) in
            make.top.left.bottom.equalTo(mapView)
            make.width.equalTo(10)
        }
        leftButton.snp.makeConstraints { (make) in
            make.width.equalTo(36)
            make.height.equalTo(36)
            make.left.equalToSuperview().offset(14)
            make.top.equalTo(self.view.safeAreaLayoutGuide)
        }
        infoBar.snp.makeConstraints { (make) in
            make.bottom.left.right.equalToSuperview()
            if name == nil, address == nil {
                make.height.equalTo(74)
            } else {
                make.top.equalTo(locationNameLabel.snp.top).offset(-17)
            }
        }
        locationButton.snp.makeConstraints { (make) in
            make.bottom.right.equalTo(mapView).offset(-13)
            make.width.equalTo(46)
            make.height.equalTo(46)
        }
        locationNameLabel.snp.makeConstraints { (make) in
            make.left.equalTo(locationAddressLabel)
            make.bottom.equalTo(locationAddressLabel.snp.top).offset(-4)
            make.right.equalTo(locationAddressLabel)
        }
        locationAddressLabel.snp.makeConstraints { (make) in
            make.left.equalTo(infoBar).offset(16)
            make.bottom.equalToSuperview().offset(-17)
            make.right.equalTo(navigationButton.snp.left).offset(-20)
        }
        navigationButton.snp.makeConstraints { (make) in
            make.right.equalTo(infoBar).offset(-16)
            make.centerY.equalTo(infoBar)
            make.width.equalTo(40)
            make.height.equalTo(40)
        }
    }

    /// 自定义业务子视图UI
    private func customizeSubviews() {
        leftButton.backgroundColor = UIColor(hexString: "#171E31")?.withAlphaComponent(0.3)
        leftButton.layer.cornerRadius = 18
        leftButton.setImage(UIImage.op_imageNamed("ema_map_back"), for: .normal)
        leftButton.addTarget(self, action: #selector(navigationBarLeftItemTapped), for: .touchUpInside)

        infoBar.backgroundColor = UDColor.bgBody

        locationButton.backgroundColor = UDColor.bgFiller
        locationButton.layer.ud.setShadowColor(UDColor.shadowDefaultSm)
        locationButton.layer.shadowOffset = CGSize(width: 0, height: 5)
        locationButton.layer.shadowOpacity = 1
        locationButton.layer.shadowRadius = 10
        locationButton.layer.cornerRadius = 23
        locationButton.setImage(UDIcon.localOutlined.ud.withTintColor(UDColor.iconN1), for: .normal)
        locationButton.addTarget(self, action: #selector(locationButtonTapped), for: .touchUpInside)
        locationNameLabel.text = self.name
        locationNameLabel.font = UIFont.ema_title20
        locationNameLabel.numberOfLines = 2

        locationAddressLabel.text = self.address
        locationAddressLabel.font = UIFont.ema_text12
        locationAddressLabel.numberOfLines = 3

        navigationButton.backgroundColor = UDOCColor.primaryContentDefault
        navigationButton.layer.cornerRadius = 20
        navigationButton.setImage(UIImage.op_imageNamed("ema_map_nav"), for: .normal)
        navigationButton.addTarget(self, action: #selector(navigationTapped), for: .touchUpInside)
    }

    @objc
    private func navigationBarLeftItemTapped() {
        self.navigationController?.popViewController(animated: true)
    }

    @objc
    private func locationButtonTapped() {
        guard LarkLocationAuthority.checkAuthority() else {
            LarkLocationAuthority.showDisableTip(on: self.view)
            return
        }
        let userCoor = mapView.userLocation.coordinate
        // userCoor.isValid: Fix Invalid Region <center:-180.00000000 error
        if userCoor.latitude != 0 && userCoor.longitude != 0, userCoor.isValid {
            let viewRegin = MKCoordinateRegion(center: userCoor, latitudinalMeters: metersForCurrentScale(), longitudinalMeters: 0)
            mapView.setRegion(viewRegin, animated: true)
        }
    }

    @objc
    private func navigationTapped() {
        let currentLocation = MKMapItem.forCurrentLocation()
        let tolocation = MKMapItem(placemark: MKPlacemark(coordinate: location, addressDictionary: nil))
        tolocation.name = name
        MKMapItem.openMaps(with: [currentLocation, tolocation], launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }

    // MARK: - MKMapViewDelegate
    private static let annotationID = "annotationID"
    private static let scaleMeters: [Int: Int] = [ 5: 3500000,
                                                   6: 1800000,
                                                   7: 900000,
                                                   8: 450000,
                                                   9: 225000,
                                                  10: 112000,
                                                  11: 56000,
                                                  12: 28000,
                                                  13: 14000,
                                                  14: 7000,
                                                  15: 3500,
                                                  16: 1800,
                                                  17: 1000,
                                                  18: 500]

    public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation .isKind(of: OpenMapAnnotation.self) {
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: OpenViewLocationController.annotationID)
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: OpenViewLocationController.annotationID)
            }

            annotationView?.canShowCallout = true
            if let image = UIImage.op_imageNamed("ema_location_pin") {
                annotationView?.image = image
                annotationView?.centerOffset = CGPoint(x: 0, y: -image.size.height / 2)
            }

            return annotationView
        } else {
            return nil
        }

    }

    func metersForCurrentScale() -> CLLocationDistance {
        return CLLocationDistance(OpenViewLocationController.scaleMeters[scale] ?? 500)
    }
}

final class OpenMapAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(0, 0)
    var title: String?
    var subtitle: String?
}

