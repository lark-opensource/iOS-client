//
//  SearchTableViewCell.swift
//  CalendarInChat
//
//  Created by zoujiayi on 2019/8/9.
//

import UIKit
import LarkInteraction
enum SearchTableViewCellType {
    case event
    case monthTitle
    case weekTitle
}

protocol SearchCellProtocol {
    var height: CGFloat { get }
    var cellType: SearchTableViewCellType { get }
    var belongingDate: Date { get }
    var calendarId: String { get }
    var key: String { get }
    var originalTime: Int64 { get }
}

final class SearchTableViewCell: UITableViewCell {
    static let identifier: String = "SearchTableViewCell"

    override convenience init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.init(style: style)
        self.clipsToBounds = true
    }

    init(style: UITableViewCell.CellStyle) {
        super.init(style: style, reuseIdentifier: SearchTableViewCell.identifier)
        self.selectionStyle = .none
        if #available(iOS 13.4, *) {
            let pointer = PointerInteraction(
                style: .init(effect: .hover(prefersScaledContent: false))
            )
            self.addLKInteraction(pointer)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var instanceView: SearchInstanceView = {
        return SearchInstanceView(frame: self.frame)
    }()

    func layout(instanceView: UIView) {
        self.contentView.addSubview(instanceView)
        instanceView.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview().inset(5)
            make.right.equalToSuperview().offset(-5)
            make.left.equalToSuperview().offset(57)
        }
    }

    func update(with content: SearchInstanceViewContent) {
        instanceView.updateContent(content: content)
        layout(instanceView: instanceView)
    }
}
