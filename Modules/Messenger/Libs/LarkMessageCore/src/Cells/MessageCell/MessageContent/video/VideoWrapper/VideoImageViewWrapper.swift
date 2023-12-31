//
//  VideoView.swift
//  Action
//
//  Created by K3 on 2018/8/7.
//

import Foundation
import UIKit
import RxSwift
import SnapKit
import LarkCore
import ByteWebImage
import LarkMessengerInterface

// 最大高度450px（针对2X屏幕） 宽度不限（根据屏幕）
// 最小宽度240px（针对2X屏幕）
let videoMaxSize = CGSize(width: max(120, UIScreen.main.bounds.width * 0.6), height: 225)

let videoMinSize = CGSize(width: 120, height: 120)

public enum VideoViewStatus {
    /// 富文本中视频专用，消息未发送成功则设置为此状态
    case notWork
    /// 发送成功状态
    case normal
    /// 1：发送失败，2：正在转码/上传时用户主动取消
    case pause
    /// 假消息上屏后默认状态，正在转码/上传
    case uploading
    /// 被撤回
    case fileRecalled
    /// 被管理员临时删除
    case fileRecoverable
    /// 被管理员永久删除
    case fileUnrecoverable
    /// 被ka用脚本清除
    case fileFreedup
}

public final class VideoImageViewWrapper: UIView {

    public typealias TapAction = (VideoImageViewWrapper, VideoViewStatus) -> Void

    private let disposeBag = DisposeBag()

    private var subscribedTap: Bool = false

    private let isSmallPreview: Bool
    // 无预览权限遮罩
    private lazy var noPermissionPreviewLayerView = NoPermissonPreviewLayerView()
    // 无预览权限时候的方形小遮罩
    private lazy var noPermissionPreviewSmallLayerView: NoPermissonPreviewSmallLayerView = {
        let view = NoPermissonPreviewSmallLayerView()
        view.tapAction = { [weak self] _ in
            guard let self = self else { return }
            self.tapAction?(self, self.status)
        }
        return view
    }()

    public var tapAction: TapAction? {
        didSet {
            if subscribedTap { return }
            subscribedTap = true
            tap.subscribe(onNext: { [weak self] (status) in
                guard let `self` = self else { return }
                self.tapAction?(self, status)
            }).disposed(by: disposeBag)
        }
    }
    /// 点击事件（touchend触发）
    public var tap: Observable<VideoViewStatus> { return _tap.asObservable() }

    private var _tap = PublishSubject<VideoViewStatus>()

    /// 视频上传进度
    public var uploadProgress: Double = 0 {
        didSet {
            if uploadProgress > 0 {
                status = .uploading
            }
            uploadProgressView.uploadProgress = uploadProgress
        }
    }

    /// 视频状态
    public var status: VideoViewStatus = .normal {
        didSet {
            self.setStatusStyle()
        }
    }

    /// show NoPermission layer
    private func showNoPermissionPreviewLayer(dynamicAuthorityEnum: DynamicAuthorityEnum) {
        if noPermissionPreviewLayerView.superview == nil {
            self.addSubview(noPermissionPreviewLayerView)
            noPermissionPreviewLayerView.snp.makeConstraints({ (make) in
                make.centerX.equalToSuperview()
                make.centerY.equalToSuperview()
                make.width.height.equalToSuperview()
            })
        }
        noPermissionPreviewLayerView.isHidden = false
        noPermissionPreviewLayerView.setLayerType(dynamicAuthorityEnum: dynamicAuthorityEnum, previewType: .video)
    }

    /// show 小showNoPermission layer
    public func showNoPermissionPreviewSmallLayer() {
        if noPermissionPreviewSmallLayerView.superview == nil {
            self.addSubview(noPermissionPreviewSmallLayerView)
            noPermissionPreviewSmallLayerView.snp.makeConstraints({ (make) in
                make.centerX.equalToSuperview()
                make.centerY.equalToSuperview()
                make.width.height.equalToSuperview()
            })
        }
        noPermissionPreviewSmallLayerView.isHidden = false
    }

    /// hide NoPermission layer
    private func hideNoPermissionPreviewLayer() {
        noPermissionPreviewLayerView.isHidden = true
    }

    /// hide NoPermission layer
    public func hideNoPreviewPermissionSmallLayer() {
        noPermissionPreviewSmallLayerView.isHidden = true
    }

    //返回值：是否有权限
    public func handleAuthority(dynamicAuthorityEnum: DynamicAuthorityEnum, hasPermissionPreview: Bool) -> Bool {
        if dynamicAuthorityEnum.authorityAllowed && hasPermissionPreview {
            if isSmallPreview {
                hideNoPreviewPermissionSmallLayer()
            } else {
                hideNoPermissionPreviewLayer()
            }
            return true
        } else {
            if isSmallPreview {
                showNoPermissionPreviewSmallLayer()
            } else {
                showNoPermissionPreviewLayer(dynamicAuthorityEnum: dynamicAuthorityEnum)
            }
            return false
        }
    }

