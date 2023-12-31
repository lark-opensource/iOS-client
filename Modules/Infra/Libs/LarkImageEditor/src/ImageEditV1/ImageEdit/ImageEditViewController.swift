//
//  ImageEditViewController.swift
//  LarkUIKit
//
//  Created by ChalrieSu on 2018/7/30.
//  Copyright © 2018 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import ServerPB
import SnapKit
import LarkExtensions
import LarkUIKit

public final class ImageEditViewController: BaseUIViewController,
                                      UIViewControllerTransitioningDelegate,
                                      EditViewController {
    public weak var delegate: ImageEditViewControllerDelegate?

    private let smartMosaicStateSubject = PublishSubject<SmartMosaicState>()
    private let editEventSubject = PublishSubject<ImageEditEvent>()
    public var editEventObservable: Observable<ImageEditEvent> {
        return editEventSubject.asObservable()
    }

    private var smartMosaicState = SmartMosaicState.loading

    private let originalImage: UIImage
    private var hasAppeared: Bool = false
    private let disposeBag = DisposeBag()

    // UI
    private let closeButton = UIControl()
    private var imageEditView: ImageEditView
    private let zoomScrollView: ZoomScrollView
    private var functionView: ImageEditFunctionBottomView
    private let bottomPanel = ImageEditBottomPanel()

    // 用于标记是否已经发生过不可逆的图片裁剪操作
    private var hadRebuildImageEditView = false

    public init(image: UIImage) {
        self.originalImage = image
        imageEditView = ImageEditView(image: image,
                                      imageEditEventSubject: editEventSubject,
                                      smartMosaicStateObservable: smartMosaicStateSubject.asObservable())
        zoomScrollView = ZoomScrollView(zoomView: imageEditView, originSize: imageEditView.showRect.size)
        imageEditView.zoomScrollView = zoomScrollView
        functionView = ImageEditFunctionBottomView(currentFunction: .default,
                                                   smartMosaicStateObservable: smartMosaicStateSubject.asObservable())

        super.init(nibName: nil, bundle: nil)

        if #available(iOS 13.0, *) {
            view.overrideUserInterfaceStyle = .light
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var ignoreViewDidLayoutSubviews: Bool = false
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !Display.phone && !ignoreViewDidLayoutSubviews {
            zoomScrollView.relayoutZoomView()
        }
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !hasAppeared {
            imageEditView.imageUndoManager?
                .canUndoObservale
                .subscribe(onNext: { [weak self] (isEnable) in
                    self?.bottomPanel.isRevertButtonEnable = isEnable
                })
                .disposed(by: disposeBag)
        }
        hasAppeared = true
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resignFirstResponder()
    }

    public override var canBecomeFirstResponder: Bool {
        return true
    }

    public override var prefersStatusBarHidden: Bool {
        return true
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black
        editEventSubject.onNext(ImageEditEvent(event: "pic_edit"))
        isNavigationBarHidden = true
        imageEditView.delegate = self

        view.addSubview(closeButton)
        view.insertSubview(zoomScrollView, belowSubview: closeButton)
        view.addSubview(functionView)
        view.addSubview(bottomPanel)

        let imageView = UIImageView(image: Resources.edit_close)
        closeButton.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.height.width.equalTo(24)
        }
        closeButton.addTarget(self, action: #selector(closeButtonDidClick), for: .touchUpInside)
        closeButton.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 48, height: 48))
            make.left.equalToSuperview().offset(12)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(0)
        }

        zoomScrollView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalTo(bottomPanel.snp.top)
        }

        functionView.delegate = self
        functionView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(bottomPanel.snp.top)
        }

        bottomPanel.delegate = self
        bottomPanel.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-52)
            make.left.right.bottom.equalToSuperview()
        }
        // 默认进入涂鸦功能
        bottomPanel(bottomPanel, didSelect: BottomPanelFunction.default)
        // 获取图片的文字和头像信息，为智能马赛克作准备
        extractSmartMosaicInfo()
    }

    @objc
    private func closeButtonDidClick() {
        self.delegate?.closeButtonDidClicked(vc: self)
    }

    private var imageEditEvents: [ImageEditEvent] {
        var events: [ImageEditEvent] = []

        if imageEditView.addLineView.hasEverOperated {
            let hasEverAdjustSize = functionView.hasEverAdjustAddLineSlider ? "y" : "n"
            events.append(ImageEditEvent(event: "pic_edit_draw",
                                         params: ["pic_edit_draw_size_adjust": hasEverAdjustSize]))
        }

        if imageEditView.addMosaicView.hasEverOperated {
            let hasEverAdjustSize = functionView.hasEverAdjustAddMosaicSlider ? "y" : "n"
            events.append(ImageEditEvent(event: "pic_edit_Mosaic",
                                         params: ["pic_edit_mosaic_size_adjust": hasEverAdjustSize]))
        }

        if imageEditView.addTextView.hasEverOperated {
            events.append(ImageEditEvent(event: "pic_edit_text"))
        }

        let addLineColors = imageEditView.addLineView.lines.map { $0.color.rawValue }
        events.append(ImageEditEvent(event: "pic_edit_draw_color",
                                     params: ["color_id": addLineColors]))

        let addMosaicTypes = imageEditView.addMosaicView.paths.map { $0.mosaicType.rawValue }
        events.append(ImageEditEvent(event: "pic_edit_mosaic_type",
                                     params: ["mosaic_id": addMosaicTypes]))

        let addMosaicSelectionTypes = imageEditView.addMosaicView.paths.map { $0.selectionType.rawValue }
        events.append(ImageEditEvent(event: "pic_edit_mosaic_selection_type",
                                     params: ["mosaic_id": addMosaicSelectionTypes]))

        let addTextColors = imageEditView.addTextView.labels.map { $0.editText.color.rawValue }
        events.append(ImageEditEvent(event: "pic_edit_text_box_create",
                                     params: ["text_color_id": addTextColors]))
        return events
    }

    /// 退出当前界面
    public func exit() {
        imageEditEvents.forEach { editEventSubject.onNext($0) }
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

    public func animationController(forPresented presented: UIViewController,
                                    presenting: UIViewController,
                                    source: UIViewController)
    -> UIViewControllerAnimatedTransitioning? {
        if let functionVC = presented as? CropperViewController {
            functionVC.view.layoutIfNeeded()
            let transition = ImageEditPresentTransition(transitionFromView: zoomScrollView.zoomView,
                                                        transitionToView: functionVC.overlayView.hollow.rectView)
            return transition
        }
        return nil
    }

    public func animationController(forDismissed dismissed: UIViewController)
    -> UIViewControllerAnimatedTransitioning? {
        if let functionVC = dismissed as? CropperViewController {
            if let croppeddImageView = functionVC.croppedImageView {
                return ImageEditDismissTransition(transitionFromView: croppeddImageView,
                                                  transitionToView: zoomScrollView.zoomView)
            }
        }
        return nil
    }

    // MARK: - SmartMosaic

    private func extractSmartMosaicInfo() {
        // smart mosaic功能下线
//        guard let dependency = ModuleDependency.dependency else {
//            return
//        }
//
//        if !dependency.isSmartMosaicEnabled() {
//            return
//        }
//
//        // Reset ocr state
//        updateSmartMosaicState(.loading)
//        guard let imageData = imageEditView.originalImage.pngData() else {
//            updateSmartMosaicState(.fail("failed to get imageData"))
//            return
//        }
//
//        dependency.requestImageSmartMosaic(pngData: imageData,
//                                           detectText: true,
//                                           detectAvatar: true) { [weak self] (result) in
//            guard let self = self else {
//                return
//            }
//            switch result {
//            case .success(let response):
//                self.updateSmartMosaicState(.ready)
//                self.imageEditView.addMosaicView.smartMosaicResponse = response
//            case .failure(let error):
//                self.updateSmartMosaicState(.fail(error.localizedDescription))
//            }
//        }
    }

    private func updateSmartMosaicState(_ state: SmartMosaicState) {
        self.smartMosaicState = state
        smartMosaicStateSubject.onNext(state)
    }
}

