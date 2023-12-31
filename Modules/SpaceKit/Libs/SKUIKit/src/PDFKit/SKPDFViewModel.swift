//
//  SKPDFViewModel.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2020/6/8.
//

import Foundation
import RxSwift
import RxCocoa
import PDFKit
import SKFoundation
import UniverseDesignColor

public extension SKPDFViewModel {
    enum ThumbnailError: Error {
        case documentNotReady
        case invalidPageNumber
    }


    struct Config {
        // MS场景，PPT文件的「演示模式」使用PDF转码文件
        public static let presentationPPTMode = Config(shouldShowPresentationSwitchBtn: true,
                                                       shouldLandscape: true,
                                                       mode: .singlePage,
                                                       backgroundColor: .black,
                                                       enableScrollBar: false,
                                                       enableGrid: false,
                                                       enablePresentationMask: true)
        
        // MS场景，PPT文件的「默认模式」
        public static let normalPPTMode = Config(shouldShowPresentationSwitchBtn: true,
                                                 shouldLandscape: false,
                                                 mode: .singlePageContinuous,
                                                 backgroundColor: UDColor.bgBase,
                                                 enableScrollBar: true,
                                                 enableGrid: true,
                                                 enablePresentationMask: false)
        
        // 正常PDF文件预览
        public static let `default` = Config(shouldShowPresentationSwitchBtn: false,
                                             shouldLandscape: false,
                                             mode: .singlePageContinuous,
                                             backgroundColor: UDColor.bgBase,
                                             enableScrollBar: true,
                                             enableGrid: true,
                                             enablePresentationMask: false)

        // config 变化时的操作来源
        public enum ActionSource: String {
            // 自动进入演示模式
            case auto
            // 点击导航栏按钮
            case click
        }

        // 导航栏是否显示切换展示模式的BarItem
        public let shouldShowPresentationSwitchBtn: Bool
        public var source: ActionSource = .auto
        // 是否横屏展示
        public let shouldLandscape: Bool
        // PDF的展示模式：连续/不连续
        public let mode: PDFDisplayMode
        // PDFView背景颜色
        public let backgroundColor: UIColor
        // 是否显示滚动球
        public let enableScrollBar: Bool
        // 是否显示缩略图
        public let enableGrid: Bool
        // 是否显示演示模式下的蒙层
        public let enablePresentationMask: Bool
        /// 是否启用缩略图功能(用于控制 PDFKit 生成缩略图的操作)
        public var enableThumbnail: Bool = true
        
        /// PDF 缩放大小
        public var maxScale: Float = 6
        
        public var minScale: Float = 0.5
    }
}

open class SKPDFViewModel {
    public let fileURL: URL
    let presentationModeEnabled: Bool

    private let documentRelay = BehaviorRelay<PDFDocument?>(value: nil)
    private let thumbnailQueue = DispatchQueue(label: "spacekit.pdfkit.thumbnail")
    private let thumbnailSubject = PublishSubject<(Int, UIImage)>()
    /// 预览模式
    let configRelay: BehaviorRelay<Config>

    public var document: PDFDocument? {
        return documentRelay.value
    }

    public var pageCount: UInt {
        guard let document = document else { return 0 }
        return UInt(document.pageCount)
    }

    // MARK: - Rx Input
    /// 重新载入的信号输入
    let reloadDocumentSubject = PublishSubject<Void>()
    /// 用户输入密码
    let passwordSubject = PublishSubject<String>()
    /// 缩略图请求，传入的页码为0开始
    let thumbnailRequestSubject = PublishSubject<(Int, CGSize)>()
    /// PDF UI加载完成事件
    public let uiReadyRelay = BehaviorRelay<Bool>(value: false)
    /// 上一页
    let goPreviousSubject = PublishSubject<()>()
    /// 下一页
    let goNextSubject = PublishSubject<()>()
    /// 进入、退出演示模式事件
    public let presentationModeChangedSubject = PublishSubject<(Bool, Config.ActionSource)>()

    // MARK: - Rx Output
    /// 模式变更通知
    public lazy var configChanged: Driver<Config> = {
        return Observable.combineLatest(configRelay, uiReadyRelay)
            .filter { $0.1 }
            .map { $0.0 }
            .asObservable()
            .asDriver(onErrorJustReturn: .default)
    }()
    /// 上一页
    public lazy var goPrevious: Driver<()> = {
        return self.goPreviousSubject.asObservable().asDriver(onErrorJustReturn: ())
    }()
    /// 下一页
    public lazy var goNext: Driver<()> = {
        return self.goNextSubject.asObservable().asDriver(onErrorJustReturn: ())
    }()
    /// PDF文件加载完成
    public var documentUpdated: Driver<PDFDocument> {
        return documentRelay
            .compactMap { $0 }
            .asDriver(onErrorJustReturn: PDFDocument())
    }

