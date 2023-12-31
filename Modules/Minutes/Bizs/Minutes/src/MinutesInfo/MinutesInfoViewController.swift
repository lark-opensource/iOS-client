//
//  MinutesInfoViewController.swift
//  Minutes
//
//  Created by panzaofeng on 2021/1/12.
//  Copyright © 2021年 wangcong. All rights reserved.
//

import UIKit
import Kingfisher
import UniverseDesignColor
import ESPullToRefresh
import MinutesFoundation
import MinutesNetwork
import EENavigator
import LarkUIKit
import UniverseDesignColor
import UniverseDesignToast
import LarkFeatureGating
import UniverseDesignIcon
import SnapKit
import LarkContainer
import LarkTimeFormatUtils

class MinutesInfoViewController: UIViewController {
    let userResolver: UserResolver
    private var viewModel: MinutesInfoViewModel?

    var dependency: MinutesDependency? {
        return try? userResolver.resolve(assert: MinutesDependency.self)
    }
    
    private var tracker: MinutesTracker?

    var onClickItem: (() -> Void)?
    
    let participantSize = 10000

    var items: [MinutesInfoItem<MinutesInfoItemValue>] {
        viewModel?.items ?? []
    }

    lazy var loadingView: MinutesSummaryLoadingContainerView = {
        return MinutesSummaryLoadingContainerView()
    }()

    lazy var emptyView: MinutesSummaryEmptyContainerView = {
        return MinutesSummaryEmptyContainerView()
    }()

    lazy var tableView: MinutesTableView = {
        let tableView: MinutesTableView = MinutesTableView(frame: CGRect.zero, style: .plain)
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        if #available(iOS 13.0, *) {
            tableView.automaticallyAdjustsScrollIndicatorInsets = false
        }
        tableView.delegate = self
        tableView.dataSource = self
        tableView.delaysContentTouches = false
        tableView.register(MinutesInfoTableViewCellTypeName.self, forCellReuseIdentifier: MinutesInfoTableViewCellTypeName.description())
        tableView.register(MinutesInfoTableViewCellTypeOwner.self, forCellReuseIdentifier: MinutesInfoTableViewCellTypeOwner.description())
        tableView.register(MinutesInfoTableViewCellTypeTime.self, forCellReuseIdentifier: MinutesInfoTableViewCellTypeTime.description())
        tableView.register(MinutesInfoTableViewCellTypeParticipant.self, forCellReuseIdentifier: MinutesInfoTableViewCellTypeParticipant.description())
        tableView.register(MinutesInfoTableViewCellTypeLink.self, forCellReuseIdentifier: MinutesInfoTableViewCellTypeLink.description())
        tableView.register(MinutesInfoCoverCell.self, forCellReuseIdentifier: MinutesInfoCoverCell.description())
        tableView.keyboardDismissMode = .onDrag
        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.estimatedRowHeight = 52
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)
        return tableView
    }()

    private lazy var header: MinutesRefreshHeaderAnimator = {
        let header = MinutesRefreshHeaderAnimator(frame: .zero)
        return header
    }()

    init(resolver: UserResolver, minutes: Minutes) {
        self.userResolver = resolver
        self.viewModel = MinutesInfoViewModel(minutes: minutes)
        self.tracker = MinutesTracker(minutes: minutes)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = UIScrollView.ContentInsetAdjustmentBehavior.never
        } else {
            self.automaticallyAdjustsScrollViewInsets = false
        }
        tableView.es.addPullToRefresh(animator: header) { [weak self] in
            guard let self = self else { return }
            self.viewModel?.fetchData({ [weak self] in
                self?.tableView.es.stopPullToRefresh()
                self?.tableView.reloadData()
                self?.showLoadingView(false)
            })
        }
        view.addSubview(tableView)
        view.addSubview(loadingView)
        view.addSubview(emptyView)

        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        loadingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        emptyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        tableView.reloadData()

        showLoadingView(true)
        self.viewModel?.fetchData({ [weak self] in
            self?.tableView.reloadData()
            self?.showLoadingView(false)
        })

        NotificationCenter.default.addObserver(self, selector: #selector(updateSpeakerSuccess), name: NSNotification.Name.EditSpeaker.updateSpeakerSuccess, object: nil)
    }

    private func showLoadingView(_ show: Bool) {
        emptyView.isHidden = true
        loadingView.isHidden = !show
    }

    private func showEmptyView(_ show: Bool) {
        loadingView.isHidden = true
        emptyView.isHidden = !show
    }

    func removeRefreshHeader() {
        if tableView.header == nil { return }

        tableView.es.removeRefreshHeader()
    }

    func enterSearch() {
        removeRefreshHeader()
    }

    func exitSearch() {
        if tableView.header != nil { return }

        tableView.es.addPullToRefresh(animator: header) { [weak self] in
            guard let wSelf = self else { return }
            wSelf.requestNewInfoData()
        }
    }

    @objc
    private func updateSpeakerSuccess() {
        let size = participantSize
        self.viewModel?.minutes.info.fetchBasicInfo(catchError: true, completionHandler: {[weak self] result in
            guard let self = self else {
                return
            }
            switch result {
            case .success(let response):
                self.viewModel?.minutes.info.fetchParticipant(catchError: false, size: size, completionHandler: { _ in
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                })
            case .failure(let error): break
            }
        })
    }
}

