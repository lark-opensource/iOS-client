//
//  OPBlockitBizErrorCode.swift
//  OPBlockInterface
//
//  Created by Jiayun Huang on 2023/5/9.
//

import Foundation

public enum OPBlockitEntityBizErrorCode: Int {
    case invalidCode = 1
    case unpackFailure = 2
}

public enum OPBlockitEntityResultErrorCode: Int {
    case invalidEntity = 1
    case invalidBlockId = 2
    case invalidInfos = 3
    case getEntityFail = 4
}

public enum OPBlockitMountInternalErrorCode: Int {
    case hostUnavailable = 1
    case containerNotFound = 2
    case getBlockEntityError = 3
}

public enum OPBlockitMountParamErrorCode: Int {
    case mountByEntityParamInvalid = 1
    case mountByBlockIdParamInvalid = 2
    case mountCreatorParamInvalid = 3
}

public enum OPBlockitGuideInfoBizErrorCode: Int {
    case invalidType = 1
    case invalidCode = 2
    case parseDataFail = 3
    case parseInjectedDataFail = 4
    case injectedDataInvalidType = 5
}

public enum OPBlockitLoadMetaFailErrorCode: Int {
    case outputMetaInvalidType = 1
    case illegalMetaVersion = 2
    case noMeta = 3
}

public enum OPBlockitLoadPkgFailErrorCode: Int {
    case outputNoPkg = 1
    case loadNoPkg = 2
}

public enum OPBlockitParsePkgFailErrorCode: Int {
    case blockConfigNotFound = 1
    case noPackageReader = 2
}

public enum OPBlockitLaunchInternalErrorCode: Int {
    case invalidLoadTaskInput = 1
    case invalidBundleTaskInput = 2
    case invalidGuideInfoTaskInout = 3
    case invalidContainerConfig = 4
    case createGuideInfoRequestFail = 5
    case getMetaUrlFail = 6
}

public enum OPBlockitComponentErrorCode: Int {
    case invalidConfigTaskOutput = 1
    case invalidContainerConfig = 2
    case invalidMeta = 3
    case webRenderUnusable = 4
    case invalidJsPath = 5
    case createComponentFail = 6
    case fromFailListener = 7 // component_fail listener 事件通知
    case inputNil = 8
    case switchToComponentFail = 12
}
