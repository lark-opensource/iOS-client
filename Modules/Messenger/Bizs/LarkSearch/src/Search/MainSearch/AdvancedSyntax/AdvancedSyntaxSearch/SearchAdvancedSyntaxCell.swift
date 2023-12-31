//
//  SearchAdvancedSyntaxCell.swift
//  LarkSearch
//
//  Created by ByteDance on 2023/12/1.
//

import LarkUIKit
import UniverseDesignColor
import UniverseDesignFont
import UniverseDesignIcon
import SnapKit
import LarkContainer
import LarkMessengerInterface
import LarkSearchCore
import LarkSearchFilter
import LarkBizAvatar
import LarkAccountInterface

// 目前还没用，为以后拓展类型留的
protocol SearchAdvancedSyntaxCellProtocol {
    func set(viewModel: SearchAdvancedSyntaxCellViewModel)
    var viewModel: SearchAdvancedSyntaxCellViewModel? { get }
}

class SearchAdvancedSyntaxCell: UITableViewCell, SearchAdvancedSyntaxCellProtocol {
    public static let cellHeight: CGFloat = 44
    var viewModel: SearchAdvancedSyntaxCellViewModel?
    private let iconImageView: UIImageView = {
        let iconImage: UIImage = UDIcon.getIconByKey(.searchOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 18, height: 18))
        let iconImageView: UIImageView = UIImageView(image: iconImage)
        return iconImageView
    }()
    private let containerView: UIView = {
        let containerView = UIView()
        containerView.backgroundColor = UIColor.ud.primaryPri50
        containerView.layer.cornerRadius = 6
        return containerView
    }()
    private let avatarView = BizAvatar()
    private let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textColor = UIColor.ud.primaryPri800
        return titleLabel
    }()

    private let nameLabel: UILabel = {
        let nameLabel = UILabel()
        nameLabel.textColor = UIColor.ud.primaryPri800
        return nameLabel
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupUI()
    }

    private func setupUI() {
        backgroundColor = UIColor.clear
        selectedBackgroundView = SearchCellSelectedView()
        contentView.addSubview(iconImageView)
        contentView.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(avatarView)
        containerView.addSubview(nameLabel)
        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 18, height: 18))
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
        }
        containerView.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(10)
            make.height.equalTo(24)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview().offset(-10)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(4)
            make.centerY.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }
        avatarView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 18, height: 18))
            make.leading.equalTo(titleLabel.snp.trailing).offset(4)
            make.centerY.equalToSuperview()
        }
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(2)
            make.height.equalTo(24)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview().offset(-4)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        avatarView.image = nil
        nameLabel.text = nil
    }

    override func layoutSubviews() {
        let frame = self.contentView.frame.inset(by: UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5))
        self.selectedBackgroundView?.frame = frame
        self.selectedBackgroundView?.layer.cornerRadius = 6
    }

    func set(viewModel: SearchAdvancedSyntaxCellViewModel) {
        guard let advancedSyntaxFilterType = viewModel.filter.advancedSyntaxFilterType else { return }
        self.viewModel = viewModel
        titleLabel.text = "\(advancedSyntaxFilterType.title):"
        if let avatarInfo = viewModel.filter.avatarInfos.first {
            avatarView.setAvatarByIdentifier(avatarInfo.avatarID,
                                             avatarKey: avatarInfo.avatarKey,
                                             avatarViewParams: .init(sizeType: .size(18)))
        }
        nameLabel.text = viewModel.filter.content
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        updateCellState(animated: animated)
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        updateCellState(animated: animated)
    }

    private func updateCellState(animated: Bool) {
        updateCellStyle(animated: animated)
    }
}
