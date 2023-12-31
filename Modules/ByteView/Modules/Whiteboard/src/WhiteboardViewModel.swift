//
//  WhiteboardViewModel.swift
//  Whiteboard
//
//  Created by helijian on 2022/2/28.
//

import Foundation
import WbLib
import ByteViewNetwork
import ByteViewCommon
import UniverseDesignTheme
import UniverseDesignColor

typealias RwAtomic = ByteViewCommon.RwAtomic

public struct WhiteboardClientConfig {
    let meetingID: String
    let renderFPS: Int
    let sendIntervalMs: Int
    let maxPageCount: Int
    let canvasSize: CGSize
    let account: ByteviewUser

    public init(meetingID: String, renderFPS: Int, sendIntervalMs: Int, maxPageCount: Int, canvasSize: CGSize, account: ByteviewUser) {
        self.meetingID = meetingID
        self.renderFPS = renderFPS
        self.sendIntervalMs = sendIntervalMs
        self.maxPageCount = maxPageCount
        self.canvasSize = canvasSize
        self.account = account
    }
}

class WhiteboardViewModel {
    static let saveQueue = DispatchQueue(label: "WhiteboardViewModel.SaveQueue", attributes: .concurrent)
    @RwAtomic
    private var isSaving: Bool = false
    // 当前主题，用于多白板页面背景色以及白板背景色的设置，有变化时，多白板数据要重新生成。
    static var currentTheme: WbTheme = .Light
    // 外部依赖
    var dependencies: Dependencies?
    // 缓存生成好的多白板数据, 降低不必要的重复生成。
    var resultOfItems: [Int64: WhiteboardSnapshotItem] = [:]
    // 用于判断多白板页面数据是否需要重新生成
    var pageHasChanged: [Int64: Bool] = [:]
    var currentPageID: Int64?
    var grootSession: GrootSession?
    @RwAtomic
    var upVersion: Int64 = 0
    var lastPaths: [String: CGMutablePath] = [:]
    weak var delegate: WhiteboardViewDelegate?
    weak var dataDelegate: WhiteboardDataDelegate?

    let account: ByteviewUser
    let drawBoard: DrawBoard
    let wbClient: WhiteboardClient
    let isEnableIncrementalPath: Bool = true

    @RwAtomic
    private var pageIDs: Set<Int64> = []
    private var snapshotCount: Int = 0
    private var lastSnapshotData: Data?
    private var lastWhiteboardInfo: WhiteboardInfo?

    @RwAtomic
    private var isWhiteBoardSaved: Bool = false
    @RwAtomic
    private var pageHasSaved: [Int64: Bool] = [:]

    func savePages(pageIDs: [Int64]) {
        for pageID in pageIDs {
            pageHasSaved[pageID] = true
        }
        reportPageSaveIfNeeded()
    }

    func resetPageSave() {
        guard let currentPageID = currentPageID,
              pageHasSaved[currentPageID] != false else {
            return
        }
        pageHasSaved[currentPageID] = false
        reportPageSaveIfNeeded()
    }

    private func reportPageSaveIfNeeded() {
        var isAllSaved: Bool = true
        for pageID in pageIDs {
            isAllSaved = isAllSaved && (pageHasSaved[pageID] ?? false)
        }
        if isWhiteBoardSaved != isAllSaved {
            isWhiteBoardSaved = isAllSaved
            dataDelegate?.didChangeSnapshotSaveState(isSaved: isAllSaved)
        }
    }

    // 埋点相关
    private var shouldTrack = false
    private var pullSnapshotCost: CFTimeInterval?
    private var setSnapshotTime: CFTimeInterval?

    private let meetingID: String
    private let renderFPS: Int
    private let sendIntervalMs: Int
    private let layerBuild = LayerBuilder()

    var canvasSize: CGSize {
        didSet {
            drawBoard.canvasSize = canvasSize
        }
    }

    var isSelfSharing: Bool {
        if lastWhiteboardInfo?.sharer == account {
            return true
        }
        return false
    }

    var hasMultiBoards: Bool {
        guard let info = lastWhiteboardInfo else {
            return false
        }
        return info.pages.count > 1
    }

