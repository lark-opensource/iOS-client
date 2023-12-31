//
//  DetailSubTaskFooterView.swift
//  Todo
//
//  Created by baiyantao on 2022/7/28.
//

import Foundation
import UIKit
import UniverseDesignIcon
import LarkActivityIndicatorView
import UniverseDesignFont

struct DetailSubTaskFooterViewData {
    var loadingState: LoadingState = .hide
    var isAddSubTaskHidden: Bool = false

    enum LoadingState {
        case hide
        case loading
        case showMore
        case failed
        case initFailed
    }
}

extension DetailSubTaskFooterViewData {
    var footerHeight: CGFloat {
        switch loadingState {
        case .hide:
            if isAddSubTaskHidden {
                return 0
            } else {
                return DetailSubTask.footerItemHeight + DetailSubTask.footerBottomOffset
            }
        case .loading, .showMore, .failed, .initFailed:
            var height = DetailSubTask.footerItemHeight
            if !isAddSubTaskHidden {
                height += DetailSubTask.footerItemHeight
            }
            height += DetailSubTask.footerBottomOffset
            return height
        }
    }
}

final class DetailSubTaskFooterView: UIView {

    var viewData: DetailSubTaskFooterViewData? {
        didSet {
            guard let viewData = viewData else { return }
            addSubTaskView.isHidden = viewData.isAddSubTaskHidden

            switch viewData.loadingState {
            case .hide:
                resetState()
            case .showMore:
                resetState()
                showMoreView.isHidden = false
            case .loading:
                resetState()
                loadingView.isHidden = false
                loadingView.loadingIndicator.startAnimating()
            case .failed, .initFailed:
                resetState()
                failedRetryView.isHidden = false
            }
        }
    }

    var showMoreClickHandler: (() -> Void)?
    var retryClickHandler: (() -> Void)?
    var addSubTaskClickHandler: (() -> Void)? {
        didSet {
            addSubTaskView.onTapAddHandler = addSubTaskClickHandler
        }
    }

    private lazy var stackView = getStackView()
    private lazy var showMoreView = getShowMoreView()
    private lazy var loadingView = LoadingView()
    private lazy var failedRetryView = getFailedRetryView()
    private lazy var addSubTaskView = getAddSubTaskView()

    init() {
        super.init(frame: .zero)

        addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        stackView.addArrangedSubview(showMoreView)
        showMoreView.snp.makeConstraints { $0.height.equalTo(36) }
        showMoreView.isHidden = true

        stackView.addArrangedSubview(loadingView)
        loadingView.snp.makeConstraints { $0.height.equalTo(36) }
        loadingView.isHidden = true

        stackView.addArrangedSubview(failedRetryView)
        failedRetryView.snp.makeConstraints { $0.height.equalTo(36) }
        failedRetryView.isHidden = true

        stackView.addArrangedSubview(addSubTaskView)
        addSubTaskView.snp.makeConstraints { $0.height.equalTo(36) }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func resetState() {
        showMoreView.isHidden = true
        loadingView.isHidden = true
        failedRetryView.isHidden = true
        loadingView.loadingIndicator.stopAnimating()
    }

    private func getStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 0
        return stackView
    }

