//
//  DetailAttachmentFooterView.swift
//  Todo
//
//  Created by baiyantao on 2022/12/21.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignFont

struct DetailAttachmentFooterViewData {
    var hasMoreState: HasMoreState = .noMore
    var isAddViewHidden: Bool = false

    enum HasMoreState {
        case hasMore(moreCount: Int)
        case noMore
    }
}

extension DetailAttachmentFooterViewData {
    var footerHeight: CGFloat {
        switch hasMoreState {
        case .hasMore:
            var height = DetailAttachment.footerItemHeight
            if !isAddViewHidden {
                height += DetailAttachment.footerItemHeight
            }
            height += DetailAttachment.footerBottomOffset
            return height
        case .noMore:
            if isAddViewHidden {
                return 0
            } else {
                return DetailAttachment.footerItemHeight + DetailAttachment.footerBottomOffset
            }
        }
    }
}

final class DetailAttachmentFooterView: UIView {

    var viewData: DetailAttachmentFooterViewData? {
        didSet {
            guard let data = viewData else { return }
            switch data.hasMoreState {
            case .hasMore(let moreCount):
                expandMoreView.isHidden = false
                expandMoreView.update(moreCount: moreCount)
            case .noMore:
                expandMoreView.isHidden = true
            }

            addAttachmentView.isHidden = data.isAddViewHidden
        }
    }

    var expandMoreClickHandler: (() -> Void)?
    var addAttachmentClickHandler: ((UIView) -> Void)?

    private lazy var stackView = initStackView()
    private lazy var expandMoreView = initExpandMoreView()
    private lazy var addAttachmentView = initAddAttachmentView()

    init() {
        super.init(frame: .zero)
        backgroundColor = UIColor.ud.bgBody

        let containerView = UIView()
        addSubview(containerView)
        containerView.snp.makeConstraints {
            $0.top.left.right.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-DetailAttachment.footerBottomOffset)
        }

        containerView.addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        stackView.addArrangedSubview(expandMoreView)
        expandMoreView.snp.makeConstraints { $0.height.equalTo(DetailAttachment.footerItemHeight) }

        stackView.addArrangedSubview(addAttachmentView)
        addAttachmentView.snp.makeConstraints { $0.height.equalTo(DetailAttachment.footerItemHeight) }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 4
        return stackView
    }

    private func initExpandMoreView() -> ExpandMoreView {
        let view = ExpandMoreView()
        let tap = UITapGestureRecognizer(target: self, action: #selector(onExpandMoreClick))
        view.addGestureRecognizer(tap)
        return view
    }

    private func initAddAttachmentView() -> DetailAddView {
        let view = DetailAddView()
        view.text = I18N.Todo_Task_AddAttachment
        view.onTapAddHandler = { [weak self] in
            self?.onAddAttachmentClick()
        }
        return view
    }

    @objc
    private func onExpandMoreClick() {
        expandMoreClickHandler?()
    }

    private func onAddAttachmentClick() {
        addAttachmentClickHandler?(addAttachmentView.addLabel)
    }
}

private final class ExpandMoreView: UIView {
    private lazy var titleLabel = initTitleLabel()

    init() {
        super.init(frame: .zero)

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(moreCount: Int) {
        titleLabel.text = I18N.Todo_ViewMoreAttachments_Button(moreCount)
    }

    private func initTitleLabel() -> UILabel {
        let label = UILabel()
        label.textColor = UIColor.ud.bgPricolor
        label.font = UDFont.systemFont(ofSize: 14)
        label.numberOfLines = 1
        return label
    }
}
