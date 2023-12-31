//
//  SettingBaseHeaderView.swift
//  ByteViewSetting
//
//  Created by liurundong.henry on 2023/10/27.
//

import Foundation

/// 所有SettingHeader的基类
class SettingBaseHeaderView: UITableViewHeaderFooterView {
    private enum Layout {
        static let saperatorLeftSpacing: CGFloat = 16.0
        static let saperatorHeight: CGFloat = 0.5
    }

    private(set) var header: SettingDisplayHeader?
    private(set) var contentInsets: UIEdgeInsets = .zero

    var isShowSeparator: Bool = false {
        didSet {
            separatorView.isHidden = !isShowSeparator
        }
    }

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

    func config(for header: SettingDisplayHeader, maxLayoutWidth: CGFloat, contentInsets: UIEdgeInsets, showSaperator: Bool = false) {
        self.header = header
        self.contentInsets = contentInsets
        self.separatorView.isHidden = !showSaperator
    }
}
