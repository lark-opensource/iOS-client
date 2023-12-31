//
//  SpaceVerticalGridCell.swift
//  SKECM
//
//  Created by Weston Wu on 2020/12/21.
//

import UIKit
import SnapKit
import UniverseDesignColor
import RxSwift
import RxRelay
import RxCocoa
import SKUIKit
import SKCommon
import SKResource
import UniverseDesignBadge
import UniverseDesignIcon
import SKInfra

private extension SpaceVerticalGridCell {
    enum Layout {
        static let iconSize: CGFloat = 24
        static let badgeSize: CGFloat = 8
    }
}

class SpaceVerticalGridCell: UICollectionViewCell {

    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = .clear
        view.clipsToBounds = true
        return view
    }()

    private lazy var badgeView: UDBadge = {
        let view = iconView.addBadge(.dot, anchor: .topRight, offset: .init(width: 0, height: 0))
        
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = UDColor.textTitle
        return label
    }()

    private var hoverGesture: UIGestureRecognizer?

    private let disposeBag = DisposeBag()
    private var reuseBag = DisposeBag()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        contentView.backgroundColor = UDColor.bgBody
        contentView.layer.cornerRadius = 6
        contentView.layer.borderWidth = 0.5
        contentView.layer.ud.setBorderColor(UDColor.lineDividerDefault)

        contentView.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(8)
            make.width.height.equalTo(Layout.iconSize)
            make.centerY.equalToSuperview()
        }


        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(8)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(8)
        }

        if #available(iOS 13.0, *) {
            setupHoverInteraction()
        }
    }

    @available(iOS 13.0, *)
    private func setupHoverInteraction() {
        let gesture = UIHoverGestureRecognizer()
        gesture.rx.event.subscribe(onNext: { [weak self] gesture in
            guard let self = self else { return }
            switch gesture.state {
            case .began, .changed:
                self.contentView.layer.ud.setBorderColor(UIColor.ud.colorfulBlue)
            case .ended, .cancelled:
                self.contentView.layer.ud.setBorderColor(UDColor.lineDividerDefault)
            default:
                break
            }
        }).disposed(by: disposeBag)
        hoverGesture = gesture
        contentView.addGestureRecognizer(gesture)
    }


    override func prepareForReuse() {
        super.prepareForReuse()
        iconView.layer.cornerRadius = 0
        reuseBag = DisposeBag()
    }

    func update(item: SpaceVerticalGridItem) {
        hoverGesture?.isEnabled = item.enable
        contentView.alpha = item.enable ? 1 : 0.3
        titleLabel.text = item.title
        badgeView.isHidden = !item.needRedPoint
        setup(iconType: item.iconType)
    }

    private func setup(iconType: SpaceListItem.IconType) {
        switch iconType {
        case let .newIcon(data):
            iconView.layer.cornerRadius = Layout.iconSize / 2
            guard !data.iconKey.isEmpty else { break }
            let fixedKey = data.iconKey.replacingOccurrences(of: "lark.avatar/", with: "")
                .replacingOccurrences(of: "mosaic-legacy/", with: "")
            iconView.bt.setLarkImage(with: .avatar(key: fixedKey, entityID: ""), placeholder: data.placeHolder)
        case let .thumbIcon(thumbInfo):
            iconView.layer.cornerRadius = 6
            let processer = SpaceRoundProcesser(diameter: Layout.iconSize)
            let placeHolderImage = UDIcon.getIconByKeyNoLimitSize(.fileRoundUnknowColorful)
            let manager = DocsContainer.shared.resolve(SpaceThumbnailManager.self)
            let request = SpaceThumbnailManager.Request(token: thumbInfo.token,
                                                        info: thumbInfo.thumbInfo,
                                                        source: thumbInfo.source,
                                                        fileType: thumbInfo.fileType,
                                                        placeholderImage: placeHolderImage,
                                                        failureImage: placeHolderImage,
                                                        processer: processer)
            manager?.getThumbnail(request: request)
                .asDriver(onErrorJustReturn: placeHolderImage)
                .drive(onNext: { [weak self] image in
                    self?.iconView.image = image
                })
                .disposed(by: reuseBag)
        case let .icon(image, _):
            iconView.image = image
        }
    }
}
