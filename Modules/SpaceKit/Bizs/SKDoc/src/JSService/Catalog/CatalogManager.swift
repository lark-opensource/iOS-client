//
//  CatalogManager.swift
//  SpaceKit
//
//  Created by Webster on 2019/5/5.
//

// swiftlint:disable file_length
import SKFoundation
import SKCommon
import SKBrowser
import SKUIKit
import RxSwift
import UIKit
import LarkUIKit
import SpaceInterface

/// delegate
protocol CatalogManagerDelegate: AnyObject {
    /// 显示底部目录入口的时候发送的回调
    ///
    /// - Parameters:
    ///   - show: 是否显示目录入口
    ///   - emptyHeight: webview扣除目录入口界面的剩余高度
    func notifyDisplayBottomEntry(show: Bool, emptyHeight: CGFloat)
}

class CatalogManager {
    /// 目录入口、目录按钮的布局信息
    private class CatalogLayout {
        static var keyboardHeight: CGFloat = 0
        static let indicatorSize: CGFloat = 72
        static var sideWidth: CGFloat = 206
        static let indicatorRealSize: CGFloat = BrowseCatalogIndicator.circleWidth
        static let bottomEntryHeight: CGFloat = 48
        static let navigationBarHeight: CGFloat = 44.0
        static let statusBarHeight: CGFloat = UIApplication.shared.statusBarFrame.height
        static let shadowPadding: CGFloat = (indicatorSize - BrowseCatalogIndicator.circleWidth) / 2
    }
    
    private class Const {
        static var keyboardHeight: CGFloat = 44
        static let boardHeight: CGFloat = 22
        static var duration: Double = 0.3
        static var asyncAfterTime = 0.1
        static var asyncAfterJump = 0.15
    }

    var docsType: DocsType?
    var canShowIPadCatalog: Bool {
        if SKDisplay.pad, let docsType = docsType, docsType == .docX {
            return true
        }
        return false
    }

    // 用于获悉当前是否已经获取到数据
    var alreadyFetchData: Bool = false
    
    //iphone目录详情支持的屏幕方向
    private(set) var supportOrentations: UIInterfaceOrientationMask = .portrait

    /// delegate
    weak var delegate: CatalogManagerDelegate?
    /// 滚动信息
    private weak var proxy: EditorScrollViewProxy?
    /// 工具栏关联接口
    private weak var toolBar: DocsToolbarManagerProxy?
    /// js执行接口
    private weak var jsEngine: BrowserJSEngine?
    /// 路由
    private weak var navigator: BrowserNavigator?

    private var safeAreaInsets: UIEdgeInsets {
        return navigator?.currentBrowserVC?.view.safeAreaInsets ?? UIEdgeInsets.zero
    }
    /// 目录所要依附的view
    private weak var attachView: CatalogPadDisplayer?
    /// 当前文档信息
    private var docsInfo: DocsInfo?
    /// 工具栏的目录入口
    private lazy var catalogEntryView: CatalogBottomEntryView = {
        let fontZoomable = self.docsInfo?.fontZoomable ?? false
        let view = CatalogBottomEntryView(frame: .zero, alignment: .center, fontZoomable: fontZoomable)
        view.snp.makeConstraints { (make) in
            make.height.equalTo(44)
        }
        view.displayTopShadow()
        return view
    }()
    /// 侧边栏 - 目录指示器
    private var catalogIndicator: BrowseCatalogIndicator?
    /// 侧边栏 - 目录详情
    private(set) var catalogSideView: BrowserCatalogSideView?
    /// 底部目录入口
    private(set) var catalogBottomEntry: CatalogBottomEntryView?
    /// 目录详情
    private(set) weak var weakCatalogDetailsVC: CatalogDetailsViewController?
    /// 目录详细信息
    private var catalogDatas: [CatalogItemDetail]?
    /// 目录相关界面的移除计时器
    private(set) var timer: Timer?
    /// 目录相关的view的退出时间
    private let animationDuration = 0.3
    /// 侧边目录跟底边目录的消失间隔时间
    private let animationBlanking = 0.15
    /// 目录指示器消失时候的y坐标
    private var indicatorRemovedY: CGFloat = 0
    /// 是否是手指拖动触发的滚动
    private var scrollByDragging: Bool = false
    ///
    private var doingSideCatalogItemAnimation = false
    private var removingBottomEntry = false
    private var hostWidth: CGFloat {
        guard let hostVC = self.navigator?.currentBrowserVC else {
            return 0
        }
        return hostVC.view.bounds.width
    }
    ///目录显示监听
    private let catalogDisplayObserver = BehaviorSubject<Bool>(value: false)

    /// iPad 目录
    private var iPadCatalogSideView: IPadCatalogSideView?
    private(set) var catalogViewAllowCapture = true // 文档大纲是否允许被截图
    private var ipadCatalogMode: IPadCatalogMode?
    private var highlightIdentifier: String?
    private var curKeyboardHeight: CGFloat = 0

