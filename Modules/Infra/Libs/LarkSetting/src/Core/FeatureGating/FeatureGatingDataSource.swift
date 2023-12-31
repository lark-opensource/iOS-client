//
//  FeatureGatingDataSource.swift
//  LarkSetting
//
//  Created by 王元洵 on 2023/3/1.
//

/// FeatureGatingDatasource 主要功能是向FeatureGating数据源获取数据，并解除依赖
protocol FeatureGatingDatasource: AnyObject {
    func fetchImmutableFeatureGating(with id: String)
    func fetchImmutableFeatureGating(with id: String, and key: String) throws -> Bool
    func fetchGlobalFeatureGating(deviceID: String)
}
