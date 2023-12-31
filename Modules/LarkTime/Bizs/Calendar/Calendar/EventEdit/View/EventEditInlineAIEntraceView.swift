//
//  EventEditInlineAIEntraceView.swift
//  Calendar
//
//  Created by pluto on 2023/9/26.
//

import Foundation
import UniverseDesignColor
import UniverseDesignIcon

class EventEditInlineAIEntraceView: UIView {
    var onClickAIAction: (() -> Void)?
    
    lazy var aiContainerView: UIButton = {
       let btn = UIButton()
        btn.addTarget(self, action: #selector(onClickAiBtn), for: .touchUpInside)
        return btn
    }()
    
    lazy var spliteRect: UIView = {
       let view = UIView()
        view.backgroundColor = UDColor.textCaption
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
        return view
    }()
    
    lazy var aiIcon: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.getIconByKey(.myaiColorful,
                                        size: CGSize(width: 18, height: 18))
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
        return view
    }()
    
    lazy var aiPlaceHolderLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.Calendar.Calendar_Edit_AddTitle
        label.textColor = .clear
        label.font = EventEditUIStyle.Font.titleText
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.isUserInteractionEnabled = false
        return label
    }()
    
    lazy var aiLabel: UILabel = {
        let label = UILabel()
        label.text = I18n.Calendar_G_AICreateEvent_Button(AiNickname: "")
        label.textColor = .ud.textCaption
        label.font = EventEditUIStyle.Font.normalText
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layoutAITriggerView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func layoutAITriggerView() {
        addSubview(aiPlaceHolderLabel)
        addSubview(aiContainerView)
        aiContainerView.addSubview(spliteRect)
        aiContainerView.addSubview(aiIcon)
        aiContainerView.addSubview(aiLabel)
        
        let width = aiPlaceHolderLabel.text?.getWidth(font: EventEditUIStyle.Font.titleText) ?? 70
        aiPlaceHolderLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(5)
            make.top.equalToSuperview().offset(8)
            make.width.equalTo(width)
        }
        
        aiContainerView.snp.makeConstraints { make in
            make.right.top.bottom.equalToSuperview()
            make.left.equalTo(aiPlaceHolderLabel.snp.right)
        }
        
        spliteRect.snp.makeConstraints { make in
            make.width.equalTo(0.5)
            make.height.equalTo(15)
            make.left.equalTo(aiPlaceHolderLabel.snp.right).offset(8)
            make.centerY.equalTo(aiPlaceHolderLabel)
        }
        
        aiIcon.snp.makeConstraints { make in
            make.left.equalTo(spliteRect.snp.right).offset(8)
            make.centerY.equalTo(aiPlaceHolderLabel)
            make.size.equalTo(18)
        }
        
        aiLabel.snp.makeConstraints { make in
            make.left.equalTo(aiIcon.snp.right).offset(3)
            make.right.equalToSuperview()
            make.centerY.equalTo(aiPlaceHolderLabel)
        }
    }
    
    func configAILabel(myAiNickName: String) {
        aiLabel.text = I18n.Calendar_G_AICreateEvent_Button(AiNickname: myAiNickName)
    }
    
    @objc
    private func onClickAiBtn() {
        self.onClickAIAction?()
    }
}