    init(attach: CatalogPadDisplayer?,
         proxy: EditorScrollViewProxy?,
         toolBar: DocsToolbarManagerProxy?,
         jsEngine: BrowserJSEngine?,
         navigator: BrowserNavigator?) {
        self.attachView = attach
        self.proxy = proxy
        self.toolBar = toolBar
        self.jsEngine = jsEngine
        self.navigator = navigator
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(orientationDidChange),
                                               name: UIApplication.didChangeStatusBarOrientationNotification,
                                               object: nil)
    }

    deinit {
        killTimer()
    }

    @objc
    func orientationDidChange() {
        removeAll(animated: false)
        weakCatalogDetailsVC?.orientationDidChange()
    }
    
    private func updateIndicatorFrame() {
        guard let catalogIndicatorView = catalogIndicator else { return }
        let attachViewWidth = attachView?.frame.width ?? self.hostWidth
        let indicatorX: CGFloat = (attachViewWidth - BrowseCatalogIndicator.indicatorSizeHalf)
        let dx = indicatorX - catalogIndicatorView.frame.minX
        let newFrame = catalogIndicatorView.frame.offsetBy(dx: dx, dy: CGFloat(0))
        catalogIndicator?.frame = newFrame
    }
}

extension CatalogManager: CatalogDisplayer {
    /// 重置目录信息 (文档退出后重置)
    func resetCatalog() {
        if canShowIPadCatalog {
            self.iPadCatalogSideView = nil
            self.alreadyFetchData = false
            self.highlightIdentifier = nil
        }
        CatalogLayout.keyboardHeight = 0
        self.catalogDatas = nil
    }

    /// 移除目录
    func hideCatalog() {
        if canShowIPadCatalog, let iPadCatalogSideView = iPadCatalogSideView, iPadCatalogSideView.superview != nil {
            self.attachView?.dismissCatalogSideViewByTapContent(complete: { [weak self] in
                guard let self = self else { return }
                self.jsEngine?.simulateJSMessage(DocsJSService.iPadCatalogButtonState.rawValue, params: ["isOpen": false])
                self.iPadCatalogSideView?.curKeyboardHeight = 0
            })
            return
        }
        self.doingSideCatalogItemAnimation = (catalogSideView != nil)
        removeSideAndBottom(animated: true, alongsideAnimation: { [weak self] in
            self?.toolBar?.setCoverStickerView(nil)
        }, completed: {
            self.doingSideCatalogItemAnimation = false
        })
        removeCatalogAccessoryWithDelay()
    }
    
    func setCatalogOrentations(_ orentations: UIInterfaceOrientationMask) {
        self.supportOrentations = orentations
    }

    /// 展示目录详情
    func showCatalogDetails() {
        openCatalogDetails(.more)
    }

    /// 隐藏目录详情
    func hideCatalogDetails() {
        weakCatalogDetailsVC?.dismiss(animated: false, completion: nil)
    }

    func closeCatalog() {
        resetCatalog()
        removeAll(animated: false)
    }

    /// 接受前端的目录信息
    ///
    /// - Parameter items: 目录详细信息
    func prepareCatalog(_ items: [CatalogItemDetail]) {
        self.alreadyFetchData = true
        if canShowIPadCatalog, let iPadCatalogSideView = iPadCatalogSideView, iPadCatalogSideView.superview != nil {
            self.catalogDatas = items
            iPadCatalogSideView.reload(items)
            iPadCatalogSideView.setCaptureAllowed(catalogViewAllowCapture)
            return
        }
        if canShowIPadCatalog , self.iPadCatalogSideView == nil, !items.isEmpty {
            jsEngine?.simulateJSMessage(DocsJSService.ipadCatalogDisplay.rawValue, params: ["autoShow": true, "autoPresentInEmbed": true])
            self.catalogDatas = items
            return
        }
        //如果前端回设的时候，当前正在展示目录，并且数量发生了变化，就重置
        if let oldData = catalogDatas,
            catalogIndicatorVisible(),
            oldData.count != items.count {
            removeAll(animated: false)
            self.catalogDatas = items
            weakCatalogDetailsVC?.reload(items, index: selectingIndex())
            weakCatalogDetailsVC?.setCaptureAllowed(catalogViewAllowCapture)
        } else {
            catalogSideView?.update(items, reload: true)
            catalogSideView?.setCaptureAllowed(catalogViewAllowCapture)
            let contentY = proxy?.contentOffset.y ?? 0
            var indicatorY = (catalogIndicator?.frame.minY) ?? 0
            indicatorY += CatalogLayout.shadowPadding
            catalogSideView?.resetIndex(contentOffsetY: contentY, indicatorOffsetY: indicatorY)
            self.catalogDatas = items
            weakCatalogDetailsVC?.reload(items, index: selectingIndex())
            weakCatalogDetailsVC?.setCaptureAllowed(catalogViewAllowCapture)
        }
    }

