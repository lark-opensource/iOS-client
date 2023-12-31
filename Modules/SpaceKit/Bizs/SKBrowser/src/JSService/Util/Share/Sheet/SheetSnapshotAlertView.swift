//
//  SheetSnapshotAlertView.swift
//  SKBrowser
//
//  Created by 吴珂 on 2020/10/23.
//  


import Foundation
import UIKit
import SnapKit
import RxCocoa
import RxSwift
import SKCommon
import SKResource
import SKFoundation
import Lottie
import SKUIKit
import UniverseDesignColor
import UniverseDesignIcon

class SheetSnapshotAlertView: UIView {
    
    var wrapperView = UIView().construct { (it) in
        it.backgroundColor = UIColor.ud.N50
        it.layer.cornerRadius = 10
        it.layer.masksToBounds = true
    }
    
    var imageViewSize: CGSize
    
    lazy var titleLabel: UILabel = {
        return UILabel(frame: .zero).construct { (it) in
            it.font = UIFont.systemFont(ofSize: 16).medium
            it.text = ""
            it.textAlignment = .center
            it.textColor = UIColor.ud.N900
            it.numberOfLines = 0
        }
    }()
    
    lazy var messageLabel: UILabel = {
        return UILabel(frame: .zero).construct { (it) in
            it.font = UIFont.systemFont(ofSize: 14)
            it.lineBreakMode = .byTruncatingTail
            it.textAlignment = .center
            it.numberOfLines = 0
            it.textColor = UIColor.ud.N900
        }
    }()
    
    lazy var middleLine = UIView().construct { (it) in
        it.backgroundColor = UIColor.ud.N300
    }
    
    lazy var verticalLine = UIView().construct { (it) in
        it.backgroundColor = UIColor.ud.N300
    }
    
    
    var operationView = UIView()
    var imageWrapperView = UIView()
    
    var loadingView = AnimationViews.sheetAlertLoadingAnimation.construct { (it) in
        it.autoReverseAnimation = false
    }
    
    var loadingWrapperView = UIView().construct { (it) in
        it.backgroundColor = UIColor.ud.N50
    }
    
    var imagePreview: LongPicPreview?
    
    var dismissButton = UIButton()
    
    var dismissAction: (() -> Void)?
    
    var shareAction: (() -> Void)?
    var saveAction: (() -> Void)?

    var ratio: CGFloat //图片宽高比
    
//    var loadingView: LOTAnimationView = AnimationViews.sheetExportAnimation
    
    lazy var contentBackgroundView: UIView = {
        return UIView(frame: .zero).construct { (it) in
            it.backgroundColor = UIColor.ud.N100
            it.layer.cornerRadius = 10
        }
    }()
    
