//
//  ImageEditorViewController.swift
//  LarkImageEditor
//
//  Created by 王元洵 on 2021/7/4.
//

import Foundation
import UIKit
import RxSwift
import SnapKit
import LarkUIKit
import TTVideoEditor

// swiftlint:disable file_length
final class ImageEditorViewController: BaseUIViewController, UIViewControllerTransitioningDelegate, UIScrollViewDelegate,
                                 UIGestureRecognizerDelegate {
    weak var delegate: ImageEditViewControllerDelegate?

    // event
    private let editEventSubject = PublishSubject<ImageEditEvent>()
    var editEventObservable: Observable<ImageEditEvent> { editEventSubject.asObservable() }

    // timer
    private var displayLink: CADisplayLink?

    // variables and constant
    private let originalImage: UIImage
    private let bottomFunctionPanelHeight = 92
    private var isBottomToolBarHidden = false
    private(set) var currentImageScale = CGFloat(1)
    private(set) var currentImageInitialScale = CGFloat(1)
    private var shoudAdjustVEFrame = false
    private var shouldRender = false
    private var hasEnterDeleteButtonFrame = false

    private var currentEditType = CurrentEditType.none {
        didSet {
            switch currentEditType {
            case .none, .text:
                imageEditor.preview.subviews
                    .forEach { ($0 as? TextStickerBoarderView)?.isUserInteractionEnabled = true }
            case .draw, .mosaic, .tag:
                imageEditor.preview.subviews
                    .forEach { ($0 as? TextStickerBoarderView)?.isUserInteractionEnabled = false }
            }

            if (oldValue.isNone && !currentEditType.isNone) || (!oldValue.isNone && currentEditType.isNone) {
                setNeedsUpdateOfScreenEdgesDeferringSystemGestures()
            }
        }
    }

    // UI
    private let imageEditor = VEImage(newLooper: true)
    private let closeButton = UIButton()
    private let bottomFunctionPanel = ImageEditFunctionPanel()
    private let scrollView = UIScrollView()
    private let lineFunctionView = LineFunctionView()
    private let tagFunctionView = TagFunctionView()
    private let mosaicFunctionView = MosaicFunctionView()
    private let revertButton = UIButton(type: .custom)
    private let backButton = UIButton(type: .custom)
    private let stickerDeleteButton = UIButton(type: .custom)
    private let topGradientLayer = CAGradientLayer()
    private let bottomGradientLayer = CAGradientLayer()
    private let widthIndicateCircle = UIView()
    private let allToolBars: [EditorToolBar]

    // operators
    private let brushOperator: ImageEditorBrushOperator
    private let stickerOperator: ImageEditorTextStickerOperator
    private let tagOperator: ImageEditorTagOperator
    private let undoOperator: ImageEditorUndoOperator
    private let rectSelectOperator: ImageEditorRectSelectOperator

    init(image: UIImage) {
        originalImage = image.fixOrientation()
        allToolBars = [bottomFunctionPanel, lineFunctionView, tagFunctionView, mosaicFunctionView]
        brushOperator = ImageEditorBrushOperator(with: imageEditor)
        stickerOperator = ImageEditorTextStickerOperator(with: imageEditor)
        tagOperator = ImageEditorTagOperator(with: imageEditor)
        undoOperator = ImageEditorUndoOperator(with: imageEditor)
        rectSelectOperator = ImageEditorRectSelectOperator(with: imageEditor)

        super.init(nibName: nil, bundle: nil)

        brushOperator.delegate = self
        stickerOperator.delegate = self
        tagOperator.delegate = self
        undoOperator.delegate = self
        rectSelectOperator.delegate = self
        bottomFunctionPanel.delegate = self
        lineFunctionView.delegate = self
        tagFunctionView.delegate = self
        mosaicFunctionView.delegate = self
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var prefersStatusBarHidden: Bool { return true }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        guard shoudAdjustVEFrame else { return }

        scrollView.frame = view.bounds
        imageEditor.preview.center = scrollView.center
        shouldRender = true

        stickerOperator.resetAllStickers()
        tagOperator.resetTagCenter()

        topGradientLayer.bounds = .init(origin: .zero, size: .init(width: view.bounds.width, height: 120))
        topGradientLayer.position = .init(x: view.bounds.width / 2, y: 60)
        bottomGradientLayer.bounds = .init(x: 0, y: view.bounds.height - 120, width: view.bounds.width, height: 120)
        bottomGradientLayer.position = .init(x: view.bounds.width / 2, y: view.bounds.height - 60)

        shoudAdjustVEFrame = false
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        shoudAdjustVEFrame = true
        scrollView.setZoomScale(1, animated: false)
        scaleToFullScreen(size)
        allToolBars.forEach { $0.updateCurrentViewWidth(size.width) }
    }

    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        currentEditType.isNone ? [] : [.top, .bottom]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        ImageEditorResourceManager.unzip(currentView: view)

        editEventSubject.onNext(.init(event: "public_pic_edit_view"))
        isNavigationBarHidden = true
        setUpSrollView()
        setUpToolBars()
        setUpBottomArea()
        setUpTopArea()
        setUpWidthIndicater()
        setUpGesture()
        scaleToFullScreen(view.bounds.size)
        setupCADisplayLink()
        setupOperators()
    }

    // setup operators
    private func setupOperators() {
        brushOperator.setup()
        rectSelectOperator.setup()
        tagOperator.setup()
        undoOperator.setup(currentBrushID: brushOperator.brushID, currentVectorID: tagOperator.vectorStickerID)
    }

    // setup timer
    private func setupCADisplayLink() {
        // VE的渲染如果不和主线程同步会出现卡顿问题，这里放入displaylink保证同步
        displayLink = CADisplayLink(target: self, selector: #selector(render))
        displayLink?.add(to: .main, forMode: .default)
    }

    @objc
    private func render() {
        guard shouldRender else { return }
        imageEditor.renderLayerQueueAsyn()
        shouldRender = false
    }

    // setup gesture
    private func setUpGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        panGesture.shouldRequireFailure(of: scrollView.panGestureRecognizer)
        panGesture.maximumNumberOfTouches = 1
        panGesture.delegate = self
        imageEditor.preview.addGestureRecognizer(panGesture)

        let singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap))
        singleTapRecognizer.delegate = self
        imageEditor.preview.addGestureRecognizer(singleTapRecognizer)
    }

    // setup UI
    private func setUpSrollView() {
        view.addSubview(scrollView)
        scrollView.frame = view.bounds
        scrollView.backgroundColor = .ud.staticBlack
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self

        scrollView.addSubview(imageEditor.preview)
        imageEditor.preview.frame = scrollView.bounds
        imageEditor.addImageLayer(with: originalImage)
        imageEditor.preview.contentMode = .scaleAspectFit
    }

    private func setUpWidthIndicater() {
        view.addSubview(widthIndicateCircle)
        widthIndicateCircle.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(0)
        }
        widthIndicateCircle.backgroundColor = .ud.color(0, 0, 0, 0.5)
        widthIndicateCircle.alpha = 0
    }

    private func setUpToolBars() {
        allToolBars.forEach {
            view.addSubview($0)
            let height = UIDevice.current.userInterfaceIdiom == .pad ? $0.heightForIpad: $0.heightForIphone
            $0.snp.makeConstraints { make in
                make.leading.trailing.bottom.equalToSuperview()
                make.height.equalTo(height)
            }
            $0.updateCurrentViewWidth(view.bounds.width)
            $0.isHidden = true
        }
        bottomFunctionPanel.isHidden = false
    }

    private func setUpBottomArea() {
        bottomGradientLayer.ud.setColors([UIColor.ud.N1000.withAlphaComponent(0).alwaysLight,
                                          UIColor.ud.N1000.withAlphaComponent(0.3).alwaysLight],
                                         bindTo: view)
        bottomGradientLayer.bounds = .init(x: 0, y: view.bounds.height - 120, width: view.bounds.width, height: 120)
        bottomGradientLayer.position = .init(x: view.bounds.width / 2, y: view.bounds.height - 60)
        view.layer.addSublayer(bottomGradientLayer)

        view.addSubview(stickerDeleteButton)
        stickerDeleteButton.setTitle(BundleI18n.LarkImageEditor.Lark_ImageViewer_DragHereToDelete, for: .normal)
        stickerDeleteButton.setTitle(BundleI18n.LarkImageEditor.Lark_ImageViewer_ReleaseToDelete, for: .selected)
        stickerDeleteButton.setTitleColor(.ud.colorfulRed, for: .normal)
        stickerDeleteButton.setTitleColor(.ud.primaryOnPrimaryFill, for: .selected)
        stickerDeleteButton.setImage(Resources.edit_delete, for: .normal)
        stickerDeleteButton.setImage(Resources.edit_delete_highlighted, for: .selected)
        stickerDeleteButton.backgroundColor = .ud.N00.withAlphaComponent(0.9)
        stickerDeleteButton.layer.cornerRadius = 8
        stickerDeleteButton.titleLabel?.font = .systemFont(ofSize: 14)
        stickerDeleteButton.titleEdgeInsets = .init(top: 17, left: 24, bottom: 17, right: 15)
        stickerDeleteButton.imageEdgeInsets = .init(top: 20, left: 18, bottom: 20, right: 122)
        stickerDeleteButton.snp.makeConstraints { make in
            make.height.equalTo(56)
            make.width.equalTo(156)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(44)
        }
        setDeleteButtonDisable(true)
    }

    private func setUpTopArea() {
        topGradientLayer.ud.setColors([UIColor.ud.N1000.withAlphaComponent(0.5).alwaysLight,
                                       UIColor.ud.N1000.withAlphaComponent(0).alwaysLight],
                                      bindTo: view)
        view.layer.addSublayer(topGradientLayer)
        topGradientLayer.bounds = .init(origin: .zero, size: .init(width: view.bounds.width, height: 120))
        topGradientLayer.position = .init(x: view.bounds.width / 2, y: 60)

        view.addSubview(closeButton)
        closeButton.setImage(Resources.edit_close, for: .normal)
        closeButton.addTarget(self, action: #selector(closeButtonDidClick), for: .touchUpInside)
        closeButton.snp.makeConstraints { (make) in
            make.size.equalTo(48)
            make.left.equalToSuperview().offset(6)
            make.top.equalTo(view.safeAreaLayoutGuide).inset(12)
        }
        view.addSubview(revertButton)
        revertButton.setImage(Resources.edit_revert, for: .normal)
        revertButton.addTarget(self, action: #selector(revertButtonDidClicked), for: .touchUpInside)
        revertButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(6)
            make.size.centerY.equalTo(closeButton)
        }
        revertButton.isHidden = true

        view.addSubview(backButton)
        backButton.setImage(Resources.edit_back, for: .normal)
        backButton.addTarget(self, action: #selector(backButtonDidClicked), for: .touchUpInside)
        backButton.snp.makeConstraints { (make) in
            make.edges.equalTo(closeButton)
        }
        backButton.isHidden = true
    }

    private func adjustRevertButtonIfNeeded(editCount: Int) { if editCount == 0 { revertButton.isHidden = true } }

    // actions
    @objc
    private func revertButtonDidClicked() {
        switch currentEditType {
        case .draw(let currentLineCount):
            editEventSubject.onNext(.init(event: "public_pic_edit_draw_click",
                                          params: ["click": "undo", "target": "none"]))
            undoOperator.undoOnce(with: .line(lineCount: 1))
            adjustRevertButtonIfNeeded(editCount: currentLineCount - 1)
            currentEditType = .draw(currentLineCount: currentLineCount - 1)
        case .mosaic(let currentMosaicCount):
            editEventSubject.onNext(.init(event: "public_pic_edit_mosaic_click",
                                          params: ["click": "undo", "target": "none"]))
            undoOperator.undoOnce(with: .mosaic)
            adjustRevertButtonIfNeeded(editCount: currentMosaicCount - 1)
            currentEditType = .mosaic(currentMosaicCount: currentMosaicCount - 1)
        case .tag(let currentTagCount):
            editEventSubject.onNext(.init(event: "public_pic_edit_graph_click",
                                          params: ["click": "undo", "target": "none"]))
            tagOperator.cancelSelected()
            resetTagFunctionView()
            undoOperator.undoOnce(with: .tag)
            adjustRevertButtonIfNeeded(editCount: currentTagCount - 1)
            currentEditType = .tag(currentTagCount: currentTagCount - 1)
        case .text, .none: break
        }
    }

    @objc
    private func backButtonDidClicked() {
        let afterFinish = { [weak self] (toolbar: EditorToolBar) -> Void in
            toolbar.animateHideToolBar {
                self?.bottomFunctionPanel.animateShowToolBar()
                toolbar.isHidden = true
                self?.toolBarDidChanged(isShow: false)
            }
        }
        switch currentEditType {
        case .draw(let currentLineCount):
            undoOperator.undoAll(with: .line(lineCount: currentLineCount))
            afterFinish(lineFunctionView)
        case .mosaic:
            undoOperator.undoAll(with: .mosaic)
            afterFinish(mosaicFunctionView)
        case .tag:
            tagOperator.setVectorEnable(false)
            undoOperator.undoAll(with: .tag)
            afterFinish(tagFunctionView)
        case .text, .none: break
        }
        currentEditType = .none
    }

    @objc
    private func closeButtonDidClick() { delegate?.closeButtonDidClicked(vc: self) }

    @objc
    private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        switch (currentEditType, mosaicFunctionView.currentSelectType) {
        case (.draw, _):
            handleToolBarPanGesture(gesture, toolBar: lineFunctionView)
            brushOperator.handleBrushPanGesture(gesture)
        case (.mosaic, .smear):
            handleToolBarPanGesture(gesture, toolBar: mosaicFunctionView)
            brushOperator.handleBrushPanGesture(gesture) { [weak self] in
                guard let self = self else { return }
                self.undoOperator.saveMosaicStatus((.smear, self.brushOperator.brushID))
            }
        case (.mosaic, .rect):
            handleToolBarPanGesture(gesture, toolBar: mosaicFunctionView)
            rectSelectOperator.handleSelectPanGesture(gesture,
                                                      currentResourcePath: mosaicFunctionView.currentMosaic == .mosaic
                                                      ? ImageEditorResourceManager.mosaicRectResourcePath
                                                      : ImageEditorResourceManager.mosaicGuassRectResourcePath) {
                [weak self] in self?.undoOperator.saveMosaicStatus((.rect, $0))
            }
        case (.tag, _):
            handleToolBarPanGesture(gesture, toolBar: tagFunctionView)
            if gesture.state == .began &&
                !tagOperator.pointInCurrentTag(with: gesture.location(in: imageEditor.preview)) {
                tagOperator.cancelSelected()
            }
            tagOperator.inSelected ? handleTagStickerPan(gesture)
            : tagOperator.handleAddPan(gesture, boarderViewDelegate: self) { [weak self] in
                guard let self = self, let lastTag = self.tagOperator.lastTag else { return }
                self.undoOperator.saveTagStatus(lastTag)
                self.resetTagFunctionView()
            }
        case (.none, _), (.text, _): handleStickerPan(gesture)
        }
    }

    @objc
    private func handleSingleTap(_ tap: UITapGestureRecognizer) {
        switch currentEditType {
        case .draw: handleToolBarSingleTap(lineFunctionView)
        case .mosaic: handleToolBarSingleTap(mosaicFunctionView)
        case .tag:
            if tagOperator.inSelected
                && !tagOperator.pointInCurrentTag(with: tap.location(in: imageEditor.preview)) {
                tagOperator.cancelSelected()
                resetTagFunctionView()
                break
            }

            tagOperator.selectTagIfNeeded(with: tap.location(in: imageEditor.preview))
            tagOperator.inSelected ? tagOperator.handleTagTap { [weak self] in
                self?.tagFunctionView.animateShowToolBar()
                self?.tagFunctionView.updateType($0)
                self?.tagFunctionView.updateSlider($1)
                self?.tagFunctionView.updateColor($2)
            } : handleToolBarSingleTap(tagFunctionView)
        case .none:
            if let currentSelectedStickerBorder = stickerOperator.currentSelectedStickerBorder {
                handleTextStickerTap(tap, in: currentSelectedStickerBorder)
            } else {
                handleToolBarSingleTap(bottomFunctionPanel)
            }
        case .text: break
        }
    }

    // scroll view delegate
    func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageEditor.preview }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        currentImageScale *= scale

        // scrollview的放大不会改变view的bounds，也就不会触发VE的重绘，会出现放大后模糊的问题。这里先缩回去，然后手动放大VE的view到相同位置
        let size = imageEditor.preview.frame.size
        let origin = imageEditor.preview.frame.origin
        let offset = scrollView.contentOffset
        scrollView.maximumZoomScale /= scale
        scrollView.minimumZoomScale /= scale
        scrollView.setZoomScale(1, animated: false)
        scrollView.contentOffset = offset
        scrollView.contentSize = size
        imageEditor.preview.frame = .init(origin: origin, size: size)

        let currentLayerFrame = imageEditor.currentLayerFrameOnView
        imageEditor.scale(withScale: .init(width: scale, height: scale),
                          anchor: .init(x: 0, y: currentLayerFrame.height))
        let frameOrigin = currentLayerFrame.origin
        imageEditor.translate(withOffset: .init(x: -frameOrigin.x, y: frameOrigin.y))

        imageEditor.renderEffect()
        shouldRender = true

        switch currentEditType {
        case .draw: brushOperator.changeBrushWidth(with: lineFunctionView.currentSliderValue)
        case .mosaic: brushOperator.changeBrushWidth(with: mosaicFunctionView.currentSliderValue)
        case .none, .text, .tag: break
        }

        stickerOperator.resetAllStickers()
        tagOperator.updateAllTags(with: scale)
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        tagOperator.cancelSelected()

        // 使得content一直处于scrollview的中心，这样放大后content不会偏移
        let xCenter = scrollView.contentSize.width > scrollView.frame.size.width
        ? scrollView.contentSize.width / 2 : scrollView.bounds.width / 2
        let yCenter = scrollView.contentSize.height > scrollView.frame.size.height
        ? scrollView.contentSize.height / 2 : scrollView.bounds.height / 2
        imageEditor.preview.center = .init(x: xCenter, y: yCenter)
    }

    // gesture delegate
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        switch currentEditType {
        case .none :
            stickerOperator.checkPointInStickerArea(touch.location(in: imageEditor.preview))
            return stickerOperator.currentSelectedStickerBorder != nil || gestureRecognizer is UITapGestureRecognizer
        case .text, .mosaic, .draw, .tag: return true
        }
    }
}

