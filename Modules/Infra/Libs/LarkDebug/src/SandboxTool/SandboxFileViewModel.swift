//
//  SandboxFileViewModel.swift
//  swit_test
//
//  Created by bytedance on 2021/7/11.
//
import Foundation
#if !LARK_NO_DEBUG
import UIKit

final class SandboxFileViewModel {
    var datas: [SandboxInfoItem] = []
    let rootPath = NSHomeDirectory()
    var refreshCallBack: (() -> Void)?
    var currentPath: String {
        didSet {
            loadDataForPath(currentPath)
        }
    }
    var isRootDic: Bool {
        return currentPath == rootPath
    }
    var title: String {
        return isRootDic ? "沙盒浏览器" : FileManager.default.displayName(atPath: currentPath)
    }
    init() {
        currentPath = rootPath
        loadDataForPath(currentPath)
    }

   private func loadDataForPath(_ path: String) {
        guard let paths = try? FileManager.default.contentsOfDirectory(atPath: path) else {
            datas = []
            refreshCallBack?()
            return
        }
        datas = paths.map({ subPath in
            let fullPath = path + "/" + subPath
            var isDir: ObjCBool = false
            FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDir)
            let item = SandboxInfoItem()
            item.path = fullPath
            item.type = isDir.boolValue ? .directory : .file
            item.name = subPath
            return item
        })
        refreshCallBack?()
    }
    func lastHierarchy() {
        currentPath = (currentPath as NSString).deletingLastPathComponent
    }
}
#endif