    func catalogDetails() -> [CatalogItemDetail]? {
        return catalogDatas
    }

    /// 键盘高度变化
    ///
    /// - Parameter options: 键盘信息
    func keyboardDidChangeState(_ options: Keyboard.KeyboardOptions) {
        switch options.event {
        case .willShow, .didShow, .willChangeFrame, .didChangeFrame:
            CatalogLayout.keyboardHeight = options.endFrame.height - Const.keyboardHeight
            if CatalogLayout.keyboardHeight == Const.keyboardHeight {
                requestDisplayToolBarCatalogEntry(show: false)
            }
        case .willHide, .didHide:
            CatalogLayout.keyboardHeight = 0
        default:
            return
        }
        self.updateIpadCatalogSideViewWith(options)
    }

    func updateIpadCatalogSideViewWith(_ options: Keyboard.KeyboardOptions) {
        guard SKDisplay.pad else {
            return
        }
        var curKeyboardHeight: CGFloat = 0
        switch options.event {
        case .didChangeFrame:
            curKeyboardHeight = options.endFrame.height + Const.boardHeight
        case .willHide, .didHide:
            curKeyboardHeight = 0
        default:
            return
        }
        self.curKeyboardHeight = curKeyboardHeight
        guard let iPadCatalogSideView = iPadCatalogSideView, iPadCatalogSideView.superview != nil else {
            return
        }
        if curKeyboardHeight >= 0 {
            iPadCatalogSideView.curKeyboardHeight = curKeyboardHeight
        }
    }

    func getCatalogDisplayObserver() -> BehaviorSubject<Bool> {
        return catalogDisplayObserver
    }

    // iPad目录显示
    func configIPadCatalog(_ isShow: Bool, autoPresentInEmbed: Bool, complete: ((_ mode: IPadCatalogMode) -> Void)?) {
        if self.iPadCatalogSideView == nil {
            guard let attachView = attachView else {
                return
            }
            let frame = CGRect(x: 0, y: 0, width: 100, height: attachView.frame.height)
            var status: IpadCatalogStatus
            if self.alreadyFetchData {
                if let datas = self.catalogDatas, datas.isEmpty {
                    status = .empty
                } else {
                    status = .normal
                }
            } else {
                status = .loading
            }
            self.iPadCatalogSideView = IPadCatalogSideView(frame: frame, status: status, darkModeEnable: true, details: self.catalogDatas ?? [])
            self.iPadCatalogSideView?.delegate = self
        }
        guard let sideView = self.iPadCatalogSideView else {
            return
        }
        if isShow {
            sideView.reload(self.catalogDatas ?? [])
            sideView.setCaptureAllowed(catalogViewAllowCapture)
            // 增加一个 Bool 值 autoPresentInEmbed，用于判断是处于：目录数据来了之后自动展示嵌入式目录的方法 如果当前没有全屏文档，则目录数据来了不自动展开目录
            self.attachView?.presentCatalogSideView(catalogSideView: sideView, autoPresentInEmbed: autoPresentInEmbed, complete: { [weak self] (mode) in
                guard let self = self, let identifier = self.highlightIdentifier else { return }
                self.setHighlightCatalogItemWith(identifier)
                self.iPadCatalogSideView?.curKeyboardHeight = self.curKeyboardHeight
                complete?(mode)
            })
        } else {
            self.attachView?.dismissCatalogSideView { [weak self] in
                guard let self = self else { return }
                self.iPadCatalogSideView?.curKeyboardHeight = 0
            }
        }
    }

    // 目前只有docsIpad使用到
    func setHighlightCatalogItemWith(_ identifier: String) {
        // 保留该值
        self.highlightIdentifier = identifier
        guard canShowIPadCatalog, let iPadCatalogSideView = iPadCatalogSideView, iPadCatalogSideView.superview != nil else {
            return
        }
        iPadCatalogSideView.setHighlightCatalogItemWith(identifier)
    }
}

extension CatalogManager: IPadCatalogSideViewDelegate {
    func didClickItem(_ item: CatalogItemDetail, mode: IPadCatalogMode) {
        jsJumpOffset(itemId: item.identifier)
        if mode == .covered {
            hideCatalog()
        }
    }
}

// MARK: - 外部调用接口
extension CatalogManager {
    func setCurDocsType(type: DocsType) {
        docsType = type
    }
    /// webview回调触发 begin dragging
    ///
    /// - Parameter info: 当前的docs info
    func catalogDidReceiveBeginDragging(info: DocsInfo?) {
        scrollByDragging = true
        docsInfo = info
        killTimer()
        if catalogReadyToDisplay() {
            showOrginalIndicator(false)
        }
    }

