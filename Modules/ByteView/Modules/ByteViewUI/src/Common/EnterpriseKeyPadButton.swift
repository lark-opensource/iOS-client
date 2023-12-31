//
//  EnterpriseKeyPadButton.swift
//  ByteView
//
//  Created by fakegourmet on 2021/10/19.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UniverseDesignColor
import UniverseDesignIcon
import UIKit
import ByteViewCommon

open class AnimatedBackgroundButton: UIButton {

    public var duration: TimeInterval {
        0.25
    }

    public var extendEdge: UIEdgeInsets = .zero

    open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return bounds.inset(by: extendEdge).contains(point)
    }

    open override var isHighlighted: Bool {
        get {
            super.isHighlighted
        }
        set {
            UIView.transition(with: self,
                              duration: duration,
                              options: [.transitionCrossDissolve, .allowAnimatedContent, .allowUserInteraction],
                              animations: {
                super.isHighlighted = newValue
            },
                              completion: nil)
        }
    }
}

public final class EnterpriseKeyPadButton: AnimatedBackgroundButton {

    public enum Style {
        case `default`
        case tiny
        case max

        var mainInsets: UIEdgeInsets {
            if self == .default {
                return UIEdgeInsets(top: 12.0, left: 25.0, bottom: 0.0, right: 0.0)
            } else if self == .max {
                return Display.typeIsLike == .iPhoneXR ? UIEdgeInsets(top: 13.0, left: 29.5, bottom: 0.0, right: 0.0) : UIEdgeInsets(top: 13.0, left: 28.0, bottom: 0.0, right: 0.0)
            } else {
                return UIEdgeInsets(top: 7.67, left: 22.22, bottom: 0.0, right: 0.0)
            }
        }

        var subInsets: UIEdgeInsets {
            if self == .default {
                return UIEdgeInsets(top: 0.0, left: 0.0, bottom: 12.0, right: 0.0)
            } else if self == .max {
                return UIEdgeInsets(top: 0.0, left: 0.0, bottom: 15.0, right: 0.0)
            } else {
                return UIEdgeInsets(top: 0.0, left: 0.0, bottom: 9.94, right: 0.0)
            }
        }
    }

    lazy var mainLabel: UILabel = {
        let mainLabel = UILabel()
        return mainLabel
    }()

    lazy var subLabel: UILabel = {
        let subLabel = UILabel()
        return subLabel
    }()

    lazy var iconImageView: UIImageView = UIImageView()

    public private(set) var mainText: String?
    public private(set) var subText: String?

    public init(style: Style = .default, title: String?, subtitle: String?, mainText: String?, subText: String?) {
        super.init(frame: .zero)

        vc.setBackgroundColor(.ud.N900.withAlphaComponent(0.1), for: .normal)
        vc.setBackgroundColor(.ud.N900.withAlphaComponent(0.2), for: .highlighted)
        clipsToBounds = true
        isExclusiveTouch = true

        extendEdge = .init(top: -10.0,
                           left: -16.0,
                           bottom: -10.0,
                           right: -16.0)

        configTitle(title)
        configSubtitle(subtitle)
        self.mainText = mainText
        self.subText = subText

        addSubview(mainLabel)
        addSubview(subLabel)

        mainLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(style.mainInsets.top)
            $0.centerX.equalToSuperview()
        }
        subLabel.snp.makeConstraints {
            $0.centerX.equalTo(mainLabel).offset(1)
            $0.bottom.equalToSuperview().inset(style.subInsets.bottom)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        Util.runInMainThread { [weak self] in
            guard let self = self else { return }
            self.layer.cornerRadius = self.bounds.size.width / 2
        }
    }

    private func configTitle(_ title: String?) {
        guard let title = title else {
            return
        }
        if title.contains("*") {
            iconImageView.image = UDIcon.getIconByKey(.asteriskOutlined, iconColor: .ud.textTitle, size: CGSize(width: 24, height: 24))
            addSubview(iconImageView)
            iconImageView.snp.makeConstraints {
                $0.center.equalToSuperview()
            }
        } else if title.contains("#") {
            iconImageView.image = UDIcon.getIconByKey(.hashOutlined, iconColor: .ud.textTitle, size: CGSize(width: 24, height: 24))
            addSubview(iconImageView)
            iconImageView.snp.makeConstraints {
                $0.center.equalToSuperview()
            }
        } else {
            mainLabel.attributedText = .init(string: title, config: Display.iPhoneMaxSeries ? .enterpriseKeyPadMaxSeriesTitle : .enterpriseKeyPadTitle, alignment: .center)
        }
    }

    private func configSubtitle(_ subtitle: String?) {
        guard let subtitle = subtitle else {
            return
        }
        if subtitle.contains("+") {
            subLabel.attributedText = .init(string: subtitle, config: .enterpriseKeyPadSubtitleSpecial, alignment: .center, textColor: .ud.textTitle)
        } else {
            var attributes: [NSAttributedString.Key: Any] = [
                .kern: 2,
                .foregroundColor: UIColor.ud.textTitle
            ]
            let attr = Display.iPhoneMaxSeries ? VCFontConfig.enterpriseKeyPadMaxSeriesSubtitle.toAttributes() : VCFontConfig.enterpriseKeyPadSubtitle.toAttributes()
            attributes.merge(attr) { $1 }
            subLabel.attributedText = .init(string: subtitle, attributes: attributes)
        }
    }
}

private extension VCFontConfig {
    static let enterpriseKeyPadTitle = VCFontConfig(fontSize: 36, lineHeight: 38, fontWeight: .regular)
    static let enterpriseKeyPadTitleSpecial = VCFontConfig(fontSize: 72, lineHeight: 38, fontWeight: .regular)
    static let enterpriseKeyPadSubtitle = VCFontConfig(fontSize: 9, lineHeight: 12.6, fontWeight: .semibold)
    static let enterpriseKeyPadSubtitleSpecial = VCFontConfig(fontSize: 14, lineHeight: 19.6, fontWeight: .semibold)
    static let enterpriseKeyPadMaxSeriesTitle = VCFontConfig(fontSize: 38, lineHeight: 42, fontWeight: .regular)
    static let enterpriseKeyPadMaxSeriesSubtitle = VCFontConfig(fontSize: 11, lineHeight: 14, fontWeight: .semibold)
}
