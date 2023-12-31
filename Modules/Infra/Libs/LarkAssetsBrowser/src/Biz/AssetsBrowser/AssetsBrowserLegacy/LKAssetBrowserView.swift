//
//  LKAssetBrowserView.swift
//  LarkAssetsBrowser
//
//  Created by Hayden Wang on 2021/12/7.
//

import Foundation
import UIKit
import SnapKit

final class LKAssetBrowserView: UIView {

    public private(set) lazy var backScrollView: UIScrollView! = {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = UIColor.clear
        scrollView.alwaysBounceHorizontal = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.isPagingEnabled = true
        scrollView.contentInsetAdjustmentBehavior = .never
        return scrollView
    }()

    lazy var photoIndexLabel: UILabel = {
        let label = UILabel()
        label.layer.cornerRadius = 6
        label.layer.masksToBounds = true
        label.font = UIFont.ud.body2(.fixed)
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.backgroundColor = Cons.buttonColor
        return label
    }()

    lazy var showOriginButton: ShowOriginButton = {
        let button = ShowOriginButton()
        button.layer.cornerRadius = 16
        button.layer.masksToBounds = true
        button.font = UIFont.ud.body2(.fixed)
        button.textColor = UIColor.ud.primaryOnPrimaryFill
        button.backgroundColor = Cons.buttonColor
        return button
    }()

    lazy var actionButtonContainer: UIStackView = {
        let stack = UIStackView()
        stack.alignment = .trailing
        stack.spacing = 12
        return stack
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

    }

    private func setup() {
        setupSubviews()
        setupConstraints()
        setupAppearance()
    }

    private func setupSubviews() {
        addSubview(backScrollView)
        addSubview(photoIndexLabel)
        addSubview(showOriginButton)
        addSubview(actionButtonContainer)
    }

    private func setupConstraints() {
        photoIndexLabel.snp.makeConstraints { (make) in
            make.height.equalTo(28)
            make.left.equalToSuperview().offset(16)
            make.centerY.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-22)
        }
        actionButtonContainer.snp.makeConstraints { make in
            make.height.equalTo(32)
            make.right.equalToSuperview().offset(-20)
            make.centerY.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-22)
        }
        showOriginButton.snp.makeConstraints { make in
            make.width.greaterThanOrEqualTo(96).priority(.high)
            make.height.equalTo(32)
            make.left.equalToSuperview().offset(20)
            make.right.lessThanOrEqualTo(actionButtonContainer.snp.left).offset(10)
            make.centerY.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-22)
        }
    }

    private func setupAppearance() {
        backgroundColor = .black
    }
}

extension LKAssetBrowserView {

    enum Cons {
        static var buttonColor: UIColor {
            UIColor.ud.N600.nonDynamic.withAlphaComponent(0.6)
        }
        static var buttonHighlightColor: UIColor {
            UIColor.ud.colorfulBlue.nonDynamic
        }
    }
}