    /// 缩略图预览
    public let previewView: VideoImageView

    private let uploadProgressView: VideoUploadProgressView
    private let playIcon: UIImageView
    // 视频时间相关的view
    private let timeView: VideoTimeView

    private var originSize: CGSize = .zero {
        didSet {
            self.previewView.origionSize = originSize
            self.invalidateIntrinsicContentSize()
        }
    }

    public override var intrinsicContentSize: CGSize {
        return self.previewView.intrinsicContentSize
    }

    public init(isSmallPreview: Bool = false) {
        self.isSmallPreview = isSmallPreview
        previewView = VideoImageView(maxSize: videoMaxSize, minSize: videoMinSize)
        uploadProgressView = VideoUploadProgressView()
        playIcon = UIImageView()
        timeView = VideoTimeView()
        super.init(frame: .zero)

        addSubview(previewView)
        previewView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        addSubview(uploadProgressView)
        uploadProgressView.snp.makeConstraints { (maker) in
            maker.width.height.equalTo(40)
            maker.center.equalToSuperview()
        }

        addSubview(playIcon)
        playIcon.snp.makeConstraints { (maker) in
            maker.edges.equalTo(uploadProgressView)
        }

        addSubview(timeView)
        timeView.snp.makeConstraints { (maker) in
            maker.height.equalTo(20)
            maker.right.bottom.equalToSuperview().offset(-12)
        }

        playIcon.isHidden = true
        uploadProgressView.isHidden = true

        setStatusStyle()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 拓展背景图
    ///
    /// - Parameter backgroundImage: 背景图片
    public func stretchBackgroundImage(_ backgroundImage: UIImage) {
        self.lu.stretchBackgroundImage(backgroundImage, self.intrinsicContentSize)
    }

    /// 绘制描边
    public func drawImageBubbleBorder() {
        self.lu.drawBubbleBorder(self.intrinsicContentSize)
    }

    /// 隐藏视频时间view
    public func hideTimeView() {
        timeView.isHidden = true
    }

    /// 计算图片应该显示的大小
    ///
    /// - Parameters:
    ///   - originSize: 原始大小
    ///   - maxSize: 最大显示大小
    ///   - minSize: 最小显示大小
    /// - Returns: 应该显示的大小
    public static func calculateSize(originSize: CGSize, maxSize: CGSize, minSize: CGSize) -> CGSize {
        let imageMaxSizeWidthLimit: CGFloat = 400
        let imageMaxSizeHeightLimit: CGFloat = 400
        let scaleMaxSize = CGSize(width: min(imageMaxSizeWidthLimit, maxSize.width), height: min(imageMaxSizeHeightLimit, maxSize.height))
        return VideoImageView.calculateSizeAndContentMode(originSize: originSize, maxSize: scaleMaxSize, minSize: minSize).0
    }
}

extension VideoImageViewWrapper {
    /// 设置预览图原始大小
    ///
    /// - Parameter size: 原始大小
    public func setOriginSize(_ size: CGSize) {
        self.originSize = size
    }
    /// 设置视频时间
    ///
    /// - Parameter duration: 视频时间
    public func setDuration(_ duration: Int32) {
        self.timeView.setDuration(duration)
    }
    /// 设置原始大小和回调
    ///
    /// - Parameters:
    ///         super.update(view: view)
    ///   - originSize: 原始大小
    public func setVideoPreviewSize(originSize: CGSize, authorityAllowed: Bool) {
        /// 设置预览图原始大小
        /// - Parameter originSize: 原始大小
        /// - Parameter hasPermissionPreview: 有无权限预览
        self.originSize = authorityAllowed ? originSize : ChatNoPreviewPermissionLayerSizeConfig.normalSize
    }

    private func setStatusStyle() {
        func resetStatusUI() {
            playIcon.isHidden = true
            uploadProgressView.isHidden = true
        }

        resetStatusUI()

        switch status {
        case .notWork:
            break
        case .normal, .pause:
            playIcon.image = BundleResources.video_play
            playIcon.isHidden = false
        case .fileRecoverable, .fileUnrecoverable, .fileRecalled, .fileFreedup:
            playIcon.image = BundleResources.video_file_deleted
            playIcon.isHidden = false
        case .uploading:
            uploadProgressView.isHidden = false
            uploadProgressView.status = status
        }
    }
}

/// @zhaochen 修正点赞/查看视频/查看帖子手势与查看时间行为互相影响的问题
public extension VideoImageViewWrapper {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else {
            return
        }

        switch status {
        case .notWork:
            break
        case .normal, .fileRecalled, .pause, .fileRecoverable, .fileUnrecoverable, .fileFreedup:
            _tap.onNext(status)
        case .uploading:
            if uploadProgressView.frame.contains(point) {
                _tap.onNext(status)
            }
        }
    }
}
