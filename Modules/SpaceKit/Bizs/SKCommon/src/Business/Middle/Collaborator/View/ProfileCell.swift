//
//  ProfileCell.swift
//  SKCommon
//
//  Created by lijuyou on 2020/7/13.
//  


import Foundation
import SKUIKit

/*
public class ProfileCell: UICollectionViewCell {

    public let imageView: UIImageView = SKAvatar(config: .init(style: .circle,
                                                               contentMode: .scaleAspectFill))
    public var enableClips: Bool = false

    public override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(imageView)
        layoutImageView()
        startAnimation(enable: true)
    }

    private func layoutImageView() {
        let radius = frame.width > 0 ? frame.width / 2 : 0
        imageView.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = radius
        imageView.contentMode = .scaleAspectFill
    }

    public func enableAvatar(enable: Bool, isOwner: Bool = false) {
        imageView.isUserInteractionEnabled = enable
        imageView.alpha = (enable || isOwner) ? 1.0 : 0.3
    }

    public func startAnimation(enable: Bool) {
        if enable {
            imageView.showAnimatedGradientSkeleton()
            imageView.startSkeletonAnimation()
        } else {
            imageView.hideSkeleton(reloadDataAfter: true)
            imageView.stopSkeletonAnimation()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public class NumbersCell: UICollectionViewCell {

    public var enableClips: Bool = false
    private lazy var numberLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.N800
        label.textAlignment = .center
        return label
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.N200
        let radius = frame.height > 0 ? frame.height / 2 : 0
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true

        contentView.addSubview(numberLabel)
        numberLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(7.5)
            make.right.equalToSuperview().offset(-7.5)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func update(numbers: Int) {
        self.numberLabel.text = "+" + String(numbers)
    }
}
 */
