//
//  BDGeckoTest.swift
//  DocsTests
//
//  Created by Webster on 2019/6/26.
//  Copyright © 2019 Bytedance. All rights reserved.
//

import Foundation
import Quick
import Nimble
@testable import SpaceKit
@testable import Docs
/* 离线资源有三个存储文件夹：
 1. bundle: SKResource.framework/SKResource.bundle/eesz
 2. gecko: Library/Caches/IESWebCache/xxxxGeckoKeyxxxx/docs_app/eesz
 3. 最终资源: Library/DocsSDK/ResourceService/docs_app/eesz
 测试文件夹copy是否成功，copy后路径版本提取是否正确∫
 */
class BDGeckoFolderTest: QuickSpec {

    lazy var channelInfo: DocsChannelInfo = {
        let info = DocsChannelInfo(type: GeckoChannleType.webInfo, name: "docs_app", path: "SKResource.framework/SKResource.bundle/eesz")
        return info
    }()

    class func resourceFolder() -> String {
        return GeckoPackageManager.Folder.finalFolderPath(channel: "docs_app") + "/eesz"
    }

    class func cleanResourceFolder() {
        let path = BDGeckoFolderTest.resourceFolder()
        let folderExist = FileManager.default.fileExists(atPath: path)
        if folderExist {
            do {
                try FileManager.default.removeItem(atPath: path)
            } catch let error {
                fail("删除文件夹失败: \(error.localizedDescription)")
            }
        }
    }

    override func spec() {

        //全局的set up
        beforeSuite {
        }

        //全局tear down
        afterSuite {
            //删除测试的资源包，防止出错
            BDGeckoFolderTest.cleanResourceFolder()
        }

        describe("保证测试最终资源路径的正确性") {
            beforeEach {
                BDGeckoFolderTest.cleanResourceFolder()
            }

            it("测试资源的存储路径的构建和删除", closure: {
                let path = BDGeckoFolderTest.resourceFolder()
                let folderExist = FileManager.default.fileExists(atPath: path)
                if folderExist {
                    do {
                        try FileManager.default.removeItem(atPath: path)
                    } catch let error {
                        fail("删除资源路径失败: \(error.localizedDescription) PATH: \(path)")
                    }
                }
                do {
                    try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
                } catch let error {
                    fail("创建资源路径失败: \(error.localizedDescription) PATH: \(path)")
                }
            })
        }

        describe("测试资源的基础copy") {
            beforeEach {
                BDGeckoFolderTest.cleanResourceFolder()
            }
            it("高版本覆盖, 低版本抛弃", closure: {
                //本地存着几个正确的资源包在defaultBundle中
                guard let testBundlePath = Bundle(for: BDGeckoFolderTest.self).path(forResource: "default", ofType: "bundle") else {
                    fail("缺少测试资源")
                    return
                }
                //不需要对比的copy函数
                let path = BDGeckoFolderTest.resourceFolder()
                let resource11000 = testBundlePath.appending("/gecko/11000/eesz")
                GeckoPackageManager.Folder.copyFiles(resource11000, to: path)
                var version = GeckoPackageManager.Folder.revision(in: path)
                expect(version).to(equal("1.0.1.11000"))

                let resource13010 = testBundlePath.appending("/gecko/13010/eesz")
                GeckoPackageManager.Folder.copyFiles(resource13010, to: path)
                version = GeckoPackageManager.Folder.revision(in: path)
                expect(version).to(equal("1.0.1.13010"))

                let resource12956 = testBundlePath.appending("/gecko/12956/eesz")
                GeckoPackageManager.Folder.copyFiles(resource12956, to: path)
                version = GeckoPackageManager.Folder.revision(in: path)
                expect(version).to(equal("1.0.1.12956"))
            })
        }

        describe("测试Bundle和目标资源的依赖管理") { [weak self] in
            guard let strongSelf = self,
                let testBundlePath = Bundle(for: BDGeckoFolderTest.self).path(forResource: "default", ofType: "bundle") else {
                    fail("缺少测试资源")
                    return
            }
            beforeEach {
                BDGeckoFolderTest.cleanResourceFolder()
            }
            it("高版本覆盖, 低版本抛弃", closure: {
                let path = BDGeckoFolderTest.resourceFolder()
                let resource11000 = testBundlePath.appending("/gecko/11000/eesz")
                GeckoPackageManager.Folder.copyFiles(resource11000, to: path)

                let resource13010 = testBundlePath.appending("/gecko/13010/eesz")
                GeckoPackageManager.Folder.copyBundleFileIfNeed(channel: strongSelf.channelInfo, bundlePath: resource13010, dstPath: path, fromBundle: true)
                var version = GeckoPackageManager.Folder.revision(in: path)
                expect(version).to(equal("1.0.1.13010"))

                let resource12956 = testBundlePath.appending("/gecko/12956/eesz")
                GeckoPackageManager.Folder.copyBundleFileIfNeed(channel: strongSelf.channelInfo, bundlePath: resource12956, dstPath: path, fromBundle: true)
                version = GeckoPackageManager.Folder.revision(in: path)
                expect(version).to(equal("1.0.1.13010"))
            })

        }

    }

}

/*
 describe: 描述类、方法
 Context: 指定条件
 it: 描述测试的方法名
 +x： 屏蔽
 +f: 只启动带f的
 */
