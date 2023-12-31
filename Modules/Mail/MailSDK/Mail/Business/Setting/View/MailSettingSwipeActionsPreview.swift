//
//  MailSettingSwipeActionsPreview.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2023/1/29.
//

import Foundation
import FigmaKit
import LarkSwipeCellKit
import UniverseDesignIcon
import UniverseDesignColor

class MailSettingSwipeActionsPreview: UIView {
    var orientation: SwipeActionsOrientation = .left
    var actions: [MailThreadCellSwipeAction] = []
    
    private var actionsContainer = UIStackView()
    private var threadCellContainer = UIView()
    private var borderView = UIView()
    
    func setActionsAndLayoutView(orientation: SwipeActionsOrientation,
                                 actions: [MailThreadCellSwipeAction]) {
        self.orientation = orientation
        self.actions = actions
        resetPreview()
        setupViews()
    }
    
    func resetPreview() {
        actionsContainer.removeFromSuperview()
        threadCellContainer.removeFromSuperview()
        borderView.removeFromSuperview()
        actionsContainer = UIStackView()
        threadCellContainer = UIView()
        borderView = UIView()
    }
    
    /// 提供给外部调用的Onboard动画接口
    func swipeOnboard() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        if orientation == .left {
            animation.values = [-CGFloat(actions.count * 70), 0]
        } else {
            animation.values = [CGFloat(actions.count * 70), 0]
        }
        animation.duration = 0.5
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        animation.repeatCount = 1
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        threadCellContainer.layer.add(animation, forKey: nil)
        actionsContainer.layer.add(animation, forKey: nil)
    }
    
    private func setupViews() {
        layer.cornerRadius = 8
        layer.masksToBounds = true
        clipsToBounds = true
        configThreadListCell()
        configActionsContainer()
    }
    
    private func configActionsContainer() {
        actionsContainer.axis = .horizontal
        actionsContainer.spacing = 0
        actionsContainer.alignment = .leading
        actionsContainer.distribution = .fillEqually
        actionsContainer.setContentHuggingPriority(.required, for: .horizontal)
        actionsContainer.setContentCompressionResistancePriority(.required, for: .horizontal)
        actionsContainer.backgroundColor = .darkGray
        actionsContainer.clipsToBounds = true
        addSubview(actionsContainer)
        actionsContainer.snp.makeConstraints { make in
            if orientation == .left {
                make.leading.equalToSuperview()
            } else {
                make.trailing.equalToSuperview()
            }
            make.top.height.equalToSuperview()
            make.width.equalTo(actions.count * 70)
        }
        
        for action in actions {
            let actionButton = MailSwipeActionButton(icon: action.actionIcon(), title: action.actionTitle())
            actionButton.backgroundColor = action.actionBgColor()
            
            actionButton.clipsToBounds = true
            actionsContainer.addArrangedSubview(actionButton)
            actionButton.snp.makeConstraints { (make) in
                make.size.equalTo(CGSize(width: 70, height: 80))
                make.centerY.equalToSuperview()
            }
        }
    }
    
    private func configThreadListCell() {
        addSubview(threadCellContainer)
        threadCellContainer.backgroundColor = .clear
        threadCellContainer.snp.makeConstraints { make in
            if orientation == .left {
                make.leading.equalTo(actions.count * 70)
            } else {
                make.trailing.equalTo(-actions.count * 70)
            }
            make.top.width.height.equalToSuperview()
        }
        
        let senderView = UIView()
        let titleView = UIView()
        let summaryView = UIView()
        threadCellContainer.addSubview(senderView)
        threadCellContainer.addSubview(titleView)
        threadCellContainer.addSubview(summaryView)
        
        senderView.backgroundColor = .ud.N300
        senderView.layer.cornerRadius = 5
        senderView.layer.masksToBounds = true
        senderView.snp.makeConstraints { make in
            make.leading.equalTo(16)
            make.trailing.equalTo(-145)
            make.top.equalTo(15)
            make.height.equalTo(10)
        }
        
        titleView.backgroundColor = .ud.N200
        titleView.layer.cornerRadius = 5
        titleView.layer.masksToBounds = true
        titleView.snp.makeConstraints { make in
            make.leading.equalTo(16)
            make.top.equalTo(senderView.snp.bottom).offset(10)
            make.trailing.equalTo(-181)
            make.height.equalTo(10)
        }
        
        summaryView.backgroundColor = .ud.bgFiller
        summaryView.layer.cornerRadius = 5
        summaryView.layer.masksToBounds = true
        summaryView.snp.makeConstraints { make in
            make.leading.equalTo(16)
            make.trailing.equalTo(-43)
            make.top.equalTo(titleView.snp.bottom).offset(10)
            make.height.equalTo(10)
        }
        
        if orientation == .right {
            let timeView = UIView()
            let flagView = UIImageView(image: UDIcon.flagOutlined.withRenderingMode(.alwaysTemplate))
            flagView.tintColor = .ud.iconDisabled
            threadCellContainer.addSubview(timeView)
            threadCellContainer.addSubview(flagView)
            timeView.backgroundColor = .ud.N200
            timeView.layer.cornerRadius = 5
            timeView.layer.masksToBounds = true
            timeView.snp.makeConstraints { make in
                make.trailing.equalTo(-16)
                make.top.equalTo(15)
                make.height.equalTo(10)
                make.width.equalTo(40)
            }
            
            flagView.snp.makeConstraints { make in
                make.trailing.equalTo(-16)
                make.centerY.equalTo(summaryView)
                make.width.height.equalTo(14)
            }
        }

        borderView.layer.cornerRadius = 8
        borderView.layer.masksToBounds = true
        borderView.layer.borderWidth = 1.0
        borderView.backgroundColor = .clear
        let borderColor = UIColor.mail.rgb("#DEE0E3") & UIColor.mail.rgb("#373737")
        borderView.layer.ud.setBorderColor(borderColor)
        addSubview(borderView)
        borderView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

class MailSwipeActionButton: UIButton {
    
    private let imageSize = CGSize(width: 18, height: 18)
    private let title: String
    
    init(icon: UIImage, title: String) {
        self.title = title
        super.init(frame: CGRect(origin: .zero, size: CGSize(width: 70, height: 80)))
        
        setTitle(title, for: .normal)
        titleLabel?.font = UIFont.systemFont(ofSize: 12.0, weight: .medium)
        titleLabel?.textAlignment = .center
        titleLabel?.lineBreakMode = .byTruncatingTail
        titleLabel?.numberOfLines = 1
        
        setImage(icon, for: .normal)
        imageView?.contentMode = .scaleAspectFit
        contentVerticalAlignment = .center
        contentHorizontalAlignment = .center
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if self.title.getTextWidth(font: UIFont.systemFont(ofSize: 12.0, weight: .medium), height: 18) <= (70 - 8) {
            imageView?.frame = CGRect(origin: CGPoint(x: (frame.width - imageSize.width) / 2.0, y: 20), size: imageSize)
            titleLabel?.frame = CGRect(origin: CGPoint(x: 4, y: 42), size: CGSize(width: frame.width - 8, height: 18))
        } else {
            imageView?.frame = CGRect(origin: CGPoint(x: (frame.width - imageSize.width) / 2.0, y: 16), size: imageSize)
            titleLabel?.font = UIFont.systemFont(ofSize: 10.0, weight: .medium)
            titleLabel?.numberOfLines = 2
            titleLabel?.frame = CGRect(origin: CGPoint(x: 4, y: 38), size: CGSize(width: frame.width - 8, height: 26))
        }
        
    }
}

