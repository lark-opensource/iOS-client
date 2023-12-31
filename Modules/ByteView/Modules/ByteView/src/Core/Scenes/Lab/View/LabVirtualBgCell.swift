//
//  LabVirtualBgCell.swift
//  ByteView
//
//  Created by admin on 2020/9/19.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import SnapKit
import UniverseDesignIcon
import ByteViewCommon
import ByteViewUI

protocol LabVirtualBgCellDelegate: AnyObject {
    func didTapDelete(model: VirtualBgModel)
}

class LabVirtualBgCell: UICollectionViewCell {
    struct Layout {
        static func cellImageWidth() -> CGFloat { Layout.isRegular() ? 78 : 48 }
        static func cellImageHeight() -> CGFloat { Layout.isRegular() ? 78 : 48 }
        static let cellCornerRadius: CGFloat = 8
        static let borderCornerRadius: CGFloat = 10
        static func cellBorderWidth() -> CGFloat { Layout.isRegular() ? 2.5 : 2 }
        static func cellBorderGapSize() -> CGFloat { Layout.isRegular() ? 4 : 2 }
        static func iconSize() -> CGSize { Layout.isRegular() ? CGSize(width: 32, height: 32) : CGSize(width: 20, height: 20) }
        static func cellBorderTotalWidth() -> CGFloat { Layout.cellBorderWidth() + Layout.cellBorderGapSize() }
        static let deleteSize: CGFloat = 32
        static func deleteCircleSize() -> CGFloat { Layout.isRegular() ? 28 : 20 }
        static func deleteImageSize() -> CGFloat { Layout.isRegular() ? 16 : 10 }

        static func isRegular() -> Bool {
            return VCScene.rootTraitCollection?.isRegular ?? false
        }
    }

