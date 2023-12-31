//
//  ThreadTypeFilterViewController.swift
//  LarkSearch
//
//  Created by lixiaorui on 2020/2/29.
//

import Foundation
import UIKit
import LarkUIKit
import LarkModel
import LarkSearchFilter
import LarkSDKInterface

final class ThreadTypeFilterViewController: BaseUIViewController, PresentWithFadeAnimatorVC, UIViewControllerTransitioningDelegate {

    var threadTypeHandler: ((ThreadFilterType, UIViewController) -> Void)?
    private var selectedType: ThreadFilterType
    private lazy var typeButtons: [ThreadTypeButton] = {
        var btns: [ThreadTypeButton] = []
        ThreadFilterType.allCases.forEach { (type) in
            let btn = ThreadTypeButton(type: type)
            btn.selectHandler = { type in
                self.selectTypeChanged(type)
            }
            btns.append(btn)
        }
        return btns
    }()

    let colorBgView = UIView()
    let contentView = UIView()

    init(selectedType: ThreadFilterType) {
        self.selectedType = selectedType
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // 此处样式，复用原群组类型选择器ChatTypeFilterViewController
        view.backgroundColor = UIColor.clear

        colorBgView.backgroundColor = UIColor.ud.bgMask
        view.addSubview(colorBgView)
        colorBgView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        view.addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        let groupView = UIView()
        groupView.backgroundColor = UIColor.ud.bgFloat
        contentView.addSubview(groupView)
        groupView.roundCorners(corners: [.topLeft, .topRight], radius: 10.0)
        groupView.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview()
            make.top.equalToSuperview().inset(222.5)
            make.width.equalToSuperview()
        }

        let closeBtn = ExpandRangeButton()
        closeBtn.addTarget(self, action: #selector(closeButtonDidClick), for: .touchUpInside)
        closeBtn.setImage(Resources.thread_type_close.withRenderingMode(.alwaysTemplate), for: .normal)
        closeBtn.tintColor = UIColor.ud.iconN3
        closeBtn.addedTouchArea = 20.0
        groupView.addSubview(closeBtn)
        closeBtn.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(22.0)
            make.left.equalToSuperview().offset(16.0)
        }

        let titleLabel = UILabel()
        titleLabel.text = BundleI18n.LarkSearch.Lark_Search_SearchChannelsByChannelType
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.font = UIFont.systemFont(ofSize: 16.0)
        groupView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(closeBtn.snp.centerY)
            make.centerX.equalToSuperview()
        }

        let stackView = UIStackView()
        stackView.backgroundColor = UIColor.ud.bgFloatOverlay
        stackView.axis = .vertical
        typeButtons.forEach {
            stackView.addArrangedSubview($0)
            $0.isSelected = $0.type == selectedType
        }
        groupView.addSubview(stackView)
        stackView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().inset(64.0)
        }
        stackView.lu.addTopBorder(leading: 0.0, trailing: 0.0, color: UIColor.ud.lineDividerDefault)
    }

    private func selectTypeChanged(_ selected: ThreadFilterType) {
        selectedType = selected
        typeButtons.forEach {
            $0.isSelected = $0.type == selected
        }
        threadTypeHandler?(selectedType, self)
    }

    @objc
    private func closeButtonDidClick() {
        threadTypeHandler?(selectedType, self)
    }

    // MARK: - UIViewControllerTransitioningDelegate
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PresentWithFadeAnimator()
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DismissWithFadeAnimator()
    }
}

private final class ThreadTypeButton: UIControl {
    var selectHandler: ((ThreadFilterType) -> Void)?
    let type: ThreadFilterType
    private let imageView = UIImageView()
    private let title = UILabel()
    override var isSelected: Bool {
        didSet {
            guard isSelected != oldValue else { return }
            imageView.image = isSelected ? Resources.thread_type_selected : Resources.thread_type_noSelected
        }
    }

    init(type: ThreadFilterType) {
        self.type = type
        super.init(frame: .zero)
        self.isSelected = false
        imageView.image = Resources.thread_type_noSelected

        title.text = type.title
        title.font = UIFont.systemFont(ofSize: 16.0)
        title.textColor = UIColor.ud.textTitle

        addSubview(imageView)
        addSubview(title)

        imageView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 18.0, height: 18.0))
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(16.0)
        }

        title.snp.makeConstraints { (make) in
            make.leading.equalTo(imageView.snp.trailing).offset(12.0)
            make.centerY.equalToSuperview()
        }

        lu.addBottomBorder(leading: 16.0, color: UIColor.ud.lineDividerDefault)

        addTarget(self, action: #selector(didClick), for: .touchUpInside)

        snp.makeConstraints { (make) in
            make.height.equalTo(62)
        }

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func didClick() {
        guard !isSelected else { return }
        isSelected = !isSelected
        selectHandler?(type)
    }
}
