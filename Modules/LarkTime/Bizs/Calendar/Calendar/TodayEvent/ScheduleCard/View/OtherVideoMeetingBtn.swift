//
//  OtherVideoMeetingBtn.swift
//  Calendar
//
//  Created by chaishenghua on 2023/8/15.
//

import UniverseDesignColor
import UniverseDesignFont

class OtherVideoMeetingBtn: UIButton {

    lazy var label: UILabel = {
        let label = UILabel()
        label.font = UDFont.body2
        return label
    }()

    init(summary: String, isLinkAvaliable: Bool) {
        super.init(frame: .zero)
        self.backgroundColor = UDColor.bgBody
        setup(summary: summary, isLinkAvaliable: isLinkAvaliable)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup(summary: String, isLinkAvaliable: Bool) {
        self.addSubview(label)
        if isLinkAvaliable {
            label.font = UDFont.body2
            label.textColor = UDColor.primaryContentDefault
            self.layer.ud.setBorderColor(UDColor.primaryContentDefault)
        } else {
            label.textColor = UDColor.textDisabled
            self.layer.ud.setBorderColor(UDColor.lineBorderComponent)
        }
        label.text = summary
        let containerInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        self.layer.cornerRadius = 6
        self.layer.borderWidth = 1
        self.label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(containerInsets)
        }
    }
}
