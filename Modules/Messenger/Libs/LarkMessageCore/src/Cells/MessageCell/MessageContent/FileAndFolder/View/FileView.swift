//
//  FileView.swift
//  LarkChat
//
//  Created by chengzhipeng-bytedance on 2018/3/23.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import UIKit
import Foundation
import SnapKit
import LarkUIKit
import LarkFoundation
import RichLabel
import LarkMessengerInterface
import LarkContainer

/// 通用文件/附件 view, 包含图标, 文件名, 大小, 来源, 进度条.
public final class FileView: UIView {
    /// 这里抽取常量因为多个地方使用
    enum Cons {
        static var nameLabelLineSpace: CGFloat { 0 }
        static var nameLabelNumberOfLine: Int { 3 }
        static var sizeAndRateNumberOfLine: Int { 2 }
        static var fileNameFont: UIFont { UIFont.ud.body0 }
        static var sizeAndRateFont: UIFont { UIFont.ud.caption1 }
        static var fileStatusFont: UIFont { UIFont.ud.caption1 }
        static var noPermissionHintFont: UIFont { UIFont.ud.caption1 }
        static var fileViewTextAttributes: [NSAttributedString.Key: Any] {
            let paragraph = NSMutableParagraphStyle()
            paragraph.lineBreakMode = .byWordWrapping
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.ud.textTitle,
                .font: fileNameFont,
                .paragraphStyle: paragraph
            ]
            return attributes
        }
        static var noPermissionPreviewfileViewTextAttributes: [NSAttributedString.Key: Any] {
            let paragraph = NSMutableParagraphStyle()
            paragraph.lineBreakMode = .byWordWrapping
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.ud.textPlaceholder,
                .font: fileNameFont,
                .paragraphStyle: paragraph
            ]
            return attributes
        }
    }
    private var sizeAndRateStr: String = ""
    private var sizeStr: String = ""
    private var lastEditInfoString: String?
    private var rateStr: String = ""
    private lazy var fileIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.clear
        imageView.contentMode = .scaleAspectFit
        imageView.layer.masksToBounds = true
        return imageView
    }()

    // 局域网传输icon
    private lazy var lanTransIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.clear
        imageView.contentMode = .scaleAspectFill
        imageView.image = BundleResources.lan_Trans_Icon_light
        imageView.layer.masksToBounds = true
        return imageView
    }()

    public lazy var nameLabel: LKLabel = {
        let nameLabel = LKLabel().lu.setProps(
            fontSize: Cons.fileNameFont.pointSize,
            numberOfLine: Cons.nameLabelNumberOfLine
        )
        /**
         lu.setProps 内部会关闭 translatesAutoresizingMaskIntoConstraints
         使用frame布局需要为true
         */
        nameLabel.translatesAutoresizingMaskIntoConstraints = true
        nameLabel.autoDetectLinks = false
        nameLabel.lineSpacing = Cons.nameLabelLineSpace
        return nameLabel
    }()

    /// 显示当前文件大小&速率
    private lazy var sizeAndRateLabel: UILabel = {
        let sizeAndRateLabel = UILabel()
        sizeAndRateLabel.textColor = UIColor.ud.textPlaceholder
        sizeAndRateLabel.font = Cons.sizeAndRateFont
        sizeAndRateLabel.textAlignment = .left
        sizeAndRateLabel.lineBreakMode = .byTruncatingMiddle
        sizeAndRateLabel.numberOfLines = Cons.sizeAndRateNumberOfLine
        return sizeAndRateLabel
    }()

    /// 当用户无文件预览权限时,大小&速率不予显示,展示"暂无无预览权限"小字
    private lazy var noPermissionLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = Cons.noPermissionHintFont
        label.textAlignment = .left
        return label
    }()

    private lazy var statusLabel: UILabel = {
        let statusLabel = UILabel()
        statusLabel.textColor = UIColor.ud.textPlaceholder
        statusLabel.font = Cons.fileStatusFont
        statusLabel.textAlignment = .right
        statusLabel.numberOfLines = 0
        statusLabel.lineBreakMode = .byTruncatingMiddle
        return statusLabel
    }()
    /**
     UIProgressView 有自己的高度，直接设置高度无用  默认高度为 2
     eg: 设置frame为(0,0,100,3) 实际打印为：(0,0,100,2)
     */
    private lazy var progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.progress = 0.0
        progress.progressTintColor = UIColor.ud.primaryContentDefault
        progress.isHidden = true
        progress.trackTintColor = UIColor.ud.lineBorderCard
        return progress
    }()

    private lazy var topBorderView = UIView(frame: CGRect.zero)
    private lazy var bottomBorderView = UIView(frame: CGRect.zero)

    private var tapGestureAdded: Bool = false
    public var tapAction: ((FileView) -> Void)? {
        didSet {
            if tapGestureAdded { return }
            tapGestureAdded = true
            self.lu.addTapGestureRecognizer(action: #selector(fileViewTapped(_:)), target: self)
        }
    }

    public var showTopBorder: Bool = true {
        didSet {
            self.topBorderView.isHidden = !showTopBorder
        }
    }
    public var showBottomBorder: Bool = true {
        didSet {
            self.bottomBorderView.isHidden = !showBottomBorder
        }
    }

    public init() {
        super.init(frame: .zero)

        self.backgroundColor = UIColor.clear

        self.addSubview(topBorderView)
        topBorderView.backgroundColor = UIColor.ud.N300
        self.addSubview(fileIconImageView)
        self.addSubview(lanTransIcon)
        self.addSubview(nameLabel)
        self.addSubview(sizeAndRateLabel)
        self.addSubview(statusLabel)
        self.addSubview(noPermissionLabel)
        insertSubview(bottomBorderView, belowSubview: fileIconImageView)
        bottomBorderView.backgroundColor = UIColor.ud.N300
        /**
         关于progressView的出现场景
         1 目前下载的时候不会出现
         2 上传的时候才会出现
         3 上传文件未成功的时候 不能有用户点赞之类的Reaction
         */
        self.addSubview(progressView)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func fileViewTapped(_ gesture: UIGestureRecognizer) {
        tapAction?(self)
    }

    public func setProgress(_ progress: Float, animated: Bool) {
        if progress <= 0.0 {
            self.progressView.setProgress(0, animated: false)
            self.progressView.isHidden = true
        } else if progress >= 1.0 - 1e-6 {
            self.progressView.setProgress(progress, animated: animated)
            // 进度从非隐藏到隐藏时需要加动画（进度变为1了不立即消失）
            if !self.progressView.isHidden {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.8, execute: {
                    self.progressView.isHidden = true
                })
            }
        } else {
            self.progressView.isHidden = false
            self.progressView.setProgress(progress, animated: animated)
        }
    }

    public func setRate(_ rate: String) {
        self.rateStr = rate
        if let lastEditInfoString = self.lastEditInfoString {
            self.sizeAndRateLabel.lineBreakMode = .byTruncatingTail
            self.sizeAndRateStr = self.sizeStr + lastEditInfoString + self.rateStr
        } else {
            self.sizeAndRateLabel.lineBreakMode = .byTruncatingMiddle
            self.sizeAndRateStr = self.sizeStr + self.rateStr
        }
        self.sizeAndRateLabel.text = self.sizeAndRateStr
    }

    func set(fileName: String,
             sizeLabelContent: String,
             lastEditInfoString: String?,
             icon: UIImage,
             isShowLanTransIcon: Bool,
             statusText: String = "",
             dynamicAuthorityEnum: DynamicAuthorityEnum,
             hasPermissionPreview: Bool = true) {
        self.sizeStr = sizeLabelContent
        self.lastEditInfoString = lastEditInfoString
        self.statusLabel.textAlignment = sizeLabelContent.isEmpty ? .left : .right
        self.fileIconImageView.image = icon
        self.lanTransIcon.isHidden = !isShowLanTransIcon
        self.statusLabel.text = statusText
        let attributes: [NSAttributedString.Key: Any]
        if hasPermissionPreview && dynamicAuthorityEnum.authorityAllowed {
            attributes = Cons.fileViewTextAttributes
        } else {
            attributes = Cons.noPermissionPreviewfileViewTextAttributes
            noPermissionLabel.text = ChatSecurityControlServiceImpl.getNoPermissionSummaryText(permissionPreview: hasPermissionPreview,
                                                                                               dynamicAuthorityEnum: dynamicAuthorityEnum,
                                                                                               sourceType: .file)
        }
        let strs = fileName.lf.trimCharacters(in: .whitespacesAndNewlines, postion: .both).components(separatedBy: ".")
        DispatchQueue.main.async { //LKLabel有个bug，不async一下的话UI上attribute不更新。
            if !strs.isEmpty {
                self.nameLabel.outOfRangeText = NSAttributedString(string: "... .\(strs.last ?? "")", attributes: attributes)
            }
            self.nameLabel.attributedText = NSAttributedString(string: fileName, attributes: attributes)
        }
    }

    func updateLayout(layoutResult: FileViewLayoutResult) {

        if let layoutEngine = layoutResult.layoutEngine {
            self.nameLabel.setForceLayout(layoutEngine)
        }

        let views: [UIView] = [self.nameLabel,
                      self.topBorderView,
                      self.fileIconImageView,
                      self.lanTransIcon,
                      self.sizeAndRateLabel,
                      self.statusLabel,
                      self.noPermissionLabel,
                      self.progressView,
                      self.bottomBorderView]
        let rects: [CGRect] = [layoutResult.nameLabelFrame,
                      layoutResult.topBorderViewFrame,
                      layoutResult.fileIconImageViewFrame,
                      layoutResult.lanTransIconImageViewFrame,
                      layoutResult.sizeAndRateLabelFrame,
                      layoutResult.statusLabelFrame,
                      layoutResult.noPermissionLabelFrame,
                      layoutResult.progressViewFrame,
                      layoutResult.bottomBorderViewFrame]
        //不一致再更新frame
        for i in 0..<views.count {
            let view = views[i]
            if !view.frame.equalTo(rects[i]) {
                view.frame = rects[i]
            }
        }
    }
}
