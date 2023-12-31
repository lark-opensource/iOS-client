//
//  RedPacketCoverDetailCell.swift
//
//  Created by JackZhao on 2021/10/29.
//  Copyright © 2021 JACK. All rights reserved.
//

import UIKit
import Foundation
import LarkUIKit
import ByteWebImage
import LarkSDKInterface
import LarkMessengerInterface

// red packet detail cell
final class RedPacketCoverDetailCell: UICollectionViewCell {
    struct Config {
        static let descriptionLabelHeight: CGFloat = 24
        static let descriptionBackgroundViewHeight: CGFloat = 30
    }

    private let coverImageView: ByteImageView = {
        let imageView = ByteImageView(image: Resources.hongbao_open_top)
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    private let bottomImageView: UIImageView = {
        let imageView = UIImageView(image: Resources.hongbao_open_bottom)
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
        return imageView
    }()

    private let openImageView: UIImageView = {
        let imageView = UIImageView(image: Resources.red_packet_open)
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = .systemFont(ofSize: 14)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()

    // 用来显示企业名
    var descriptionLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.Y200.alwaysLight
        label.numberOfLines = 1
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()

    var descriptionBackgroundView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    var model: RedPacketCoverDetailCellModel? {
        didSet {
            setCellInfo()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: .zero)

        contentView.addSubview(coverImageView)
        coverImageView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(coverImageView.snp.width).multipliedBy(1.35)
        }

        contentView.addSubview(bottomImageView)
        bottomImageView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(coverImageView.snp.height).multipliedBy(0.43)
        }

        contentView.addSubview(openImageView)
        openImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(coverImageView.snp.bottom)
            make.width.height.equalTo(coverImageView.snp.width).multipliedBy(0.32)
        }

        contentView.addSubview(descriptionBackgroundView)
        contentView.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.height.equalTo(Self.Config.descriptionLabelHeight)
            make.centerX.equalToSuperview()
            make.left.greaterThanOrEqualTo(20)
            make.right.lessThanOrEqualTo(-20)
        }

        descriptionBackgroundView.snp.makeConstraints { make in
            let verticalPadding = (Self.Config.descriptionBackgroundViewHeight - Self.Config.descriptionLabelHeight) / 2
            make.edges.equalTo(descriptionLabel).inset(UIEdgeInsets(top: -verticalPadding, left: -10, bottom: -verticalPadding, right: -10))
        }

        contentView.addSubview(nameLabel)
        nameLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        nameLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(bottomImageView.snp.bottom).offset(16)
            make.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setCellInfo() {
        guard let model = model else { return }
        if !model.isDefaultCover {
            self.coverImageView.bt.setLarkImage(with: .default(key: model.cover.mainCover.key),
                                                placeholder: Resources.hongbao_open_top)
        } else {
            self.coverImageView.bt.setLarkImage(with: .default(key: ""),
                                                placeholder: Resources.hongbao_open_top)
        }
        nameLabel.text = model.cover.name
        if model.cover.hasDisplayName, model.cover.displayName.displayName.isEmpty == false {
            let displayName = model.cover.displayName
            descriptionLabel.text = displayName.displayName
            descriptionLabel.isHidden = false
            descriptionBackgroundView.isHidden = false
            var pass = ImagePassThrough()
            pass.key = displayName.backgroundImg.key
            pass.fsUnit = displayName.backgroundImg.fsUnit
            let placeholder = self.processImage(Resources.hongbao_card_background,
                                                scale: 1,
                                                bgBorderWidth: CGFloat(10))
            descriptionBackgroundView.bt.setLarkImage(with: .default(key: displayName.backgroundImg.key ?? ""),
                                                      placeholder: placeholder,
                                                      passThrough: pass,
                                                      options: [.disableAutoSetImage],
                                                      completion: { [weak self] result in
                guard let icon = try? result.get().image, !displayName.backgroundImg.key.isEmpty else { return }
                let scale = Self.Config.descriptionBackgroundViewHeight / icon.size.height
                self?.descriptionBackgroundView.image = self?.processImage(icon,
                                                                           scale: scale,
                                                                           bgBorderWidth: CGFloat(displayName.bgBorderWidth) * scale)
           })
        } else {
            descriptionLabel.isHidden = true
            descriptionBackgroundView.isHidden = true
        }
    }
    private func processImage(_ image: UIImage,
                              scale: CGFloat,
                              bgBorderWidth: CGFloat) -> UIImage? {
        // 缩放
        let scaledIcon = image.ud.scaled(by: scale)
        // 控制可拉伸范围
        let inset = UIEdgeInsets(top: 0, left: bgBorderWidth, bottom: 0, right: bgBorderWidth)
        let resizableImage = scaledIcon.resizableImage(withCapInsets: inset,
                                                       resizingMode: .stretch)
        return resizableImage
    }
}

