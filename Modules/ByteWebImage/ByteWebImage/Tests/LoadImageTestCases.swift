//
//  LoadImageTestCases.swift
//  ByteWebImage-Unit-Tests
//
//  Created by xiongmin on 2021/10/27.
//

import ByteWebImage
import LarkCache
import XCTest

class LoadImageTestCases: XCTestCase {
    override class func setUp() {
        super.setUp()
        ImageManager.default.forceDecode = true
        LarkImageService.shared.originCache.diskCache.removeAll()
    }

    func testLoadJPG() {
        let imageView = UIImageView()
        imageView.bt.setLarkImage(with: .default(key: "MonochromeTestImage.jpg"), completion: { result in
            switch result {
            case let .success(imageRequest):
                XCTAssert(imageRequest.image?.bt.codeType == .JPEG)
            case .failure:
                XCTAssert(false)
            }
        })
    }

    func testLoadPng() {
        let imageView = UIImageView()
        let expectation = XCTestExpectation(description: "load png image")
        imageView.bt.setLarkImage(with: .default(key: "TestImage.png"), completion: { result in
            switch result {
            case let .success(imageRequest):
                XCTAssert(imageRequest.image?.bt.codeType == .PNG)
                XCTAssertNotNil(imageRequest.image)
                XCTAssertEqual(imageRequest.form, .downloading)
                expectation.fulfill()
            case .failure:
                XCTAssert(false)
            }
        })
        wait(for: [expectation], timeout: 10)
    }

    func testLoadWebp() {
        let imageView = UIImageView()
        let expectation = XCTestExpectation(description: "load webp image")
        imageView.bt.setLarkImage(with: .default(key: "TestImageStatic.webp"), completion: { result in
            switch result {
            case let .success(imageRequest):
                XCTAssert(imageRequest.image?.bt.codeType == .WebP)
                XCTAssertNotNil(imageRequest.image)
                XCTAssertEqual(imageRequest.form, .downloading)
                expectation.fulfill()
            case .failure:
                XCTAssert(false)
            }
        })
        wait(for: [expectation], timeout: 10)
    }

    func testLoadGIF() {
        let window = UIApplication.shared.keyWindow
        let imageView = ByteImageView(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))
        window?.addSubview(imageView)
        let expectation = XCTestExpectation(description: "load webp image")
        imageView.bt.setLarkImage(with: .default(key: "TestImage.gif"), completion: { result in
            switch result {
            case let .success(imageRequest):
                XCTAssert(imageRequest.image?.bt.codeType == .GIF)
                XCTAssertNotNil(imageRequest.image)
                XCTAssertEqual(imageRequest.form, .downloading)
                expectation.fulfill()
            case .failure:
                XCTAssert(false)
            }
        })
        wait(for: [expectation], timeout: 10)
    }

    func testLoadHttpUrl() {
        let imageView = UIImageView()
        imageView.bt.setLarkImage(with: .default(key: "https://t7.baidu.com/it/u=1819248061,230866778&fm=193&f=GIF"), completion: { result in
            switch result {
            case let .success(imageRequest):
                XCTAssert(imageRequest.image?.bt.codeType == .JPEG)
            case .failure:
                XCTAssert(false)
            }
        })
    }

    func testLargeImage() {
        let imageView = UIImageView()
        imageView.bt.setLarkImage(with: .default(key: "TestImageLarge.jpg"), completion: { result in
            switch result {
            case let .success(imageRequest):
                XCTAssert(imageRequest.image?.bt.codeType == .JPEG)
            case .failure:
                XCTAssert(false)
            }
        })
    }

    func testLoadBigWebp() {
        let imageView = UIImageView()
        imageView.bt.setLarkImage(with: .default(key: "TestWebPDownsample.webp"), completion: { result in
            switch result {
            case let .success(imageRequest):
                XCTAssert(imageRequest.image?.bt.codeType == .WebP)
            case .failure:
                XCTAssert(false)
            }
        })
    }

    func testLoadPlain() {
        let imageView = UIImageView()
        imageView.bt.setImage(with: URL(string: "https://t7.baidu.com/it/u=1819248061,230866778&fm=193&f=GIF"),
                              completionHandler: { result in
                                  switch result {
                                  case let .success(imageRequest):
                                      XCTAssert(imageRequest.image?.bt.codeType == .JPEG)
                                  case .failure:
                                      XCTAssert(false)
                                  }
                              })
    }

    func testButtonLoadPlain() {
        let button = UIButton()
        button.bt.setImage(with: URL(string: "https://t7.baidu.com/it/u=1819248061,230866778&fm=193&f=GIF"),
                           for: .normal,
                              completionHandler: { result in
                                  switch result {
                                  case let .success(imageRequest):
                                      XCTAssert(imageRequest.image?.bt.codeType == .JPEG)
                                  case .failure:
                                      XCTAssert(false)
                                  }
                              })
    }

    func testButtonLoad() {
        let button = UIButton()
        button.bt.setLarkImage(with: .default(key: "TestImageLarge.jpg"), for: .normal, completion: { result in
            switch result {
            case let .success(imageRequest):
                XCTAssert(imageRequest.image?.bt.codeType == .JPEG)
            case .failure:
                XCTAssert(false)
            }
        })
    }
}