// animation
extension ImageEditorViewController {
    private func animateHideTopButtons() {
        UIView.animate(withDuration: 0.2, animations: { [weak self] in
            self?.backButton.alpha = 0
            self?.revertButton.alpha = 0
            self?.closeButton.alpha = 0
        })
    }

    private func animateShowTopButtons() {
        UIView.animate(withDuration: 0.2, animations: { [weak self] in
            self?.backButton.alpha = 1
            self?.revertButton.alpha = 1
            self?.closeButton.alpha = 1
        })
    }
}

// utils
extension ImageEditorViewController {
    private func scaleToFullScreen(_ size: CGSize) {
        let scale = imageEditor.scaleToFullScreen(size)
        currentImageScale = 1
        currentImageInitialScale = scale
        if imageEditor.preview.frame.height > size.height && size.width / size.height < 0.75 {
            imageEditor.preview.frame.origin = .zero
            scrollView.contentSize = imageEditor.preview.frame.size
        }
        shouldRender = true
    }

    private func resetVEImage(with image: UIImage) {
        scrollView.setZoomScale(1, animated: false)
        imageEditor.replaceImageLayer(with: image, setupBlock: nil)
        scaleToFullScreen(view.bounds.size)
        imageEditor.preview.center = scrollView.center
        brushOperator.setUpBrushCache()
        tagOperator.setup()
    }
}

