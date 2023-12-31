//
//  SettingHeaderView.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/2/28.
//

import Foundation
import ByteViewCommon

/// - heade/footerr: H:|-(16)-[titleLabel]-(0)-|
/// - header: V:|-(4)-[titleLabel]-(4)-|
/// - footer: V:|-(4)-[titleLabel]-(12)-|
final class SettingHeaderFooterView: UITableViewHeaderFooterView {
    var isShowSeparator: Bool = false {
        didSet {
            separatorView.isHidden = !isShowSeparator
        }
    }
    private(set) var contentInsets: UIEdgeInsets = .zero
    fileprivate let titleLabel = UILabel()
    private lazy var separatorView = {
        let view = UIView()
        view.backgroundColor = .ud.lineDividerDefault
        view.isHidden = true
        return view
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        addSubview(titleLabel)
        addSubview(separatorView)
        titleLabel.numberOfLines = 0
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(contentInsets.top)
            make.bottom.equalToSuperview().offset(-contentInsets.bottom)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview()
        }
        separatorView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.top.right.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateContentInsets(_ contentInsets: UIEdgeInsets) {
        if contentInsets == self.contentInsets { return }
        self.contentInsets = contentInsets
        titleLabel.snp.updateConstraints { make in
            make.top.equalToSuperview().offset(contentInsets.top)
            make.bottom.equalToSuperview().offset(-contentInsets.bottom)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview()
        }
    }

    func config(_ model: SettingDisplayHeaderFooter) {
        titleLabel.attributedText = NSAttributedString(string: model.title, config: model.textStyle, textColor: model.style.color)
    }
}
