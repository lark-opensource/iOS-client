//
//  OCRRecognitionController.swift
//  LarkOCR
//
//  Created by 李晨 on 2022/8/23.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignColor
import RxSwift
import UniverseDesignIcon
import LarkUIKit
import LKCommonsLogging
import UniverseDesignToast
import LarkStorage
import LKCommonsTracker
import Reachability

public final class OCRRecognitionController: UIViewController, OCRImageViewDelegate {

    enum State {
        case unknown
        case recognizing
        case recognized
        case recognizeFailed
    }

    static let logger = Logger.log(OCRRecognitionController.self, category: "LarkOCR")

    public let zoomingViewContainer: UIView = UIView()
    public let zoomingView: ZoomingScrollView = ZoomingScrollView()
    public let bottomPanel: ImageActionPanel
    public let closeBtn: UIButton = UIButton()

    public let scanningImgLayer = CALayer()
    public let scanningAnimation = CABasicAnimation()
    private var scanningRect: CGRect = .zero

    // 是否使用动态变化的框选浮层，默认为 false，如果为 true 则保持选择框宽度固定，动态渲染
    // 如果为 false，则只渲染一次，选框宽度会跟随和图片放大缩小
    // 需要在 vc 展示前修改
    public var dynamicAnnotationLayer: Bool = false

    public private(set) var config: ImageOCRConfig

    private var showResult: [AnnotationBox] = []

    var selectNone: Bool = true {
        didSet {
            if oldValue == selectNone {
                return
            }
            self.bottomPanel.update(actions: self.getImageOCRActions(selectNone: selectNone))
        }
    }

    var state: State = .unknown {
        didSet {
            if oldValue == state {
                return
            }
            Self.logger.info("state change \(state)")
            if state == .recognizing {
                self.addScanAnimation(rect: self.view.bounds)
                self.bottomPanel.isHidden = true
                self.bottomHeightConstraint?.isActive = true
            } else if state == .recognized {
                self.removeScanAnimation()
                self.bottomPanel.isHidden = false
                self.bottomHeightConstraint?.isActive = false
            } else if state == .recognizeFailed {
                self.removeScanAnimation()
                let window = self.view.window
                self.dismiss(animated: false)
                if let window = window {
                    if let result = self.recognitionResult, result.lines.isEmpty {
                        UDToast.showFailure(with: BundleI18n.LarkOCR.Lark_IM_ImageToText_NoTextFound_Text, on: window)
                    } else if let reachability = Reachability(), reachability.connection != .none {
                        UDToast.showFailure(with: BundleI18n.LarkOCR.Lark_IM_ImageToText_FailedToExtractText_Toast, on: window)
                    } else {
                        UDToast.showFailure(with: BundleI18n.LarkOCR.Lark_Legacy_NetworkError, on: window)
                    }
                }
            }
        }
    }

    private var bottomHeightConstraint: Constraint?

    private var recognitionResult: ImageOCRResult?

    public var annotationLayer: OCRAnnotationShapeLayer?

    private var timer: CADisplayLink?

    private var retriedCount = 0
    private let maxRetryCount = 1

    private lazy var _store = KVStores.udkv(space: .global, domain: Domain.biz.core.child("OCR"))
    private static let store = \OCRRecognitionController._store

    @KVBinding(to: store, key: "showTapGuideKey", default: false)
    private var showTapGuide: Bool

    @KVBinding(to: store, key: "showScrollGuide", default: false)
    private var showScrollGuide: Bool

    public init(config: ImageOCRConfig) {
        self.config = config
        self.bottomPanel = ImageActionPanel(actions: [])
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UDColor.staticBlack

        self.view.addSubview(self.zoomingViewContainer)
        self.zoomingViewContainer.layer.masksToBounds = true
        self.zoomingViewContainer.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
        }

        self.zoomingView.setUpPhotoImageView(self.config.image)
        self.zoomingViewContainer.addSubview(self.zoomingView)
        self.zoomingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.zoomingView.photoImageView.delegate = self
        self.zoomingView.zoomingEndBlock = { [weak self] in
            guard let self = self else { return }
            self.showScrollGuideIfNeeded()
        }

