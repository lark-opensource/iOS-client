//
//  SettingBaseFooterView.swift
//  ByteViewSetting
//
//  Created by liurundong.henry on 2023/10/30.
//

import Foundation

class SettingBaseFooterView: UITableViewHeaderFooterView {
    private enum Layout {
        static let saperatorLeftSpacing: CGFloat = 16.0
        static let saperatorHeight: CGFloat = 0.5
    }

    private(set) var footer: SettingDisplayFooter?

    private lazy var separatorView = {
        let view = UIView()
        view.backgroundColor = .ud.lineDividerDefault
        view.isHidden = true
        return view
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        addSubview(separatorView)
        separatorView.snp.makeConstraints {
            $0.left.equalToSuperview().inset(Layout.saperatorLeftSpacing)
            $0.top.right.equalToSuperview()
            $0.height.equalTo(Layout.saperatorHeight)
        }
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// override point for subclass. Do not call directly.
    func setupViews() { }

    func config(for footer: SettingDisplayFooter, maxLayoutWidth: CGFloat, showSaperator: Bool = false) {
        self.footer = footer
        self.separatorView.isHidden = !showSaperator
    }
}
