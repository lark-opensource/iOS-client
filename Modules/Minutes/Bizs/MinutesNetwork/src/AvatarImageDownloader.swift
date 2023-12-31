//
//  AvatarImageDownloader.swift
//  MinutesFoundation
//
//  Created by admin on 2021/2/7.
//

import UIKit
import Foundation
import Kingfisher

public extension MinutesAPI {
    public static var imageDownloader: ImageDownloader {
        let imageDownloader = ImageDownloader(name: "MinutesImageDownloader")
        imageDownloader.sessionConfiguration = MinutesAPI.sessionConfiguration
        return imageDownloader
    }
}

public extension UIImageView {

    public func setAvatarImage(with resource: Resource?, placeholder: Placeholder? = nil) {
        kf.cancelDownloadTask()
        kf.setImage(with: resource,
                    placeholder: placeholder,
                    options: [.downloader(MinutesAPI.imageDownloader)])
    }
}

public extension UIButton {

    public func setAvatarImage(with resource: Resource?, for state: UIControl.State, placeholder: UIImage? = nil) {

        kf.setImage(with: resource,
                    for: state,
                    placeholder: placeholder,
                    options: [.downloader(MinutesAPI.imageDownloader)])
    }
}
