//
//  MeetingRoomCell.swift
//  Calendar
//
//  Created by harry zou on 2019/4/16.
//

import UniverseDesignIcon
import UIKit
import CalendarFoundation
final class SeizeMeetingRoomCell: UIView {
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.cd.regularFont(ofSize: 16)
        label.numberOfLines = 2
        return label
    }()

    let imageView = UIImageView(image: UDIcon.getIconByKeyNoLimitSize(.roomOutlined).renderColor(with: .n3))

    override init(frame: CGRect) {
        super.init(frame: frame)
        layout(imageView: imageView)
        layout(titleView: titleLabel, leadingView: imageView)
        addBottomBorder(inset: UIEdgeInsets(top: 0, left: 44, bottom: 0, right: 0), lineHeight: 1)
    }

    func layout(imageView: UIImageView) {
        addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
            make.leading.equalToSuperview().offset(16)
        }
    }

    func layout(titleView: UILabel, leadingView: UIView) {
        addSubview(titleView)
        titleView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(15)
            make.bottom.equalToSuperview().offset(-15)
            make.leading.equalTo(leadingView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-16)
        }
    }

    func update(title: String) {
        titleLabel.text = title
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
