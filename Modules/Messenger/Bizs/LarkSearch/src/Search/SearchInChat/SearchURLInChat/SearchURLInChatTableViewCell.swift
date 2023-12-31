//
//  SearchURLInChatViewController.swift
//  LarkSearch
//
//  Created by SuPeng on 5/28/19.
//

import UIKit
import Foundation
import LarkUIKit
import EENavigator
import LarkExtensions
import LarkSDKInterface
import LarkSearchCore
import RustPB
import LarkListItem

final class SearchURLInChatTableViewCell: UITableViewCell, BaseSearchInChatTableViewCellProtocol {

    private(set) var viewModel: SearchInChatCellViewModel?

    private let avtarImageView = UIImageView()
    private let mainTitle = UILabel()
    private let urlLabel = UILabel()
    private let stackView = UIStackView()
    private let subLabel = UILabel()
    private let leftLine = UIView()
    private let bottomLabel = UILabel()
    private let goToMessageButton = UIButton()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectedBackgroundView = SearchCellSelectedView()
        self.backgroundColor = UIColor.ud.bgBody

        goToMessageButton.setImage(Resources.goDoc.withRenderingMode(.alwaysTemplate), for: .normal)
        goToMessageButton.tintColor = UIColor.ud.iconN2
        contentView.addSubview(goToMessageButton)
        goToMessageButton.snp.makeConstraints { (make) in
            make.right.equalTo(-16)
            make.centerY.equalToSuperview()
        }
        goToMessageButton.addTarget(self, action: #selector(gotoMessageButtonDidClick), for: .touchUpInside)
        goToMessageButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        goToMessageButton.setContentHuggingPriority(.required, for: .horizontal)

        avtarImageView.clipsToBounds = true
        avtarImageView.layer.cornerRadius = 24
        contentView.addSubview(avtarImageView)
        avtarImageView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 48, height: 48))
            make.top.equalTo(12)
            make.left.equalTo(16)
        }

        stackView.axis = .vertical
        stackView.alignment = .fill
        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { (make) in
            make.left.equalTo(avtarImageView.snp.right).offset(12)
            make.centerY.equalTo(avtarImageView)
            make.right.lessThanOrEqualTo(goToMessageButton.snp.left).offset(-19)
        }

        mainTitle.textColor = UIColor.ud.textTitle
        mainTitle.font = UIFont.systemFont(ofSize: 16)
        stackView.addArrangedSubview(mainTitle)

        urlLabel.textColor = UIColor.ud.textPlaceholder
        urlLabel.font = UIFont.systemFont(ofSize: 14)
        stackView.addArrangedSubview(urlLabel)

        subLabel.textColor = UIColor.ud.textPlaceholder
        subLabel.font = UIFont.systemFont(ofSize: 14)
        subLabel.numberOfLines = 2
        contentView.addSubview(subLabel)
        subLabel.snp.makeConstraints { (make) in
            make.left.equalTo(27)
            make.right.equalTo(goToMessageButton.snp.left).offset(-19)
            make.top.equalTo(avtarImageView.snp.bottom).offset(8)
        }

        leftLine.backgroundColor = UIColor.ud.fillTag
        addSubview(leftLine)
        leftLine.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.top.equalTo(subLabel.snp.top)
            make.bottom.equalTo(subLabel.snp.bottom)
            make.width.equalTo(3)
        }

        bottomLabel.textColor = UIColor.ud.textPlaceholder
        bottomLabel.font = UIFont.systemFont(ofSize: 12)
        contentView.addSubview(bottomLabel)
        bottomLabel.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.top.equalTo(subLabel.snp.bottom).offset(8)
            make.right.lessThanOrEqualTo(goToMessageButton.snp.left).offset(-19)
            make.bottom.equalTo(-14)
        }

        let bottomLine = lu.addBottomBorder(leading: 16, trailing: -16)
        bottomLine.backgroundColor = UIColor.ud.lineDividerDefault
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        let frame = self.contentView.frame.inset(by: UIEdgeInsets(top: 1, left: 6, bottom: 1, right: 6))
        self.selectedBackgroundView?.frame = frame
        self.selectedBackgroundView?.layer.cornerRadius = 8
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        updateCellStyle(animated: animated)
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        updateCellStyle(animated: animated)
    }

    @objc
    private func gotoMessageButtonDidClick() {
        viewModel?.gotoChat()
    }

    func update(viewModel: SearchInChatCellViewModel, currentSearchText: String) {
        self.viewModel = viewModel

        guard let searchResult = viewModel.data, case let .link(searchMeta) = searchResult.meta else { return }

        avtarImageView.kf.setImage(with: URL(string: searchResult.imageURL), placeholder: Resources.url_link)
        var mainText = searchResult.title
        if mainText.length == 0 { mainText = .init(string: searchMeta.originalURL) }
        mainTitle.attributedText = mainText

        let urlText = searchMeta.originalURL
        let searchText = currentSearchText.lowercased()
        if urlText.contains(searchText) {
            urlLabel.attributedText = SearchResult.attributedText(
                attributedString: NSAttributedString(string: urlText),
                withHitTerms: [searchText],
                highlightColor: UIColor.ud.textLinkNormal)
            urlLabel.isHidden = (urlLabel.text ?? "").isEmpty
        } else {
            urlLabel.isHidden = true
        }
        subLabel.attributedText = searchResult.summary
        if (subLabel.text ?? "").isEmpty {
            subLabel.isHidden = true
            leftLine.isHidden = true
            bottomLabel.snp.remakeConstraints { (make) in
                make.left.equalTo(16)
                make.top.equalTo(avtarImageView.snp.bottom).offset(8)
                make.right.lessThanOrEqualToSuperview().offset(-35)
                make.bottom.equalTo(-14)
            }
        } else {
            subLabel.isHidden = false
            leftLine.isHidden = false
            bottomLabel.snp.remakeConstraints { (make) in
                make.left.equalTo(16)
                make.top.equalTo(subLabel.snp.bottom).offset(8)
                make.right.lessThanOrEqualToSuperview().offset(-35)
                make.bottom.equalTo(-14)
            }
        }
        bottomLabel.attributedText = Search_V2_ExtraInfoBlock.mergeExtraInfoBlocks(blocks: searchResult.extraInfos, separator: searchResult.extraInfoSeparator)
    }
}
