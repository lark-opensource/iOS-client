//
//  MinutesInfoAddNewParticipantView.swift
//  Minutes
//
//  Created by panzaofeng on 2021/1/11.
//

import Foundation
import MinutesFoundation
import UniverseDesignIcon

public final class MinutesInfoAddNewParticipantView: UIView {

    private lazy var barTextLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        label.text = BundleI18n.Minutes.MMWeb_G_AddParticipant
        label.textAlignment = .left
        return label
    }()

    private lazy var barImageView: UIImageView = {
        let contentView = UIImageView(image: UDIcon.getIconByKey(.memberAddOutlined, iconColor: UIColor.ud.iconN1))
        return contentView
    }()
    
    lazy var pressMask: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.fillPressed
        view.layer.cornerRadius = 6.0
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.bgBody

        addSubview(barImageView)
        addSubview(barTextLabel)
        addSubview(pressMask)
        
        barImageView.snp.makeConstraints {
            $0.left.equalToSuperview().offset(0)
            $0.height.equalTo(20)
            $0.width.equalTo(20)
            $0.centerY.equalToSuperview()
        }

        barTextLabel.snp.makeConstraints {
            $0.left.equalTo(barImageView.snp.right).offset(9)
            $0.height.equalTo(22)
            $0.centerY.equalToSuperview()
            $0.right.equalToSuperview()
        }
    
        pressMask.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(-3)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
