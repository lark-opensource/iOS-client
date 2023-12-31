//
//  FilesListSection.swift
//  Alamofire
//
//  Created by weidong fu on 23/11/2017.
//

import UIKit

@objc
public enum FileSource: Int, CaseIterable {
    case unknown = 0
    case personal
    case share
    case recent
    case trash
    case favorites
    case shareFolder
    case manualOffline
    case pin //快速访问界面
    case subFolder // 子文件夹内
}