    private func getShowMoreView() -> ShowMoreView {
        let view = ShowMoreView()
        let tap = UITapGestureRecognizer(target: self, action: #selector(onShowMoreClick))
        view.addGestureRecognizer(tap)
        return view
    }

    private func getFailedRetryView() -> FailedRetryView {
        let view = FailedRetryView()
        let tap = UITapGestureRecognizer(target: self, action: #selector(onRetryClick))
        view.addGestureRecognizer(tap)
        return view
    }

    private func getAddSubTaskView() -> DetailAddView {
        let view = DetailAddView()
        view.text = I18N.Todo_AddASubTask_Placeholder
        return view
    }

    @objc
    private func onShowMoreClick() {
        showMoreClickHandler?()
    }

    @objc
    private func onRetryClick() {
        retryClickHandler?()
    }
}

private final class ShowMoreView: UIView {

    private lazy var showMoreLabel = getShowMoreLabel()

    init() {
        super.init(frame: .zero)

        addSubview(showMoreLabel)
        showMoreLabel.snp.makeConstraints {
            $0.left.equalToSuperview().offset(28)
            $0.centerY.equalToSuperview()
            $0.right.lessThanOrEqualToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func getShowMoreLabel() -> UILabel {
        let label = UILabel()
        label.textColor = UIColor.ud.textLinkHover
        label.textAlignment = .left
        label.numberOfLines = 1
        label.font = UDFont.systemFont(ofSize: 14)
        label.text = I18N.Todo_MultipleSubTasks_ShowMore_Button
        return label
    }
}

private final class LoadingView: UIView {

    private(set) lazy var loadingIndicator = ActivityIndicatorView(color: UIColor.ud.primaryContentDefault)
    private lazy var loadingLabel = getLoadingLabel()

    init() {
        super.init(frame: .zero)

        addSubview(loadingIndicator)
        loadingIndicator.snp.makeConstraints {
            $0.left.equalToSuperview().offset(28)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(20)
        }
        addSubview(loadingLabel)
        loadingLabel.snp.makeConstraints {
            $0.left.equalTo(loadingIndicator.snp.right).offset(8)
            $0.centerY.equalTo(loadingIndicator)
            $0.right.lessThanOrEqualToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func getLoadingLabel() -> UILabel {
        let label = UILabel()
        label.textColor = UIColor.ud.textLinkHover
        label.textAlignment = .left
        label.numberOfLines = 1
        label.font = UDFont.systemFont(ofSize: 14)
        label.text = I18N.Lark_Legacy_LoadingNow
        return label
    }
}

private final class FailedRetryView: UIView {
    private lazy var failedLabel = getFailedLabel()
    private lazy var addLabel = getAddLabel()

    init() {
        super.init(frame: .zero)

        addSubview(failedLabel)
        failedLabel.snp.makeConstraints {
            $0.left.equalToSuperview().offset(28)
            $0.centerY.equalToSuperview()
        }
        addSubview(addLabel)
        addLabel.snp.makeConstraints {
            $0.left.equalTo(failedLabel.snp.right).offset(8)
            $0.centerY.equalTo(failedLabel)
            $0.right.lessThanOrEqualToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func getFailedLabel() -> UILabel {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.textAlignment = .left
        label.numberOfLines = 1
        label.font = UDFont.systemFont(ofSize: 14)
        label.text = I18N.Todo_LoadingFailedPleaseRetry_Text("")
        return label
    }

    private func getAddLabel() -> UILabel {
        let label = UILabel()
        label.textColor = UIColor.ud.textLinkHover
        label.textAlignment = .left
        label.numberOfLines = 1
        label.font = UDFont.systemFont(ofSize: 14)
        label.text = I18N.Todo_LoadingFailedPleaseRetry_Variable
        return label
    }
}

final class DetailAddView: UIView {

    var onTapAddHandler: (() -> Void)?

    var text: String? {
        didSet {
            addLabel.text = text
        }
    }

    private lazy var addIcon = getAddIcon()
    private(set) lazy var addLabel = getAddLabel()

    init() {
        super.init(frame: .zero)

        addSubview(addIcon)
        addIcon.snp.makeConstraints {
            $0.left.equalToSuperview()
            $0.centerY.equalToSuperview()
        }
        addSubview(addLabel)
        addLabel.snp.makeConstraints {
            $0.left.equalTo(addIcon.snp.right).offset(8)
            $0.centerY.equalTo(addIcon)
            $0.right.lessThanOrEqualToSuperview()
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTapClick))
        addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func getAddIcon() -> UIImageView {
        let view = UIImageView()
        view.image = UDIcon.addOutlined
            .ud.resized(to: CGSize(width: 16.0, height: 16.0))
            .ud.withTintColor(UIColor.ud.iconN3)
        return view
    }

    private func getAddLabel() -> UILabel {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.textAlignment = .left
        label.numberOfLines = 1
        label.font = UDFont.systemFont(ofSize: 14)
        return label
    }

    @objc
    private func onTapClick() {
        onTapAddHandler?()
    }
}
