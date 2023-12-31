//
//  TourConfigAPI.swift
//  LarkTour
//
//  Created by Jiayun Huang on 2020/5/15.
//

import Foundation

import RxSwift

protocol TourConfigAPI {
    /// 获取字节云平台指定key对应的value
    func fetchSettingsRequest(fields: [String]) -> Observable<[String: String]>
}
