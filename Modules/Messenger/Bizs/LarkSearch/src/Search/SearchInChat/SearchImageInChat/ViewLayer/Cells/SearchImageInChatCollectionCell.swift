//
//  SearchImageInChatCollectionCell.swift
//  LarkSearch
//
//  Created by zc09v on 2018/9/12.
//

import Foundation
import LarkModel
import LarkCore
import ByteWebImage
import UniverseDesignIcon
import UIKit
import LarkUIKit

final class SearchImageInChatCollectionCell: UICollectionViewCell {
    var imageView: UIImageView
    let gifTag: UIImageView
    private lazy var videoTagView = VideoTagView()
    private lazy var noPermissionPreviewView = NOPermissionPreviewView()

    override init(frame: CGRect) {
        imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.borderWidth = 0.5
        imageView.layer.ud.setBorderColor(UIColor.ud.lineDividerDefault)
        imageView.ud.setMaskView()

        gifTag = UIImageView(frame: .zero)
        gifTag.image = Resources.gifTag

        super.init(frame: frame)
        self.contentView.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        self.contentView.addSubview(noPermissionPreviewView)
        noPermissionPreviewView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        self.contentView.addSubview(gifTag)
        gifTag.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(6)
            make.left.equalToSuperview().offset(6)
        }

        contentView.addSubview(videoTagView)
        videoTagView.snp.makeConstraints { (make) in
            make.height.equalTo(30)
            make.width.equalToSuperview()
            make.bottom.equalToSuperview()
            make.right.equalToSuperview()
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func set(resource: SearchResource.Data, hasPreviewPremission: Bool?) {
        guard hasPreviewPremission == true else {
            showNoPremissionView()
            return
        }
        noPermissionPreviewView.hidden()
        gifTag.isHidden = true
        var isVideo = false
        let imageSet: ImageSet
        switch resource {
        case .image(let image):
            imageSet = image
            videoTagView.hidden()
            videoTagView.isHidden = true
        case .video(let video):
            isVideo = true
            videoTagView.isHidden = false
            videoTagView.setDuration(video.duration)
            imageSet = video.image
        }
        let key = ImageItemSet.transform(imageSet: imageSet).getThumbInfoForSearchHistory().0
        imageView.bt.setLarkImage(with: .default(key: key),
                                  placeholder: Resources.imageDownloading,
                                  options: [.onlyLoadFirstFrame],
                                  trackStart: {
                                    return TrackInfo(scene: .Search, fromType: .chatHistory)
                                  },
                                  completion: { [weak self] result in
                                    switch result {
                                    case .success(let imageResult):
                                        if imageResult.image?.bt.isAnimatedImage ?? false {
                                            self?.gifTag.isHidden = false
                                        }
                                    case .failure:
                                        self?.imageView.image = Resources.imageDownloadFail
                                    }
                                  })
    }

    func showNoPremissionView() {
        imageView.isHidden = true
        gifTag.isHidden = true
        videoTagView.isHidden = true
        noPermissionPreviewView.show()
    }
}
final class NOPermissionPreviewView: UIView {
    struct Style {
        static let backgroundColor: UIColor = UIColor.ud.bgFloatOverlay
        static let textFontSize: CGFloat = 14
        static let fontWeight: UIFont.Weight = .regular
        static let textColor: UIColor = UIColor.ud.textPlaceholder
        static let numberOfLines: Int = 2
        static let titleAlignment: NSTextAlignment = .center
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.backgroundColor = Style.backgroundColor
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: Style.textFontSize, weight: Style.fontWeight)
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.textColor = Style.textColor
        label.numberOfLines = Style.numberOfLines
        label.text = BundleI18n.LarkSearch.Lark_IM_UnableToPreview_Button
        label.textAlignment = Style.titleAlignment

        self.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.left.equalToSuperview().offset(12)
            make.right.equalToSuperview().offset(-12)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func show() {
        self.isHidden = false
    }
    func hidden() {
        self.isHidden = true
    }
}

final class VideoTagView: UIView {

    lazy var gradientView: GradientView = {
        let gradientView = GradientView()
        gradientView.backgroundColor = UIColor.clear
        gradientView.colors = [UIColor.ud.staticBlack.withAlphaComponent(0.0), UIColor.ud.staticBlack.withAlphaComponent(0.25)]
        gradientView.direction = .vertical
        return gradientView
    }()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        label.sizeToFit()
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(gradientView)
        gradientView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }

        addSubview(timeLabel)
        timeLabel.snp.makeConstraints { (maker) in
            maker.right.equalToSuperview().offset(-4)
            maker.bottom.equalToSuperview().offset(-4)
        }

        isHidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Display readable time string on tag.
    /// - Parameter duration: total time of video in milliseconds.
    func setDuration(_ duration: Int32) {
        var time: Int = Int(duration / 1000)
        let seconds = time % 60
        time /= 60
        let minutes = time % 60
        time /= 60
        let timeString: String
        if time == 0 {
            timeString = String(format: "%02d:%02d", minutes, seconds)
        } else {
            timeString = String(format: "%02d:%02d:%02d", time, minutes, seconds)
        }
        timeLabel.text = timeString
    }

    func show(with timeString: String) {
        timeLabel.text = timeString
        self.isHidden = false
    }

    func hidden() {
        self.isHidden = true
    }
}
