//
//  AvatarGroup.swift
//  UniverseDesignAvatar
//
//  Created by 郭怡然 on 2022/8/23.
//

import Foundation
import UIKit
import UniverseDesignTheme
import UniverseDesignColor
import UniverseDesignFont

public final class UDAvatarGroup: UIView {
    
    public var avatars: [UDAvatar] = [] {
        didSet {
            updateView()
        }
    }

    var lastAvatar: UDAvatar?

    public var showCount: Int

    var isRestNumHidden: Bool

    lazy var textView: UILabel = UILabel()

    public var sizeClass: UDAvatar.Configuration.Size {
        didSet {
            updateView()
        }
    }

    var offset: CGFloat {
        sizeClass.offset
    }

    public init(avatars: [UDAvatar], sizeClass: UDAvatar.Configuration.Size, showCount: Int = 5) {
        self.avatars = avatars
        self.sizeClass = sizeClass
        self.showCount = showCount
        self.isRestNumHidden = showCount >= avatars.count
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        if !isRestNumHidden {
            self.addSubview(textView)
        }
        updateView()
    }

    func getLeftMargin(index: Int) -> CGFloat {
        return sizeClass.borderWidth + (sizeClass.width + sizeClass.offset) * CGFloat(index)
    }

    private func updateView() {
        updateAvatarView()
        updateTextView()
    }

    func updateAvatarView() {
        for i in 0..<min(avatars.count - 1 ,showCount) {
            var avatar = avatars[i]
            avatar.configuration.hasExternalBorder = true
            avatar.configuration.sizeClass = sizeClass
            avatar.configuration.style = .circle
            if !self.subviews.contains(avatar) {
                self.addSubview(avatar)
            }
            avatar.snp.remakeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.height.equalToSuperview()
                make.right.lessThanOrEqualToSuperview()
                make.left.equalToSuperview().offset(getLeftMargin(index: i))
            }
        }
    }

    func updateTextView() {
        guard !isRestNumHidden else { return }
        self.bringSubviewToFront(textView)
        textView.backgroundColor = UIColor.ud.bgFiller
        textView.textAlignment = .center
        textView.text = "+\(avatars.count - showCount)"
        textView.layer.masksToBounds = true
        textView.font = sizeClass.font
        textView.layer.borderWidth = sizeClass.borderWidth
        textView.layer.ud.setBorderColor(UIColor.ud.bgBody)
        textView.textColor = UIColor.ud.textCaption
        textView.snp.remakeConstraints { (make) in
            make.width.equalTo(sizeClass.width + sizeClass.borderWidth * 2)
            make.height.equalTo(sizeClass.height + sizeClass.borderWidth * 2)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(getLeftMargin(index: showCount) - sizeClass.borderWidth)
            make.right.lessThanOrEqualToSuperview()
        }

        let minLength = min(sizeClass.width, sizeClass.height)
        textView.layer.cornerRadius = (minLength + sizeClass.borderWidth * 2) / 2
    }
}

extension UDAvatar.Configuration.Size {
    var offset: CGFloat {
        switch self{
        case .mini:     return -4
        case .small:    return -4
        case .middle:   return -8
        case .large:    return -8
        case .extraLarge:    return -12
        }
    }
}


