//
//  OPDiagnoseRunnerContext.swift
//  OPSDK
//
//  Created by 尹清正 on 2021/2/18.
//

import Foundation
import LarkOPInterface

/// DiagnoseRunner执行完毕时调用的回调函数
public typealias OPDiagnoseRunnerCallback = (_ error: OPError?, _ response: [String:Any]) -> Void

/// DiagnoseRunner上下文，封装了运行一个DiagnoseRunner所需要的全部信息，包括DiagnoseRunner传入的参数以及运行完成之后对应的回调
@objcMembers public final class OPDiagnoseRunnerContext: NSObject {
    /// 此次执行的参数
    public var params: [String: Any]
    /// 此次执行过程中产生的响应数据
    public var response: [String: Any]
    /// 保存此次runner执行的回调
    public var callback: OPDiagnoseRunnerCallback?
    /// 保存触发此次runner执行的小程序所处的controller
    public var controller: UIViewController?

    public init(params: [String: Any]?) {
        self.params = params ?? [:]
        response = [String: Any]()
    }

    /// 表示该次runner执行失败，返回对应的Error
    public func execCallback(withError error: OPError) {
        callback?(error, response)
    }

    /// 表示该次runner执行成功，返回数据
    public func execCallbackSuccess() {
        callback?(nil, response)
    }
}
