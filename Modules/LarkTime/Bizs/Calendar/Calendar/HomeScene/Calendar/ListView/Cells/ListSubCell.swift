//
//  ListSubCell.swift
//  Calendar
//
//  Created by zhu chao on 2018/8/13.
//  Copyright © 2018年 EE. All rights reserved.
//

import UIKit
import Foundation
import CalendarFoundation

protocol EventInstanceViewDelegate: AnyObject {
    func iconTapped(_ info: [String: Any], isSelected: Bool)
    func showVC(_ vc: UIViewController)
}

final class ListSubCell: UITableViewCell {
    static let identifier = "ListSubCell"
    private static let topMargin: CGFloat = 5.0
    private static let bottomMargin: CGFloat = 5.0
    private static let eventHeight: CGFloat = 50.0
    static let cellHeight: CGFloat = topMargin + bottomMargin + eventHeight

    static func eventViewFrame() -> CGRect {
        return CGRect(x: 57,
                      y: topMargin,
                      width: 0,
                      height: eventHeight)
    }

    private let eventView = ListBlockView()
    weak var delegate: EventInstanceViewDelegate?
    private var content: BlockListEventItem?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.layoutEventView(eventView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(content: BlockListEventItem) {
        self.content = content
        guard let eventContent = content.content else { return }
        self.eventView.updateContent(content: eventContent)
        self.eventView.delegate = delegate
    }

    private func layoutEventView(_ eventView: ListBlockView) {
        self.contentView.addSubview(eventView)
        eventView.frame = CGRect(x: 57, y: ListSubCell.topMargin, width: self.bounds.width - 57 - 5, height: ListSubCell.eventHeight)
        eventView.autoresizingMask = [.flexibleWidth]
    }
}