// MARK: - Requests

extension MinutesInfoViewController {
    func requestNewInfoData() {
        self.viewModel?.fetchData({ [weak self] in
            self?.tableView.reloadData()
            self?.showLoadingView(false)
        })
    }
}

extension MinutesInfoViewController: MinutesAddParticipantSearchViewControllerDelegate {
    func participantsInvited(_ controller: MinutesAddParticipantSearchViewController) {
        requestNewInfoData()
    }
}

// MARK: - UITableViewDataSource && UITableViewDelegate

extension MinutesInfoViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        switch item.type {
        case .name:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: MinutesInfoTableViewCellTypeName.description(), for: indexPath)
                    as? MinutesInfoTableViewCellTypeName else { return UITableViewCell() }
            cell.setData(leftLabelText: item.title,
                              leftLabelWidth: 0,
                              rightLabelText: item.value.string ?? "",
                              rightLabelWidth: 0)
            return cell
        case .owner:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: MinutesInfoTableViewCellTypeOwner.description(), for: indexPath)
                    as? MinutesInfoTableViewCellTypeOwner else { return UITableViewCell() }
            cell.setData(leftLabelText: item.title,
                              leftLabelWidth: 0,
                              rightImageName: item.imageUrl ?? "",
                              rightLabelText: item.value.string ?? "",
                                          rightLabelWidth: 0)
            return cell
        case .participant:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: MinutesInfoTableViewCellTypeParticipant.description(), for: indexPath)
                    as? MinutesInfoTableViewCellTypeParticipant else { return UITableViewCell() }
            cell.setData(leftLabelText: item.title,
                              leftLabelWidth: 0,
                              participants: viewModel?.minutes.info.participants ?? [],
                              rightLabelWidth: 0)
            return cell
        case .time:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: MinutesInfoTableViewCellTypeTime.description(), for: indexPath)
                    as? MinutesInfoTableViewCellTypeTime else { return UITableViewCell() }
            cell.setData(leftLabelText: item.title,
                              leftLabelWidth: 0,
                              rightLabelText: item.value.string ?? "",
                              rightLabelWidth: 0)
            return cell
        case .summary:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: MinutesInfoTableViewCellTypeLink.description(), for: indexPath)
                    as? MinutesInfoTableViewCellTypeLink else { return UITableViewCell() }
            cell.setData(topTitle: item.title, leftLabelWidth: 0, files: item.value.files)
            cell.onClickFile = { [weak self] file in
                guard let wSelf = self else { return }
                wSelf.userResolver.navigator.push(file.fileURL, context: ["forcePush": true], from: wSelf)
                wSelf.tracker?.tracker(name: .detailClick, params: ["click": "meeting_minutes_doc", "file_id": file.token ?? "", "target": "none"])
            }
            return cell
        case .link:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: MinutesInfoTableViewCellTypeLink.description(), for: indexPath)
                    as? MinutesInfoTableViewCellTypeLink else { return UITableViewCell() }
            cell.dependency = dependency
            cell.setData(topTitle: item.title, leftLabelWidth: 0, files: item.value.files)
            cell.onClickFile = { [weak self] file in
                guard let wSelf = self else { return }
                self?.userResolver.navigator.push(file.fileURL, context: ["forcePush": true], from: wSelf)

                var trackParams: [AnyHashable: Any] = [:]
                trackParams.append(.openShareLink)
                trackParams["file_id"] = file.fid
                wSelf.tracker?.tracker(name: .clickButton, params: trackParams)

                wSelf.tracker?.tracker(name: .detailClick, params: ["click": "open_share_link", "file_id": file.fid, "target": "none"])
            }
            return cell
        case .groupChat, .channels, .fragment:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: MinutesInfoCoverCell.description(), for: indexPath)
                    as? MinutesInfoCoverCell else { return UITableViewCell() }
            var data: [CoverInfo] = []
            var isClip = false
            if item.type == .groupChat {
                data = item.value.groupChats
            } else if item.type == .channels {
                data = item.value.channels
            } else {
                data = item.value.fragments
                isClip = true
            }
            cell.sectionTitle = data.first?.sectionName
            cell.items = data
            cell.click = { [weak self] info in
                guard let self = self else { return }
                if let url = URL(string: info.url) {
                    if let minutes = Minutes(url) {
                        self.onClickItem?()
                        if isClip {
                            let body = MinutesClipBody(minutes: minutes, source: .clipList, destination: .detail)
                            var params = NaviParams()
                            params.forcePush = true
                            self.userResolver.navigator.push(body: body, naviParams: params, from: self)
                        } else {
                            let body = MinutesDetailBody(minutes: minutes, source: .info, destination: .detail)
                            var params = NaviParams()
                            params.forcePush = true
                            self.userResolver.navigator.push(body: body, naviParams: params, from: self)
                        }
                    }
                }

                if item.type == .groupChat {
                    self.tracker?.tracker(name: .detailClick, params: ["click": "discussion_record", "target": "none"])
                } else if item.type == .channels {
                    self.tracker?.tracker(name: .detailClick, params: ["click": "interpretation", "target": "none"])
                } else if item.type == .fragment {
                    self.tracker?.tracker(name: .detailClick, params: ["click": "clip_share", "target": "none"])
                }
            }
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        switch item.type {
        case .owner:
            if let ownerInfo = viewModel?.minutes.info.basicInfo?.ownerInfo {
                self.tracker?.tracker(name: .clickButton, params: ["action_name": "profile_picture", "page_name": "detail_page", "from_source": " owner_picture"])
                MinutesProfile.personProfile(chatterId: ownerInfo.userId, from: self, resolver: userResolver)

                tracker?.tracker(name: .detailClick, params: ["click": "profile", "location": "owner_picture", "target": "none"])
            }
        case .participant:
            guard let participantInfo = viewModel?.minutes.info else { return }
            self.tracker?.tracker(name: .clickButton, params: ["action_name": "participant_profile"])
            self.tracker?.tracker(name: .detailClick, params: ["click": "participant_profile", "target": "none"])

            if let minutes = viewModel?.minutes {
                if minutes.info.participants.count > 0 {
                    let minutesInfoParticipantViewController = MinutesInfoParticipantViewController(resolver: userResolver, minutes: minutes)
                    minutesInfoParticipantViewController.delegate = self

                    if Display.pad {
                        userResolver.navigator.present(minutesInfoParticipantViewController, wrap: LkNavigationController.self, from: self) { $0.modalPresentationStyle = .formSheet }
                    } else {
                        userResolver.navigator.push(minutesInfoParticipantViewController, from: self)
                    }
                } else {
                    let minutesParticipantsSearchController = MinutesAddParticipantSearchViewController(resolver: userResolver, minutes: minutes)
                    minutesParticipantsSearchController.delegate = self
                    let style: UIModalPresentationStyle = Display.pad ? .formSheet : .fullScreen
                    userResolver.navigator.present(minutesParticipantsSearchController, wrap: LkNavigationController.self, from: self) { $0.modalPresentationStyle = style }
                }
            }
        default:
            break
        }
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {

    }
}

