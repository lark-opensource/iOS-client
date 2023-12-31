//
//  MetricParams.swift
//  LarkContact
//
//  Created by shizhengyu on 2019/12/29.
//

import Foundation

enum MetricParams {

    static func errorMsg(_ errorCode: Int32) -> String {
        switch errorCode {
        case 20_001_501: return "发送失败，请重试"
        case 20_001_502: return "请输入正确的邮箱"
        case 20_001_503: return "发送超时，请重试"
        case 20_001_504: return "生成邀请失败，请重试"
        case 20_001_505: return "请输入正确的手机号码"
        case 20_001_506: return "用户已存在！"
        case 20_001_601: return "姓名太长！"
        case 20_001_602: return "姓名格式错误！"
        default: return "未知错误"
        }
    }
}
