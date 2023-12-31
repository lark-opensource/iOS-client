//
//  DBUpdateSpec.swift
//  DocsTests
//
//  Created by guotenghu on 2019/7/12.
//  Copyright © 2019 Bytedance. All rights reserved.

import Foundation
import Quick
import Nimble
import SQLite
@testable import SpaceKit

//swiftlint:disable identifier_name function_body_length
class DBUpdateSpec: DocsSpec {
    override func spec() {
        beforeSuite {
            self.initDocsNet()
        }
        test32Db()
        test33Db()
    }

    /// 测试 3.2 版本数据库升级
    private func test32Db() {
        log("test32DB start")
        let currentConfig = UserDefaultConfig.getCurrent()
        beforeEach {
            self.clearDBCachePath()
        }
        afterEach {
            self.clearDBCachePath()
            currentConfig.save()
            self.wait(2)
        }
        it("从3.2升级", closure: {
            var testConfig = UserDefaultConfig()
            testConfig.bitableEnable = true
            testConfig.mindnoteEnable = true
            testConfig.fileEnable = true
            testConfig.slideEnable = true
            testConfig.currentDBVersion = 2019_03_05_18_38 // 3.2版本数据库的版本
            testConfig.pinNodesSequence = ["BCWupvXvFdwPy816", "qUV2Mr1TMLCZ1A35", "mrBrY3u5tgwxQexNCcz0Hb", "Eij3PwO48zLORkFBRm4Z9e"]
            testConfig.starNodesSequence = ["3OjBiBuZcyEdnQlrozpv9d",
                                            "Ef3yUp93o4r4rypfkOZaGf",
                                            "qK54BVqTOZdmzejYXBg13e",
                                            "doccn2FVjl2vI2gHrKNaub",
                                            "doccna0m6GpeG9w79cavie",
                                            "fldcnNMmrhulNZNYVhVSKtYoXFf",
                                            "fldcnb1DrMMWMxjEXtEJNrhxs5d",
                                            "boxcnaGjWArbh42nVoy6DI5Ntqh",
                                            "BCWupvXvFdwPy816",
                                            "qUV2Mr1TMLCZ1A35",
                                            "boxcn23J7527ydfZOTcftr",
                                            "mrBrY3u5tgwxQexNCcz0Hb",
                                            "PRx3no2RFEwB4Sp8NBxIrf",
                                            "Eij3PwO48zLORkFBRm4Z9e",
                                            "TPCTyiza4F97fi59",
                                            "W7CAG0ekyhyckshhYsRFOc"]
            testConfig.save()

            TablesManager.useNewDB = false
            let testDataCenter = self.getDataCenterFromOldDBFileName("file32")
            waitUntil(timeout: 100, action: { (done) in
                testDataCenter.reloadData {
                    let allFolders = testDataCenter.fileResource.userFile
                    expect(allFolders.recent.files.count).to(equal(1645))
                    expect(allFolders.favorites.files.count).to(equal(11))
                    expect(allFolders.pins.files.count).to(equal(2))
                    expect(allFolders.share.files.count).to(equal(25))
                    let rootFolders = allFolders.folderInfoMap.folders["creRuzFuBOIiVS36"]!
                    let folderCount = rootFolders.files.filter { $0.type == .folder }.count
                    expect(folderCount).to(equal(7))
                    let testConnection = testDataCenter.docConnection as? TestDocsDBConnectionProvidor
                    expect(testConnection!.calledResetCount).to(equal(1))
                    DispatchQueue.main.async {
                        testDataCenter.removeUserFiles()
                        done()
                    }
                }
            })
            self.wait(2)
        })
    }

