//
//  SingleSelectionView.swift
//  ByteView
//
//  Created by chenyizhuo on 2021/10/12.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UIKit
import ByteViewCommon
import UniverseDesignCheckBox

class SingleSelectionView: UIView {
    private lazy var stackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [switchViewContainer, titleLabel])
        view.axis = .horizontal
        view.spacing = 12
        return view
    }()

    private lazy var switchViewContainer: UIView = {
        let view = UIView()
        view.addSubview(switchView)
        view.snp.makeConstraints {
            $0.width.equalTo(20)
        }
        switchView.snp.makeConstraints {
            $0.size.equalTo(20)
            $0.center.equalToSuperview()
        }
        return view
    }()

    private lazy var switchView: UDCheckBox = {
        let view = UDCheckBox(boxType: .single)
        view.isUserInteractionEnabled = false
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        return label
    }()

    var title = "" {
        didSet {
            titleLabel.text = title
        }
    }

    var isOn = false {
        didSet {
            switchView.isSelected = isOn
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
