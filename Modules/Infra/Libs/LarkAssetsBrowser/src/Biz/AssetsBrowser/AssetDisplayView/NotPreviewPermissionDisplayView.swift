//
//  NotPermissionView.swift
//  LarkAssetsBrowser
//
//  Created by zhaojiachen on 2022/4/28.
//

import UIKit
import Foundation
import LarkUIKit
import UniverseDesignColor
import LKCommonsLogging

final class NotPermissionView: UIView, LKAssetPageView {
    var handleLoadCompletion: ((AssetLoadCompletionInfo) -> Void)?
    static private let logger = Logger.log(NotPermissionView.self,
                                           category: "LarkUIKit.NotPermissionView")
    
    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 20)
        titleLabel.textColor = UIColor.ud.textPlaceholder
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 4
        switch displayState {
        case .allow:
            assertionFailure("please message to kangsiwan@bytedance.com")
        case .previewDeny:
            if isVideo {
                titleLabel.text = BundleI18n.LarkAssetsBrowser.Lark_IM_UnableToPreviewVideo_Text
            } else {
                titleLabel.text = BundleI18n.LarkAssetsBrowser.Lark_IM_UnableToPreviewImage_Text
            }
        case .receiveDeny:
            titleLabel.text = BundleI18n.LarkAssetsBrowser.Lark_IM_NoReceivingPermission_Text
        case .receiveLoading:
            titleLabel.text = ""
        }
        return titleLabel
    }()

    private lazy var viewContainer: UIView = {
        let viewContainer = UIView()
        viewContainer.backgroundColor = UIColor.ud.bgFloatOverlay
        return viewContainer
    }()

    private var singleTap = UITapGestureRecognizer()
    private let isVideo: Bool
    let displayState: PermissionDisplayState

    init(isVideo: Bool, displayState: PermissionDisplayState) {
        self.isVideo = isVideo
        self.displayState = displayState
        super.init(frame: .zero)

        self.addSubview(viewContainer)
        viewContainer.addSubview(titleLabel)
        viewContainer.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(self.snp.width).multipliedBy(0.6)
        }
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview().inset(16)
        }
        singleTap.addTarget(self, action: #selector(handleSingleTap(_:)))
        self.addGestureRecognizer(singleTap)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func handleSingleTap(_ gesture: UITapGestureRecognizer) {
        if dismissCallback == nil {
            Self.logger.info("handleSingleTap, dismissCallback is nil")
        } else {
            Self.logger.info("handleSingleTap, dismissCallback")
        }
        dismissCallback?()
    }

    var prepareAssetInfo: PrepareAssetInfo?
    var displayIndex: Int = Int.max
    var displayAsset: LKDisplayAsset?
    var dismissFrame: CGRect = .zero
    var dismissImage: UIImage?
    var longGesture: UILongPressGestureRecognizer = UILongPressGestureRecognizer()
    var getExistedImageBlock: GetExistedImageBlock?
    var setImageBlock: SetImageBlock?
    var setSVGBlock: SetSVGBlock?
    var dismissCallback: (() -> Void)?
    var longPressCallback: ((UIImage?, LKDisplayAsset, UIView?) -> Void)?
    var moreButtonClickedCallback: ((UIImage?, LKDisplayAsset, UIView?) -> Void)?
    func handleSwipeDown() {}
    func prepareDisplayAsset(completion: @escaping () -> Void) {}
    func prepareForReuse() {}
    func recoverToInitialState() {}
    func handleCurrentDisplayAsset() {}
    func handleTranslateProcess(baseView: UIView,
                                cancelHandler: @escaping () -> Void,
                                processHandler: @escaping (@escaping () -> Void, @escaping (Bool, LKDisplayAsset?) -> Void) -> Void,
                                dataSourceUpdater: @escaping (LKDisplayAsset) -> Void) {}
}
