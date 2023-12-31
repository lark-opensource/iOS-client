//
//  IconType.swift
//  LarkIcon
//
//  Created by huangzhikai on 2023/12/13.
//

import Foundation

//{\"type\":0,\"key\":\"\",\"obj_type\":22,\"file_type\":null,\"token\":\"F1tudt2qdo1pCpxmBXkblYXGc3c\",\"version\":1}"
/// 0 : 无icon， 1: 表情符号类型，unicode字符， 2.， image 图片类型key，通过转换和拼接可以获得url
public enum IconType {
    case none
    case unicode
    case image
    case word
    
    public init(rawValue: Int) {
        switch rawValue {
        case 0: do { self = .none }
        case 1: do { self = .unicode }
        case 2: do { self = .image }
        case 3: do { self = .word }
        default: do { self = .none }
        }
    }
    
    // enable-lint: magic number
    // nolint: magic number
    public var rawValue: Int {
        switch self {
        case .none:        return 0
        case .unicode:     return 1
        case .image:       return 2
        case .word:        return 3
        }
    }
}
