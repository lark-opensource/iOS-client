//
//  ShareImagesView.swift
//  ShareExtension
//
//  Created by K3 on 2018/7/4.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import LarkExtensionCommon
import MobileCoreServices

private let margin: CGFloat = 15
private let space: CGFloat = 7.5

final class ShareImagesView: UIView, ShareTableHeaderProtocol {
    var viewHeight: CGFloat {
        let rowCount = ceil(Double(item.images.count) / 3)
        return CGFloat(rowCount) * (imageWidth + space) + 2 * margin - space
    }

    var showErrorAlert: ((ShareUnsupportErrorType) -> Void)?

    private var availableWidth: CGFloat
    private var imageWidth: CGFloat {
        return (availableWidth - 2 * space - 2 * margin) / 3
    }

    private var item: ShareImageItem
    private var imageViews: [UIImageView] = [UIImageView]()

    init(item: ShareImageItem, availableWidth: CGFloat) {
        self.item = item
        self.availableWidth = availableWidth
        super.init(frame: .zero)

        createImageViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        for i in 0..<imageViews.count {
            imageViews[i].frame = CGRect(
                x: margin + CGFloat(i % 3) * (imageWidth + space),
                y: margin + CGFloat(i / 3) * (imageWidth + space),
                width: imageWidth,
                height: imageWidth
            )
        }
    }
}

private extension ShareImagesView {
     func createImageViews() {
        guard item.isLoadDataSuccess else {
            return
        }

        for url in item.images {
            let imageView = makeImageView()
            imageView.image = item.previewMaps[url]
            addSubview(imageView)
            imageViews.append(imageView)
        }
    }

    func makeImageView() -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 2
        return imageView
    }
}
