//
//  NoPermissionActionInterceptor.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2022/5/17.
//

import Foundation
import SwiftyJSON

public protocol NoPermissionActionInterceptor {
    func addInterceptorHandler(_ handler: NoPermissionActionInterceptorHandler?)
    func removeInterceptorHandler(_ handler: NoPermissionActionInterceptorHandler?)
    func onInterceptorCompleted()
}

@objc
public protocol NoPermissionActionInterceptorHandler: AnyObject {
    var bizPriority: Int { get }
    var bizName: NSString { get }
    func needIntercept() -> Bool
    func onReceiveSecurityAction(_ action: NSString, extra: [NSString: NSNumber])
}