    private func test33Db() {
        log("test33DB start")
        let currentConfig = UserDefaultConfig.getCurrent()
        let testConfig = UserDefaultConfig.get33Config()
        beforeEach {
            self.clearDBCachePath()
            testConfig.save()
        }
        afterEach {
            self.clearDBCachePath()
            currentConfig.save()
            self.wait(2)
        }
        it("从3.3升级", closure: {
            TablesManager.useNewDB = false
            let testDataCenter = self.getDataCenterFromOldDBFileName("file33")
            waitUntil(timeout: 100, action: { (done) in
                testDataCenter.reloadData {
                    let allFolders = testDataCenter.fileResource.userFile
                    expect(allFolders.recent.files.count).to(equal(1651))
                    expect(allFolders.favorites.files.count).to(equal(15))
                    expect(allFolders.pins.files.count).to(equal(5))
                    expect(allFolders.share.files.count).to(equal(100))
                    expect(allFolders.shareFolder.files.count).to(equal(55))
                    let 水印测试文档文件夹 = allFolders.folderInfoMap.folders["X3iKBebIY2S7Yh35"]!
                    expect(水印测试文档文件夹.files.count).to(equal(2))
                    let 工作文件夹 = allFolders.folderInfoMap.folders["Wo5LaQ704gajJm05"]!
                    expect(工作文件夹.files.count).to(equal(26))
                    let 测试文档文件夹 = allFolders.folderInfoMap.folders["EiiPdolvVFCVlU72"]!
                    expect(测试文档文件夹.files.count).to(equal(45))

                    let 复杂文档文件夹 = allFolders.folderInfoMap.folders["WvKlBjTXYuKkRr21"]!
                    expect(复杂文档文件夹.files.count).to(equal(3))
                    expect(复杂文档文件夹.name).to(equal("复杂文档"))
                    expect(测试文档文件夹.files.first!.objToken).to(equal("WvKlBjTXYuKkRr21"))
                    let testConnection = testDataCenter.docConnection as? TestDocsDBConnectionProvidor
                    expect(testConnection!.calledResetCount).to(equal(1))
                    DispatchQueue.main.async {
                        testDataCenter.removeUserFiles()
                    }
                    done()
                }
            })
            self.wait(2)
        })
    }

    private func getDataCenterFromOldDBFileName(_ dbFileName: String) -> DataCenter {
        let user: User = {
            let user = User.current
            let userInfo = UserInfo(userID: "")
            User.current.info = userInfo
            userInfo.updateUser(info: ("65934242", "1", "00888"))
            return user
        }()
//        testDataCenterContext.bulletin = TestBulletIn()
        let bundle = Bundle(for: DBUpdateSpec.self)
        let oldDBPath = bundle.url(forResource: dbFileName, withExtension: "sqlite3")!
        let targetDirectory = targetTestURL()
        let targetPath = targetDirectory.appendingPathComponent("old.sqlite")
        do {
            var isDirectory = ObjCBool(false)
            let exists = FileManager.default.fileExists(atPath: targetDirectory.path, isDirectory: &isDirectory)
            if !exists || isDirectory.boolValue == false {
                try FileManager.default.createDirectory(at: targetTestURL(), withIntermediateDirectories: true, attributes: nil)
                log("create directory success")
            }
            try FileManager.default.copyItem(at: oldDBPath, to: targetTestURL().appendingPathComponent("old.sqlite"))
            log("copy to \(targetTestURL()) success")
        } catch {
            log("copy old db file, error is \(error)")
        }
        let testConnection = TestDocsDBConnectionProvidor(targetPath)
        let testDataCenter = DataCenter(docConnection: testConnection,
                                             user: user)
        return testDataCenter

    }
    private func clearDBCachePath() {
        let directory = targetTestURL()
        do {
            try FileManager.default.removeItem(at: directory)
        } catch {
            log("delete old db file, error is \(error)")
        }

    }

    private func targetTestURL() -> URL {
        let cacheDirectory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
        let cacheUrl = URL(fileURLWithPath: cacheDirectory)
        return cacheUrl.appendingPathComponent("DBTest")
    }
}

extension DBUpdateSpec {
    private struct UserDefaultConfig {
        var starNodesSequence = [String]()
        var pinNodesSequence = [String]()
        var personalFilesObjsSequence = [String]()
        var shareFolderObjsSequence = [String]()
        var recentSyncMetaInfoKey = Data()
        var bitableEnable: Any?
        var mindnoteEnable: Any?
        var fileEnable: Any?
        var slideEnable: Any?
        /// 当前的数据库版本
        var currentDBVersion: Int64!

