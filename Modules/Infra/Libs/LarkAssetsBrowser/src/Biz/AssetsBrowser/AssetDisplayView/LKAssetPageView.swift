//
//  LKAssetPageView.swift
//  LarkUIKit
//
//  Created by Yuguo on 2018/8/9.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit
import ByteWebImage

public typealias GetExistedImageBlock = (_ displayAsset: LKDisplayAsset) -> UIImage?
public typealias SetImageBlock = (LKDisplayAsset, UIImageView, DownloadProgressBlock?, CompletionHandler?) -> CancelImageBlock?
public typealias PrepareAssetInfo = (LKDisplayAsset) -> (ImageDisplayDataProvider, ImagePassThrough?, TrackInfo)
public typealias SetSVGBlock = (LKDisplayAsset, SVGObtainCompletionHandler?) -> CancelImageBlock?
public typealias DownloadProgressBlock = (_ receivedSize: Int64, _ totalSize: Int64) -> Void
public typealias CompletionHandler = (_ image: UIImage?, _ info: CompletionInfo?, _ error: Error?) -> Void
typealias ResultCompletionHandler = (_ imageResult: ImageResult?, _ error: Error?) -> Void
public typealias CancelImageBlock = () -> Void

public protocol LKAssetPageView: UIView {
    var displayIndex: Int { get set }
    var displayAsset: LKDisplayAsset? { get set }

    var dismissFrame: CGRect { get }
    var dismissImage: UIImage? { get }

    // Used at LarkCore/AssetBrowserActionHandler.
    var longGesture: UILongPressGestureRecognizer { get }

    var getExistedImageBlock: GetExistedImageBlock? { get set }
    var setImageBlock: SetImageBlock? { get set }
    var handleLoadCompletion: ((AssetLoadCompletionInfo) -> Void)? { get set }
    var prepareAssetInfo: PrepareAssetInfo? { get set }
    var setSVGBlock: SetSVGBlock? { get set }

    var dismissCallback: (() -> Void)? { get set }
    var longPressCallback: ((UIImage?, LKDisplayAsset, UIView?) -> Void)? { get set }
    var moreButtonClickedCallback: ((UIImage?, LKDisplayAsset, UIView?) -> Void)? { get set }

    func handleSwipeDown()
    func prepareDisplayAsset(completion: @escaping () -> Void)
    func prepareForReuse()
    func recoverToInitialState()
    func handleCurrentDisplayAsset()
    func handleTranslateProcess(baseView: UIView,
                                cancelHandler: @escaping () -> Void,
                                processHandler: @escaping (@escaping () -> Void, @escaping (Bool, LKDisplayAsset?) -> Void) -> Void,
                                dataSourceUpdater: @escaping (LKDisplayAsset) -> Void)
}
