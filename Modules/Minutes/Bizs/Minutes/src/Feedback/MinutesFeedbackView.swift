//
//  MinutesFeedbackView.swift
//  Minutes
//
//

import UIKit
import Foundation
import RoundedHUD
import LarkUIKit
import EENavigator
import MinutesFoundation
import UniverseDesignToast
import UniverseDesignColor
import LarkContainer
import LarkAccountInterface
import LarkSetting
import UniverseDesignIcon
import AudioToolbox
import FigmaKit

enum MinutesFeedbackViewType {
    case sumary
    case todo
    case chapter
    case speakerSummary
}

enum MinutesFeedbackStatus {
    case none
    case checked
    case unChecked
}


final class MinutesFeedbackView: UIView {
    private var type: MinutesFeedbackViewType?
    
    private var isFeedbackLiked: Bool = false
    private var isFeedbackDisLiked: Bool = false
    private let buttonSize = 20
    private let imgSize = 16
    private let enlargeSize = 6.0
    
    var feelgoodAction: ((_ name:BusinessTrackerName, _ params:[String:AnyHashable]) -> Void)?
    var clickAction: ((_ isLiked:Bool, _ isChecked:Bool) -> Void)?

    lazy var likeButton: EnlargeTouchButton = {
        let button = EnlargeTouchButton(type: .custom)
        button.enlargeRegionInsets = UIEdgeInsets(top: enlargeSize, left: enlargeSize, bottom: enlargeSize, right: enlargeSize)
        button.setImage(UDIcon.getIconByKey(.thumbsupOutlined, iconColor: UIColor.ud.iconN3, size: CGSize(width: imgSize, height: imgSize)), for: .normal)
        button.addTarget(self, action: #selector(onFeedbackLikeClick), for: .touchUpInside)
        return button
    }()
    
    lazy var dislikeBtn: EnlargeTouchButton = {
        let button = EnlargeTouchButton(type: .custom)
        button.enlargeRegionInsets = UIEdgeInsets(top: enlargeSize, left: enlargeSize, bottom: enlargeSize, right: enlargeSize)
        button.setImage(UDIcon.getIconByKey(.thumbdownOutlined, iconColor: UIColor.ud.iconN3, size: CGSize(width: imgSize, height: imgSize)), for: .normal)
        button.addTarget(self, action: #selector(onFeedbackDisLikeClick), for: .touchUpInside)
        return button
    }()
    

    init(frame: CGRect, type: MinutesFeedbackViewType?, likeStatus:MinutesFeedbackStatus) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        
        addSubview(likeButton)
        likeButton.snp.makeConstraints { make in
            make.centerY.left.equalToSuperview()
            make.width.height.equalTo(buttonSize)
        }
        
        addSubview(dislikeBtn)
        dislikeBtn.snp.makeConstraints { make in
            make.centerY.right.equalToSuperview()
            make.width.height.equalTo(buttonSize)
        }
    
        self.type = type
        if likeStatus != .none {
            let liked = likeStatus == .checked
            isFeedbackLiked = liked
            isFeedbackDisLiked = !liked
            refresh()
        }

    }
    

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    private func onFeedbackLikeClick() {
        isFeedbackLiked = !isFeedbackLiked
        
        if isFeedbackLiked {
            isFeedbackDisLiked = false
        }
        sendFeedback(true,false)
        refresh()
    }
    
    @objc
    private func onFeedbackDisLikeClick() {
        isFeedbackDisLiked = !isFeedbackDisLiked
        if isFeedbackDisLiked {
            isFeedbackLiked = false
        }
        sendFeedback(false,true)
        refresh()
    
    }
    
    private func refresh() {
        if isFeedbackLiked {
            self.likeButton.setImage(UDIcon.getIconByKey(.thumbsupFilled, iconColor: UIColor.ud.Y350, size: CGSize(width: imgSize, height: imgSize)), for: .normal)
        } else {
            self.likeButton.setImage(UDIcon.getIconByKey(.thumbsupOutlined, iconColor: UIColor.ud.iconN3, size: CGSize(width: imgSize, height: imgSize)), for: .normal)
        }
        
        if isFeedbackDisLiked {
            self.dislikeBtn.setImage(UDIcon.getIconByKey(.thumbdownFilled, iconColor: UIColor.ud.iconN2, size: CGSize(width: imgSize, height: imgSize)), for: .normal)
        } else {
            self.dislikeBtn.setImage(UDIcon.getIconByKey(.thumbdownOutlined, iconColor: UIColor.ud.iconN3, size: CGSize(width: imgSize, height: imgSize)), for: .normal)
        }
        self.setNeedsDisplay()
        
    }
    
    
    private func sendFeedback(_ isLikeChecked:Bool, _ isDisLikeChecked:Bool) {
        
        let isChecked = isFeedbackLiked||isFeedbackDisLiked
        clickAction?(isLikeChecked,isChecked)
        
        if !isFeedbackDisLiked {
            return
        }
        
        let contentTypeDict = [MinutesFeedbackViewType.sumary:"summary",MinutesFeedbackViewType.todo :"todo",MinutesFeedbackViewType.chapter:"agenda"] as [AnyHashable : String]
        
        
        let params = ["click": isLikeChecked ? "like":"dislike", "content_type": contentTypeDict[type], "is_checked":isChecked ? "true" : "false"]
        
        switch type {
        case .sumary:
            feelgoodAction?(.feelgoodPopAIMainPoint, params)
        case .todo:
            feelgoodAction?(.feelgoodPopAIMainTodo, params)
        case .chapter:
            feelgoodAction?(.feelgoodPopAIMainAgenda, params)
        case .speakerSummary:
            feelgoodAction?(.feelgoodPopSpeakerSummary, params)
        case .none:
            break
        }
    }
    
    func reset() {
        isFeedbackDisLiked = false
        isFeedbackLiked = false
        refresh()
    }
}

