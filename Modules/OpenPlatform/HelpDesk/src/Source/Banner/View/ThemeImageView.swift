//
//  ThemeImageView.swift
//  LarkHelpdesk
//
//  Created by yinyuan on 2021/8/30.
//

import Foundation
import UniverseDesignTheme
import ByteWebImage

@objcMembers
public final class ThemeImageView: UIImageView {
    
    var themedImageKey: ThemedImageKey? {
        didSet {
            self.bt.setLarkImage(with: .default(key: getThemeKey() ?? ""))
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public override init(image: UIImage?) {
        super.init(image: image)
        setup()
    }
    
    public override init(image: UIImage?, highlightedImage: UIImage?) {
        super.init(image: image, highlightedImage: highlightedImage)
        setup()
    }
    
    public convenience init() {
        self.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        
    }
    
    private func getThemeKey() -> String? {
        if #available(iOS 12.0, *) {
            if self.traitCollection.userInterfaceStyle == .dark, let darkKey = themedImageKey?.dark, !darkKey.isEmpty {
                return darkKey
            }
        }
        return themedImageKey?.light
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                self.bt.setLarkImage(with: .default(key: getThemeKey() ?? ""))
            }
        }
    }
}

