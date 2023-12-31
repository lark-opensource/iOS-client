//
//  DeviceManagerAPI.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2022/4/12.
//

import RxSwift
import Alamofire
import LarkContainer
import LarkSecurityComplianceInfra

struct DeviceManagerAPI {

    @Provider private var client: HTTPClient // Global

    func ping() -> Observable<BaseResponse<PingResp>> {
        return client.request(HTTPRequest(path: "/ping"))
    }

    // C端-获取申报状态
    func getDeviceApplyStatus() -> Observable<BaseResponse<GetDeviceApplyStatusResp>> {
        let req = HTTPRequest(path: "/device/apply_status")
        return client.request(req).retry(1)
    }

    // C端-获取自主申报开关
    func getDeviceApplySwitch() -> Observable<BaseResponse<GetDeviceApplySwitchResp>> {
        let req = HTTPRequest(path: "/device/apply_switch")
        return client.request(req).retry(1)
    }
    // C端-尝试绑定设备did
    func bindDevice() -> Observable<BaseResponse<BindDeviceResp>> {
        let req = HTTPRequest(path: "/device/bind", method: .post)
        return client.request(req)
    }

    // C端-检查设备did是否存在
    func checkDevice() -> Observable<BaseResponse<CheckDeviceResp>> {
        return client.request(HTTPRequest(path: "/device/check"))
    }

    // C端-绑定webdid到did
    func bindDeviceWeb(_ webDid: String) -> Observable<BaseResponse<BindDeviceWebResp>> {
        return client.request(HTTPRequest(path: "/device/bind_web",
                                          method: .post,
                                          params: ["webdid": webDid]))
    }

    // C端-申报设备
    func applyDevice(ownership: Int, applyReason: String) -> Observable<BaseResponse<ApplyDeviceResp>> {
        return client.request(HTTPRequest(path: "/device/apply",
                                          method: .post,
                                          params: ["ownership": ownership,
                                                   "apply_reason": applyReason]))
    }

    // C端-获取设备信息
    func getDeviceInfo() -> Observable<BaseResponse<GetDeviceInfoResp>> {
        return client.request(HTTPRequest(path: "/device/info"))
    }
}
