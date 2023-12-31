//
//  SEItemParser.swift
//  ShareExtension
//
//  Created by K3 on 2018/7/3.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import MobileCoreServices
import LarkExtensionCommon
import AVFoundation

public final class SEItemParser<BaseType> {
    public let base: BaseType

    public init(_ base: BaseType) {
        self.base = base
    }
}

public protocol SEItemParserCompatible {
    associatedtype SEItemParserCompatibleType
    var se: SEItemParserCompatibleType { get }
}

public extension SEItemParserCompatible {
    var se: SEItemParser<Self> {
        return SEItemParser(self)
    }
}

extension NSExtensionContext: SEItemParserCompatible {}

extension NSItemProvider: SEItemParserCompatible {}

enum ShareDataMaxSize {
    enum Image {
        // 文件体积
        static let limitFileSize: UInt64 = 25 * 1024 * 1024
        // 图片像素乘积
        static let limitImageSize: CGFloat = 12_000 * 12_000
    }
    enum File {
        // 文件体积
        static let limitFileSize: UInt64 = 100 * 1024 * 1024 * 1024
    }
    enum Movie {
        // 文件体积
        static let limitFileSize: UInt64 = 5 * 1024 * 1024 * 1024
        // 视频时长
        static let limitDuration: Double = 5 * 60
    }
    enum Text {
        // 文本长度
        static let limitTextLength: UInt64 = 10_000
    }
}

enum ShareUnsupportErrorType: Error {
    case unknown
    case noData
    case unsupportAttachmentCount
    case unsupportType
    case unsupportTextLength
    /// 文件大小超出上限
    /// - fileSize: 超出上限的文件大小
    /// - fileSizeLimit: 文件大小上限
    case unsupportFileSize(fileSize: UInt64, fileSizeLimit: UInt64)
    case loadDataFaild
    case unsupportMixImageAndVideo
}

enum ShareItemProviderType {
    case unknown
    case text
    case image
    case fileUrl
    case url
    case movie
    case data
    var value: String {
        let cfValue: CFString
        switch self {
        case .text: cfValue = kUTTypeText
        case .image: cfValue = kUTTypeImage
        case .fileUrl: cfValue = kUTTypeFileURL
        case .url: cfValue = kUTTypeURL
        case .movie: cfValue = kUTTypeMovie
        case .data: cfValue = kUTTypeData
        default: cfValue = kUTTypeData
        }
        return cfValue as String
    }
}

typealias PreloadResult = Result<ShareContent, ShareUnsupportErrorType>
typealias LoadImageResult = (url: URL, image: UIImage)
typealias LoadFileResult = (url: URL, name: String)

typealias RandomFileURLMaker = () -> URL?
typealias ResultHandler = (_ data: PreloadResult) -> Void
private typealias TypeChecker = (NSItemProvider) -> Bool

extension SEItemParser where BaseType: NSExtensionContext {
    // 当前NSExtensionContext仅包含一个NSExtensionItem
    fileprivate var attachments: [NSItemProvider]? {
        return (base.inputItems as? [NSExtensionItem])?.first?.attachments
    }