    private lazy var containerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = Layout.cellCornerRadius
        view.clipsToBounds = true
        return view
    }()

    private var exclusiveLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.font = UIFont.systemFont(ofSize: 10)
        label.textAlignment = .center
        label.text = I18n.View_G_Interview_VirtualBackground
        return label
    }()

    private var exclusiveView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.staticBlack70
        view.isHidden = true
        view.layer.cornerRadius = Layout.cellCornerRadius
        view.layer.masksToBounds = true
        view.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        return view
    }()

    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = Layout.cellCornerRadius
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    private lazy var deleteBtn: UIButton = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloat
        view.isUserInteractionEnabled = false
        view.frame = CGRect(x: (Layout.deleteSize - Layout.deleteCircleSize()) / 2, y: (Layout.deleteSize - Layout.deleteCircleSize()) / 2, width: Layout.deleteCircleSize(), height: Layout.deleteCircleSize())
        view.layer.cornerRadius = Layout.deleteCircleSize() / 2
        view.layer.borderWidth = 0.5
        view.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        view.layer.ud.setShadowColor(UIColor.ud.shadowDefaultSm)
        view.layer.shadowOpacity = 1
        view.layer.shadowRadius = 4
        view.layer.shadowOffset = CGSize(width: 0, height: 2)

        let image = UDIcon.getIconByKey(.closeOutlined, iconColor: UIColor.ud.iconN2, size: CGSize(width: Layout.deleteImageSize(), height: Layout.deleteImageSize()))
        let imageView = UIImageView(image: image)
        imageView.frame = CGRect(x: (Layout.deleteCircleSize() - Layout.deleteImageSize()) / 2, y: (Layout.deleteCircleSize() - Layout.deleteImageSize()) / 2, width: Layout.deleteImageSize(), height: Layout.deleteImageSize())
        view.addSubview(imageView)

        let button = UIButton()
        button.addTarget(self, action: #selector(deleteAction), for: .touchUpInside)
        button.addSubview(view)
        button.isHidden = true

        return button
}()

    // 图标（只有无/虚拟背景/增加图片）
    private lazy var iconView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    private var loadingView: LoadingView = {
        let loadingView = LoadingView(frame: CGRect(x: 0, y: 0, width: 24, height: 24), style: .grey)
        loadingView.isHidden = true
        return loadingView
    }()

    var deleteBlock: ((VirtualBgModel) -> Void)?
    weak var delegate: LabVirtualBgCellDelegate?
    var model: VirtualBgModel?

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(containerView)
        self.containerView.addSubview(imageView)
        self.containerView.addSubview(exclusiveView)
        self.containerView.addSubview(iconView)
        self.containerView.addSubview(loadingView)

        // 自身设置边框
        self.contentView.layer.cornerRadius = Layout.borderCornerRadius
        self.contentView.layer.borderWidth = CGFloat(Layout.cellBorderWidth())
        switchSelectedState(selected: true)

        containerView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().inset(Layout.cellBorderWidth())
        }

        imageView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().inset(Layout.cellBorderGapSize())
        }

        iconView.snp.makeConstraints { maker in
            maker.size.equalTo(Layout.iconSize())
            maker.center.equalToSuperview()
        }

        loadingView.snp.makeConstraints { maker in
            maker.size.equalTo(24)
            maker.center.equalToSuperview()
        }

        exclusiveView.addSubview(exclusiveLabel)
        exclusiveLabel.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        exclusiveView.snp.makeConstraints { (make) in
            make.right.left.bottom.equalToSuperview().inset(Layout.cellBorderGapSize())
            make.height.equalTo(16)
        }

        self.addSubview(deleteBtn)
        deleteBtn.snp.makeConstraints { maker in
            maker.size.equalTo(Layout.deleteSize)
            maker.top.equalTo(imageView.snp.top).offset(Layout.isRegular() ? -10 : -12)
            maker.right.equalTo(imageView.snp.right).offset(Layout.isRegular() ? 10 : 12)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bindData(model: VirtualBgModel) {
        self.model = model

        switchSelectedState(selected: model.isSelected)
        let iconColor = model.isSelected ? UIColor.ud.primaryContentDefault : UIColor.ud.iconN2

        deleteBtn.isHidden = !model.isShowDelete

        switch (model.bgType, model.status.isLoading) {
        case (.setNone, false):
            self.iconView.isHidden = false
            self.exclusiveView.isHidden = true
            self.iconView.image = UDIcon.getIconByKey(.banOutlined, iconColor: iconColor, size: Layout.iconSize())
            self.imageView.image = nil
            self.imageView.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.1)
            self.stopLoading()
        case (.blur, false):
            self.exclusiveView.isHidden = true
            self.iconView.isHidden = false
            self.iconView.image = UDIcon.getIconByKey(.blurOutlined, iconColor: iconColor, size: Layout.iconSize())
            self.imageView.backgroundColor = nil
            self.imageView.image = BundleResources.ByteView.Lab.VirtualBg
            self.stopLoading()
        case (.virtual, false):
            self.iconView.isHidden = true
            self.imageView.backgroundColor = Display.pad ? .ud.bgFiller : .ud.N900.withAlphaComponent(0.1)
//            if let imageData = NSData(contentsOf: URL.init(fileURLWithPath: model.thumbnailPath)),
//                let rawImage = UIImage(data: imageData as Data) {
//                self.imageView.image = rawImage
//            }
            if model.imageSource == .appPeople { self.exclusiveView.isHidden = false } else {
                self.exclusiveView.isHidden = true
            }
            self.stopLoading()
        case (.add, false):
            self.exclusiveView.isHidden = true
            self.iconView.isHidden = false
            self.iconView.image = UDIcon.getIconByKey(.moreAddOutlined, iconColor: iconColor, size: Layout.iconSize())
            self.imageView.image = nil
            self.imageView.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.1)
            self.stopLoading()
        case (_, true):
            self.exclusiveView.isHidden = true
            self.iconView.isHidden = true
            self.imageView.image = nil
            self.imageView.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.1)
            self.playLoading()
        }
    }

    private func switchSelectedState(selected: Bool) {
        self.contentView.layer.vc.borderColor = selected ? .ud.primaryContentDefault : .ud.cgClear
    }

    func playLoading() {
        loadingView.isHidden = false
        loadingView.play()
    }

    func stopLoading() {
        loadingView.stop()
        loadingView.isHidden = true
    }

    @objc
    private func deleteAction() {
        if let model = self.model {
            self.delegate?.didTapDelete(model: model)
            self.deleteBlock?(model)
        }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let result = super.hitTest(point, with: event) // 解决删除按钮超出父视图无法相应事件的问题
        let deleteBtnPoint = deleteBtn.convert(point, from: self)
        if deleteBtn.point(inside: deleteBtnPoint, with: event), !deleteBtn.isHidden {
            return deleteBtn
        }
        return result
    }
}