extension ImageEditViewController: FunctionBottomViewDelegate {
    func bottomView(_ bottomView: ImageEditFunctionBottomView, didInvoke panGesture: UIPanGestureRecognizer) {
        imageEditView.panGestureInvoke(gesture: panGesture)
    }

    func bottomView(_ bottomView: ImageEditFunctionBottomView, didChange lineWidth: CGFloat) {
        switch bottomView.currentFunction {
        case .line:
            imageEditView.addLineView.lineWidth = lineWidth
        case .mosaic:
            imageEditView.addMosaicView.updateLineWidth(lineWidth)
        case .text, .trim:
            break
        }
    }

    func bottomView(_ bottomView: ImageEditFunctionBottomView, didChange color: ColorPanelType) {
        switch bottomView.currentFunction {
        case .line:
            imageEditView.addLineView.currentColor = color
        case .text:
            imageEditView.addTextView.update(color: color)
        case .mosaic, .trim:
            break
        }
    }

    func bottomView(_ bottomView: ImageEditFunctionBottomView, didChange mosaicType: MosaicType) {
        imageEditView.addMosaicView.updateMosaicType(mosaicType)
    }

    func bottomView(_ bottomView: ImageEditFunctionBottomView, didChange selectionType: SelectionType) {
        imageEditView.addMosaicView.updateSelectionType(selectionType)
        // Try OCR again if it failed last time.
        if selectionType == .area,
           case .fail = smartMosaicState {
            extractSmartMosaicInfo()
        }
    }
}

