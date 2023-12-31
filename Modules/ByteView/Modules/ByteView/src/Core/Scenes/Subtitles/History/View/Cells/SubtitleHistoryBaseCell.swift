//
//  SubtitleHistoryBaseCell.swift
//  ByteView
//
//  Created by kiri on 2020/6/11.
//

import UIKit
import RxSwift
import ByteViewUI

class SubtitleHistoryBaseCell: UITableViewCell {

    var containerWidth: CGFloat = 0

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = UIColor.ud.textCaption
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .vertical)
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 1
        return label
    }()

    lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = UIColor.ud.textCaption
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .vertical)
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 1
        return label
    }()

    lazy var avatarImageView: AvatarView = {
        let avatarImageView = AvatarView()
        avatarImageView.layer.masksToBounds = true
        avatarImageView.layer.cornerRadius = 14
        avatarImageView.contentMode = .scaleAspectFill
        return avatarImageView
    }()

    var viewModel: SubtitleViewData?
    var service: MeetingBasicService?

    var shouldShowMenu: Bool = false
    var menuAnchorView: UIView? {
        didSet {
            shouldShowMenu = true
        }
    }

    var cellHeight: CGFloat = 0

    private(set) var disposeBag = DisposeBag()

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
    }

    open func setup() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(avatarImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(timeLabel)

        avatarImageView.snp.makeConstraints { (maker) in
            maker.width.height.equalTo(28)
            maker.left.equalToSuperview().inset(16)
            maker.top.equalToSuperview().offset(8)
        }

        titleLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(avatarImageView)
            maker.left.equalTo(avatarImageView.snp.right).offset(8)
            maker.right.equalTo(timeLabel.snp.left).offset(-4)
            maker.height.equalTo(18)
        }
        timeLabel.snp.makeConstraints { (maker) in
            maker.centerY.equalTo(titleLabel)
            maker.left.equalTo(titleLabel.snp.right).offset(4)
            maker.right.lessThanOrEqualToSuperview().offset(-19)
            maker.height.equalTo(18)
        }
    }

    open func updateViewModel(vm: SubtitleViewData) -> CGFloat {
        self.viewModel = vm
        guard let viewModel = self.viewModel else {
            return 0
        }

        avatarImageView.setTinyAvatar(viewModel.avatarInfo)
        titleLabel.text = viewModel.name
        timeLabel.text = viewModel.realTime
        disposeBag = DisposeBag()
        viewModel.nameRelay
            .skip(1)
            .distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.titleLabel.text = $0
            }).disposed(by: disposeBag)
        return 32 + 16
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        timeLabel.text = nil
        disposeBag = DisposeBag()
    }

    override var canBecomeFirstResponder: Bool {
        return self.shouldShowMenu
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return action == #selector(copy(_:))
    }

    open func showMenu() {
        if let anchor = self.menuAnchorView {
            self.becomeFirstResponder()
            let menu = UIMenuController.shared
            if #available(iOS 13.0, *) {
                menu.showMenu(from: anchor, rect: anchor.bounds)
            } else {
                menu.setTargetRect(anchor.bounds, in: anchor)
                menu.setMenuVisible(true, animated: true)
            }
        }
    }

    open func hideMenu() {
        if self.menuAnchorView != nil {
            let menu = UIMenuController.shared
            if menu.isMenuVisible {
                if #available(iOS 13.0, *) {
                    menu.hideMenu()
                } else {
                    menu.setMenuVisible(false, animated: true)
                }
            }
        }
    }
}
