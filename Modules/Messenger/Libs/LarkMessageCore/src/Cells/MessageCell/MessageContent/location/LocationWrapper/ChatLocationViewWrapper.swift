//
//  ChatLocationViewWrapper.swift
//  Pods
//
//  Created by Fangzhou Liu on 2019/6/12.
//  Copyright © 2019 ByteDance Inc. All rights reserved.
//

import UIKit
import Foundation
import SnapKit
import AsyncComponent
import LarkSDKInterface

public typealias LocationViewCompletion = (UIImage?, Error?) -> Void
public typealias LocationViewTappedCallback = () -> Void
public typealias SetImageType = ((UIImageView, @escaping LocationViewCompletion) -> Void)

public struct LocationConsts {
    public static var defaultNameFont: UIFont { UIFont.ud.headline }
    public static var defaultDescriptionFont: UIFont { UIFont.ud.body2 }
    public static let defaultLabelGap: CGFloat = 2.5
    public static let defaultMargin: UIEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
    public static let defaultScreenShotSize: CGSize = CGSize(width: UIScreen.main.bounds.size.width, height: 200)
}

public struct ChatLocationViewStyleSetting {
    var margin: UIEdgeInsets
    var nameFont: UIFont
    var labelGap: CGFloat
    var descriptionFont: UIFont
    var imageViewSize: CGSize

    public init(
        nameFont: UIFont = LocationConsts.defaultNameFont,
        labelGap: CGFloat = LocationConsts.defaultLabelGap,
        descriptionFont: UIFont = LocationConsts.defaultDescriptionFont,
        margin: UIEdgeInsets = LocationConsts.defaultMargin,
        imageSize: CGSize = LocationConsts.defaultScreenShotSize
    ) {
        self.nameFont = nameFont
        self.labelGap = labelGap
        self.descriptionFont = descriptionFont
        self.margin = margin
        self.imageViewSize = imageSize
    }
}

public final class ChatLocationViewWrapper: UIView {
    /// 显示地址的view
    public var locationInfoView = UIStackView()

