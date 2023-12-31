//
//  BDPMapView.swift
//  EEMicroAppSDK
//
//  Created by 武嘉晟 on 2019/12/23.
//

import UIKit
import MapKit
import OPPluginManagerAdapter
import OPFoundation
import LarkOpenAPIModel
import LKCommonsLogging
import LarkFeatureGating
import OPPluginBiz

/// BDPMapViewModel 参数校验规则
enum BDPMapViewModelCheckRule: Int {
    case allMust = 1 /// 每个参数都必须有，老map规则
    case onlyValuedParam = 2 /// 只校验有值参数，新同层map
}

final class BDPMapView: UIView, BDPComponentViewProtocol {

    /// 定位管理器
    private let locationManager = CLLocationManager()

    /// 组件id
    public var componentID: Int = 0

    /// 地图
    private lazy var mapView: MKMapView = {
        let mapView = MKMapView(frame: CGRect(x: 0, y: 0, width: model.frame().width, height: model.frame().height))
        mapView.delegate = self
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.isRotateEnabled = true
        mapView.isPitchEnabled = true
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.showsBuildings = true
        mapView.showsTraffic = false
        return mapView
    }()

    /// 地图组件的数据对象
    private var model: BDPMapViewModel = BDPMapViewModel()

    /// 大概率是BDPAppPage，所以得用weak，小心内存泄漏
    private weak var engine: BDPJSBridgeEngineProtocol?

    /// 大头针数据模型字典，地图组件移除大头针没有removeAll方法
    private var markersArray: [BDPPointAnnotation] = []

    /// 圆数据模型字典，地图组件移除圆没有removeAll方法
    private var circlesArray: [BDPCircle] = []

    static let logger = Logger.log(BDPMapView.self, category: "EEMicroAppSDK")


    public required init(
        model: BDPMapViewModel,
        componentID: Int,
        engine: BDPJSBridgeEngineProtocol?
    ) {
        super.init(frame: model.frame())
        self.componentID = componentID
        self.model = model
        self.engine = engine
        setupViews()
    }

    deinit {
        locationManager.stopUpdatingHeading()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 初始化地图
    private func setupViews() {
        let center = CLLocationCoordinate2D(
            latitude: Double(model.latitude),
            longitude: Double(model.longitude)
        )
        let span = getSpan(with: model.scale)
        let region = MKCoordinateRegion(
            center: center,
            span: span
        )
        addSubview(mapView)
        setValidRegion(
            region,
            animated: true
        )
        if model.showLocation {
            /// 显示位置
            mapView.showsUserLocation = true
        }
        setupMarkers()
        setupCircles()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        mapView.frame = bounds /// 同层视图frame改变，子视图frame需要改变
    }

    /// 全量set或者reset大头针
    private func setupMarkers() {
        /// 每次设置或者重新设置需要重制该数组
        markersArray.removeAll()
        guard let markers = model.markers else {
            return
        }
        mapView.addAnnotations(
            markers.map { (markerModel) -> BDPPointAnnotation in
                let marker = BDPPointAnnotation(
                    uniqueID: markerModel.id,
                    markerModel: markerModel
                )
                markersArray.append(marker)
                marker.coordinate = CLLocationCoordinate2D(
                    latitude: Double(markerModel.latitude),
                    longitude: Double(markerModel.longitude)
                )
                return marker
            }
        )
    }

    /// 全量set或者reset圆
    private func setupCircles() {
        /// 每次设置或者重新设置需要重制该数组
        circlesArray.removeAll()
        guard let circles = model.circles else {
            return
        }
        mapView.addOverlays(
            circles.map { (circleModel) -> BDPCircle in
                let circle = BDPCircle(
                    center: CLLocationCoordinate2D(
                        latitude: CLLocationDegrees(circleModel.latitude),
                        longitude: CLLocationDegrees(circleModel.longitude)
                    ),
                    radius: CLLocationDistance(circleModel.radius)
                )
                circle.circleModel = circleModel
                circlesArray.append(circle)
                return circle
            }
        )
    }
}

// MARK: - 实现MKMapViewDelegate
extension BDPMapView: MKMapViewDelegate {
    public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isKind(of: MKUserLocation.self) {
            /// 用户位置的蓝色大头针
            return nil
        }
        /// 只处理自定义的marker
        if let marker = annotation as? BDPPointAnnotation {
            let markerModel = marker.markerModel
            /// markerModel从oc那边过来的 最好保护一下
            if markerModel == nil {
                return nil
            }
            let annotationView = BDPAnnotationView(
                uniqueID: marker.uniqueID,
                annotation: marker,
                reuseIdentifier: nil
            )
            let defaultImage = UIImage.ema_imageNamed("program_map_destinaion")
            /// 处理用户设置大头针图片的逻辑
            if let iconPath = markerModel.iconPath {
                DispatchQueue.global().async {
                    EMAFileManager.image(with: iconPath, engine: self.engine) { (image) in
                        DispatchQueue.main.async {
                            if let image = image {
                                annotationView.image = image
                            } else {
                                /// 用户图片不合法，需要使用默认图片
                                annotationView.image = defaultImage
                            }
                        }
                    }
                }
            } else {
                annotationView.image = defaultImage
            }
            annotationView.canShowCallout = true
            let label = UILabel()
            label.text = markerModel.title
            annotationView.detailCalloutAccessoryView = label
            return annotationView
        }
        return nil
    }
    public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let circle = overlay as? BDPCircle,
            let circleModel = circle.circleModel else {
                return MKOverlayRenderer(overlay: overlay)
        }
        let circleRenderer = MKCircleRenderer(circle: circle)
        if let color = circleModel.color {
            /// 描边颜色
            circleRenderer.strokeColor = UIColor(hexString: color)
        }
        if let fillColor = circleModel.fillColor {
            /// 填充颜色
            circleRenderer.fillColor = UIColor(hexString: fillColor)
        }
        if circleModel.strokeWidth > 0 {
            circleRenderer.lineWidth = circleModel.strokeWidth
        }
        return circleRenderer
    }
    public func mapViewWillStartLocatingUser(_ mapView: MKMapView) {
        do {
            try OPSensitivityEntry.requestWhenInUseAuthorization(forToken: .bDPMapViewMapViewWillStartLocatingUserRequestWhenInUseAuthorization, manager: locationManager)
            try OPSensitivityEntry.startUpdatingLocation(forToken: .bDPMapViewMapViewWillStartLocatingUserStartUpdatingLocation, manager: locationManager)
        } catch let error {
            Self.logger.error("mapViewWillStartLocatingUser failed", error: error)
        }
    }
    public func mapViewDidStopLocatingUser(_ mapView: MKMapView) {
        locationManager.stopUpdatingHeading()
    }
}

