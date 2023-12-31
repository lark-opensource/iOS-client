//
//  DetailAttachmentView.swift
//  Todo
//
//  Created by baiyantao on 2022/12/21.
//

import CTFoundation
import UniverseDesignIcon

final class DetailAttachmentView: BasicCellLikeView {

    var contentHeight = DetailAttachment.emptyViewHeight

    private(set) lazy var emptyView = initEmptyView()
    private(set) lazy var contentView = DetailAttachmentContentView(
        edgeInsets: .init(top: 0, left: 0, bottom: 0, right: 16)
    )

    init() {
        super.init(frame: .zero)
        let attach = UDIcon.getIconByKey(
            .attachmentOutlined,
            renderingMode: .automatic,
            iconColor: nil,
            size: CGSize(width: 20, height: 20)
        )
        iconAlignment = .centerVertically
        content = .customView(emptyView)
        icon = .customImage(attach.ud.withTintColor(UIColor.ud.iconN3))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: Self.noIntrinsicMetric, height: contentHeight)
    }

    private func initEmptyView() -> DetailEmptyView {
        let view = DetailEmptyView()
        view.text = I18N.Todo_Task_AddAttachment
        return view
    }
}