// toolbar related
extension ImageEditorViewController {
    private func increaseElementCount() {
        switch currentEditType {
        case .draw(let currentLineCount): currentEditType = .draw(currentLineCount: currentLineCount + 1)
        case .mosaic(let currentMosaicCount): currentEditType = .mosaic(currentMosaicCount: currentMosaicCount + 1)
        case .tag(let currentTagCount): currentEditType = .tag(currentTagCount: currentTagCount + 1)
        case .none, .text: break
        }
    }

    private func updateWidthIndicateCircle(with width: CGFloat) {
        widthIndicateCircle.alpha = 1
        widthIndicateCircle.snp.updateConstraints { make in make.size.equalTo(width) }
        widthIndicateCircle.layer.cornerRadius = width / 2
    }

    private func setToolBarHidden(_ toolBar: EditorToolBar, _ hidden: Bool) {
        if hidden {
            toolBar.animateHideToolBar()
            animateHideTopButtons()
        } else if !isBottomToolBarHidden {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                toolBar.animateShowToolBar()
                self?.animateShowTopButtons()
            }
        }
    }

    private func handleToolBarSingleTap(_ toolBar: EditorToolBar) {
        isBottomToolBarHidden = !isBottomToolBarHidden
        isBottomToolBarHidden ? toolBar.animateHideToolBar() : toolBar.animateShowToolBar()
        isBottomToolBarHidden ? animateHideTopButtons() : animateShowTopButtons()
    }

    private func handleToolBarPanGesture(_ gesture: UIPanGestureRecognizer, toolBar: EditorToolBar) {
        switch gesture.state {
        case .began:
            setToolBarHidden(toolBar, true)
        case .ended, .cancelled, .failed:
            setToolBarHidden(toolBar, false)
            revertButton.isHidden = false
            if !tagOperator.inSelected { increaseElementCount() }
        case .possible, .changed: break
        @unknown default: assertionFailure("should not come here")
        }
    }

    private func toolBarDidChanged(isShow: Bool) {
        if isShow {
            closeButton.isHidden = true
            backButton.isHidden = false
        } else {
            closeButton.isHidden = false
            backButton.isHidden = true
            revertButton.isHidden = true
        }
    }
}

