//
//  ActionContainer.swift
//  SKBitable
//
//  Created by yinyuan on 2023/8/30.
//

import Foundation
import UniverseDesignColor

final class ActionContainer: UIView {
    
    private lazy var titleLable: UILabel = {
        let view = UILabel()
        view.font = .systemFont(ofSize: 14)
        view.textColor = UDColor.textCaption
        view.numberOfLines = 1
        return view
    }()
    
    private lazy var actionButton0: ActionButton = {
        let view = ActionButton()
        return view
    }()
    
    private lazy var actionButton1: ActionButton = {
        let view = ActionButton()
        return view
    }()
    
    private lazy var actionButton2: ActionButton = {
        let view = ActionButton()
        return view
    }()
    
    private lazy var actionsView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [actionButton0, actionButton1, actionButton2])
        view.axis = .horizontal
        view.spacing = 12
        view.alignment = .fill
        view.distribution = .fillEqually
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    private func setup() {
        addSubview(titleLable)
        addSubview(actionsView)
        
        titleLable.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(20)
            make.top.leading.trailing.equalToSuperview()
        }
        
        actionsView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(titleLable.snp.bottom).offset(8)
            make.height.equalTo(62)
        }
    }
    
    func setData(_ data: ActionContainerModel) {
        // 设置标题
        titleLable.text = data.title
        
        // 设置 buttons
        let buttons = actionsView.arrangedSubviews
        for index in 0..<buttons.count {
            let button = buttons[index]
            if let button = button as? ActionButton {
                if index < data.items.count {
                    let item = data.items[index]
                    button.isHidden = false
                    button.isUserInteractionEnabled = true
                    button.setData(item)
                } else {
                    // 多出的不需要显示
                    // 隐藏不响应事件
                    button.isHidden = true
                    button.isUserInteractionEnabled = false
                }
            } else {
                // 不会走到这里
            }
        }
    }
    
}
