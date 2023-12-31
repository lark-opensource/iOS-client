//
// Created by duanxiaochen.7 on 2020/9/14.
// Affiliated with SKCommon.
//
// Description: 卡片引导

import Foundation
import UIKit
import SKFoundation
import SKUIKit
import SKResource
import Lottie
import SnapKit

class OnboardingCardViewController: OnboardingBaseViewController {

    weak var cardDataSource: OnboardingCardDataSources?

    init(id: OnboardingID, delegate: OnboardingDelegate?, dataSource: OnboardingCardDataSources?) {
        cardDataSource = dataSource
        super.init(id: id, delegate: delegate, dataSource: dataSource)
    }

    private lazy var skipButton = UIButton().construct { it in
        it.setImage(BundleResources.SKResource.Common.Global.icon_global_ipad_close_nor,
                    withColorsForStates: [(OnboardingStyle.cardSkipButtonColor, .normal),
                                          (OnboardingStyle.cardSkipButtonHighlightColor, .highlighted),
                                          (OnboardingStyle.cardSkipButtonHighlightColor, .selected)])
        it.hitTestEdgeInsets = OnboardingStyle.buttonHitTestInsets
        it.addTarget(self, action: #selector(skipButtonAction), for: .touchUpInside)
    }

    @objc
    func skipButtonAction() {
        disappearBehavior = .skip
        removeSelf()
    }

    private lazy var ackButton = UIButton().construct { it in
        it.setTitle(cardDataSource?.onboardingStartText(for: id), withFontSize: 16, fontWeight: .medium,
                    colorsForStates: [(OnboardingStyle.bubbleColor, .normal),
                                      (OnboardingStyle.bubbleColor, .highlighted),
                                      (OnboardingStyle.bubbleColor, .selected)])
        it.backgroundColor = OnboardingStyle.startButtonBackgroundColor
        it.layer.cornerRadius = OnboardingStyle.buttonCornerRadius
        it.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        it.addTarget(self, action: #selector(ackButtonAction), for: .touchUpInside)
    }

    @objc
    func ackButtonAction() {
        disappearBehavior = .acknowledge
        removeSelf()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = OnboardingStyle.maskColor

        imageBackgroundView.layer.cornerRadius = OnboardingStyle.bubbleCornerRadius
        imageBackgroundView.layer.maskedCorners = .top
        imageBackgroundView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill

        titleLabel.textAlignment = .center

        setupLayout()
    }

    func setupLayout() {
        view.addSubview(bubble)
        bubble.snp.makeConstraints { make in
            make.width.equalTo(OnboardingStyle.cardWidth)
            make.center.equalToSuperview()
        }

        bubble.addSubview(ackButton)
        ackButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.equalToSuperview().offset(OnboardingStyle.cardPadding)
            make.trailing.equalToSuperview().offset(-OnboardingStyle.cardPadding)
            make.bottom.equalToSuperview().offset(-OnboardingStyle.cardPadding)
        }

        bubble.addSubview(hintLabel)
        var hintBottomPadding = OnboardingStyle.buttonPaddingTop1
        var graphBottomAnchor = hintLabel.snp.top
        var graphBottomPadding = OnboardingStyle.cardGraphPaddingBottom1
        if cardDataSource?.onboardingTitle(for: id) != nil {
            bubble.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.bottom.equalTo(hintLabel.snp.top).offset(-OnboardingStyle.titleHintSpacing)
                make.leading.equalToSuperview().offset(OnboardingStyle.cardPadding)
                make.trailing.equalToSuperview().offset(-OnboardingStyle.cardPadding)
            }
            hintBottomPadding = OnboardingStyle.buttonPaddingTop2
            graphBottomAnchor = titleLabel.snp.top
            graphBottomPadding = OnboardingStyle.cardGraphPaddingBottom2
        }
        hintLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(ackButton.snp.top).offset(-hintBottomPadding)
            make.leading.equalToSuperview().offset(OnboardingStyle.cardPadding)
            make.trailing.equalToSuperview().offset(-OnboardingStyle.cardPadding)
        }

        if cardDataSource?.onboardingImage(for: id) != nil {
            bubble.addSubview(imageBackgroundView)
            bubble.addSubview(imageView)
            imageBackgroundView.snp.makeConstraints { make in
                make.bottom.equalTo(graphBottomAnchor).offset(-graphBottomPadding)
                make.leading.trailing.top.equalToSuperview()
                make.height.equalTo(OnboardingStyle.cardImageBackgroundHeight)
            }
            imageView.snp.makeConstraints { make in
                make.edges.equalTo(imageBackgroundView).inset(OnboardingStyle.cardPadding)
            }
        } else {
            guard cardDataSource?.onboardingLottieView(for: id) != nil, let lottieView = lottieView else {
                skAssertionFailure("卡片引导 \(id) 没有给静态图片也没有给动图")
                return
            }
            bubble.addSubview(imageBackgroundView)
            bubble.addSubview(lottieView)
            lottieView.snp.makeConstraints { make in
                make.bottom.equalTo(graphBottomAnchor).offset(-graphBottomPadding)
                make.leading.trailing.top.equalToSuperview()
            }
            imageBackgroundView.snp.makeConstraints { make in
                make.edges.equalTo(lottieView)
            }
        }

        bubble.addSubview(skipButton)
        skipButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(OnboardingStyle.cardSkipPaddingTopTrailing)
            make.size.equalTo(OnboardingStyle.cardSkipButtonSize)
            make.trailing.equalToSuperview().offset(-OnboardingStyle.cardSkipPaddingTopTrailing)
        }
    }

    deinit {
        // 边界情况处理
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
