//
//  DetailAttachmentHeaderView.swift
//  Todo
//
//  Created by baiyantao on 2023/1/2.
//

import Foundation
import UniverseDesignFont

struct DetailAttachmentHeaderViewData {
    var attachmentCount: Int = 0
    var fileSizeText: String = ""
}

extension DetailAttachmentHeaderViewData {
    var headerHeight: CGFloat {
        return DetailAttachment.headerHeight
    }
}

final class DetailAttachmentHeaderView: UIView {

    var viewData: DetailAttachmentHeaderViewData? {
        didSet {
            guard let data = viewData else { return }
            titleLabel.text = I18N.Todo_TaskAttachment_Text(data.attachmentCount, data.fileSizeText)
        }
    }

    private lazy var titleLabel = initTitleLabel()

    init() {
        super.init(frame: .zero)
        backgroundColor = UIColor.ud.bgBody

        let containerView = UIView()
        addSubview(containerView)
        containerView.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.top.equalToSuperview().offset(6)
            $0.bottom.equalToSuperview().offset(-4)
        }

        containerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.left.right.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initTitleLabel() -> UILabel {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.font = UDFont.systemFont(ofSize: 14)
        return label
    }

}
