//
//  UIImageTransformTestCases.swift
//  ByteWebImage-Unit-Tests
//
//  Created by xiongmin on 2021/10/27.
//

import XCTest
@testable import ByteWebImage

// disable-lint: magic number

class UIImageTransformTestCases: XCTestCase {

    func imagePath(key: String) -> String {
        let bundle = Bundle(for: CacheTestCases.self)
        let component = key.split(separator: ".")
        let name = component.first
        let type = component.last
        return bundle.path(forResource: String(name ?? ""), ofType: String(type ?? "")) ?? ""
    }

    func testRectFit() {
        let rect = CGRect(origin: .zero, size: CGSize(width: 100, height: 100))
        let result1 = ByteRectFit(with: .bottom, rect: rect, size: CGSize(width: 50, height: 50))
        let result2 = ByteRectFit(with: .top, rect: rect, size: CGSize(width: 50, height: 50))
        let result3 = ByteRectFit(with: .left, rect: rect, size: CGSize(width: 50, height: 50))
        let result4 = ByteRectFit(with: .right, rect: rect, size: CGSize(width: 50, height: 50))
        let result5 = ByteRectFit(with: .topLeft, rect: rect, size: CGSize(width: 50, height: 50))
        let result6 = ByteRectFit(with: .topRight, rect: rect, size: CGSize(width: 50, height: 50))
        let result7 = ByteRectFit(with: .bottomLeft, rect: rect, size: CGSize(width: 50, height: 50))
        let result8 = ByteRectFit(with: .bottomRight, rect: rect, size: CGSize(width: 50, height: 50))
        let result9 = ByteRectFit(with: .center, rect: rect, size: CGSize(width: 50, height: 50))
        let result10 = ByteRectFit(with: .scaleAspectFit, rect: rect, size: CGSize(width: 50, height: 50))
        let result11 = ByteRectFit(with: .scaleAspectFill, rect: rect, size: CGSize(width: 50, height: 50))
        let result12 = ByteRectFit(with: .scaleToFill, rect: rect, size: CGSize(width: 50, height: 50))
        let result13 = ByteRectFit(with: .redraw, rect: rect, size: CGSize(width: 50, height: 50))

        XCTAssert(result1 != .zero)
        XCTAssert(result2 != .zero)
        XCTAssert(result3 != .zero)
        XCTAssert(result4 != .zero)
        XCTAssert(result5 != .zero)
        XCTAssert(result6 != .zero)
        XCTAssert(result7 != .zero)
        XCTAssert(result8 != .zero)
        XCTAssert(result9 != .zero)
        XCTAssert(result10 != .zero)
        XCTAssert(result11 != .zero)
        XCTAssert(result12 != .zero)
        XCTAssert(result13 != .zero)

    }

    func testGetGifDaly() {
        let path = imagePath(key: "TestImage.gif")
        let url = URL(fileURLWithPath: path)
        let data = (try? Data(contentsOf: url))!
        guard let gifSource = CGImageSourceCreateWithData(data as CFData, nil) else {
            XCTAssert(false)
            return
        }
        let delay = ByteImageSourceGetGIFFrameDelay(at: 3, source: gifSource)
        XCTAssert(delay >= 0.1)
    }

    func testResizeImage() {
        let path = imagePath(key: "TestImage.jpg")
        let image = UIImage(contentsOfFile: path)
        let resizeImage = image?.bt.resize(to: CGSize(width: 20, height: 20))
        XCTAssert(resizeImage?.size.width == 20 && resizeImage?.size.height == 20)
    }

    func testCompressGif() {
        let path = imagePath(key: "TestImage.gif")
        let url = URL(fileURLWithPath: path)
        let data = (try? Data(contentsOf: url))!
        guard let gif = UIImage.image(withSmallGIF: data, scale: 0.5) else {
            XCTAssert(false)
            return
        }
        XCTAssert(gif.scale == 0.5)
    }

    func testImageWithColor() {
        let image = UIImage.image(with: .red)
        XCTAssertNotNil(image)
    }

    func testCrop() {
        let path = imagePath(key: "TestImage.jpg")
        let ori = UIImage(contentsOfFile: path)
        let rect = CGRect(origin: .zero, size: CGSize(width: 50, height: 50))
        let image = ori?.bt.crop(to: rect)
        XCTAssert(image?.size == rect.size)
    }

    func testInsertEdge() {
        let path = imagePath(key: "TestImage.jpg")
        let ori = UIImage(contentsOfFile: path)
        let edge = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        let dest = ori?.bt.insetEdge(by: edge, with: .red)
        XCTAssertNotNil(dest)
    }

    func testCorner() {
        let path = imagePath(key: "TestImage.jpg")
        let ori = UIImage(contentsOfFile: path)
        let dest = ori?.bt.roundCorner(with: 5.0, corners: .allCorners, borderWidth: 1.0, borderColor: .red, borderLineJoin: nil)
        XCTAssertNotNil(dest)
    }

    func test() {
        let path = imagePath(key: "TestImage.jpg")
        let ori = UIImage(contentsOfFile: path)
        let r90 = ori?.bt.rotate(by: 0.5 * .pi, fitSize: true)
        let r180 = ori?.bt.rotate(by: .pi, fitSize: true)
        let r270 = ori?.bt.rotate(by: 1.5 * .pi, fitSize: true)
        XCTAssertNotNil(r90)
        XCTAssertNotNil(r180)
        XCTAssertNotNil(r270)

    }

}
