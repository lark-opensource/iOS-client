//
//  DetailSubTaskView.swift
//  Todo
//
//  Created by baiyantao on 2022/7/25.
//

import CTFoundation
import UIKit
import UniverseDesignIcon

final class DetailSubTaskView: BasicCellLikeView {

    var contentHeight = DetailSubTask.emptyViewHeight

    private(set) lazy var emptyView = getEmptyView()
    private(set) lazy var contentView = DetailSubTaskContentView()
    private(set) lazy var skeletonView = DetailSubTaskSkeletonView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        let followIcon = UDIcon.getIconByKey(
            .subtasksOutlined,
            renderingMode: .automatic,
            iconColor: nil,
            size: CGSize(width: 20, height: 20)
        )
        icon = .customImage(followIcon.ud.withTintColor(UIColor.ud.iconN3))
        iconAlignment = .centerVertically
        content = .customView(emptyView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: Self.noIntrinsicMetric, height: contentHeight)
    }

    private func getEmptyView() -> DetailEmptyView {
        let view = DetailEmptyView()
        view.text = I18N.Todo_AddASubTask_Placeholder
        return view
    }
}
