//
//  SpaceThumbnailManager+SimpleMode.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2020/5/19.
//  

import SKFoundation

extension SpaceThumbnailManager: SimpleModeObserver {
    public func deleteFilesInSimpleMode(_ files: [SimpleModeWillDeleteFile], completion: (() -> Void)?) {
        DocsLogger.info("space.thumbnail.manager --- cleaning data in simple mode")
        let tokens = files.map { $0.objToken }
        cache.cleanUp(tokens: tokens, completion: completion)
    }
}
