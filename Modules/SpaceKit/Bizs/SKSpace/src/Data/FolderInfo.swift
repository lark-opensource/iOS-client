//
//  FolderInfo.swift
//  SKSpace
//
//  Created by Weston Wu on 2021/6/15.
//

import Foundation
import SKCommon
import SwiftyJSON

/// 一个文件夹
public final class FolderInfo: SKListData {
    public var name: String = ""
    public var folderNodeToken: FileListDefine.NodeToken = ""
    public var files: [SpaceEntry] = []
}

/// [Token: folderInfo]的map
public struct FolderInfoMap {
    public var folders: [FileListDefine.NodeToken: FolderInfo] = [:]
    public var ownerJSON: JSON?
    public var error: NSError?
}
