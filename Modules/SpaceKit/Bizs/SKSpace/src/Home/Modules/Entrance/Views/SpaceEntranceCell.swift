//
//  SpaceEntranceCell.swift
//  SKECM
//
//  Created by Weston Wu on 2020/11/25.
//

import UIKit
import SnapKit
import RxSwift
import RxRelay
import RxCocoa
import UniverseDesignColor
import CoreGraphics
import SKFoundation

public class SpaceEntranceCell: UICollectionViewCell, SpaceEntranceCellType {

    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UDColor.textTitle
        label.numberOfLines = 2
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()

    private lazy var badgeView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage.circle(diameter: 6, color: UIColor.ud.B300)
        view.contentMode = .center
        return view
    }()

    public override var isHighlighted: Bool {
        didSet {
            contentView.backgroundColor = isHighlighted ? UIColor.ud.N200 : UIColor.clear
        }
    }

    private var reuseBag = DisposeBag()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.backgroundColor = UIColor.clear
        contentView.layer.cornerRadius = 4

        contentView.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(7)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(30)
        }

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconView.snp.bottom).offset(7)
            make.centerX.equalToSuperview()
            make.left.greaterThanOrEqualToSuperview().inset(8)
        }

        contentView.addSubview(badgeView)
        badgeView.snp.makeConstraints { make in
            make.width.equalTo(6)
            make.height.equalTo(14)
            make.right.equalTo(titleLabel.snp.left).offset(-2)
            make.top.equalTo(titleLabel.snp.top)
        }
        badgeView.isHidden = true

        contentView.docs.addHighlight(with: .zero, radius: 8)
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        iconView.image = nil
        titleLabel.attributedText = nil
        reuseBag = DisposeBag()
    }

    public func update(entrance: SpaceEntrance) {
        iconView.image = entrance.image
        titleLabel.text = entrance.title
        entrance.redDotVisableRelay.asDriver()
            .distinctUntilChanged()
            .drive(onNext: { [weak self] needRedDot in
                guard let self = self else { return }
                self.badgeView.isHidden = !needRedDot
                // 这里使用 remake 的原因是，调整 greaterThanOrEqualToSuperview 的 inset 并不能保证 title 在蓝点消失后延伸到左右两侧，
                // 导致蓝点消失后label仍然保持换行的状态，所以用 remake 强制布局一下
                if needRedDot {
                    self.titleLabel.snp.remakeConstraints { make in
                        make.top.equalTo(self.iconView.snp.bottom).offset(4)
                        make.centerX.equalToSuperview()
                        make.left.greaterThanOrEqualToSuperview().inset(8)
                    }
                } else {
                    self.titleLabel.snp.remakeConstraints { make in
                        make.top.equalTo(self.iconView.snp.bottom).offset(4)
                        make.centerX.equalToSuperview()
                        make.left.equalToSuperview()
                    }
                }
            })
            .disposed(by: reuseBag)
    }
    
    public func update(needHighlight: Bool) {}
}

private extension UIImage {
    class func circle(diameter: CGFloat, color: UIColor) -> UIImage? {
        var imgSize = CGSize(width: diameter, height: diameter)
        if imgSize.width == 0 { imgSize.width = 1 }
        if imgSize.height == 0 { imgSize.height = 1 }
        UIGraphicsBeginImageContextWithOptions(imgSize, false, 0)
        defer {
            UIGraphicsEndImageContext()
        }
        guard let context = UIGraphicsGetCurrentContext() else {
            DocsLogger.error("space.entrance.cell --- failed to get context when draw circle")
            return nil
        }
        context.saveGState()

        let rect = CGRect(x: 0, y: 0, width: diameter, height: diameter)
        context.setFillColor(color.cgColor)
        context.fillEllipse(in: rect)

        context.restoreGState()
        guard let circleImage = UIGraphicsGetImageFromCurrentImageContext() else {
            DocsLogger.error("space.entrance.cell --- failed to get image from context")
            return nil
        }
        return circleImage
    }
}
