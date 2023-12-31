//
//  MomentsVideoCorveView.swift
//  Moment
//
//  Created by liluobin on 2021/3/24.
//
import Foundation
import UIKit
import LKCommonsLogging
import LarkMessageCore
import UniverseDesignIcon

final class MomentsVideoCorveView: UIView {
    static let logger = Logger.log(MomentsVideoCorveView.self, category: "Module.Moments.MomentsVideoCorveView")
    let displayImageView = SkeletonImageView()
    let corveImageView = UIImageView()
    let videoTimeView = VideoTimeView()

    var setImageAction: SetImageAction
    var imageClick: ((UIImageView) -> Void)?
    var coverImage: UIImage?

    init(coverImage: UIImage?, setImageAction: SetImageAction, duration: Int32?, imageClick: ((UIImageView) -> Void)?) {
        self.setImageAction = setImageAction
        super.init(frame: .zero)
        setupView()
        updateViewWith(corveImage: coverImage, setImageAction: setImageAction, duration: duration, imageClick: imageClick)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        displayImageView.contentMode = .scaleAspectFill
        self.clipsToBounds = true
        self.addSubview(displayImageView)
        displayImageView.coverContainer.addSubview(corveImageView)
        displayImageView.coverContainer.addSubview(videoTimeView)
        let tap = UITapGestureRecognizer(target: self, action: #selector(click))
        self.addGestureRecognizer(tap)
        videoTimeView.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview().offset(-8)
            make.right.equalToSuperview().offset(-8)
            make.height.equalTo(20)
        }
        displayImageView.ud.setMaskView()
    }

    func updateViewWith(corveImage: UIImage?, setImageAction: SetImageAction, duration: Int32?, imageClick: ((UIImageView) -> Void)?) {
        self.setImageAction = setImageAction
        self.imageClick = imageClick
        self.setImageAction?(self.displayImageView, 0, { [weak self] (_, error) in
            if let error = error {
                Self.logger.error("\(error)")
                self?.displayImageView.image = Resources.imageDownloadFailed
                self?.displayImageView.contentMode = .center
            } else {
                self?.displayImageView.contentMode = .scaleAspectFill
            }
        })
        self.updateCorveImageViewWith(corveImage: corveImage)
        self.updateVideoDuration(duration)
    }

    func updateCorveImageViewWith(corveImage: UIImage?) {
        self.corveImageView.isHidden = (corveImage == nil)
        corveImageView.image = corveImage
        corveImageView.frame = CGRect(origin: .zero, size: corveImage?.size ?? .zero)
        corveImageView.center = displayImageView.center
    }

    func updateVideoDuration(_ duration: Int32?) {
        if let duration = duration, duration > 0 {
            videoTimeView.setDuration(duration * 1000)
            videoTimeView.isHidden = false
        } else {
            videoTimeView.isHidden = true
        }
    }

    @objc
    func click() {
        self.imageClick?(self.displayImageView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if displayImageView.frame != self.bounds {
            displayImageView.frame = self.bounds
        }

        if corveImageView.center != displayImageView.center, !self.corveImageView.isHidden {
            corveImageView.center = displayImageView.center
        }
    }

    /// 视频的展示规则
    static func videoCoverImageSizeWith(originSize: CGSize, preferMaxWidth: CGFloat) -> CGSize {
        if originSize.width < originSize.height {
            var width = Int(preferMaxWidth * 2.0 / 3.0)
            width = width % 2 == 0 ? width : width + 1
            var height = Int(CGFloat(width) / 2.0 * 3.0)
            height = height % 2 == 0 ? height : height + 1
            return CGSize(width: width, height: height)
        } else {
            let width = Int(preferMaxWidth)
            var height = Int(CGFloat(width) / 16.0 * 9.0)
            height = height % 2 == 0 ? height : height + 1
            return CGSize(width: width, height: height)
        }
    }
}