    /// 预加载数据
    ///
    /// - Parameter urlMaker: random url maker
    /// - Returns: PreloadResult
    func preloadShareContent(
        _ urlMaker: @escaping RandomFileURLMaker,
        callback: @escaping ResultHandler
    ) {
        guard let attachments = attachments, !attachments.isEmpty else {
            LarkShareExtensionLogger.shared.error("preloadShareContent, attachments is nil or empty")
            callback(.failure(.noData))
            return
        }
        LarkShareExtensionLogger.shared.info("preloadShareContent, attachments = \(attachments)")

        switch attachments.count {
        case 1: // 如果仅有一个 attachment，则按类型处理，类型有先后顺序，因为有包含关系，打乱先后顺序可能会导致分享类型错误
            guard let item = attachments.first, let url = urlMaker() else {
                LarkShareExtensionLogger.shared.error("preloadShareContent, attachments.first is nil or urlMaker() is nil")
                callback(.failure(.loadDataFaild))
                return
            }

            // 用于组不用字典是为了方便调整优先级
            let typeAndRunner: [(type: ShareItemProviderType, runner: () -> Void)] = [
                // 视频
                (.movie, { item.se.preloadMovie(type: .movie, to: url, callback: callback) }),

                // 图片
                (.image, { item.se.preloadImage(to: url, callback: callback) }),

                // 文件URL
                (.fileUrl, { item.se.preloadData(type: .fileUrl, to: url, callback: callback) }),

                // 文本
                (.text, { item.se.preloadText(to: url, callback: callback) }),

                // URL
                (.url, {
                    item.se.loadItem(for: .url) { data in
                        if let text = (data as? URL)?.absoluteString {
                            callback(loadTextContent(text))
                        } else {
                            LarkShareExtensionLogger.shared.error("preloadShareContent, (data as? URL)?.absoluteString is nil")
                            callback(.failure(.loadDataFaild))
                        }
                    }
                }),

                // 二进制
                (.data, { item.se.preloadData(type: .data, to: url, callback: callback) })
            ]

            if let match = typeAndRunner.first(where: { item.se.isKind(of: $0.type) }) {
                match.runner()
            } else {
                callback(.failure(.unsupportType))
            }
        case 2 ..< 10:
            // 如果多个，且小于9个，且Item都可以当成Image处理

            let textChecker: TypeChecker = { $0.se.isKind(of: .text) || $0.se.isKind(of: .url) }
            let imageChecker: TypeChecker = { $0.se.isKind(of: .image) }
            let fileURLChecker: TypeChecker = { $0.se.isKind(of: .fileUrl) }
            let photoVideoMixChecker: TypeChecker = { $0.se.isKind(of: .image) || $0.se.isKind(of: .movie) }

            let items = attachments
            let conditionAndRunner: [(condition: () -> Bool, runner: () -> Void)] = [
                // 全是图片类型
                ({ items.allSatisfy(imageChecker) }, { [weak self] in self?.preloadImages(items, urlMaker, callback: callback) }),

                // 图片视频混合
                ({ items.allSatisfy(photoVideoMixChecker) }, { callback(.failure(.unsupportMixImageAndVideo)) }),

                // 混合附件和其他类型，且仅混合一个附件
                ({ items.filter(fileURLChecker).count == 1 }, {
                    guard let url = urlMaker(), let item = items.first(where: fileURLChecker) else {
                        callback(.failure(.unsupportType))
                        return
                    }

                    item.se.preloadData(type: .fileUrl, to: url, callback: callback)
                }),

                // 包含图片类型的数据且包含文本类型的数据
                ({ items.contains(where: imageChecker) && items.contains(where: textChecker) }, { [weak self] in
                    self?.preloadText(items.filter(textChecker), urlMaker, callback: callback) }),

                // 包含图片类型的数据且不是图片视频混合
                ({ items.contains(where: imageChecker) }, { [weak self] in self?.preloadImages(items.filter(imageChecker), urlMaker, callback: callback) }),

                // 全是文本类型或者URL类型
                ({ items.allSatisfy(textChecker) }, { [weak self] in self?.preloadText(items, urlMaker, callback: callback) }),

                // 包含文本类型的数据
                ({ items.contains(where: textChecker) }, { [weak self] in self?.preloadText(items.filter(textChecker), urlMaker, callback: callback) })
            ]

            if let match = conditionAndRunner.first(where: { $0.condition() }) {
                match.runner()
            } else {
                callback(.failure(.unsupportType))
            }

        default:
            callback(.failure(.unsupportAttachmentCount))
        }
    }

