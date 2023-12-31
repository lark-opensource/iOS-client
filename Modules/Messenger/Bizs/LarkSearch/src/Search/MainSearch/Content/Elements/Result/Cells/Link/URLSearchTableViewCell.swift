//
//  URLSearchTableViewCell.swift
//  LarkSearch
//
//  Created by SuPeng on 5/24/19.
//

import Foundation
import UIKit
import LarkCore
import LarkUIKit
import LarkAccountInterface
import LarkExtensions
import LarkInteraction
import LarkSearchCore
import LarkSDKInterface
import RustPB
import LarkListItem

final class URLSearchTableViewCell: UITableViewCell, SearchTableViewCellProtocol {

    private(set) var viewModel: SearchCellViewModel?
    private let avtarImageView = UIImageView()
    private let mainTitle = UILabel()
    private let urlLabel = UILabel()
    private let stackView = UIStackView()
    private let subLabel = UILabel()
    private let leftLine = UIView()
    private let bottomLabel = UILabel()
    private let goToMessageButton = UIButton()
    private let bgView = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectedBackgroundView = SearchCellSelectedView()
        bgView.backgroundColor = UIColor.clear
        bgView.layer.cornerRadius = 8
        bgView.clipsToBounds = true
        contentView.addSubview(bgView)
        bgView.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        goToMessageButton.setImage(Resources.goDoc.withRenderingMode(.alwaysTemplate), for: .normal)
        goToMessageButton.tintColor = UIColor.ud.iconN2
        bgView.addSubview(goToMessageButton)
        goToMessageButton.snp.makeConstraints { (make) in
            make.right.equalTo(-16)
            make.centerY.equalToSuperview()
        }
        goToMessageButton.addTarget(self, action: #selector(gotoMessageButtonDidClick), for: .touchUpInside)
        goToMessageButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        goToMessageButton.setContentHuggingPriority(.required, for: .horizontal)
        goToMessageButton.hitTestEdgeInsets = .init(top: -10, left: -10, bottom: -10, right: -10)

        avtarImageView.clipsToBounds = true
        avtarImageView.layer.cornerRadius = 24
        bgView.addSubview(avtarImageView)
        avtarImageView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 48, height: 48))
            make.top.equalTo(12)
            make.left.equalTo(16)
        }

        stackView.axis = .vertical
        stackView.alignment = .fill
        bgView.addSubview(stackView)
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
        bgView.addSubview(subLabel)
        subLabel.snp.makeConstraints { (make) in
            make.left.equalTo(27)
            make.right.equalTo(goToMessageButton.snp.left).offset(-19)
            make.top.equalTo(avtarImageView.snp.bottom).offset(8)
        }

        leftLine.backgroundColor = UIColor.ud.N200
        addSubview(leftLine)
        leftLine.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.top.equalTo(subLabel.snp.top)
            make.bottom.equalTo(subLabel.snp.bottom)
            make.width.equalTo(3)
        }

        bottomLabel.textColor = UIColor.ud.textPlaceholder
        bottomLabel.font = UIFont.systemFont(ofSize: 12)
        bgView.addSubview(bottomLabel)
        bottomLabel.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.top.equalTo(subLabel.snp.bottom).offset(8)
            make.right.lessThanOrEqualTo(goToMessageButton.snp.left).offset(-19)
            make.bottom.equalTo(-14)
        }

        let bottomLine = lu.addBottomBorder(leading: 16, trailing: -16)
        bottomLine.backgroundColor = UIColor.ud.lineDividerDefault

        if #available(iOS 13.4, *) {
            let pointer = PointerInteraction(
                style: .init(effect: .hover(prefersScaledContent: false))
            )
            self.addLKInteraction(pointer)
        }
    }

    required init?(coder aDecoder: NSCoder) {
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

    override func layoutSubviews() {
        var bottom = 1
        if needShowDividerStyle() {
            bottom = 13
        }
        let frame = self.contentView.frame.inset(by: UIEdgeInsets(top: 1, left: 6, bottom: CGFloat(bottom), right: 6))
        self.selectedBackgroundView?.frame = frame
        self.selectedBackgroundView?.layer.cornerRadius = 8
    }

    @objc
    private func gotoMessageButtonDidClick() {
        if let model = viewModel as? URLSearchViewModel, let from = controller {
            model.gotoChat(from: from)
        } else {
            assertionFailure("gotoMessageButtonDidClick model or fromVC nil")
        }
    }

    func set(viewModel: SearchCellViewModel, currentAccount: User?, searchText: String?) {
        self.viewModel = viewModel

        guard case let .link(searchMeta) = viewModel.searchResult.meta else { return }
        let searchResult = viewModel.searchResult

        avtarImageView.kf.setImage(with: URL(string: searchResult.imageURL), placeholder: Resources.url_link)
        var mainText = searchResult.title
        if mainText.length == 0 { mainText = .init(string: searchMeta.originalURL) }
        mainTitle.attributedText = mainText

        let urlText = searchMeta.originalURL
        if let searchText = searchText?.lowercased(), urlText.contains(searchText) {
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

        if needShowDividerStyle() {
            updateToPadStyle()
        } else {
            updateToMobobileStyle()
        }
    }

    private func needShowDividerStyle() -> Bool {
        if let support = viewModel?.supprtPadStyle() {
            return support
        }
        return false
    }

    private func updateToPadStyle() {
        self.backgroundColor = UIColor.ud.bgBase
        bgView.backgroundColor = UIColor.ud.bgBody
        bgView.snp.updateConstraints { make in
            make.bottom.equalToSuperview().offset(-12)
        }
    }

    private func updateToMobobileStyle() {
        self.backgroundColor = UIColor.ud.bgBody
        bgView.backgroundColor = UIColor.clear
        bgView.snp.updateConstraints { make in
            make.bottom.equalToSuperview()
        }
    }

    private func updateCellState(animated: Bool) {
        updateCellStyle(animated: animated)
        if needShowDividerStyle() {
            self.selectedBackgroundView?.backgroundColor = UIColor.clear
            updateCellStyleForPad(animated: animated, view: bgView)
        }
    }
}
