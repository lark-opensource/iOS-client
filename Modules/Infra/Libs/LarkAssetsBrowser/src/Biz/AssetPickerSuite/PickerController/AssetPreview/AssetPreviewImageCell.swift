//
//  AssetPreviewImageCell.swift
//  LarkImagePicker
//
//  Created by ChalrieSu on 2018/8/31.
//  Copyright © 2018 ChalrieSu. All rights reserved.
//

import Foundation
import UIKit
import ByteWebImage
import LarkImageEditor
import UniverseDesignColor

final class AssetPreviewImageCell: UICollectionViewCell {
    var assetIdentifier: String?
    var currentShowImage: UIImage? {
        return imageView.image
    }

    private let imageView = ByteImageView()
    private let zoomView: ZoomScrollView

    override init(frame: CGRect) {
        zoomView = ZoomScrollView(zoomView: imageView, originSize: .zero)

        super.init(frame: frame)

        addSubview(zoomView)
        imageView.contentMode = .scaleAspectFit
        zoomView.isUserInteractionEnabled = false
        contentView.addGestureRecognizer(zoomView.panGestureRecognizer)
        contentView.addGestureRecognizer(zoomView.pinchGestureRecognizer!)
        zoomView.contentInsetAdjustmentBehavior = .never
        zoomView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        imageView.backgroundColor = UIColor.ud.primaryOnPrimaryFill
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setImage(_ image: UIImage?) {
        imageView.image = image
        zoomView.originSize = image?.size ?? .zero
    }

    func resetZoomView() {
        zoomView.relayoutZoomView()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
}