    // MARK: - 多图
    /// 尝试从所有的attachments加在图片，以判断所有Item均可正确加在图片
    ///
    /// - Parameters:
    ///   - attachments: attachments
    ///   - handler: result
    private func preloadImages(_ items: [NSItemProvider], _ urlMaker: RandomFileURLMaker, callback: @escaping ResultHandler) {
        var imageResultarray = [LoadImageResult]()
        var hugeImgResultArray = [LoadFileResult]()
        let queue = DispatchQueue(label: "share.extension.queue.preloadImages")
        let group = DispatchGroup()
        var errorResult: PreloadResult?

        for item in items {
            guard let url = urlMaker() else {
                LarkShareExtensionLogger.shared.error("preloadImages, urlMaker() is nil")
                errorResult = .failure(.loadDataFaild)
                return
            }
            group.enter()
            queue.async {
                // 有过错误返回，返回，不再请求新资源
                guard errorResult == nil else {
                    group.leave()
                    return
                }
                // imageResult与error只会返回一个
                item.se.loadPrviewImageAndSaveImage(to: url, callback: { (imageResult) in
                    if let imageResult = imageResult {
                        imageResultarray.append(imageResult)
                    }
                    group.leave()
                }, convertFileCallback: { (fileResult) in
                    if let fileResult = fileResult {
                        hugeImgResultArray.append(fileResult)
                    }
                    group.leave()
                }, errorCallback: { (result) in
                    // 有错误发生，返回错误
                    errorResult = result
                    group.leave()
                })
            }
        }

        // 请求资源遍历完成，回调结果
        group.notify(queue: queue) {
            if let errorResult = errorResult {
                callback(errorResult)
            } else {
                // 对请求到的资源加载，组成array
                let previewMap = imageResultarray.reduce(into: [URL: UIImage]()) { $0[$1.url] = $1.image }
                let imageItem = ShareImageItem(urls: imageResultarray.map({ $0.url }), previewMaps: previewMap)

                guard !hugeImgResultArray.isEmpty else {
                    let result = ShareContent(contentType: .image, item: imageItem)
                    callback(.success(result))
                    return
                }

                let fileItems = hugeImgResultArray.map { (url: URL, name: String) in
                    return ShareFileItem(url: url, name: name)
                }

                let multipleItem = ShareMultipleItem(imageItem: imageItem, fileItems: fileItems)
                let result = ShareContent(contentType: .multiple, item: multipleItem)
                callback(.success(result))

            }
        }
    }

    // MARK: - 混合类型提取文本
    /// 尝试从混合(多类型)attachments中加在所有文本类型（text、url【fileurl不是】）数据
    /// - Parameter handler: 如果可以，则生成一个新的NSItemProvider
    private func preloadText(_ items: [NSItemProvider], _ urlMaker: RandomFileURLMaker, callback: @escaping ResultHandler) {
        let queue = DispatchQueue(label: "share.extension.queue.preloadText")
        let group = DispatchGroup()
        var texts = [String]()
        var errorResult: PreloadResult?

        for item in items {
            // 请求资源，根据资源类型进行转换
            func innerLoadItem(for type: ShareItemProviderType, transform: @escaping (NSSecureCoding?) -> String?) {
                guard errorResult == nil else { // 有过错误发生，返回，不请求新资源
                    group.leave()
                    return
                }

                item.se.loadItem(for: type) { (data) in
                    if let text = transform(data) {
                        texts.append(text)
                    } else {
                        LarkShareExtensionLogger.shared.error("preloadImages, transform(data) is nil")
                        errorResult = .failure(.loadDataFaild)
                    }

                    group.leave()
                }
            }

            group.enter()
            queue.async {
                if item.se.isKind(of: .text) {
                    innerLoadItem(for: .text, transform: { $0 as? String })
                } else if item.se.isKind(of: .url) {
                    innerLoadItem(for: .url, transform: { ($0 as? URL)?.absoluteString })
                }
            }
        }

        // 请求完成，回调对应值
        group.notify(queue: queue) {
            if let errorResult = errorResult {
                callback(errorResult)
            } else {
                callback(loadTextContent(texts.compactMap({ $0 }).joined(separator: " ")))
            }
        }
    }
}

extension SEItemParser where BaseType: NSItemProvider {
    /// 检查当前的Item是否可以当做指定类型的数据
    ///
    /// - Parameter type: 类型
    /// - Returns: result
    @inline(__always)
    func isKind(of type: ShareItemProviderType) -> Bool {
        return base.hasItemConformingToTypeIdentifier(type.value)
    }

    /// 加载数据
    ///
    /// - Parameter type: 加载的数据的类型
    /// - Returns: 结果
    func loadItem(for type: ShareItemProviderType, callback: @escaping (_ data: NSSecureCoding?) -> Void) {
        base.loadItem(forTypeIdentifier: type.value, options: nil) { (data, _) in
            callback(data)
        }
    }

