//
//  ArchiveFileInfoProcessor.swift
//  SpaceKit
//
//  Created by bupozhuang on 2020/1/9.
//

import Foundation
import SKFoundation

class ArchiveFileInfoProcessor: DefaultFileInfoProcessor {
    override var useCacheIfExist: Bool {
        if networkStatus.isReachable {
            return false // 有网络不打缓存的开源文件，从网络加载json目录信息
        } else {
            return true  // 无网络的情况下如果已经缓存源文件，用源文件打开，显示不支持预览
        }
    }
}
