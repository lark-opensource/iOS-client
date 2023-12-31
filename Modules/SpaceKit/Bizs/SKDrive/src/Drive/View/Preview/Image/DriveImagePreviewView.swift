//
//  DriveImagePreviewView.swift
//  Alamofire
//
//  Created by bupozhuang on 2019/6/2.

import UIKit
import SnapKit
import KingfisherWebP
import Kingfisher
import SKCommon
import SKUIKit
import SKFoundation
import EENavigator
import RxCocoa

protocol DriveImagePreviewViewDelegate: NSObjectProtocol {
    func imagePreviewViewBlankDidTap(_ view: DriveImagePreviewView)
    func imagePreviewView(_ view: DriveImagePreviewView, enter mode: DriveImagePreviewMode)
    func imagePreviewView(_ view: DriveImagePreviewView, commentAt area: DriveAreaComment.Area)
    func imagePreviewView(_ view: DriveImagePreviewView, didSelectedAt area: DriveAreaComment)
    func imagePreviewViewDeselected(_ view: DriveImagePreviewView)
    func imagePreviewViewImageDidUpdated(_ view: DriveImagePreviewView)
    func imagePreviewViewFailed() // 加载图片失败
}

protocol ImagePreviewViewProtocol: UIView {
    func setupImageView(path: SKFilePath)
    func setupImageView(image: UIImage?)
    func updatePreviewStratery(_ stratery: SKImagePreviewStrategy)

    // 区域评论相关
    var showComment: Bool { get set }
    var canComment: Bool { get set }
    var commentDisplayView: DriveSelectionsDisplayView { get set }
    func selectArea(at commentId: String)
    func selectArea(at index: Int)
    func deselectArea()
    func showAreaDisplayView(_ show: Bool)
    func showAreaEditView(_ show: Bool)
    func updateAreas(_ areas: [DriveAreaComment])

    var delegate: DriveImagePreviewViewDelegate? { get set }
    var currentZoomScale: BehaviorRelay<CGFloat>? { get }
    func setZoomScale(_ scale: CGFloat, animated: Bool)
    func didTapBlank(_ callback: @escaping (() -> Void))
}

class DriveImagePreviewView: UIView, ImagePreviewViewProtocol {

    private let editScale: CGFloat = 2.0

    var showComment: Bool = true {
        didSet {
            DocsLogger.driveInfo("showComment did set", extraInfo: ["showComment": showComment])
            commentDisplayView.isHidden = !showComment
        }
    }
    var canComment: Bool = true
    
    var tapBlankCallback: (() -> Void)?
    
    var commentDisplayView = DriveSelectionsDisplayView()
    
    private var currentView: BaseSKImageView?
    
    private lazy var displayViewV2: SKImagePreviewViewV2 = {
        let view = SKImagePreviewViewV2(frame: .zero,
                                      previewStratery: DriveImagePreviewStrategy
                                        .defaultStrategy(for: Navigator.shared.mainSceneWindow?.bounds.size ?? .zero))
        view.delegate = self
        return view
    }()
    
    private lazy var displayView: SKImagePreviewView = {
        let view = SKImagePreviewView(frame: .zero,
                                      previewStratery: DriveImagePreviewStrategy
                                        .defaultStrategy(for: Navigator.shared.mainSceneWindow?.bounds.size ?? .zero))
        view.delegate = self
        return view
    }()

    private var imageDidLoad: Bool = false
    weak var addSelectionView: DriveAddSelectionView?
    weak var delegate: DriveImagePreviewViewDelegate?

    private var path: SKFilePath? {
        didSet {
            if UserScopeNoChangeFG.TYP.DriveIMImageEable {
                setupPreviewImageView(displayViewV2)
            } else {
                setupPreviewImageView(displayView)
            }
            currentView?.path = path
        }
    }
    private var linImage: UIImage? {
        didSet {
            if UserScopeNoChangeFG.TYP.DriveIMImageEable {
                setupPreviewImageView(displayViewV2)
                displayViewV2.updateImage(linImage)
            } else {
                setupPreviewImageView(displayView)
                displayView.updateImage(linImage)
            }
        }
    }