extension MinutesInfoViewController: MinutesInfoParticipantViewControllerDelegate {
    func participantsChanged(_ controller: MinutesInfoParticipantViewController) {
        requestNewInfoData()
    }
}

// MARK: - MinutesInfoTableViewCellTypeName - 名称

class MinutesInfoTableViewCellTypeName: UITableViewCell {

    private lazy var leftLabel: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.textColor = UIColor.ud.textCaption
        label.textAlignment = .left
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()

    private lazy var rightLabel: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.textColor = UIColor.ud.textCaption
        label.textAlignment = .left
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.ud.bgBody
        contentView.addSubview(leftLabel)
        leftLabel.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.top.equalTo(15)
            make.width.equalTo(80)
        }
        contentView.addSubview(rightLabel)
        rightLabel.snp.makeConstraints { make in
            make.top.equalTo(16)
            make.left.equalTo(leftLabel.snp.right).offset(4)
            make.right.bottom.equalTo(-16)
        }
    }

    func setData(leftLabelText: String, leftLabelWidth: CGFloat, rightLabelText: String, rightLabelWidth: CGFloat) {
        leftLabel.text = leftLabelText
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 0.98
        rightLabel.attributedText = NSAttributedString(string: rightLabelText, attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
        leftLabel.snp.updateConstraints { make in
            make.width.equalTo(leftLabelWidth)
        }
    }
}