    /// webview回调触发 begin dragging
    ///
    /// - Parameters:
    ///   - isEditPool: 是否预加载 (预加载不需要触发目录)
    ///   - isOpenSDK: 是否群公告 （群公告不能触发目录）
    ///   - info: 文档信息
    func catalogDidReceivedScroll(isEditPool: Bool, hideCatalog: Bool, isOpenSDK: Bool, info: DocsInfo?) {
        docsInfo = info
        if let mayBeIndicator = catalogIndicator, mayBeIndicator.isInPanGesture { return }
        if !doingSideCatalogItemAnimation, hideCatalog {
            removeSideAndBottom(animated: false)
        }
        if isEditPool || isOpenSDK || !scrollByDragging { return }
        if !catalogReadyToDisplay() { return }
        if weakCatalogDetailsVC != nil { return }
        putIndicator()
        adjustIndicatorAndSidePoz()
    }

    func catalogDidEndScrollingAnimation() {
        scrollByDragging = false
    }

    /// webview回调触发: 用力滑动scrollview后滚动停止的瞬间
    func catalogDidReceiveEndDecelerating() {
        removeCatalogAccessoryWithDelay()
        scrollByDragging = false
    }

    /// webview回调触发: 小弧度滑动后停止
    ///
    /// - Parameter decelerate:
    func catalogDidReceiveEndDragging(decelerate: Bool) {
        //小弧度滑动后停止
        if !decelerate {
            removeCatalogAccessoryWithDelay()
            scrollByDragging = false
        }
    }
}

// MARK: - private
extension CatalogManager {
    ///当前界面上是否正在显示目录
    private func catalogIndicatorVisible() -> Bool {
        guard let incicator = catalogIndicator, incicator.superview != nil else { return false }
        return !(incicator.isHidden)
    }

    /// 目前是否能够显示目录
    ///
    /// - Returns: 是否有显示目录的条件
    func catalogReadyToDisplay() -> Bool {
        let count = self.catalogDatas?.count ?? 0
        var isDoc = true
        if let info = docsInfo {
            isDoc = (info.type == .doc) || (info.type == .docX)
        }
        let isPortrait = UIApplication.shared.statusBarOrientation.isPortrait
        return (count > 0) && isDoc && isPortrait
    }

    /// 添加目录侧边栏和底部入口
    private func putSideAndBottomEntry() {
        guard UIApplication.shared.statusBarOrientation.isPortrait else { return }
        if catalogSideView == nil || catalogSideView?.superview == nil {
            let docsType = self.docsInfo?.type ?? .doc
            let newSide = BrowserCatalogSideView(frame: .zero, docsType: docsType, items: self.catalogDatas ?? [CatalogItemDetail]())
            newSide.delegate = self
            if let indicator = catalogIndicator {
                attachView?.insertSubview(newSide, belowSubview: indicator)
            } else {
                attachView?.addSubview(newSide)
            }
            catalogSideView = newSide
                newSide.snp.makeConstraints { (make) in
                    make.width.equalTo(CatalogLayout.sideWidth)
                    make.top.right.equalToSuperview()
                    make.height.equalToSuperview()
                }
            catalogSideView?.setCaptureAllowed(catalogViewAllowCapture)
            reportDisplayNavCatalog()
            reportBottomEntryModifyWebEmpty(show: true)
            toolBar?.setToolbarInvisible(toHidden: true)
        }

        if catalogBottomEntry == nil || catalogBottomEntry?.superview == nil {
            let fontZoomable = self.docsInfo?.fontZoomable ?? false
            let newBottom = CatalogBottomEntryView(frame: .zero, alignment: .center, fontZoomable: fontZoomable)
            newBottom.displayTopShadow()
            let bottomHeight = CatalogLayout.bottomEntryHeight + self.safeAreaInsets.bottom
            attachView?.addSubview(newBottom)
            attachView?.bringSubviewToFront(newBottom)
            catalogBottomEntry = newBottom
            newBottom.delegate = self
            newBottom.snp.makeConstraints { (make) in
                make.left.right.bottom.equalToSuperview()
                make.height.equalTo(bottomHeight)
            }
        }

    }

    private func showOrginalIndicator(_ show: Bool) {
        proxy?.showsVerticalScrollIndicator = show
    }

    private func killTimer() {
        timer?.invalidate()
        timer = nil
    }

    /// 显示目录指示器
    private func putIndicator() {
        if let indicator = catalogIndicator, indicator.superview != nil {
            return
        } else {
            let rect = CGRect(x: BrowseCatalogIndicator.indicatorX(attachViewWidth: attachView?.frame.width ?? self.hostWidth),
                              y: CatalogLayout.shadowPadding,
                              width: CatalogLayout.indicatorSize,
                              height: CatalogLayout.indicatorSize)
            let newIndicator = BrowseCatalogIndicator(frame: rect)
            newIndicator.delegate = self
            catalogIndicator = newIndicator
            attachView?.addSubview(newIndicator)
            showOrginalIndicator(false)
        }
    }

