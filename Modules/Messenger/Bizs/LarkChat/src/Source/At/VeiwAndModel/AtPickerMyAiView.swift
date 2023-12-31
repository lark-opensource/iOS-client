//
//  AtPickerMyAiView.swift
//  LarkChat
//
//  Created by Yuri on 2023/7/20.
//

import Foundation
import LarkMessengerInterface
import LarkAIInfra
/// 用于显示MyAi
final class AtPickerMyAiView: UIView {
    var onTap: (() -> Void)?

    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()

    var ai: MyAIInfo? {
        didSet {
            guard let ai else { return }
            avatarImageView.image = ai.avatarImage
            nameLabel.text = ai.name
        }
    }

    init() {
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.bgBody

        addSubview(avatarImageView)
        avatarImageView.layer.cornerRadius = 24
        avatarImageView.layer.masksToBounds = true
        avatarImageView.snp.makeConstraints { (maker) in
            maker.width.height.equalTo(48).priority(.required)
            maker.left.equalTo(12)
            maker.centerY.equalToSuperview()
        }

        nameLabel.font = UIFont.systemFont(ofSize: 16)
        nameLabel.textColor = UIColor.ud.N900
        addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (maker) in
            maker.left.equalTo(avatarImageView.snp.right).offset(12)
            maker.centerY.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.backgroundColor = UIColor.ud.N300.withAlphaComponent(0.5)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.backgroundColor = UIColor.ud.bgBody.withAlphaComponent(0.5)
        onTap?()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.backgroundColor = UIColor.ud.bgBody.withAlphaComponent(0.5)
    }
}
