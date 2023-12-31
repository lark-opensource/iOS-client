//
//  URLVideoCoverImageViewComponent.swift
//  LarkMessageCore
//
//  Created by zc09v on 2019/6/23.
//

import Foundation
import UIKit
import AsyncComponent
import EEFlexiable
import LarkModel
import ByteWebImage
import UniverseDesignTheme

final class URLVideoCoverImageViewComponent<C: Context>: ASComponent<URLVideoCoverImageViewComponent.Props, EmptyState, VideoCoverImageView, C> {
    final class Props: ASComponentProps {
        var coverOnTapped: ((UIImageView) -> Void)?
        var coverImageSet: ImageSet?
        var preferMaxWidth: CGFloat = 0
    }

    override var isComplex: Bool {
        return true
    }

    override var isSelfSizing: Bool {
        return true
    }

    override func sizeToFit(_ size: CGSize) -> CGSize {
        let width = (props.preferMaxWidth - 15)
        let height = width * (9.0 / 16.0)
        return CGSize(width: width, height: height)
    }

    override func update(view: VideoCoverImageView) {
        super.update(view: view)
        view.coverOnTapped = props.coverOnTapped
        view.videoIconImageView.alpha = 0
        view.videoCoverTapGesture?.isEnabled = false
        view.backgroundColor = UIColor.ud.staticBlack
        if let coverImageSet = props.coverImageSet {
            let imageSet = ImageItemSet.transform(imageSet: coverImageSet)
            let key = imageSet.getThumbKey()
            let placeholder = imageSet.inlinePreview
            let resource = LarkImageResource.default(key: key)
            view.bt.setLarkImage(with: resource,
                                 placeholder: placeholder,
                                 trackStart: {
                                  return TrackInfo(scene: .Chat, fromType: .urlPreview)
                                 },
                                 completion: { result in
                                     switch result {
                                     case .success:
                                         // 预览图正常设置后，才显示播放按钮图标, 点击手势才生效
                                         view.videoCoverTapGesture?.isEnabled = true
                                         view.videoIconImageView.alpha = 1
                                     case .failure:
                                         break
                                     }
                                 })
        } else {
            view.image = nil
        }
    }
}

final class VideoCoverImageView: UIImageView {
    let videoIconImageView: UIImageView
    var coverOnTapped: ((UIImageView) -> Void)?
    var videoCoverTapGesture: UITapGestureRecognizer?

    public override init(frame: CGRect) {
        self.videoIconImageView = UIImageView()
        super.init(frame: frame)
        self.layer.cornerRadius = 4
        self.layer.masksToBounds = true
        self.contentMode = .scaleAspectFit
        videoIconImageView.image = BundleResources.videoPreviewIcon
        self.addSubview(videoIconImageView)
        videoIconImageView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.height.equalTo(40)
        }
        videoIconImageView.ud.setMaskView()
        self.videoCoverTapGesture = self.lu.addTapGestureRecognizer(action: #selector(videoCoverImageViewClick), target: self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func videoCoverImageViewClick() {
        self.coverOnTapped?(self)
    }
}