    private func removeCatalogAccessoryWithDelay() {
        guard catalogIndicatorVisible() else { return }
        killTimer()
        let timer = Timer(timeInterval: 2.0, repeats: false) { [weak self] (_) in
            self?.removeAll(animated: true, alongsideAnimation: {
                self?.toolBar?.setCoverStickerView(nil)
            })
        }
        self.timer = timer
        RunLoop.current.add(timer, forMode: .default)
    }

    private func removeSideAndBottom(animated: Bool, alongsideAnimation: (() -> Void)? = nil, completed: (() -> Void)? = nil) {
        removingBottomEntry = (catalogBottomEntry != nil)
        func defaultRemoveSide() {
            self.catalogSideView?.removeFromSuperview()
            self.catalogSideView = nil
        }
        func defaultRemoveBottom() {
            self.catalogBottomEntry?.removeFromSuperview()
            self.catalogBottomEntry = nil
            removingBottomEntry = false
            requestDisplayToolBarCatalogEntry(show: false)
            toolBar?.setToolbarInvisible(toHidden: false)
        }

        if !animated {
            defaultRemoveSide()
            defaultRemoveBottom()
            alongsideAnimation?()
            completed?()
        } else {
        let bottomEntryHeight: CGFloat = self.catalogBottomEntry?.frame.height ?? 0
            UIView.animate(withDuration: animationDuration, animations: { [weak self] in
                self?.catalogSideView?.snp.updateConstraints({ (make) in
                    make.right.equalToSuperview().offset(CatalogLayout.sideWidth)
                })
                self?.catalogSideView?.alpha = 0.0
                self?.catalogSideView?.layoutIfNeeded()
                self?.attachView?.layoutIfNeeded()
                UIView.performWithoutAnimation {
                    self?.attachView?.superview?.layoutIfNeeded()
                }
                
            }, completion: { _ in
                defaultRemoveSide()
            })

            DispatchQueue.main.asyncAfter(deadline: .now() + animationBlanking) { [weak self] in
                let duration = self?.animationDuration ?? Const.duration
                UIView.animate(withDuration: duration, animations: { [weak self] in
                    self?.catalogBottomEntry?.snp.updateConstraints({ (make) in
                        make.bottom.equalToSuperview().offset(bottomEntryHeight)
                    })
                    alongsideAnimation?()
                    self?.catalogBottomEntry?.layoutIfNeeded()
                    self?.attachView?.layoutIfNeeded()
                    self?.attachView?.superview?.layoutIfNeeded()
                    }, completion: { _ in
                        defaultRemoveBottom()
                        completed?()
                })
            }
        }
    }

    private func adjustIndicatorAndSidePoz(resetSide: Bool = true) {
        guard let realProxy = self.proxy else { return }
        let contentOffsetY = realProxy.contentOffset.y
        let contentSizeY = realProxy.contentSize.height
        let contentDefaultY = realProxy.frame.size.height
        guard contentSizeY > 0,
            contentSizeY > contentDefaultY else { return }

        let scrollableHeight = contentSizeY - contentDefaultY
        let offsetRatio = contentOffsetY / scrollableHeight
        let maxIndicatorY = indicatorMaxYOffset()
        var indicatorY = maxIndicatorY * offsetRatio
        indicatorY = min(max(0, indicatorY), maxIndicatorY)
        let indicatorCircleOffset = indicatorY - CatalogLayout.shadowPadding
        let loz = CGRect(x: BrowseCatalogIndicator.indicatorX(attachViewWidth: attachView?.frame.width ?? self.hostWidth),
                         y: indicatorCircleOffset,
                         width: CatalogLayout.indicatorSize,
                         height: CatalogLayout.indicatorSize)
        catalogIndicator?.frame = loz
        if resetSide {
            catalogSideView?.resetIndex(contentOffsetY: contentOffsetY, indicatorOffsetY: indicatorY)
        }
    }

