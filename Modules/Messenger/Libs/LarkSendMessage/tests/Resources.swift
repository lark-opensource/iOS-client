//
//  Resources.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李勇 on 2022/12/19.
//

import UIKit
import Foundation

final class BundleConfig: NSObject {
    static let SelfBundle: Bundle = {
        if let url = Bundle.main.url(forResource: "Frameworks/LarkSendMessage", withExtension: "framework") {
            return Bundle(url: url)!
        } else {
            return Bundle(for: BundleConfig.self)
        }
    }()
    private static let TestBundleURL = SelfBundle.url(forResource: "LarkSendMessageUnitTest", withExtension: "bundle")!
    static let TestBundle = Bundle(url: TestBundleURL)!
}

/// 获取资源
final class Resources {
    // MARK: - 图片资源
    static func image(named: String) -> UIImage {
        return UIImage(data: Resources.imageData(named: named))!
    }
    static func imageData(named: String) -> Data {
        // 目前图片格式就击中，我们就挨个判断这些格式，省掉调用方传入
        var imageUrl: URL?
        ["jpeg", "jpg", "png", "heic", "gif"].forEach({ ext in
            if imageUrl != nil { return }
            imageUrl = BundleConfig.TestBundle.url(forResource: named, withExtension: ext)
        })
        guard let url = imageUrl, let data = try? Data(contentsOf: url) else {
            assertionFailure("get url/data is nil")
            return Data()
        }
        return data
    }
    static func imageUrl(named: String) -> URL {
        var imageUrl: URL?
        ["jpeg", "jpg", "png", "heic", "gif"].forEach({ ext in
            if imageUrl != nil { return }
            imageUrl = BundleConfig.TestBundle.url(forResource: named, withExtension: ext)
        })
        guard let url = imageUrl else {
            assertionFailure("get url is nil")
            return URL(fileURLWithPath: "")
        }
        return url
    }

    // MARK: - 视频资源
    static func mediaData(named: String) -> Data {
        // 目前图片格式就击中，我们就挨个判断这些格式，省掉调用方传入
        var mediaUrl: URL?
        ["mp4", "MOV"].forEach({ ext in
            if mediaUrl != nil { return }
            mediaUrl = BundleConfig.TestBundle.url(forResource: named, withExtension: ext)
        })
        guard let url = mediaUrl, let data = try? Data(contentsOf: url) else {
            assertionFailure("get url/data is nil")
            return Data()
        }
        return data
    }
    static func mediaUrl(named: String) -> URL {
        // 目前图片格式就击中，我们就挨个判断这些格式，省掉调用方传入
        var mediaUrl: URL?
        ["mp4", "MOV"].forEach({ ext in
            if mediaUrl != nil { return }
            mediaUrl = BundleConfig.TestBundle.url(forResource: named, withExtension: ext)
        })
        guard let url = mediaUrl else {
            assertionFailure("get url is nil")
            return URL(fileURLWithPath: "")
        }
        return url
    }

    // MARK: - 语音资源
    static func audioData(named: String) -> Data {
        // 目前图片格式就几种，我们就挨个判断这些格式，省掉调用方传入
        var audioUrl: URL?
        ["opus", "wav"].forEach({ ext in
            if audioUrl != nil { return }
            audioUrl = BundleConfig.TestBundle.url(forResource: named, withExtension: ext)
        })
        guard let url = audioUrl, let data = try? Data(contentsOf: url) else {
            assertionFailure("get url/data is nil")
            return Data()
        }
        return data
    }
    static func audioUrl(named: String) -> URL {
        var audioUrl: URL?
        ["opus", "wav"].forEach({ ext in
            if audioUrl != nil { return }
            audioUrl = BundleConfig.TestBundle.url(forResource: named, withExtension: ext)
        })
        guard let url = audioUrl else {
            assertionFailure("get url is nil")
            return URL(fileURLWithPath: "")
        }
        return url
    }

    // MARK: - 文件资源
    static func fileData(named: String) -> Data {
        var fileUrl: URL?
        ["zip"].forEach({ ext in
            if fileUrl != nil { return }
            fileUrl = BundleConfig.TestBundle.url(forResource: named, withExtension: ext)
        })
        guard let url = fileUrl, let data = try? Data(contentsOf: url) else {
            assertionFailure("get url/data is nil")
            return Data()
        }
        return data
    }

    // MARK: - ...资源
}
