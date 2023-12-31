//
//  BDGeckoManagerTest.swift
//  DocsTests
//
//  Created by Webster on 2019/6/27.
//  Copyright © 2019 Bytedance. All rights reserved.
//

import Foundation
import Quick
import Nimble
//import IESGeckoKit
@testable import SpaceKit
@testable import Docs

/*
  GeckoPackageManager 单例
  1. 封装bundle资源、gecko资源和本地资源的替换逻辑 (包括版本升级清空、gecko热更等)
  2. 封装gecko的拉取过程
  3. 通过初始化配置，支持多业务的资源分离管理
  4. 对外提供当前资源接口的逻辑获取、版本获取
  5. 集成了md5资源的校验能力
 */

class BDGeckoManagerTest: QuickSpec {
    private var hasUpdated = false
    override func spec() {

        // 初始化的时候 配置gecko用iphoneX的id去远端的测试channel（ios_test）拉取12725的包
        // 配置测试的gecko key，gecko channel
        // 在测试的环境下给指定device下发12725的包，并用指定deviceId初始化

        beforeSuite { [weak self] in
            guard let strongSelf = self else { return }
            //IESGeckoKit.clearCache()
            //远端部署，给这台设备定向下发12725的包
            let testChannelInfos = [(GeckoChannleType.unitTest, "ios_test", "SKResource.framework/SKResource.bundle/eesz")]
            let testConfig = GeckoInitConfig(channels: testChannelInfos, deviceId: "58839610073")
            GeckoPackageManager.shared.unitTest_updateGeckoKey(key: "2f8feb7db4d71d6ddf02e76668896c41")
            GeckoPackageManager.shared.setupConfig(config: testConfig)
            GeckoPackageManager.shared.addEventObserver(obj: strongSelf)
        }

        //tear down
        afterSuite {
            BDGeckoFolderTest.cleanResourceFolder()
            //IESGeckoKit.clearCache()
        }

        describe("测试gecko热更接口") {
            it("update接口测试获取到高版本", closure: {
                guard let path = Bundle(for: BDGeckoManagerTest.self).path(forResource: "default", ofType: "bundle") else {
                    fail("找不到测试资源")
                    return
                }
                let folderExist = FileManager.default.fileExists(atPath: self.resourceFinalPath())
                if folderExist {
                    do {
                        try FileManager.default.removeItem(atPath: self.resourceFinalPath())
                    } catch let error {
                        fail("删除文件夹失败: \(error.localizedDescription)")
                    }
                }
                //IESGeckoKit.clearCache()
                //把最终资源包替换成11000
                let resourcePath = path + "/gecko/11000/eesz"
                let finalPath = self.resourceFinalPath()
                GeckoPackageManager.Folder.copyFiles(resourcePath, to: finalPath)
                GeckoPackageManager.shared.syncResourcesIfNeeded()
                waitUntil(timeout: 10, action: { (done) in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
                        expect(self.hasUpdated).to(equal(true))
                        let finalPath = self.resourceFinalPath()
                        let version = GeckoPackageManager.Folder.revision(in: finalPath)
                        expect(version).to(equal("1.0.1.12725"))
                        done()
                    })
                })

            })

            it("update接口测试获取到低版本", closure: {
                guard let path = Bundle(for: BDGeckoManagerTest.self).path(forResource: "default", ofType: "bundle") else {
                    fail("找不到测试资源")
                    return
                }
                let folderExist = FileManager.default.fileExists(atPath: self.resourceFinalPath())
                if folderExist {
                    do {
                        try FileManager.default.removeItem(atPath: self.resourceFinalPath())
                    } catch let error {
                        fail("删除文件夹失败: \(error.localizedDescription)")
                    }
                }
               // IESGeckoKit.clearCache()
                //把最终资源包替换成11000
                let resourcePath = path + "/gecko/13010/eesz"
                let finalPath = self.resourceFinalPath()
                GeckoPackageManager.Folder.copyFiles(resourcePath, to: finalPath)
                GeckoPackageManager.shared.syncResourcesIfNeeded()
                waitUntil(timeout: 10, action: { (done) in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
                        expect(self.hasUpdated).to(equal(true))
                        let finalPath = self.resourceFinalPath()
                        let version = GeckoPackageManager.Folder.revision(in: finalPath)
                        expect(version).to(equal("1.0.1.13010"))
                        done()
                    })
                })

            })
        }

    }

    func resourceFinalPath() -> String {
        let dstPath = GeckoPackageManager.Folder.finalFolderPath(channel: "ios_test") + "/eesz"
        return dstPath
    }
}

extension BDGeckoManagerTest: GeckoEventListener {

    func packageWillUpdate(_ gecko: GeckoPackageManager?, in channel: GeckoChannleType) {
        if channel == .unitTest {
            hasUpdated = true
            GeckoPackageManager.shared.tryApplyPackage(in: channel, nextLauch: false)
        }
    }

    func packageDidUpdate(_ gecko: GeckoPackageManager?, in channel: GeckoChannleType, isSuccess: Bool, needReloadRN: Bool) {

    }
}