struct RedPacketCoverDetailCellModel {
    let reuseIdentify = NSStringFromClass(RedPacketCoverDetailCell.self)

    let cover: HongbaoCover
    var isDefaultCover = false
}

// origin UICollectionViewDelegate wrapper
protocol UICollectionViewDelegateWrapper: UICollectionViewDelegate {
}

// red packet detail collectionView: can specicy page width
final class RedPacketCoverDetailCollectionView: UICollectionView,
                                          UICollectionViewDelegate {
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.isPagingEnabled = true
        scrollView.delegate = self
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(scrollViewOnTapped(_:))))
        return scrollView
    }()

    weak var wrapperDelegate: UICollectionViewDelegateWrapper?

    init(frame: CGRect,
         scrollViewWidth: CGFloat,
         collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: .zero, collectionViewLayout: layout)
        self.delegate = self

        self.addSubview(scrollView)
        scrollView.frame = CGRect(x: 0, y: 0, width: scrollViewWidth, height: 0)
    }

    // 这里利用scrollView的宽度和PagingEnabled来实现自定义翻页宽度的CollectionView
    // 因此外部指定scrollView的宽度, 即翻页的宽度
    func setInlineScrollViewWidth(_ width: CGFloat) {
        scrollView.frame = CGRect(x: 0, y: 0, width: width, height: 0)
    }

    func setInlineScrollViewContentSize(_ size: CGSize) {
        self.scrollView.contentSize = size
    }

    func setInlineScrollViewContentOffset(_ offset: CGPoint) {
        let isScroll = scrollView.isDragging || scrollView.isDecelerating || scrollView.isTracking
        guard !isScroll else { return }
        scrollView.contentOffset = offset
    }

    @objc
    func scrollViewOnTapped(_ recognizer: UITapGestureRecognizer) {
        let point = recognizer.location(in: self)
        if let indexPath = indexPathForItem(at: point) {
            self.collectionView(self, didSelectItemAt: indexPath)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func adjustVisibleCellsAlpha() {
        // adjust the aplha value of the cell on the screen according to the width of the cell displayed on the screen
        for cell in visibleCells {
            let cellFrame = self.convert(cell.frame, to: self.superview)
            let cellVisibleWidth: CGFloat
            if cellFrame.maxX < cellFrame.width {
                cellVisibleWidth = cellFrame.maxX
            } else if cellFrame.maxX < self.frame.width {
                cellVisibleWidth = cellFrame.width
            } else {
                cellVisibleWidth = self.frame.width - cellFrame.origin.x
            }
            // minium alpha value is 0.5
            cell.contentView.alpha = max(0.5, cellVisibleWidth / cellFrame.width)
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == self.scrollView {
            self.contentOffset = scrollView.contentOffset
        }
        // adjust all visible cell alpha to display anmiation
        adjustVisibleCellsAlpha()
        wrapperDelegate?.scrollViewDidScroll?(scrollView)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.scrollView.setContentOffset(CGPoint(x: indexPath.item * Int(self.scrollView.frame.width), y: 0), animated: true)
        wrapperDelegate?.collectionView?(collectionView, didSelectItemAt: indexPath)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return self.scrollView
    }
}
