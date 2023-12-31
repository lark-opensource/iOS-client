//
//  PickerSearchNavigationBar.swift
//  LarkSearchCore
//
//  Created by Yuri on 2023/4/6.
//

import UIKit
import SnapKit
import UniverseDesignColor
import UniverseDesignButton

public class PickerSearchBar: UIView {
    var didCancelHandler: (() -> Void)?

    private let contentView = UIStackView()
    private var searchBar: UIView
    private let context: PickerContext
    init(context: PickerContext, searchBar: UIView) {
        self.context = context
        self.searchBar = searchBar
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.axis = .horizontal
        contentView.spacing = 12
        addSubview(contentView)
        contentView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.trailing.equalToSuperview().inset(12)
            $0.bottom.equalToSuperview()
            $0.height.equalTo(52)
        }
        contentView.addArrangedSubview(searchBar)

        if context.style == .picker { return }
        guard context.featureConfig.searchBar.hasCancelBtn else { return }

        let title = BundleI18n.LarkSearchCore.Lark_Legacy_Cancel
        let font = UIFont.systemFont(ofSize: 16)
        let size = title.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 20), options: .usesLineFragmentOrigin, context: nil)
        let cancelBtn = UIButton()
        cancelBtn.setTitle(title, for: .normal)
        cancelBtn.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        cancelBtn.titleLabel?.font = font
        cancelBtn.addTarget(self, action: #selector(onClickCancel), for: .touchUpInside)
        cancelBtn.snp.makeConstraints {
            $0.width.equalTo(size.width + 24)
            $0.height.equalTo(52)
        }
        contentView.addArrangedSubview(cancelBtn)
    }

    @objc
    func onClickCancel() {
        didCancelHandler?()
    }
    @objc
    func injected() {
        subviews.forEach { $0.removeFromSuperview() }
        setupUI()
    }
}
