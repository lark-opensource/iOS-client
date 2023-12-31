//
//  URLFaviconComponent.swift
//  Action
//
//  Created by 刘宏志 on 2019/4/9.
//

import UIKit
import Foundation
import AsyncComponent
import EEFlexiable
import ByteWebImage

private struct URLFaviconConstraints {
    static let cornerRadius: CGFloat = 2.0
    static let faviconLimitedSize = CGSize(width: 16, height: 16)
    static let thumbnailImageWidth: CGFloat = 20
}

final class URLFaviconComponent<C: Context>: ASComponent<URLFaviconComponent.Props, EmptyState, UIImageView, C> {
    final class Props: ASComponentProps {
        var iconKey: String?
        var iconURL: String?
    }
    override func update(view: UIImageView) {
        super.update(view: view)
        view.contentMode = .scaleAspectFill

        guard let url = props.iconURL else {
            view.image = BundleResources.url_preview_icon
            return
        }
        let completion: (UIImage?, Error?) -> Void = { image, _ in
            guard let image = image else {
                return
            }
            let scale = UIScreen.main.scale
            if image.size.width * scale < URLFaviconConstraints.faviconLimitedSize.width
                || image.size.height * scale < URLFaviconConstraints.faviconLimitedSize.height {
                view.image = BundleResources.url_preview_icon
            }
        }
        view.bt.setLarkImage(with: .default(key: url),
                             placeholder: BundleResources.url_preview_icon,
                             trackStart: {
                              return TrackInfo(scene: .Chat, fromType: .urlPreview)
                             },
                             completion: { result in
                                switch result {
                                case .success(let imageResult):
                                    completion(imageResult.image, nil)
                                case .failure(let error):
                                    completion(nil, error)
                                }
                             })
    }
}