extension ImageEditViewController: ImageEditBottomPanelDelegate {
    func bottomPanelDidClickRevert(_ bottomPanel: ImageEditBottomPanel) {
        editEventSubject.onNext(ImageEditEvent(event: "pic_edit_withdraw_click"))
        switch bottomPanel.currentFunction {
        case .mosaic, .line, .text:
            imageEditView.imageUndoManager?.undo()
        case .trim:
            break
        }
    }

    func bottomPanelDidClickFinish(_ bottomPanel: ImageEditBottomPanel) {
        // 如果图片没有编辑过且 EditView 没有被重建过的话
        // 直接返回 originalImage
        if !self.hadRebuildImageEditView,
           !self.imageEditView.imageEdited() {
            self.delegate?.finishButtonDidClicked(vc: self, editImage: originalImage)
            return
        }

        ignoreViewDidLayoutSubviews = true

        imageEditView.becomeDeactive()

        let originalFrame = imageEditView.frame
        imageEditView.frame.size = imageEditView.showRect.size
        imageEditView.layoutIfNeeded()
        // 限制生成的图片大小，避免内存暴涨
        let editImage = imageEditView.lu.screenshot(maxLength: 3840)
        imageEditView.frame = originalFrame

        self.ignoreViewDidLayoutSubviews = false

        self.delegate?.finishButtonDidClicked(vc: self, editImage: editImage ?? originalImage)
    }

    func bottomPanel(_ bottomPanel: ImageEditBottomPanel, didSelect function: BottomPanelFunction) {
        let preFunction = bottomPanel.currentFunction

        imageEditView.currentFunction = function
        functionView.currentFunction = function
        functionView.isHidden = false
        functionView.alpha = 1
        bottomPanel.currentFunction = function
        functionView.refreshSettings()

        if function == .trim {
            zoomScrollView.setZoomScale(1.0, animated: true)
            showCropperViewController(from: preFunction, completion: { [weak self] in
                self?.zoomScrollView.relayoutZoomView()
            })
        }
    }

