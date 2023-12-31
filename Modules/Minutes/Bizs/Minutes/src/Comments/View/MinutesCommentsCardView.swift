//
//  MinutesCommentsCardView.swift
//  Minutes
//
//  Created by yangyao on 2021/1/31.
//

import UIKit
import YYText
import UniverseDesignColor
import MinutesFoundation
import MinutesNetwork
import LarkContainer
import SnapKit
import UniverseDesignIcon

class MinutesCommentsCardView: UIView {
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = UIColor.ud.bgFloat
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(MinutesCommentsContentCell.self, forCellReuseIdentifier: MinutesCommentsContentCell.description())
        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
#if swift(>=5.5)
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
#endif
        return tableView
    }()

    var dataSource: [MinutesCommentsContentViewModel] = []

    lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.lineBreakMode = .byTruncatingTail
        label.textColor = UIColor.ud.textPlaceholder
        label.font = .systemFont(ofSize: 14)
        return label
    }()

    private lazy var tableHeaderInSection: UIView = {
        let frame = CGRect(x: 0, y: 0, width: bounds.width, height: 0)
        let tableHeader = UIView(frame: frame)
        tableHeader.backgroundColor = UIColor.ud.bgFloat
        let quoteImageView = UIImageView()
        quoteImageView.image = UIImage.dynamicIcon(.iconQuote, dimension: 14, color: UIColor.ud.textPlaceholder)
        let sep = UIView()
        sep.backgroundColor = UIColor.ud.lineDividerDefault

        tableHeader.addSubview(quoteImageView)
        tableHeader.addSubview(contentLabel)
        tableHeader.addSubview(sep)

        quoteImageView.frame = CGRect(x: 20, y: 20, width: 14, height: 14)
        contentLabel.frame = CGRect(x: quoteImageView.frame.maxX + 8, y: 0, width: frame.width - quoteImageView.frame.maxX - 8 - 20, height: 20)
        contentLabel.snp.makeConstraints { make in
            make.left.equalTo(36)
            make.right.equalTo(-8)
            make.centerY.equalTo(quoteImageView)
        }

        sep.frame = CGRect(x: 0, y: 52, width: frame.width, height: 0.5)
        return tableHeader
    }()

    lazy var indicatorView: UIActivityIndicatorView = {
        let indicatorView = UIActivityIndicatorView()
        indicatorView.transform = CGAffineTransform(scaleX: 0.86, y: 0.86)
        if #available(iOS 12.0, *) {
            if self.traitCollection.userInterfaceStyle == .dark {
                indicatorView.style = .white
            } else {
                indicatorView.style = .gray
            }
        } else {
            indicatorView.style = .gray
        }
        return indicatorView
    }()

    lazy var commentsView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloatOverlay

        let sep = UIView()
        sep.backgroundColor = UIColor.ud.bgFloatOverlay
        view.addSubview(sep)
        view.addSubview(inputTextView)
        view.addSubview(sendButton)
        view.addSubview(countOverflowLabel)
        view.addSubview(indicatorView)

        sep.snp.makeConstraints { (maker) in
            maker.top.left.right.equalToSuperview()
            maker.height.equalTo(0.5)
        }
        inputTextView.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.left.equalToSuperview().offset(20)
        }
        sendButton.sizeToFit()
        sendButton.snp.makeConstraints { (maker) in
            maker.left.equalTo(inputTextView.snp.right).offset(15)
            maker.right.equalToSuperview().offset(-20)
            maker.top.equalToSuperview().offset(13)
            maker.bottom.equalToSuperview().offset(-13)
            maker.width.equalTo(sendButton.bounds.width)
        }
        indicatorView.snp.makeConstraints { (maker) in
            maker.centerX.centerY.equalTo(sendButton)
        }
        countOverflowLabel.snp.makeConstraints { (maker) in
            maker.centerX.centerY.equalTo(sendButton)
        }

        let maskButton = UIButton()
        maskButton.addTarget(self, action: #selector(presentAddCommentsView), for: .touchUpInside)
        view.addSubview(maskButton)
        maskButton.snp.makeConstraints { (maker) in
            maker.edges.equalTo(inputTextView)
        }

        return view
    }()

    lazy var inputTextView: YYTextView = {
        let textView = YYTextView()
        textView.font = .systemFont(ofSize: 16)
        textView.allowsCopyAttributedString = false
        // placeholder 位置不准
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)
        textView.placeholderFont = .systemFont(ofSize: 16)
        textView.placeholderText = BundleI18n.Minutes.MMWeb_G_AddComment
        textView.textColor = UIColor.ud.textTitle
        textView.placeholderTextColor = UIColor.ud.textDisable
        textView.delegate = self
        textView.isEditable = false
        return textView
    }()

    lazy var sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(BundleI18n.Minutes.MMWeb_G_CommentSend, for: .normal)
        button.addTarget(self, action: #selector(onBtnSend), for: .touchUpInside)
        button.titleLabel?.textColor = UIColor.ud.colorfulPurple
        button.isUserInteractionEnabled = false
        button.alpha = 0.3
        return button
    }()

    lazy var countOverflowLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.colorfulRed
        label.font = .systemFont(ofSize: 16)
        label.isHidden = true
        return label
    }()

    var sendCommentsBlock: (() -> Void)?
    var addCommentsActionBlock: (() -> Void)?
    var didSelectAavtarBlock: ((String) -> Void)?
    var textLongTapBlock: ((CommentContent, NSAttributedString, CGPoint) -> Void)?
    var imageLongTapBlock: ((CommentContent, CGPoint) -> Void)?
    var textTapBlock: ((String) -> Void)?
    var linkTapBlock: ((String) -> Void)?
    var imageTapBlock: (([ContentForIMItem], Int) -> Void)?

    @objc func onBtnSend() {
        sendCommentsBlock?()
    }

    func getText() -> String {
        return inputTextView.text
    }

    func fillText(_ text: String) {
        inputTextView.text = text

        if text.count > MinutesAddCommentsView.minutesCommentMaxCount {
            sendButton.isHidden = true
            countOverflowLabel.isHidden = false

            let newCount = text.count - MinutesAddCommentsView.minutesCommentMaxCount
            countOverflowLabel.text = "-\(newCount.formatUsingAbbreviation())"
        } else {
            sendButton.isHidden = false
            countOverflowLabel.isHidden = true

            countOverflowLabel.text = nil
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        layer.cornerRadius = 12
        layer.masksToBounds = true
        backgroundColor = UIColor.ud.bgFloat
        addSubview(tableView)
        addSubview(commentsView)
        tableView.snp.makeConstraints { (maker) in
            maker.left.right.top.equalToSuperview()
            maker.bottom.equalTo(commentsView.snp.top)
        }
        commentsView.snp.makeConstraints { (maker) in
            maker.left.right.bottom.equalToSuperview()
            maker.height.equalTo(52)
        }
    }

    func showLoading(_ show: Bool) {
        sendButton.isHidden = show
        indicatorView.isHidden = !show
        if show {
            indicatorView.startAnimating()
        } else {
            indicatorView.stopAnimating()
        }
    }

    func configure(resolver: UserResolver, contentWidth: CGFloat, comment: Comment, originalComment: Comment? = nil, isInTranslationMode: Bool) {
        dataSource.removeAll()

        for (idx, content) in comment.contents.enumerated() {
            var originalContent: CommentContent?
            if originalComment?.contents.indices.contains(idx) == true {
                originalContent = originalComment?.contents[idx]
            }
            let vm = MinutesCommentsContentViewModelFactory.build(resolver: resolver, contentWidth: contentWidth, isInTranslationMode: isInTranslationMode, content: content, originalContent: isInTranslationMode ? originalContent : nil)
            dataSource.append(vm)
        }

        contentLabel.text = comment.quote
        commentsView.isHidden = isInTranslationMode

        if isInTranslationMode {
            tableView.snp.remakeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
        } else {
            tableView.snp.remakeConstraints { (maker) in
                maker.left.right.top.equalToSuperview()
                maker.bottom.equalTo(commentsView.snp.top)
            }
        }
        tableView.reloadData()
    }

    @objc func presentAddCommentsView() {
        addCommentsActionBlock?()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MinutesCommentsCardView: YYTextViewDelegate {
    func textViewDidChange(_ textView: YYTextView) {
        let text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        sendButton.isUserInteractionEnabled = !text.isEmpty
        sendButton.alpha = !text.isEmpty ? 1.0 : 0.3
    }
}

extension MinutesCommentsCardView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return dataSource[indexPath.row].cellHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let userID = dataSource[indexPath.row].userID
        didSelectAavtarBlock?(userID)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableHeaderInSection
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 56
    }
}

