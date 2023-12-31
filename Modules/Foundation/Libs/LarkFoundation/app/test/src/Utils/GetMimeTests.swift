//
//  GetMineTests.swift
//  LarkFoundationDevEEUnitTest
//
//  Created by kongkaikai on 2023/6/19.
//

import Foundation
import XCTest

@testable import LarkFoundation

class getMimeTests: XCTestCase {

    func testgetMime() {
        // Test cases with known file types
        XCTAssertEqual(Utils.getMime(fileName: "image.png"), "image/png")
        XCTAssertEqual(Utils.getMime(fileName: "document.pdf"), "application/pdf")
        XCTAssertEqual(Utils.getMime(fileName: "audio.mp3"), "audio/mpeg")
        XCTAssertEqual(Utils.getMime(fileName: "video.mp4"), "video/mp4")
        XCTAssertEqual(Utils.getMime(fileName: "text.txt"), "text/plain")
        XCTAssertEqual(Utils.getMime(fileName: "archive.zip"), "application/zip")

        // Test case with an unknown file type
        XCTAssertEqual(Utils.getMime(fileName: "unknown.xyz"), "")

        // Test case with a file name without an extension
        XCTAssertEqual(Utils.getMime(fileName: "no_extension"), "")

        // Test case with a file name with multiple periods
        XCTAssertEqual(Utils.getMime(fileName: "example.file.txt"), "text/plain")

        // Test case with an empty file name
        XCTAssertEqual(Utils.getMime(fileName: ""), "")


        if #available(iOS 14.0, *) {
            XCTAssertEqual(Utils.getMime(fileName: "iwork.key"), "application/x-iwork-keynote-sffkey")
            XCTAssertEqual(Utils.getMime(fileName: "iwork.kth"), "application/x-iwork-keynote-sffkth")
            XCTAssertEqual(Utils.getMime(fileName: "iwork.numbers"), "application/x-iwork-numbers-sffnumbers")
        } else {
            XCTAssertEqual(Utils.getMime(fileName: "iwork.key"), "")
            XCTAssertEqual(Utils.getMime(fileName: "iwork.kth"), "")
            XCTAssertEqual(Utils.getMime(fileName: "iwork.numbers"), "")
        }
    }
}
