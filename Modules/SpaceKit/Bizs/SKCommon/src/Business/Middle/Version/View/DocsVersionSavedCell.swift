//
//  DocsVersionSavedCell.swift
//  SKBrowser
//
//  Created by GuoXinyi on 2022/9/4.
//

import Foundation
import UIKit
import SKUIKit
import SnapKit
import UniverseDesignColor
import UniverseDesignIcon
import SKFoundation
import SKResource

public protocol DocsVersionSavedCellDelegate: AnyObject {
    func didClickCell(cell: UITableViewCell)
}

protocol DocsVersionSavedCellPresenter {
    var mainTitle: String { get }
    var subTitle: String { get }
}

public final class DocsVersionSavedCell: UITableViewCell {
    
    private(set) lazy var seperatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()

    private lazy var label = UILabel().construct { it in
        it.font = .systemFont(ofSize: 16)
        it.textColor = UIColor.ud.N900
    }

    private lazy var sublabel = UILabel().construct { it in
        it.font = .systemFont(ofSize: 14)
        it.textColor = UDColor.textPlaceholder
    }
    
    private lazy var selectIcon = UIImageView().construct { it in
        it.image = UDIcon.listCheckBoldOutlined.ud.withTintColor(UIColor.ud.textLinkHover)
    }

    public weak var delegate: DocsVersionSavedCellDelegate?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        backgroundColor = .clear

        contentView.addSubview(seperatorView)
        contentView.addSubview(label)
        contentView.addSubview(sublabel)
        contentView.addSubview(selectIcon)
        
        seperatorView.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.bottom.right.equalToSuperview()
            make.height.equalTo(0.5)
        }

        label.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-30)
            make.height.equalTo(20)
        }

        sublabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-30)
            make.top.equalTo(label).offset(27)
            make.height.equalTo(14)
        }
        
        selectIcon.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-12)
            make.width.equalTo(15)
            make.height.equalTo(17)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func renderCell(presenter: DocsVersionSavedCellPresenter) {
        label.text = presenter.mainTitle
        sublabel.text = presenter.subTitle
    }
    
    public func updateSelect(_ select: Bool) {
        selectIcon.isHidden = !select
    }
    
    /// 计算高度
    static func calculateCellHeight() -> CGFloat {
        return 69.5
    }
    
    @objc
    private func didClickDelete() {
        delegate?.didClickCell(cell: self)
    }
    
}
