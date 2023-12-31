//
//  NewVoteDetailInfoViewController.swift
//  LarkMessageCore
//
//  Created by bytedance on 2022/4/6.
//

import Foundation
import UIKit
import LarkUIKit
import SnapKit
import RustPB
import EENavigator
import LarkMessengerInterface
import LarkSDKInterface
import LarkAccountInterface
import UniverseDesignIcon
import UniverseDesignTag
import RxSwift
import LarkBizTag
import LarkTag

public final class NewVoteDetailInfoViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource {

    static let CellIdentifier = "NewVoteDetailInfoCell"

    private let viewModel: NewVoteDetailInfoViewModel

    let disposeBag = DisposeBag()

    init(title: String?, countText: String?, viewModel: NewVoteDetailInfoViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.titleText = title
        self.countText = countText
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var navigationBarStyle: LarkUIKit.NavigationBarStyle {
        return .custom(UIColor.ud.bgFloat)
    }

    private var voteDetailInfo: [Voter] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }

    public var titleText: String? {
        get {
            return self.titleLabel.text
        }
        set {
            self.titleLabel.text = newValue
        }
    }

    public var countText: String? {
        get {
            return self.countLabel.text
        }
        set {
            self.countLabel.text = newValue
        }
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.bgFloat
        self.tableView.backgroundColor = UIColor.ud.bgFloat
        self.navigationItem.titleView = titleContainerView
        titleContainerView.addSubview(titleLabel)
        titleContainerView.addSubview(countLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.right.equalTo(countLabel.snp.left)
        }
        countLabel.snp.makeConstraints { make in
            make.right.top.bottom.equalToSuperview()
        }
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        self.view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.register(NewVoteDetailInfoCell.self, forCellReuseIdentifier: Self.CellIdentifier)
        tableView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.right.bottom.equalToSuperview()
        }

        self.viewModel.datasourceDriver.drive(onNext: { [weak self] voters in
            guard let self = self else { return }
            self.voteDetailInfo = voters
        }).disposed(by: disposeBag)

        self.viewModel.haveMoreDriver.drive(onNext: { [weak self] haveMore in
            guard let self = self else { return }
            self.tableView.endBottomLoadMore()
            if haveMore && !self.viewModel.isLimitBySecurity {
                self.tableView.addBottomLoadMoreView { [weak self] in
                    self?.viewModel.loadMore()
                }
            } else {
                self.tableView.removeBottomLoadMore()
            }
        }).disposed(by: disposeBag)

        self.viewModel.loadMore()
    }

    private lazy var titleContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloat
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.textAlignment = .center
        label.font = UIFont.ud.title3
        label.textColor = UIColor.ud.N900
        return label
    }()

    private lazy var countLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.textAlignment = .center
        label.font = UIFont.ud.title3
        label.textColor = UIColor.ud.N900
        return label
    }()

    private lazy var tableView: UITableView = UITableView()

    private func pushToPersonPage(chatterId: String, chatId: String) {
        let body = PersonCardBody(chatterId: chatterId, chatId: chatId, source: .chat)
        let mainVC = self.viewModel.nav.mainSceneTopMost
        guard let mainVC = mainVC else { return }
        self.viewModel.nav.push(body: body, from: mainVC)
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return voteDetailInfo.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.CellIdentifier, for: indexPath)
        let voterInfo = self.voteDetailInfo[indexPath.row]
        if let itemCell = cell as? NewVoteDetailInfoCell {
            let isCreator = (voterInfo.id == viewModel.initiator)
            itemCell.updateUI(voterInfo: voterInfo, isCreator: isCreator)
        }
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        // 获取数据
        let chatterId = self.voteDetailInfo[indexPath.row].id
        let chatId = viewModel.chatID
        self.pushToPersonPage(chatterId: chatterId, chatId: chatId)
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 66.0
    }

    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if viewModel.isLimitBySecurity {
            return 44.0
        } else {
            return 0.0
        }
    }

    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if viewModel.isLimitBySecurity {
            let footerView = UIView()
            footerView.backgroundColor = UIColor.ud.bgFloat
            let label = UILabel()
            label.backgroundColor = .clear
            label.text = BundleI18n.LarkMessageCore.Lark_IM_Poll_HideInfoForSecurityReasons_Text
            label.font = UIFont.systemFont(ofSize: 12)
            label.textColor = UIColor.ud.textPlaceholder
            label.textAlignment = .center
            label.numberOfLines = 0
            footerView.addSubview(label)
            label.snp.makeConstraints { make in
                make.left.equalTo(16)
                make.right.equalTo(-16)
                make.top.equalToSuperview()
            }
            return footerView
        } else {
            return nil
        }
    }
}

private final class NewVoteDetailInfoCell: UITableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var avatarImageView: UIImageView = {
        let avatar = UIImageView()
        avatar.layer.cornerRadius = 20
        avatar.clipsToBounds = true
        return avatar
    }()

    private lazy var labelContainer: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.backgroundColor = UIColor.ud.bgFloat
        stackView.distribution = .fill
        stackView.alignment = .center
        stackView.spacing = 8
        return stackView
    }()

    private lazy var creatorTag: UDTag = {
        let textConfig = UDTagConfig.TextConfig(font: UIFont.ud.caption0, textColor: UIColor.ud.B600, backgroundColor: UIColor.ud.B100)
        let tag = UDTag(text: BundleI18n.LarkMessageCore.Lark_IM_Poll_Creator_Label,
                        textConfig: textConfig)
        return tag
    }()

    lazy var chatterTagBuilder: ChatterTagViewBuilder = ChatterTagViewBuilder()
    lazy var chatterTagView: TagWrapperView = {
        let tagView = chatterTagBuilder.build()
        tagView.isHidden = true
        return tagView
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.ud.body0
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private func setupUI() {
        self.backgroundColor = UIColor.ud.bgFloat
        self.selectionStyle = .none
        contentView.addSubview(avatarImageView)
        contentView.addSubview(labelContainer)
        avatarImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(16)
            make.width.height.equalTo(40)
        }
        labelContainer.snp.makeConstraints { make in
            make.height.centerY.equalToSuperview()
            make.left.equalTo(avatarImageView.snp.right).offset(12)
            make.right.lessThanOrEqualToSuperview().offset(-8)
        }
        labelContainer.addArrangedSubview(nameLabel)
        labelContainer.addArrangedSubview(creatorTag)
        labelContainer.addArrangedSubview(chatterTagView)
    }

    public func updateUI(voterInfo: Voter, isCreator: Bool) {
        avatarImageView.bt.setLarkImage(with: .avatar(key: voterInfo.avatar.key, entityID: voterInfo.id))
        nameLabel.text = voterInfo.name
        chatterTagBuilder.reset(with: []).addTags(with: voterInfo.tagInfo.transform() ?? []).refresh()
        chatterTagView.isHidden = chatterTagBuilder.isDisplayedEmpty()
        creatorTag.isHidden = !isCreator
    }
}
