//
//  DetailCustomFieldsFooterView.swift
//  Todo
//
//  Created by baiyantao on 2023/4/18.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignFont

struct DetailCustomFieldsFooterViewData {
    var state: HasMoreState = .noMore

    enum HasMoreState {
        case hasMore
        case noMore
    }

    var footerHeight: CGFloat {
        switch state {
        case .hasMore:
            return 42
        case .noMore:
            return 18
        }
    }
}

final class DetailCustomFieldsFooterView: UIView {

    var viewData: DetailCustomFieldsFooterViewData? {
        didSet {
            guard let data = viewData else { return }
            if case .hasMore = data.state {
                buttonContainerView.isHidden = false
                leftDividingLine.isHidden = false
                rightDividingLine.isHidden = false
            } else {
                buttonContainerView.isHidden = true
                leftDividingLine.isHidden = true
                rightDividingLine.isHidden = true
            }
        }
    }

    var clickHandler: (() -> Void)?

    private lazy var buttonContainerView = initButtonContainerView()
    private lazy var buttonTitle = initButtonTitle()
    private lazy var buttonIcon = initButtonIcon()
    private lazy var leftDividingLine = initDividingLine()
    private lazy var rightDividingLine = initDividingLine()

    init() {
        super.init(frame: .zero)

        addSubview(buttonContainerView)
        buttonContainerView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-6)
        }
        buttonContainerView.addSubview(buttonTitle)
        buttonTitle.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.left.equalToSuperview()
        }

        buttonContainerView.addSubview(buttonIcon)
        buttonIcon.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.left.equalTo(buttonTitle.snp.right).offset(4)
            $0.right.equalToSuperview()
            $0.width.height.equalTo(14)
        }

        addSubview(leftDividingLine)
        leftDividingLine.snp.makeConstraints {
            $0.height.equalTo(0.5)
            $0.left.equalToSuperview()
            $0.right.equalTo(buttonContainerView.snp.left).offset(-8)
            $0.centerY.equalTo(buttonContainerView.snp.centerY)
        }
        addSubview(rightDividingLine)
        rightDividingLine.snp.makeConstraints {
            $0.height.equalTo(0.5)
            $0.left.equalTo(buttonContainerView.snp.right).offset(8)
            $0.right.equalToSuperview()
            $0.centerY.equalTo(buttonContainerView.snp.centerY)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initButtonContainerView() -> UIView {
        let view = UIView()
        let tap = UITapGestureRecognizer(target: self, action: #selector(onClick))
        view.addGestureRecognizer(tap)
        return view
    }

    private func initButtonTitle() -> UILabel {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UDFont.systemFont(ofSize: 14)
        label.text = I18N.Todo_TaskList_ListField_ViewMore_Button
        return label
    }

    private func initButtonIcon() -> UIView {
        let imageView = UIImageView()
        imageView.image = UDIcon.downOutlined.ud.withTintColor(UIColor.ud.iconN2)
        return imageView
    }

    private func initDividingLine() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }

    @objc
    private func onClick() {
        clickHandler?()
    }
}