    /// 加载预览图
    ///
    /// - Returns: 预览图，可能为nil
    private func loadPreviewImage(callback: @escaping (_ image: UIImage?) -> Void) {
        base.loadPreviewImage(options: nil) { (data, _) in
            callback(data as? UIImage)
        }
    }

    /// 根绝类型复制数据到指定URL
    ///
    /// - Parameters:
    ///   - type: 指定的类型
    ///   - url: target url
    /// - Returns: 结果
    private func preloadData(type: ShareItemProviderType, to url: URL, callback: @escaping ResultHandler) {
        loadItem(for: type) { (data) in
            if let at = data as? URL {
                let result = loadFileContent(at: at, to: url, size: ShareDataMaxSize.File.limitFileSize)
                callback(result)
            } else {
                LarkShareExtensionLogger.shared.error("preloadData, (data as? URL) is nil")
                callback(.failure(.loadDataFaild))
            }
        }
    }
}

extension SEItemParser where BaseType == NSItemProvider {
    /// 预加载 text
    fileprivate func preloadText(to targetURL: URL, callback: @escaping ResultHandler) {
        loadItem(for: .text) { (data) in
            if let text = data as? String {
                callback(loadTextContent(text))
            } else if let url = data as? URL {
                callback(loadFileContent(at: url, to: targetURL, size: ShareDataMaxSize.Text.limitTextLength))
            } else {
                LarkShareExtensionLogger.shared.error("preloadText, (data as? String) or (data as? URL) is nil")
                callback(.failure(.loadDataFaild))
            }
        }
    }

    private func preloadMovie(type: ShareItemProviderType, to url: URL, callback: @escaping ResultHandler) {
        loadItem(for: type) { data in
            guard let at = data as? URL else {
                LarkShareExtensionLogger.shared.error("preloadMovie, (data as? URL) is nil")
                callback(.failure(.loadDataFaild))
                return
            }
            self.loadMovie(from: at, to: url, callback: { (shareMovieItem) in
                callback(.success(ShareContent(contentType: .movie, item: shareMovieItem)))
            }, errorCallback: { (shareUnsupportErrorType) in
                callback(.failure(shareUnsupportErrorType))
            })
        }
    }

    /// 预加载 image
    fileprivate func preloadImage(to targetURL: URL, callback: @escaping ResultHandler) {
        // imageResult和error只会返回一个
        loadPrviewImageAndSaveImage(to: targetURL, callback: { (imageResult) in
            if let imageResult = imageResult {
                let url = imageResult.0
                let previewImage = imageResult.1
                let item = ShareImageItem(urls: [url], previewMaps: [url: UIImage(contentsOfFile: url.path) ?? previewImage])
                callback(.success(ShareContent(contentType: .image, item: item)))
            }
        }, convertFileCallback: { (fileResult) in
            if let fileResult = fileResult {
                let url = fileResult.0
                let name = fileResult.1
                let item = ShareFileItem(url: url, name: name)
                callback(.success(ShareContent(contentType: .fileUrl, item: item)))
            }
        }, errorCallback: { (result) in
            callback(result)
        })
    }
}

