//
//  DockCell.swift
//  AnimatedTabBar
//
//  Created by Hayden on 2021/5/28.
//

import Foundation
import UIKit
import Kingfisher
import ByteWebImage
import UniverseDesignIcon

protocol DockCellDelegate: AnyObject {
    func didSelectDockCell(_ cell: DockCell)
    func didDeleteDockCell(_ cell: DockCell)
}

protocol DockCell: UITableViewCell {

    static var reuseIdentifier: String { get }
    static var cellHeight: CGFloat { get }
    var delegate: DockCellDelegate? { get set }
    var suspendItem: SuspendPatch? { get set }
    func configure(item: SuspendPatch)
}

class BaseDockCell: UITableViewCell, DockCell {

    class var cellHeight: CGFloat {
        Cons.avatarSize + Cons.vMargin * 2
    }

    static var reuseIdentifier: String {
        String(describing: Self.self)
    }

    weak var delegate: DockCellDelegate?

    var iconSize: CGFloat { Cons.iconSize }
    var iconCornerRadius: CGFloat { 0 }

    private lazy var container: UIView = {
        let view = UIView()
        view.backgroundColor = Cons.itemColor
        view.layer.cornerRadius = Cons.cornerRadius
        if #available(iOS 13.0, *) {
            view.layer.cornerCurve = .continuous
        }
        return view
    }()

    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = Cons.textFont
        label.textColor = Cons.textColor
        return label
    }()

    private lazy var closeIcon: UIImageView = {
        return UIImageView(image: UDIcon.getIconByKey(
                            .closeOutlined,
                            iconColor: UIColor.ud.iconN3,
                            size: CGSize(width: 12, height: 12)))
    }()

    lazy var deleteButton: UIButton = {
        let button = UIButton()
        button.addSubview(closeIcon)
        closeIcon.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(Cons.closeBtnSize)
            make.leading.equalToSuperview().offset(Cons.hSpacing)
        }
        return button
    }()

    var suspendItem: SuspendPatch?

    func configure(item: SuspendPatch) {
        suspendItem = item
        titleLabel.text = item.title
        if let iconKey = item.iconKey {
            iconView.bt.setLarkImage(
                with: .avatar(key: iconKey, entityID: item.iconEntityID ?? ""),
                trackStart: {
                    return TrackInfo(scene: .Chat, fromType: .avatar)
                }
            )
        } else if let iconURL = item.iconURL, let url = URL(string: iconURL) {
            iconView.bt.setImage(url)
        } else {
            iconView.image = item.displayIcon
        }
    }

    private func setupSubviews() {
        contentView.addSubview(container)
        container.addSubview(iconView)
        container.addSubview(titleLabel)
        container.addSubview(deleteButton)
    }

    private func setupConstraints() {
        container.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Cons.vPadding)
            make.bottom.equalToSuperview().offset(-Cons.vPadding)
            make.leading.equalToSuperview().offset(Cons.hPadding)
            make.trailing.equalToSuperview().offset(-Cons.hPadding)
        }
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(iconSize)
            make.leading.equalToSuperview().offset(Cons.hMargin)
            make.centerY.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(iconView.snp.trailing).offset(Cons.hSpacing)
            make.trailing.equalTo(deleteButton.snp.leading)
        }
        deleteButton.snp.makeConstraints { make in
            make.width.equalTo(Cons.closeBtnSize * 2 + Cons.hSpacing)
            make.top.bottom.trailing.equalToSuperview()
        }
    }

    private func setupAppearance() {
        backgroundColor = .clear
        layer.masksToBounds = true
        layer.cornerRadius = Cons.cornerRadius
        selectionStyle = .none
        if iconCornerRadius != 0 {
            iconView.layer.masksToBounds = true
            iconView.layer.cornerRadius = iconCornerRadius
        }

        deleteButton.addTarget(self, action: #selector(didDeleteItem(_:)), for: .touchUpInside)
        container.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didSelectItem)))
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        deleteButton.tag = tag
        setupSubviews()
        setupConstraints()
        setupAppearance()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    @objc
    private func didSelectItem() {
        delegate?.didSelectDockCell(self)
    }

    @objc
    private func didDeleteItem(_ sender: UIButton) {
        delegate?.didDeleteDockCell(self)
    }
}

final class ChatDockCell: BaseDockCell {

    class override var cellHeight: CGFloat {
        Cons.avatarSize + Cons.vMargin * 2
    }
    override var iconSize: CGFloat { Cons.avatarSize }
    override var iconCornerRadius: CGFloat { Cons.avatarSize / 2 }
}

private enum Cons {
    static var cornerRadius: CGFloat { 10 }
    static var iconSize: CGFloat { 24.auto() }
    static var avatarSize: CGFloat { 40.auto() }
    static var closeBtnSize: CGFloat { 12.auto() }
    static var hPadding: CGFloat { 16 }
    static var vPadding: CGFloat { 4 }
    static var hMargin: CGFloat { 12 }
    static var vMargin: CGFloat { 12 }
    static var hSpacing: CGFloat { 8 }
    static var textFont: UIFont { UIFont.ud.body0 }
    static var textColor: UIColor { UIColor.ud.textTitle }
    static var itemColor: UIColor { UIColor.ud.bgFloat }
}
