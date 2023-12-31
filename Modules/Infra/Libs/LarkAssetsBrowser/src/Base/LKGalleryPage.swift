//
//  LKGalleryPage.swift
//  LKBaseAssetBrowser
//
//  Created by Hayden Wang on 2022/1/25.
//

import Foundation
import UIKit

public protocol LKGalleryPage: UIView {

    func prepareForReuse()
    static func generate(with assetBrowser: LKAssetBrowser) -> Self
}

extension LKGalleryPage {

    var reuseIdentifier: String {
        return String(describing: Self.classForCoder())
    }

    static var reuseIdentifier: String {
        return String(describing: self.classForCoder())
    }
}
