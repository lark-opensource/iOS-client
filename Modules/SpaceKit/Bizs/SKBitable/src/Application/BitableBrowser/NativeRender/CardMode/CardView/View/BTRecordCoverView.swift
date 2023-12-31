//
//  BTRecordCoverView.swift
//  SKBitable
//
//  Created by zoujie on 2023/11/8.
//

import SKFoundation
import RxSwift
import UniverseDesignColor
import UniverseDesignIcon

final class BTRecordCoverView: UIView {
    struct Const {
        static let videoPlayIconSize: CGFloat = 40
        static let videoPlayImageSize = CGSize(width: 16, height: 16)
        
        static let loadingViewSize = CGSize(width: 36, height: 36)
        
        struct EmptyView {
            static let rightBlobWidth: CGFloat = 174
            static let rightBlobLeftOffset: CGFloat = 25
            static let rightBlodTopOffset: CGFloat = 25
            
            static let smallBlobWidth: CGFloat = 21
            static let smallBlobLeftOffset: CGFloat = 16
            static let smallBlodTopOffset: CGFloat = 16
        }
    }
    private var disposeBag = DisposeBag()
    
    var clickCallback: (() -> Void)?
    
    private lazy var fileIcon = UIImageView().construct { it in
        it.contentMode = .scaleAspectFill
    }
    private lazy var fileIconBgView = UIView().construct { it in
        it.isHidden = true
    }
    
    private var currentData: BTAttachmentModel? = nil
    private var noAttachmentBallsView: BTAttachmentEmptyView?
    
    private lazy var noAttachmentBackgroundView = UIView().construct { it in
        it.backgroundColor = UDColor.bgBodyOverlay
        it.isUserInteractionEnabled = false
    }

    private lazy var noAttachmentBackgroundLayer = CAGradientLayer().construct { it in
        it.colors = [UDColor.primaryPri50.cgColor, UDColor.bgBody.cgColor]
        it.startPoint = CGPoint(x: 0.5, y: 0)
        it.endPoint = CGPoint(x: 0.5, y: 1)
    }
    
    private lazy var imageView = UIImageView().construct { it in
        it.contentMode = .scaleAspectFill
        it.isUserInteractionEnabled = true
    }
    
    private lazy var loadingView = UIImageView().construct { it in
        let loadingIcon = UDIcon.getIconByKey(
            .loadingOutlined,
            iconColor: UIColor.ud.iconDisabled,
            size: Const.loadingViewSize
        )
        it.image = loadingIcon
        it.isHidden = true
    }

