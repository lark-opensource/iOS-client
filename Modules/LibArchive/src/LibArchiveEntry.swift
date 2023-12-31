//
//  LibArchiveEntry.swift
//  LibArchiveExample
//
//  Created by ZhangYuanping on 2021/9/28.
//  


import Foundation

public struct LibArchiveEntry {
    public enum EntryType: Int {
        case directory = 16384
        case file = 32768
    }
    
    public var type: EntryType
    public var path: String
    public var size: UInt64
    
    public init(type: EntryType, path: String, size: UInt64) {
        self.type = type
        self.path = path
        self.size = size
    }
}
