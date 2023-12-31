//
//  ReactionPageSegmentCell.swift
//  Calendar
//
//  Created by pluto on 2023/5/24.
//

import Foundation
import UIKit
import SnapKit
import LarkPageController
import UniverseDesignIcon
import LarkEmotion
import UniverseDesignColor

final class ReactionPageSegmentCell: PageSegmentCell {
    private let reactionHeight: CGFloat = 20
    var contentSelected: (() -> Void)?
    override var isSelected: Bool {
        didSet {
            switchStyle()
        }
    }

    let wapperView: UIView = UIView()
    let reactionBGView: UIView = UIView()
    let reactionView: UIImageView = UIImageView()
    private lazy var btnBg: UIButton = {
        let btn = UIButton(type: .custom)
        btn.backgroundColor = .clear
        btn.addTarget(self, action: #selector(tapBtnBg), for: .touchUpInside)
        return btn
    }()
    
    private let countLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.N600
        label.font = UIFont.ud.body0
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }()
    
    private lazy var reactionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.ud.body0
        label.textColor = UIColor.ud.N600
        label.text = I18n.Calendar_Detail_AwaitingColon
        return label
    }()

    private var reactionKey: ReplyStatus? {
        didSet {
            let isNeedAction: Bool = reactionKey == .needsAction
            switch reactionKey {
            case .accept:
                reactionView.image = UDIcon.getIconByKey(.yesFilled, iconColor: UDColor.calendarRSVPCardacceptBtnBgColor)
            case .tentative:
                reactionView.image = UDIcon.getIconByKey(.maybeFilled, iconColor: UIColor.ud.iconN2)
            case .decline:
                reactionView.image = UDIcon.getIconByKey(.noFilled, iconColor: UIColor.ud.colorfulRed)
            @unknown default:
                break
            }

            reactionView.layer.opacity = isNeedAction ? 0 : 1
            reactionBGView.layer.opacity = isNeedAction ? 0 : 1
            reactionLabel.layer.opacity = isNeedAction ? 1 : 0
        }
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return contentView.frame.contains(point)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let contentViewPoint = convert(point, to: contentView)
        if contentView.bounds.contains(contentViewPoint) {
            return contentView.hitTest(contentViewPoint, with: event)
        }
        return super.hitTest(point, with: event)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.clipsToBounds = false
        self.contentView.snp.makeConstraints { make in
            make.bottom.left.top.equalToSuperview()
            make.width.equalTo(62)
        }
        
        contentView.addSubview(wapperView)
        contentView.addSubview(btnBg)
        wapperView.addSubview(reactionBGView)
        wapperView.addSubview(reactionView)
        wapperView.addSubview(reactionLabel)
        wapperView.addSubview(countLabel)
        
        btnBg.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        wapperView.clipsToBounds = true
        wapperView.layer.cornerRadius = 14
        wapperView.backgroundColor = UIColor.ud.bgBody
        wapperView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
            maker.height.equalTo(28)
        }
        
        reactionBGView.backgroundColor = UIColor.ud.bgBody
        reactionBGView.layer.cornerRadius = (reactionHeight - 2) / 2
        reactionBGView.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.left.equalToSuperview().offset(9)
            maker.width.height.equalTo(reactionHeight-2)
        }
        
        reactionView.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.left.equalToSuperview().inset(8)
            maker.width.height.equalTo(reactionHeight)
        }
        
        reactionLabel.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.left.equalToSuperview().offset(8)
            maker.height.equalTo(reactionHeight)
            let awaitWidth = I18n.Calendar_Detail_AwaitingColon.getWidth(font: UIFont.ud.body0)
            maker.width.equalTo(awaitWidth)
        }

        countLabel.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.left.equalTo(reactionView.snp.right).offset(4)
            maker.right.equalToSuperview().inset(8)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func switchStyle() {
        if isSelected {
            wapperView.backgroundColor = UIColor.ud.primaryPri500
            countLabel.textColor = UIColor.ud.staticWhite
            reactionLabel.textColor = UIColor.ud.staticWhite
        } else {
            wapperView.backgroundColor = UIColor.ud.N100
            countLabel.textColor = UIColor.ud.N600
            reactionLabel.textColor = UIColor.ud.N600
        }
    }

    func set(reactionKey: ReplyStatus, count: Int) {
        countLabel.text = "\(count)"
        self.reactionKey = reactionKey
        let awiaitingWidth: CGFloat = I18n.Calendar_Detail_AwaitingColon.getWidth(font: UIFont.ud.body0)
        let countWidth = "\(count)".getWidth(font: UIFont.ud.body0)
        switch reactionKey {
        case .needsAction:
            countLabel.snp.remakeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.left.equalTo(reactionLabel.snp.right).offset(4)
                maker.right.equalToSuperview().inset(8)
            }
            self.contentView.snp.updateConstraints { make in
                make.width.equalTo(awiaitingWidth + 20 + countWidth)
            }
        @unknown default:
            countLabel.snp.remakeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.left.equalTo(reactionView.snp.right).offset(4)
                maker.right.equalToSuperview().inset(8)
            }

            self.contentView.snp.updateConstraints { make in
                make.width.equalTo(self.reactionHeight + 20 + countWidth)
            }
        }
        
        switchStyle()
        setNeedsLayout()
    }
    
    @objc
    func tapBtnBg() {
        self.contentSelected?()
    }
}
