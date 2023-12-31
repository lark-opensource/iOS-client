//
//  LKCanvasViewController.swift
//  LarkCanvas
//
//  Created by Saafo on 2021/2/5.
//

import Foundation
import Homeric
import LarkFoundation
import LarkKeyCommandKit
import LarkSensitivityControl
import LarkUIKit
import LKCommonsLogging
import LKCommonsTracker
import RoundedHUD
import RxSwift
import UIKit
import UniverseDesignActionPanel
import UniverseDesignColor
import UniverseDesignDialog

@available(iOS 13.0, *)
public final class LKCanvasViewController: UIViewController, LKCanvasViewDelegate, CanvasControllerViewDelegate {

    // MARK: Enums

    /// LKCanvasViewController initialize option
    public enum Option {
        /// Title of the ViewController
        case set(title: String)
        /// Customize finish button title, default will be `Lark_Legacy_Completed`
        case setFinishButton(title: String)
        /// Whether show clear canvas navigation button, default will be `true`
        case clearNaviButton(shouldShow: Bool)
        /// Whether show save to album navigation button, default will be `true`
        case saveNaviButton(shouldShow: Bool)
        /// When saving image, export whole canvas or minimum content of drawing, default will be `true`
        case saveMinimumImage(minimum: Bool)
        /// Saving strategy, will effect both close and finish, default will be `saveOnNotEmpty`
        case saveOn(mode: SaveMode)
        /// the provider which provides local cache functionality for canvas,
        /// default will be `LKCanvasConfig.cacheProvider`
        case cache(provider: LKCanvasCacheProvider?)
    }

    /// Saving strategy, will effect both close and finish
    public enum SaveMode {
        /// Once the canvas is not empty, asking to save or delete the draft
        case saveOnNotEmpty
        /// Once the drawing is changed, asking to save or delete the draft
        case saveOnChanged
    }

    // MARK: Components

    /// canvas view
    public var canvas = LKCanvasView()

    /// save or load the canvas data from or to the identifer
    public let cacheId: String

    /// Delegate
    public weak var delegate: LKCanvasViewControllerDelegate?

    // MARK: Configurations
    private var finishButtonTitle: String = BundleI18n.LarkCanvas.Lark_Legacy_Completed
    private var showClearNaviButton: Bool = true
    private var showSaveNaviButton: Bool = true
    private var saveMinimumImage: Bool = true
    private var saveMode: SaveMode = .saveOnNotEmpty
    private var cacheProvider: LKCanvasCacheProvider? = LKCanvasConfig.cacheProvider

    // MARK: Private Attributes

    /// data of canvas
    /// - Note: is only used to record the initializing data, won't update to the newer data afterwards
    private var _data: Data?

    private var _lastTimeFullContentScale: CGFloat?

    private var _lastTimeViewSize: CGSize?

    private var _newTraitCollection: UITraitCollection?

    private var shouldSaveToCacheOnDisappear: Bool = true

    private let biz: String?

    private var isLoadFromCache: Bool = false

    private let drawingChanged = PublishSubject<Void>()

    private let disposeBag = DisposeBag()

//    private let serializationQueue = DispatchQueue(label: "LKCanvasSerializationQueue", qos: .background)

    static let logger = Logger.log(LKCanvasViewController.self, category: "Module.LarkCanvas.ViewController")

    // MARK: Navi buttons

    /// undo button
    private var undoBarButton = LKBarButtonItem()

    /// redo button
    private var redoBarButton = LKBarButtonItem()

    /// close vc button
    private var closeButton = LKBarButtonItem()

    /// clear canvas button
    private var clearButton = LKBarButtonItem()

    /// save to album button
    private var saveToAlbumButton = LKBarButtonItem()

    /// finish button
    private var finishButton = LKBarButtonItem()

    private var undoRedoBtns: [LKBarButtonItem] = []

    private var generalBtns: [LKBarButtonItem] = []