/// 预处理图片数据 且 生成缩略图
/// Load Image的结果可能是图片的fileurl或者Image(如：iOS11截图分享)，所以要分开处理
/// load preview 的结果可能为nil，此时要使用原图作为preview
extension SEItemParser where BaseType == NSItemProvider {
    func loadMovie(from: URL, to: URL,
                   callback: @escaping (_ a: ShareMovieItem) -> Void,
                   errorCallback: @escaping (_ c: ShareUnsupportErrorType) -> Void) {
        let to: URL = URL(fileURLWithPath: to.path + ".mov")
        guard copyOrMoveFile(at: from, to: to) else {
            LarkShareExtensionLogger.shared.error("loadMovie,copyorMoveFile failed")
            errorCallback(.loadDataFaild)
            return
        }
        // 视频名称
        let name = to.lastPathComponent
        // 获取视频的文件大小
        guard let attr = try? FileManager.default.attributesOfItem(atPath: to.path),
           let fileSize = attr[FileAttributeKey.size] as? NSNumber else {
            LarkShareExtensionLogger.shared.error("preloadImages, attr is nil or fileSize is nil")
            errorCallback(.loadDataFaild)
            return
        }
        // 视频文件大小超过文件最大上限
        guard fileSize.uint64Value < ShareDataMaxSize.File.limitFileSize else {
            errorCallback(.unsupportFileSize(fileSize: fileSize.uint64Value, fileSizeLimit: ShareDataMaxSize.File.limitFileSize))
            return
        }
        // 比较视频的文件大小
        if fileSize.uint64Value > ShareDataMaxSize.Movie.limitFileSize {
            let movieItem = ShareMovieItem(url: to, isFallbackToFile: true, name: name, duration: 0, movieSize: nil)
            callback(movieItem)
            return
        }
        let avasset = AVURLAsset(url: to)
        // 获取视频的时长
        let time = avasset.duration
        let duration = (Double(time.value) / Double(time.timescale)).rounded()
        // 比较视频的时长
        if duration > ShareDataMaxSize.Movie.limitDuration {
            let movieItem = ShareMovieItem(url: to, isFallbackToFile: true, name: name, duration: duration, movieSize: nil)
            callback(movieItem)
            return
        }
        var movieSize: CGSize?
        if let track = avasset.tracks(withMediaType: .video).first {
            // 获取分辨率
            let naturalSize = track.naturalSize
            // 矫正视频宽高，有的视频带着旋转角度，需要调整
            let t = track.preferredTransform
            switch (t.a, t.b, t.c, t.d) {
            case (0, 1, -1, 0), (0, -1, -1, 0), (0, -1, 1, 0), (0, 1, 1, 0):
                movieSize = CGSize(width: naturalSize.height, height: naturalSize.width)
            default: movieSize = naturalSize
            }
        }
        let movieItem = ShareMovieItem(url: to, isFallbackToFile: false, name: name, duration: duration, movieSize: movieSize)
        callback(movieItem)
    }

    // swiftlint:disable line_length
    func loadPrviewImageAndSaveImage(to: URL,
                                     callback: @escaping (_ imageResult: LoadImageResult?) -> Void,
                                     convertFileCallback: @escaping (_ hugeImageResult: LoadFileResult?) -> Void,
                                     errorCallback: @escaping ResultHandler) {
        var currentImage: UIImage?
        var currentData: NSSecureCoding?
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "share.extension.queue.loadPrviewImageAndSaveImage")

        group.enter()
        queue.async {
            // 请求image资源
            self.loadPreviewImage { (image) in
                currentImage = image
                group.leave()
            }
        }

        group.enter()
        queue.async {
            // 请求data资源
            self.loadItem(for: .image) { (data) in
                guard let data = data else {
                    LarkShareExtensionLogger.shared.error("loadPreviewImageAndSaveImage, data is nil")
                    errorCallback(.failure(.loadDataFaild))
                    group.leave()
                    return
                }
                currentData = data
                group.leave()
            }
        }

