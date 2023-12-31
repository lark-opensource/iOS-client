//
//  LOTAnimationTapView.swift
//  Pods
//
//  Created by zc09v on 2019/7/22.
//

import Foundation
import UIKit
import Lottie
import UniverseDesignTheme

public final class LOTAnimationTapView: TappedView {
    private let filePathLight: String
    private let filePathDark: String?
    public var identifier: String = ""

    private func getFilePath() -> String {
        if #available(iOS 13.0, *),
           UDThemeManager.getRealUserInterfaceStyle() == .dark,
           let filePathDark = filePathDark {
            return filePathDark
        }
        return filePathLight
    }
    public lazy var animationView: LOTAnimationView = {
        let view = LOTAnimationView(filePath: getFilePath())
        return view
    }()
    private lazy var iconDisabled: UIImageView = {
        let view = UIImageView()
        view.isHidden = true
        view.tintColor = .ud.iconDisabled
        view.contentMode = .center
        return view
    }()
    public override var isUserInteractionEnabled: Bool {
        didSet {
            iconDisabled.isHidden = isUserInteractionEnabled
            animationView.isHidden = !isUserInteractionEnabled
        }
    }
    public init(frame: CGRect, filePathLight: String, filePathDark: String?) {
        self.filePathLight = filePathLight
        self.filePathDark = filePathDark
        super.init(frame: frame)
        self.addSubview(animationView)
        addSubview(iconDisabled)
        iconDisabled.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    public func setImageForDisabled(_ image: UIImage?) {
        iconDisabled.image = image?.withRenderingMode(.alwaysTemplate)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        animationView.frame = self.bounds
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if #available(iOS 13.0, *),
           traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            if animationView.superview != nil {
                animationView.removeFromSuperview()
            }
            animationView = LOTAnimationView(filePath: getFilePath())
            self.addSubview(animationView)
        }
    }
}
