//
//  SelectedMeetingRoomEditCell.swift
//  Calendar
//
//  Created by Rico on 2021/5/17.
//

import UIKit
import Foundation
import SnapKit
import CalendarFoundation
import RxSwift

final class SelectedMeetingRoomEditCell: UITableViewCell {

    var currentContentView: UIView?
    let disposeBag = DisposeBag()

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

    func updateContent(_ content: EventEditMeetingRoomItemDataType,
                       itemDeleteHandler: ((_ index: Int) -> Void)? = nil,
                       itemFormClickHandler: ((Int) -> Void)? = nil,
                       itemClickHandler: ((_ index: Int) -> Void)? = nil) {

        if currentContentView != nil {
            currentContentView?.removeFromSuperview()
            currentContentView = nil
        }

        let view = EventEditMeetingRoomView.makeItemView(index: 0,
                                                         leadingIcon: .none,
                                                         item: content,
                                                         itemDeleteHandler: itemDeleteHandler,
                                                         itemFormClickHandler: itemFormClickHandler,
                                                         itemClickHandler: itemClickHandler,
                                                         disposeBag: disposeBag)
        contentView.addSubview(view)
        contentView.addSubview(sepLine)

        view.snp.makeConstraints {
            $0.leading.equalTo(0)
            $0.trailing.equalTo(0)
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
