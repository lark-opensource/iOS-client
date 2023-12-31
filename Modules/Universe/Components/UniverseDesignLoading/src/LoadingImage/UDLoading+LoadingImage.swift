//
//  UDLoading+LoadingImage.swift
//  UniverseDesignLoading
//
//  Created by Miaoqi Wang on 2020/11/11.
//

import UIKit
import Foundation

extension UDLoading {
    /// UDLoading image view
    public static func loadingImageView(lottieResource: String? = nil) -> UIView {
        return UDLoadingImageView(lottieResource: lottieResource)
    }

    /// UDLoading view controller
    public static func loadingImageController(lottieResource: String? = nil) -> UIViewController {
        return UDLoadingImageViewController(lottieResource: lottieResource)
    }
}
