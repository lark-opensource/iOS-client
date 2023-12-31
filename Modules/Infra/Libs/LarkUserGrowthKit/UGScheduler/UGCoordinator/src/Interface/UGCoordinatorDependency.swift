//
//  UGCoordinatorDependency.swift
//  UGCoodinator
//
//  Created by zhenning on 2021/1/21.
//

import Foundation
public protocol UGCoordinatorDependency {
    /// 从存储中拿到当前需要调度的所有触达点位的初始信息
    func getExampleReachPointEntitys() -> [UGReachPointEntity]

    /// 从存储中拿到当前需要调度的所有触达点位的初始信息
    func getTestCaseReachPointEntitys() -> [UGReachPointEntity]
}
