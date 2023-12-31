//
//  DriveAuditResult.swift
//  SpaceKit
//
//  Created by bupozhuang on 2019/7/14.

import Foundation
import RxSwift
import RxCocoa
import UIKit
import SKCommon
import SKFoundation
import SpaceInterface
import SKUIKit

typealias DriveAuditState = (result: DriveAuditResult, reason: DriveAuditFailedReason)

/// 文件审核状态
enum DriveAuditResult {
    /// 审核通过
    case legal
    /// 审核不通过，用户是文件所有者
    case ownerIllegal
    /// 审核不通过，用户不是所有者
    case collaboratorIllegal
}

/// 文件审核失败原因
enum DriveAuditFailedReason {
    case none
    /// 机器审核不过
    case machineAuditFailed
    /// 人工审核不过或者举报不过
    case humanAuditFailed
}