// stickers related
extension ImageEditorViewController {
    private func presentAddTextVC(clickedBoardView: TextStickerBoarderView? = nil) {
        let addTextVC = ImageEditorAddTextViewController(editText: clickedBoardView?.sticker.editText ?? .default)
        let dismissBlock = { [weak self] (vc: ImageEditorAddTextViewController) -> Void in
            self?.stickerOperator.setStickerAlpha(1, boarder: clickedBoardView)
            vc.dismiss(animated: true) {
                self?.bottomFunctionPanel.animateShowToolBar()
                self?.closeButton.isHidden = false
            }
        }
        addTextVC.eventBlock = { [weak self] in self?.editEventSubject.onNext($0) }
        addTextVC.cancelEditBlock = dismissBlock
        addTextVC.finishEditBlock = { [weak self] (vc, editText) in
            guard let self = self,
                  let jsonString = self.stickerOperator.setUpTextStickerParams(with: editText) else {
                      dismissBlock(vc)
                      return
                  }

            if let boarderView = clickedBoardView {
                self.stickerOperator.updateTextSticker(with: editText, of: boarderView, and: jsonString)
            } else if !editText.text.isEmpty {
                self.stickerOperator.createNewTextSticker(with: editText, and: jsonString, boarderViewDelegate: self,
                                                          currentView: self.view)
            }
            self.currentEditType = .none

            dismissBlock(vc)
        }

        addTextVC.modalPresentationStyle = .overCurrentContext
        closeButton.isHidden = true
        bottomFunctionPanel.animateHideToolBar { [weak self] in
            self?.present(addTextVC, animated: true)
            self?.stickerOperator.setStickerAlpha(0, boarder: clickedBoardView)
        }
    }

