//
//  SpaceSubListHeaderView.swift
//  SKECM
//
//  Created by Weston Wu on 2021/2/4.
//

import UIKit
import UniverseDesignColor
import SnapKit
import SKResource
import SKCommon
import RxSwift
import RxRelay
import RxCocoa
import UniverseDesignIcon

class SpaceSubListHeaderLeftView: UIControl {

    private(set) lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.ud.N600
        return label
    }()
    private lazy var arrowView: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.downBoldOutlined.withRenderingMode(.alwaysTemplate)
        view.tintColor = UIColor.ud.N600
        view.contentMode = .scaleAspectFit
        return view
    }()

    private var titleArrowConstraint: Constraint?

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(arrowView)
        arrowView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 12, height: 12))
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(6)
        }

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            titleArrowConstraint = make.right.equalTo(arrowView.snp.left).offset(-6).constraint
            make.right.lessThanOrEqualToSuperview()
        }
        updateArrowView(isHidden: true)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateArrowView(isHidden: Bool) {
        arrowView.isHidden = isHidden
        if isHidden {
            titleArrowConstraint?.deactivate()
        } else {
            titleArrowConstraint?.activate()
        }
    }
}


class SpaceSubListHeaderView: UICollectionReusableView {

    static let height: CGFloat = 44
    private var reuseBag = DisposeBag()

    private(set) lazy var toolBar: SpaceListToolBar = {
        let toolBar = SpaceListToolBar()
        return toolBar
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = UDColor.textTitle
        return label
    }()
    private lazy var leftView: SpaceSubListHeaderLeftView = {
        let label = SpaceSubListHeaderLeftView()
        return label
    }()

    private lazy var bottomSeperator: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()

    private var disposeBag = DisposeBag()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = UDColor.bgBody

//        addSubview(bottomSeperator)
//        bottomSeperator.snp.makeConstraints { make in
//            make.bottom.left.right.equalToSuperview()
//            make.height.equalTo(0.5)
//        }

        addSubview(toolBar)
        toolBar.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.right.equalToSuperview()
        }

        addSubview(leftView)
        leftView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.right.lessThanOrEqualTo(toolBar.snp.left).offset(-8)
//            make.right.equalTo(toolBar.snp.left).offset(-16)
        }

        toolBar.setContentHuggingPriority(.required, for: .horizontal)
        leftView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        leftView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        toolBar.setContentCompressionResistancePriority(.required, for: .horizontal)

        toolBar.layoutAnimationSignal
            .emit(onNext: { [weak self] in
                guard let self = self else { return }
                UIView.animate(withDuration: 0.3) {
                    self.layoutIfNeeded()
                }
            })
            .disposed(by: disposeBag)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        reuseBag = DisposeBag()
        toolBar.reset()
    }

    func update(title: String, tools: [SpaceListTool]) {
        leftView.updateArrowView(isHidden: true)
        leftView.titleLabel.text = title

        let tool = tools.first { tool -> Bool in
            if case .sort = tool { return true }
            return false
        }
        if let tool = tool {
            leftView.updateArrowView(isHidden: false)
            setup(tool: tool)
        }

        toolBar.update(tools: tools)
    }

    private func setup(tool: SpaceListTool) {
        if case let .sort(_, titleRelay, isEnabled, clickHandler) = tool {
            titleRelay.asDriver()
                .drive(onNext: { [weak leftView] name in
                    guard let leftView = leftView else { return }
                    leftView.titleLabel.text = name
                })
                .disposed(by: reuseBag)

            isEnabled.asDriver(onErrorJustReturn: false)
                .drive(onNext: { [weak leftView] isEnabled in
                    guard let leftView = leftView else { return }
                    leftView.updateArrowView(isHidden: !isEnabled)
                    leftView.isEnabled = isEnabled
                })
                .disposed(by: reuseBag)

            leftView.rx.controlEvent(.touchUpInside)
                .subscribe(onNext: { [weak leftView] _ in
                    guard let view = leftView else { return }
                    clickHandler(view)
                })
                .disposed(by: reuseBag)
        }
    }
}