extension MinutesCommentsCardView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MinutesCommentsContentCell.description(), for: indexPath) as? MinutesCommentsContentCell else {
            return UITableViewCell()
        }
        cell.selectionStyle = .none
        let commentsContentVM = dataSource[indexPath.row]
        cell.configure(commentsContentVM)
        cell.setSeperateLineHidden(indexPath.row == dataSource.count - 1)
        cell.textLongTapBlock = { [weak self, weak cell] in
            guard let self = self, let weakCell = cell else { return }
            let point =
                weakCell.contentView.convert(CGPoint(x: 0, y: weakCell.contentTextView.frame.origin.y), to: self)
            self.textLongTapBlock?(commentsContentVM.commentContent, commentsContentVM.getAttributedText(), point)
        }
        cell.imageLongTapBlock = { [weak self, weak cell] in
            guard let self = self, let weakCell = cell else { return }
            let point =
                weakCell.contentView.convert(CGPoint(x: 0, y: weakCell.contentTextView.frame.origin.y), to: self)
            self.imageLongTapBlock?(commentsContentVM.commentContent, point)
        }
        
        cell.textTapBlock = { [weak self] userID in
            guard let self = self else { return }
            self.textTapBlock?(userID)
        }
        cell.linkTapBlock = { [weak self] url in
            guard let self = self else { return }
            self.linkTapBlock?(url)
        }
        cell.imageTapBlock = { [weak self] imageItems, fromIndex in
            guard let self = self else { return }
            self.imageTapBlock?(imageItems, fromIndex)
        }
        return cell
    }
}
