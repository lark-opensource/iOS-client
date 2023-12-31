//
//  RefuseReasonView.swift
//  ByteView
//
//  Created by wangpeiran on 2023/3/21.
//

import Foundation
import UniverseDesignColor
import UniverseDesignIcon
import SnapKit
import ByteViewTracker

struct RefuseReasonItem {
    var title: String
    var isCustom: Bool

    init(title: String, isCustom: Bool) {
        self.title = title
        self.isCustom = isCustom
    }
}

class RefuseReasonView: RefuseShadowView {

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        return label
    }()

    private lazy var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = .ud.lineDividerDefault
        return view
    }()

    private lazy var titleView: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var closeBtn: UIButton = {
        let button = EnlargeTouchButton(padding: 10)
        let img = UDIcon.getIconByKey(.closeOutlined, iconColor: UIColor.ud.iconN2, size: CGSize(width: 16.0, height: 16.0))
        button.setImage(img, for: .normal)
        button.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
        return button
    }()

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.register(RefuseReasonCell.self, forCellReuseIdentifier: "RefuseReasonCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 50
        tableView.separatorColor = .ud.lineDividerDefault
        tableView.isScrollEnabled = false
        return tableView
    }()

    var dataList: [RefuseReasonItem] = {
        return [RefuseReasonItem(title: I18n.View_G_NotAvailableWait, isCustom: false),
                RefuseReasonItem(title: I18n.View_G_InAMeetingWait, isCustom: false),
                RefuseReasonItem(title: I18n.View_G_HoldOnComing, isCustom: false),
                RefuseReasonItem(title: I18n.View_G_CustomReplyClick, isCustom: true)]
    }()

    var tapBlock: ((RefuseReasonItem?) -> Void)?

    var body: RingRefuseBody?

    override func setupView(needPan: Bool = true) {
        super.setupView(needPan: false)

        tableView.dataSource = self
        tableView.delegate = self

        titleView.addSubview(titleLabel)
        titleView.addSubview(closeBtn)
        titleView.addSubview(lineView)
        containerView.addSubview(titleView)
        containerView.addSubview(tableView)

        let cellTotalHeight = 50 * dataList.count

        titleView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
        }

        lineView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(1 / self.vc.displayScale)
            make.bottom.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.top.bottom.equalToSuperview().inset(12)
            make.height.greaterThanOrEqualTo(18.0)
        }

        closeBtn.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(13)
            make.right.equalToSuperview().offset(-16)
            make.left.equalTo(titleLabel.snp.right).offset(14)
            make.size.equalTo(16)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(titleView.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().inset(6)
            make.height.greaterThanOrEqualTo(cellTotalHeight)
        }
    }

    func setTitle(name: String) {
        titleLabel.attributedText = NSAttributedString(string: I18n.View_G_SendSetMessageToVaryName(name: name), config: .tinyAssist, textColor: UIColor.ud.textCaption)
    }

    @objc func closeAction() {
        Logger.ringRefuse.info("close action")
        tapBlock?(nil)
    }
}

extension RefuseReasonView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "RefuseReasonCell",
                                                    for: indexPath) as? RefuseReasonCell {
            cell.setTitle(dataList[indexPath.row].title)
            cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
            return cell
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        tapBlock?(dataList[indexPath.row])

        var quickReplyContent: String = ""
        if indexPath.row == 0 {
            quickReplyContent = "in_a_meeting"
        } else if indexPath.row == 1 {
            quickReplyContent = "not_convenient"
        } else if indexPath.row == 2 {
            quickReplyContent = "join_later"
        }
        let params: TrackParams = [
            "quickReplyContent": quickReplyContent,
            "conference_id": body?.meetingId ?? "",
            "caller_user_id": body?.inviterUserId ?? "",
            .click: "quick_reply"
        ]
        VCTracker.post(name: .vc_meeting_callee_msgnotes_click, params: params)
    }
}


class RefuseReasonCell: UITableViewCell {

    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = .systemFont(ofSize: 16.0)
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        self.setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        self.selectedBackgroundView = UIView()
        self.selectedBackgroundView?.backgroundColor = UIColor.ud.fillPressed
        self.contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(14)
            make.left.right.equalToSuperview().inset(16)
            make.height.greaterThanOrEqualTo(22.0)
        }
    }

    func setTitle(_ title: String) {
        titleLabel.text = title
    }
}
