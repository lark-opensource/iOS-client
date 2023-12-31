//
//  LarkLocationPickerUtils.swift
//  LarkLocationPicker
//
//  Created by Fangzhou Liu on 2019/7/24.
//
import UIKit
import Foundation
import MapKit
import LarkActionSheet
import LarkStorage

public final class LarkLocationPickerUtils {
    public enum LocationType {
        case gaode
        case baidu
        case tencent
        case google
        case apple
        case waze
        case sougou

        public var map: String {
            switch self {
                case .apple:
                    return BundleI18n.LarkLocationPicker.Lark_Chat_MessageLocationMapApple
                case .gaode:
                    return BundleI18n.LarkLocationPicker.Lark_Chat_MessageLocationMapGaode
                case .baidu:
                    return BundleI18n.LarkLocationPicker.Lark_Chat_MessageLocationMapBaidu
                case .tencent:
                    return BundleI18n.LarkLocationPicker.Lark_Chat_MessageLocationMapTencent
                case .google:
                    return BundleI18n.LarkLocationPicker.Lark_Chat_MessageLocationMapGoogle
                case .waze:
                    return BundleI18n.LarkLocationPicker.Lark_Chat_MessageLocationMapWaze
                case .sougou:
                    return BundleI18n.LarkLocationPicker.Lark_Chat_MessageLocationMapSougou
            }
        }

        public var url: String {
            switch self {
                case .apple:
                    return "maps://"
                case .gaode:
                    return "iosamap://"
                case .baidu:
                    return "baidumap://"
                case .tencent:
                    return "qqmap://"
                case .google:
                    return "comgooglemaps://"
                case .waze:
                    return "waze://"
                case .sougou:
                    return "sgmap://"
            }
        }

        /// 将地点检索信息转化为URL  用于App跳转
        public func coordinateToURL(query: String) -> URL? {
            var url = String()
            /// 中文地图会传入目的地名称并转化为%形式，如目的地信息无法转化则传空
            var urlWithoutDestinationName = String()

            switch self {
            case .gaode:
                url = "iosamap://poi?sourceApplication=Lark&name=\(query)"
                urlWithoutDestinationName = "iosamap://path?sourceApplication=Lark&name="
            case .baidu:
              url = "baidumap://map/nearbysearch?query=\(query)"
                urlWithoutDestinationName = "baidumap://map/nearbysearch?query="
            case .tencent:
                url = "qqmap://map/search?keyword=\(query)"
                urlWithoutDestinationName = "qqmap://map/search?keyword="
            case .google:
                url = "comgooglemaps://?q=\(query)"
                urlWithoutDestinationName = "comgooglemaps://?q="
            case .waze:
                url = "https://waze.com/ul?q=\(query)"
                urlWithoutDestinationName = "https://waze.com/ul?q="
            default:
                url = "http://maps.apple.com/?q=\(query)"
                urlWithoutDestinationName = "http://maps.apple.com/?q="
            }
            if let newURL = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                return URL(string: newURL)
            }
            return URL(string: urlWithoutDestinationName)
        }

