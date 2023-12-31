//
//  AppDetailOperationHeaderView.swift
//  LarkAppCenter
//
//  Created by dengbo on 2021/9/6.
//

import Foundation
import LarkUIKit
import SnapKit
import UniverseDesignIcon

enum OperationButtonType: String {
    case sendMessage    // 发送消息
    case openApp        // 打开应用
    case feedback       // 反馈
}

class AppDetailOperationButton: UIButton {
    fileprivate var opType: OperationButtonType?
    
    private lazy var container: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        return view
    }()
    
    fileprivate lazy var iconView: UIImageView = {
        let imgView = UIImageView(frame: .zero)
        imgView.contentMode = .scaleAspectFill
        imgView.isUserInteractionEnabled = false
        return imgView
    }()
    
    fileprivate lazy var descLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textColor = UIColor.ud.N800
        label.isUserInteractionEnabled = false
        label.textAlignment = .center
        return label
    }()
    
    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? UIColor.ud.fillPressed : UIColor.ud.bgBodyOverlay
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 10
        layer.masksToBounds = true
        isHighlighted = false
        setupViews()
        
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        addSubview(container)
        container.addSubview(iconView)
        container.addSubview(descLabel)
        container.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview().offset(-5)
            make.bottom.lessThanOrEqualToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(5)
            make.top.greaterThanOrEqualToSuperview()
        }
    }
    
    func updateStyle(_ horizontal: Bool) {
        if horizontal {
            descLabel.textAlignment = .left
            descLabel.font =  UIFont.systemFont(ofSize: 16.0)
            iconView.snp.remakeConstraints { make in
                make.top.leading.bottom.equalToSuperview()
                make.size.equalTo(CGSize(width: 20, height: 20))
            }
            descLabel.snp.remakeConstraints { make in
                make.centerY.trailing.equalToSuperview()
                make.leading.equalTo(iconView.snp.trailing).offset(4)
            }
        } else {
            descLabel.textAlignment = .center
            descLabel.font =  UIFont.systemFont(ofSize: 11.0)
            iconView.snp.remakeConstraints { make in
                make.top.centerX.equalToSuperview()
                make.size.equalTo(CGSize(width: 20, height: 20))
            }
            descLabel.snp.remakeConstraints { make in
                make.leading.trailing.bottom.equalToSuperview()
                make.top.equalTo(iconView.snp.bottom).offset(1)
            }
        }
    }
}

class AppDetailOperationHeaderView: UIView {
    static let headerReuseID = "AppDetailOperationHeaderViewReuseID"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var container: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBody
       return view
    }()
    
    private lazy var btnContainer: UIStackView = {
        let view = UIStackView()
        view.backgroundColor = .clear
        view.axis = .horizontal
        view.alignment = .fill
        view.distribution = .fillEqually
        view.spacing = 10
        return view
    }()
    
    private lazy var sendMessageButton: AppDetailOperationButton = {
        let button = AppDetailOperationButton(frame: .zero)
        button.opType = .sendMessage
        button.iconView.image = UDIcon.chatFilled.ud.withTintColor(UIColor.ud.iconN1)
        button.addTarget(self, action: #selector(onTapped(sender:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var openAppButton: AppDetailOperationButton = {
        let button = AppDetailOperationButton(frame: .zero)
        button.opType = .openApp
        button.iconView.image = UDIcon.appDefaultFilled.ud.withTintColor(UIColor.ud.iconN1)
        button.descLabel.text = BundleI18n.AppDetail.AppDetail_Card_OpenAppTooltip
        button.addTarget(self, action: #selector(onTapped(sender:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var feedbackButton: AppDetailOperationButton = {
        let button = AppDetailOperationButton(frame: .zero)
        button.opType = .feedback
        button.iconView.image = UDIcon.feedbackFilled.ud.withTintColor(UIColor.ud.iconN1)
        button.descLabel.text = BundleI18n.AppDetail.AppDetail_Card_Feedback
        button.addTarget(self, action: #selector(onTapped(sender:)), for: .touchUpInside)
        return button
    }()
    
    private var actionOnClick: ((OperationButtonType) -> Void)?
    
    @objc
    private func onTapped(sender: AppDetailOperationButton) {
        guard let type = sender.opType else {
            return
        }
        self.actionOnClick?(type)
    }

    private func setupViews() {
        backgroundColor = UIColor.ud.bgBase
        addSubview(container)
        container.addSubview(btnContainer)
        container.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-8)
            make.height.equalTo(0)
        }
        btnContainer.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(0)
        }
    }
    
    func updateViews(buttons: [OperationButtonType], chatType: AppDetailChatType, actionOnClick: ((OperationButtonType) -> Void)?) {
        self.actionOnClick = actionOnClick
        
        if chatType == .InterActiveBot {
            sendMessageButton.descLabel.text = BundleI18n.AppDetail.AppDetail_Card_MessageBotTooltip
        } else if chatType == .NotifyBot {
            sendMessageButton.descLabel.text = BundleI18n.AppDetail.AppDetail_Card_ViewMessage
        }
        
        btnContainer.subviews.forEach {
            $0.removeFromSuperview()
        }
        
        container.snp.updateConstraints { make in
            make.height.equalTo(buttons.isEmpty ? 0 : 64)
        }
        btnContainer.snp.updateConstraints { make in
            make.bottom.equalToSuperview().offset(buttons.isEmpty ? 0 : -16)
        }
        
        let horizontalStyle = buttons.count == 1
        buttons.forEach { type in
            switch type {
            case .sendMessage:
                sendMessageButton.updateStyle(horizontalStyle)
                btnContainer.addArrangedSubview(sendMessageButton)
            case .openApp:
                openAppButton.updateStyle(horizontalStyle)
                btnContainer.addArrangedSubview(openAppButton)
            case .feedback:
                feedbackButton.updateStyle(horizontalStyle)
                btnContainer.addArrangedSubview(feedbackButton)
            }
        }
    }
}
