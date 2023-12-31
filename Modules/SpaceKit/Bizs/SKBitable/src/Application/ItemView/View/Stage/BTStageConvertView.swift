//
//  BTStageConvertView.swift
//  SKBitable
//
//  Created by X-MAN on 2023/6/15.
//

import Foundation
import UniverseDesignColor
import UniverseDesignButton
import UniverseDesignIcon
import SKResource
import SKBrowser
import UniverseDesignProgressView
import UniverseDesignToast

fileprivate let notStartText = BundleI18n.SKResource.Bitable_Flow_RecordCard_NotStarted_Text
fileprivate let completeText = BundleI18n.SKResource.Bitable_Flow_RecordCard_CompleteStep_Button
fileprivate let progressingText = BundleI18n.SKResource.Bitable_Flow_RecordCard_InProgress_Text
fileprivate let doneText = BundleI18n.SKResource.Bitable_Flow_RecordCard_Done_Text

final class BTStageDetailConvertStateView: UIView {
    
    private var state: BTStageModel.StageNodeState?
    
    private lazy var imageView: UIImageView = {
        let imgView = UIImageView()
        return imgView
    }()
    
    private lazy var textLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
    private lazy var progressView: UDProgressView = {
        let theme = UDProgressViewThemeColor(bgColor: UDColor.lineBorderCard, indicatorColor: UDColor.O350)
        let uiConfig = UDProgressViewUIConfig(type: .circular, themeColor: theme)
        let layoutConfig = UDProgressViewLayoutConfig(circleProgressWidth: 16)
        let progress = UDProgressView(config: uiConfig, layoutConfig: layoutConfig)
        progress.setProgress(0.8, animated: false)
        return progress
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    init() {
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        addSubview(imageView)
        addSubview(textLabel)
        addSubview(progressView)
        textLabel.snp.makeConstraints { make in
            make.trailing.top.bottom.equalToSuperview()
        }
        imageView.snp.makeConstraints { make in
            make.trailing.equalTo(textLabel.snp.leading).offset(-6)
            make.centerY.equalToSuperview()
            make.size.equalTo(16)
        }
        progressView.snp.makeConstraints { make in
            make.trailing.equalTo(textLabel.snp.leading).offset(-6)
            make.centerY.equalToSuperview()
            make.size.equalTo(16)
        }
    }
    
    func config(state: BTStageModel.StageNodeState) {
        guard self.state != state else { return }
        self.state = state
        switch state {
        case .finish:
            imageView.layer.borderColor = UIColor.clear.cgColor
            imageView.layer.borderWidth = 0
            imageView.image = UDIcon.yesFilled.ud.withTintColor(UDColor.G400)
            textLabel.text = doneText
            textLabel.textColor = UDColor.G400
            imageView.isHidden = false
            progressView.isHidden = true
        case .pending:
            imageView.image = UDIcon.timeOutlined.ud.withTintColor(UDColor.iconN3)
            textLabel.text = notStartText
            textLabel.textColor = UDColor.iconN3
            progressView.isHidden = true
            imageView.isHidden = false
        case .progressing:
            progressView.isHidden = false
            imageView.isHidden = true
            textLabel.text = progressingText
            textLabel.textColor = UDColor.O350
        }
    }
    
}

final class BTStageDetailConvertView: UIView {
    
    private let sepline = UIView()
    private var status: BTStageModel.StageNodeState = .pending
    private var isCancel: Bool = false
    var convertButtonClick: (() -> Void)?
    var revertButtonClick: ((UIView) -> Void)?
    
    private lazy var indicator: BTStageItemView = {
        let view = BTStageItemView(with: .big)
        return view
    }()
    
    private lazy var finishButton: UDButton = {
        let config = UDButtonUIConifg.primaryBlue
        let button = UDButton(config)
        button.setTitle(completeText, for: .normal)
        button.addTarget(self, action: #selector(stateButtonClick), for: .touchUpInside)
        return button
    }()
    
    private lazy var stateView: BTStageDetailConvertStateView = {
        return BTStageDetailConvertStateView()
    }()
        
    private lazy var revertButton: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.downOutlined, for: [.normal, .highlighted])
        button.addTarget(self, action: #selector(revertClick), for: .touchUpInside)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.setContentHuggingPriority(.required, for: .horizontal)
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        sepline.backgroundColor = UDColor.lineBorderCard
        addSubview(indicator)
        addSubview(revertButton)
        addSubview(finishButton)
        addSubview(stateView)
        addSubview(sepline)
        sepline.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
        revertButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.size.equalTo(16)
        }
        let size = finishButton.sizeThatFits(CGSize(width: Double.infinity, height: Double.infinity))
        finishButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-12)
            make.width.equalTo(size.width)
        }
        
        stateView.snp.makeConstraints { make in
            make.trailing.equalTo(revertButton.snp.leading)
            make.centerY.equalToSuperview()
            make.width.greaterThanOrEqualTo(64)
        }
        let tapGes = UITapGestureRecognizer(target: self, action: #selector(stateViewTap))
        stateView.addGestureRecognizer(tapGes)
    }
    
    func setData(_ model: BTStageModel, canceled: Bool, hasPermission: Bool) {
        status = model.status
        isCancel = canceled
        if canceled {
            finishButton.isHidden = true
            stateView.isHidden = true
            revertButton.isHidden = true
        } else {
            if status == .finish {
                revertButton.isHidden = !hasPermission
                finishButton.isHidden = true
                stateView.isHidden = false
            } else {
                revertButton.isHidden = true
                finishButton.isHidden = !hasPermission
                stateView.isHidden = hasPermission
            }
        }
        indicator.configInDetail(name: model.name, status: model.status, isInConvert: true)
//        let indicatorWidth = indicator.width()
        if !stateView.isHidden {
            stateView.snp.remakeConstraints { make in
                if revertButton.isHidden {
                    make.trailing.equalToSuperview().offset(-12)
                } else {
                    make.trailing.equalTo(revertButton.snp.leading).offset(-16)
                }
                make.centerY.equalToSuperview()
                make.width.greaterThanOrEqualTo(64)
            }
            stateView.config(state: status)
            indicator.snp.remakeConstraints { make in
                make.centerY.equalToSuperview()
                make.leading.equalToSuperview().offset(15)
                make.trailing.lessThanOrEqualTo(stateView.snp.leading).offset(-12)
                make.height.equalToSuperview()
            }
        } else {
            indicator.snp.remakeConstraints { make in
                make.centerY.equalToSuperview()
                make.leading.equalToSuperview().offset(15)
                make.height.equalToSuperview()
                make.trailing.equalTo(finishButton.snp.leading).offset(-12).priority(.required)
            }
        }
        
    }
    
    @objc
    private func stateButtonClick() {
        if status != .finish {
            convertButtonClick?()
        }
    }
    
    @objc
    private func revertClick() {
        if status == .finish {
            revertButtonClick?(revertButton)
        }
    }
    
    @objc
    private func stateViewTap() {
        switch status {
        case .pending, .progressing:
            if let window = window {
                UDToast.showTips(with: BundleI18n.SKResource.Bitable_Flow_RecordCard_NoPermitComplete_Desc, on: window)
            }
        case .finish:
            break
        }
    }
    
}
