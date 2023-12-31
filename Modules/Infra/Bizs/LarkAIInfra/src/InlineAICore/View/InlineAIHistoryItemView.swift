//
//  InlineAIHistoryItemView.swift
//  LarkInlineAI
//
//  Created by Guoxinyi on 2023/4/26.
//

import Foundation
import UIKit
import UniverseDesignColor
import UniverseDesignIcon

class InlineAIHistoryItemView: InlineAIItemBaseView {
    
    struct Layout {
        static let thumbsIconSize: CGSize = CGSize(width: 18, height: 18)
        static let bottomInset: CGFloat = 8
    }
    
    lazy var numLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .regular)
        label.textColor = UDColor.textTitle
        return label
    }()
    
    lazy var prePageButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UDIcon.getIconByKey(.leftBoldOutlined, size: CGSize(width: 16,height: 16)).ud.withTintColor(UDColor.iconN1), for: .normal)
        btn.setImage(UDIcon.getIconByKey(.leftBoldOutlined, size: CGSize(width: 16,height: 16)).ud.withTintColor(UDColor.iconDisabled), for: .disabled)
        btn.addTarget(self, action: #selector(didClickPreBtn), for: .touchUpInside)
        btn.hitTestEdgeInsets = .init(top: -16, left: -16, bottom: -16, right: -16)
        return btn
    }()
    
    lazy var nextPageButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UDIcon.getIconByKey(.rightBoldOutlined, size: CGSize(width: 16,height: 16)).ud.withTintColor(UDColor.iconN1), for: .normal)
        btn.setImage(UDIcon.getIconByKey(.rightBoldOutlined, size: CGSize(width: 16,height: 16)).ud.withTintColor(UDColor.iconDisabled), for: .disabled)
        btn.addTarget(self, action: #selector(didClickNextBtn), for: .touchUpInside)
        btn.hitTestEdgeInsets = .init(top: -16, left: -16, bottom: -16, right: -16)
        return btn
    }()
    
    lazy var thumbsupButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UDIcon.getIconByKey(.thumbsupOutlined, iconColor: UDColor.iconN3, size: Layout.thumbsIconSize), for: .normal)
        btn.setImage(UDIcon.getIconByKey(.thumbsupFilled, iconColor: UDColor.yellow, size: Layout.thumbsIconSize), for: .selected)
        btn.addTarget(self, action: #selector(didClickThumbUpBtn), for: .touchUpInside)
        btn.hitTestEdgeInsets = .init(top: -12, left: -12, bottom: -8, right: -8)
        return btn
    }()
    
    lazy var thumbsdownButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UDIcon.getIconByKey(.thumbdownOutlined, iconColor: UDColor.iconN3, size: Layout.thumbsIconSize), for: .normal)
        btn.setImage(UDIcon.getIconByKey(.thumbdownFilled, iconColor: UDColor.iconN3, size: Layout.thumbsIconSize), for: .selected)
        btn.addTarget(self, action: #selector(didClickThumbDownBtn), for: .touchUpInside)
        btn.hitTestEdgeInsets = .init(top: -12, left: -8, bottom: -8, right: -12)
        return btn
    }()
    
    var containerView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.left.right.bottom.equalToSuperview()
        }
        containerView.addSubview(prePageButton)
        prePageButton.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.width.height.equalTo(16)
            make.centerY.equalToSuperview()
        }
        
        containerView.addSubview(numLabel)
        numLabel.setContentHuggingPriority(.defaultHigh + 1, for: .horizontal)
        numLabel.snp.makeConstraints { make in
            make.left.equalTo(prePageButton.snp.right).offset(6)
            make.height.equalTo(20)
            make.centerY.equalToSuperview()
        }
        
        containerView.addSubview(nextPageButton)
        nextPageButton.snp.makeConstraints { make in
            make.left.equalTo(numLabel.snp.right).offset(6)
            make.width.height.equalTo(prePageButton)
            make.centerY.equalToSuperview()
        }
        
        containerView.addSubview(thumbsdownButton)
        thumbsdownButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(4)
            make.height.equalToSuperview()
            make.width.equalTo(34)
            make.centerY.equalToSuperview()
        }

        containerView.addSubview(thumbsupButton)
        thumbsupButton.snp.makeConstraints { make in
            make.right.equalTo(thumbsdownButton.snp.left)
            make.width.height.equalTo(thumbsdownButton)
            make.centerY.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateHistory(text: String, leftEnable: Bool, rightEnable: Bool, hideHistory: Bool, showThumbsBtn: Bool, like: Bool, unlike: Bool) {
        numLabel.text = text
        prePageButton.isEnabled = leftEnable
        nextPageButton.isEnabled = rightEnable
        numLabel.isHidden = hideHistory
        prePageButton.isHidden = hideHistory
        nextPageButton.isHidden = hideHistory
        thumbsdownButton.isHidden = !showThumbsBtn
        thumbsupButton.isHidden = !showThumbsBtn
        if showThumbsBtn {
            thumbsdownButton.isSelected = unlike
            thumbsupButton.isSelected = like
        } else {
            thumbsdownButton.isSelected = false
            thumbsupButton.isSelected = false
        }
    }
    
    @objc
    private func didClickPreBtn() {
        eventRelay.accept(.clickPrePage)
    }
    
    @objc
    private func didClickNextBtn() {
        eventRelay.accept(.clickNextPage)
    }
    
    @objc
    private func didClickThumbUpBtn() {
        let selected = thumbsupButton.isSelected
        thumbsdownButton.isSelected = false
        thumbsupButton.isSelected = !selected
        eventRelay.accept(.clickThumbUp(isSelected: thumbsupButton.isSelected))
    }
    
    @objc
    private func didClickThumbDownBtn() {
        let selected = thumbsdownButton.isSelected
        thumbsupButton.isSelected = false
        thumbsdownButton.isSelected = !selected
        eventRelay.accept(.clickThumbDown(isSelected: thumbsdownButton.isSelected))
    }
}
