//
//  AvatarComponent.swift
//  AvatarComponent
//
//  Created by 姚启灏 on 2020/6/16.
//

import UIKit
import Foundation

open class AvatarComponent: UIImageView {
    /// AvatarComponent UI Config
    private var config: AvatarComponentUIConfig = AvatarComponentUIConfig()

    public init(frame: CGRect, config: AvatarComponentUIConfig) {
        super.init(frame: frame)

        self.setConfig(config)

        self.clipsToBounds = true
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.config.style == .circle ? min(bounds.width, bounds.height) / 2 : 0
    }

    /// Update the image of the component
    /// - Parameter image: Avatar
    open func updateAvatar(_ image: UIImage? = nil) {
        self.image = image
    }

    /// Update the configuration of the component
    /// - Parameter config: AvatarComponent UI Config
    open func updateConfig(_ config: AvatarComponentUIConfig) {
        self.setConfig(config)
    }

    /// Set configuration and update component properties
    /// - Parameter config: AvatarComponent UI Config
    private func setConfig(_ config: AvatarComponentUIConfig) {
        self.config = config

        self.backgroundColor = config.backgroundColor
        self.contentMode = config.contentMode

        setNeedsLayout()
    }
}
