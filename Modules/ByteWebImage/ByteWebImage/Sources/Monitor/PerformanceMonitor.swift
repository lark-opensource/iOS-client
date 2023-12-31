//
//  PerformanceMonitor.swift
//  ByteWebImage
//
//  Created by xiongmin on 2021/5/27.
//

import Foundation

public struct ImageDecodeInfo {
    public var resourceLength: Int = 0
    public var resouceHeight: Int = 0
    public var resourceWidth: Int = 0
    public var framesCount: Int = 1
    public var loadWidth: Int = 0
    public var loadHeigt: Int = 0
    public var colorSpace: String = ""
    public var colorType: String = ""
    public var imageType: String = "unknown"
    public var success: Bool = true
    public var cost: TimeInterval = 0

    public init() { }
}

public struct ImageDownloadInfo {
    public var fromNet: Bool = true
    public var downloadCost: TimeInterval = 0
    public var queueCost: TimeInterval = 0
    public var decryptCost: TimeInterval = 0
    public var success: Bool = true
    public var resourceLength = 0
    public var imageFileFormat: ImageFileFormat = .unknown
    public var imageSize: CGSize = .zero

    public init() { }
}

public final class PerformanceMonitor {

    public static let shared = PerformanceMonitor()

    private var plugins: [any PerformancePlugin]

    private let logQueue = DispatchQueue(label: "com.bt.performance.serial")

    init() {
        self.plugins = []
    }

    public func registerPlugin(_ plugin: some PerformancePlugin) {
        logQueue.async { [weak self] in
            guard let `self` = self else { return }
            if self.plugins.contains(where: { $0.identifier == plugin.identifier }) { return }
            self.plugins.append(plugin)
        }
    }

    public func unRegisterPlugin(_ plugin: some PerformancePlugin) {
        logQueue.async { [weak self] in
            guard let `self` = self else { return }
            guard self.plugins.contains(where: { $0.identifier == plugin.identifier }) else { return }
            if let index = self.plugins.firstIndex(where: { $0.identifier == plugin.identifier }) {
                self.plugins.remove(at: index)
            }
        }

    }

    /// 图片加载完成记录
    public func receiveRecord(_ recoder: PerformanceRecorder) {
        logQueue.async { [weak self] in
            guard let `self` = self else { return }
            guard recoder.enableRecord else { return }

            for plugin in self.plugins {
                plugin.receivedRecord(recoder)
            }
        }
    }

    /// 图片解码后信息
    public func receiveDecodeInfo(key: String, decodeInfo: ImageDecodeInfo) {
        logQueue.async { [weak self] in
            guard let `self` = self else { return }
            for plugin in self.plugins {
                plugin.receiveDecodeInfo(key: key, decodeInfo: decodeInfo)
            }
        }
    }

    /// 图片下载信息
    public func receiveDownloadInfo(key: String, downloadInfo: ImageDownloadInfo) {
        logQueue.async { [weak self] in
            guard let `self` = self else { return }
            for plugin in self.plugins {
                plugin.receiveDownloadInfo(key: key, downloadInfo: downloadInfo)
            }
        }
    }

}
