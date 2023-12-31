//
//  LKAssetsCollectionCell.swift
//  LarkAssetsBrowser
//
//  Created by 王元洵 on 2021/5/25.
//

import Foundation
import FigmaKit
import ByteWebImage
import UniverseDesignCheckBox
import UIKit
import LarkUIKit

protocol LKAssetsCollectionCellDelegate: AnyObject {
    func checkBoxDidTapped(in cell: LKAssetsCollectionCell, selected: Bool)
}

final class LKAssetsCollectionCell: UICollectionViewCell {

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.borderWidth = 0.5
        imageView.ud.setLayerBorderColor(UIColor.ud.lineBorderCard)
        return imageView
    }()

    private let gifTag: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Resources.gifTag
        return imageView
    }()

    private lazy var noPermissionView: NotPreviewPermissionView = {
        let noPermissionView = NotPreviewPermissionView()
        return noPermissionView
    }()

    private lazy var checkBox: UDCheckBox = {
        let config = UDCheckBoxUIConfig(
            unselectedBackgroundEnabledColor: UIColor.ud.staticBlack.withAlphaComponent(0.16)
        )
        return UDCheckBox(boxType: .multiple, config: config)
    }()

    private lazy var videoTagView = VideoTagView()

    weak var delegate: LKAssetsCollectionCellDelegate?

    private(set) var canSelect = false
    private(set) var permissionState: PermissionDisplayState = .allow

    private(set) var currentResourceKeyWithThumbnail: (String, UIImage?) = ("", nil)

    override init(frame: CGRect) {

        super.init(frame: frame)

        contentView.addSubview(imageView)
        contentView.addSubview(gifTag)
        contentView.addSubview(noPermissionView)
        contentView.addSubview(checkBox)
        contentView.addSubview(videoTagView)

        imageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        gifTag.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(6)
            make.left.equalToSuperview().offset(6)
        }
        checkBox.snp.makeConstraints { (make) in
            make.right.top.equalToSuperview().inset(8)
        }
        videoTagView.snp.makeConstraints { (make) in
            make.height.equalTo(20)
            make.left.equalToSuperview().offset(5)
            make.bottom.equalToSuperview().offset(-5)
        }
        noPermissionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        checkBox.tapCallBack = { [weak self] in
            guard let self = self else { return }
            self.delegate?.checkBoxDidTapped(in: self, selected: $0.isSelected)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(resource: LKMediaResource, isBlur: Bool, isSelected: Bool) {
        gifTag.isHidden = true
        canSelect = resource.canSelect
        permissionState = resource.permissionState
        checkBox.isSelected = isSelected
        if !resource.permissionState.isAllow {
            noPermissionView.isHidden = false
            noPermissionView.previewPermission = permissionState
            imageView.bt.setLarkImage(with: .default(key: ""))
            imageView.isHidden = true
            videoTagView.isHidden = true
            return
        }
        noPermissionView.isHidden = true
        imageView.isHidden = false
        imageView.alpha = isBlur ? 0.6 : 1

        var isVideo = false

        switch resource.type {
        case .image:
            videoTagView.hidden()
            videoTagView.isHidden = true
        case .video(let duration):
            isVideo = true
            videoTagView.isHidden = false
            videoTagView.setDuration(duration)
        }

        let displayImageKey: String = {
            if (resource.data.originWidth ?? 0) > 850,
               let midKey = resource.data.middle?.key,
               !midKey.isEmpty {
                return midKey
            } else {
                return resource.data.thumbnail?.key ?? ""
            }
        }()

        imageView.bt.setLarkImage(
            with: .default(key: displayImageKey),
            placeholder: Resources.imageDownloading,
            options: [.onlyLoadFirstFrame],
            trackStart: {
                TrackInfo(scene: .Chat, fromType: .chatAlbum)
            },
            completion: { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let imageResult):
                    if imageResult.image?.bt.isAnimatedImage ?? false {
                        self.gifTag.isHidden = false
                    }
                    self.currentResourceKeyWithThumbnail = (resource.key, imageResult.image)
                case .failure(let error):
                    self.imageView.image = Resources.imageDownloadFail
                }
            })
    }

    func showCheckBox() {
        checkBox.isHidden = false
    }

    func hideCheckBox() {
        checkBox.isHidden = true
    }

    func flipCheckBox() {
        checkBox.isSelected.toggle()
    }

    func thumbnail() -> UIImageView {
        return imageView
    }

    final class NotPreviewPermissionView: UIView {
        var previewPermission: PermissionDisplayState = .previewDeny {
            didSet {
                switch previewPermission {
                case .allow:
                    assertionFailure("please message to kangsiwan@bytedance.com")
                case .previewDeny:
                    titleLabel.text = BundleI18n.LarkAssetsBrowser.Lark_IM_UnableToPreview_Button
                case .receiveDeny:
                    titleLabel.text = BundleI18n.LarkAssetsBrowser.Lark_IM_NoReceivingPermission_Text
                case .receiveLoading:
                    titleLabel.text = ""
                }
            }
        }
        private lazy var titleLabel: UILabel = {
            let titleLabel = UILabel()
            titleLabel.font = UIFont.systemFont(ofSize: 10)
            titleLabel.textColor = UIColor.ud.textPlaceholder
            titleLabel.textAlignment = .center
            titleLabel.numberOfLines = 4
            return titleLabel
        }()

        override init(frame: CGRect) {
            super.init(frame: frame)

            self.backgroundColor = UIColor.ud.bgFloatOverlay
            self.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.left.right.equalToSuperview().inset(6)
            }
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

extension LKMediaResource {

    /// Choose image key at proper size for previewing.
    var previewKey: String? {
        if (data.originWidth ?? 0) > 850, let midKey = data.middle?.key, !midKey.isEmpty {
            return midKey
        }
        return data.thumbnail?.key
    }
}
