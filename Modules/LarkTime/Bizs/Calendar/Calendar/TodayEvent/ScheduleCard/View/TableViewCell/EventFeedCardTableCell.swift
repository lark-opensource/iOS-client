//
//  EventFeedCardTableCell.swift
//  Calendar
//
//  Created by chaishenghua on 2023/8/8.
//

import LarkSwipeCellKit
import UniverseDesignColor
import UIKit

class EventFeedCardTableCell: SwipeTableViewCell {
    private lazy var selectedView: UIView = {
        let backgroundView = UIView()
        backgroundView.backgroundColor = UDColor.fillPressed
        backgroundView.layer.cornerRadius = 10
        return backgroundView
    }()

    static let identifier: String = String(describing: EventFeedCardTableCell.self)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.layer.borderWidth = 1
        contentView.layer.masksToBounds = true
        contentView.layer.cornerRadius = 10
        contentView.layer.ud.setBorderColor(UDColor.lineBorderCard)
        self.swipeView.backgroundColor = .clear
        /*
         SwipeTableViewCell中使用了autoresizingMask对swipeView进行进行布局，
         而translatesAutoresizingMaskIntoConstraints=true会讲fram布局转化为约束布局，从而导致约束冲突
         */
        self.swipeView.translatesAutoresizingMaskIntoConstraints = false
        self.swipeView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        self.selectedBackgroundView = selectedView
        self.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        self.selectionStyle = .none
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setModel(model: EventFeedCardViewMananger) {
        let view = model.cardView
        self.swipeView.btd_removeAllSubviews()
        swipeView.addSubview(view)
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
