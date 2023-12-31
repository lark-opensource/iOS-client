//
//  HashTagDetailDescriptionView.swift
//  Moment
//
//  Created by liluobin on 2021/6/28.
//

import Foundation
import UIKit

final class HashTagDetailDescriptionView: UIView {

    private lazy var usersAvatarView: MomentsUserAvatarsView = {
        let view = MomentsUserAvatarsView(itemWidth: 20)
        return view
    }()
    let layout = HashTagDetailDescriptionLayout()
    var labels: [UILabel] = []
    var currentStyle: HashTagDetailDescriptionLayout.Style?
    var suggestHeight: CGFloat {
        return self.labels.last?.frame.maxY ?? .zero
    }
    let labelCount = 5
    init() {
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        addSubview(usersAvatarView)
        for _ in 0..<labelCount {
            let label = UILabel()
            label.textColor = UIColor.ud.textTitle
            label.textAlignment = .center
            addSubview(label)
            labels.append(label)
        }
    }
    func updateDataWithUsers(_ users: [MomentUser], items: [HashTagDescriptionItem]) {
        usersAvatarView.updateUsers(users)
        layout.avatarViewSize = usersAvatarView.suggestSize()
        layout.calculateForItems(items)
        if let currentStyle = currentStyle, currentStyle == layout.style {
            return
        }
        let allItems = layout.insertSeparationItemFor(items: items)
        for (idx, label) in self.labels.enumerated() {
            label.text = allItems[idx].title
            label.frame = allItems[idx].frame
            label.font = allItems[idx].font
            label.isHidden = allItems[idx].isHidden
        }
    }
}
