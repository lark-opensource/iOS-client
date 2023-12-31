//
//  BlockitMonitor.swift
//  Blockit
//
//  Created by 王飞 on 2021/11/16.
//

import ECOProbe
import OPSDK
import OPBlockInterface
import OPFoundation

extension OPMonitor {
    // uniqueID Common: 与setUniqueID的通用公参保持对齐，setUniqueID 目前嵌在ttmicroapp里blockit不应该依赖，后续应该拆成base，然后blockit依赖base
    @discardableResult
    func setCommon(_ config: OPBlockContainerConfigProtocol) -> OPMonitor {
        addCategoryValue("app_id", config.uniqueID.appID)
        addCategoryValue("application_id", config.uniqueID.appID)
        addCategoryValue("app_type", OPAppTypeToString(config.uniqueID.appType))
        addCategoryValue("identifier", config.uniqueID.identifier)
        addCategoryValue("version_type", OPAppVersionTypeToString(config.uniqueID.versionType))
        addCategoryValue("container_id", config.containerID)
        addCategoryValue("block_type_id", config.blockInfo?.blockTypeID)
        addCategoryValue("block_id", config.blockInfo?.blockID)
        addCategoryValue("host", config.host)
        tracing(config.trace)
        return self
    }
}