    private func removeAll(animated: Bool, alongsideAnimation: (() -> Void)? = nil) {
        removingBottomEntry = true
        func defaultRemoveSide() {
            self.catalogIndicator?.removeFromSuperview()
            self.catalogSideView?.removeFromSuperview()
            self.catalogIndicator = nil
            self.catalogSideView = nil
        }

        func defaultRemoveBottom() {
            if catalogBottomEntry != nil {
                reportBottomEntryModifyWebEmpty(show: false)
            }
            self.catalogBottomEntry?.removeFromSuperview()
            self.catalogBottomEntry = nil
            removingBottomEntry = false
            requestDisplayToolBarCatalogEntry(show: false)
            toolBar?.setToolbarInvisible(toHidden: false)
            self.showOrginalIndicator(true)
        }


        if let indicator = catalogIndicator {
            indicatorRemovedY = indicator.frame.minY
        }

        if !animated {
            defaultRemoveSide()
            defaultRemoveBottom()
            alongsideAnimation?()
        } else {
            let oldFrame: CGRect = catalogIndicator?.frame ?? CGRect(x: 0, y: 0, width: 0, height: 0)
            let newFrame = CGRect(x: attachView?.frame.width ?? self.hostWidth,
                                  y: oldFrame.minY,
                                  width: oldFrame.width,
                                  height: oldFrame.height)
            let bottomEntryHeight: CGFloat = self.catalogBottomEntry?.frame.height ?? 0

            UIView.animate(withDuration: animationDuration, animations: { [weak self] in
                self?.catalogIndicator?.frame = newFrame
                if self?.catalogSideView?.superview != nil {
                    self?.catalogSideView?.snp.updateConstraints({ (make) in
                        make.right.equalToSuperview().offset(CatalogLayout.sideWidth)
                    })
                    self?.catalogSideView?.alpha = 0.0
                }

                self?.catalogSideView?.layoutIfNeeded()
                //self?.attachView?.layoutIfNeeded()
                //self?.attachView?.superview?.layoutIfNeeded()
                }, completion: { _ in
                    defaultRemoveSide()
            })

            DispatchQueue.main.asyncAfter(deadline: .now() + animationBlanking) { [weak self] in
                let duration = self?.animationDuration ?? Const.duration
                UIView.animate(withDuration: duration, animations: { [weak self] in
                    if self?.catalogBottomEntry?.superview != nil {
                        self?.catalogBottomEntry?.snp.updateConstraints({ (make) in
                            make.bottom.equalToSuperview().offset(bottomEntryHeight)
                        })
                    }
                    alongsideAnimation?()
                    self?.catalogBottomEntry?.layoutIfNeeded()
                    //fix VCFollow小窗切换，刷新布局，会导致browserview的宽度变成132，
                    //导致前端渲染出现问题，先去掉这里的刷新browserview布局的逻辑
                    //self?.attachView?.layoutIfNeeded()
                    //self?.attachView?.superview?.layoutIfNeeded()
                    }, completion: { _ in
                        defaultRemoveBottom()
                })
            }
        }
    }

    /// 工具栏处显示目录入口
    ///
    /// - Parameter show: 是否展示
    private func requestDisplayToolBarCatalogEntry(show: Bool) {
        var shouldDisplay = show
        if shouldDisplay, CatalogLayout.keyboardHeight <= Const.keyboardHeight {
            shouldDisplay = false
        }
        if show {
            catalogEntryView.delegate = self
        }
        toolBar?.setCoverStickerView(shouldDisplay ? catalogEntryView : nil)
    }

    /// 告诉前端当前底部栏的高度
    ///
    /// - Parameter show: 是否展示底部栏
    private func reportBottomEntryModifyWebEmpty(show: Bool) {
        //阅读态的时候才需要处理
        guard CatalogLayout.keyboardHeight <= 0,
            let realProxy = proxy else { return }
        var height = realProxy.frame.height
        if show, let entry = catalogBottomEntry {
            height -= entry.frame.height
        }
        catalogDisplayObserver.onNext(show)
        delegate?.notifyDisplayBottomEntry(show: show, emptyHeight: height)
    }
}

extension CatalogManager: BrowseCatalogIndicatorDelegate {

    func indicatorDidClicked(indicator: BrowseCatalogIndicator) {
        killTimer()
        putSideAndBottomEntry()
        requestDisplayToolBarCatalogEntry(show: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + Const.asyncAfterTime) {
            // 有一定概率时机展开面板是约束还没完成，计算会有问题
            self.adjustIndicatorAndSidePoz()
            self.removeCatalogAccessoryWithDelay()
        }
    }

    func indicatorStartMoveVertical(indicator: BrowseCatalogIndicator) {
        killTimer()
    }

    /// 正在移动indicator/松手后不超过2s
    func indicatorDidMovedVertical(indicator: BrowseCatalogIndicator) {
        guard let realProxy = self.proxy else { return }
        killTimer()
        putSideAndBottomEntry()
        requestDisplayToolBarCatalogEntry(show: true)
        let contentSizeY = realProxy.contentSize.height
        let contentDefaultY = realProxy.frame.size.height
        let maxIndicatorY = indicatorMaxYOffset()
        let offsetRatio = (indicator.frame.minY + CatalogLayout.shadowPadding) / maxIndicatorY
        let scrollableHeight = contentSizeY - contentDefaultY
        let newOffsetY = scrollableHeight * offsetRatio
        let oldOffset = realProxy.contentOffset
        let newOffset = CGPoint(x: oldOffset.x, y: newOffsetY)
        realProxy.setContentOffset(newOffset, animated: false)
        let realIndicatorY = indicator.frame.minY + CatalogLayout.shadowPadding
        catalogSideView?.resetIndex(contentOffsetY: newOffsetY, indicatorOffsetY: realIndicatorY)
    }