    private func setDeleteButtonDisable(_ disable: Bool) {
        stickerDeleteButton.isHidden = disable
        bottomGradientLayer.isHidden = disable
    }

    private func setDeleteButtonSelected(_ selected: Bool) {
        stickerDeleteButton.isSelected = selected
        stickerDeleteButton.backgroundColor = selected ? .ud.colorfulRed : .ud.N00.withAlphaComponent(0.9)
    }

    private func updateDeleteButton(currentTouchPoint: CGPoint) {
        if stickerDeleteButton.frame.contains(currentTouchPoint) {
            setDeleteButtonSelected(true)
            hasEnterDeleteButtonFrame = true
        } else {
            setDeleteButtonSelected(false)
            if hasEnterDeleteButtonFrame {
                stickerDeleteButton.isHidden = true
            }
        }
    }
}

// tag related
extension ImageEditorViewController {
    private func resetTagFunctionView() {
        tagFunctionView.updateType(tagOperator.currentType)
        tagFunctionView.updateSlider(tagOperator.currentWidth)
        tagFunctionView.updateColor(tagOperator.currentColor)
    }
}

extension ImageEditorViewController: ImageEditFunctionPanelDelegate {
    private func showFunctionView(_ toolbar: EditorToolBar) {
        bottomFunctionPanel.animateHideToolBar { [weak self] in
            self?.toolBarDidChanged(isShow: true)
            toolbar.isHidden = false
            toolbar.animateShowToolBar()
        }
    }