// MARK: - MinutesInfoTableViewCellType1 - 所有者

class MinutesInfoTableViewCellTypeOwner: UITableViewCell {

    private lazy var leftLabel: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.textColor = UIColor.ud.textCaption
        label.textAlignment = .left
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()

    private lazy var rightImageView: UIImageView = {
        let imageView: UIImageView = UIImageView(frame: CGRect.zero)
        return imageView
    }()

    private lazy var rightLabel: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .left
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.ud.bgBody
        selectionStyle = .none
        contentView.addSubview(leftLabel)
        leftLabel.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.top.equalTo(22)
            make.height.equalTo(22)
            make.right.equalTo(-16)
        }
        contentView.addSubview(rightImageView)
        rightImageView.layer.cornerRadius = 12
        rightImageView.layer.masksToBounds = true
        rightImageView.snp.makeConstraints { (maker) in
            maker.top.equalTo(leftLabel.snp.bottom).offset(8)
            maker.left.equalTo(leftLabel)
            maker.width.height.equalTo(24)
            maker.bottom.equalToSuperview().offset(-4)
        }
        contentView.addSubview(rightLabel)
        rightLabel.snp.makeConstraints { (maker) in
            maker.centerY.equalTo(rightImageView)
            maker.left.equalTo(rightImageView.snp.right).offset(4)
            maker.right.equalTo(-16)
        }
    }

    func setData(leftLabelText: String, leftLabelWidth: CGFloat, rightImageName: String, rightLabelText: String, rightLabelWidth: CGFloat) {
        leftLabel.text = leftLabelText
        rightLabel.text = rightLabelText
        rightImageView.setAvatarImage(with: URL(string: rightImageName), placeholder: UIImage.dynamicIcon(.adsMobileAvatarCircle, dimension: 48, color: UIColor.ud.N300))

    }
}

// MARK: - MinutesInfoTableViewCellType2 - 创建时间

class MinutesInfoTableViewCellTypeTime: UITableViewCell {

    private lazy var leftLabel: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.textColor = UIColor.ud.textCaption
        label.textAlignment = .left
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()

    private lazy var rightLabel: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .left
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.ud.bgBody
        selectionStyle = .none
        contentView.addSubview(leftLabel)
        contentView.addSubview(rightLabel)
    }

    func setData(leftLabelText: String, leftLabelWidth: CGFloat, rightLabelText: String, rightLabelWidth: CGFloat) {
        leftLabel.text = leftLabelText
        rightLabel.text = rightLabelText

        leftLabel.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.top.equalTo(22)
            make.right.equalTo(-16)
            make.height.equalTo(22)
        }

        rightLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(leftLabel.snp.bottom).offset(9)
            maker.left.right.equalTo(leftLabel)
            maker.bottom.equalToSuperview().offset(-4)
        }
    }
}

// MARK: - MinutesInfoTableViewCellTypeParticipant - 参会人

class MinutesInfoTableViewCellTypeParticipant: UITableViewCell {

    private var avatarsView: UIView?