// MARK: - 组件内部API
extension BDPMapView {
    /// 缩放级别转span
    /// - Parameter zoomLevel: 缩放级别scale
    private func getSpan(with zoomLevel: Int) -> MKCoordinateSpan {
        MKCoordinateSpan(
            latitudeDelta: 0,
            longitudeDelta: 360 / pow(2, Double(zoomLevel)) * Double(self.frame.size.width) / 256
        )
    }
}

// MARK: - 提供对外API
extension BDPMapView {
    /// 将地图中心移置指定位置
    /// - Parameter location: 坐标
    public func move(to location: CLLocationCoordinate2D) {
        let span = mapView.region.span
        let region = MKCoordinateRegion(
            center: location,
            span: span
        )
        setValidRegion(
            region,
            animated: true
        )
    }

    /// 将地图中心移置当前定位
    public func moveToCurrentLocation() {
        let currentLocation = mapView.userLocation.coordinate
        move(to: currentLocation)
    }

    /// 更新地图组件数据
    /// - Parameter model: 地图组件的数据对象
    public func update(with updateModel: BDPMapViewModel) {
        update(with: updateModel, checkRule: .allMust)
    }

    /// 更新地图组件数据
    /// - Parameter model: 地图组件的数据对象
    /// - Parameter checkRule: 参数校验规则
    public func update(with updateModel: BDPMapViewModel, checkRule: BDPMapViewModelCheckRule) {
        var center: CLLocationCoordinate2D?
        /// 仅处理 经纬度 缩放级别 大头针
        switch checkRule {
        case .onlyValuedParam:
            /// 有值参数才处理，差量更新map
            if !updateModel.isEmptyParam("longitude") || !updateModel.isEmptyParam("latitude") {
                model.longitude = !updateModel.isEmptyParam("longitude") ? updateModel.longitude : model.longitude
                model.latitude = !updateModel.isEmptyParam("latitude") ? updateModel.latitude : model.latitude
                center = CLLocationCoordinate2D(
                    latitude: Double(model.latitude),
                    longitude: Double(model.longitude)
                )
            }
        case .allMust:
            if updateModel.longitude != nil,
            updateModel.latitude != nil {
                model.longitude = updateModel.longitude
                model.latitude = updateModel.latitude
                center = CLLocationCoordinate2D(
                    latitude: Double(model.latitude),
                    longitude: Double(model.longitude)
                )
            }
        }
        if updateModel.scale != nil && !updateModel.isEmptyParam("scale") {
            model.scale = updateModel.scale
            var region = mapView.region
            let span = getSpan(with: model.scale)
            region.span = span
            if let mapViewCenter = center {
                region.center = mapViewCenter
            }
            // setRegion为异步，包含setCenter+scale
            setValidRegion(
                region,
                animated: true
            )
        } else if let mapViewCenter = center {
            mapView.setCenter(
                mapViewCenter,
                animated: true
            )
        }
        /// 千万要注意nil和空数组的关系，空数组是设置为空，nil为没更新这个属性
        if let markers = updateModel.markers {
            model.markers = markers
            mapView.removeAnnotations(markersArray)
            setupMarkers()
        }
        if let circles = updateModel.circles {
            model.circles = circles
            mapView.removeOverlays(circlesArray)
            setupCircles()
        }
        if !updateModel.isEmptyParam("showLocation") {
            mapView.showsUserLocation = updateModel.showLocation
        }
    }

    func setValidRegion(_ region: MKCoordinateRegion, animated: Bool) {
        if isValidRegion(map: mapView, region: region) {
            mapView.setRegion(
                region,
                animated: true
            )
        } else {
            Self.logger.warn("move to inValid region - \(region.center.latitude) - \(region.center.longitude) - \(region.span.latitudeDelta) - \(region.span.longitudeDelta)")
        }
    }

    /// 有效region判断，否则会引起NSException Invalid Region crash
    public func isValidRegion(map: MKMapView, region: MKCoordinateRegion) -> Bool {
        let adjustRegion = map.regionThatFits(region)
        return !adjustRegion.span.latitudeDelta.isNaN && !adjustRegion.span.longitudeDelta.isNaN
    }

}
