//
//  SKFilePathTests.swift
//  SKFoundation-Unit-Tests
//
//  Created by huangzhikai on 2023/1/19.
//

import XCTest
@testable import SKFoundation

class SKFilePathTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testSKFilePathCreateFile() throws {
        //----------fg关闭-----------
        UserScopeNoChangeFG.setMockFG(key: "ccm.common.use_unified_storage", value: true)
        let path = SKFilePath.globalSandboxWithDocument.appendingRelativePath("testFilePath")
        
        //创建路径
        let createDir = path.createDirectoryIfNeeded()
        XCTAssertTrue(createDir)
        
        //是否存在
        let exists = path.exists
        XCTAssertTrue(exists)
        
        //创建文件
        let filePath = path.appendingRelativePath("test.txt")
        let writeString = "abc"
        let fileData = writeString.data(using: .utf8)
        
        let createFile = filePath.createFileIfNeeded(with: fileData)
        XCTAssertTrue(createFile)
        
        // 文件大小
        let fileSize = filePath.fileSize ?? 0
        XCTAssertTrue(fileSize > 0)
        
        // 取出文件data
        let filePathData = filePath.contentsAtPath() ?? Data()
         
        XCTAssertTrue(String(data: filePathData, encoding: .utf8) == writeString)
        
        //最后路径
        let lastPath = filePath.lastPathComponent
        XCTAssertTrue(lastPath == "test.txt")
        
        let displayName = filePath.displayName
        XCTAssertTrue(displayName == "test.txt")
        
        //复制文件
        let copyPath = path.appendingRelativePath("copyPath")
        copyPath.createDirectoryIfNeeded()
        let copyFile = copyPath.appendingRelativePath("test.txt")
        filePath.copyItem(to: copyFile, overwrite: true)
       
        XCTAssertTrue(copyFile.exists)
        XCTAssertTrue(copyFile.fileSize ?? 0 > 0)
        
        //移动文件
        let movePath = path.appendingRelativePath("movePath")
        movePath.createDirectoryIfNeeded()
        let moveFile = movePath.appendingRelativePath("test.txt")
        copyFile.moveItem(to: moveFile, overwrite: true)
        
        XCTAssertTrue(copyFile.exists == false)
        XCTAssertTrue(moveFile.exists)
        
        
        // 取出iso下的文件路径，跟old取出来对比需要一样
        let contentPathsIso = try path.contentsOfDirectory()
        let subpathsOfDirIso = try path.subpathsOfDirectory()
        let enumsIso = path.enumerator()
        let subpathsIso = path.subpaths()
        
        //----------fg关闭-----------
        UserScopeNoChangeFG.removeMockFG(key: "ccm.common.use_unified_storage")
        
        let pathOld = SKFilePath.globalSandboxWithDocument.appendingRelativePath("testFilePath")
        
        //创建路径
        let createDirOld = pathOld.createDirectoryIfNeeded()
        XCTAssertTrue(createDirOld)
        
        //是否存在
        let existsOld = pathOld.exists
        XCTAssertTrue(existsOld)
        
        //创建文件
        let filePathOld = pathOld.appendingRelativePath("test.txt")
        
        // 文件大小
        let fileSizeOld = filePathOld.fileSize ?? 0
        XCTAssertTrue(fileSizeOld > 0)
        
        // 取出文件data
        let filePathDataOld = filePathOld.contentsAtPath() ?? Data()
         
        XCTAssertTrue(String(data: filePathDataOld, encoding: .utf8) == writeString)
        
        //最后路径
        let lastPathOld = filePathOld.lastPathComponent
        XCTAssertTrue(lastPathOld == "test.txt")
        
        let displayNameOld = filePathOld.displayName
        XCTAssertTrue(displayNameOld == "test.txt")
        
        // 取出iso下的文件路径，跟old取出来对比需要一样
        let contentPathsOld = try path.contentsOfDirectory()
        let subpathsOfDirOld = try path.subpathsOfDirectory()
        let enumsOld = path.enumerator()
        let subpathsOld = path.subpaths()
        
        XCTAssertTrue(contentPathsOld == contentPathsIso)
        XCTAssertTrue(subpathsOfDirOld == subpathsOfDirIso)
        XCTAssertTrue(enumsOld == enumsIso)
        XCTAssertTrue(subpathsOld == subpathsIso)
        
        //old创建文件
        let filePathOld2 = pathOld.appendingRelativePath("testOld.txt")
        let fileDataOld2 = writeString.data(using: .utf8)

        let createFileOld2 = filePathOld2.createFileIfNeeded(with: fileDataOld2)
        XCTAssertTrue(createFileOld2)
        
        //old复制文件
        let copyPathOld = pathOld.appendingRelativePath("copyPathOld")
        copyPathOld.createDirectoryIfNeeded()
        let copyFileOld = copyPathOld.appendingRelativePath("testOld.txt")
        filePathOld2.copyItem(to: copyFileOld, overwrite: true)

        XCTAssertTrue(copyFileOld.exists)
        XCTAssertTrue(copyFileOld.fileSize ?? 0 > 0)

        //old移动文件
        let movePathOld = pathOld.appendingRelativePath("movePathOld")
        movePathOld.createDirectoryIfNeeded()
        let moveFileOld = movePathOld.appendingRelativePath("testOld.txt")
        copyFileOld.moveItem(to: moveFileOld, overwrite: true)

        XCTAssertTrue(copyFileOld.exists == false)
        XCTAssertTrue(moveFileOld.exists)
        
    }
}