    private lazy var addParticipantsView: MinutesInfoAddNewParticipantView = {
        let view = MinutesInfoAddNewParticipantView(frame: .zero)
        return view
    }()

    private lazy var leftLabel: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.textColor = UIColor.ud.textCaption
        label.textAlignment = .left
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.ud.bgBody
        selectionStyle = .none
        contentView.addSubview(leftLabel)
        leftLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(22)
            maker.left.equalTo(16)
            maker.height.equalTo(22)
        }

        contentView.addSubview(addParticipantsView)
        addParticipantsView.snp.makeConstraints { (maker) in
            maker.top.equalTo(leftLabel.snp.bottom).offset(8)
            maker.left.equalTo(leftLabel)
            maker.right.equalToSuperview().offset(-16)
            maker.height.equalTo(26)
            maker.bottom.equalToSuperview().offset(-4)
        }

        addParticipantsView.isHidden = true
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        addParticipantsView.pressMask.isHidden = !highlighted
    }

    func getAvatarsView(participants: [Participant]) -> UIView {
        let avatarsView = UIView(frame: CGRect.zero)
        for (index, participant) in participants.enumerated() {
            if index < 7 {
                let imageView: UIImageView = UIImageView(frame: CGRect.zero)
                imageView.setAvatarImage(with: participant.avatarURL, placeholder: UIImage.dynamicIcon(.adsMobileAvatarCircle, dimension: 48, color: UIColor.ud.N300))
                imageView.layer.borderWidth = 1
                imageView.layer.ud.setBorderColor(UIColor.ud.N00)
                imageView.layer.cornerRadius = 12
                imageView.layer.masksToBounds = true

                avatarsView.addSubview(imageView)
                imageView.snp.makeConstraints { (maker) in
                    maker.top.equalToSuperview()
                    maker.left.equalToSuperview().offset(20 * CGFloat(index))
                    maker.width.height.equalTo(26)
                }
            } else {
                if participants.count == 8 {
                    let imageView: UIImageView = UIImageView(frame: CGRect.zero)
                    imageView.setAvatarImage(with: participant.avatarURL, placeholder: UIImage.dynamicIcon(.adsMobileAvatarCircle, dimension: 48, color: UIColor.ud.N300))
                    imageView.layer.borderWidth = 1
                    imageView.layer.ud.setBorderColor(UIColor.ud.N00)
                    imageView.layer.cornerRadius = 13
                    imageView.layer.masksToBounds = true

                    avatarsView.addSubview(imageView)
                    imageView.snp.makeConstraints { (maker) in
                        maker.top.equalToSuperview()
                        maker.left.equalToSuperview().offset(20 * CGFloat(index))
                        maker.width.height.equalTo(26)
                    }
                } else {
                    let moreView: UIView = UIView(frame: CGRect.zero)
                    moreView.backgroundColor = UIColor.ud.bgFiller
                    moreView.layer.borderWidth = 1
                    moreView.layer.ud.setBorderColor(UIColor.ud.N00)
                    moreView.layer.cornerRadius = 13
                    moreView.layer.masksToBounds = true
                    avatarsView.addSubview(moreView)
                    moreView.snp.makeConstraints { (maker) in
                        maker.top.equalToSuperview()
                        maker.left.equalToSuperview().offset(20 * CGFloat(index))
                        maker.width.height.equalTo(26)
                    }

                    let moreLabel: UILabel = UILabel(frame: CGRect.zero)
                    if participants.count <= 99 {
                        moreLabel.text = "+\(participants.count - 7)"
                    } else if participants.count > 99 && participants.count <= 999 {
                        moreLabel.text = "99+"
                    } else {
                        moreLabel.text = "1k+"
                    }
                    moreLabel.textAlignment = .center
                    moreLabel.textColor = UIColor.ud.textCaption
                    moreLabel.font = UIFont.systemFont(ofSize: 10)
                    moreView.addSubview(moreLabel)
                    moreLabel.snp.makeConstraints { (maker) in
                        maker.center.equalToSuperview()
                    }
                }
                break
            }
        }
        return avatarsView
    }

    func setData(leftLabelText: String, leftLabelWidth: CGFloat, participants: [Participant], rightLabelWidth: CGFloat) {
        leftLabel.text = leftLabelText

        if let avatarsView = avatarsView {
            avatarsView.removeFromSuperview()
        }

        if participants.count == 0 {
            addParticipantsView.isHidden = false
        } else {
            addParticipantsView.isHidden = true
            avatarsView = self.getAvatarsView(participants: participants)
            if let avatarsView = avatarsView {
                contentView.addSubview(avatarsView)
                avatarsView.snp.makeConstraints { (maker) in
                    maker.top.equalTo(leftLabel.snp.bottom).offset(8)
                    maker.bottom.equalToSuperview().offset(-14)
                    maker.left.equalTo(leftLabel)
                    maker.right.equalToSuperview().offset(-16)
                    maker.height.equalTo(27)
                }
            }
        }
    }
}

