//
//  CalendarCountdownView.swift
//  Calendar
//
//  Created by chaishenghua on 2023/8/21.
//

import UniverseDesignColor
import UniverseDesignFont

class CalendarCountdownView: UIView {
    private lazy var label: UILabel = {
        let label = UILabel()
        label.font = UDFont.caption0
        label.textColor = UDColor.udtokenTagNeutralTextNormal
        label.layer.cornerRadius = 4
        return label
    }()

    init() {
        super.init(frame: .zero)
        self.layer.cornerRadius = 4
        self.addSubview(label)
        label.snp.makeConstraints { make in
            make.trailing.leading.equalToSuperview().inset(4)
            make.top.bottom.equalToSuperview()
        }
    }

    func setText(text: String, color: UIColor) {
        label.text = text
        label.textColor = color
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
