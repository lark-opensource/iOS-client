//
//  ImageListCell.swift
//  UniverseDesignImageList
//
//  Created by 郭怡然 on 2022/9/20.
//

import Foundation
import UIKit
import UniverseDesignColor
import UniverseDesignProgressView
import UniverseDesignIcon

class ImageListCell: UICollectionViewCell {
    static let progressWidth: CGFloat = 16
    static let closeBtnMargin: CGFloat = 4
    static let iconSize: CGFloat = 24
    static let closeIconSize: CGFloat = 12
    static let closeViewSize: CGFloat = 20
    static let cornerRadius: CGFloat = 8
    static let reuseIdentifier: String = "ImageListCell"

    var itemModel: ImageListItem?

    weak var delegate: ImageListCellDelegate?

    var progressValue: CGFloat? {
        didSet {
            guard let progressValue = progressValue else { return }
            progressView.setProgress(progressValue, animated: true)
        }
    }
    var status: ImageListItem.Status = .initial {
        didSet {
            changeStatus()
        }
    }

    func configure(with model: ImageListItem) {
        self.itemModel = model
        imageView.image = model.image
        imageView.contentMode = .scaleAspectFill
        status = model.status
    }

    var imageView = UIImageView()

    lazy var retryView: UIImageView = {
        let view = UIImageView(image: UDIcon.refreshOutlined.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill))
        let tapRetryView = UITapGestureRecognizer(target: self, action: #selector(retryCell(_:)))
        view.addGestureRecognizer(tapRetryView)
        view.isUserInteractionEnabled = true
        return view
    }()

    var progressView: UDProgressView = {
        let layoutConfig = UDProgressViewLayoutConfig(circleProgressWidth: progressWidth)
        let progressView = UDProgressView(config: UDProgressViewUIConfig(type: .circular, layoutDirection: . vertical, themeColor: UDProgressViewThemeColor.maskThemeColor, showValue: true), layoutConfig: layoutConfig)
        return progressView
    }()

    lazy var dimmingView: UIView = {
        let view = UIView()
        let tapDimmingView = UITapGestureRecognizer(target: self, action: #selector(clickImage(_:)))
        view.addGestureRecognizer(tapDimmingView)
        return view
    }()

    lazy var closeView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.6)
        var closeIcon = UDIcon.getIconByKey(.closeBoldOutlined,
                                            iconColor: UIColor.ud.primaryOnPrimaryFill,
                                            size: CGSize(width: ImageListCell.closeIconSize,
                                                         height: ImageListCell.closeIconSize))
        let icon = UIImageView(image: closeIcon)
        view.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        view.layer.cornerRadius = ImageListCell.closeViewSize / 2
        let tapCloseView = UITapGestureRecognizer(target: self, action: #selector(deleteCell(_:)))
        view.addGestureRecognizer(tapCloseView)
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.cornerRadius = ImageListCell.cornerRadius
        self.layer.masksToBounds = true
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupSubviews() {
        addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        addSubview(dimmingView)
        dimmingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        addSubview(closeView)
        closeView.snp.makeConstraints { make in
            make.width.height.equalTo(ImageListCell.closeViewSize)
            make.right.equalToSuperview().offset(-ImageListCell.closeBtnMargin)
            make.top.equalToSuperview().offset(ImageListCell.closeBtnMargin)
        }
        addSubview(progressView)
        progressView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        addSubview(retryView)
        retryView.snp.makeConstraints { make in
            make.width.height.equalTo(ImageListCell.iconSize)
            make.center.equalToSuperview()
        }
    }

    func changeStatus() {
        switch status {
        case .inProgress:
            retryView.isHidden = true
            progressView.isHidden = false
            dimmingView.isHidden = false
            dimmingView.backgroundColor = UIColor.ud.bgMask.withAlphaComponent(0.4)
            dimmingView.layer.borderWidth = 1
            dimmingView.layer.borderColor = UIColor.ud.lineBorderCard.cgColor
        case .success:
            progressView.isHidden = true
            retryView.isHidden = true
            dimmingView.isHidden = false
            dimmingView.backgroundColor = UIColor.ud.fillImgMask
            dimmingView.layer.borderWidth = 1
            dimmingView.layer.borderColor = UIColor.ud.lineBorderCard.cgColor
        case .error:
            progressView.isHidden = true
            retryView.isHidden = false
            dimmingView.isHidden = false
            dimmingView.backgroundColor = UIColor.ud.bgMask.withAlphaComponent(0.4)
            dimmingView.layer.borderWidth = 1
            dimmingView.layer.borderColor = UIColor.ud.functionDangerContentDefault.cgColor
        case .initial:
            retryView.isHidden = true
            progressView.isHidden = true
            dimmingView.isHidden = true
            dimmingView.layer.borderWidth = 0
            dimmingView.layer.cornerRadius = ImageListCell.cornerRadius
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.imageView.image = nil
        self.progressValue = 0
        self.status = .initial
    }
}

extension ImageListCell {
    @objc
    func deleteCell(_ sender: UITapGestureRecognizer) {
        guard let onDeleteClicked = delegate?.onDeleteClicked,
              let itemModel = itemModel else { return }
        onDeleteClicked(itemModel)
    }
    @objc
    func retryCell(_ sender: UITapGestureRecognizer) {
        guard let onRetryClicked = delegate?.onRetryClicked,
              let itemModel = itemModel else { return }
        onRetryClicked(itemModel)
    }
    @objc
    func clickImage(_ sender: UITapGestureRecognizer) {
        guard let onImageClicked = delegate?.onImageClicked,
              let itemModel = itemModel else { return }
        onImageClicked(itemModel)
    }
}

protocol ImageListCellDelegate: AnyObject {
    var onRetryClicked: ((ImageListItem) -> Void)? { get set }
    var onImageClicked: ((ImageListItem) -> Void)? {  get set }
    var onDeleteClicked: ((ImageListItem) -> Void)? { get set }
}