    // swiftlint:disable function_body_length
    private func showCropperViewController(from: BottomPanelFunction,
                                           completion: (() -> Void)? = nil) {
        imageEditView.becomeDeactive()
        guard let compositeImage = imageEditView.compositeImage() else { return }
        let scale = compositeImage.size.width / imageEditView.originalImage.size.width
        let initialRect = CGRect(origin: imageEditView.showRect.origin * scale,
                                 size: imageEditView.showRect.size * scale)
        let config = CropperConfigure(squareScale: false,
                                      initialRect: initialRect)
        let cropperVC = CropperViewController(image: compositeImage, config: config)
        cropperVC.successCallback = { [weak self] (image, cropVC, rect) in
            guard let self = self, let cropperVC = cropVC as? CropperViewController else { return }
            if cropperVC.direction == .up {
                let scale = self.imageEditView.originalImage.size.width / compositeImage.size.width
                let rectInOriginImage = CGRect(origin: rect.origin * scale,
                                               size: rect.size * scale)
                let roundedRect = CGRect(
                    x: rectInOriginImage.minX.rounded(.towardZero),
                    y: rectInOriginImage.minY.rounded(.towardZero),
                    width: rectInOriginImage.width.rounded(.towardZero),
                    height: rectInOriginImage.height.rounded(.towardZero))
                self.imageEditView.set(showRect: roundedRect)
                self.zoomScrollView.originSize = self.imageEditView.showRect.size
                cropperVC.dismiss(animated: true, completion: nil)
            } else {
                self.hadRebuildImageEditView = true
                self.imageEditView = ImageEditView(image: image,
                                                   imageEditEventSubject: self.editEventSubject,
                                                   smartMosaicStateObservable:
                                                    self.smartMosaicStateSubject.asObservable())
                self.zoomScrollView.reset(zoomView: self.imageEditView, originSize: image.size)
                self.imageEditView.zoomScrollView = self.zoomScrollView
                self.imageEditView.delegate = self
                self.imageEditView.imageUndoManager?
                    .canUndoObservale
                    .subscribe(onNext: { [weak self] (isEnable) in
                        self?.bottomPanel.isRevertButtonEnable = isEnable
                    })
                    .disposed(by: self.disposeBag)
                // 旋转后图片被改变，重新获取智能马赛克信息
                self.extractSmartMosaicInfo()
                cropperVC.dismiss(animated: false, completion: nil)
            }
            self.bottomPanel(self.bottomPanel, didSelect: from)
        }
        cropperVC.cancelCallback = { [weak self] cropperVC in
            guard let self = self else { return }
            self.bottomPanel(self.bottomPanel, didSelect: from)
            cropperVC.dismiss(animated: false, completion: nil)
        }
        cropperVC.modalPresentationStyle = .overCurrentContext
        cropperVC.transitioningDelegate = self
        cropperVC.rx.methodInvoked(#selector(CropperViewController.editViewDidTapRotate(_:)))
            .subscribe(onNext: { [weak self] (_) in
                self?.editEventSubject.onNext(ImageEditEvent(event: "pic_edit_rotate"))
            })
            .disposed(by: disposeBag)

        present(cropperVC, animated: true, completion: completion)
    }
    // swiftlint:enable function_body_length
}

extension ImageEditViewController: ImageEditAddLineViewDelegate {
    func addLineViewDidTapped(_ addLineView: ImageEditAddLineView) {
        UIView.animate(withDuration: 0.3) {
            self.functionView.isHidden.toggle()
        }
    }

    func addLineViewDidBeginToDraw(_ addLineView: ImageEditAddLineView) {
        UIView.animate(withDuration: 0.3) {
            self.functionView.alpha = 0
        }
    }

    func addLineViewDrawing(_ addLineView: ImageEditAddLineView) {}

    func addLineViewDidFinishDrawing(_ addLineView: ImageEditAddLineView) {
        UIView.animate(withDuration: 0.3) {
            self.functionView.alpha = 1
        }
    }
}

extension ImageEditViewController: ImageEditViewDelegate {
    func imageEditView(_ imageEditView: ImageEditView, didChangeTo function: BottomPanelFunction) {
        bottomPanel(bottomPanel, didSelect: function)
    }
}

extension ImageEditViewController: ImageEditAddMosaicViewDelegate {
    func addMosaicViewDidTapped(_ addMosaicView: ImageEditAddMosaicView) {
        UIView.animate(withDuration: 0.3) {
            self.functionView.isHidden.toggle()
        }
    }

    func addMosaicViewDidBeginToDraw(_ addMosaicView: ImageEditAddMosaicView) {
        UIView.animate(withDuration: 0.3) {
            self.functionView.alpha = 0
        }
    }

    func addMosaicViewDrawing(_ addMosaicView: ImageEditAddMosaicView) {}

    func addMosaicViewDidFinishDrawing(_ addMosaicView: ImageEditAddMosaicView) {
        UIView.animate(withDuration: 0.3) {
            self.functionView.alpha = 1
        }
    }
}

extension ImageEditViewController: ImageEditAddTextViewDelegate {
    func addTextView(_ addTextView: ImageEditAddTextView, didTap highLightLabel: ImageEditAddTextLabel) {
        let vc = ImageEditAddTextViewController(editText: highLightLabel.editText)
        vc.cancelEditBlock = { [weak self] (vc) in
            highLightLabel.isHidden = false
            self?.closeButton.isHidden = false
            vc.dismiss(animated: true, completion: nil)
        }
        vc.finishEditBlock = { [weak self] (vc, editText) in
            highLightLabel.isHidden = false
            self?.closeButton.isHidden = false
            self?.imageEditView.addTextView.update(editText: editText, for: highLightLabel)
            self?.functionView.textColorPannelColor = editText.color
            vc.dismiss(animated: true, completion: nil)
        }
        vc.modalPresentationStyle = .overCurrentContext
        highLightLabel.isHidden = true
        closeButton.isHidden = true
        present(vc, animated: true, completion: nil)
    }

    func addTextViewCurrentColor(_ addTextView: ImageEditAddTextView) -> ColorPanelType {
        return functionView.textColorPannelColor
    }
}
