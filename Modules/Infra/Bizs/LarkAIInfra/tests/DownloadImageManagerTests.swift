//
//  DownloadImageManagerTests.swift
//  LarkAIInfra-Unit-Tests
//
//  Created by huayufan on 2023/11/27.
//  


import XCTest
@testable import LarkAIInfra
import ByteWebImage

final class DownloadImageManagerTests: XCTestCase {

    var testURL1: URL? {
        return URL(string: "https://www.baidu1.com")
    }

    var testURL2: URL? {
        return URL(string: "https://www.baidu2.com")
    }

    var testURL3: URL? {
        return URL(string: "https://www.baidu3.com")
    }

    var success = false
    
    var downloadSuccess: Bool?

    var keepLoading = false

    override func setUp() {
        super.setUp()
        
    }

    override func tearDown() {
        super.tearDown()
        self.downloadSuccess = nil
        self.success = false
        self.keepLoading = false
    }

    func testDownloadImage() {
        guard let url = testURL1 else {
            return
        }
        self.success = true
        let manager = DownloadImageManager(api: self)
        manager.delegate = self
        manager.downloadImage(models: [.init(checkNum: 0, source: .url(url), id: "000")])
        XCTAssertNotNil(manager)
        self.downloadSuccess = nil
        
        
        // 不重复下载
        self.keepLoading = true
        manager.downloadImage(models: [.init(checkNum: 0, source: .url(url), id: "000")])
        XCTAssertNotNil(manager)
        self.downloadSuccess = nil
        manager.downloadImage(models: [.init(checkNum: 0, source: .url(url), id: "000")])
        XCTAssertNil(downloadSuccess)
        XCTAssertEqual(manager.dowloadTask.count, 1)
        self.keepLoading = false
        
        
        // 下载错误
        self.downloadSuccess = nil
        guard let url2 = testURL2 else {
            return
        }
        self.success = false
        manager.downloadImage(models: [.init(checkNum: 0, source: .url(url2), id: "111")])
        
        XCTAssertTrue(downloadSuccess == false, "result should be error")
        
        // 空不处理
        guard let url3 = testURL3 else {
            return
        }
        self.downloadSuccess = nil
        manager.api = nil
        manager.downloadImage(models: [.init(checkNum: 0, source: .url(url3), id: "222")])
        XCTAssertNil(downloadSuccess)
    }
}

extension DownloadImageManagerTests: DownloadAIImageAPI, InlineAIImageManagerDelegate {
    
    enum DownloadError: Error {
        case testError
    }

    func requestImageURL(urlString: String, callback: @escaping (ImageRequestResult) -> Void) {
        if keepLoading == true {
            return
        }
        guard let url = testURL1 else {
            return
        }
        if success {
            callback(.success(ImageResult.init(request: .init(url: url), image: UIImage(), data: Data(), from: .downloading, savePath: "")))
        } else {
            callback(.failure(.error(DownloadError.testError, defaultCode: .fatal)))
        }
    }
    
    func aiImageDownloadSuccess(with model: InlineAICheckableModel, image: UIImage?) {
        downloadSuccess = true
    }
    
    func aiImageDownloadFailure(with model: InlineAICheckableModel) {
        downloadSuccess = false
    }
}