        /// 将位置信息转化为URL 用于App跳转
        /// 坐标为WGS-84坐标系
        /// isInternal的原意是是否需要转成wgs84坐标，但其实没有必要。因为gcj02坐标系只对国内的坐标加密，国外的坐标gcj02和wgs84一样。
        /// 日历这边存的是LocationData.rawLocation，对应gcj02下的坐标。跳转的时候直接使用rawLocation，地图的参数传gcj02就行，不用再转换。
        /// 其他业务方如一开始是用了isInternal，isGcj02传false
        /// ToDo: @qujieye
        /// 修改此接口参数，去除isGcj02参数，修改wgs84coord为coord
        public func coordinateToURL(isInternal: Bool, isGcj02: Bool = false, destination: String, wgs84coord: CLLocationCoordinate2D) -> URL? {
            var url = String()
            /// 中文地图会传入目的地名称并转化为%形式，如目的地信息无法转化则只通过URL传入经纬度
            var urlWithoutDestinationName = String()
            let coord = wgs84coord
            /// ToDo: @qujieye
            /// 5.13版本bug为了保证国内跳转正确写死高德和百度的参数；国外经过测试coordType传哪个都会有问题，考虑到国外百度使用较少，所以先忽略国外百度的偏差情况
            let dev = "dev=0"
            let coordType = "coord_type=gcj02"
            switch self {
                case .gaode:
                    url = "iosamap://path?sourceApplication=Lark&dlat=\(wgs84coord.latitude)&dlon=\(wgs84coord.longitude)&dname=\(destination)&\(dev)&t=0"
                    urlWithoutDestinationName = "iosamap://path?sourceApplication=Lark&dlat=\(wgs84coord.latitude)&dlon=\(wgs84coord.longitude)&\(dev)&t=0"
                case .baidu:
                    url = "baidumap://map/direction?destination=name:\(destination)|latlng:\(wgs84coord.latitude),\(wgs84coord.longitude),&\(coordType)&mode=driving&src=Lark"
                    urlWithoutDestinationName = "baidumap://map/direction?destination=\(wgs84coord.latitude),\(wgs84coord.longitude),&\(coordType)&mode=driving&src=Lark"
                case .tencent:
                    url = "qqmap://map/routeplan?type=drive&fromcoord=CurrentLocation&to=\(destination)&tocoord=\(coord.latitude),\(coord.longitude)&referer=Lark"
                    urlWithoutDestinationName = "qqmap://map/routeplan?type=drive&fromcoord=CurrentLocation&tocoord=\(coord.latitude),\(coord.longitude)&referer=Lark"
                case .google:
                    url = "comgooglemaps://?daddr=\(coord.latitude),\(coord.longitude)&directionsmode=driving"
                    urlWithoutDestinationName = url
                case .waze:
                    url = "https://waze.com/ul?ll=\(coord.latitude),\(coord.longitude)&navigate=yes"
                    urlWithoutDestinationName = url
                default:
                    url = "http://maps.apple.com/?daddr=\(coord.latitude),\(coord.longitude)&dirflg=d&t=m"
                    urlWithoutDestinationName = url
            }
            if let newURL = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                return URL(string: newURL)
            }
            return URL(string: urlWithoutDestinationName)
        }
    }

    /// 默认的TableCell高度
    public static let cellHeight = CGFloat(70.0)
    /// 默认的Footer高度
    public static let footerHeight = CGFloat(44.0)
    public static var mapMaxHeight: CGFloat { CGFloat(280.0 / 736) * UIScreen.main.bounds.height }
    public static var mapMinHeight: CGFloat { CGFloat(110.0 / 736) * UIScreen.main.bounds.height }
    public static let locationCellID = "LarkLocationCell"
    /// UserDefault的key
    private static let userLocationKey = KVKey<[CLLocationDegrees]?>("defaultUserLocation")
    /// 一次搜索所显示的item数量
    public static let defaultPageOffset = 24

    static private let mapURLDics = [LocationType.apple,
                              LocationType.gaode,
                              LocationType.baidu,
                              LocationType.google,
                              LocationType.tencent,
                              LocationType.waze]

    private static let globalStore = KVStores.udkv(
        space: .global,
        domain: Domain.biz.core.child("LocationPicker")
    )

    /// 将定位存在UserDefault
    static public func stashUserLocation(location: CLLocationCoordinate2D) {
        let location = [location.latitude, location.longitude]
        globalStore[userLocationKey] = location
    }

    /// 将定位从UserDefault中取出
    static public func getStatshUserLocation() -> CLLocationCoordinate2D? {
        if let location = globalStore[userLocationKey] {
            let center = CLLocationCoordinate2D(latitude: location[0], longitude: location[1])
            return center
        }
        return nil
    }

    // 计算两个坐标间的距离（米）
    static public func calculateDistance(from: CLLocationCoordinate2D?, to: CLLocationCoordinate2D) -> String {
        guard let source = from else {
            return "0米"
        }
        let src = CLLocation(latitude: source.latitude, longitude: source.longitude)
        let sink = CLLocation(latitude: to.latitude, longitude: to.longitude)
        let distance = sink.distance(from: src)
        if distance < 1_000 {
            return String(format: "%d米", Int64(sink.distance(from: src)))
        }
        return String(format: "%.2f公里", sink.distance(from: src) / 1_000)
    }

    static public func createHighlightedString(text: String, keywords: String, color: UIColor) -> NSAttributedString {
        var ranges: [NSRange] = []
        var str = NSString(string: text)
        while str.contains(keywords) {
            ranges.append(str.range(of: keywords))
            str = str.substring(from: str.range(of: keywords).upperBound) as NSString
        }
        print("\(ranges)")
        /* 如果搜索结果不包括关键词，返回空 */
        guard !ranges.isEmpty else {
            return NSAttributedString(string: text)
        }
        return createHighlightedString(text: text, ranges: ranges, color: color)
    }

    // 设置搜索结果高亮
    static public func createHighlightedString(text: String, ranges: [NSRange], color: UIColor) -> NSAttributedString {
        let highlightedString = NSMutableAttributedString(string: text, attributes: [.kern: 0.0])

        // Each `NSValue` wraps an `NSRange` that can be used as a style attribute's range with `NSAttributedString`.
        ranges.forEach { (range) in
            highlightedString.addAttribute(
                .foregroundColor,
                value: color,
                range: range
            )
        }
        return highlightedString
    }

    /// 地图mapSheet
    /// - Parameters:
    ///   - vc:
    ///   - query: 搜索地点
    ///   - completion: 跳转外部地图是否成功的回调
    static public func showMapSelectionSheet(from vc: UIViewController,
                                               query: String,
                                               openCompletionHandler completion: ((Bool) -> Void)? = nil ) {

        let installedMaps = searchAvailableMap()

        // 如果没有安装任何地图App，跳转到App Store下载
        if installedMaps.isEmpty {
            guard let appURI = LocationType.apple.coordinateToURL(query: query) else {
                return
            }
            UIApplication.shared.open(appURI, options: [:], completionHandler: completion)
        }
        /// 只有一个地图的时候不用出action sheet 直接跳转
        if installedMaps.count == 1 {
            let map = installedMaps[0]
            guard let appURI = map.coordinateToURL(query: query) else {
                return
            }
            UIApplication.shared.open(appURI, options: [:], completionHandler: completion)
        } else {
            let mapActionSheet = ActionSheet()
            /// 添加已经安装的地图App Item
            for map in installedMaps {
                mapActionSheet.addItem(
                    title: map.map,
                    action: {
                        guard let appURI = map.coordinateToURL(query: query) else {
                            return
                        }
                        UIApplication.shared.open(appURI, options: [:], completionHandler: completion)
                    }
                )
            }
            /// 取消
            mapActionSheet.addCancelItem(title: BundleI18n.LarkLocationPicker.Lark_Legacy_Cancel)
            vc.present(mapActionSheet, animated: true, completion: nil)
        }
    }

    /// 地图mapSheet
    /// - Parameters:
    ///   - vc:
    ///   - isInternal: 是否是国际地图
    ///   - locationName:
    ///   - latitude:
    ///   - longitude:
    ///   - completion: 跳转外部地图是否成功的回调
    static public func showMapSelectionSheet(from vc: UIViewController,
                                             isInternal: Bool,
                                             isGcj02: Bool = false,
                                             locationName: String,
                                             latitude: Double,
                                             longitude: Double,
                                             openCompletionHandler completion: ((Bool) -> Void)? = nil ) {
        let wgs84coord = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

        let installedMaps = searchAvailableMap()

        // 如果没有安装任何地图App，跳转到App Store下载
        if installedMaps.isEmpty {
            guard let appURI = LocationType.apple.coordinateToURL(
                isInternal: isInternal,
                isGcj02: isGcj02,
                destination: locationName,
                wgs84coord: wgs84coord) else {
                return
            }
            UIApplication.shared.open(appURI, options: [:], completionHandler: completion)
        }
        /// 只有一个地图的时候不用出action sheet 直接跳转
        if installedMaps.count == 1 {
            let map = installedMaps[0]
            guard let appURI = map.coordinateToURL(
                isInternal: isInternal,
                isGcj02: isGcj02,
                destination: locationName,
                wgs84coord: wgs84coord) else {
                return
            }
            UIApplication.shared.open(appURI, options: [:], completionHandler: completion)
        } else {
            let mapActionSheet = ActionSheet()
            /// 添加已经安装的地图App Item
            for map in installedMaps {
                mapActionSheet.addItem(
                    title: map.map,
                    action: {
                        guard let appURI = map.coordinateToURL(isInternal: isInternal,
                                                               isGcj02: isGcj02,
                                                               destination: locationName,
                                                               wgs84coord: wgs84coord) else {
                            return
                        }
                        UIApplication.shared.open(appURI, options: [:], completionHandler: completion)
                    }
                )
            }
            /// 取消
            mapActionSheet.addCancelItem(title: BundleI18n.LarkLocationPicker.Lark_Legacy_Cancel)
            vc.present(mapActionSheet, animated: true, completion: nil)
        }
    }

    /// 搜索已经安装的地图App
    static private func searchAvailableMap() -> [LocationType] {
        var installedMaps: [LocationType] = []
        for item in mapURLDics {
            if UIApplication.shared.canOpenURL(URL(string: item.url)!) {
                installedMaps.append(item)
            }
        }
        return installedMaps
    }
}
