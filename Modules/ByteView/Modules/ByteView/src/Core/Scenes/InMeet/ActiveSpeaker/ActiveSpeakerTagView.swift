//
//  ActiveSpeakerTagView.swift
//  ByteView
//
//  Created by Tobb Huang on 2022/9/28.
//

import Foundation

class ActiveSpeakerTagView: UIView {

    lazy var activeSpeakerNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .ud.primaryOnPrimaryFill
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.numberOfLines = 1
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    lazy var speakingNameLabel: UILabel = {
        let label = UILabel()
        label.text = I18n.View_G_SpeakingNameDot("")
        label.textColor = .ud.primaryOnPrimaryFill
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.numberOfLines = 1
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .ud.staticBlack.withAlphaComponent(0.4)
        self.layer.cornerRadius = 4

        addSubview(activeSpeakerNameLabel)
        activeSpeakerNameLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(5)
            make.top.bottom.equalToSuperview().inset(1)
        }

        addSubview(speakingNameLabel)
        speakingNameLabel.snp.makeConstraints { make in
            make.left.equalTo(activeSpeakerNameLabel.snp.right)
            make.right.equalToSuperview().inset(5)
            make.centerY.equalTo(activeSpeakerNameLabel)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setName(_ name: String) {
        self.activeSpeakerNameLabel.text = name
    }
}