    init(clientConfig: WhiteboardClientConfig,
         whiteboardInfo: WhiteboardInfo?) {
        self.meetingID = clientConfig.meetingID
        self.account = clientConfig.account
        self.canvasSize = clientConfig.canvasSize
        self.renderFPS = clientConfig.renderFPS
        self.sendIntervalMs = clientConfig.sendIntervalMs
        self.wbClient = WhiteboardClient(account: account, renderFPS: renderFPS, sendIntervalMs: sendIntervalMs, isEnableIncrementalPath: isEnableIncrementalPath)
        self.wbClient.configDefaultClient()
        drawBoard = DrawBoard(renderer: SketchHybridRenderer(canvasSize: canvasSize))
        if #available(iOS 13.0, *) {
            NotificationCenter.default.addObserver(self, selector: #selector(didChangeTheme), name: UDThemeManager.didChangeNotification, object: nil)
            didChangeTheme()
        }
        drawBoard.changeBackgroundColor(UIColor.ud.bgBody)
        self.wbClient.configTheme(mode: Self.currentTheme)
        if let whiteboardInfo = whiteboardInfo {
            receiveWhiteboardInfo(info: whiteboardInfo)
        }
        logger.info("init whiteboardViewModel")
    }

    @available(iOS 13.0, *)
    @objc func didChangeTheme() {
        let currentUserTheme = UDThemeManager.getRealUserInterfaceStyle()
        logger.info("theme changed because of app config")
        changeTheme(theme: currentUserTheme)
    }

    @available(iOS 13.0, *)
    func changeTheme(theme: UIUserInterfaceStyle? = nil) {
        guard let theme = theme else { return }
        switch theme {
        case .light, .unspecified:
            Self.currentTheme = .Light
        case .dark:
            Self.currentTheme = .Dark
        }
        resultOfItems = [:]
        pageHasChanged = [:]
        logger.info("changeTheme to \(theme)")
        drawBoard.changeBackgroundColor(UIColor.ud.bgBody)
        wbClient.configTheme(mode: Self.currentTheme)
    }

    func configWbClientNotificationDelegate() {
        wbClient.notificationDelegate = self
    }

    func getThemeColor() -> UIColor {
        return Self.currentTheme.color
    }

    func receiveWhiteboardInfo(info: WhiteboardInfo) {
        guard info != lastWhiteboardInfo else {
            logger.info("receiveWhiteboardInfo failed because of same value")
            return
        }
        logger.info("receiveWhiteboardInfo info: \(info)")
        // 判断是否删除页面
        let hasRemovedPages = handlePages(newPages: info.pages, oldPages: lastWhiteboardInfo?.pages ?? [])
        // 正在共享的页面发生变化
        let pageId = handleCurrentPage(info.pages.first(where: { $0.isSharing})?.pageID)
        self.lastWhiteboardInfo = info
        if let pageId = pageId {
            self.handleMultiPageInfo(info: info)
            fetchWhiteboardSnapshot(whiteboardID: info.whiteboardID, pageID: pageId) { [weak self] in
                guard let self = self else { return }
                self.delegate?.shouldReloadTotalSnapshot()
            }
        } else if hasRemovedPages {
            self.handleMultiPageInfo(info: info)
            self.delegate?.shouldReloadTotalSnapshot()
        }
    }

    func configDependencies(_ dependencies: Dependencies? = nil) {
        self.dependencies = dependencies
    }

    func getMultiPageInfo() {
        guard let info = lastWhiteboardInfo else { return }
        handleMultiPageInfo(info: info)
    }

