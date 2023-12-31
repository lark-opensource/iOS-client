//
//  LarkBoxSetting.swift
//  LarkBoxSetting-LarkBoxSettingAuto
//
//  Created by aslan on 2023/2/23.
//

import Foundation
import LKCommonsLogging
import LarkReleaseConfig
import RxSwift

public class BoxSetting {

    static let logger = Logger.log(BoxSetting.self)
    /// 有需要监听box实时获取信号的，可以用单例获取
    public static let shared = BoxSetting()

    let dataChangeSubject: PublishSubject<Bool> = PublishSubject<Bool>()
    /// 值变化的信号
    public var boxOffChangeObservable: Observable<Bool> {
        return dataChangeSubject.asObservable()
    }

    public func isBoxOff() -> Bool {
        return Self.isBoxOff()
    }

    ///  如果返回值是 true，需要关掉入口
    public static func isBoxOff() -> Bool {
        if ReleaseConfig.isKAEnterprise {
             /// 如果是私有化企业签打包，可以动态下发小程序
             return false
         }
        let isOn = BoxSettingStore().getConfig()
        Self.logger.info("fetch boxsetting, return is: \(isOn)")
        return isOn
    }
}
