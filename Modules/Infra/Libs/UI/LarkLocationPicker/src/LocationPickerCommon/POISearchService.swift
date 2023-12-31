//
//  POISearchService.swift
//  LarkLocationPicker
//
//  Created by Fangzhou Liu on 2019/7/23.
//

import Foundation
import LarkLocalizations
import RxSwift
import RxCocoa
import MapKit

typealias SearchPOIResponse = Result<(UILocationData), Error>

public protocol SearchAPIDelegate: AnyObject {
    // 搜索返回错误
    func searchFailed(err: Error)
    // 输入提示结束
    func searchInputTipDone(keyword: String, data: [(UILocationData, Bool)])
    // 搜索结束
    // POI搜索 keyword为nil
    // 关键字搜索 keyword为request的关键字
    func searchDone(keyword: String?, data: [UILocationData], isFirstPage: Bool)
    // 反解析结束
    func reGeocodeDone(data: UILocationData)
    // 超出地图范围
    func regionOutOfService(current: UILocationData)
    // 反解析错误
    func reGeocodeFailed(data: UILocationData, err: Error)
}

//回调
public protocol SearchPOIDelegate: AnyObject {
    // 搜索结果
    func searchPOIDone(data: [LocationData])
    // 搜索返回错误
    func searchFailed(err: Error)
}

/// 搜索SDK的调用
/// 国内用高德，国外用苹果
///
/// - apple: 苹果地图
/// - amap: 高德地图
public enum MapType: String {
    case apple = "apple"
    case amap = "gaode"
}

/// 打点使用
/// 从哪里选择的地址
///
/// - defaultType: 默认位置
/// - list: 列表选择
/// - search: 搜索选择
public enum SelectedType: String {
    case defaultType = "defatult"
    case list = "list"
    case search = "search"
}

public enum CoordinateSystem {
    case wgs84 // 全部转为WGS-84坐标
    case origin // 直接用搜索出的坐标，不用坐标系转化
}
