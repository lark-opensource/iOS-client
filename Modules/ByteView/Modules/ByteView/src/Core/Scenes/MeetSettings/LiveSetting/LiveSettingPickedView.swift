//
//  LiveSettingPickedView.swift
//  ByteView
//
//  Created by sihuahao on 2022/5/4.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import UniverseDesignIcon
import UIKit
import ByteViewUI

class PickerHeaderCustomView: UIView {

    private lazy var line: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        return line
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = I18n.View_MV_ViewerSpecific_Explain
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textCaption
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.bgBody

        addSubview(titleLabel)
        addSubview(line)
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        line.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.height.equalTo(0.5)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol PickedViewDelegate: AnyObject {
    func refreshPickedLayout()
    func goToPickerBody()
}

extension LiveSettingPickedView: PickedCollectionProtocol {
    var totalHeadCount: Int { viewModel.totalHeadCount }
    var pickedViewHeight: CGFloat { viewModel.pickedViewHeight }
}

final class LiveSettingPickedView: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    var viewModel: LiveSettingPickedViewModel
    weak var delegate: PickedViewDelegate?

    private lazy var pickedCollection: UICollectionView = {
        let layout = LiveSettingPickedLeftLayout()
        layout.minimumLineSpacing = 4
        layout.minimumInteritemSpacing = 4
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(LiveSettingPickedFlowCollectionCell.self, forCellWithReuseIdentifier: LiveSettingPickedFlowCollectionCell.description())
        collectionView.register(LiveSettingPickedMoreCollectionCell.self, forCellWithReuseIdentifier: LiveSettingPickedMoreCollectionCell.description())
        collectionView.backgroundColor = UIColor.clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.allowsSelection = false
        collectionView.isScrollEnabled = false
        return collectionView
    }()

    private lazy var rightArrorIcon: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.getIconByKey(.rightOutlined, iconColor: UIColor.ud.iconN3, size: CGSize(width: 16, height: 16))
        return view
    }()

    override init(frame: CGRect) {
        viewModel = LiveSettingPickedViewModel(viewWidth: frame.width)
        super.init(frame: frame)
        viewModel.delegate = self
        self.backgroundColor = UIColor.clear
        addSubview(pickedCollection)
        addSubview(rightArrorIcon)

        pickedCollection.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview()
            maker.left.equalToSuperview()
            maker.right.equalToSuperview().offset(-16)
            maker.bottom.equalToSuperview()
        }

        rightArrorIcon.snp.makeConstraints { make in
            make.right.centerY.equalToSuperview()
            make.size.equalTo(16)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        if viewModel.needMoreCell {
            return viewModel.visibleCount + 1
        } else {
            return viewModel.pickedDatas.count
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if viewModel.needMoreCell && viewModel.visibleCount == indexPath.row {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LiveSettingPickedMoreCollectionCell.description(), for: indexPath) as? LiveSettingPickedMoreCollectionCell {
                cell.configNum(num: viewModel.addOnHeadCount)
                return cell
            }
        } else {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LiveSettingPickedFlowCollectionCell.description(), for: indexPath) as? LiveSettingPickedFlowCollectionCell {
                let pickedData = viewModel.pickedDatas

                cell.configNormalCell(avatarKey: pickedData[indexPath.row].avatarKey, memberId: pickedData[indexPath.row].id, isChatter: pickedData[indexPath.row].isChatter, isDepartment: pickedData[indexPath.row].isDepartment, name: pickedData[indexPath.row].name, isAllResigned: self.viewModel.isAllResigned ?? false)
                return cell
            }
        }
        return UICollectionViewCell()
    }

    // MARK: - UICollectionViewDelegate / UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellWidth: CGFloat = viewModel.visibleWidth[indexPath.row]
        return CGSize(width: cellWidth, height: 28)

    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 4
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 4
    }
}

extension LiveSettingPickedView: PickedViewModelDelegate {
    func reload() {
        pickedCollection.reloadData()
        delegate?.refreshPickedLayout()
    }
}

final class LiveSettingPickedFlowCollectionCell: UICollectionViewCell {

    private lazy var avatarImage = AvatarView()

    private lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.lineBreakMode = .byTruncatingTail
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private lazy var content: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 14
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(content)
        content.addSubview(avatarImage)
        content.addSubview(contentLabel)

        content.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        avatarImage.snp.makeConstraints { make in
            make.size.equalTo(20)
            make.left.equalToSuperview().offset(4)
            make.centerY.equalToSuperview()
        }

        contentLabel.snp.makeConstraints { make in
            make.left.equalTo(avatarImage.snp.right).offset(4)
            make.right.equalToSuperview().offset(-8)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configNormalCell(avatarKey: String, memberId: String, isChatter: Bool, isDepartment: Bool, name: String, isAllResigned: Bool) {
        content.backgroundColor = isChatter ? UIColor.ud.udtokenTagNeutralBgNormal : UIColor.ud.udtokenTagBgBlue

        if isDepartment {
            avatarImage.setAvatarInfo(.asset(BundleResources.ByteView.Live.DepartmentAvatar), size: .medium)
        } else {
            if isAllResigned {
                avatarImage.setAvatarInfo(.asset(UDIcon.getIconByKey(.memberFilled, iconColor: UIColor.ud.udtokenTagNeutralTextNormal)), size: .medium)
                contentLabel.textColor = UIColor.ud.udtokenTagNeutralTextNormal
            } else {
                avatarImage.setAvatarInfo(.remote(key: avatarKey, entityId: memberId), size: .medium)
            }
        }
        contentLabel.text = name
    }
}

class LiveSettingPickedMoreCollectionCell: UICollectionViewCell {

    private lazy var content: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.udtokenTagNeutralBgNormal
        view.layer.cornerRadius = 14
        return view
    }()

    private lazy var labelMore: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textTitle
        return label
    }()


    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(content)
        content.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        content.addSubview(labelMore)
        labelMore.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configNum(num: Int) {
        labelMore.text = "+\(num)"
    }
}
