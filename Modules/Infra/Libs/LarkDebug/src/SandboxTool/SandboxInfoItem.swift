//
//  SandboxInfoItem.swift
//  swit_test
//
//  Created by liluobin on 2021/6/29.
//
#if !LARK_NO_DEBUG
import UIKit
enum SandboxFileType {
    case file
    case directory
}
final class SandboxInfoItem {
    var name: String = ""
    var path: String = ""
    var type: SandboxFileType = .file
}
#endif
