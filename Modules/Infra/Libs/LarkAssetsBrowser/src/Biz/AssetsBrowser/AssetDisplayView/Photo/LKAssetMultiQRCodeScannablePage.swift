//
//  LKAssetMultiQRCodeScannablePage.swift
//  LarkAssetsBrowser
//
//  Created by Saafo on 2023/10/12.
//

import Foundation

/// 主要用于配合 MultiQRCodeScanner 使用
public protocol LKAssetMultiQRCodeScannablePage: LKAssetPageView {

    var visibleRect: CGRect? { get }

    var visibleImage: UIImage? { get }

    var originalImageData: Data? { get }

    var currentImageScale: Double { get }
}
