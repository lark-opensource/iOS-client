//
//  SelectedMeetingRoomDetailCell.swift
//  Calendar
//
//  Created by Rico on 2021/5/14.
//

import UIKit
import Foundation
import SnapKit
import CalendarFoundation

final class SelectedMeetingRoomDetailCell: UITableViewCell {

    var currentContentView: UIView?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        currentContentView?.removeFromSuperview()
        currentContentView = nil
    }

    func updateContent(_ content: DetailMeetingRoomItemContent, didClickTrailingButton: (() -> Void)?) {
        let view = DetailMeetingRoomCell.makeItemView(with: content, of: 0) { _ in
            didClickTrailingButton?()
        }

        contentView.addSubview(view)
        contentView.addSubview(sepLine)

        view.snp.makeConstraints {
            $0.leading.equalTo(16)
            $0.trailing.equalTo(-16)
            $0.top.equalTo(12)
            $0.bottom.equalTo(-12)
        }
        currentContentView = view

        sepLine.snp.makeConstraints {
            $0.bottom.trailing.equalToSuperview()
            $0.height.equalTo(0.5)
            $0.leading.equalTo(view)
        }
    }

    private lazy var sepLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()
}
