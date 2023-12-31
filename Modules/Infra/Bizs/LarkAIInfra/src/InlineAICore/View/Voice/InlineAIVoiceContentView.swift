//
//  InlineAIVoiceContentView.swift
//  LarkAIInfra
//
//  Created by ByteDance on 2023/9/22.
//

import Foundation
import UniverseDesignFont
import UniverseDesignColor
import UniverseDesignIcon
import RxSwift
import RxCocoa

/// 语音SDK的AI面板视图
class InlineAIVoiceContentView: UIView {
    
    var onThemeChange: (() -> Void)?
    
    var onAIEvent: ((InlineAIEvent) -> Void)?
    
    private lazy var headerView = InlineAIVoiceContentHeaderView()
    
    private let disposeBag = DisposeBag()
    
    private lazy var contentView: InlineAIContentView = {
        let bgColor = UDColor.bgBodyOverlay
        let v = InlineAIContentView(customContentView: nil, webCustomBgColor: bgColor, fullHeightMode: true)
        v.eventRelay.subscribe(onNext: { [weak self] event in
            self?.onAIEvent?(event)
        }).disposed(by: disposeBag)
        v.setWebContentViewOpaque(false)
        v.backgroundColor = .clear
        return v
    }()
    
    private lazy var footerView = InlineAIVoiceContentFooterView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubviews() {
        
        self.addSubview(headerView)
        headerView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(44)
        }
        
        self.addSubview(footerView)
        footerView.snp.makeConstraints {
            $0.bottom.equalToSuperview()
            $0.leading.trailing.equalToSuperview()
        }
        
        self.addSubview(contentView)
        contentView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom)
            $0.leading.trailing.equalToSuperview().inset(10)
            $0.bottom.equalTo(footerView.snp.top)
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard #available(iOS 13.0, *) else { return }
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
        guard UIApplication.shared.applicationState != .background else { return }
        onThemeChange?()
    }
}

extension InlineAIVoiceContentView {
    
    var onCloseClick: (() -> Void)? {
        get { headerView.onClickClose }
        set { headerView.onClickClose = newValue }
    }
    
    var onFinishClick: (() -> Void)? {
        get { footerView.onClickFinish }
        set { footerView.onClickFinish = newValue }
    }
    
    var onStopClick: (() -> Void)? {
        get { footerView.onClickStop }
        set { footerView.onClickStop = newValue }
    }
    
    var tabIndexChanged: ((Int) -> Void)? {
        get { headerView.tabIndexChanged }
        set { headerView.tabIndexChanged = newValue }
    }
    
    func setTitle(_ title: String?) {
        headerView.setTitle(title)
    }
    
    func setTabTitles(_ titles: [String]) {
        headerView.setTabTitles(titles)
    }
    
    func updateContent(_ content: String, theme: String, conversationId: String, taskId: String, isFinish: Bool) {
        contentView.updateContent(content, extra: nil, theme: theme, conversationId: conversationId, taskId: taskId, isFinish: isFinish)
    }
    
    func setState(_ state: AIAsrSDKState) {
        footerView.setState(state)
    }
}