    func lineButtonDidClicked() {
        editEventSubject.onNext(.init(event: "public_pic_edit_click",
                                      params: ["click": "draw", "target": "public_pic_edit_draw_view"]))
        editEventSubject.onNext(.init(event: "public_pic_edit_draw_view"))
        currentEditType = .draw(currentLineCount: 0)
        brushOperator.setUpBrushResourcePack(with: lineFunctionView.currentSeletedColor,
                                             and: lineFunctionView.currentSliderValue)

        showFunctionView(lineFunctionView)
    }

    func mosaicButtonDidClicked() {
        editEventSubject.onNext(.init(event: "public_pic_edit_click",
                                      params: ["click": "mosaic", "target": "public_pic_edit_mosaic_view"]))
        editEventSubject.onNext(.init(event: "public_pic_edit_mosaic_view"))
        currentEditType = .mosaic(currentMosaicCount: 0)
        switch mosaicFunctionView.currentMosaic {
        case .mosaic: brushOperator.setUpMosaicResourcePack(with: mosaicFunctionView.currentSliderValue, isGuass: false)
        case .gaussan: brushOperator.setUpMosaicResourcePack(with: mosaicFunctionView.currentSliderValue, isGuass: true)
        }

        showFunctionView(mosaicFunctionView)
    }

    func textButtonDidClicked() {
        editEventSubject.onNext(.init(event: "public_pic_edit_click",
                                      params: ["click": "text", "target": "public_pic_edit_text_view"]))
        editEventSubject.onNext(.init(event: "public_pic_edit_text_view"))
        presentAddTextVC()
    }

    func trimButtonDidClicked() {
        currentEditType = .none

        editEventSubject.onNext(.init(event: "public_pic_edit_click",
                                      params: ["click": "crop", "target": "public_pic_edit_crop_view"]))
        editEventSubject.onNext(.init(event: "public_pic_edit_crop_view"))
        let currentImage = imageEditor.getCurrentImage(false, isPanoramic: false)
        let initialRect = CGRect(origin: .zero, size: .init(width: currentImage.size.width,
                                                            height: currentImage.size.height))

        let config = CropperConfigure(squareScale: false, initialRect: initialRect, style: .more)
        let cropperVC = ImageEditCropperViewController(image: currentImage, config: config)
        cropperVC.successCallback = { [weak self] (image, cropperVC, _) in
            self?.stickerOperator.removeAllBoarder()
            self?.tagOperator.removeAllBoarder()
            self?.resetVEImage(with: image)
            cropperVC.dismiss(animated: true) {
                self?.bottomFunctionPanel.animateShowToolBar()
            }
        }
        cropperVC.cancelCallback = { [weak self] in
            $0.dismiss(animated: true) { self?.bottomFunctionPanel.animateShowToolBar() }
        }
        cropperVC.eventBlock = { [weak self] in self?.editEventSubject.onNext($0) }
        cropperVC.modalPresentationStyle = .overCurrentContext
        cropperVC.transitioningDelegate = self

        bottomFunctionPanel.animateHideToolBar { [weak self] in
            self?.present(cropperVC, animated: true)
        }
    }

