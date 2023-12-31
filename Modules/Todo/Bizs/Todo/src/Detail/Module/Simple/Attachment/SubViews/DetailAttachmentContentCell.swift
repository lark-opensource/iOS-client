//
//  DetailAttachmentContentCell.swift
//  Todo
//
//  Created by baiyantao on 2022/12/21.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignProgressView
import TodoInterface
import UniverseDesignFont

protocol DetailAttachmentContentCellDelegate: AnyObject {
    func onClick(_ cell: DetailAttachmentContentCell)
    func onRetryBtnClick(_ cell: DetailAttachmentContentCell)
    func onDeleteBtnClick(_ cell: DetailAttachmentContentCell)
}

struct DetailAttachmentContentCellData {
    let source: Source

    var coverImage: UIImage?
    var nameText: String?
    var sizeText: String?
    var uploadState: UploadState = .idle
    var canDelete = false

    enum UploadState {
        case idle
        case inProgress(CGFloat)
        case failed
    }
    enum Source {
        case rust(attachment: Rust.Attachment)
        case attachmentService(info: AttachmentInfo)
    }
}

extension DetailAttachmentContentCellData {
    var cellHeight: CGFloat {
        DetailAttachment.cellHeight
    }
    var fileToken: String? {
        switch source {
        case .rust(let attachment):
            return attachment.fileToken
        case .attachmentService(let info):
            return info.uploadInfo.fileToken
        }
    }
    var uploadTime: Int64 {
        switch source {
        case .rust(let attachment):
            return attachment.uploadMilliTime
        case .attachmentService(let info):
            return info.fileInfo.uploadTime
        }
    }
}

final class DetailAttachmentContentCell: UITableViewCell {

    var viewData: DetailAttachmentContentCellData? {
        didSet {
            guard let data = viewData else { return }
            coverView.image = data.coverImage
            nameLabel.text = data.nameText
            sizeLabel.text = data.sizeText
            deleteBtn.isHidden = !data.canDelete

            // 先重置状态
            progressView.isHidden = true
            retryBtn.isHidden = true
            containerView.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
            switch data.uploadState {
            case .idle:
                break
            case .inProgress(let progress):
                progressView.isHidden = false
                progressView.setProgress(progress, animated: true)
            case .failed:
                retryBtn.isHidden = false
                containerView.layer.ud.setBorderColor(UIColor.ud.functionDangerContentDefault)
            }
        }
    }

    weak var actionDelegate: DetailAttachmentContentCellDelegate?

    private lazy var containerView = initContainerView()

    private lazy var coverView = UIImageView()
    private lazy var nameLabel = initNameLabel()
    private lazy var sizeLabel = initSizeLabel()

    private lazy var stackView = initStackView()
    private lazy var retryBtn = initRetryBtn()
    private lazy var deleteBtn = initDeleteBtn()

    private lazy var progressView = UDProgressView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = UIColor.ud.bgBody
        selectionStyle = .none

        contentView.addSubview(containerView)
        containerView.snp.makeConstraints {
            $0.left.top.right.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-DetailAttachment.bottomSpace)
        }

        containerView.addSubview(coverView)
        coverView.snp.makeConstraints {
            $0.width.height.equalTo(36)
            $0.centerY.equalToSuperview()
            $0.left.equalToSuperview().offset(8)
        }

        containerView.addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.right.equalToSuperview().offset(-12)
            $0.centerY.equalToSuperview()
        }

        stackView.addArrangedSubview(retryBtn)
        retryBtn.snp.makeConstraints { $0.width.height.equalTo(36) }
        retryBtn.isHidden = true

        stackView.addArrangedSubview(deleteBtn)
        deleteBtn.snp.makeConstraints { $0.width.height.equalTo(36) }

        containerView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints {
            $0.top.equalTo(coverView)
            $0.left.equalTo(coverView.snp.right).offset(8)
            $0.right.equalTo(stackView.snp.left).offset(-8)
        }

        containerView.addSubview(sizeLabel)
        sizeLabel.snp.makeConstraints {
            $0.bottom.equalTo(coverView)
            $0.left.equalTo(coverView.snp.right).offset(8)
            $0.right.equalTo(stackView.snp.left).offset(-8)
        }

        containerView.addSubview(progressView)
        progressView.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-2)
        }
        progressView.isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        // UD Progress 组件必须上屏后设置才生效，已经反馈，先暂时这样解决
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if case .inProgress(let progress) = self.viewData?.uploadState {
                self.progressView.setProgress(progress, animated: false)
            }
        }
    }

    private func initContainerView() -> UIView {
        let view = UIView()
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 4
        view.layer.borderWidth = 1
        view.ud.setLayerBorderColor(UIColor.ud.lineBorderCard)
        let tap = UITapGestureRecognizer(target: self, action: #selector(onClick))
        view.addGestureRecognizer(tap)
        return view
    }

    private func initNameLabel() -> UILabel {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UDFont.systemFont(ofSize: 14)
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingMiddle
        return label
    }

    private func initSizeLabel() -> UILabel {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UDFont.systemFont(ofSize: 12)
        label.numberOfLines = 1
        return label
    }

    private func initStackView() -> UIStackView {
        var stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.spacing = 0
        return stackView
    }

    private func initRetryBtn() -> UIView {
        let containerView = UIView()
        let imageView = UIImageView()
        imageView.image = UDIcon.refreshOutlined
            .ud.resized(to: CGSize(width: 20, height: 20))
            .ud.withTintColor(UIColor.ud.iconN2)
        containerView.addSubview(imageView)
        imageView.snp.makeConstraints { $0.center.equalToSuperview() }
        let tap = UITapGestureRecognizer(target: self, action: #selector(onRetryBtnClick))
        containerView.addGestureRecognizer(tap)
        return containerView
    }

    private func initDeleteBtn() -> UIView {
        let containerView = UIView()
        let imageView = UIImageView()
        imageView.image = UDIcon.deleteTrashOutlined
            .ud.resized(to: CGSize(width: 20, height: 20))
            .ud.withTintColor(UIColor.ud.iconN2)
        containerView.addSubview(imageView)
        imageView.snp.makeConstraints { $0.center.equalToSuperview() }
        let tap = UITapGestureRecognizer(target: self, action: #selector(onDeleteBtnClick))
        containerView.addGestureRecognizer(tap)
        return containerView
    }

    @objc
    private func onClick() {
        actionDelegate?.onClick(self)
    }

    @objc
    private func onRetryBtnClick() {
        actionDelegate?.onRetryBtnClick(self)
    }

    @objc
    private func onDeleteBtnClick() {
        actionDelegate?.onDeleteBtnClick(self)
    }
}