        static func getCurrent() -> UserDefaultConfig {
            var config = UserDefaultConfig()
            config.starNodesSequence = UserDefaults.standard.stringArray(forKey: UserDefaultKeys.starNodesSequence) ?? []
            config.pinNodesSequence = UserDefaults.standard.stringArray(forKey: UserDefaultKeys.pinNodesSequence) ?? []
            config.personalFilesObjsSequence = UserDefaults.standard.stringArray(forKey: UserDefaultKeys.personalFilesObjsSequence) ?? []
            config.shareFolderObjsSequence = UserDefaults.standard.stringArray(forKey: UserDefaultKeys.shareFolderObjsSequence) ?? []
            config.recentSyncMetaInfoKey = UserDefaults.standard.data(forKey: UserDefaultKeys.recentSyncMetaInfoKeyNew) ?? Data()
            config.currentDBVersion = UserDefaults.standard.value(forKey: "currentFileDBVersionKey") as? Int64 ?? 0
            config.bitableEnable = UserDefaults.standard.value(forKey: RemoteConfigUpdater.ConfigKey.bitableEnable.rawValue)
            config.mindnoteEnable = UserDefaults.standard.value(forKey: RemoteConfigUpdater.ConfigKey.mindnoteEnable.rawValue)
            config.fileEnable = UserDefaults.standard.value(forKey: RemoteConfigUpdater.ConfigKey.driveListEnable.rawValue)
            config.slideEnable = UserDefaults.standard.value(forKey: RemoteConfigUpdater.ConfigKey.slideEnable.rawValue)

            return config
        }

        func save() {
            UserDefaults.standard.set(bitableEnable, forKey: RemoteConfigUpdater.ConfigKey.bitableEnable.rawValue)
            UserDefaults.standard.set(mindnoteEnable, forKey: RemoteConfigUpdater.ConfigKey.mindnoteEnable.rawValue)
            UserDefaults.standard.set(fileEnable, forKey: RemoteConfigUpdater.ConfigKey.driveListEnable.rawValue)
            UserDefaults.standard.set(slideEnable, forKey: RemoteConfigUpdater.ConfigKey.slideEnable.rawValue)

            UserDefaults.standard.set(starNodesSequence, forKey: UserDefaultKeys.starNodesSequence)
            UserDefaults.standard.set(pinNodesSequence, forKey: UserDefaultKeys.pinNodesSequence)
            UserDefaults.standard.set(personalFilesObjsSequence, forKey: UserDefaultKeys.personalFilesObjsSequence)
            UserDefaults.standard.set(shareFolderObjsSequence, forKey: UserDefaultKeys.shareFolderObjsSequence)
            UserDefaults.standard.set(recentSyncMetaInfoKey, forKey: UserDefaultKeys.recentSyncMetaInfoKeyNew)
            UserDefaults.standard.set(currentDBVersion, forKey: "currentFileDBVersionKey")
        }

