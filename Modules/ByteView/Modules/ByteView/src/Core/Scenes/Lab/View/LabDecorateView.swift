//
//  DecorateView.swift
//  ByteView
//
//  Created by wangpeiran on 2021/10/15.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import SnapKit
import UniverseDesignIcon
import ByteViewUI

class LabDecorateView: UICollectionReusableView {
    struct Layout {
        static let width: CGFloat = VCScene.bounds.width
        static func height() -> CGFloat { Layout.buttonTopMargin() + Layout.buttonHeight() + Layout.buttonBottomMargin() }
        static func buttonTopMargin() -> CGFloat { (Layout.isRegular() ? 20 : 16) - LabVirtualBgCell.Layout.cellBorderTotalWidth() }
        static func buttonHeight() -> CGFloat { Layout.isRegular() ? 48 : 34 }
        static func buttonBottomMargin() -> CGFloat { Layout.isRegular() ? 28 : 16 }

        static func isRegular() -> Bool { VCScene.rootTraitCollection?.isRegular ?? false }
    }

    lazy var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private lazy var decorateBtn: UIButton = {
        let button = UIButton()
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 6
        button.isExclusiveTouch = true
        button.setTitle(I18n.View_G_DecorateVirtualBackground, for: .normal)
        let fontSize: CGFloat = Layout.isRegular() ? 14 : 12
        button.titleLabel?.font = UIFont.systemFont(ofSize: fontSize)
        button.titleLabel?.textAlignment = .center
        button.setTitleColor(UIColor.ud.textCaption, for: .normal)
        button.setImage(UDIcon.getIconByKey(.rightOutlined, iconColor: .ud.iconN2, size: CGSize(width: 14, height: 14)), for: .normal)
        button.vc.setBackgroundColor(.clear, for: .normal)
        button.vc.setBackgroundColor(.ud.fillPressed, for: .highlighted)
        button.addTarget(self, action: #selector(decorateAction), for: .touchUpInside)

        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: (button.titleLabel?.intrinsicContentSize.width ?? 0) + 2, bottom: 0, right: -(button.titleLabel?.intrinsicContentSize.width ?? 0) - 2 )
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: -(button.currentImage?.size.width ?? 0) - 2, bottom: 0, right: button.currentImage?.size.width ?? 0 + 2)

        return button
    }()

    var observation: NSKeyValueObservation?

    var viewModel: InMeetingLabViewModel?

    override init(frame: CGRect) {
        super.init(frame: CGRect(x: 0, y: 0, width: Layout.width, height: Layout.height()))
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        addSubview(containerView)
        containerView.addSubview(lineView)
        containerView.addSubview(decorateBtn)

        containerView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        decorateBtn.snp.makeConstraints { maker in
            maker.left.right.equalToSuperview()
            maker.height.equalTo(Layout.buttonHeight())
            maker.top.equalToSuperview().offset(Layout.buttonTopMargin())
        }

        lineView.snp.makeConstraints { maker in
            maker.left.right.equalToSuperview()
            maker.height.equalTo(0.5)
            maker.bottom.equalTo(decorateBtn.snp.top)
        }

        observation = decorateBtn.observe(\.isHighlighted, options: [.old, .new], changeHandler: {[weak self] _, change  in
            if let value = change.newValue {
                self?.lineView.isHidden = value
            }
        })
    }

    func updateView(inset: CGFloat) {
        decorateBtn.snp.updateConstraints { maker in
            maker.left.right.equalToSuperview().inset(inset)
        }

        lineView.snp.updateConstraints { maker in
            maker.left.right.equalToSuperview().inset(inset)
        }
    }

    @objc
    func decorateAction() {
        LabTrack.trackClickDecorate()
        viewModel?.selectDecorate()
    }
}
