//
//  DriveUpdatingCell.swift
//  SpaceKit
//
//  Created by chenjiahao.gill on 2019/3/3.
//  

import UIKit
import SnapKit
import SKCommon
import SKResource
import UniverseDesignColor
import UniverseDesignProgressView
import UniverseDesignIcon
import SKUIKit
import SKFoundation

public final class DriveUploadContentView: UIView {

    private var curProgress: Float = 0.0
    // MARK: - 相关 View
    private lazy var iconImage: UIImageView = {
        let imgView = UIImageView(frame: .zero)
        imgView.image = UDIcon.getIconByKeyNoLimitSize(.driveloadOutlined).ud.withTintColor(UIColor.ud.colorfulBlue)
        imgView.contentMode = .scaleAspectFill
        imgView.isHidden = true
        return imgView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.textColor = UDColor.textTitle
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private lazy var errImg: UIImageView = {
        let img = UIImageView(frame: .zero)
        img.image = UDIcon.getIconByKeyNoLimitSize(.warningOutlined).ud.withTintColor(UIColor.ud.colorfulOrange)
        img.contentMode = .scaleAspectFill
        img.isHidden = true
        return img
    }()

    private var titleText: String = BundleI18n.SKResource.Doc_List_UploadingFile {
        didSet {
            titleLabel.text = titleText
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func rotate() {
        DispatchQueue.main.async {
            let animation = CABasicAnimation(keyPath: "transform.rotation.z")
            animation.fromValue = 0
            animation.toValue = CGFloat(Double.pi * 2)
            animation.duration = 3.0
            animation.repeatCount = Float.infinity
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false
            self.iconImage.layer.add(animation, forKey: "RotationForeverAnimation")
        }
    }

    private func setupUI() {
        self.backgroundColor = UDColor.bgFloat
        self.layer.cornerRadius = 10
        self.layer.ud.setBorderColor(UDColor.lineBorderCard)
        self.layer.borderWidth = 1
        self.layer.ud.setShadow(type: .s2Down)
        addSubview(iconImage)
        addSubview(titleLabel)
        addSubview(errImg)
        iconImage.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 24, height: 24))
            make.left.equalTo(12)
            make.centerY.equalToSuperview()
        }
        errImg.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 24, height: 24))
            make.left.equalTo(12)
            make.centerY.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(iconImage.snp.right).offset(13)
            make.height.equalTo(24)
            make.centerY.equalToSuperview()
        }
    }

    public func update(_ model: DriveStatusItem) {
        // 根据状态重新布局 view
        if model.status == .uploading {
            rotate()
            let totalCount: Int
            if model.progress < 0.001 {
                totalCount = model.count
            } else if model.progress == 1 {
                totalCount = 0
            } else {
                totalCount = model.totalCount
            }
            iconImage.isHidden = false
            errImg.isHidden = true
            titleText = BundleI18n.SKResource.Drive_Drive_Uploading + " \(totalCount - model.count + 1)/\(totalCount)"
        } else if model.status == .failed {
            iconImage.isHidden = true
            errImg.isHidden = false
            titleText = BundleI18n.SKResource.Doc_List_UploadedFail(model.count)
        }
    }
}

class DriveUpdatingCell: UICollectionViewCell {

    private lazy var uploadView = DriveUploadContentView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(uploadView)
        if SKDisplay.pad, UserScopeNoChangeFG.MJ.newIpadSpaceEnable {
            uploadView.snp.makeConstraints { make in
                make.left.equalToSuperview()
                make.right.equalToSuperview()
                make.top.equalToSuperview().offset(16)
                make.height.equalTo(48)
            }
        } else {
            uploadView.snp.makeConstraints { make in
                make.left.equalToSuperview().offset(16)
                make.right.equalToSuperview().offset(-16)
                make.top.equalToSuperview().offset(16)
                make.height.equalTo(48)
            }
        }
    }

    func update(_ model: DriveStatusItem, topOffset: CGFloat = 16) {
        uploadView.update(model)
        uploadView.snp.updateConstraints { make in
            make.top.equalToSuperview().offset(topOffset)
        }
    }
}

// Space 新列表架构中，网格视图下，sectionInset 会影响 drive 上传进度的 UI 布局，暂时通过包装一层来实现
class DriveGridUploadCell: UICollectionViewCell {
    private lazy var actualContentView = UIView()
    private lazy var uploadView = DriveUploadContentView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(actualContentView)
        actualContentView.snp.makeConstraints { make in
            // 参考 SpaceRecentListSection 的 grid section insets
            make.top.equalToSuperview().inset(-2)
            make.bottom.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }

        actualContentView.addSubview(uploadView)
        uploadView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalToSuperview().offset(6)
            make.height.equalTo(48)
        }
    }

    func update(item: DriveStatusItem) {
        uploadView.update(item)
    }
}