    private lazy var videoPlayIcon = UIView().construct { it in
        it.layer.masksToBounds = true
        it.layer.cornerRadius = Const.videoPlayIconSize * 0.5
        it.isHidden = true
        it.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.7)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        noAttachmentBackgroundLayer.frame = noAttachmentBackgroundView.bounds
    }
    
    private func setupUI() {
        self.addSubview(imageView)
        self.addSubview(loadingView)
        self.addSubview(noAttachmentBackgroundView)
        
        self.layer.borderWidth = 0
        self.layer.ud.setBorderColor(UDColor.lineBorderCard)
        imageView.addSubview(videoPlayIcon)
        imageView.addSubview(fileIconBgView)
        imageView.addSubview(fileIcon)
        setupVideoBtn()
        
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        loadingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(Const.loadingViewSize)
        }
        
        videoPlayIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(Const.videoPlayIconSize)
        }
        
        fileIconBgView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        fileIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(40)
        }
        
        let leftBlobData = BTAttachmentEmptyView.BallItem(blobWidth: 0,
                                                          topOffset: 0,
                                                          leftOffset: 0)
        let rightBlobData = BTAttachmentEmptyView.BallItem(blobWidth: Const.EmptyView.rightBlobWidth,
                                                           topOffset: Const.EmptyView.rightBlodTopOffset,
                                                           leftOffset: Const.EmptyView.rightBlobLeftOffset)
        let smallBlobData = BTAttachmentEmptyView.BallItem(blobWidth: Const.EmptyView.smallBlobWidth,
                                                           topOffset: Const.EmptyView.smallBlodTopOffset,
                                                           leftOffset: Const.EmptyView.smallBlobLeftOffset)

        let ballsView = BTAttachmentEmptyView(leftBlobData: leftBlobData,
                                              rightBlobData: rightBlobData,
                                              smallBlobData: smallBlobData)
        self.addSubview(ballsView)
        ballsView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        ballsView.layer.masksToBounds = true
        ballsView.isHidden = true
        ballsView.isUserInteractionEnabled = false
        noAttachmentBallsView = ballsView
        noAttachmentBallsView?.isUserInteractionEnabled = false
        
        noAttachmentBackgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        noAttachmentBackgroundView.layer.addSublayer(noAttachmentBackgroundLayer)
        noAttachmentBackgroundView.isHidden = true
        
        self.layer.cornerRadius = 6
        self.clipsToBounds = true
        // 封面长按应该不响应
        let longPressGes = UILongPressGestureRecognizer(target: self, action: nil)
        longPressGes.cancelsTouchesInView = true
        self.imageView.addGestureRecognizer(longPressGes)
        let tapGes = UITapGestureRecognizer(target: self, action: #selector(didClick))
        tapGes.require(toFail: longPressGes)
        self.imageView.addGestureRecognizer(tapGes)
    }
    
    @objc
    func didClick() {
        self.clickCallback?()
    }
    
    private func setupVideoBtn() {
        let image = UDIcon.playFilled.ud.resized(to: Const.videoPlayImageSize).ud.withTintColor(UDColor.staticWhite)
        let imageView = UIImageView(image: image)
        videoPlayIcon.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.size.equalTo(Const.videoPlayImageSize)
            make.center.equalToSuperview()
        }
    }
    
    private func startAnimation() {
        DispatchQueue.main.async {
            self.loadingView.isHidden = false
            BTUtil.startRotationAnimation(view: self.loadingView)
            self.fileIcon.isHidden = true
            self.videoPlayIcon.isHidden = true
        }
    }

    private func stopAnimation(success: Bool, showFileIcon: Bool) {
        DispatchQueue.main.async {
            self.loadingView.isHidden = true
            BTUtil.stopRotationAnimation(view: self.loadingView)
            self.fileIcon.isHidden = !showFileIcon
            self.fileIconBgView.isHidden = !showFileIcon
            if showFileIcon {
                self.imageView.image = nil
                self.fileIconBgView.backgroundColor = self.currentData?.backgroundColor ?? .clear
                self.fileIcon.image = self.currentData?.iconImage
            }
            
            self.layer.borderWidth = success ? 0.5 : 0
            self.videoPlayIcon.isHidden = self.currentData?.fileType.isVideo == false
        }
    }
    
    func showEmptyView(index: Int?) {
        guard let index = index, let emptyView = self.noAttachmentBallsView else {
            return
        }
        
        guard let (top, bottom) = emptyView.updateNoAttachmentBallsViewColor(index: index) else {
            return
        }
        
        noAttachmentBackgroundLayer.colors = [top.cgColor, bottom.cgColor]
        noAttachmentBackgroundView.isHidden = false
        emptyView.isHidden = false
        self.bringSubviewToFront(emptyView)
        self.imageView.isHidden = true
        self.isUserInteractionEnabled = false
        self.layer.borderWidth = 0
    }
    
    private func hideEmptyView() {
        noAttachmentBackgroundView.isHidden = true
        noAttachmentBallsView?.isHidden = true
        self.imageView.isHidden = false
        self.isUserInteractionEnabled = true
    }
    
    func load(model: CardRecordCoverModel?, thumbnailProvider: BTAttachmentThumbnailProvider) {
        guard let data = model?.cover else {
            showEmptyView(index: model?.index)
            return
        }
        
        hideEmptyView()
        
        guard currentData != data else {
            return
        }
        
        disposeBag = DisposeBag()
        currentData = data
        videoPlayIcon.isHidden = !data.fileType.isVideo
        DocsLogger.btInfo("[BTRecordCoverView] attachment thumbnail start load")
        guard BTAttachmentField.AttachmentCell.hasFilePreviewPermission(token: data.attachmentToken) else {
            // 没有文件预览权限，不加载预览图
            DocsLogger.btInfo("[BTRecordCoverView] attachment thumbnail no permission")
            stopAnimation(success: false, showFileIcon: true)
            return
        }
        
        if data.prefersThumbnail {
            startAnimation()
            thumbnailProvider.fetchThumbnail(info: data, resumeBag: disposeBag) { [weak self] thumbnailImage, token, error in
                if let error = error {
                    self?.stopAnimation(success: false, showFileIcon: true)
                    DocsLogger.btError("[BTRecordCoverView] attachment thumbnail error: \((error as NSError).localizedDescription)")
                } else if let thumbnailImage = thumbnailImage, self?.currentData?.attachmentToken == token { // token 校验，时序问题
                    self?.setImage(thumbnailImage, token)
                    self?.stopAnimation(success: true, showFileIcon: false)
                    DocsLogger.btInfo("[BTRecordCoverView] attachment thumbnail start fetch success from drive")
                } else {
                    DocsLogger.btError("[BTRecordCoverView] attachment thumbnail fail: error nil，image nil")
                    self?.stopAnimation(success: false, showFileIcon: true)
                }
            }
        } else {
            stopAnimation(success: false, showFileIcon: true)
        }
    }
    
    private func setImage(_ image: UIImage, _ token: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, token == self.currentData?.attachmentToken else {
                return
            }
            self.imageView.image = image
        }
    }

    func resetForReuse() {
        self.imageView.image = nil
        self.fileIcon.image = nil
        self.currentData = nil
        self.videoPlayIcon.isHidden = true
    }
}
