//
//  PopConfirmView.swift
//  ByteView
//
//  Created by liurundong.henry on 2022/09/30.
//

import Foundation
import SnapKit
import ByteViewUI

class PopConfirmView: UIView {

    enum Direction {
        case top
        case bottom
    }

    private enum Layout {
        // common layout params
        static let commonLabelFontSize: CGFloat = 14.0
        static let commonButtonHeight: CGFloat = 28.0
        static let commonButtonCornerRadius: CGFloat = 6.0
        static let commonButtonBorderWidth: CGFloat = 1.0
        static let commonButtonEdgeInsets = UIEdgeInsets(top: 4.0, left: 8.0, bottom: 4.0, right: 8.0)
        static let commonVerticalSpacing: CGFloat = 16.0
        static let commonHorizontalSpacing: CGFloat = 20.0

        // spacific layout params
        static let contentCornerRadius: CGFloat = 8.0
        static let contentMaxWidth: CGFloat = 300.0
        static let buttonHorizontalSpacing: CGFloat = 12.0
        static let titleLabelToTopSpacing: CGFloat = 16.0
        static let buttonBottomSpacing: CGFloat = 20.0
        static let arrowViewSize: CGSize = CGSize(width: 12.0, height: 12.0)
        //static let arrowViewSize: CGSize = CGSize(width: 16.0, height: 6.0)
    }

    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloat
        view.layer.cornerRadius = Layout.contentCornerRadius
        view.layer.masksToBounds = true
        view.layer.borderWidth = 1.0
        view.layer.vc.borderColor = UIColor.ud.lineBorderCard
        view.isUserInteractionEnabled = true
        return view
    }()

    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = I18n.View_G_VerticalBrowseOnly
        lbl.textColor = UIColor.ud.textTitle
        lbl.font = UIFont.systemFont(ofSize: Layout.commonLabelFontSize, weight: .medium)
        lbl.numberOfLines = 0
        lbl.setContentCompressionResistancePriority(.required, for: .vertical)
        lbl.setContentCompressionResistancePriority(.required, for: .horizontal)
        return lbl
    }()

    private lazy var cancelButton: UIButton = {
        let btn = UIButton()
        btn.setTitle(I18n.View_G_CancelButton, for: .normal)
        btn.setTitleColor(UIColor.ud.textTitle, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: Layout.commonLabelFontSize)
        btn.vc.setBackgroundColor(UIColor.ud.udtokenComponentOutlinedBg, for: .normal)
        btn.layer.masksToBounds = true
        btn.layer.cornerRadius = Layout.commonButtonCornerRadius
        btn.layer.vc.borderColor = UIColor.ud.lineBorderComponent
        btn.layer.borderWidth = Layout.commonButtonBorderWidth
        btn.contentEdgeInsets = Layout.commonButtonEdgeInsets
        btn.addTarget(self, action: #selector(didTapLeftButton), for: .touchUpInside)
        return btn
    }()

    private lazy var viewOnPortraitButton: UIButton = {
        let btn = UIButton()
        btn.setTitle(I18n.View_G_VerticalViewButton, for: .normal)
        btn.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: Layout.commonLabelFontSize)
        btn.vc.setBackgroundColor(UIColor.ud.primaryContentDefault, for: .normal)
        btn.layer.masksToBounds = true
        btn.layer.cornerRadius = Layout.commonButtonCornerRadius
        btn.contentEdgeInsets = Layout.commonButtonEdgeInsets
        btn.addTarget(self, action: #selector(didTapRightButton), for: .touchUpInside)
        return btn
    }()

    private let whiteArrowView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloat
        view.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi / 4.0))
        return view
    }()

    private let arrowView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloat
        view.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi / 4.0))
        view.layer.vc.borderColor = UIColor.ud.lineBorderCard
        view.layer.borderWidth = 1.0
        return view
    }()

    // TODO: @liurundong.henry 基于TriangleView实现边框
//    private lazy var arrowView: TriangleView = {
//        let view = TriangleView()
//        view.color = UIColor.ud.primaryOnPrimaryFill
//        view.direction = .top
//        view.backgroundColor = UIColor.clear
//        view.layer.borderWidth = 1.0
//        view.layer.borderColor = UIColor.ud.lineBorderCard.cgColor
//        return view
//    }()

    var leftBtnTapAction: (() -> Void)?
    var rightBtnTapAction: (() -> Void)?

    var arrowDirection: PopConfirmView.Direction = Display.phone ? .bottom : .top

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear

        addSubview(contentView)
        addSubview(arrowView)
        addSubview(whiteArrowView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(cancelButton)
        contentView.addSubview(viewOnPortraitButton)

        let tapGr = UITapGestureRecognizer(target: self, action: #selector(doNothingTapAction))
        contentView.addGestureRecognizer(tapGr)

        switch arrowDirection {
        case .top:
            contentView.snp.remakeConstraints {
                $0.width.lessThanOrEqualTo(Layout.contentMaxWidth)
                $0.left.right.bottom.equalToSuperview()
            }
            arrowView.snp.remakeConstraints {
                $0.top.centerX.equalToSuperview()
                $0.top.equalTo(contentView).offset(-6)
                $0.size.equalTo(Layout.arrowViewSize)
            }
            whiteArrowView.snp.remakeConstraints {
                $0.centerX.equalToSuperview()
                $0.top.equalTo(arrowView).offset(1)
                $0.size.equalTo(Layout.arrowViewSize)
            }
        case .bottom:
            contentView.snp.remakeConstraints {
                $0.width.lessThanOrEqualTo(Layout.contentMaxWidth)
                $0.top.left.right.equalToSuperview()
            }
            arrowView.snp.remakeConstraints {
                $0.centerX.bottom.equalToSuperview()
                $0.bottom.equalTo(contentView).offset(6)
                $0.size.equalTo(Layout.arrowViewSize)
            }
            whiteArrowView.snp.remakeConstraints {
                $0.centerX.equalToSuperview()
                $0.bottom.equalTo(arrowView).offset(-1)
                $0.size.equalTo(Layout.arrowViewSize)
            }
        }
        titleLabel.snp.remakeConstraints {
            $0.top.equalToSuperview().offset(Layout.commonVerticalSpacing)
            $0.left.right.equalToSuperview().inset(Layout.commonHorizontalSpacing)
        }
        cancelButton.snp.remakeConstraints {
            $0.left.greaterThanOrEqualToSuperview().offset(Layout.commonHorizontalSpacing)
            $0.top.equalTo(titleLabel.snp.bottom).offset(Layout.commonVerticalSpacing)
            $0.height.equalTo(Layout.commonButtonHeight)
            $0.bottom.equalToSuperview().inset(Layout.buttonBottomSpacing)
        }
        viewOnPortraitButton.snp.remakeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(Layout.commonVerticalSpacing)
            $0.left.equalTo(cancelButton.snp.right).offset(Layout.buttonHorizontalSpacing)
            $0.right.equalToSuperview().inset(Layout.commonHorizontalSpacing)
            $0.height.equalTo(Layout.commonButtonHeight)
            $0.bottom.equalToSuperview().inset(Layout.buttonBottomSpacing)
        }
    }

    @objc
    private func didTapLeftButton() {
        leftBtnTapAction?()
    }

    @objc
    private func didTapRightButton() {
        rightBtnTapAction?()
    }

    @objc
    /// block contentView 上的点击事件，避免触发沉浸态的奇怪表现
    private func doNothingTapAction() {
        // empty imp
    }

}
