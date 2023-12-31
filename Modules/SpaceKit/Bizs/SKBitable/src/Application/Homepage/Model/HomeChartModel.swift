//
//  SKBitableRecommendNativeController.swift
//  SKBitable
//
//  Created by justin on 2023/8/30.
//

import Foundation
import UIKit
import SKFoundation
import SwiftyJSON
import SKCommon

typealias chartLynxData = [String: Any]

// 首页图表响应
class ChartResponse {
    private(set) var charts: [Chart] = []
    private(set) var userType: Int?
    
    
    init(_ json: JSON) {
        if let userType = json["user_type"].int { self.userType = userType }
        if let charts = json["charts"].array {
            self.charts = charts.map({ chartJson in
                let chart = Chart(chartJson)
                return chart
            })
        }
    }
    
    func updateCharts(_ charts:[Chart]) {
        self.charts = charts
    }
    
    func toJsonData() -> Data? {
        do {
            let data = try JSONSerialization.data(withJSONObject: toMap(), options: [])
            return data
        } catch {
            return nil
        }
    }
    
    func toMap() -> [String: Any] {
        let chartsObj = charts.map { chart in
            return chart.toMap()
        }
        
        return ["user_type": userType ?? 0,"charts": chartsObj] as [String : Any]
    }
}


class ChartInDashboard {
    private(set) var token: String?
    private(set) var type: String?
    private(set) var name: String?
    init(_ json: JSON) {
        if let token = json["token"].string { self.token = token }
        if let type = json["type"].string { self.type = type }
        if let name = json["name"].string { self.name = name }
    }
}

// Dashboard 插入页面相应
class DashboardResponse {
    private(set) var isTemplate: Bool = false
    private(set) var dashboards: [Dashboard] = []
    init(_ json: JSON) {
        if let isTemplate = json["is_template"].bool { self.isTemplate = isTemplate }
        if let dashboards = json["dashboards"].array {
            self.dashboards = dashboards.map({ dashboardJson in
                let dashboard = Dashboard(dashboardJson)
                return dashboard
            })
        }
    }
}

class Dashboard {
    private(set) var charts: [ChartInDashboard] = []
    private(set) var token: String?
    private(set) var name: String?
    
    func updateCharts(charts: [ChartInDashboard]) {
        self.charts = charts
    }
    
    init(_ json: JSON) {
        if let token = json["token"].string { self.token = token }
        if let name = json["name"].string { self.name = name }
        if let charts = json["charts"].array {
            self.charts = charts.map({ chartJson in
                let chart = ChartInDashboard(chartJson)
                return chart
            })
        }
    }
}

enum ChartType: String {
    case column
    case line
    case combo
    case bar
    case scatter
    case pie
    case statistics
    case wordCloud
    case funnel
}

enum ChartScene: String {
    case add = "add"
    case home = "home"
    case homeEdit = "home_edit"
    case fullScreen = "fullscreen"
}

class Chart {
    
    var token: String?
    var type: ChartType?
    var baseName: String?
    var baseToken: String?
    var isTemplate: Bool = false
    var dashboardUrl: String?
    var baseIcon: String?
    var dashboardToken: String?
    var name: String?
    var status: Int?
    var isSelected: Bool = false
    
    // 赋值属性
    var gradientStyle: ChartGradientSTyle = .blue
    //标记图表是在什么场景，需要传回 lynxRender用于埋点
    private(set) var scene: ChartScene = .home
    
    init(_ json: JSON) {
        if let token = json["token"].string { self.token = token }
        if let type = json["type"].string { self.type = ChartType(rawValue: type) }
        if let baseName = json["base_name"].string { self.baseName = baseName }
        if let baseToken = json["base_token"].string { self.baseToken = baseToken }
        if let isTemplate = json["is_template"].bool { self.isTemplate = isTemplate }
        if let dashboardUrl = json["dashboard_url"].string { self.dashboardUrl = dashboardUrl }
        if let baseIcon = json["base_icon"].string { self.baseIcon = baseIcon }
        if let dashboardToken = json["dashboard_token"].string { self.dashboardToken = dashboardToken }
        if let name = json["name"].string { self.name = name }
        if let status = json["status"].int { self.status = status }
        if let scene = json["scene"].string { self.scene = ChartScene(rawValue: scene) ?? .home }
    }
    
    func updateScene(scene: ChartScene) {
        self.scene = scene
    }
    
    func toMap() -> [String:Any] {
        return ["token":self.token ?? "",
                     "type":self.type?.rawValue ?? "",
                     "base_name":self.baseName ?? "",
                     "base_token":self.baseToken ?? "",
                     "is_template":self.isTemplate,
                     "dashboard_url":self.dashboardUrl ?? "",
                     "base_icon":self.baseIcon ?? "",
                     "dashboard_token":self.dashboardToken ?? "",
                     "name":self.name ?? "",
                     "status":self.status ?? 0,
                    ]
    }
}

// MARK: - Request model
// 更新用户图表请求
struct UpdateChartRequestParam {
    // 服务端入参
    let chartTokens: [String]
    
    func transformToDict() -> [String: Any] {
        var dict: [String: Any] =  [:]
        dict["chart_tokens"] = chartTokens
        dict["version"] = Int64(Date().timeIntervalSince1970 * 1000)
        return dict
    }
}

// 查询单个图表slice数据请求入参
struct ChartSliceRequestParam {
    // 服务端入参
    let chartToken: String
    
    func transformToDict() -> [String: Any] {
        var dict: [String: Any] =  [:]
        dict["token"] = chartToken
        return dict
    }
}

// 根据 Base ID 获取 仪表盘骨架信息
struct SkeletonRequestParam {
    // 服务端入参
    let token: String
    
    func transformToDict() -> [String: Any] {
        var dict: [String: Any] =  [:]
        dict["token"] = token
        return dict
    }
}
