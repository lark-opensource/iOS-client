//
//  DownloaderTask.swift
//  ByteWebImage
//
//  Created by bytedance on 2021/3/25.
//

import CommonCrypto
import Foundation

public struct ByteDownloadTaskInfo: Hashable, Equatable, RawRepresentable {
    public init?(rawValue: String) {
        self.rawValue = rawValue
    }

    public var rawValue: String

    public typealias Key = String

    static let responseHeader = "HTTPResponseHeader"
    static let requsetHeader = "HTTPRequestHeader"
    static let originURL = "OriginalURL"
    static let currentURL = "CurrentURL"
    static let cacheControl = "cache-control"
    static let contentLength = "Content-Length"
    static let contentType = "Content-Type"
    static let imageMd5 = "X-Md5"
    static let imageXLength = "X-Length"
    static let imageXcrops = "X-Crop-Rs"
    static let responseCache = "x-response-cache"
    static let resumeData = "ResumeData"
}

public struct DownloadTaskOptions: OptionSet {

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public let rawValue: Int
    public static let `default` = DownloadTaskOptions(rawValue: 1 << 0)
    public static let lowPriority = DownloadTaskOptions(rawValue: 1 << 1)
    public static let highPriority = DownloadTaskOptions(rawValue: 1 << 2)
}

public protocol DownloadTaskDelegate: NSObjectProtocol {
    func downloadTask(_ task: DownloadTask, finishedWith result: Result<Data, ByteWebImageError>, path: String?)
    func downloadTaskDidCanceled(_ task: DownloadTask)

    func downloadTask(_ task: DownloadTask, received rSize: Int, expected eSize: Int)
    func downloadTask(_ task: DownloadTask, didReceived data: Data?, increment: Data?)
}

/// 下载任务
public class DownloadTask: Operation {

    public var expectedSize: Int = 0
    public var receivedSize: Int = 0

    private(set) var url: URL
    private(set) var identifier: String
    private(set) var createTime: TimeInterval = 0
    private(set) var startTime: TimeInterval = 0
    private(set) var finishTime: TimeInterval = 0

    var defaultHeaders: [String: String] = [:]
    var options: DownloadTaskOptions = .default
    var tempPath: String = "" // 临时文件缓存路径，由DownloadManager管理
    var downloadResumeEnable: Bool = false // 是否支持断点续传
    weak var delegate: DownloadTaskDelegate?
    var timeoutInterval: TimeInterval = 30.0
    var timeoutIntervalForResource: TimeInterval = 30.0
    var checkMimeType: Bool = false
    var checkDataLength: Bool = false
    var isConcurrentCallback: Bool = false
    var progressDownload: Bool = false // 是否是渐进下载
    var smartCropRect: CGRect = .zero // 智能剪裁附带信息
    var cacheControlTime: Int = 0 // 缓存控制时间
    var savePath: String? // Rust会需要下载路径
    var extralInfo: [String: Any]? // 业务透传信息

    private var _finished: Bool = false
    private var _executing: Bool = false

    public override var isAsynchronous: Bool {
        return true
    }

    public override var isExecuting: Bool {
        set {
            if newValue != self._executing {
                self.willChangeValue(forKey: "isExecuting")
                self._executing = newValue
                self.didChangeValue(forKey: "isExecuting")
            }
        }
        get {
            return _executing
        }
    }

    public override var isFinished: Bool {
        set {
            if newValue != self._finished {
                self.willChangeValue(forKey: "isFinished")
                self._finished = newValue
                if self._finished {
                    self.finishTime = CACurrentMediaTime()
                }
                self.isExecuting = !newValue
                self.didChangeValue(forKey: "isFinished")
            }
        }
        get {
            return _finished
        }
    }

    public required init(with request: ImageRequest) {
        self.url = request.currentRequestURL
        self.identifier = request.currentRequestURL.absoluteString
        super.init()
        self.createTime = CACurrentMediaTime()
    }

    public override func start() {
        if self.isCancelled {
            self._finished = true
            self.delegate?.downloadTaskDidCanceled(self)
            return
        }
        self.isExecuting = true
        self.startTime = CACurrentMediaTime()
    }

    public override func cancel() {
        if self.isFinished { return }
        super.cancel()
        self._cancel()
        if self.isExecuting {
            self.isFinished = true
        }
    }

    // MARK: - Func

    public static func check(data: Data, md5: String) -> Bool {
        var dataMd5 = CC_MD5_CTX()

        CC_MD5_Init(&dataMd5)
        CC_MD5_Update(&dataMd5, (data as NSData).bytes, CC_LONG(data.count))
        var result = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        CC_MD5_Final(&result, &dataMd5)
        var resultMd5 = ""
        for i in result {
            resultMd5.append(String(format: "%02x", i))
        }
        return md5 == resultMd5
    }

    public static func getCacheControlTime(from response: String) -> Int {
        let controlList = response.components(separatedBy: "=")
        guard controlList.count == 2
        else { return 0 }
        return Int(controlList[1]) ?? 0
    }
    /// 将 header 的 智能裁剪区域解析并设置SmartCropRect
    /// header 区域左上角坐标-右下角坐标：(0,256)-(556,812) 转换成 CGRect 格式
    public func setupSmartCropRect(from headers: [ByteDownloadTaskInfo.Key: String]) {
        guard let cropRs = headers[ByteDownloadTaskInfo.imageXcrops],
              !cropRs.isEmpty
        else { return }
        let nonDigits = CharacterSet.decimalDigits.inverted
        let coordinates = cropRs.components(separatedBy: "-")
        var points = [CGPoint]()
        for coordinate in coordinates {
            let nums = coordinate.components(separatedBy: ",")
            if nums.count == 2 {
                if let x = Int(nums[0].trimmingCharacters(in: nonDigits)),
                   let y = Int(nums[1].trimmingCharacters(in: nonDigits)) {
                    let point = CGPoint(x: x, y: y)
                    points.append(point)
                }
            }
        }
        if points.count != 2 {
            self.smartCropRect = .zero
            return
        }
        let start = points[0]
        let end = points[1]
        if start.x < end.x && start.y < end.y {
            self.smartCropRect = CGRect(x: start.x, y: start.y, width: end.x - start.x, height: end.y - end.y)
        } else {
            self.smartCropRect = .zero
        }
    }

    public func checkDataError(_ data: Data, headers: [ByteDownloadTaskInfo.Key: String]) throws {
        if let xLength = headers[ByteDownloadTaskInfo.imageXLength],
           let contentType = headers[ByteDownloadTaskInfo.contentType] {
            let codeType = data.bt.imageFileFormat
            if self.checkMimeType && !contentType.isEmpty && codeType == .unknown {
                throw ImageError(ByteWebImageErrorCheckTypeError, userInfo: [NSLocalizedDescriptionKey: "download data is not a image type"])
            } else if self.checkDataLength && !xLength.isEmpty && data.count != Int(xLength) {
                throw ImageError(ByteWebImageErrorCheckTypeError, userInfo: [NSLocalizedDescriptionKey: "download data is incomplete"])
            }
        }
    }

}

public extension DownloadTask {
    // swiftlint:disable identifier_name
    func _cancel() {

    }

    func set(received rSize: Int, expected eSize: Int) {
        self.receivedSize = rSize
        self.expectedSize = eSize
        self.delegate?.downloadTask(self, received: rSize, expected: eSize)
    }

}