    func getSnapshotItems() -> [WhiteboardSnapshotItem] {
        guard currentPageID != nil else {
            logger.info("getSnapshotItems error, no currentPageID")
            return []
        }
        guard let info = lastWhiteboardInfo else {
            logger.info("getSnapshotItems error, no lastWhiteboardInfo")
            return []
        }
        var result: [WhiteboardSnapshotItem] = []
        let pages = info.pages
        for (index, page) in pages.enumerated() {
            // 如果是已经拉取过，但是没有切换到对应页的页面，可以直接返回item
            // pullsnapshot后，但是未switchPage的页面
            if let hasChanged = pageHasChanged[page.pageID], !hasChanged, var item = resultOfItems[page.pageID] {
                item.index = index + 1
                item.totalCount = pages.count
                resultOfItems[page.pageID] = item
                result.append(item)
                continue
            }
            // 如果已经展示过的页面(可能有新数据产生），直接生成最新的image
            if self.pageIDs.contains(page.pageID) {
                if let image = getImageWithPage(pageId: page.pageID) {
                    pageHasChanged[page.pageID] = true
                    let item = WhiteboardSnapshotItem(image: image, index: index + 1, totalCount: pages.count, page: page, whiteboardId: info.whiteboardID)
                    resultOfItems[page.pageID] = item
                    result.append(item)
                } else {
                    let item = WhiteboardSnapshotItem(index: index + 1, totalCount: pages.count, page: page, whiteboardId: info.whiteboardID)
                    resultOfItems[page.pageID] = item
                    result.append(item)
                }
                continue
            }
            // 未展示过的多白板页面，需要拉取snapshot然后生成image
            let item = WhiteboardSnapshotItem(index: index + 1, totalCount: pages.count, page: page, whiteboardId: info.whiteboardID)
            result.append(item)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                let pullSnapshotStartTime = CACurrentMediaTime()
                let request = PullWhiteboardSnapshotRequest(pageIds: [page.pageID], whiteboardID: info.whiteboardID)
                HttpClient(userId: self.account.id).getResponse(request) { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case .success(let response):
                        let pullSnapshotEndTime = CACurrentMediaTime()
                        self.pullSnapshotCost = pullSnapshotEndTime - pullSnapshotStartTime
                        logger.info("get snapshotImage with response snapshots: \(response.snapshots)")
                        guard let snapshot = response.snapshots.first else {
                            logger.info("get snapshotImage no sharing snapshot")
                            return
                        }
                        self.snapshotCount = snapshot.snapshotData.count
                        self.getSnapshotAndImage(snapshot.snapshotData, pageId: page.pageID, index: index, totalCount: pages.count, page: page, whiteboardId: info.whiteboardID)
                    case .failure(let error):
                        logger.info("get snapshotImage pullwhiteboardsnapshot fail with error: \(error)")
                    }
                }
            }
        }
        // 默认选中正在共享的页面
        for index in result.indices {
            if result[index].page.isSharing {
                result[index].state = .selected
            }
        }
        return result
    }

    func saveCurrentSnapshot(completion: @escaping PhotoManager.PhotoSaveCompletion) {
        guard currentPageID != nil else {
            logger.error("save whiteboard error, no currentPageID")
            completion(.failure(PhotoManager.PhotoSaveError.unknown))
            return
        }
        guard let info = lastWhiteboardInfo else {
            logger.error("save whiteboard error, no lastWhiteboardInfo")
            completion(.failure(PhotoManager.PhotoSaveError.unknown))
            return
        }
        guard let currentPage = info.pages.first(where: { $0.pageID == currentPageID }) else {
            completion(.failure(PhotoManager.PhotoSaveError.unknown))
            return
        }
        saveSnapshots(pages: [currentPage], whiteboardID: info.whiteboardID, completion: completion)
    }

    func saveAllSnapshot(completion: @escaping PhotoManager.PhotoSaveCompletion) {
        guard let info = lastWhiteboardInfo else {
            logger.error("save whiteboard error, no lastWhiteboardInfo")
            completion(.failure(PhotoManager.PhotoSaveError.unknown))
            return
        }
        saveSnapshots(pages: info.pages, whiteboardID: info.whiteboardID, completion: completion)
    }

    private func saveSnapshots(pages: [WhiteboardPage], whiteboardID: Int64, completion: @escaping PhotoManager.PhotoSaveCompletion) {
        guard !isSaving else {
            logger.debug("save whiteboard saving, skip")
            completion(.failure(PhotoManager.PhotoSaveError.running))
            return
        }
        isSaving = true
        let _completion: PhotoManager.PhotoSaveCompletion = { [weak self] result in
            completion(result)
            self?.isSaving = false
        }

        logger.debug("save whiteboard start, count: \(pages.count)")

        var snapshotItems: [WhiteboardSnapshotItem] = []

        let saveBlock = { [weak self] in
            logger.debug("save whiteboard ready, count: \(snapshotItems.count)")
            let data = snapshotItems.sorted(by: { $0.index < $1.index }).compactMap { $0.image?.pngData() }
            guard !data.isEmpty else {
                logger.error("save whiteboard fail when transfer to data")
                _completion(.failure(PhotoManager.PhotoSaveError.unknown))
                return
            }
            PhotoManager.shared
                .savePhotos(
                    data: data
                ) { result in
                    _completion(result)
                    switch result {
                    case .success:
                        logger.debug("save whiteboard success")
                        self?.dependencies?.showToast(BundleI18n.Whiteboard.View_G_SavedToAlbum_Toast)
                        self?.savePages(pageIDs: pages.map { $0.pageID })
                    case .failure(let error):
                        logger.error("save whiteboard fail with error: \(error)")
                    }
                }
        }

        let execute: () -> Void = { [weak self] in
            var layerCache: [Int: CALayer?] = [:]
            for (index, page) in pages.enumerated() {
                var filterEmptyBoard = true
                if self?.currentPageID == page.pageID {
                    // 保留当前页面
                    filterEmptyBoard = false
                }
                self?.dependencies?.getWatermarkView { watermarkView in
                    // assert main
                    let layer = self?.getLayerWithPage(pageId: page.pageID,
                                                       watermarkLayer: watermarkView?.layer,
                                                       filterEmptyBoard: filterEmptyBoard)
                    layerCache[index] = layer
                    let isOpaque: Bool? = layer?.isOpaque
                    let bounds: CGRect? = layer?.bounds
                    if layerCache.count == pages.count {
                        // 等待下一个loop
                        DispatchQueue.main.async {
                            // 此步骤会造成主线程阻塞，放子线程处理
                            for (index, page) in pages.enumerated() {
                                if let layer = layerCache[index] as? CALayer {
                                    Self.saveQueue.async {
                                        let item = WhiteboardSnapshotItem(image: layer.vc.toImage(isOpaque: isOpaque, bounds: bounds), index: index, totalCount: pages.count, page: page, whiteboardId: whiteboardID)
                                        snapshotItems.append(item)
                                    }
                                }
                            }
                            Self.saveQueue.async(flags: .barrier) {
                                saveBlock()
                            }
                        }
                    }
                }
            }
        }

        let newPageIDs = pages.filter { !pageIDs.contains($0.pageID) }.map { $0.pageID }

        if newPageIDs.isEmpty {
            // 数据已缓存，直接保存
            execute()
        } else {
            // 需要拉取数据
            let request = PullWhiteboardSnapshotRequest(pageIds: newPageIDs, whiteboardID: whiteboardID)
            HttpClient(userId: account.id).getResponse(request) { [weak self] result in
                switch result {
                case .success(let response):
                    for snapshot in response.snapshots {
                        self?.wbClient.setPageSnapshot(snapshot.snapshotData.bytes)
                        self?.pageIDs.insert(snapshot.page.pageID)
                    }
                    execute()
                case .failure(let error):
                    logger.error("save whiteboard pullwhiteboardsnapshot fail with error: \(error)")
                    _completion(.failure(PhotoManager.PhotoSaveError.unknown))
                }
            }
        }
    }

    // MARK: private
    private func getSnapshotAndImage(_ data: Data, pageId: Int64, index: Int, totalCount: Int, page: WhiteboardPage, whiteboardId: Int64) {
        DispatchQueue.main.async {
            logger.info("getSnapshotAndImage \(pageId) \(index) \(totalCount)")
            self.wbClient.setPageSnapshot(data.bytes)
            self.pageIDs.insert(pageId)
            if let image = self.getImageWithPage(pageId: pageId) {
                self.pageHasChanged[pageId] = false
                let item = WhiteboardSnapshotItem(image: image, index: index + 1, totalCount: totalCount, page: page, whiteboardId: whiteboardId)
                self.resultOfItems[pageId] = item
                self.delegate?.shouldReloadSnapshot(item: item)
            }
        }
    }

    private func getLayerWithPage(pageId: Int64,
                                  watermarkLayer: CALayer? = nil,
                                  filterEmptyBoard: Bool = false) -> CALayer? {
        // 渲染所有笔画
        let wbGraphic = wbClient.getPageGraphics(pageId: pageId)
        if filterEmptyBoard, wbGraphic.isEmpty {
            return nil
        }
        let layer = CALayer()
        layer.backgroundColor = Self.currentTheme.color.cgColor
        layer.bounds = CGRect(origin: .zero, size: canvasSize)
        for graphic in wbGraphic {
            switch graphic.primitive {
            case .Path:
                let shape = VectorShape(id: "", wbGraphic: graphic)
                let shapeLayer = layerBuild.buildLayer(drawable: shape)
                if let shapeLayer = shapeLayer {
                    layer.addSublayer(shapeLayer)
                }
            case .Text:
                let shape = TextDrawable(id: "", wbGraphic: graphic)
                let shapeLayer = layerBuild.buildRecognizeTextLayer(drawable: shape)
                if let shapeLayer = shapeLayer {
                    layer.addSublayer(shapeLayer)
                }
            default:
                break
            }
        }
        if let watermarkLayer = watermarkLayer {
            layer.addSublayer(watermarkLayer)
            // 水印需要强制渲染一下，否则不显示
            layer.setNeedsLayout()
            layer.layoutIfNeeded()
        }
        return layer
    }

    private func getImageWithPage(pageId: Int64) -> UIImage? {
        // nolint-next-line: magic number
        return getLayerWithPage(pageId: pageId)?.vc.toImage(scale: 0.15)
    }

    private func receiveRemoteSyncData(_ data: Data, type: DataType) {
        resetPageSave()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch type {
            case .drawData:
                self.wbClient.handleSyncData(data.bytes, type: .DrawData)
            case .syncData:
                self.wbClient.handleSyncData(data.bytes, type: .SyncData)
            }
        }
    }

    private func receiveSnapshotData(_ data: Data) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            logger.info("receiveSnapshotData \(data.count)")
            self.wbClient.setPageSnapshot(data.bytes)
        }
    }

    private func removePage(id: Int64) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            logger.info("remove page \(id)")
            self.resultOfItems.removeValue(forKey: id)
            self.pageHasChanged.removeValue(forKey: id)
            self.wbClient.removePage(id: id)
        }
    }

    private func newPage(id: Int64) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            logger.info("new page \(id)")
            self.wbClient.newPage(id: id)
        }
    }

    private func switchPage(id: Int64) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            logger.info("switch page \(id)")
            self.pageHasChanged[id] = true
            self.wbClient.switchPage(id: id)
        }
    }

    private func fetchWhiteboardSnapshot(whiteboardID: Int64, pageID: Int64, completion: (() -> Void)? = nil) {
        let channelID = "\(whiteboardID)"
        // 如果是之前存在的页面，直接切换页面
        if pageIDs.contains(pageID) {
            logger.info("snapshot exists pageID: \(pageID)")
            switchPage(id: pageID)
            currentPageID = pageID
            // nolint-next-line: magic number
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                completion?()
            }
            return
        }
        shouldTrack = true
        let pullSnapshotStartTime = CACurrentMediaTime()
        logger.info("start fetchWhiteboardSnapshot, whiteboardID: \(whiteboardID), pageID: \(pageID)")
        let request = PullWhiteboardSnapshotRequest(pageIds: [pageID], whiteboardID: whiteboardID)
        HttpClient(userId: account.id).getResponse(request) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                let pullSnapshotEndTime = CACurrentMediaTime()
                self.pullSnapshotCost = pullSnapshotEndTime - pullSnapshotStartTime
                logger.info("response snapshots: \(response.snapshots)")
                guard let snapshot = response.snapshots.first else {
                    logger.info("no sharing snapshot")
                    return
                }
                self.pageIDs.insert(pageID)
                self.snapshotCount = snapshot.snapshotData.count
                self.receiveSnapshotData(snapshot.snapshotData)
                self.switchPage(id: pageID)
                self.currentPageID = pageID
                self.openGrootChannelIfNeed(channelID: channelID, version: snapshot.latestDownVersion)
                // 防止SDK还未切换页面
                // nolint-next-line: magic number
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    completion?()
                }
            case .failure(let error):
                logger.info("fetchWhiteboardSnapshot fail with error: \(error)")
            }
        }
    }

    private func openGrootChannelIfNeed(channelID: String, version: Int64) {
        if let grootSession = grootSession {
            grootSession.update(version: version, useUpVersionFromSource: true)
            logger.info("update groot session with version: \(version)")
        } else {
            let meetingMeta = MeetingMeta(meetingID: meetingID)
            let grootSession: GrootSession = GrootSession(userId: account.id, channel: GrootChannel(id: channelID, type: .newWhiteBoardChannel, meetingMeta: meetingMeta), cellHandler: self)
            self.grootSession = grootSession
            grootSession.open(version: version, useUpVersionFromSource: true) { [weak self] result in
                logger.info("grootSession open result: \(result)")
                if self?.grootSession?.isOpen == true {
                    // 拉一下最新数据，防止snapshot确实数据
                    self?.grootSession?.update(version: version, useUpVersionFromSource: true)
                }
            }
            logger.info("open groot channel with channelID: \(channelID), version: \(version)")
        }
    }

    private func handlePages(newPages: [WhiteboardPage], oldPages: [WhiteboardPage]) -> Bool {
        guard newPages != oldPages else {
            return false
        }
        let newIds = Set(newPages.map { $0.pageID })
        let oldIds = Set(oldPages.map { $0.pageID })
        let removeIds = oldIds.subtracting(newIds)
        if !removeIds.isEmpty {
            // 旧的页面删除
            logger.info("didRemoveOldPages: \(removeIds)")
            removeIds.forEach { self.removePage(id: $0) }
            return true
        }
        return false
    }

    private func handleCurrentPage(_ pageID: Int64?) -> Int64? {
        guard let pageID = pageID else { return nil }
        guard currentPageID != pageID else { return nil }
        logger.info("handleCurrentPage: \(pageID)")
        return pageID
    }

    private func handleMultiPageInfo(info: WhiteboardInfo) {
        guard let currentPage = info.pages.first(where: { $0.isSharing}) else {
            logger.info("handleMultiPageInfo failed: no currentSharing page")
            return
        }
        delegate?.changeMultiPageInfo(currentPageNum: currentPage.pageNum, totalPages: info.pages.count)
    }
}

