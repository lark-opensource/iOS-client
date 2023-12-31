//
//  OPBlockConfig.swift
//  OPSDK
//
//  Created by yinyuan on 2020/11/17.
//

import Foundation
import OPSDK

public final class OPBlockProjectConfig: OPProjectConfig {
    
    public override func preParsePropeties(_ appendPropeties: [Any] = []) -> [Any] {
        super.preParsePropeties(appendPropeties) + [blocks]
    }
    
    public lazy var blocks: [OPBlockConfig]? = {
        
        guard let blocks = configData["blocks"] as? [String] else {
            return nil
        }
        
        return blocks.map { (path) -> OPBlockConfig in
            OPBlockConfig(basePath: path, reader: reader)
        }
    }()
}

public final class OPBlockConfig: OPFileConfig {
    
    public override func preParsePropeties(_ appendPropeties: [Any] = []) -> [Any] {
        super.preParsePropeties(appendPropeties) + [blockid, navigationBarTitleText, creator]
    }

    /// 对应的 html 文件的路径，包含后缀
    public lazy var htmlPath: String = {
        "\(basePath).html"
    }()
    
    public lazy var blockid: String? = {
        return configData["blockid"] as? String
    }()

    public lazy var navigationBarTitleText: String? = {
        return configData["navigationBarTitleText"] as? String
    }()

    public lazy var creator: OPBlockCreatorConfig? = {
        guard let creator = configData["creator"] as? String else {
            return nil
        }
        return OPBlockCreatorConfig(basePath: creator, reader: reader)
    }()

    public lazy var darkmode: Bool? = {
        return configData["darkmode"] as? Bool
    }()

}

public final class OPBlockCreatorConfig: OPFileConfig {
    
}
