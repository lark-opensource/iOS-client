//
//  EventBasicDivideView.swift
//  Calendar
//
//  Created by chaishenghua on 2023/9/8.
//

import UniverseDesignColor

class EventBasicDivideView: UIView {
    private lazy var divide: UILabel = {
        let label = UILabel()
        label.backgroundColor = UDColor.lineDividerDefault
        return label
    }()

    private let containerInsets: UIEdgeInsets

    init(containerInsets: UIEdgeInsets = UIEdgeInsets(top: 14, left: 16, bottom: 14, right:0)) {
        self.containerInsets = containerInsets
        super.init(frame: .zero)
        self.addSubview(divide)
        divide.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(self.containerInsets)
            make.height.equalTo(CGFloat(1.0 / UIScreen.main.scale))
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
