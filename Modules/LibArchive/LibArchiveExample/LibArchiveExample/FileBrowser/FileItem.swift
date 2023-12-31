//
//  FileItem.swift
//  ArchiveDemo
//
//  Created by ZhangYuanping on 2021/8/30.
//  


import Foundation

enum FileItemType {
    case none
    case up
    case directory
    case file
}

struct FileItem {
    var name: String = ""
    var path: String = ""
    var type: FileItemType = .none
}
