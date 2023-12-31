//
//  DemoVC.swift
//  LarkCacheDev
//
//  Created by Supeng on 2020/8/18.
//

import UIKit
import Foundation
import LarkCache

//enum Test: Biz {
//    static var parent: Biz.Type?
//    static var path: String = "Test"
//}
//
//class DemoVC1: UIViewController {
//    let fileName = "test.txt"
//
//    /// 会在Document/Messenger/Test目录下创建缓存文件夹以及缓存DB
//    let cache = CacheManager.shared.cache(biz: Test.self, directory: .cache)
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        view.backgroundColor = .white
//
//        // 通过cach.config.cachPath获取缓存路径
//        let fileDownloadPath = cache.rootPath + "/" + fileName
//
//        // 假装下载文件
//        try? "Not important content".write(toFile: fileDownloadPath, atomically: true, encoding: .utf8)
//
//        // 文件下载成功后，需要调用一下saveFileName方法，在DB中记录文件信息
//        // 需要确保在cache.rootPath目录下，存在fileName文件，才能保存成功
//        let saveSucceed = cache.saveFileName(fileName)
//        assert(saveSucceed)
//
//        // 调用saveFileName(fileName:)后，可以在cache中可以查询到文件信息
//        assert(cache.containsFile(fileName))
//
//        // 调用filePath(fileName:)来获取路径，而不要直接自己拼路径
//        let path = cache.filePath(forKey: fileName)
//        let content = String(bytes: (try? Data(contentsOf: URL(fileURLWithPath: path)))!, encoding: .utf8)
//        assert(content == "Not important content")
//
//        // removeFile(fileName:)方法会同时移除文件，以及DB中的文件信息
//        cache.removeFile(fileName)
//        // 从cache中移除文件后，在cache中查询不到文件信息
//        assert(!cache.containsFile(fileName))
//    }
//}
