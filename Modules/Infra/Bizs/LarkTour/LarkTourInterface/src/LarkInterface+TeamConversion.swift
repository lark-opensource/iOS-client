//
//  LarkInterface+TeamConversion.swift
//  LarkTourInterface
//
//  Created by Meng on 2020/2/28.
//

import UIKit
import Foundation

public protocol TeamConversionService: AnyObject {
    // note: 有其他团队依赖，暂时先留着，其他业务先下掉后，再删
    func successUpgradeTeam<T: UIViewController>(path: String,
                                                 sourceScenes: String,
                                                 lastVCType: T.Type?,
                                                 from: UIViewController?)
}
