//
//  RedPacketCoverCell.swift
//
//  Created by JackZhao on 2021/10/28.
//  Copyright © 2021 JACK. All rights reserved.
//

import UIKit
import Foundation
import LarkCore
import LarkUIKit
import ByteWebImage
import LarkSDKInterface

struct RedPacketCoverItemCellModel {
    let reuseIdentify = NSStringFromClass(RedPacketCoverItemCell.self)

    let cover: HongbaoCover
    var isDefaultCover = false
    var isShowBorder = false
}

final class RedPacketCoverCellViewModel {
    static let collectionCellSize = CGSize(width: 106, height: 200)
    let reuseIdentify = NSStringFromClass(RedPacketCoverCell.self)

    let title: String
    let datas: [RedPacketCoverItemCellModel]
    // param: coverId
    let coverItemCellTapHandler: (Int64) -> Void

    init(title: String = "",
         datas: [RedPacketCoverItemCellModel] = [],
         coverItemCellTapHandler: @escaping (Int64) -> Void = { _ in }) {
        self.title = title
        self.datas = datas
        self.coverItemCellTapHandler = coverItemCellTapHandler
    }
}

// 一行排列的红包封面cell
final class RedPacketCoverCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource {
    var viewModel: RedPacketCoverCellViewModel? {
        didSet {
            setCellInfo()
        }
    }

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .left
        return label
    }()

    private lazy var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 10
        flowLayout.itemSize = RedPacketCoverCellViewModel.collectionCellSize
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        flowLayout.scrollDirection = .horizontal

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.bounces = true
        collectionView.backgroundColor = UIColor.ud.bgBody
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(RedPacketCoverItemCell.self, forCellWithReuseIdentifier: NSStringFromClass(RedPacketCoverItemCell.self))
        return collectionView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = UIColor.ud.bgBody
        selectionStyle = .none

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.left.equalTo(16)
        }

        contentView.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(RedPacketCoverCellViewModel.collectionCellSize.height)
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel?.datas.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let vm = viewModel, indexPath.row < vm.datas.count else {
            assertionFailure("datasource out of range")
            return UICollectionViewCell()
        }
        let cellVM = vm.datas[indexPath.row]
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellVM.reuseIdentify, for: indexPath) as? RedPacketCoverItemCell else { return UICollectionViewCell() }
        cell.model = cellVM
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let vm = viewModel, indexPath.row < vm.datas.count else {
            assertionFailure("datasource out of range")
            return
        }
        let cellVM = vm.datas[indexPath.row]
        viewModel?.coverItemCellTapHandler(cellVM.cover.id)
    }

    func setCellInfo() {
        guard let vm = viewModel else { return }
        titleLabel.text = vm.title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// 红包封面单个cell
final class RedPacketCoverItemCell: UICollectionViewCell {
    struct Config {
        static let descriptionLabelHeight: CGFloat = 14
        static let descriptionBackgroundViewHeight: CGFloat = 20
    }

    var model: RedPacketCoverItemCellModel? {
        didSet {
            setCellInfo()
        }
    }

    private let redPacketCoverContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        view.layer.borderColor = UIColor.ud.colorfulBlue.cgColor
        return view
    }()

    private let redPacketCoverImageView: ByteImageView = {
        let imageView = ByteImageView(image: Resources.hongbao_open_top)
        imageView.layer.cornerRadius = 6
        imageView.contentMode = .scaleAspectFill
        imageView.autoPlayAnimatedImage = false
        imageView.clipsToBounds = true
        return imageView
    }()

    private let openImageView: UIImageView = {
        let imageView = UIImageView(image: Resources.red_packet_open)
        imageView.layer.cornerRadius = 16
        return imageView
    }()

    private let bottomImageView: UIImageView = {
        let imageView = UIImageView(image: Resources.hongbao_open_bottom)
        imageView.layer.cornerRadius = 6
        imageView.clipsToBounds = true
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textCaption
        label.textAlignment = .center
        return label
    }()

    // 用来显示企业名
    var descriptionLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.Y200.alwaysLight
        label.numberOfLines = 1
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 6)
        return label
    }()

    var descriptionBackgroundView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        contentView.backgroundColor = UIColor.ud.bgBody

        contentView.addSubview(redPacketCoverContainer)
        redPacketCoverContainer.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(172)
        }

        redPacketCoverContainer.addSubview(redPacketCoverImageView)
        redPacketCoverImageView.snp.makeConstraints { make in
            make.top.left.equalTo(3)
            make.right.equalTo(-3)
            make.height.equalTo(133)
        }

        redPacketCoverContainer.addSubview(bottomImageView)
        bottomImageView.snp.makeConstraints { make in
            make.left.equalTo(3)
            make.right.bottom.equalTo(-3)
            make.height.equalTo(59)
        }

        redPacketCoverContainer.addSubview(openImageView)
        openImageView.snp.makeConstraints { make in
            make.size.equalTo(32)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(redPacketCoverImageView).offset(15)
        }

        redPacketCoverContainer.addSubview(descriptionBackgroundView)
        redPacketCoverContainer.addSubview(descriptionLabel)
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
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(redPacketCoverContainer.snp.bottom).offset(10)
            make.left.right.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setCellInfo() {
        guard let model = model else { return }
        redPacketCoverContainer.layer.borderWidth = model.isShowBorder ? 2 : 0
        if !model.isDefaultCover {
            var pass = ImagePassThrough()
            pass.fsUnit = model.cover.mainCover.fsUnit
            pass.key = model.cover.mainCover.key
            self.redPacketCoverImageView.bt.setLarkImage(with: .default(key: model.cover.mainCover.key),
                                                         placeholder: Resources.hongbao_open_top,
                                                         passThrough: pass)
        } else {
            self.redPacketCoverImageView.bt.setLarkImage(with: .default(key: ""),
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
