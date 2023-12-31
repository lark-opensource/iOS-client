//
//  LoadingView.swift
//  Lark
//
//  Created by liuwanlin on 2017/10/18.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Lottie
import UniverseDesignTheme

open class LoadingPlaceholderView: UIView {

    public enum Style {
        case `default`
        case center
    }

    public var style: Style = .default

    public var text: String = "" {
        didSet {
            label.text = self.text
        }
    }

    open var image: UIImage? {
        nil
    }

    override public var frame: CGRect {
        didSet {
            if container.superview != nil {
                /// 调整边距，jira：https://jira.bytedance.com/browse/SUITE-60649
                container.snp.remakeConstraints { (make) in
                    make.centerX.left.right.equalToSuperview()
                    switch style {
                    case .default:
                        make.top.equalToSuperview().offset(frame.height / 3)
                    default:
                        make.top.equalToSuperview()
                    }
                }
            }
        }
    }

    override public var bounds: CGRect {
        didSet {
            if container.superview != nil {
                /// 调整边距，jira：https://jira.bytedance.com/browse/SUITE-60649
                container.snp.remakeConstraints { (make) in
                    make.centerX.left.right.equalToSuperview()
                    switch style {
                    case .default:
                        make.top.equalToSuperview().offset(bounds.height / 3)
                    default:
                        make.top.equalToSuperview()
                    }
                }
            }
        }
    }

    public let container = UIView()
    public let logo = UIImageView()
    public let label = UILabel()
    public var animationView = LOTAnimationView(name: lottieResourceName, bundle: .localResources)

    private var isLoadingView: Bool {
        return self.image == nil
    }

    public init(style: Style) {
        super.init(frame: .zero)
        self.style = style
        initialize()
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    private func initialize() {
        self.backgroundColor = UIColor.ud.N00

        self.addSubview(container)
        container.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            switch style {
            case .default:
                make.top.equalToSuperview().offset(bounds.height / 3)
            default:
                make.top.equalToSuperview()
            }
        }

        // logo
        logo.image = image
        container.addSubview(logo)
        logo.snp.makeConstraints { (make) in
            //偏移为10是为了与插画UDEmptyView的设计规范对齐
            make.top.equalToSuperview().offset(10)
            make.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 100, height: 100))
        }

        container.addSubview(animationView)
        animationView.snp.makeConstraints { (make ) in
            make.edges.equalTo(logo)
        }

        if isLoadingView {
            logo.isHidden = true
            animationView.isHidden = false
            animationView.loopAnimation = true
        } else {
            logo.isHidden = false
            animationView.isHidden = true
        }

        // 文案
        label.text = self.text
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.N600
        label.textAlignment = .center
        label.numberOfLines = 0
        container.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(logo.snp.bottom).offset(16)
//            make.height.equalTo(20)
            make.bottom.equalToSuperview()
        }
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        themeDidChange()
    }

    private func themeDidChange() {
        animationView.stop()
        animationView.removeFromSuperview()
        animationView = LOTAnimationView(name: Self.lottieResourceName, bundle: .localResources)
        container.addSubview(animationView)
        animationView.snp.makeConstraints { (make ) in
            make.edges.equalTo(logo)
        }
        animationView.play()
        animationView.loopAnimation = true
    }

    private static var lottieResourceName: String {
        var fileSuffix = "LM"
        if #available(iOS 13.0, *) {
            fileSuffix = UDThemeManager.getRealUserInterfaceStyle() == .dark ? "DM" : "LM"
        }
        return "\(fileSuffix)-loading"
    }

    public override var isHidden: Bool {
        didSet {
            if isHidden {
                self.stop()
            } else {
                self.play()
            }
        }
    }

    private func play() {
        if isLoadingView {
            animationView.playIfNeeded()
        }
    }

    private func stop() {
        animationView.stopIfNeeded()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.stop()
    }
}