    func indicatorEndMoveVertical(indicator: BrowseCatalogIndicator) {
        removeCatalogAccessoryWithDelay()
    }

    /// 能滚动的轨迹长度
    ///
    /// - Returns: 轨迹长度
    func indicatorMaxYOffset() -> CGFloat {
        guard let realProxy = self.proxy else { return 0 }
        let contentDefaultY = realProxy.frame.size.height
        var maxIndicatorY = contentDefaultY - CatalogLayout.indicatorRealSize - self.safeAreaInsets.bottom
        if let entry = catalogBottomEntry, !entry.isHidden, !removingBottomEntry {
            maxIndicatorY = contentDefaultY - CatalogLayout.indicatorRealSize - entry.frame.height
        }
        if CatalogLayout.keyboardHeight > Const.keyboardHeight {
            maxIndicatorY = contentDefaultY - CatalogLayout.indicatorRealSize - CatalogLayout.keyboardHeight
        }
        return maxIndicatorY
    }
}

extension CatalogManager: CatalogBottomEntryViewDelegate {
    func didRequestOpenCatalogDetails(_ view: CatalogBottomEntryView) {
        
        if let vc = navigator?.currentBrowserVC, vc.tryBecomeFirstResponderIfNeed() {
            //打开目录后，将焦点从webview转移到vc上，否则点击目录滚动位置，再关闭目录时，webview会自动获取焦点，滚动到旧的位置 https://meego.feishu.cn/larksuite/issue/detail/4627139
            DocsLogger.info("currentBrowserVC becomeFirstResponder", component: LogComponents.catalog)
        }
        
        openCatalogDetails(.navCatalog)
    }

    private func openCatalogDetails(_ from: CatalogOpenSource) {
        let items = catalogDatas ?? [CatalogItemDetail]()// 可以为nil，或者count == 0 ，产品说，及时没有，也要显示空白页，嗯，就是这样
        removeAll(animated: false, alongsideAnimation: { [weak self] in
            self?.toolBar?.setCoverStickerView(nil)
        })
        let fontZoomable = self.docsInfo?.fontZoomable ?? false
        let detailsVC = CatalogDetailsViewController(fontZoomable: fontZoomable, details: items, delegate: self, selected: selectingIndex())
        detailsVC.openFrom = from
        detailsVC.supportOrentations = supportOrentations
        detailsVC.modalPresentationStyle = .overFullScreen
        weakCatalogDetailsVC = detailsVC
        weakCatalogDetailsVC?.setCaptureAllowed(catalogViewAllowCapture)
        navigator?.presentViewController(detailsVC, animated: false, completion: nil)
        reportDisplayOutLineCatalog(from: from)
    }

    private func selectingIndex() -> Int {
        var index = 0
        let contentY = proxy?.contentOffset.y ?? 0
        var indicatorY = indicatorRemovedY + CatalogLayout.shadowPadding
        if let indicator = catalogIndicator {
            indicatorY = indicator.frame.minY + CatalogLayout.shadowPadding
        }
        if let data = catalogDatas {
            index = BrowserCatalogSideView.findIndex(datas: data,
                                                     scrollOffset: contentY,
                                                     indicatorOffset: indicatorY)
        }
        return index
    }

}

extension CatalogManager: CatalogDetailsViewControllerDelegate {
    func didClickItem(_ item: CatalogItemDetail, controller: CatalogDetailsViewController) {
        DocsLogger.info("CatalogDetail didClicked item itemId: \(item.identifier.encryptToShort), title: \(item.title)", component: LogComponents.catalog)
        jumpToRightPlace(item: item)
        reportClickOutLineCatalog(from: controller.openFrom)
    }

    func didClickImage(_ item: CatalogItemDetail, controller: CatalogDetailsViewController) {
        let params: [String: Any] = ["hash": item.identifier, "status": item.collapse]
        jsEngine?.callFunction(DocsJSCallBack.catalogSwitchHeading, params: params, completion: { (_, error) in
            guard error == nil else {
                DocsLogger.error(String(describing: error))
                return
            }
        })
    }
    
    func didAppear(height: CGFloat, controller: CatalogDetailsViewController) {
        guard let detailsVC = weakCatalogDetailsVC,
                let container = navigator?.currentBrowserVC as? DocsContainerType else { return }
        let visiableHeight = container.webviewHeight - height
        let info = SimulateKeyboardInfo(height: visiableHeight, isShow: true, trigger: DocsKeyboardTrigger.catalog.rawValue)
        let params: [String: Any] = [SimulateKeyboardInfo.key: info]
        self.jsEngine?.simulateJSMessage(DocsJSService.simulateKeyboardChange.rawValue, params: params)
    }
    