// MARK: - MinutesInfoTableViewCellTypeLink - 相关链接
class MinutesInfoTableViewCellTypeLink: UITableViewCell {

    var dependency: MinutesDependency?

    var onClickFile: ((FileInfo) -> Void)?
    
    private var files: [FileInfo] = []

    private lazy var topLabel: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.textColor = UIColor.ud.textCaption
        label.textAlignment = .left
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()

    private lazy var fileStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.distribution = .fill
        return stack
    }()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.ud.bgBody
        contentView.addSubview(topLabel)
        selectionStyle = .none
        topLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(22)
            maker.left.equalTo(16)
            maker.height.equalTo(22)
        }
        contentView.addSubview(fileStack)
        fileStack.snp.makeConstraints { make in
            make.top.equalTo(topLabel.snp.bottom).offset(8)
            make.left.equalTo(topLabel)
            make.bottom.equalTo(-4)
            make.right.equalTo(-16)
        }
    }

    func config(files: [FileInfo]) {
        let subviews = fileStack.subviews
        for v in subviews {
            v.removeFromSuperview()
        }
        for (index, file) in files.enumerated() {
            let fileContainerView: UIView = UIView(frame: CGRect.zero)

            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTapFile(_:)))
            fileContainerView.addGestureRecognizer(tapGestureRecognizer)
            fileContainerView.isUserInteractionEnabled = true
            fileContainerView.tag = index

            let fileImageView: UIImageView = UIImageView(frame: CGRect.zero)

            fileImageView.image = UDIcon.getIconByKey(.fileLinkOtherfileOutlined, iconColor: UIColor.ud.colorfulBlue, size: CGSize(width: 18, height: 18))
            dependency?.docs?.getDocsIconImageAsync(url: file.fileURL.absoluteString, finish: { image in
                DispatchQueue.main.async {
                    fileImageView.image = image
                }
            })
            
            fileImageView.contentMode = .scaleAspectFit
            fileContainerView.addSubview(fileImageView)
            fileImageView.snp.makeConstraints { (maker) in
                maker.top.equalTo(0)
                maker.left.equalToSuperview()
                maker.height.width.equalTo(18)
            }

            let fileTitleLabel: UILabel = UILabel(frame: CGRect.zero)
            fileTitleLabel.text = file.fileTitle
            fileTitleLabel.numberOfLines = 0
            fileTitleLabel.textColor = UIColor.ud.colorfulBlue
            fileTitleLabel.font = UIFont.systemFont(ofSize: 16)
            fileContainerView.addSubview(fileTitleLabel)
            fileTitleLabel.snp.makeConstraints { (maker) in
                maker.top.equalToSuperview()
                maker.left.equalTo(fileImageView.snp.right).offset(4)
                maker.right.equalToSuperview()
                maker.bottom.equalToSuperview()
            }
            fileStack.addArrangedSubview(fileContainerView)
            if index < files.count - 1 {
                fileStack.setCustomSpacing(10, after: fileContainerView)
            }
        }
    }

    func setData(topTitle: String, leftLabelWidth: CGFloat, files: [FileInfo]) {
        self.files = files

        topLabel.text = topTitle
        config(files: files)
    }

    @objc
    private func onTapFile(_ gestureRecognizer: UITapGestureRecognizer) {
        if let tapView = gestureRecognizer.view,
           tapView.tag < files.count,
           let someOnClickFile = onClickFile {
            someOnClickFile(files[tapView.tag])
        }
    }
}