// MARK: - 白板埋点
extension WhiteboardViewModel {

    func didFinishRenderCmds() {
        guard shouldTrack,
              let setSnapshotTime = setSnapshotTime,
              let pullSnapshotCost = pullSnapshotCost,
              let whiteboardID = lastWhiteboardInfo?.whiteboardID else {
            return
        }
        let finishRenderCmdsTime = CACurrentMediaTime()
        let renderSnapshotCost = finishRenderCmdsTime - setSnapshotTime
        WhiteboardTracks.trackSnapshotPaint(pullCost: pullSnapshotCost * 1000,
                                            renderCost: renderSnapshotCost * 1000,
                                            bytesize: snapshotCount,
                                            whiteboardID: whiteboardID)
        shouldTrack = false
    }

    func didTimerPaused(fps: Int, shapeCount: Int, cmdsCount: Int) {
        guard let whiteboardID = lastWhiteboardInfo?.whiteboardID else {
            return
        }
        WhiteboardTracks.trackRenderFps(fps, shapeCount: shapeCount, cmdsCount: cmdsCount, whiteboardID: whiteboardID)
    }
}

extension WhiteboardViewModel: GrootCellHandler {
    func processGrootCells(_ cells: [GrootCell]) {
        cells.forEach { cell in
            if let sender = cell.sender, sender == account { return }
            switch cell.dataType {
            case .whiteboardDrawData:
                receiveRemoteSyncData(cell.payload, type: .drawData)
            case .whiteboardSyncData:
                receiveRemoteSyncData(cell.payload, type: .syncData)
            default:
                break
            }
        }
    }
}

extension Dependencies {
    func nicknameBy(graphicInfo: DrawingStateData, completion: @escaping (String) -> Void) {
        return nicknameBy(userID: graphicInfo.userId, deviceID: graphicInfo.deviceId, userType: graphicInfo.userType, completion: completion)
    }
}


private extension Data {
    var bytes: [UInt8] {
        return [UInt8](self)
    }
}

extension WbTheme {
    var color: UIColor {
        switch self {
        case .Dark:
            return UIColor.ud.N50.alwaysDark
        case .Light:
            return UIColor.ud.N00.nonDynamic
        }
    }
}