    private static let nameNumberOfLines: Int = 2
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = LocationConsts.defaultNameFont.withWeight(.medium)
        label.textColor = UIColor.ud.N900
        label.numberOfLines = Self.nameNumberOfLines
        return label
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = LocationConsts.defaultDescriptionFont
        label.textColor = UIColor.ud.N500
        return label
    }()

    /// 显示截图的view, 为了使得图片不被拉抻到模糊，因此将ChatImageViewWrapper放到一个
    /// 固定尺寸的View上
    private let imageContainer: UIView

    private var imageSize: CGSize

    private let imageView: ChatImageViewWrapper

    private var setLocationAction: SetImageType?

    private var tapGestureAdded: Bool = false

    private var locationTappedCallback: LocationViewTappedCallback? {
        didSet {
            if !tapGestureAdded {
                self.lu.addTapGestureRecognizer(action: #selector(locationViewDidTapped(_:)), target: self)
                tapGestureAdded = true
            }
        }
    }

    public init(setting: ChatLocationViewStyleSetting) {
        imageView = ChatImageViewWrapper(
            maxSize: setting.imageViewSize,
            minSize: setting.imageViewSize,
            failureViewType: .placeholderColor,
            centerYOffset: 0
        )
        imageView.imageView.adaptiveContentModel = false
        imageView.imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = UIColor.ud.N100
        imageContainer = UIView(frame: .zero)
        imageContainer.clipsToBounds = true
        imageSize = setting.imageViewSize
        super.init(frame: .zero)
        imageContainer.addSubview(imageView)
        self.addSubview(imageContainer)
        let imageSize = setting.imageViewSize
        let margin = setting.margin
        let labelWidth = imageSize.width - (margin.left + margin.right)
        // 由于有边框，左右留一个像素，底部留一个像素
        let size = CGSize(width: imageSize.width, height: imageSize.height)
        updateFontSetting(name: setting.nameFont, description: setting.descriptionFont)

        locationInfoView.axis = .vertical
        locationInfoView.spacing = setting.labelGap
        locationInfoView.alignment = .leading
        locationInfoView.distribution = .fill

        locationInfoView.addArrangedSubview(nameLabel)
        nameLabel.snp.makeConstraints { (make) in
            make.width.equalToSuperview()
        }
        descriptionLabel.setContentCompressionResistancePriority(.defaultLow - 1, for: .horizontal)
        descriptionLabel.setContentHuggingPriority(.defaultLow - 1, for: .horizontal)
        locationInfoView.addArrangedSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { (make) in
            make.width.equalToSuperview()
        }

        addSubview(locationInfoView)
        locationInfoView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(margin.top)
            make.left.equalToSuperview().offset(margin.left)
            make.right.equalToSuperview().offset(-margin.right)
            make.width.equalTo(labelWidth)
        }
        imageContainer.snp.makeConstraints { (make) in
            make.top.equalTo(locationInfoView.snp.bottom).offset(margin.top)
            make.left.right.bottom.equalToSuperview()
            make.size.equalTo(size)
        }
        imageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// FavoriteCell, PinCell和MessageCell都用了这个类，
    /// 但是为了处理三个cell对nameLabel和descriptionLabel的设定不同的情况
    /// 下面两个设定可以从外部修改两个label控件
    private func updateFontSetting(name: UIFont, description: UIFont) {
        self.nameLabel.font = name
        self.descriptionLabel.font = description
    }

    /// 设置LocationView
    ///
    /// - Parameters:
    ///   - name: 目的地名称
    ///   - description: 目的地地址
    ///   - originSize: 图片原始大小
    ///   - locationTappedCallback: 图片点击回调
    ///   - setLocationViewAction: 设置图片回调
    public func set(
        name: String,
        description: String,
        originSize: CGSize,
        setting: ChatLocationViewStyleSetting,
        locationTappedCallback: @escaping LocationViewTappedCallback,
        setLocationViewAction: @escaping SetImageType,
        settingGifLoadConfig: GIFLoadConfig?
    ) {
        self.locationTappedCallback = locationTappedCallback
        self.nameLabel.text = name
        self.descriptionLabel.isHidden = description.isEmpty
        self.descriptionLabel.text = description
        self.imageView.set(
            originSize: originSize,
            dynamicAuthorityEnum: .allow,
            needLoading: true,
            animatedDelegate: nil,
            forceStartIndex: 0,
            forceStartFrame: nil,
            imageTappedCallback: { (_) in
                locationTappedCallback()
            },
            setImageAction: setLocationViewAction,
            settingGifLoadConfig: settingGifLoadConfig
        )
    }

    public func updateUploadProgress(_ progress: Float) {
        self.imageView.updateUploadProgress(progress)
    }

    /// 计算位置卡片的大小（目前只在Chat里有用，pin和收藏需要再调整）
    ///
    /// - Parameters:
    ///   - imageSize: 地图预览view的大小
    ///   - containerSize: 父容器size
    ///   - margin: 内部边距
    ///   - name: 位置名称
    ///   - nameFontSize: 位置名称的字体大小
    ///   - description: 位置描述
    ///   - descriptionFontSize: 位置描述字体大小
    /// - Returns: 位置卡片的大小
    public static func calculateSize(
        with setting: ChatLocationViewStyleSetting,
        containerSize: CGSize,
        name: String,
        description: String
    ) -> CGSize {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingTail
        let nameAttrStr = NSAttributedString(string: name,
                                             attributes: [.font: setting.nameFont,
                                                          .paragraphStyle: paragraphStyle]
        )
        let imageSize = setting.imageViewSize
        let margin = setting.margin
        let labelWidth = min(containerSize.width, imageSize.width) - (margin.left + margin.right)
        let nameHeight = nameAttrStr.componentTextSize(
            for: CGSize(width: max(labelWidth, 0),
                        height: CGFloat.greatestFiniteMagnitude),
            limitedToNumberOfLines: nameNumberOfLines
        ).height
        let descriptionHeight = description.size(withAttributes: [.font: setting.descriptionFont]).height

        // nameLabel距cellContentView顶部和imageContainer距locationInfoView底部距离为11
        return CGSize(
            width: imageSize.width,
            height: nameHeight + (description.isEmpty ? 0 : descriptionHeight + setting.labelGap) + (margin.top * 2) + imageSize.height
        )
    }

    @objc
    private func locationViewDidTapped(_ gesture: UIGestureRecognizer) {
        self.locationTappedCallback?()
    }
    /// 绘制图片描边，否则边角的灰边会被图片遮挡
    /// 边框宽度必须和calculateSize算出来的尺寸一致，一旦超出会导致边框显示不全
    public func drawImageBubbleBorder(setting: ChatLocationViewStyleSetting, imageSize: CGSize, hasDescription: Bool) {
        let nameHeight = self.nameLabel.text?.size(
            withAttributes: [.font: setting.nameFont]
            ).height ?? 0
        let descriptionHeight = self.descriptionLabel.text?.size(
            withAttributes: [.font: setting.descriptionFont]
            ).height ?? 0
        // nameLabel距cellContentView顶部和imageContainer距locationInfoView底部距离为11 （defaultValue为12）， 因此需要-2
        let height = nameHeight
            + (hasDescription ? (descriptionHeight + setting.labelGap) : 0)
            + (setting.margin.top * 2 - 2)
            + imageSize.height
        self.lu.drawBubbleBorder(
            CGSize(
                width: imageSize.width,
                height: height
            ),
            lineWidth: 1.0
        )
    }
}
