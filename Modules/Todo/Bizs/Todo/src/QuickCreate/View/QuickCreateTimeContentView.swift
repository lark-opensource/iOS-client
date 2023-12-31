//
//  QuickCreateTimeContentView.swift
//  Todo
//
//  Created by wangwanxin on 2021/3/23.
//

import CTFoundation
import UniverseDesignIcon

/// Time Content

final class QuickCreateTimeContentView: UIView, ViewDataConvertible {

    var viewData: DetailDueTimeViewData? {
        didSet {
            guard let viewData = viewData, viewData.isVisible else {
                isHidden = true
                return
            }
            isHidden = false
            var newData = viewData
            // 给一个大的宽度，这样一定在单行中显示
            newData.preferMaxLayoutWidth = CGFloat.greatestFiniteMagnitude
            contentView.viewData = newData
            invalidateIntrinsicContentSize()
        }
    }

    private lazy var contentView = DueTimeContentView()
    var onCloseTap: (() -> Void)? {
        didSet {
            contentView.clearButtonHandler = onCloseTap
        }
    }
    var onContentTap: (() -> Void)? {
        didSet {
            contentView.clickHandler = onContentTap
        }
    }

    override init(frame: CGRect) {
        super.init(frame: .zero)
        addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentView.containerView.backgroundColor = UIColor.ud.bgBodyOverlay
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        guard let viewData = viewData, viewData.isVisible else { return .zero }
        return contentView.singleLineSize
    }

}
