//
//  ReminderItemView.swift
//  SpaceKit
//
//  Created by nine on 2019/3/20.
//  Copyright © 2019 nine. All rights reserved.
//

import SKFoundation
import SKUIKit
import SnapKit
import SKCommon
import SKResource
import UniverseDesignColor

protocol ReminderItemView: DocsListItemView {}

protocol ReminderItemViewWithArrow: ReminderItemView {
    var arrowDirection: UIMenuController.ArrowDirection { get set }
    var arrowView: UIImageView { get set }
}

extension ReminderItemViewWithArrow {
    mutating func setArrowState(to state: UIMenuController.ArrowDirection) {
        arrowDirection = state
    }
}

extension ReminderItemView where Self: UIButton {
    func setupUI() {
        let itemLine = DocsItemLine()
        addSubview(leftTitle)
        addSubview(rightView)
        addSubview(itemLine)
        docs.addStandardHover()
        
        //rightView优先，具体宽度子类决定
        rightView.snp.makeConstraints { (make) in
            make.trailing.equalToSuperview().inset(16)
            make.width.equalTo(45)
            make.height.centerY.equalToSuperview()
        }
        leftTitle.snp.remakeConstraints { (make) in
            make.leading.equalToSuperview().inset(16)
            make.trailing.lessThanOrEqualTo(rightView.snp.leading).offset(-4)
            make.height.equalTo(30)
            make.centerY.equalToSuperview()
        }
        itemLine.snp.makeConstraints { (make) in
            make.trailing.bottom.equalToSuperview()
            make.leading.equalToSuperview().inset(16)
            make.height.equalTo(0.5)
        }
    }
}

class ReminderSwitchItemView: UIButton, ReminderItemView {
    typealias RightView = UISwitch
    lazy var leftTitle: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UDColor.textTitle
        return label
    }()
    lazy var rightView: UISwitch = {
        let view = UISwitch()
        return view
    }()
    var tapCallback: ((UISwitch) -> Void)?

    init(title: String) {
        super.init(frame: .zero)
        leftTitle.text = title
        setupUI()
        //rightView优先，但不能超过1/2
        rightView.snp.remakeConstraints { (make) in
            make.trailing.equalToSuperview().inset(16)
            make.width.lessThanOrEqualToSuperview().dividedBy(2)
            make.height.centerY.equalTo(leftTitle)
        }
        docs.removeAllPointer()
        rightView.contentHorizontalAlignment = .right
        addTarget(self, action: #selector(onTap(gesture:)), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func onTap(gesture: UITapGestureRecognizer) {
        tapCallback?(rightView)
    }
}

class ReminderPickerItemView: UIButton, ReminderItemViewWithArrow {
    typealias RightView = UILabel
    lazy var leftTitle: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UDColor.textTitle
        return label
    }()
    lazy var rightView: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 16)
        view.textAlignment = .right
        view.textColor = UDColor.textCaption
        return view
    }()
    var arrowDirection: UIMenuController.ArrowDirection = .down {
        didSet {
            if arrowDirection == .down {
                arrowView.image = BundleResources.SKResource.Common.Icon.icon_down_outlined
            } else if arrowDirection == .up {
                arrowView.image = BundleResources.SKResource.Common.Icon.icon_down_outlined.sk.rotate(radians: Float.pi)
            }
        }
    }
    lazy var arrowView: UIImageView = UIImageView(image: BundleResources.SKResource.Common.Icon.icon_down_outlined)
    var tapCallback: ((UILabel) -> Void)?
    
    override var isEnabled: Bool {
        didSet {
            if isEnabled {
                leftTitle.textColor = UDColor.textTitle
                rightView.textColor = UDColor.textCaption
            } else {
                leftTitle.textColor = UDColor.textDisabled
                rightView.textColor = UDColor.textDisabled
            }
        }
    }

    init(title: String) {
        super.init(frame: .zero)
        leftTitle.text = title
        setupUI()
        addSubview(arrowView)
        arrowView.snp.makeConstraints { (make) in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }
        //rightView优先，但不能超过1/2
        rightView.snp.remakeConstraints { (make) in
            make.trailing.equalTo(arrowView.snp.leading).offset(-12)
            make.width.lessThanOrEqualToSuperview().dividedBy(2)
            make.height.centerY.equalTo(leftTitle)
        }
        addTarget(self, action: #selector(onTap(gesture:)), for: .touchUpInside)
        self.docs.addStandardHover()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateTitle(_ newTitle: String) {
        leftTitle.text = newTitle
    }
    
    

    @objc
    func onTap(gesture: UITapGestureRecognizer) {
        tapCallback?(rightView)
    }
}

class ReminderUserItemView: UIButton, ReminderItemViewWithArrow {
    typealias RightView = ReminderUserAvatarArray
    lazy var leftTitle: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UDColor.textTitle
        return label
    }()
    var rightView: ReminderUserAvatarArray
    var arrowDirection: UIMenuController.ArrowDirection = .right
    lazy var arrowView: UIImageView = UIImageView(image: BundleResources.SKResource.Common.Icon.icon_right_outlined)
    var tapCallback: ((ReminderUserAvatarArray) -> Void)?

    init(title: String, userModels: [ReminderUserModel]?) {
        rightView = ReminderUserAvatarArray(userModels)
        super.init(frame: .zero)
        leftTitle.text = title
        setupUI()
        addSubview(arrowView)
        addSubview(rightView)
        arrowView.snp.makeConstraints { (make) in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }
        rightView.snp.remakeConstraints { (make) in
            make.trailing.equalTo(arrowView.snp.leading).offset(-12)
            make.leading.greaterThanOrEqualTo(leftTitle.snp.trailing)
            make.centerY.equalTo(leftTitle)
        }
        guard let userModels = userModels else { return } // 如果不传 model 过来，证明 right view 内容是空
        rightView.updateArray(with: userModels)
        addTarget(self, action: #selector(onTap(gesture:)), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func onTap(gesture: UITapGestureRecognizer) {
        tapCallback?(rightView)
    }
}
