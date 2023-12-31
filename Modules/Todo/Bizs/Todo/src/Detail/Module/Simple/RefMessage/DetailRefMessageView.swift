//
//  DetailRefMessageView.swift
//  Todo
//
//  Created by 张威 on 2021/2/3.
//

import LarkUIKit
import SnapKit
import LarkZoomable
import RichLabel
import LarkExtensions
import CTFoundation
import UniverseDesignIcon
import UniverseDesignFont

protocol DetailRefMessageViewDataType {
    var title: String { get }
    var content: AttrText { get }
    var isDeletable: Bool { get }
}

/// Detail - Chat - View

/// ref: LarkCore.MergeForwardView

class DetailRefMessageView: UIView, ViewDataConvertible {

    var viewData: DetailRefMessageViewDataType? {
        didSet {
            guard let viewData = viewData else {
                isHidden = true
                return
            }
            isHidden = false
            titleLabel.text = viewData.title
            contentLabel.attributedText = viewData.content
            deleteView.isHidden = !viewData.isDeletable
        }
    }

    var onTap: (() -> Void)?
    var onDelete: (() -> Void)?

    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let contentLabel = LKLabel()
    private let deleteView = UIImageView()

    override var bounds: CGRect {
        didSet {
            contentLabel.preferredMaxLayoutWidth = self.bounds.width - 64
            contentLabel.invalidateIntrinsicContentSize()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isHidden = true
        backgroundColor = UIColor.ud.bgBody

        containerView.backgroundColor = UIColor.ud.N100
        containerView.layer.masksToBounds = true
        containerView.layer.cornerRadius = 4
        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.bottom.equalToSuperview()
        }

        titleLabel.font = .body0
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = 0
        titleLabel.textColor = UIColor.ud.textTitle
        containerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(22)
            make.right.equalToSuperview().offset(-48)
            make.top.equalToSuperview().offset(16)
            make.height.greaterThanOrEqualTo(24)
        }

        let line = UIView()
        line.backgroundColor = UIColor.ud.colorfulYellow
        containerView.addSubview(line)
        line.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.width.equalTo(2)
            make.height.equalTo(titleLabel.snp.height)
            make.centerY.equalTo(titleLabel)
        }

        let baseAttrs: [AttrText.Key: Any] = [
            .foregroundColor: UIColor.ud.N600,
            .font: UDFont.systemFont(ofSize: 14)
        ]
        contentLabel.backgroundColor = UIColor.clear
        contentLabel.font = .body3
        contentLabel.textColor = UIColor.ud.N600
        contentLabel.outOfRangeText = AttrText(string: "\u{2026}", attributes: baseAttrs)
        contentLabel.numberOfLines = 4
        contentLabel.textAlignment = .left
        contentLabel.lineSpacing = 2
        containerView.addSubview(contentLabel)
        contentLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.bottom.equalToSuperview().offset(-16)
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
        }

        let closeIcon = UDIcon.closeOutlined.ud.resized(to: CGSize(width: 16, height: 16))
        deleteView.image = closeIcon.ud.withTintColor(UIColor.ud.iconN2)
        deleteView.contentMode = .center
        deleteView.isUserInteractionEnabled = true
        deleteView.isHidden = true
        containerView.addSubview(deleteView)
        deleteView.snp.makeConstraints { make in
            make.width.height.equalTo(44)
            make.top.equalToSuperview().offset(2)
            make.right.equalToSuperview().offset(-2)
        }

        deleteView.lu.addTapGestureRecognizer(action: #selector(handleDelete), target: self)
        containerView.lu.addTapGestureRecognizer(action: #selector(handleTap), target: self)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func handleTap() {
        onTap?()
    }

    @objc
    private func handleDelete() {
        onDelete?()
    }

}