    func tagButtonDidClicked() {
        editEventSubject.onNext(.init(event: "public_pic_edit_click",
                                      params: ["click": "graph", "target": "public_pic_edit_graph_view"]))
        editEventSubject.onNext(.init(event: "public_pic_edit_graph_view"))
        currentEditType = .tag(currentTagCount: 0)
        tagOperator.setVectorEnable(true)
        showFunctionView(tagFunctionView)
    }

    func finishButtonDidClicked() {
        editEventSubject.onNext(.init(event: "public_pic_edit_click",
                                      params: ["click": "done", "target": "none"]))
        currentEditType = .none
        delegate?.finishButtonDidClicked(vc: self,
                                         editImage: imageEditor.getCurrentImage(false, isPanoramic: false))
    }
}

extension ImageEditorViewController: EditorToolBarDelegate {
    func sliderTimerTicked() { widthIndicateCircle.alpha = 0 }

    func changeWidth(with width: CGFloat, defaultWidth: CGFloat) {
        switch currentEditType {
        case .draw:
            brushOperator.changeBrushWidth(with: width)
            updateWidthIndicateCircle(with: 36 + width - defaultWidth)
        case .mosaic:
            brushOperator.changeBrushWidth(with: width)
            updateWidthIndicateCircle(with: 36 + width - defaultWidth)
        case .tag:
            tagOperator.changeWidth(with: width)
            if !tagOperator.inSelected { updateWidthIndicateCircle(with: 36 + width - defaultWidth) }
        case .none, .text: break
        }
    }

    func changeColor(with color: ColorPanelType) {
        switch currentEditType {
        case .draw: brushOperator.changeLineColor(with: color.color())
        case .tag: tagOperator.changeColor(with: color)
        case .none, .mosaic, .text: break
        }
    }

    func finishButtonDidClicked(in toolbar: EditorToolBar) {
        toolbar.animateHideToolBar { [weak self] in
            toolbar.isHidden = true
            self?.brushOperator.endStickerBrush()
            self?.bottomFunctionPanel.animateShowToolBar()
            self?.toolBarDidChanged(isShow: false)
            self?.currentEditType = .none
            self?.undoOperator.clearStatus()
            self?.tagOperator.setVectorEnable(false)
        }
    }

    func eventOccured(eventName: String, params: [String: Any]) {
        editEventSubject.onNext(.init(event: eventName, params: params))
    }
}

extension ImageEditorViewController: MosaicFunctionViewDelegate {
    func aeroButtonDidClicked() {
        brushOperator.setUpMosaicResourcePack(with: mosaicFunctionView.currentSliderValue, isGuass: false)
    }

    func blurButtonDidClicked() {
        brushOperator.setUpMosaicResourcePack(with: mosaicFunctionView.currentSliderValue, isGuass: true)
    }
}

extension ImageEditorViewController: TagFunctionViewDelegate {
    func shapeButtonDidClicked(type: TagType) {
        if tagOperator.inSelected { tagOperator.cancelSelected() }
        tagOperator.updateCurrentType(with: type)
        resetTagFunctionView()
    }
}

extension ImageEditorViewController: TextStickerBoarderViewDelegate {
    func handleTextStickerTap(_ tap: UITapGestureRecognizer, in boarderView: TextStickerBoarderView) {
        stickerOperator.handleStickerTap(in: boarderView) { [weak self] in
            self?.presentAddTextVC(clickedBoardView: boarderView)
        }
    }

    func handleTextStickerPinch(_ pinch: UIPinchGestureRecognizer, in boarderView: TextStickerBoarderView) {
        stickerOperator.handleStickerPinch(pinch, in: boarderView)
        switch pinch.state {
        case .began:
            currentEditType = .text
            bottomFunctionPanel.animateHideToolBar()
            editEventSubject.onNext(.init(event: "public_pic_edit_click",
                                          params: ["click": "text_zoom", "target": "none"]))
        case .ended, .cancelled, .failed:
            bottomFunctionPanel.animateShowToolBar()
            currentEditType = .none
        case .possible, .changed: break
        @unknown default: assertionFailure("should not come here")
        }
    }

