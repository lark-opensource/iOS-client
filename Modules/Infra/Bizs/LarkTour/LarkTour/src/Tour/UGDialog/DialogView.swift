//
//  DialogView.swift
//  LarkTour
//
//  Created by Aslan on 2022/01/16.
//

import Foundation
import LarkNavigation
import ByteWebImage
import UniverseDesignDialog
import UniverseDesignColor
import UniverseDesignEmpty
import UIKit
import EENavigator
import LKCommonsLogging

final class DialogView {
    static let logger = Logger.log(DialogView.self, category: "UGDialog")

    static func show(data: [String: Any],
                     cancelHandler: @escaping () -> Void,
                     confirmHandler: @escaping () -> Void) {
        let content = data["description"] as? String ?? ""
        let image = data["image"] as? String ?? ""
        let primaryButtonTxt = data["confirmText"] as? String ?? ""
        let cancelButtonTxt = data["cancelText"] as? String ?? ""

        var config = UDDialogUIConfig()
        let dialog = UDDialog(config: config)

        if let title = data["title"] as? String {
            dialog.setTitle(text: title)
        }
        dialog.setContent(view: getContentView(image: image, content: content))
        dialog.addSecondaryButton(text: cancelButtonTxt, dismissCompletion: {
            if let cancelButtonLink = data["cancelLink"] as? String,
               !cancelButtonLink.isEmpty,
               let applink = URL(string: cancelButtonLink),
               let window = Navigator.shared.mainSceneWindow {
                Navigator.shared.open(applink, from: window)
                Self.logger.info("cancel link --> \(cancelButtonLink)")
            } else {
                Self.logger.info("cancel link error --> \(data["cancelLink"])")
            }
            cancelHandler()
        })
        dialog.addPrimaryButton(text: primaryButtonTxt, dismissCompletion: {
            if let primaryButtonLink = data["confirmLink"] as? String,
                !primaryButtonLink.isEmpty,
                let applink = URL(string: primaryButtonLink),
                let window = Navigator.shared.mainSceneWindow {
                Navigator.shared.open(applink, from: window)
                Self.logger.info("primary link --> \(primaryButtonLink)")
            } else {
                Self.logger.info("primary link error --> \(data["confirmLink"])")
            }
            confirmHandler()
        })
        RootNavigationController.shared.present(dialog, animated: true, completion: nil)
    }

    static func getContentView(image: String, content: String) -> UIView {
        let contentView = UIView()
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.bt.setLarkImage(with: .default(key: image), completion: { [weak imageView] result in
            switch result {
            case .success(let imageResult):
                break
            case .failure(let error):
                imageView?.image = EmptyBundleResources.image(named: "emptyNegativeLoadFailed")
            }
        })
        let contentLabel = getContentLabel(content: content)
        contentView.addSubview(imageView)
        contentView.addSubview(contentLabel)
        let imageWidth: CGFloat = Self.Layout.imageSize.width
        imageView.snp.makeConstraints { (make) in
            make.width.equalTo(imageWidth)
            make.height.equalTo(Self.Layout.imageSize.height)
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        contentLabel.snp.makeConstraints { (make) in
            make.top.equalTo(imageView.snp.bottom).offset(Self.Layout.topOffset)
            make.bottom.centerX.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
        return contentView
    }

    static func getContentLabel(content: String) -> UILabel {
        let paragraphStyle = NSMutableParagraphStyle()
        let font = UIFont.systemFont(ofSize: Self.Layout.fontSize)
        paragraphStyle.lineSpacing = 4
        paragraphStyle.alignment = .center

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: UDColor.textTitle
        ]

        let attributedText = NSAttributedString(string: content, attributes: attributes)
        let contentLabel = UILabel()
        contentLabel.attributedText = attributedText
        contentLabel.numberOfLines = 0
        return contentLabel
    }
}

extension DialogView {
    enum Layout {
        static let fontSize: CGFloat = 16
        static let imageSize: CGSize = CGSize(width: 120, height: 120)
        static let topOffset: CGFloat = 12
    }
}
