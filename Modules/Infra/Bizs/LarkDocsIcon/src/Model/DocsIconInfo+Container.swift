//
//  DocsIconInfo+Container.swift
//  LarkDocsIcon
//
//  Created by huangzhikai on 2023/6/20.
//

import Foundation
import UniverseDesignIcon
extension DocsIconInfo {
    
    static func getContainerImage(container: ContainerInfo?) -> UIImage? {
        
        guard let container = container else {
            DocsIconLogger.logger.info("container is nil")
            return nil
        }
        
        if container.isShareFolder {
            return DocsIconCreateUtil.creatImage(image: UDIcon.getIconByKeyNoLimitSize(.fileSharefolderColorful),
                                                 isShortCut: container.isShortCut)
        } else if container.isWikiRoot {
            if container.wikiCustomIconEnable {
                // 知识库自定义iconFG打开时，不再拦截展示默认icon
                return nil
            }
            return DocsIconCreateUtil.creatImage(image: UDIcon.wikiColorful,
                                                 isShortCut: container.isShortCut)
        }
        return nil
        
    }
    
}