    var currentZoomScale: BehaviorRelay<CGFloat>? {
        return currentView?.currentZoomScale
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    deinit {
        commentDisplayView.invalideObserver()
    }

    private func commonInit() {
        backgroundColor = .clear
    }
    
    private func setupPreviewImageView(_ baseImageView: BaseSKImageView) {
        guard self.currentView == nil else { return }
        self.currentView = baseImageView
        addSubview(baseImageView)
        commentDisplayView.delegate = self
        commentDisplayView.isUserInteractionEnabled = false
        baseImageView.contentView.addSubview(commentDisplayView)
        baseImageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        commentDisplayView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    private func commentEnable() -> Bool {
        let orientation = LKDeviceOrientation.convertMaskOrientationToDevice(UIApplication.shared.statusBarOrientation)
        // 手机横屏下不支持评论
        if orientation.isLandscape && SKDisplay.phone {
            return false
        }
        return true
    }

    func setupImageView(path: SKFilePath) {
        self.path = path
    }

    func setupImageView(image: UIImage?) {
        self.linImage = image
    }

    func setZoomScale(_ scale: CGFloat, animated: Bool) {
        currentView?.setZoomScale(scale, animated: animated)
    }

    func updatePreviewStratery(_ stratery: SKImagePreviewStrategy) {
        currentView?.updatePreviewStratery(stratery)
    }
}

// MARK: - SKImagePreviewViewDelegate
extension DriveImagePreviewView: SKImagePreviewViewDelegate {
    func imagePreviewViewUpdated(_ view: BaseSKImageView, imagviewFrame: CGRect) {
        addSelectionView?.selectionEditView?.frame = view.convert(imagviewFrame, to: self)
    }
    
    func imagePreviewViewSuccess(_ view: BaseSKImageView) {
        delegate?.imagePreviewViewImageDidUpdated(self)
    }
    
    func imagePreviewViewFailed(_ view: BaseSKImageView) {
        delegate?.imagePreviewViewFailed()
    }
    
    func imagePreviewViewDidTap(_ view: BaseSKImageView, location: CGPoint) {
        let touchPoint = view.convert(location, to: commentDisplayView)
        if let touchArea = commentDisplayView.touchArea(with: touchPoint) {
            delegate?.imagePreviewView(self, didSelectedAt: touchArea)
        } else if let callback = tapBlankCallback {
            callback()
        } else {
            if !commentDisplayView.isSelected() { // 局部评论不是选中态
                delegate?.imagePreviewViewBlankDidTap(self)
            } else { // 局部评论是选中态，移除选中效果
                delegate?.imagePreviewViewDeselected(self)
            }
            commentDisplayView.deSelectArea()
        }
    }
    
    func didTapBlank(_ callback: @escaping (() -> Void)) {
        self.tapBlankCallback = callback
    }
    
    /// 长按进入选区编辑状态
    func imagePreviewDidLongPress(_ view: BaseSKImageView, location: CGPoint, zoomScale: CGFloat) {
        guard canComment, commentEnable(), !commentDisplayView.isSelected() else {
            DocsLogger.driveInfo("detect long press", extraInfo: ["canComment": canComment,
                                                             "isSelected": commentDisplayView.isSelected()])
            return
        }

        var position = view.convert(location, to: view.contentView)
        position = CGPoint(x: position.x * zoomScale, y: position.y * zoomScale)
        position = position.relativePoint(in: view.contentView.frame)
        createArea(at: position)
    }
}

// MARK: - Area Comment
extension DriveImagePreviewView {
    /// 在以relativePosition为中心的位置添加局部评论框
    ///
    /// - Parameter relativePosition: 相对位置，百分比表示
    func createArea(at relativePosition: CGPoint) {
        DocsLogger.debug("createArea at \(relativePosition)")
        showEditAreaView(at: relativePosition)
    }

    func showAreaEditView(_ show: Bool) {
        if show {
            showEditAreaView()
        } else {
            dismissEditAreaView()
        }
    }
    func showAreaDisplayView(_ show: Bool) {
        guard commentEnable() else {
            showComment = false
            return
        }
        DocsLogger.driveInfo("showComment", extraInfo: ["show": show])
        showComment = show
    }

    func updateAreas(_ areas: [DriveAreaComment]) {
        commentDisplayView.setAreas(areas)
    }
    func deselectArea() {
        commentDisplayView.deSelectArea()
    }
    func selectArea(at index: Int) {
        commentDisplayView.selectArea(at: index)
    }
    func selectArea(at commentId: String) {
        commentDisplayView.selectArea(at: commentId)
    }
}

// MARK: - DriveSelectionContainerDelegate
extension DriveImagePreviewView: DriveSelectionsDisplayDelegate {
    func selectionsDisplayView(_ view: DriveSelectionsDisplayView, didSelectedAt area: DriveAreaComment) {
        DocsLogger.debug("did select region: \(area)")
        delegate?.imagePreviewView(self, didSelectedAt: area)
    }
}

// MARK: - Selections
extension DriveImagePreviewView {
    /// 展示编辑选区蒙层
    ///
    /// - parameter position: 相对位置，百分比表示
    func showEditAreaView(at position: CGPoint? = nil) {
        delegate?.imagePreviewView(self, enter: .selection)
        guard let currentView = currentView else { return }
        let imageView = currentView.contentView
        guard let rect = imageView.superview?.convert(imageView.frame, to: self) else { return }
        self.addSelectionView?.removeFromSuperview()
        let view = DriveAddSelectionView()
        view.show(on: self, contentRect: rect, selectionPosition: position)
        view.closeBtnDidClick = {[weak self] selectionView in
            guard let self = self else { return }
            self.dismissEditAreaView()
        }
        view.commentBtnClick = {[weak self] _, area in
            guard let self = self else { return }
            self.delegate?.imagePreviewView(self, commentAt: area)
        }
        view.touchToCreateArea = {[weak self] _, position in
            guard let self = self else { return }
            let relativePosition = position.relativePoint(in: imageView.frame)
            self.addSelectionView?.createArea(at: relativePosition)
            self.configForSelectionMode(touchPoint: relativePosition)
        }
        self.addSelectionView = view
        self.configForSelectionMode(touchPoint: position)
    }

    func dismissEditAreaView() {
        addSelectionView?.removeFromSuperview()
        self.delegate?.imagePreviewView(self, enter: .normal)
        self.configForNormalMode()

    }

    /// 进入编辑选区模式时配置scrollview属性
    func configForSelectionMode(touchPoint: CGPoint?) {
        guard let currentView = currentView else { return }
        if let point = touchPoint?.absolutedPoint(in: currentView.contentView.frame) {
            currentView.scale(to: point, scale: editScale, animated: false)
        }
        currentView.bounces = false
        currentView.isScrollEnabled = true
        currentView.enableGuesture = false
        commentDisplayView.isHidden = true
    }
    
    /// 退出编辑选区模式时配置scroview属性
    func configForNormalMode() {
        guard let currentView = currentView else { return }
        currentView.bounces = true
        currentView.enableGuesture = true
        currentView.setZoomScale(1.0, animated: true)
        commentDisplayView.isHidden = false
    }
}
