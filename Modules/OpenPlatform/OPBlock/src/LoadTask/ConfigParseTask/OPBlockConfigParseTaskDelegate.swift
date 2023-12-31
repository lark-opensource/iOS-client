//
//  OPBlockConfigParseTaskDelegate.swift
//  OPSDK
//
//  Created by yinyuan on 2020/11/16.
//

import Foundation
import OPSDK
import OPBlockInterface

class OPBlockConfigParseTaskInput: OPTaskInput {
    
}

class OPBlockConfigParseTaskOutput: OPTaskOutput {
    
    let projectConfig: OPBlockProjectConfig
    
    let blockConfig: OPBlockConfig
    
    var packageReader: OPPackageReaderProtocol
    
    required init(
        projectConfig: OPBlockProjectConfig,
        blockConfig: OPBlockConfig,
        packageReader: OPPackageReaderProtocol) {
        self.projectConfig = projectConfig
        self.blockConfig = blockConfig
        self.packageReader = packageReader
    }
    
}