    lazy var saveButton: UIButton = {
        return UIButton(type: .custom).construct { (it) in
            it.titleLabel?.font = UIFont.systemFont(ofSize: 17)
            it.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
            it.imageView?.contentMode = .scaleAspectFit
            it.imageView?.layer.allowsEdgeAntialiasing = true
            it.setTitleColor(UIColor.ud.N900, for: .normal)
            it.addTarget(self, action: #selector(save), for: .touchUpInside)
            it.setBackgroundImage(backgroundImageWithColor(UIColor.ud.N300), for: .highlighted)
            it.setTitleColor(UIColor.ud.N400, for: .disabled)
        }
    }()
    
    lazy var shareButton: UIButton = {
        return UIButton(type: .custom).construct { (it) in
            it.titleLabel?.font = UIFont.systemFont(ofSize: 17)
            it.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
            it.imageView?.contentMode = .scaleAspectFit
            it.imageView?.layer.allowsEdgeAntialiasing = true
            it.setTitleColor(UIColor.ud.colorfulBlue, for: .normal)
            
            it.addTarget(self, action: #selector(share), for: .touchUpInside)
            it.setBackgroundImage(backgroundImageWithColor(UIColor.ud.N300), for: .highlighted)
            it.setTitleColor(UIColor.ud.N400, for: .disabled)
        }
    }()
    
    lazy var closeButton: UIButton = {
        return UIButton(type: .custom).construct { (it) in
            it.imageView?.contentMode = .scaleAspectFit
            it.imageView?.layer.allowsEdgeAntialiasing = true
            it.setImage(UDIcon.moreCloseOutlined.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill), for: [.normal, .highlighted])
            it.addTarget(self, action: #selector(dismiss), for: .touchUpInside)
        }
    }()
    
    let disposeBag = DisposeBag()
    
    init(frame: CGRect, imageViewSize: CGSize, ratio: CGFloat) {
        self.imageViewSize = imageViewSize
        self.ratio = ratio
        super.init(frame: frame)
        
        setupLayout()
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupLayout() {
        
        addSubview(wrapperView)
        wrapperView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
        }
        
        wrapperView.addSubview(titleLabel)
        wrapperView.addSubview(messageLabel)
        wrapperView.addSubview(imageWrapperView)
        wrapperView.addSubview(loadingWrapperView)
        wrapperView.addSubview(shareButton)
        wrapperView.addSubview(saveButton)
        wrapperView.addSubview(contentBackgroundView)
        wrapperView.addSubview(middleLine)
        wrapperView.addSubview(verticalLine)
        
        
        
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(20)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }
        
        messageLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.left.equalToSuperview().offset(24)
            make.right.equalToSuperview().offset(-24)
        }
        
        imageWrapperView.snp.makeConstraints { (make) in
            make.top.equalTo(messageLabel.snp.bottom).offset(20)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.width.equalTo(imageWrapperView.snp.height).multipliedBy(ratio).priority(.high)
            make.height.lessThanOrEqualTo(self.imageViewSize.height)
            //要求图像区域高度最小为26
        }
        
        loadingWrapperView.snp.makeConstraints { (make) in
            make.edges.equalTo(imageWrapperView)
        }
        
        middleLine.snp.makeConstraints { (make) in
            make.top.equalTo(imageWrapperView.snp.bottom).offset(20)
            make.left.right.equalToSuperview()
            make.height.equalTo(1)
        }

        saveButton.snp.makeConstraints { (make) in
            make.top.equalTo(middleLine.snp.bottom)
            make.left.equalToSuperview()
            make.right.equalTo(verticalLine.snp.left)
            make.height.equalTo(49.5)
            make.width.equalTo(shareButton)
            make.bottom.equalToSuperview()
        }
        
        verticalLine.snp.makeConstraints { (make) in
            make.top.equalTo(saveButton)
            make.bottom.equalTo(saveButton)
            make.right.equalTo(shareButton.snp.left)
            make.width.equalTo(1)
            make.height.equalTo(saveButton)
        }

        shareButton.snp.makeConstraints { (make) in
            make.top.equalTo(saveButton)
            make.right.equalToSuperview()
            make.height.equalTo(saveButton)
            make.width.equalTo(saveButton)
            make.bottom.equalToSuperview()
        }
        
        addSubview(closeButton)
        closeButton.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 28, height: 28))
            make.top.equalTo(wrapperView.snp.bottom).offset(21)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        loadingWrapperView.addSubview(loadingView)
        
        loadingView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 24, height: 24))
            make.center.equalToSuperview()
        }
    }
    
    func setupWithAlertInfo(_ info: SheetSnapshotAlertInfo) {
        loadingView.play()
        titleLabel.text = info.title
        
        let paraph = NSMutableParagraphStyle()
        paraph.lineSpacing = 6
        let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14),
                          NSAttributedString.Key.paragraphStyle: paraph,
                          NSAttributedString.Key.foregroundColor: UIColor.ud.N900
        ]
        messageLabel.attributedText = NSAttributedString(string: info.messages, attributes: attributes)
        
        
        saveButton.setTitle(BundleI18n.SKResource.Doc_Facade_Save, for: .normal)
        shareButton.setTitle(BundleI18n.SKResource.Doc_List_Share, for: .normal)
    }
    
    
    func updateImage(_ filePath: SKFilePath) {
        let longPicPreView = LongPicPreview(filePath, delegate: self)
        imageWrapperView.addSubview(longPicPreView)
        longPicPreView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        imagePreview = longPicPreView
    }
    
    @objc
    func dismiss() {
        if let dismissAction = dismissAction {
            dismissAction()
        }
    }
    
    @objc
    func share() {
        if let shareAction = shareAction {
            shareAction()
        }
    }
    
    @objc
    func save() {
        if let saveAction = saveAction {
            saveAction()
        }
    }
    
    func changeOperationButton(_ isEnabled: Bool) {
        shareButton.isEnabled = isEnabled
        saveButton.isEnabled = isEnabled
    }
    
    func backgroundImageWithColor(_ color: UIColor) -> UIImage? {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        let context = UIGraphicsGetCurrentContext()
        color.setFill()
        context?.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

extension SheetSnapshotAlertView: LongPicPreviewDelegate {
    func animationView(_ preview: LongPicPreview) -> LongPicAnimationViewProtocol {
        return UIActivityIndicatorView()
    }
    
    func loadImageFailed(_ preview: LongPicPreview) {
        DocsLogger.info("sheet alert view 图片加载失败")
    }
    
    func didLoadFirstFrame(_ preview: LongPicPreview) {
        DispatchQueue.main.async {        
            self.loadingView.stop()
            self.loadingWrapperView.removeFromSuperview()
        }
    }
}
