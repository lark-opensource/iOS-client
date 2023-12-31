//
//  Alias.swift
//  LarkLeanMode
//
//  Created by 袁平 on 2020/3/4.
//

import Foundation
import RustPB

typealias Resources = BundleResources.LarkLeanMode
typealias I18n = BundleI18n.LarkLeanMode

public typealias SyncDataStrategy = Basic_V1_SyncDataStrategy

typealias PushLeanModeStatusAndAuthorityResponse = Im_V1_PushLeanModeStatusAndAuthorityResponse

typealias PushLeanModeSwitchFailedByAuthorityChangeResponse = Im_V1_PushLeanModeSwitchFailedByAuthorityChangeResponse

public typealias PushCleanDataResponse = Device_V1_PushCleanDataResponse

typealias PatchLeanModeStatusRequest = Im_V1_PatchLeanModeStatusRequest
typealias PatchLeanModeStatusResponse = Im_V1_PatchLeanModeStatusResponse

typealias PullLeanModeStatusAndAuthorityResponse = Im_V1_PullLeanModeStatusAndAuthorityResponse
typealias PullLeanModeStatusAndAuthorityRequest = Im_V1_PullLeanModeStatusAndAuthorityRequest

typealias PatchLockScreenCfgRequest = Im_V1_PatchLockScreenCfgRequest
public typealias PatchLockScreenCfgResponse = Im_V1_PatchLockScreenCfgResponse
public typealias LockScreenConfig = Basic_V1_LockScreenCfg