    /// 加载文件后是否需要输入密码
    var documentNeedUnlock: Driver<Bool> {
        return documentRelay
            .flatMap { document -> Observable<Bool> in
                guard let document = document else {
                    return .never()
                }
                return .just(document.isLocked)
            }
        .asDriver(onErrorJustReturn: false)
    }

    /// 输入密码后解密是否成功
    var unlockDocumentUpdated: Driver<Bool> {
        return passwordSubject
            .flatMap { [weak self] password -> Observable<Bool> in
                guard let self = self else {
                    return .never()
                }
                guard let document = self.document else {
                    spaceAssertionFailure("drive.pdfkit.vm --- password updated when document is nil!")
                    return .never()
                }
                let result = document.unlock(withPassword: password)
                return .just(result)
            }
        .asDriver(onErrorJustReturn: false)
    }

    var thumbnailUpdated: Driver<(Int, UIImage)> {
        return thumbnailRequestSubject
            .observeOn(SerialDispatchQueueScheduler(queue: thumbnailQueue,
                                                    internalSerialQueueName: "drive.pdfkit.thumbnail.schedular"))
            .flatMap { [weak self] (pageNumber, size) -> Observable<(Int, UIImage)> in
                guard let self = self else {
                    return .never()
                }
                guard let document = self.document else {
                    DocsLogger.error("drive.pdfkit.vm --- get thumbnail when document is not ready!")
                    return .never()
                }
                guard let page = document.page(at: pageNumber) else {
                    DocsLogger.error("drive.pdfkit.vm --- get thumbnail failed, unable to get page at index: \(pageNumber)")
                    return .never()
                }
                let thumbnail = page.thumbnail(of: size, for: .mediaBox)
                return .just((pageNumber, thumbnail))
            }
        .asDriver(onErrorJustReturn: (0, UIImage()))
    }

    public var currentConfig: Config {
        return configRelay.value
    }

    public let disposeBag = DisposeBag()

    /// 初始化传入的 Config
    var originConfig: Config
    
    public init(fileURL: URL, config: Config) {
        presentationModeEnabled = config.shouldShowPresentationSwitchBtn
        self.fileURL = fileURL
        self.originConfig = config
        configRelay = BehaviorRelay<Config>(value: config)
        setup()
    }

    private func setup() {
        reloadDocumentSubject
            .bind { [weak self] in
                guard let self = self else { return }
                self.documentRelay.accept(PDFDocument(url: self.fileURL))
            }
        .disposed(by: disposeBag)

        presentationModeChangedSubject
            .distinctUntilChanged {
                if $1.1 == .click {
                    // 点击主动触发的变化无需过滤，避免无法退出预览模式
                    return false
                } else {
                    // 通过判断 isPresentationMode 来比较演示模式状态是否改变
                    return $0.0 == $1.0
                }
            }
            .map { [weak self] (isPresentationMode, source) -> Config in
                guard let self = self else { return .default }
                var config: Config
                if isPresentationMode {
                    // 进入演示模式
                    config = .presentationPPTMode
                } else {
                    if self.presentationModeEnabled {
                        // 退出演示模式，且支持进入演示模式
                        config = .normalPPTMode
                    } else {
                        // 退出演示模式，且不支持进入演示模式
                        config = .default
                    }
                }
                config.source = source
                return config
            }
        .bind { [weak self] newConfig in
            self?.configRelay.accept(newConfig)
        }
        .disposed(by: disposeBag)
    }

    /// 异步获取缩略图
    /// - Parameters:
    ///   - pageNumber: 从0开始的页码
    ///   - size: 缩略图尺寸
    ///   - handler: 处理缩略图的回调
    func getThumbnail(pageNumber: Int, size: CGSize, handler: @escaping (Result<(Int, UIImage), ThumbnailError>) -> Void) {
        thumbnailQueue.async { [weak self] in
            guard let self = self else { return }
            guard let document = self.document else {
                DocsLogger.error("drive.pdfkit.vm --- get thumbnail when document is not ready!")
                handler(.failure(ThumbnailError.documentNotReady))
                return
            }
            guard let page = document.page(at: pageNumber) else {
                DocsLogger.error("drive.pdfkit.vm --- get thumbnail failed, unable to get page at index: \(pageNumber)")
                handler(.failure(ThumbnailError.invalidPageNumber))
                return
            }
            let pageSize = page.bounds(for: .mediaBox).size
            DocsLogger.info("drive.pdfkit.vm --- get thumbnail pageSize: \(pageSize)")
            let thumbnail = page.thumbnail(of: size, for: .mediaBox)
            handler(.success((pageNumber, thumbnail)))
        }
    }
}

