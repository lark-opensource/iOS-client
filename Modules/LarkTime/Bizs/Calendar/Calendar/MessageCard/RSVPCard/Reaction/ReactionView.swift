//
//  ReactionView.swift
//  Calendar
//
//  Created by pluto on 2023/1/15.
//

import UIKit
import Foundation
import LarkModel
import LarkUIKit
import UniverseDesignIcon
import UniverseDesignColor

/// ReactionTagView需要的一切属性，由外部组装
struct ReactionTag {
    var frame: CGRect = .zero
    var rsvpStatusType: ReplyStatus = .needsAction
    var userIDs: [String] = []
    var userNameWidths: [CGFloat] = []
    var iconRect: CGRect = .zero
    var separatorRect: CGRect = .zero
    var nameRect: CGRect = .zero
    // Default values not used.
    var font: UIFont = UIFont.systemFont(ofSize: UIFont.systemFontSize)
    var userNamesText: String = ""
    var textColor: UIColor = .clear
    var tagBgColor: UIColor = .clear
    var separatorColor: UIColor = .clear
}
/// 展示reactions的视图
public final class ReactionView: UIView {
    var tags: [ReactionTag] = []
    var identifier = ""
    var showProfile: ((String)->Void)?
    var reactionDidTapped: ((ReplyStatus) -> Void)?
    var reactionTapMore: ((ReplyStatus) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = true
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.isUserInteractionEnabled = true
    }

    func syncTagsToSubviews() {
        guard let subviews = self.subviews as? [ReactionTagView] else { return }
        var idx = 0
        while idx < self.tags.count && idx < subviews.count {
            subviews[idx].update(tag: self.tags[idx])
            idx += 1
        }
        for i in idx..<self.tags.count {
            self.addSubview(ReactionTagView(tag: self.tags[i]))
        }
        for i in idx..<subviews.count {
            subviews[i].removeFromSuperview()
        }
        self.subviews.forEach { view in
            if let view = view as? ReactionTagView {
                view.identifier = self.identifier
                view.showProfile = { [weak self] chatterID in
                    self?.showProfile?(chatterID)
                }
                
                view.reactionDidTapped = { [weak self] type in
                    self?.reactionDidTapped?(type)
                }
                
                view.tapMore = { [weak self] type in
                    self?.reactionTapMore?(type)
                }
            }
        }
    }
}

/// 每个reaction对应的视图
final class ReactionTagView: UIView {
    
    /// icon、分割线、名字区域
    private var reactionImageView = UIImageView()
    private let separator = UIView()
    private let namesLabel = UILabel(frame: .zero)
    /// reaction所有点击者的id
    private var userIDs: [String] = []
    /// 记录显示前i个人的长度
    private var userNameWidths: [CGFloat] = []
    var identifier = ""
    var showProfile: ((String) -> Void)?
    var reactionDidTapped: ((ReplyStatus) -> Void)?
    var tapMore: ((ReplyStatus) -> Void)?
    var rsvpStatusType: ReplyStatus

    init(tag: ReactionTag) {
        self.rsvpStatusType = tag.rsvpStatusType
        super.init(frame: .zero)
        self.isUserInteractionEnabled = true
        self.layer.cornerRadius = ReactionTagLayoutItem.Cons.totalHeight / 2
        self.backgroundColor = tag.tagBgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 2)
        self.layer.shadowColor = UIColor.ud.staticBlack.withAlphaComponent(0.1).cgColor
        self.layer.shadowRadius = 2.5
        self.addSubview(self.reactionImageView)
        if !FG.rsvpStyleOpt {
            self.separator.backgroundColor = UIColor.ud.N400
            self.addSubview(self.separator)
        }
        self.addSubview(self.namesLabel)
        self.update(tag: tag)
    }

    func update(tag: ReactionTag) {
        self.frame = tag.frame
        self.userIDs = tag.userIDs
        self.userNameWidths = tag.userNameWidths
        /// icon
        self.reactionImageView.frame = tag.iconRect
        self.rsvpStatusType = tag.rsvpStatusType
        switch tag.rsvpStatusType {
        case .accept:
            reactionImageView.image = UDIcon.getIconByKey(.yesFilled, iconColor: UDColor.calendarRSVPCardacceptBtnBgColor)
        case .tentative:
            reactionImageView.image = UDIcon.getIconByKey(.maybeFilled, iconColor: UIColor.ud.iconN2)
        case .decline:
            if FG.rsvpStyleOpt {
                reactionImageView.image = UDIcon.getIconByKey(.noFilled, iconColor: UIColor.ud.colorfulRed)
            } else {
                reactionImageView.image = UDIcon.getIconByKey(.noFilled, iconColor: UDColor.calendarRSVPCardDeclineBgColor)
            }
        @unknown default:
            self.reactionImageView.frame = .zero
        }
        if !FG.rsvpStyleOpt {
            /// 分割线
            self.separator.frame = tag.separatorRect
            self.separator.backgroundColor = tag.separatorColor
        }
        /// 名字区域
        self.namesLabel.frame = tag.nameRect
        self.namesLabel.font = tag.font
        self.namesLabel.text = tag.userNamesText
        self.namesLabel.textColor = tag.textColor
        /// 背景
        self.backgroundColor = tag.tagBgColor
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func offsetAtUserNamesIdx(_ offset: CGFloat) -> Int {
        if offset < 0 { return -1 }
        let (before, _) = self.userNameWidths.lf_bsearch(offset, comparable: { Int($0) - Int($1) })
        return before + 1
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        /// tap icon
        var responseFrame = self.reactionImageView.frame
        let insets = UIEdgeInsets(top: 7, left: 12, bottom: 7, right: 5)
        responseFrame = CGRect(
            x: responseFrame.minX - insets.left,
            y: responseFrame.minY - insets.top,
            width: responseFrame.width + insets.left + insets.right,
            height: responseFrame.height + insets.top + insets.bottom
        )
        
        if responseFrame.contains(point) {
            self.reactionDidTapped?(self.rsvpStatusType)
            return
        }
        
        let offset = point.x - self.namesLabel.frame.minX
        let idx = self.offsetAtUserNamesIdx(offset)
        // 点击更多人时
        if idx >= self.userNameWidths.count {
            self.tapMore?(self.rsvpStatusType)
            return
        }
        
        /// tap user，越界防护，空数组idx是0会造成越界
        if idx >= 0, idx < self.userIDs.count, let profileId = self.userIDs[safeIndex: idx] {
            self.showProfile?(profileId)
        }
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {}
}
