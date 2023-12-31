//
//  LoadableButton.swift
//  ByteView
//
//  Created by chenyizhuo on 2021/3/29.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UIKit

class LoadableButton: UIButton {
    private lazy var whiteLoading = LoadingView(frame: CGRect(x: 0, y: 0, width: 36, height: 36), style: .white)
    private lazy var blueLoading = LoadingView(frame: CGRect(x: 0, y: 0, width: 36, height: 36), style: .blue)

    private var loading: LoadingView { style == .fill ? whiteLoading : blueLoading }

    private let title: String
    private let normalColor = UIColor.ud.primaryContentDefault
    private let loadingColor = UIColor.ud.primaryFillSolid03
    private let loadingTextColor = UIColor.ud.primaryContentDefault.withAlphaComponent(0.5)
    private let failedColor = UIColor.ud.N400

    private var currentState: State = .normal {
        didSet {
            updateViews()
        }
    }

    var style: Style = .fill {
        didSet {
            updateViews()
        }
    }

    init(title: String) {
        self.title = title
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func startLoading() {
        guard currentState != .loading else { return }
        currentState = .loading
    }

    func stopLoading(success: Bool) {
        guard currentState == .loading else { return }
        currentState = success ? .normal : .failed
    }

    private func setupViews() {
        layer.masksToBounds = true
        layer.cornerRadius = 4
        setTitle(title, for: .normal)

        whiteLoading.isHidden = true
        addSubview(whiteLoading)
        blueLoading.isHidden = true
        addSubview(blueLoading)

        updateViews()
    }

    private func updateViews() {
        let backgroundColor: UIColor
        let disabledBackgroundColor: UIColor
        let titleColor: UIColor
        let disabledTitleColor: UIColor
        let titleLeftOffset: CGFloat
        if style == .fill {
            backgroundColor = normalColor
            disabledBackgroundColor = currentState == .loading ? loadingColor : failedColor
            titleColor = .white
            disabledTitleColor = UIColor.ud.udtokenBtnPriTextDisabled
            titleLeftOffset = currentState == .loading ? 16 : 0
        } else {
            backgroundColor = .clear
            titleColor = normalColor
            disabledBackgroundColor = .clear
            disabledTitleColor = currentState == .loading ? loadingTextColor : failedColor
            titleLeftOffset = 16
        }
        vc.setBackgroundColor(backgroundColor, for: .normal)
        vc.setBackgroundColor(disabledBackgroundColor, for: .disabled)
        setTitleColor(titleColor, for: .normal)
        setTitleColor(disabledTitleColor, for: .disabled)
        titleEdgeInsets = UIEdgeInsets(top: 0, left: titleLeftOffset, bottom: 0, right: 0)

        let font = style == .fill ? UIFont.systemFont(ofSize: 17, weight: .regular) : UIFont.systemFont(ofSize: 14, weight: .regular)
        titleLabel?.font = font

        if currentState == .loading {
            let showView = style == .fill ? whiteLoading : blueLoading
            let hideView = style == .fill ? blueLoading : whiteLoading

            let offset = title.vc.boundingWidth(height: 48, font: font)
            showView.snp.remakeConstraints { (maker) in
                maker.right.equalTo(snp.centerX).offset(-offset / 2.0)
                maker.centerY.equalToSuperview()
                maker.size.equalTo(CGSize(width: 16, height: 16))
            }
            showView.isHidden = false
            hideView.isHidden = true
            showView.play()
        } else {
            whiteLoading.stop()
            whiteLoading.isHidden = true
            blueLoading.stop()
            blueLoading.isHidden = true
        }
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: super.intrinsicContentSize.width + 20, height: super.intrinsicContentSize.height)
    }

    enum Style {
        case fill, light
    }

    private enum State {
        case normal, loading, failed
    }
}
