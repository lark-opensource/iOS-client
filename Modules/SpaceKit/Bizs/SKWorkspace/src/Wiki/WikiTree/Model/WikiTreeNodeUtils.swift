//
//  WikiTreeNodeUtils.swift
//  SpaceKit
//
//  Created by liweiye on 2019/10/18.
//

import Foundation
import SKCommon
import SKFoundation
import SpaceInterface

public class WikiTreeNodeUtils {
    public static func getWikiNodeMeta(treeMeta: WikiTreeNodeMeta) -> WikiNodeMeta {
        WikiNodeMeta(wikiToken: treeMeta.wikiToken,
                     objToken: treeMeta.objToken,
                     docsType: treeMeta.objType,
                     spaceID: treeMeta.spaceID)
    }
}
