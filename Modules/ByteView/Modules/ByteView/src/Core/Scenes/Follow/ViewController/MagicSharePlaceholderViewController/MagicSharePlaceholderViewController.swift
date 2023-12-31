//
//  MagicSharePlaceholderViewController.swift
//  ByteView
//
//  Created by liurundong.henry on 2023/11/19.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignColor

/// 会中妙享场景为了复用Webview，先释放旧文档再创建新文档，切换期间展示这个页面
class MagicSharePlaceholderViewController: BaseViewController {

    private enum Layout {
        static let phoneLoadingImageDimension: CGFloat = 36.0
        static let padLoadingImageDimension: CGFloat = 64.0
        static let loadingLabelFontSize: CGFloat = 16.0
        static let loadingLabelTopOffset: CGFloat = 8.0
    }

    let loadingImageView: UIImageView = {
        let imageDimension = Display.phone ? Layout.phoneLoadingImageDimension : Layout.padLoadingImageDimension
        let imageSize = CGSize(width: imageDimension, height: imageDimension)
        let loadingImage = UDIcon.getIconByKey(.shareScreenFilled, // 颜色和样式同共享屏幕“加载中”icon
                                               iconColor: UDColor.iconDisabled,
                                               size: imageSize)
        let imageView = UIImageView()
        imageView.image = loadingImage
        return imageView
    }()

    let loadingLabel: UILabel = {
        let label = UILabel()
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.text = I18n.View_VM_Loading // 颜色和样式同共享屏幕“加载中”文案
        label.textColor = .ud.iconDisabled
        label.font = .systemFont(ofSize: Layout.loadingLabelFontSize, weight: .bold)
        label.textAlignment = .center
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .ud.bgBody
        view.addSubview(loadingLabel)
        view.addSubview(loadingImageView)

        let imageDimension = Display.phone ? Layout.phoneLoadingImageDimension : Layout.padLoadingImageDimension
        let imageSize = CGSize(width: imageDimension, height: imageDimension)
        loadingImageView.snp.remakeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(imageSize)
        }
        loadingLabel.snp.remakeConstraints {
            $0.top.equalTo(loadingImageView.snp.bottom).offset(Layout.loadingLabelTopOffset)
            $0.centerX.equalToSuperview()
        }
    }
}