    func disAppear(controller: CatalogDetailsViewController) {
        let info = SimulateKeyboardInfo(height: 0, isShow: false, trigger: DocsKeyboardTrigger.catalog.rawValue)
        let params: [String: Any] = [SimulateKeyboardInfo.key: info]
        self.jsEngine?.simulateJSMessage(DocsJSService.simulateKeyboardChange.rawValue, params: params)
    }
}

extension CatalogManager: BrowserCatalogSideViewDelegate {
    func didClicked(_ item: CatalogItemDetail, atIndex: Int, sideView: BrowserCatalogSideView) {
        DocsLogger.info("SideCatalog didClicked item itemId: \(item.identifier.encryptToShort), title: \(item.title)", component: LogComponents.catalog)
        jumpToRightPlace(item: item)
        reportClickNavCatalog()
    }

    func didReceivePan(gesture: UIPanGestureRecognizer) {
        catalogIndicator?.didReceivePanGesture(gesture: gesture)
    }
}

extension CatalogManager {
    private func jumpToRightPlace(item: CatalogItemDetail) {
        self.doingSideCatalogItemAnimation = true
        removeSideAndBottom(animated: true, alongsideAnimation: { [weak self] in
            self?.toolBar?.setCoverStickerView(nil)
        }, completed: {
            self.doingSideCatalogItemAnimation = false
            self.adjustIndicatorAndSidePoz(resetSide: false)
        })
        removeCatalogAccessoryWithDelay()
        jsJumpOffset(itemId: item.identifier)
        DispatchQueue.main.asyncAfter(deadline: .now() + Const.asyncAfterJump) {
            self.adjustIndicatorAndSidePoz(resetSide: false)
        }
    }

    private func jsJumpOffset(itemId: String) {
        DocsLogger.info("jsJumpOffset itemId: \(itemId.encryptToShort)", component: LogComponents.catalog)
        jsEngine?.callFunction(DocsJSCallBack.navigationJump, params: ["hash": itemId.docs.escapeSingleQuote()], completion: { (_, error) in
            guard error == nil else {
                DocsLogger.error("jsJumpOffset itemId: \(itemId.encryptToShort) error: \(error?.localizedDescription ?? "")", component: LogComponents.catalog)
                DocsLogger.error(String(describing: error))
                return
            }
        })
    }

    /*
    private func nativeJumpOffset(item: CatalogItemDetail) {
        removeAll(animated: false, alongsideAnimation: { [weak self] in
            self?.toolBar?.setCoverStickerView(nil)
        })
        let oldOffset = proxy?.contentOffset ?? CGPoint.zero
        let newYOffset = item.yOffset
        proxy?.setContentOffset(CGPoint(x: oldOffset.x, y: newYOffset), animated: true)
    }*/
}

extension CatalogManager {
    private func reportDisplayOutLineCatalog(from: CatalogOpenSource) {
        var baseParams = commonReportParams()
        baseParams?["source"] = from == .more ? "more" : "nav_catalog"
        if let params = baseParams {
            DocsTracker.log(enumEvent: .showOutLineCatalog, parameters: params)
        }
    }

    private func reportClickOutLineCatalog(from: CatalogOpenSource) {
        var baseParams = commonReportParams()
        baseParams?["source"] = from == .more ? "more" : "nav_catalog"
        if let params = baseParams {
            DocsTracker.log(enumEvent: .clickOutLineCatalogItem, parameters: params)
        }
    }

    private func reportDisplayNavCatalog() {
        if let params = commonReportParams() {
            DocsTracker.log(enumEvent: .showNavCatalog, parameters: params)
        }
    }

    private func reportClickNavCatalog() {
        if let params = commonReportParams() {
            DocsTracker.log(enumEvent: .clickNavCatalogItem, parameters: params)
        }
    }

    private func commonReportParams() -> [String: Any]? {
        guard let info = docsInfo else { return nil }
        var params: [String: Any] = [String: Any]()
        params["file_id"] = DocsTracker.encrypt(id: info.objToken)
        params["file_type"] = info.type.name
        params["is_owner"] = (info.ownerID == User.current.info?.userID) ? "true" : "false"
        return params
    }
}

// MARK: - indicator显示控制
extension CatalogManager {
    func showIndicator(show: Bool) {
        catalogIndicator?.isHidden = !show
    }
}

extension CatalogManager: DocsPermissionEventObserver {
    
    func onCopyPermissionUpdated(canCopy: Bool) {
        catalogViewAllowCapture = canCopy
        DocsLogger.info("iPadCatalogSideView:\(String(describing: iPadCatalogSideView)) setCaptureAllowed => \(canCopy)")
        iPadCatalogSideView?.setCaptureAllowed(canCopy)
        catalogSideView?.setCaptureAllowed(canCopy)
        weakCatalogDetailsVC?.setCaptureAllowed(canCopy)
    }
}