    func handleTextStickerRotation(_ rotation: UIRotationGestureRecognizer, in boarderView: TextStickerBoarderView) {
        stickerOperator.handleStickerRotation(rotation, in: boarderView)
        switch rotation.state {
        case .began:
            currentEditType = .text
            bottomFunctionPanel.animateHideToolBar()
            editEventSubject.onNext(.init(event: "public_pic_edit_click",
                                          params: ["click": "text_rotation", "target": "none"]))
        case .ended, .cancelled, .failed:
            bottomFunctionPanel.animateShowToolBar()
            currentEditType = .none
        case .possible, .changed: break
        @unknown default: assertionFailure("should not come here")
        }
    }

    func handleStickerPan(_ pan: UIPanGestureRecognizer) {
        let inDeleteFrame = stickerDeleteButton.frame.contains(pan.location(in: view))
        let shouldDeleteSticker = inDeleteFrame && !stickerDeleteButton.isHidden
        stickerOperator.handleStickerPan(pan, inDeleteFrame: shouldDeleteSticker)
        switch pan.state {
        case .began:
            currentEditType = .text
            bottomFunctionPanel.animateHideToolBar()
            setDeleteButtonDisable(false)
            editEventSubject.onNext(.init(event: "public_pic_edit_click",
                                          params: ["click": "text_move", "target": "none"]))
        case .changed: updateDeleteButton(currentTouchPoint: pan.location(in: view))
        case .ended, .cancelled, .failed:
            if shouldDeleteSticker {
                editEventSubject.onNext(.init(event: "public_pic_edit_click",
                                              params: ["click": "text_delete", "target": "none"]))
            }
            setDeleteButtonSelected(false)
            setDeleteButtonDisable(true)
            hasEnterDeleteButtonFrame = false
            bottomFunctionPanel.animateShowToolBar()
            currentEditType = .none
        case .possible: break
        @unknown default: assertionFailure("should not come here")
        }
    }
}

extension ImageEditorViewController: TagStickerBoarderViewDelegate {
    private func adjustFunctionViewInGesture(_ gesture: UIGestureRecognizer) {
        switch gesture.state {
        case .began: tagFunctionView.animateHideToolBar()
        case .ended, .cancelled, .failed: tagFunctionView.animateShowToolBar()
        case .possible, .changed: break
        @unknown default: assertionFailure("should not come here")
        }
    }

    func handleTagStickerPinch(_ pinch: UIPinchGestureRecognizer) {
        adjustFunctionViewInGesture(pinch)
        tagOperator.handleSelectedPinch(pinch)
    }

    func handleTagStickerRotation(_ rotation: UIRotationGestureRecognizer) {
        adjustFunctionViewInGesture(rotation)
        tagOperator.handleSelectedRotation(rotation)
    }

    func handleTagStickerPan(_ pan: UIPanGestureRecognizer) {
        let inDeleteFrame = stickerDeleteButton.frame.contains(pan.location(in: view))
        let shouldDeleteSticker = inDeleteFrame && !stickerDeleteButton.isHidden
        tagOperator.handleSelectedPan(pan, inDeleteFrame: shouldDeleteSticker)
        switch pan.state {
        case .began: setDeleteButtonDisable(false)
        case .changed: updateDeleteButton(currentTouchPoint: pan.location(in: view))
        case .ended, .cancelled, .failed:
            if shouldDeleteSticker {
                guard case .tag(let tagCount) = currentEditType else { return }
                currentEditType = .tag(currentTagCount: tagCount - 1)
                adjustRevertButtonIfNeeded(editCount: tagCount - 1)
                resetTagFunctionView()
            }
            setDeleteButtonSelected(false)
            setDeleteButtonDisable(true)
            hasEnterDeleteButtonFrame = false
        case .possible: break
        @unknown default: assertionFailure("should not come here")
        }
    }
}

extension ImageEditorViewController: ImageEditorOperatorDelegate {
    func setRenderFlag() { shouldRender = true }
}

extension ImageEditorViewController: EditViewController {
    public func exit() {
        displayLink?.invalidate()
        if let nav = self.navigationController,
           nav.topViewController == self,
           nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        } else if self.presentingViewController != nil {
            self.dismiss(animated: true, completion: nil)
        } else {
            assertionFailure("image edit exit with error")
        }
    }
}

private extension ImageEditorViewController {
    private enum CurrentEditType {
        case draw(currentLineCount: Int)
        case mosaic(currentMosaicCount: Int)
        case tag(currentTagCount: Int)
        case text
        case none

        fileprivate var isNone: Bool {
            if case .none = self { return true }
            return false
        }
    }
}