        group.notify(queue: queue) {
            // 二者都请求完成，对数据进行处理
            if let currentURL = currentData as? URL {
                guard let fileSize = getFileSize(at: currentURL) else {
                    LarkShareExtensionLogger.shared.error("loadPreviewImageAndSaveImage, currentData is nil")
                    errorCallback(.failure(.loadDataFaild))
                    return
                }

                // 图片文件大小超过文件最大上限
                guard fileSize < ShareDataMaxSize.File.limitFileSize else {
                    LarkShareExtensionLogger.shared.error("loadPrviewImageAndSaveImage, imageSize larger than shareDataMaxSize,fileSize: \(fileSize), fileSizeLimit: \(ShareDataMaxSize.File.limitFileSize)")
                    errorCallback(.failure(.unsupportFileSize(fileSize: fileSize, fileSizeLimit: ShareDataMaxSize.File.limitFileSize)))
                    return
                }

                LarkShareExtensionLogger.shared.info("copy to url:\(to.absoluteString)")
                guard copyOrMoveFile(at: currentURL, to: to),
                    let previewImage = currentImage ?? UIImage(contentsOfFile: currentURL.path) else {
                    LarkShareExtensionLogger.shared.error("loadPrviewImageAndSaveImage, copyOrMoveFile failed or previewImage is nil")
                        errorCallback(.failure(.loadDataFaild))
                        return
                }

                let width = previewImage.size.width
                let height = previewImage.size.height
                LarkShareExtensionLogger.shared.info("loadPrviewImageAndSaveImage, imageSize: \(fileSize), shareDataLimit: \(ShareDataMaxSize.Image.limitFileSize), imageResolution: \(width * height), iamgeResolutionLimit: \(ShareDataMaxSize.Image.limitImageSize)")
                guard fileSize < ShareDataMaxSize.Image.limitFileSize,
                      width * height < ShareDataMaxSize.Image.limitImageSize else {
                    // 超大图转为文件形式数据
                    let result = (to, to.lastPathComponent)
                    convertFileCallback(result)
                    return
                }

                let result = (to, previewImage)
                callback(result)
                return
            }

            // data is ‘UIImage’
            if let image = currentData as? UIImage, let imageData = image.pngData() {
                check(image: image, data: imageData)
                return
            }

            // data is ‘Data(imageData)’
            if let imageData = currentData as? Data, let image = UIImage(data: imageData) {
                check(image: image, data: imageData)
            }
        }

        func check(image: UIImage, data: Data) {
            guard UInt64(data.count) < ShareDataMaxSize.File.limitFileSize else {
                errorCallback(.failure(.unsupportFileSize(fileSize: UInt64(data.count), fileSizeLimit: ShareDataMaxSize.File.limitFileSize)))
                return
            }

            do {
                try data.write(to: to)
                callback((to, currentImage ?? image))
            } catch let error {
                LarkShareExtensionLogger.shared.error("data write to path failed, error:\(error.localizedDescription)")
                errorCallback(.failure(.loadDataFaild))
            }
        }
    }
    // swiftlint:enable line_length
}

// MARK: config method
private func getFileSize(at url: URL) -> UInt64? {
    do {
        let fileInfo = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = fileInfo[FileAttributeKey.size] as? UInt64

        return fileSize
    } catch _ {
        return nil
    }
}

private func copyOrMoveFile(at: URL, to: URL) -> Bool {
    do {
        LarkShareExtensionLogger.shared.info("copy or move success: \(at.absoluteString), to: \(to.absoluteString)")
        try FileManager.default.copyItem(at: at, to: to)
        return true
    } catch let error {
        LarkShareExtensionLogger.shared.info("copy or move failed: \(error)")
        return false
    }
}

/// 由String创建text类型的ShareContent
///
/// - Parameter text: 文本
/// - Returns: success or faild
private func loadTextContent(_ text: String?) -> PreloadResult {
    if let text = text, !text.isEmpty {
        guard UInt64(text.count) < ShareDataMaxSize.Text.limitTextLength else {
            return .failure(.unsupportTextLength)
        }
        let content = ShareContent(contentType: .text, item: ShareTextItem(text: text))
        return .success(content)
    }
    LarkShareExtensionLogger.shared.error("loadTextContent, text is nil or empty")
    return .failure(.loadDataFaild)
}

/// 生成item是fileURL类型的ShareContent
///
/// - Parameters:
///   - at: file source url
///   - to: copy or move taget url
///   - size: support max size
/// - Returns: success or faild
private func loadFileContent(at: URL, to: URL, size: UInt64) -> PreloadResult {
    guard let fileSize = getFileSize(at: at) else {
        LarkShareExtensionLogger.shared.error("loadFileContent, fileSize is nil")
        return .failure(.loadDataFaild)
    }
    guard fileSize < size else {
        return .failure(.unsupportFileSize(fileSize: fileSize, fileSizeLimit: size))
    }
    guard copyOrMoveFile(at: at, to: to) else {
        LarkShareExtensionLogger.shared.error("loadFileContent, copyOrMoveFile failed")
        return .failure(.loadDataFaild)
    }

    let item = ShareFileItem(url: to, name: at.lastPathComponent)
    let content = ShareContent(contentType: .fileUrl, item: item)
    return .success(content)
}
