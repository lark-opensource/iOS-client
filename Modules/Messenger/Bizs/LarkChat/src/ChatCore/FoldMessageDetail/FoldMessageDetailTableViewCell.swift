//
//  FoldMessageDetailTableViewCell.swift
//  LarkChat
//
//  Created by liluobin on 2022/9/19.
//

import Foundation
import UIKit
import LKRichView
import LarkBizAvatar

final class FoldMessageDetailTableViewCell: UITableViewCell {

    private var cellWidth: CGFloat?
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    var tapAvatarBlock: ((String) -> Void)?

    var viewModel: FoldMessageDetailCellViewModel? {
        didSet {
            updateUI()
        }
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        if let cellWidth = cellWidth, cellWidth != self.frame.size.width {
            updateUI()
        }
    }

    lazy var core = LKRichViewCore()
    lazy var richContainerView: LKRichContainerView = {
        let richContainerView = LKRichContainerView(frame: .zero)
        richContainerView.richView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        richContainerView.backgroundColor = .clear
        return richContainerView
    }()

    lazy var avatarView: BizAvatar = {
        let view = BizAvatar()
        view.lu.addTapGestureRecognizer(action: #selector(avatarViewTapped), target: self)
        return view
    }()

    /// 通知不限制标题行数
    public lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textPlaceholder
        label.backgroundColor = UIColor.clear
        label.numberOfLines = 1
        return label
    }()

    public lazy var countLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.colorfulOrange
        label.font = UIFont(name: "DINAlternate-Bold", size: 14) ?? .systemFont(ofSize: 14, weight: .bold)
        label.backgroundColor = UIColor.clear
        label.numberOfLines = 1
        return label
    }()

    public lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        self.contentView.backgroundColor = UIColor.ud.bgBody
        self.contentView.addSubview(nameLabel)
        self.contentView.addSubview(timeLabel)
        self.contentView.addSubview(avatarView)
        self.contentView.addSubview(richContainerView)
        self.contentView.addSubview(countLabel)
        avatarView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 48, height: 48))
        }

        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(avatarView.snp.right).offset(12)
            make.top.equalTo(avatarView.snp.top).offset(4)
            make.right.equalTo(timeLabel.snp.left).offset(-6)
        }

        timeLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-11)
            make.centerY.equalTo(nameLabel)
        }

        richContainerView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(76)
            make.width.equalTo(0)
            make.top.equalTo(avatarView.snp.top).offset(24)
        }

        countLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-11)
            make.centerY.equalTo(richContainerView)
            make.width.equalTo(0)
        }
    }

    func updateUI() {
        guard let viewModel = viewModel else {
            return
        }
        var followNumber = viewModel.entity.count
        let width: CGFloat = followNumber <= 1 ? 0 : widthForString("×\(viewModel.entity.count)",
                                                                    font: countLabel.font ?? .systemFont(ofSize: 14, weight: .bold))
        nameLabel.text = viewModel.displayName
        countLabel.text = "×\(viewModel.entity.count)"
        countLabel.snp.updateConstraints { make in
            make.width.equalTo(width)
        }
        cellWidth = self.contentView.bounds.size.width
        let documentElement = viewModel.getRichElement()
        core.load(styleSheets: viewModel.styleSheets)
        let renderer = core.createRenderer(documentElement)
        core.load(renderer: renderer)
        let richView = richContainerView.richView
        let preferredMaxLayoutWidth = self.bounds.size.width - 76 - width - 16
        richView.preferredMaxLayoutWidth = preferredMaxLayoutWidth
        richContainerView.snp.updateConstraints { make in
            make.width.equalTo(preferredMaxLayoutWidth)
        }
        richView.isOpaque = false
        richView.backgroundColor = .clear
        richView.documentElement = documentElement
        richView.setRichViewCore(core)
        richView.delegate = viewModel
        richView.bindEvent(selectorLists: viewModel.propagationSelectors, isPropagation: true)
        self.avatarView.setAvatarByIdentifier("\(viewModel.chatter?.id ?? "")",
                                              avatarKey: viewModel.chatter?.avatarKey ?? "",
                                              avatarViewParams: .init(sizeType: .size(48))) { [weak self] res in
            guard let self = self else { return }
            switch res {
            case .failure(let err):
                print("\(err)")
            default:
                break
            }
        }
        let time = TimeInterval(viewModel.entity.followTimeMs)
        timeLabel.text = Date(timeIntervalSince1970: time / 1000.0 ).lf.formatedTime_v2()
    }

    @objc
    func avatarViewTapped() {
        guard let chatter = viewModel?.chatter else {
            return
        }
        self.tapAvatarBlock?(chatter.id)
    }

    private func widthForString(_ string: String, font: UIFont) -> CGFloat {
        let rect = (string as NSString).boundingRect(
            with: CGSize(width: CGFloat(MAXFLOAT), height: font.pointSize + 10),
            options: .usesLineFragmentOrigin,
            attributes: [NSAttributedString.Key.font: font], context: nil)
        return ceil(rect.width)
    }

}
