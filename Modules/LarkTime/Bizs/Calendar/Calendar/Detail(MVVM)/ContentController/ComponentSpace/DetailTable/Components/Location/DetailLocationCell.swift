//
//  LocationCombo.swift
//  Calendar
//
//  Created by jiayi zou on 2018/2/2.
//  Copyright © 2018年 EE. All rights reserved.
//

import UIKit
import RustPB
import MapKit
import CalendarFoundation
import LarkLocationPicker
import UniverseDesignIcon
import LarkEMM
import UniverseDesignToast
import LarkSensitivityControl

protocol DetailLocationCellContent {
    var location: String? { get }
    var address: String? { get }
    var latitude: Float? { get }
    var longitude: Float? { get }
}

protocol DetailLocationCellDelegate: AnyObject {
    func onTapMap()
}

final class DetailLocationCell: DetailCell {
    private let stackView = UIStackView()
    private var content: DetailLocationCellContent?
    weak var delegate: DetailLocationCellDelegate?
    private let labelStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 4
        return stackView
    }()

    private let locationLabel: UILabel = {
        let label = DetailCell.normalTextLabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    private let addressLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.font = UIFont.cd.regularFont(ofSize: 14)
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    private var mapView: UIView?

    private let highlitedView = UIView()
    private var copyText: String = ""
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setLeadingIcon(UDIcon.getIconByKeyNoLimitSize(.localOutlined).renderColor(with: .n3))
        self.layoutStackView(stackView)
        self.attachLongHandle()
        let warpper = UIView()
        warpper.addSubview(labelStackView)

        let arrow = UIImageView()
        arrow.image = UDIcon.getIconByKeyNoLimitSize(.rightOutlined).renderColor(with: .n2)
        warpper.addSubview(arrow)
        labelStackView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.bottom.equalToSuperview()
        }
        arrow.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview()
            make.left.equalTo(labelStackView.snp.right).offset(16)
            make.width.height.equalTo(16)
        }
        stackView.addArrangedSubview(warpper)
        labelStackView.addArrangedSubview(locationLabel)
        labelStackView.addArrangedSubview(addressLabel)
        self.layoutHighlitedView(highlitedView, labelStackView: labelStackView)
    }

    private func layoutStackView(_ stackView: UIStackView) {
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 4
        self.addCustomView(stackView)
    }

    private func layoutHighlitedView(_ highlitedView: UIView, labelStackView: UIStackView) {
        highlitedView.backgroundColor = UIColor.ud.N800.withAlphaComponent(0.05)
        highlitedView.isHidden = true
        self.addSubview(highlitedView)
        highlitedView.snp.makeConstraints { (make) in
            make.left.top.right.equalToSuperview()
            make.bottom.equalTo(labelStackView.snp.bottom).offset(13)
        }
    }

    func updateContent(_ content: DetailLocationCellContent) {

        copyText = ""

        if let location = content.location, !location.isEmpty {
            copyText += location
            locationLabel.text = location
            locationLabel.isHidden = false
        } else {
            locationLabel.isHidden = true
        }

        if let address = content.address, !address.isEmpty {
            copyText += address
            addressLabel.text = address
            addressLabel.isHidden = false
        } else {
            addressLabel.isHidden = true
        }

        guard let latitude = content.latitude, let longitude = content.longitude else {
            return
        }

        if self.content?.latitude == latitude && self.content?.longitude == longitude {
            return
        }

        if let mapView = self.mapView {
            mapView.removeFromSuperview()
        }

        let validLocation = -90.0 <= latitude && latitude <= 90.0 && -180.0 <= longitude && longitude <= 180.0
        let zeroLocation = (latitude == 0.0 && longitude == 0.0)
        if validLocation && !zeroLocation {
            // (0,0)也不显示地图
            let mapView = self.mapView(latitude: latitude, longitude: longitude)
            self.mapView = mapView
            stackView.addArrangedSubview(mapView)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(onTapMap))
        stackView.gestureRecognizers?.forEach({ (gesture) in
            stackView.removeGestureRecognizer(gesture)
        })

        stackView.addGestureRecognizer(tap)
        self.content = content
    }

    private func mapView(latitude: Float, longitude: Float) -> UIView {
        let mapViewWrapper = UIView(frame: CGRect(x: 0, y: 0, width: 311, height: 90))
        let mapView = MKMapView(frame: CGRect(x: 0, y: 10, width: 311, height: 80))
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.mapType = .standard
        mapViewWrapper.addSubview(mapView)
        mapView.zoomLevel = 15
        mapView.showsScale = false
        mapView.showsCompass = false
        mapView.isZoomEnabled = false
        mapView.isScrollEnabled = false

        let coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(latitude),
                                                longitude: CLLocationDegrees(longitude))
        mapView.setCenter(coordinate, animated: false)
        mapViewWrapper.snp.makeConstraints { (make) in
            make.height.equalTo(90)
        }

        let locationIcon = UIImageView(image: UIImage.cd.image(named: "location_icon_blue").withRenderingMode(.alwaysOriginal))
        mapViewWrapper.addSubview(locationIcon)
        locationIcon.snp.makeConstraints { (make) in
            make.bottom.equalTo(mapView.snp.centerY)
            make.centerX.equalTo(mapView)
            make.height.equalTo(34)
            make.width.equalTo(32)
        }

        return mapViewWrapper
    }

    @objc
    func onTapMap() {
        self.delegate?.onTapMap()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public var canBecomeFirstResponder: Bool {
        return true
    }

    private func attachLongHandle() {
        NotificationCenter.default.addObserver(self, selector: #selector(menuControllerWillHide),
                                               name: UIMenuController.willHideMenuNotification,
                                               object: nil)
        isUserInteractionEnabled = true
        addGestureRecognizer(UILongPressGestureRecognizer(
            target: self,
            action: #selector(showMenu(sender:))
        ))
    }

    @objc
    func menuControllerWillHide() {
        self.highlitedView.isHidden = true
    }

    func menuControllerWillShow() {
        self.highlitedView.isHidden = false
    }

    @objc
    func copyText(_ sender: Any?) {
        do {
            let config = PasteboardConfig(token: LarkSensitivityControl.Token(SCPasteboardUtils.getSceneKey(.eventDetailLocationInfoCopy)))
            try SCPasteboard.generalUnsafe(config).string = copyText
        } catch {
            SCPasteboardUtils.logCopyFailed()
            if let window = self.window {
                UDToast.showTips(with: I18n.Calendar_Share_UnableToCopy, on: window)
            }
        }
        UIMenuController.shared.setMenuVisible(false, animated: true)
    }

    @objc
    func showMenu(sender: UIGestureRecognizer) {
        becomeFirstResponder()
        CalendarTracer.shareInstance.calDetailCopy(elementType: .location)
        let menu = UIMenuController.shared
        menu.menuItems = [UIMenuItem(title: BundleI18n.Calendar.Calendar_Common_Copy, action: #selector(copyText(_:)))]
        if !menu.isMenuVisible {
            self.menuControllerWillShow()
            let point = sender.location(in: self)
            let rect = CGRect(x: point.x, y: 0, width: 1, height: self.bounds.height)
            menu.setTargetRect(rect, in: self)
            menu.setMenuVisible(true, animated: true)
        }
    }

    override public func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return (action == #selector(copyText(_:)))
    }

    deinit {
        self.resignFirstResponder()
        NotificationCenter.default.removeObserver(self)
    }
}

extension MKMapView {
    //缩放级别
    var zoomLevel: Double {
        //获取缩放级别
        get {
            return log2(360 * (Double(self.frame.size.width / 256)
                / self.region.span.longitudeDelta))
        }
        //设置缩放级别
        set (newZoomLevel) {
            setCenterCoordinate(coordinate: self.centerCoordinate,
                                zoomLevel: newZoomLevel,
                                animated: false)
        }
    }

    //设置缩放级别时调用
    private func setCenterCoordinate(coordinate: CLLocationCoordinate2D,
                                     zoomLevel: Double,
                                     animated: Bool) {
        let span = MKCoordinateSpan(latitudeDelta: 0,
                                    longitudeDelta: 360 / pow(2, zoomLevel) * Double(self.frame.size.width) / 256)
        setRegion(MKCoordinateRegion(center: centerCoordinate, span: span), animated: animated)
    }
}
