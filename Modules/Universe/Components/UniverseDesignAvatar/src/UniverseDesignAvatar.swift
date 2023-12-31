//
//  UniverseDesignAvatar.swift
//  UniverseDesignAvatar
//
//  Created by 姚启灏 on 2020/9/7.
//

import UIKit
import Foundation
import SnapKit
import FigmaKit

/// Universe Design Avatar
open class UDAvatar: UIImageView {
    /// Avatar Component UI Config

    public var configuration: UDAvatar.Configuration {
        didSet {
            self.updateConfig(configuration)
        }
    }
    var externalBorder: CALayer?

    /// init
    /// - Parameters:
    ///   - frame:
    ///   - configuration:Avatar Component UI Configuration
    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
        super.init(frame: .zero)
        self.updateConfig(configuration)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override var intrinsicContentSize: CGSize {
        return CGSize(width: configuration.width, height: configuration.height)
    }

    /// Update the image of the component
    /// - Parameter image: Avatar
    open func updateAvatar(_ image: UIImage? = nil) {
        self.image = image
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        let minLength = min(self.bounds.width, self.bounds.height)
        if self.configuration.style == .circle {
            self.layer.ux.setSmoothCorner(radius: minLength / 2, smoothness: .none)
            self.layer.masksToBounds = true
        } else {
            //使用.max，实现膨胀矩形效果
            self.layer.cornerRadius = 0
            self.layer.ux.setSmoothCorner(radius: minLength / 2)
        }
        updateExternalBorder()
    }
    
    /// Set configuration and update component properties
    /// - Parameter config: AvatarComponent UI Config
    private func updateConfig(_ configuration: Configuration) {

        self.backgroundColor = configuration.backgroundColor
        self.contentMode = configuration.contentMode
        if let image = configuration.image {
            self.image = image
        } else {
            /// When the image is empty, a placeholder needs to be set
            self.image = configuration.placeholder
        }
        let minLength = min(configuration.sizeClass.width, configuration.sizeClass.height)
        self.bounds.size = CGSize(width: configuration.width, height: configuration.height)
        self.invalidateIntrinsicContentSize()
    }

    func updateExternalBorder() {
        if let border = externalBorder {
            if self.configuration.hasExternalBorder {
                if border.frame.width != configuration.width + 2 * configuration.sizeClass.borderWidth {
                    self.removeExternalBorders()
                    externalBorder = self.addExternalBorder(borderWidth: configuration.sizeClass.borderWidth, borderColor: UIColor.ud.bgBody)
                } else {
                    return
                }
            } else {
                self.removeExternalBorders()
                externalBorder = nil
            }
        } else {
            if self.configuration.hasExternalBorder {
                externalBorder = self.addExternalBorder(borderWidth: configuration.sizeClass.borderWidth, borderColor: UIColor.ud.bgBody)
            } else {
                return
            }
        }
    }
}
