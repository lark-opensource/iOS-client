//
//  InlineAIVoiceContentFooterView.swift
//  LarkAIInfra
//
//  Created by ByteDance on 2023/9/24.
//

import Foundation
import RxSwift
import RxCocoa
import UniverseDesignFont
import UniverseDesignColor
import UniverseDesignIcon

final class InlineAIVoiceContentFooterView: UIView {
    
    /// 点击`完成`回调
    var onClickFinish: (() -> Void)?
    
    /// 点击`中止`回调
    var onClickStop: (() -> Void)?
    
    private var currentState: AIAsrSDKState = .idle
    
    private let disposeBag = DisposeBag()
    
    private lazy var tipsIconImgv: UIImageView = {
        let v = UIImageView(image: UDIcon.infoOutlined.withRenderingMode(.alwaysTemplate))
        v.tintColor = UDColor.iconDisabled
        return v
    }()
    
    private lazy var tipsLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UDFont.systemFont(ofSize: 12)
        label.textColor = UDColor.textPlaceholder
        label.text = BundleI18n.LarkAIInfra.MyAI_IM_VoiceMessage_PolishTextDisclaimer_AI_Text
        return label
    }()
    
    private lazy var finishBtn: UIButton = {
        let btn = UIButton()
        btn.setTitleColor(UDColor.textTitle, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        btn.clipsToBounds = true
        btn.layer.cornerRadius = 6
        btn.layer.borderWidth = 1
        let title = BundleI18n.LarkAIInfra.MyAI_IM_VoiceMessage_PolishText_Replace_Button
        btn.setTitle(title, for: .normal)
        btn.addTarget(self, action: #selector(onClick), for: .touchUpInside)
        return btn
    }()
    
    /// `生成中`指示视图
    private lazy var indicatorView: InlineAIItemInputView = {
        let v = InlineAIItemInputView()
        v.updateContainerBackgroundColor(UIColor(white: 0, alpha: 0.05))
        v.eventRelay.subscribe(onNext: { [weak self] event in
            if case .stopGenerating = event {
                self?.onClickStop?()
            }
        }).disposed(by: disposeBag)
        v.updateTextviewBackgroundColor(.clear)
        return v
    }()
    
    private func updateLayout(_ state: AIAsrSDKState) {
        if stateNoChange(state) { return } // state一致无需更新布局
        currentState = state
        
        subviews.forEach { $0.removeFromSuperview() }
        switch state {
        case .idle:
            break
        case .writing:
            setupProcessingView()
        case .finished:
            setupFinishView()
        }
    }
    
    private func stateNoChange(_ state: AIAsrSDKState) -> Bool {
        switch state {
        case .idle:
            if case .idle = currentState { return true }
        case .writing:
            if case .writing = currentState { return true }
        case .finished:
            if case .finished = currentState { return true }
        }
        return false
    }
    
    private func setupProcessingView() {
        
        addSubview(indicatorView)
        indicatorView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(10)
            $0.height.equalTo(48)
            $0.top.bottom.equalToSuperview().inset(10)
        }
    }
    
    private func setupFinishView() {
        
        addSubview(finishBtn)
        finishBtn.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(Layout.footerBtnHorizentalMargin)
            $0.height.equalTo(Layout.footerBtnHeight)
            $0.bottom.equalTo(-Layout.footerBtnBottomMargin)
        }
        
        addSubview(tipsLabel)
        tipsLabel.snp.makeConstraints {
            $0.top.equalTo(12)
            $0.leading.equalTo(Layout.footerBtnHorizentalMargin + Layout.tipsIconSize + 4)
            $0.trailing.equalTo(-Layout.footerBtnHorizentalMargin)
            $0.bottom.equalTo(finishBtn.snp.top).offset(-8)
            $0.height.greaterThanOrEqualTo(Layout.tipsIconSize)
        }
        
        addSubview(tipsIconImgv)
        tipsIconImgv.snp.makeConstraints {
            $0.left.equalTo(Layout.footerBtnHorizentalMargin)
            $0.size.equalTo(Layout.tipsIconSize)
            $0.centerY.equalTo(tipsLabel)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateFinishButtonStyle()
    }
    
    private func updateFinishButtonStyle() {
        let x = Layout.footerBtnHorizentalMargin
        let width = bounds.width - (2 * x)
        let y = bounds.height - Layout.footerBtnBottomMargin - Layout.footerBtnHeight
        let height = Layout.footerBtnHeight
        let btnBounds = CGRect(x: x, y: y, width: width, height: height)
        finishBtn.setButtonStyle(isGradient: true, bounds: btnBounds, xMargin: 16)
        finishBtn.setBackgroundImage(UIImage.ud.fromPureColor(UDColor.bgBody), for: .normal)
    }
    
    @objc
    private func onClick() {
        onClickFinish?()
    }
}

extension InlineAIVoiceContentFooterView {
    
    func setState(_ state: AIAsrSDKState) {
        
        updateLayout(state)
        
        switch state {
        case .idle, .finished:
            break
        case .writing(let model):
            if let input = model.input {
                indicatorView.update(model: input, fullRoundedcorners: false)
            } else {
                LarkInlineAILogger.error("input model is nil")
            }
        }
    }
}

private struct Layout {
    static let tipsIconSize: CGFloat = 16
    static let footerBtnHorizentalMargin: CGFloat = 10
    static let footerBtnHeight: CGFloat = 36
    static let footerBtnBottomMargin: CGFloat = 10
}