        static func get33Config() -> UserDefaultConfig {
            var testConfig = UserDefaultConfig()
            testConfig.bitableEnable = true
            testConfig.mindnoteEnable = true
            testConfig.fileEnable = true
            testConfig.slideEnable = true

            testConfig.currentDBVersion = 2019_07_13_05_35 // 3.2版本数据库的版本
            testConfig.starNodesSequence = ["BCWupvXvFdwPy816",
                                            "qUV2Mr1TMLCZ1A35",
                                            "mrBrY3u5tgwxQexNCcz0Hb",
                                            "Eij3PwO48zLORkFBRm4Z9e",
                                            "W7CAG0ekyhyckshhYsRFOc",
                                            "Ef3yUp93o4r4rypfkOZaGf",
                                            "qK54BVqTOZdmzejYXBg13e",
                                            "doccn2FVjl2vI2gHrKNaub",
                                            "doccna0m6GpeG9w79cavie",
                                            "fldcnNMmrhulNZNYVhVSKtYoXFf",
                                            "PRx3no2RFEwB4Sp8NBxIrf",
                                            "TPCTyiza4F97fi59",
                                            "boxcn23J7527ydfZOTcftr",
                                            "boxcnaGjWArbh42nVoy6DI5Ntqh",
                                            "fldcnb1DrMMWMxjEXtEJNrhxs5d"]
            testConfig.pinNodesSequence = ["3OjBiBuZcyEdnQlrozpv9d",
                                           "BCWupvXvFdwPy816",
                                           "qUV2Mr1TMLCZ1A35",
                                           "mrBrY3u5tgwxQexNCcz0Hb",
                                           "Eij3PwO48zLORkFBRm4Z9e"]
            testConfig.personalFilesObjsSequence = [ "doccnnmOfDYM9GuE7hL8zJomb8b",
                                                     "doccnWpmWQLOy3e8xJiOcBRGBGc",
                                                     "sldcnlg6qvLb6zE9bQ09yjGeHbc",
                                                     "shtcnP7MPNso7IVnBxAlf89FZQh",
                                                     "doccnVMACbDYnl4oC8xUzJ6v9Gc",
                                                     "doccnjX04r1CKpcwcllQnG19PAa",
                                                     "Eij3PwO48zLORkFBRm4Z9e",
                                                     "doccns114uGWlEBE0EXSEx5C2ph",
                                                     "doccnaYKN0ndXMP6Rhlp3mCUwyc",
                                                     "qK54BVqTOZdmzejYXBg13e",
                                                     "doccnEyaxvhuuaXOIsrOiDsPNyf",
                                                     "doccntqvDqXsTgiViE1N10EXMSh",
                                                     "doccn5Tfz13lzsvmzPGGm0Q2gfe",
                                                     "doccnophKOd3Py8nGM9CBAS7TDg",
                                                     "doccnB8ucINQtvCdGdikiQIUwVe",
                                                     "doccnGboe5iA0AdLSmD5kLZnBYe",
                                                     "doccnSR3UdSdGET2C9BBLIXHPrc",
                                                     "doccnbZPVnRHPNOqI15olfycItc",
                                                     "ntPw5wPEy4fhCC37wPKRsb",
                                                     "doccnFqymK5n1VvrLzRCRkgzeqb",
                                                     "doccnUHqSLcsXuXX9AF7lbtkKef",
                                                     "doccnmUKpanJ1Ile6fjQDXKOZ0e",
                                                     "doccnEhGyEw1IgoFOgStMYpamgg",
                                                     "doccnqoJadVihueSvh8AM4NnD7a",
                                                     "doccneskVPjcUZSlXUoCXKu01hh",
                                                     "doccniartH9qq7xisMjrJLjxUre",
                                                     "doccnwLWbdXxvvDpWFw3azaf1Ob",
                                                     "doccnaIrGYslf9vu3fDVIFe6Idb",
                                                     "doccnHOAOV684y0tantSCMGmtkb",
                                                     "doccnI0TAnlt1B9G6qJ74DoYIga",
                                                     "doccnAfa1FbdJHuhDnODUhEMZkf",
                                                     "doccnxCtbdDyH3XL3Y0hyl",
                                                     "doccnmy5Ut3pSPhym98dFgiHQdf",
                                                     "doccnPp6oyOngDsXl17CMxu2Z0e",
                                                     "doccnjIIXRyiyg9RqpyNlk2M0De",
                                                     "doccnhCIXAeMe2PEgNMwZIOCNCe",
                                                     "doccn3kJ5yJCTvUcc9q1HbeUDva",
                                                     "doccnH2RRu3MDYF9a1rVk3XxjIh",
                                                     "doccnLqFOUt5dUBhquPhLuq7Age",
                                                     "doccnrCNpAnCrUMwTwNqWr32RHa",
                                                     "doccnVGLkpAqwvIFM7zNHJASyhb",
                                                     "doccn59KPh0Somfw0VdDuhczbaf",
                                                     "doccnWLSsS1z0lsUrPgBaq9izRh",
                                                     "doccnrxEk2IrRds3Nl3lusXFb2f",
                                                     "bmncnJemVzft20bvXb0z2kxmqGg",
                                                     "bmncn6bxJvFV3VWGtshg2B",
                                                     "doccnZICCRhPcLsarO2h6ls2B3g",
                                                     "doccnklPZ7ZpGmVQ0knJKEKX39b",
                                                     "doccnFfCYa4iFXAGOhvGgmJqPna",
                                                     "doccnBwNJyv62DOCMeW2Wr0Y7Pf",
                                                     "doccnLHDoBZhlR8SMy7yvLP3mhg",
                                                     "doccnYYL67Cx5PsvuEV61mkcX3b",
                                                     "doccnSW8L8I7L1sPCaMmsNoTsxc",
                                                     "boxcn3zCpowvupgO6UJNoToBTqa",
                                                     "doccn5u8vvLT9fcUMDTVhmBIMGa",
                                                     "boxcnuLBld9xgWtct1RMbKO3d1e",
                                                     "doccngyHTD8ZW6AIQiYfFt5Ovmf",
                                                     "boxcnE6L8TA289YI6QHiShMlTjf",
                                                     "doccniXmKtVOsh8HMsu6TVy0Mwf",
                                                     "boxcnZMRjCQyclVjd5YTLrAgrVb",
                                                     "doccn73wngBFs5STgteQjUcPlCh",
                                                     "boxcnhOg44Eu53BaChIXANwqzyf",
                                                     "boxcnfTrDiIFuRKzywZoobpTmbc",
                                                     "boxcnlHb3VU1ir2f3pLBeBYpUfc",
                                                     "boxcnXQtP9XhzPqc77fVEMUiQda",
                                                     "boxcn2UWDLr7NJtrfcdyvObJOCb",
                                                     "boxcnTX8ygbYY4eFGAj0fZcuPJa",
                                                     "boxcnwrN9ZlN3c1BFVqw4Vtvsvg",
                                                     "doccnNsQhbvlRTu2ZcyiNFK6xPg",
                                                     "bmncnXG9zlt23brXbDIt4RaoT7c",
                                                     "doccnuUG7U9X20jzLu7YW69K6sb",
                                                     "doccnoCaklWvPB6LkVRoFLFGx7e",
                                                     "doccngAobMqap8TF3dr0SRRmQwd",
                                                     "doccn6tM1aVkieyVDEPjt1RUbrg",
                                                     "doccna8YPtOZkQTN2jcfLkcfixh",
                                                     "doccnj0D6Z56kDhVh5geuUnzi6e",
                                                     "doccnjE4px1L5g3uGcp2WDGVd1c",
                                                     "doccnkCAvDKXHK824hOiWQwxtCh",
                                                     "doccnzqsnvE501poQfnxWvuUwOd",
                                                     "doccn0cO0SigG4aZtIgSbeC1Did",
                                                     "doccn4NQDARKvQTBPFFF5V4zGhd",
                                                     "doccnRFfVUSHX6CjHfuAl7o2zja",
                                                     "doccn4w3Su3MWsWZdf4jQaAHwRf",
                                                     "doccnOg62JEf2dXNEMUnjTseLpb",
                                                     "doccn22RaLXJD0ePIRDtJt0Ta9d",
                                                     "doccn8AkYyP5lAEOlNa6D0FRDvg",
                                                     "doccn6DVIA7kY7Sy9nHtxgcvPme",
                                                     "doccncVk5tLc9c5Mwxt0F51VwVe",
                                                     "doccnF3D2lGjyytCup5JivZDeif",
                                                     "doccnvHHujsTvlh28J1gJu0cjCh",
                                                     "doccnycr1Hk3IIJkFQgl0lyDojb",
                                                     "doccnzWg9CIrUocTtOOVMEEOkIa",
                                                     "W7CAG0ekyhyckshhYsRFOc",
                                                     "doccnjrK4Ne6uJ6ELT5PjF4f36a",
                                                     "doccnVRnBcCnGakVPGLatdsxgFd",
                                                     "boxcnkhBbQ543Kz6JNCSuKLfR6c",
                                                     "bmncnHlCdq8tgzF7NAGJsg",
                                                     "doccnpVjhDqMKQF1cxondGerL1d",
                                                     "doccn2wXMhDxvDSnRT6lnYDqjNg",
                                                     "doccn214fcUyBgTylJuCPl13Tia"]
            testConfig.shareFolderObjsSequence = [ "X3iKBebIY2S7Yh35",
                                                   "fldcn3vnyvXJrNfdjbuRi56zrld",
                                                   "fldcnyfFSmH3IM6ilMBT5Xoizzh",
                                                   "fldcnyomZmjKSeahLg2WkdkAVhf",
                                                   "fldcnb1DrMMWMxjEXtEJNrhxs5d",
                                                   "fldcnQZflG6b1dna4HZfLziz4Cg",
                                                   "iq9vKKpVZk8pgK79",
                                                   "mODlERDkOKoou695",
                                                   "mZYqsSsS3CEfXv59",
                                                   "t66YLFn7OaIiCg15",
                                                   "lDeYGHccnWVLtV96",
                                                   "GdzZoRcrAmJEnn02",
                                                   "TGkCAJhFgmprLp67",
                                                   "h2sYbps12EKTOE59",
                                                   "NDMrFkVs4komgd11",
                                                   "XyUqbyQlR5fp3J94",
                                                   "BRQ1yrRWjqWUqo15",
                                                   "cpIxOTBCqWEBip89",
                                                   "q7EbjRVT4Hjlh657",
                                                   "6waeMul3OVjFbe33",
                                                   "O0jRjh5rWXv9a668",
                                                   "X3Hu8mdNSnMU4K02",
                                                   "Jl0aAKR9it9WVl79",
                                                   "qfcXFCd7huejcA04",
                                                   "XgyPjkikVwrK1O11",
                                                   "TPCTyiza4F97fi59",
                                                   "Uu4VFrJOtooQZL45",
                                                   "AxCfHuXiMtLZyK60",
                                                   "gMPhqZ25Esye0G30",
                                                   "oNOdTZjRmhz1ez95",
                                                   "ZnMqk0SllnWRDm82",
                                                   "s5a6Lp9fkDZVUJ03",
                                                   "abqPn47fiLPVMN96",
                                                   "W2OhriukolFKMx09",
                                                   "lwBFqC3btSK7M932",
                                                   "ikYZHlhD82YZLj53",
                                                   "Jf0STr1o1VcRPw16",
                                                   "Yaeo3v6J64o9Et91",
                                                   "FYAYJwkPoSFsB706",
                                                   "aROegHPAmC4LUr63",
                                                   "t1DZD0gVdGEqwd51",
                                                   "tSULXz9RZXmbG745",
                                                   "1XmCTZjS12mk1372",
                                                   "vUHeACfOkNIiJ546",
                                                   "HXpvELO9fN2dGc92",
                                                   "wkkF8eIWEuMyay31",
                                                   "6iPwTzDkxCnnNO35",
                                                   "61FGkz3haedIit88",
                                                   "UeE77YiNQt2sL251",
                                                   "qUV2Mr1TMLCZ1A35",
                                                   "HtD5ENHlZwmHXL23",
                                                   "kV9b3MRUsNYGR1I8",
                                                   "6dCLv3h3vw7FvV62",
                                                   "TYZ2Dc6oaeJ3T433",
                                                   "8lGy98ZUjtsOWs54"]
            return testConfig
        }
    }
}

private class TestBulletIn: DocsBulletinDBBridge {
    func clear() {

    }

    func reloadData() {

    }
}

private class TestDocsDBConnectionProvidor: DocsDBConnectionProvidor {
    private let dbPathURL: URL
    var calledResetCount = 0
    init(_ oldFileDBPath: URL) {
        dbPathURL = oldFileDBPath
        assert(oldFileDBPath.isFileURL)
    }
    var file: Connection?

    func setup() {
        var dbConnection: Connection?
        do {
            dbConnection = try Connection(dbPathURL.path)
        } catch {
            print("Create DB Fail  \(error)")
            spaceAssertionFailure("Create DB Fail")
        }
        file = dbConnection
    }

    func reset() {
        calledResetCount += 1
        print("called Reset")
    }

    func readyToUse() -> Bool {
        return true
    }
}
