//
//  InMeetSubtitleItemView.swift
//  ByteView
//
//  Created by 陈乐辉 on 2023/5/31.
//

import SnapKit
import ByteViewUI
import ByteViewCommon
import UIKit
import Lottie
import RichLabel
import RxSwift

class InMeetSubtitleItemView: UIView, UITableViewDataSource, UITableViewDelegate {

    static let lineHeight: CGFloat = 22

    lazy var avatarImageView: AvatarView = {
        let avatarImageView = AvatarView()
        avatarImageView.layer.masksToBounds = true
        avatarImageView.layer.cornerRadius = 10
        avatarImageView.contentMode = .scaleAspectFill
        return avatarImageView
    }()

    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = UIColor.ud.staticWhite.withAlphaComponent(0.7)
        label.numberOfLines = 1
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    lazy var tableView: BaseTableView = {
        let tableView = BaseTableView()
        tableView.isUserInteractionEnabled = false
        tableView.backgroundColor = .clear
        tableView.bounces = false
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        tableView.register(cellType: SubtitleContentCell.self)
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()

    var subtitleDatas: [SubtitleViewData] = []
    var speaker = InMeetSubtitleDataHandler.Speaker()
    var items: [SubtitleCellItem] = []

    var textAttributes: [NSAttributedString.Key: Any] = [:]

    var isAlignRight: Bool = false {
        didSet {
            guard isAlignRight != oldValue else { return }
            updateTextAttributes()
        }
    }

    var contentWidth: CGFloat { tableView.bounds.width }

    private(set) var disposeBag = DisposeBag()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.top.left.equalToSuperview()
            make.width.height.equalTo(20)
        }

        addSubview(nameLabel)
        let rightOffset: CGFloat = Display.pad ? 0 : -28
        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(self.avatarImageView.snp.right).offset(8)
            make.height.equalTo(18)
            make.top.equalToSuperview()
            make.right.lessThanOrEqualTo(rightOffset)
        }

        addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(-1)
            make.bottom.right.equalToSuperview()
        }

        updateTextAttributes()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func config(with speaker: InMeetSubtitleDataHandler.Speaker, isAlighRight: Bool) {
        let subtitleDatas = speaker.subtitles
        if subtitleDatas.isEmpty { return }
        if let data = subtitleDatas.first {
            avatarImageView.setTinyAvatar(data.avatarInfo)
            nameLabel.text = data.name
            disposeBag = DisposeBag()
            data.nameRelay
                .skip(1)
                .distinctUntilChanged()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    self?.nameLabel.text = $0
                }).disposed(by: disposeBag)
        }
        self.speaker = speaker
        self.isAlignRight = isAlighRight
        let items = subtitleDatas.map { data in
            let content = NSAttributedString(string: data.content, attributes: self.textAttributes)
            let info = self.getTextLayoutInfo(content)
            data.textHeight = info.height
            data.lineCount = info.count
            return SubtitleCellItem(content: content, height: info.height, numberOfLines: info.count)
        }
        update(with: items)
        speaker.lineCount = items.reduce(0, { partialResult, item in
            partialResult + item.numberOfLines
        })
    }

    func updateTextAttributes() {
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = Self.lineHeight
        style.maximumLineHeight = Self.lineHeight
        style.alignment = isAlignRight ? .right : .left
        style.lineBreakMode = .byWordWrapping
        let font = UIFont.systemFont(ofSize: 14)
        let offset = (Self.lineHeight - font.lineHeight) / 4.0
        let attributes: [NSAttributedString.Key: Any] = [.paragraphStyle: style, .baselineOffset: offset, .font: font, .foregroundColor: UIColor.ud.staticWhite]
        textAttributes = attributes
    }

    func getTextLayoutInfo(_ text: NSAttributedString) -> (height: CGFloat, count: Int) {
        let layout = LKTextLayoutEngineImpl()
        layout.attributedText = text
        layout.preferMaxWidth = contentWidth
        _ = layout.layout(size: CGSize(width: contentWidth, height: CGFloat.greatestFiniteMagnitude))
        let count = layout.lines.count
        let h = CGFloat(count) * Self.lineHeight
        return (h, count)
    }

    func update(with items: [SubtitleCellItem]) {
        self.items = items
        tableView.reloadData()
        DispatchQueue.main.async {
            self.scrollToBottomIfNeeded()
        }
    }

    func scrollToBottomIfNeeded() {
        let offset = max(0, tableView.contentSize.height - tableView.bounds.height)
        guard offset > tableView.contentOffset.y else { return }
        UIView.animate(withDuration: 0.1) {
            self.tableView.contentOffset = CGPoint(x: 0, y: offset)
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withType: SubtitleContentCell.self, for: indexPath)
        let item = items[indexPath.row]
        cell.label.attributedText = item.content
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        items[indexPath.row].height
    }
}

extension InMeetSubtitleItemView {

    class SubtitleContentCell: UITableViewCell {

        lazy var label: UILabel = {
            let label = UILabel()
            label.numberOfLines = 0
            label.font = .systemFont(ofSize: 14)
            label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            return label
        }()

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            backgroundColor = .clear
            contentView.addSubview(label)
            label.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    struct SubtitleCellItem {
        let content: NSAttributedString
        let height: CGFloat
        let numberOfLines: Int
    }
}