        self.zoomingView.layoutSubviewsBlock = { [weak self] in
            guard let self = self else { return }
            if self.zoomingViewHasAnimation(),
               self.timer == nil,
               self.annotationLayer != nil {
                self.timer = CADisplayLink(target: self, selector: #selector(Self.updateTipLayerTimer))
                self.timer?.add(to: RunLoop.main, forMode: .common)
                Self.logger.info("start updateTipLayerTimer")
            }
            self.updateTipLayerIfNeeded()
        }

        if !self.dynamicAnnotationLayer {
            self.zoomingView.photoImageView.showAnnotationLayer(config: self.config.ocrAnnotationUIConfig)
        }

        self.view.addSubview(self.bottomPanel)
        self.bottomPanel.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(self.zoomingViewContainer.snp.bottom)
            self.bottomHeightConstraint = make.height.equalTo(0).priority(.required).constraint
        }
        self.bottomPanel.isHidden = true
        self.bottomPanel.update(actions: self.getImageOCRActions(selectNone: true))

        self.view.layer.addSublayer(self.scanningImgLayer)
        self.scanningImgLayer.isHidden = true

        self.view.addSubview(self.closeBtn)
        closeBtn.setImage(Resources.closeIcon, for: .normal)
        closeBtn.addTarget(self, action: #selector(clickClose), for: .touchUpInside)
        closeBtn.snp.makeConstraints { make in
            make.width.height.equalTo(34)
            make.left.equalTo(20)
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(28)
        }

        if self.dynamicAnnotationLayer {
            let annotationLayer = OCRAnnotationShapeLayer(config: self.config.ocrAnnotationUIConfig)
            self.annotationLayer = annotationLayer
            self.annotationLayer?.frame = self.view.bounds
            self.zoomingViewContainer.layer.addSublayer(annotationLayer)
        }

        self.startRecognizing()

        Tracker.post(TeaEvent("public_identity_select_content_view"))
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.timer?.invalidate()
        self.timer = nil
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.state == .recognizing {
            self.addScanAnimation(rect: self.view.bounds)
        }
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.annotationLayer?.frame = self.view.bounds
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: nil) { [weak self] (_) in
            guard let self = self else { return }
            if self.state == .recognizing {
                self.addScanAnimation(rect: self.view.bounds)
            }
        }
        super.viewWillTransition(to: size, with: coordinator)
    }

    private func addScanAnimation(rect: CGRect) {
        guard scanningRect != rect else {
            return
        }
        let image = Resources.scanning
        scanningRect = rect
        scanningImgLayer.isHidden = false
        scanningImgLayer.removeAllAnimations()
        scanningImgLayer.contents = image.cgImage
        scanningImgLayer.isHidden = false
        scanningImgLayer.frame = CGRect(x: (rect.width - image.size.width) / 2, y: -image.size.height, width: image.size.width, height: image.size.height)
        scanningAnimation.keyPath = "position.y"
        scanningAnimation.toValue = rect.height - image.size.height
        scanningAnimation.duration = 2
        scanningAnimation.repeatCount = Float.infinity
        scanningAnimation.isRemovedOnCompletion = false
        scanningImgLayer.add(scanningAnimation, forKey: "ScanAnimation")
    }

    private func removeScanAnimation() {
        scanningImgLayer.removeAllAnimations()
        scanningImgLayer.isHidden = true
        scanningRect = .zero
    }

    @objc
    func clickClose() {
        Self.logger.info("click close btn in recogintion vc")
        self.dismiss(animated: false)
    }

    private func startRecognizing() {
        guard self.state != .recognizing else {
            return
        }
        var recognitionSignal: Observable<ImageOCRResult>
        if let key = config.imageKey {
            var requestKey = key
            if key.contains(":"),
                let splitKey = key.split(separator: ":").last {
                requestKey = String(splitKey)
            }
            Self.logger.info("startRecognizing requestKey \(requestKey) key \(key) extra \(config.extra)")
            recognitionSignal = self.config.service.recognition(source: .key(requestKey), extra: config.extra)
        } else {
            Self.logger.info("startRecognizing request image \(config.image.size) extra \(config.extra)")
            recognitionSignal = self.config.service.recognition(source: .image(config.image), extra: config.extra)
        }

        self.state = .recognizing
        Observable.combineLatest(
            Observable<Bool>.just(true).delay(.seconds(2), scheduler: MainScheduler.instance),
            recognitionSignal
        )
        .observeOn(MainScheduler.instance)
        .subscribe { [weak self] (_, result) in
            guard let self = self else {
                return
            }
            self.recognitionResult = result
            if result.lines.isEmpty {
                Self.logger.info("recognition success but lines is empty")
                self.state = .recognizeFailed
            } else {
                Self.logger.info("recognition successed \(result.imageSize) lines \(result.lines.count) regions \(result.regions.count) entity \(result.entities.count)")
                UIView.performWithoutAnimation {
                    self.state = .recognized
                    let boxes = result.lines.enumerated().map { index, line -> AnnotationBox in
                        return AnnotationBox(
                            lineIndex: index,
                            str: line.string,
                            isSelected: false,
                            points: [line.rect.topLeft, line.rect.topRight, line.rect.bottomRight, line.rect.bottomLeft],
                            imageSize: result.imageSize
                        )
                    }
                    self.zoomingView.photoImageView.setResult(boxes)
                    self.showTapGuideIfNeeded()
                }
            }
            // OCR识别成功后向外抛出，目前用于审计埋点上报
            self.config.delegate?.ocrRecognizeResult(imageKey: self.config.imageKey ?? "", str: self.getAllOCRResult())
        } onError: { [weak self] error in
            guard let self else { return }
            let shouldRetry = self.retriedCount < self.maxRetryCount
            Self.logger.error("recognition failed \(error), shouldRetry: \(shouldRetry)")
            if shouldRetry {
                self.retriedCount += 1
                self.config.imageKey = nil // 重试时尝试直接使用 image 请求，绕过转发消息图片无权限问题
                self.state = .unknown
                self.startRecognizing()
            } else {
                self.state = .recognizeFailed
            }
        }
    }

    private func getImageOCRActions(selectNone: Bool) -> [ImageOCRAction] {
        if selectNone {
            return [
                ImageOCRAction(icon: Resources.copyIcon, title: BundleI18n.LarkOCR.Lark_IM_ImageToText_CopyAll_Button, titleColor: UDColor.primaryOnPrimaryFill, handler: { [weak self] in
                    guard let self = self else { return }
                    Self.logger.info("click copy btn")
                    Tracker.post(TeaEvent("public_identity_select_content_click", params: [
                        "click": "copy",
                        "has_select_content": "false",
                        "target": "none"
                    ]))
                    self.config.delegate?.ocrResultCopy(result: self.getAllOCRResult().string, from: self, dismissCallback: { [weak self] (result) in
                        if result {
                            self?.dismiss(animated: true)
                        }
                    })
                }),
                ImageOCRAction(icon: Resources.forwardIcon, title: BundleI18n.LarkOCR.Lark_IM_ImageToText_ForwardAll_Button, titleColor: UDColor.primaryOnPrimaryFill, handler: { [weak self] in
                    guard let self = self else { return }
                    Self.logger.info("click forward btn")
                    Tracker.post(TeaEvent("public_identity_select_content_click", params: [
                        "click": "forward",
                        "has_select_content": "false",
                        "target": "public_multi_select_share_view"
                    ]))
                    self.config.delegate?.ocrResultForward(result: self.getAllOCRResult().string, from: self, dismissCallback: { [weak self] (result) in
                        if result {
                            self?.dismiss(animated: true)
                        }
                    })
                }),
                ImageOCRAction(icon: Resources.extractIcon, title: BundleI18n.LarkOCR.Lark_IM_ImageToText_ExtractAll_Button, titleColor: UDColor.primaryOnPrimaryFill, handler: { [weak self] in
                    guard let self = self else { return }
                    Self.logger.info("click extract btn")
                    Tracker.post(TeaEvent("public_identity_select_content_click", params: [
                        "click": "select_accurate_character",
                        "has_select_content": "false",
                        "target": "public_select_accurate_character_view"
                    ]))
                    let vc = OCRExtractController(
                        result: self.getAllOCRResult(),
                        delegate: self.config.delegate
                    )
                    let navi = LkNavigationController(rootViewController: vc)
                    self.navigationController?.present(navi, animated: true)
                })
            ]
        } else {
            return [
                ImageOCRAction(icon: Resources.copyIcon, title: BundleI18n.LarkOCR.Lark_IM_ImageToText_CopySelectedText_Button, titleColor: UDColor.primaryOnPrimaryFill, handler: { [weak self] in
                    guard let self = self else { return }
                    Self.logger.info("click copy btn")
                    Tracker.post(TeaEvent("public_identity_select_content_click", params: [
                        "click": "copy",
                        "has_select_content": "true",
                        "target": "none"
                    ]))
                    self.config.delegate?.ocrResultCopy(result: self.getOCRResult().string, from: self, dismissCallback: { [weak self] (result) in
                        if result {
                            self?.dismiss(animated: true)
                        }
                    })
                }),
                ImageOCRAction(icon: Resources.forwardIcon, title: BundleI18n.LarkOCR.Lark_IM_ImageToText_ForwardSelectedText_Button, titleColor: UDColor.primaryOnPrimaryFill, handler: { [weak self] in
                    guard let self = self else { return }
                    Self.logger.info("click forward btn")
                    Tracker.post(TeaEvent("public_identity_select_content_click", params: [
                        "click": "forward",
                        "has_select_content": "true",
                        "target": "public_multi_select_share_view"
                    ]))
                    self.config.delegate?.ocrResultForward(result: self.getOCRResult().string, from: self, dismissCallback: { [weak self] (result) in
                        if result {
                            self?.dismiss(animated: true)
                        }
                    })
                }),
                ImageOCRAction(icon: Resources.extractIcon, title: BundleI18n.LarkOCR.Lark_IM_ImageToText_ExtractSelectedText_Button, titleColor: UDColor.primaryOnPrimaryFill, handler: { [weak self] in
                    guard let self = self else { return }
                    Self.logger.info("click extract btn")
                    Tracker.post(TeaEvent("public_identity_select_content_click", params: [
                        "click": "select_accurate_character",
                        "has_select_content": "true",
                        "target": "public_select_accurate_character_view"
                    ]))
                    let vc = OCRExtractController(
                        result: self.getOCRResult(),
                        delegate: self.config.delegate
                    )
                    let navi = LkNavigationController(rootViewController: vc)
                    self.navigationController?.present(navi, animated: true)
                })
            ]
        }
    }

    private func getOCRResult() -> NSAttributedString {
        guard let result = self.recognitionResult else {
            return NSAttributedString(string: "")
        }
        var lines: [ImageOCRResult.Line] = []
        self.zoomingView.photoImageView.results.map { box in
            if box.isSelected {
                lines.append(result.lines[box.lineIndex])
            }
        }
        return getOCRResultBy(lines: lines)
    }

    private func getAllOCRResult() -> NSAttributedString {
        guard let result = self.recognitionResult else {
            return NSAttributedString(string: "")
        }
        return getOCRResultBy(lines: result.lines)
    }

    private func getOCRResultBy(lines: [ImageOCRResult.Line]) -> NSAttributedString {

        func checkHasOneEntity(_ line: ImageOCRResult.Line, _ preLine: ImageOCRResult.Line) -> Bool {
            var hasOneEntity = false
            line.entities.forEach { entity in
                entity.lines.forEach { index, _ in
                    if preLine.index == index {
                        hasOneEntity = true
                    }
                }
            }
            return hasOneEntity
        }

        func getLineStr(result: NSMutableAttributedString, line: ImageOCRResult.Line) -> NSMutableAttributedString {
            result.append(.init(string: line.string))
            line.entities.forEach { entity in
                let range = (result.string as NSString).range(of: entity.string, options: .backwards)
                if range.location != NSNotFound {
                    if entity.type == .url {
                        var targetURL: URL?
                        if let url = URL(string: entity.string) {
                            if url.scheme == nil,
                               let newURL = URL(string: "https://\(entity.string)") {
                                targetURL = newURL
                            } else {
                                targetURL = url
                            }
                        } else if let url = URL(string: "https://\(entity.string)") {
                            targetURL = url
                        }
                        if let targetURL = targetURL {
                            result.addAttribute(.link, value: targetURL, range: range)
                        }
                    } else if entity.type == .phone, let url = URL(string: "tel://\(entity.string)") {
                        result.addAttribute(.link, value: url, range: range)
                    } else {
                        Self.logger.error("entity is not url")
                    }
                } else {
                    Self.logger.error("entity not found")
                }
            }
            return result
        }
        var result = NSMutableAttributedString()
        var currentRegionIndex = 0
        lines.enumerated().forEach { index, line in
            if index == 0 {
                result = getLineStr(result: result, line: line)
            } else if currentRegionIndex != line.regionIndex {
                result.append(.init(string: "\n"))
                result = getLineStr(result: result, line: line)
            } else {
                if let first = line.string.first,
                   first.isNumber || first.isASCII,
                    !checkHasOneEntity(line, lines[index - 1]){
                    result.append(.init(string: " "))
                }
                result = getLineStr(result: result, line: line)
            }
            currentRegionIndex = line.regionIndex
        }
        result.addAttribute(
            .foregroundColor,
            value: UIColor.ud.textTitle,
            range: .init(location: 0, length: result.string.count)
        )
        return result
    }

    public func ocrImageViewResultUpdate(boxex: [AnnotationBox], isFinish: Bool) {
        self.showResult = boxex
        self.updateTipLayerIfNeeded()

        // 更新选中按钮状态
        if isFinish {
            var selectNone = true
            boxex.forEach { box in
                if box.isSelected {
                    selectNone = false
                }
            }
            self.selectNone = selectNone
        }
    }

    fileprivate func zoomingViewHasAnimation() -> Bool {
        if !(self.zoomingView.layer.animationKeys() ?? []).isEmpty {
            return true
        }
        if !(self.zoomingView.imageViewContainer.layer.animationKeys() ?? []).isEmpty {
            return true
        }
        return false
    }

    @objc
    fileprivate func updateTipLayerTimer() {
        if !self.zoomingViewHasAnimation() {
            Self.logger.info("end updateTipLayerTimer")
            self.timer?.invalidate()
            self.timer = nil
        }
        self.updateTipLayerIfNeeded()
    }

    private func updateTipLayerIfNeeded() {
        guard let annotationLayer = self.annotationLayer else {
            return
        }
        var bounds = self.zoomingView.bounds
        if self.timer != nil,
           let presentationBounds = self.zoomingView.layer.presentation()?.bounds {
            bounds = presentationBounds
        }
        var frame = self.zoomingView.imageViewContainer.frame
        if self.timer != nil,
           let presentationFrame = self.zoomingView.imageViewContainer.layer.presentation()?.frame {
            frame = presentationFrame
        }
        func pointTransform(point: CGPoint, imageSize: CGSize) -> CGPoint {
            var x = point.x * frame.width / imageSize.width
            var y = point.y * frame.height / imageSize.height

            return CGPoint(
                x: (x - bounds.origin.x + frame.origin.x),
                y: (y - bounds.origin.y + frame.origin.y)
            )
        }

        let results = self.showResult.map { box -> AnnotationBox in
            var box = box
            let points = box.points.map { point -> CGPoint in
                return pointTransform(point: point, imageSize: box.imageSize)
            }
            let path = UIBezierPath(roundedPolygon: points, radius: 2)
            box.path = path
            return box
        }
        annotationLayer.results = results
        annotationLayer.display()
    }

    private func showTapGuideIfNeeded() {
        if self.showTapGuide {
            return
        }
        if !OCRGuideView.checkCanShowGuide(in: self.view) {
            return
        }
        Self.logger.info("showTapGuide")
        self.showTapGuide = true
        let guideView = OCRGuideView(
            image: Resources.guide1,
            text: BundleI18n.LarkOCR.Lark_IM_ImageToText_TapOrDragToSelectText
        )
        guideView.showIn(view: self.view)
    }

    private func showScrollGuideIfNeeded() {
        guard self.state == .recognized else {
            return
        }
        if self.showScrollGuide {
            return
        }
        if !OCRGuideView.checkCanShowGuide(in: self.view) {
            return
        }
        Self.logger.info("showScrollGuide")
        self.showScrollGuide = true
        let guideView = OCRGuideView(
            image: Resources.guide2,
            text: BundleI18n.LarkOCR.Lark_IM_ImageToText_ScrollWith2Fingers_Text
        )
        guideView.showIn(view: self.view)
    }
}
