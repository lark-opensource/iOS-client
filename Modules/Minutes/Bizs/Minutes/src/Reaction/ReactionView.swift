//
//  ReactionView.swift
//  Minutes
//
//  Created by lvdaqian on 2021/3/2.
//

import Foundation
import LarkEmotion

class ReactionView: UIView {
    private lazy var reactionImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var countLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .white
        label.textAlignment = .left
        label.numberOfLines = 1
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    var model: ReactionViewModel {
        didSet {
            setupViews()
        }
    }

    var reactionKey: String? {
        didSet {
            if let key = reactionKey,
               let image = EmotionResouce.shared.imageBy(key: key) {
                reactionImageView.image = image
            } else {
                reactionImageView.image = BundleResources.Minutes.minutes_comment_tip
            }
        }
    }

    var count: Int = 0 {
        didSet {
            if count > 1 {
                countLabel.isHidden = false
                countLabel.text = "x\(count)"
            } else {
                countLabel.isHidden = true
                countLabel.text = ""
            }
        }
    }

    func setupLayout() {

        reactionImageView.snp.makeConstraints { maker in
            maker.width.height.equalTo(20)
            maker.left.centerY.equalToSuperview()
        }

        countLabel.snp.makeConstraints { maker in
            maker.left.equalTo(reactionImageView.snp.right)
            maker.right.centerY.equalToSuperview()
        }
    }

    init(_ model: ReactionViewModel) {
        self.model = model
        super.init(frame: .zero)
        setupViews()
        setupLayout()
    }

    func setupViews() {
        self.reactionKey = model.reactionKey
        self.count = model.count

        addSubview(reactionImageView)
        addSubview(countLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