extension MinutesInfoViewController: PagingViewListViewDelegate {
    public func listView() -> UIView {
        return view
    }

    public func listScrollView() -> UIScrollView {
        return self.tableView
    }
}

class MinutesInfoCollectionViewCell: UICollectionViewCell {
    private lazy var iconImage: UIImageView = UIImageView()
    private lazy var permissionImage: UIImageView = UIImageView()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.ud.bgBody
        contentView.addSubview(iconImage)
        contentView.addSubview(permissionImage)
        contentView.addSubview(titleLabel)

        permissionImage.isHidden = true

        iconImage.layer.cornerRadius = 6.0
        iconImage.layer.masksToBounds = true
        iconImage.layer.borderWidth = 1
        iconImage.layer.borderColor = UIColor.ud.lineBorderCard.cgColor

        iconImage.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.size.equalTo(CGSize(width: 100, height: 56))
        }
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(iconImage.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        permissionImage.snp.makeConstraints { make in
            make.center.equalTo(iconImage)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func config(with item: CoverInfo) {
        titleLabel.text = item.name
        if item.permissionStatus == 0 {
            // 无权限
            permissionImage.isHidden = false
            // 空url用于取消下载
            iconImage.setAvatarImage(with: URL(string: ""), placeholder: BundleResources.Minutes.minutes_info_collection_bg)
            iconImage.image = BundleResources.Minutes.minutes_info_collection_bg

            permissionImage.image = UDIcon.getIconByKey(.lockOutlined, iconColor: UIColor.ud.staticBlack.withAlphaComponent(0.4))
        } else if item.permissionStatus == 1 {
            // 有权限
            if item.generateStatus == 1 {
                // 生成完成
                permissionImage.isHidden = true
                iconImage.setAvatarImage(with: URL(string: item.image), placeholder: BundleResources.Minutes.minutes_info_collection_bg)
            } else {
                // 生成中
                permissionImage.isHidden = false

                iconImage.setAvatarImage(with: URL(string: ""), placeholder: BundleResources.Minutes.minutes_info_collection_bg)
                iconImage.image = BundleResources.Minutes.minutes_info_collection_bg
                permissionImage.image = UDIcon.getIconByKey(.timeOutlined, iconColor: UIColor.ud.staticBlack.withAlphaComponent(0.4))
            }
        }
    }
}

class MinutesInfoCoverCell: UITableViewCell {
    private lazy var sectionTitleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textCaption
        return label
    }()

    private var layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = Layout.itemSize
        layout.minimumLineSpacing = 8
        return layout
    }()

    private(set) lazy var collectionView: UICollectionView = {
        let collection = UICollectionView(frame: CGRect.zero, collectionViewLayout: self.layout)
        collection.showsHorizontalScrollIndicator = false
        collection.backgroundColor = UIColor.ud.bgBody
        collection.register(MinutesInfoCollectionViewCell.self, forCellWithReuseIdentifier: MinutesInfoCollectionViewCell.description())
        collection.delegate = self
        collection.dataSource = self
        return collection
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        backgroundColor = UIColor.ud.bgBody

        contentView.addSubview(sectionTitleLabel)
        contentView.addSubview(collectionView)
        sectionTitleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(22)
        }
        collectionView.snp.makeConstraints { (make) in
            make.top.equalTo(sectionTitleLabel.snp.bottom).offset(8)
            make.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(78)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate enum Layout {
        static let itemMinimumLineSpacing: CGFloat = 10
        static let itemMinimumInteritemSpacing: CGFloat = 0
        static let menuMargin: CGFloat = 4
        static let itemSize = CGSize(width: 100, height: 78)
    }

    var sectionTitle: String? {
        didSet {
            sectionTitleLabel.text = sectionTitle
        }
    }

    var items: [CoverInfo] = [] {
        didSet {
            collectionView.reloadData()
        }
    }

    var click: ((CoverInfo) -> Void)?
}

extension MinutesInfoCoverCell: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MinutesInfoCollectionViewCell.description(), for: indexPath) as? MinutesInfoCollectionViewCell else {
            return UICollectionViewCell()
        }
        cell.config(with: items[indexPath.row])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let menuItem = items[indexPath.row]
        click?(menuItem)
    }
}

