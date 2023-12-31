//
//  BitableRecordHeaderButtonWrapper.swift
//  SKBitable
//
//  Created by 刘焱龙 on 2023/8/7.
//

import Foundation
import UniverseDesignColor

final class BitableRecordHeaderButtonWrapper: UIView {
    private lazy var blurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .regular)
        let view = UIVisualEffectView(effect: blurEffect)
        view.contentView.backgroundColor = UIColor.ud.N300.withAlphaComponent(0.3)
        view.isHidden = true
        return view
    }()

    lazy var button = UIButton()

    init() {
        super.init(frame: .zero)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        addSubview(blurView)
        addSubview(button)

        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        button.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func update(showBlur: Bool) {
        guard blurView.isHidden == showBlur else {
            return
        }
        blurView.isHidden = !showBlur
    }

    func updateHeaderAlpha(alpha: CGFloat) {
        let reverseAlpha = 1 - alpha
        let buttonBlurAlpha = reverseAlpha >= 0 ? reverseAlpha : 0
        // UIVisualEffectView 重复设置 alpha 会闪烁
        if blurView.alpha != buttonBlurAlpha {
            blurView.alpha = buttonBlurAlpha
        }
    }
}
