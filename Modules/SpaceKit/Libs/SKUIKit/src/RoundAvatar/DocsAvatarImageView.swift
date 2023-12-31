//
//  DocsAvatarImageView.swift
//  SKUIKit
//
//  Created by chensi on 2021/8/16.
//  


import Foundation

public final class DocsAvatarImageView: AvatarImageView {

    override func commonInit() {
        super.commonInit()

        imageView.backgroundColor = nil
        backgroundColor = nil
        isOpaque = false
        lastingColor = .clear
        imageView.contentMode = .scaleAspectFit
    }
}