    /// Init a PencilKit canvas, with tools and navi bar management built-in
    /// - Parameters:
    ///   - identifier:         save or load the canvas data from or to the identifier
    ///   - data:               load the canvas with the data
    ///   - biz:                used for `is_from` info of Homeric
    ///   - options:            Options of LKCanvasViewController
    ///   - delegate:           delegate object for `LKCanvasViewController`
    /// - Note: if is provided with data, `LKCanvasViewController` will load the canvas with the data,
    ///         and save data with the identifier if users wish to stash the canvas
    public init(
        identifier: String,
        data: Data? = nil,
        from biz: String?,
        options: [LKCanvasViewController.Option] = [],
        delegate: LKCanvasViewControllerDelegate? = nil
    ) {
        self.cacheId = identifier
        self.biz = biz
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
        self._data = data
        // Configurations
        options.forEach { option in
            switch option {
            case .set(title: let title):
                self.title = title
            case .setFinishButton(title: let title):
                self.finishButtonTitle = title
            case .clearNaviButton(shouldShow: let show):
                self.showClearNaviButton = show
            case .saveNaviButton(shouldShow: let show):
                self.showSaveNaviButton = show
            case .saveMinimumImage(minimum: let minimum):
                self.saveMinimumImage = minimum
            case .saveOn(mode: let mode):
                self.saveMode = mode
            case .cache(provider: let provider):
                self.cacheProvider = provider
            }
        }
        // PM requires allowing finger drawing in iOS 13 by default
        if #available(iOS 14.0, *) {} else {
            canvas.canvasView.allowsFingerDrawing = true
        }
    }

    // MARK: Interfaces

    /// Set the data including drawings in canvas
    /// - Parameter data: should be able to decode to LKCanvasDataModel.
    public func setData(data: Data) {
        let succeeded = canvas.load(from: data, fullyRestore: true)
        if succeeded {
            _data = data
            updateLayout(viewSize: view.bounds.size,
                         traitCollection: _newTraitCollection ?? view.traitCollection)
        }
        delegate?.canvasDidEnter(
            lifeCycle: .canvasDidLoadData(canvas: canvas, succeeded: succeeded)
        )
    }

    /// Update the data including drawings from cacheProvider load(for:) method
    public func updateData() {
        var succeeded = false
        if let data = cacheProvider?.loadCache(identifier: cacheId) {
            succeeded = canvas.load(from: data)
        }
        delegate?.canvasDidEnter(
            lifeCycle: .canvasDidLoadData(canvas: canvas, succeeded: succeeded)
        )
    }

    /// Export data of canvas
    /// - Returns: data of canvas encoded from LKCanvasDataModel, nil when canvas is empty
    public func getData() -> Data? {
        return canvas.export()
    }

    /// Export an image contains the drawing
    /// - Returns: Returns an image object that contains the the drawing, nil when canvas is empty
    public func getImage() -> UIImage? {
        // PM require to always export lightmode image temporarily
        return canvas.exportAsImage(minimum: saveMinimumImage, style: .light)
    }

    // MARK: View Life Cycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.N00

        canvas.delegate = self
        view.addSubview(canvas)
        canvas.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        // Navigation Bar Items
        // must call after add canvas to view because
        // the grey `naviLine` of navibar should on the top of canvas
        setupNaviItems()
    }

    /// The reason why using `viewWillLayoutSubviews` instead of `viewWillTransition`
    /// is that in the situation of presenting this VC from a formSheet-styled VC, the `size` parameter
    /// will be overridden by the formSheet-styled VC (seems like an Apple bug), causing this VC
    /// updating to a wrong layout.
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if _lastTimeViewSize == nil || _lastTimeViewSize! != view.bounds.size {
            if let traitCollection = view.window?.traitCollection {
                _lastTimeViewSize = view.bounds.size
                updateLayout(viewSize: view.bounds.size, traitCollection: self._newTraitCollection ?? traitCollection)
            } else {
                Self.logger.error("cannot get traitCollection in LKCanvasViewController.")
            }
        }
    }

    public override func willTransition(
        to newCollection: UITraitCollection,
        with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        self._newTraitCollection = newCollection
    }

    public override func loadView() {
        let view = CanvasControllerView()
        view.delegate = self
        self.view = view
    }

    fileprivate func viewWillMove(toWindow newWindow: UIWindow?) {
        if let window = newWindow {
            let toolPickerHeight =
                Display.phone ? canvas.getToolPickerObscuredHeight(for: window.traitCollection) : 0
            canvas.setLayout(
                window: window,
                contentSize: CGSize(
                    width: window.screen.bounds.width,
                    height: window.screen.bounds.height -
                        // PM required that the default canvas size
                        // should cut off the height of navigation bar
                        view.frame.minY -
                        // On iPhone, the toolPicker height should also be cut off
                        toolPickerHeight
                )
            )
            Self.logger.info("""
                    canvasView contentSize is \( canvas.canvasView.contentSize),
                    and bounds is \(canvas.canvasView.bounds)
                    when viewWillMove to \(window)
                    """)
            if self._data == nil {
                self._data = cacheProvider?.loadCache(identifier: cacheId)
                isLoadFromCache = self._data != nil
            }
            if let data = self._data {
                let succeeded = canvas.load(from: data)
                delegate?.canvasDidEnter(
                    lifeCycle: .canvasDidLoadData(canvas: canvas, succeeded: succeeded)
                )
                Self.logger.info("""
                    canvasView contentSize is \( canvas.canvasView.contentSize),
                    and bounds is \(canvas.canvasView.bounds)
                    when data is loaded
                    """)
            }
            if cacheProvider != nil {
                turnAutoSaveOn()
            }
            delegate?.canvasDidEnter(lifeCycle: .viewDidLayout)
        } // when the view disappear, willMove(to nil) will be called
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        delegate?.canvasDidEnter(lifeCycle: .viewDidAppear)
    }

    /// Dismiss this ViewController
    /// - Parameter dismiss: whether should dismiss this ViewController
    private func shouldDismiss(_ dismiss: Bool) {
        if dismiss {
            shouldSaveToCacheOnDisappear = false
            saveToCacheIfNeeded() // update cache state before dismissing
            self.dismiss(animated: true)
        } else {
            shouldSaveToCacheOnDisappear = true
            canvas.canvasView.becomeFirstResponder()
        }
    }

    // MARK: Update layout

    /// update layout of VC
    /// - Parameters:
    ///   - viewSize:        size of canvas view
    ///   - traitCollection: traitCollection of the window, used to caculate tool picker dock height
    func updateLayout(viewSize: CGSize, traitCollection: UITraitCollection) {

        // calculate tool picker height
        let toolPickerObscuredFrameHeight = canvas.getToolPickerObscuredHeight(for: traitCollection)

        // Set suitable content scale for canvas view
        var scale: CGFloat = 0
        // cut off the height of navigation bar
        let visiableHeight = viewSize.height - toolPickerObscuredFrameHeight
        let fullHeightScale = visiableHeight / (canvas.canvasView.contentSize.height / canvas.canvasView.zoomScale)
        // Note: contentsize includes scale factor, and bounds is just visiable area
        let fullWidthScale = viewSize.width / (canvas.canvasView.contentSize.width / canvas.canvasView.zoomScale)
        let fullContentScale = min(fullWidthScale, fullHeightScale)

        if canvas.canvasCanScale {
            canvas.canvasView.minimumZoomScale = fullContentScale
            canvas.canvasView.maximumZoomScale = fullContentScale * 4
            canvas.canvasView.bouncesZoom = true
            if let lastTimeFullContentScale = _lastTimeFullContentScale {
                if lastTimeFullContentScale == canvas.canvasView.zoomScale {
                    scale = fullContentScale
                } else {
                    scale = min(max(fullContentScale, canvas.canvasView.zoomScale), fullContentScale * 4)
                }
            } else {
                scale = fullContentScale
            }
            _lastTimeFullContentScale = fullContentScale
        } else {
            canvas.canvasView.minimumZoomScale = fullContentScale
            canvas.canvasView.maximumZoomScale = fullContentScale
            scale = fullContentScale
        }
        Self.logger.info("canva safeAreaInsets is: \(canvas.safeAreaInsets.bottom)")
        canvas.canvasView.setZoomScale(scale, animated: false)
        Self.logger.info("canvasView scale set to: \(canvas.canvasView.zoomScale)")
        Self.logger.info("""
                canvasView contentSize is \( canvas.canvasView.contentSize),
                and bounds is \(canvas.canvasView.bounds)
                when layout updated
                """)
        // Set canvas inset
        adjustCanvasInsets(traitCollection: traitCollection, viewSize: viewSize)
    }

    /// Help method to adjust insets of canvas
    /// - Parameters:
    ///   - traitCollection: traitCollection of the window, used to caculate tool picker dock height
    ///   - viewSize:        size of canvas view, if set to .zero, this method will get current frame size of canvasView
    public func adjustCanvasInsets(traitCollection: UITraitCollection, viewSize: CGSize) {
        let size = viewSize == .zero ? canvas.canvasView.frame.size : viewSize
        let toolPickerObscuredHeight = canvas.getToolPickerObscuredHeight(for: traitCollection)
        // make the canvas anchor to the center
        let leftMargin = (size.width - canvas.canvasView.contentSize.width) / 2
        let topMargin = (size.height -
                            canvas.canvasView.contentSize.height -
                            toolPickerObscuredHeight) / 2
        canvas.canvasView.contentInset.top = max(topMargin, 0)
        canvas.canvasView.contentInset.left = max(leftMargin, 0)
        /// Note that the tool picker floats over the canvas in regular size classes, but docks to
        /// the canvas in compact size classes, occupying a part of the screen that the canvas
        /// could otherwise use.
        if toolPickerObscuredHeight != 0 {
            undoRedoBtns(shouldShow: true)
            canvas.canvasView.contentInset.bottom =
                toolPickerObscuredHeight - canvas.safeAreaInsets.bottom
        } else {
            undoRedoBtns(shouldShow: false)
            canvas.canvasView.contentInset.bottom = .zero
        }
        canvas.canvasView.scrollIndicatorInsets = canvas.canvasView.contentInset

        canvas.backgroundView.frame.size = canvas.canvasView.contentSize
    }

    /// Apple said: Hide the home indicator, as it will affect latency.
    public override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    // MARK: Auto save

    /// Auto save on every 2 seconds when drawing changed
    func turnAutoSaveOn() {
        drawingChanged.skip(1)
            .throttle(.seconds(4), latest: true, scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.saveToCacheIfNeeded()
            }).disposed(by: disposeBag)
    }

    func saveToCacheIfNeeded() {
        if self.shouldSaveToCacheOnDisappear, let data = getData() {
            // save
//            serializationQueue.async { [self] in // TODO: multi-thread saving, will add in near future
            _ = self.cacheProvider?.saveCache(identifier: cacheId, data: data)
//            }
        } else {
            // clear
//            serializationQueue.async { [self] in
            _ = self.cacheProvider?.saveCache(identifier: cacheId, data: nil)
//            }
        }
    }

    // MARK: Imp of delegate

    public func canvasViewDidFinishRenderingCallback() {
        // update item state on appear or on clear all
        updateNaviItemState()
        drawingChanged.onNext(())
    }

    public func canvasViewDrawingDidChangeCallback() {
        // update item state on every stroke
        updateNaviItemState()
        drawingChanged.onNext(())
    }

    // MARK: Navi item

    private func setupNaviItems() {
        closeButton = naviButtonFactory(
            image: Resources.iconClose, color: UIColor.ud.iconN1, action: #selector(close)
        )
        navigationItem.setLeftBarButton(closeButton, animated: false)
        finishButton = naviButtonFactory(
            title: self.finishButtonTitle,
            color: UIColor.ud.primaryContentDefault,
            action: #selector(finish),
            disabledTitleColor: UIColor.ud.textDisable
        )
        saveToAlbumButton = naviButtonFactory(
            image: Resources.iconSave,
            color: UIColor.ud.iconN1,
            action: #selector(saveToAlbum),
            disabledImageColor: UIColor.ud.iconDisable
        )
        clearButton = naviButtonFactory(
            image: Resources.iconClear,
            color: UIColor.ud.iconN1,
            action: #selector(clear),
            disabledImageColor: UIColor.ud.iconDisable
        )
        undoBarButton = naviButtonFactory(
            image: Resources.iconUndo,
            color: UIColor.ud.iconN1,
            action: #selector(canvasUndo),
            disabledImageColor: UIColor.ud.iconDisable
        )

        redoBarButton = naviButtonFactory(
            image: Resources.iconRedo,
            color: UIColor.ud.iconN1,
            action: #selector(canvasRedo),
            disabledImageColor: UIColor.ud.iconDisable
        )
        // compose general buttons
        generalBtns = [finishButton]
        if showSaveNaviButton { generalBtns.append(saveToAlbumButton) }
        if showClearNaviButton { generalBtns.append(clearButton) }
        undoRedoBtns = [redoBarButton, undoBarButton]
        navigationItem.setRightBarButtonItems(generalBtns, animated: false)
        // add grey line of navi bar
        let naviLine = UIView()
        naviLine.backgroundColor = UIColor.ud.lineDividerDefault
        view.addSubview(naviLine)
        naviLine.snp.makeConstraints {
            $0.height.equalTo(1)
            $0.width.top.equalToSuperview()
        }
    }

    /// function to show or hide(remove) undo and redo buttons on navigation bar
    /// - Parameter shouldShow: whether show undo and redo buttons
    ///
    /// Apple declare toolPicker would have undo and redo buttons in compact view,
    /// however, in landscape view on iPhone, the width is compact, but the toolPicker won't show undo and redo buttons
    ///
    /// When this delegate method get called, `shouldShow` will be true
    /// only if the toolPicker isn't floating(i.e. the toolPicker won't have undo and redo buttons)
    public func undoRedoBtns(shouldShow: Bool) {
        if shouldShow {
            navigationItem.setRightBarButtonItems(generalBtns + undoRedoBtns, animated: false)
        } else {
            navigationItem.setRightBarButtonItems(generalBtns, animated: false)
        }
    }

    /// update navi item enabled state
    public func updateNaviItemState() {
        DispatchQueue.main.async { [weak self] in
            self?.undoBarButton.isEnabled = self?.canvas.undoManager?.canUndo ?? true
            self?.redoBarButton.isEnabled = self?.canvas.undoManager?.canRedo ?? true
            let canvasIsNotEmpty = self?.canvas.canvasIsNotEmpty ?? true
            self?.clearButton.isEnabled = canvasIsNotEmpty
            self?.saveToAlbumButton.isEnabled = canvasIsNotEmpty
            self?.finishButton.isEnabled = {
                guard let `self` = self else { return true }
                switch self.saveMode {
                case .saveOnNotEmpty:
                    return canvasIsNotEmpty
                case .saveOnChanged:
                    return ((self.canvas.undoManager?.canUndo ?? true) || self.isLoadFromCache) && canvasIsNotEmpty
                }
            }()
        }
    }

    // MARK: Navi Item Actions

    @objc
    func close() {
        post(teaEvent: Homeric.PUBLIC_WHITEBOARD_CLOSE_CLICK, from: biz)
        let shouldShowAlertPanel: Bool
        let actionPanelTitle: String
        let actionPanelSaveText: String
        let actionPanelCancelText: String
        switch saveMode {
        case .saveOnNotEmpty:
            shouldShowAlertPanel = canvas.canvasIsNotEmpty
            actionPanelTitle = BundleI18n.LarkCanvas.Lark_Core_SaveDraft
            actionPanelSaveText = BundleI18n.LarkCanvas.Lark_Core_Save
            actionPanelCancelText = BundleI18n.LarkCanvas.Lark_Core_Discard
        case .saveOnChanged:
            shouldShowAlertPanel = (canvas.undoManager?.canUndo ?? true) && canvas.canvasIsNotEmpty
            actionPanelTitle = BundleI18n.LarkCanvas.Lark_Docs_iPadWhiteboard_SaveOrNot_Toast
            actionPanelSaveText = BundleI18n.LarkCanvas.Lark_Docs_iPadWhiteboard_SaveChanges_Options
            actionPanelCancelText = BundleI18n.LarkCanvas.Lark_Docs_iPadWhiteboard_CancelChanges_Options
        }
        guard shouldShowAlertPanel else {
            saveToCacheIfNeeded() // update cache state before calling canvasDidClose
            self.dismiss(animated: true)
            Self.logger.info("Canvas closed with empty data")
            self.delegate?.canvasDidEnter(lifeCycle: .viewDidDisappear)
            return
        }
        guard let closeBtnView = closeButton.customView else {
            Self.logger.error("Cannot find close button on canvas close")
            saveToCacheIfNeeded() // update cache state before calling canvasDidClose
            self.dismiss(animated: true)
            self.delegate?.canvasDidEnter(lifeCycle: .viewDidDisappear)
            return
        }
        let actionSheet = UDActionSheet(
            config: UDActionSheetUIConfig(
                isShowTitle: true,
                popSource: UDActionSheetSource(
                    sourceView: closeBtnView, sourceRect: closeBtnView.bounds,
                    preferredContentWidth: 280, arrowDirection: .up
                )
            )
        )
        actionSheet.setTitle(actionPanelTitle)
        actionSheet.addDefaultItem(text: actionPanelSaveText) { [weak self] in
            post(teaEvent: Homeric.PUBLIC_WHITEBOARD_SAVE_CLICK, from: self?.biz)
            guard let `self` = self else { return }
            switch self.saveMode {
            case .saveOnNotEmpty:
                self.shouldSaveToCacheOnDisappear = true
                self.saveToCacheIfNeeded() // update cache state before calling canvasDidClose
                self.dismiss(animated: true)
                self.delegate?.canvasDidEnter(lifeCycle: .viewDidDisappear)
            case .saveOnChanged:
                self.finish()
            }
        }
        actionSheet.addDestructiveItem(text: actionPanelCancelText) { [weak self] in
            post(teaEvent: Homeric.PUBLIC_WHITEBOARD_DELETE_CLICK, from: self?.biz)
            guard let `self` = self else { return }
            if self.saveMode == .saveOnChanged && self.isLoadFromCache {
                // When saving on changed, tap `cancel` is expected to save the version of data on opening
                _ = self.cacheProvider?.saveCache(identifier: self.cacheId, data: self._data)
            } else {
                self.shouldSaveToCacheOnDisappear = false
                self.saveToCacheIfNeeded() // update cache state before calling canvasDidClose
            }
            self.dismiss(animated: true)
            self.delegate?.canvasDidEnter(lifeCycle: .viewDidDisappear)
        }
        actionSheet.setCancelItem(text: BundleI18n.LarkCanvas.Lark_Legacy_Cancel) { [weak self] in
            self?.canvas.canvasView.becomeFirstResponder()
        }
        canvas.canvasView.resignFirstResponder()
        self.present(actionSheet, animated: true)

    }

    @objc
    private func saveToAlbum() {
        post(teaEvent: Homeric.PUBLIC_WHITEBOARD_DOWNLOAD_CLICK, from: biz)
        guard let image = self.getImage() else {
            Self.logger.error("saveToAlbum() shouldn't be called when canvas is empty")
            return
        }
        do {
            try Utils.savePhoto(
                token: Token("LARK-PSDA-canvas_save_photo"), image: image
            ) { [weak self] (succeeded, granted) in
                self?.delegate?.canvasDidEnter(
                    lifeCycle: .savedToAlbum(succeeded: succeeded && granted)
                )
                DispatchQueue.main.async {
                    guard granted else {
                        Self.logger.error("Cannot save photo because of the privacy permission")
                        self?.photoDenied()
                        return
                    }
                    self?.showSaveImageTip(succeeded)
                }
            }
        } catch {
            Self.logger.error("Cannot save photo because of the privacy permission: \(error)")
            self.photoDenied()
            return
        }
    }
    @objc
    private func clear() {
        guard let clearBtnView = clearButton.customView else {
            Self.logger.error("Cannot find clear button on clear canvas")
            canvas.clear()
            return
        }
        let actionSheet = UDActionSheet(
            config: UDActionSheetUIConfig(
                isShowTitle: true,
                popSource: UDActionSheetSource(
                    sourceView: clearBtnView,
                    sourceRect: clearBtnView.bounds,
                    preferredContentWidth: 280,
                    arrowDirection: .up
                )
            )
        )
        actionSheet.setTitle(BundleI18n.LarkCanvas.Lark_Core_DeleteDraft)
        actionSheet.addDestructiveItem(text: BundleI18n.LarkCanvas.Lark_Core_Delete) { [weak self] in
            post(teaEvent: Homeric.PUBLIC_WHITEBOARD_CLEAR_CLICK, from: self?.biz)
            self?.canvas.clear()
            self?.saveToCacheIfNeeded() // clear cache
            self?.canvas.canvasView.becomeFirstResponder()
        }
        actionSheet.setCancelItem(text: BundleI18n.LarkCanvas.Lark_Legacy_Cancel) { [weak self] in
            self?.canvas.canvasView.becomeFirstResponder()
        }
        canvas.canvasView.resignFirstResponder()
        self.present(actionSheet, animated: true)
    }
    @objc
    private func finish() {
        post(teaEvent: Homeric.PUBLIC_WHITEBOARD_COMPLETE_CLICK, from: biz)
        guard let image = self.getImage(), let data = self.getData() else {
            Self.logger.error("finish() shouldn't be called when canvas is empty")
            return
        }
        canvas.canvasView.resignFirstResponder()
        delegate?.canvasWillFinish(in: self, drawingImage: image, canvasData: data,
                                   canvasShouldDismissCallback: { [weak self] dismiss in
                                    self?.shouldDismiss(dismiss)
                                   })
    }

    /// Undo
    @objc
    public func canvasUndo() {
        canvas.undoManager?.undo()
    }

    /// redo
    @objc
    public func canvasRedo() {
        canvas.undoManager?.redo()
    }

    public override func handleModalDismissKeyCommand() {
        self.close()
    }

    // MARK: LKCanvasViewDelegate
    public func canvasViewDidEnter(lifeCycle: LKCanvasView.LifeCycle) {
        switch lifeCycle {
        case .viewDidTouch(canvas: let canvasView, touch: let touch, isFirstTouch: let first):
            delegate?.canvasDidEnter(
                lifeCycle: .canvasDidTouch(canvas: canvasView, touch: touch, isFirstTouch: first)
            )
            if first {
                post(teaEvent: Homeric.PUBLIC_WHITEBOARD_DRAW,
                     from: biz,
                     params: ["is_pencil": touch.type == .pencil ? "true" : "false"] as [String: Any])
                Self.logger.info("is pencil on first touch: \(touch.type == .pencil)")
            }
        }
    }

    // MARK: - Private

    private func naviButtonFactory(
        image: UIImage? = nil,
        title: String? = nil,
        color: UIColor,
        action: Selector,
        disabledImageColor: UIColor? = nil,
        disabledTitleColor: UIColor? = nil
    ) -> LKBarButtonItem {
        let item = LKBarButtonItem(image: image?.ud.withTintColor(color, renderingMode: .alwaysOriginal), title: title)
        // UX required the actual distance between two button is 24, minus the default spacing 8 is 16.
        item.button.frame = CGRect(x: 0, y: 0, width: item.button.frame.width + 16, height: item.button.frame.height)
        item.button.contentHorizontalAlignment = .center
        item.button.snp.remakeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(item.button.frame.width)
            $0.height.equalTo(item.button.frame.height)
        }
        item.button.addTarget(self, action: action, for: .touchUpInside)
        item.button.setTitleColor(color, for: .normal)
        if let disabledImageColor = disabledImageColor {
            item.button.setImage(image?.ud.withTintColor(disabledImageColor), for: .disabled)
        }
        item.button.setTitleColor(disabledTitleColor, for: .disabled)
        return item
    }

    private func photoDenied() {
        let dialog = UDDialog.noPermissionDialog(title: BundleI18n.LarkCanvas.Lark_Core_PhotoAccessForSavePhoto,
                                                 detail: BundleI18n.LarkCanvas.Lark_Core_PhotoAccessForSavePhoto_Desc())
        self.present(dialog, animated: true, completion: nil)
    }

    private func showSaveImageTip(_ succeeded: Bool) {
        guard let window = self.view.window else {
            Self.logger.error("Cannot find window before showing HUD")
            return
        }
        if succeeded {
            RoundedHUD.showSuccess(
                with: BundleI18n.LarkCanvas.Lark_Legacy_QrCodeSaveToAlbum,
                on: window
            )
        } else {
            RoundedHUD.showFailure(
                with: BundleI18n.LarkCanvas.Lark_Legacy_PhotoZoomingSaveImageFail,
                on: window
            )
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Help Protocol for detecting new window
private protocol CanvasControllerViewDelegate: AnyObject {

    func viewWillMove(toWindow newWindow: UIWindow?)
}

/// Help View for detecting new window
@available(iOS 13.0, *)
private final class CanvasControllerView: UIView {
    weak var delegate: LKCanvasViewController?
    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        delegate?.viewWillMove(toWindow: newWindow)
    }
}

/// Homeric helper method
private func post(teaEvent: String, from biz: String?, params: [String: Any] = [:]) {
    var params = params
    if let biz = biz {
        params["is_from"] = biz
    }
    Tracker.post(TeaEvent(teaEvent, params: params))
}
