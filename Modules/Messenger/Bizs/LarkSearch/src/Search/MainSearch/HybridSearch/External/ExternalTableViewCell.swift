//
//  ExternalTableViewCell.swift
//
//
//  Created by SuPeng on 7/22/19.
//

import Foundation
import UIKit
import LarkModel
import LarkCore
import LarkUIKit
import Kingfisher
import LarkAccountInterface
import LarkExtensions
import LarkInteraction
import LarkSearchCore

final class ExternalTableViewCell: UITableViewCell, SearchTableViewCellProtocol {
    var viewModel: SearchCellViewModel?

    private let hStack = UIStackView()
    private let avatarView = UIImageView()
    private let vStack = UIStackView()
    private let mainTitle = UILabel()
    private let subTitle = UILabel()
    private let bottomStackView = UIStackView()
    private let spacer = UIView()
    private let dateLabel = UILabel()
    private let sourceLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectedBackgroundView = SearchCellSelectedView()
        self.backgroundColor = UIColor.ud.bgBody

        hStack.axis = .horizontal
        hStack.alignment = .top
        hStack.distribution = .fill
        hStack.spacing = 10.5
        hStack.setContentHuggingPriority(.required, for: .horizontal)
        hStack.setContentCompressionResistancePriority(.required, for: .horizontal)
        hStack.setContentHuggingPriority(.required, for: .vertical)
        hStack.setContentCompressionResistancePriority(.required, for: .vertical)
        contentView.addSubview(hStack)
        hStack.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.top.equalTo(8)
            make.bottom.equalTo(-8)
        }

        avatarView.layer.cornerRadius = 24
        avatarView.layer.masksToBounds = true
        avatarView.setContentHuggingPriority(.required, for: .horizontal)
        avatarView.setContentCompressionResistancePriority(.required, for: .horizontal)
        hStack.addArrangedSubview(avatarView)
        avatarView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 48, height: 48))
        }

        vStack.axis = .vertical
        vStack.alignment = .leading
        vStack.distribution = .fill
        vStack.spacing = 0
        hStack.addArrangedSubview(vStack)

        mainTitle.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        mainTitle.textColor = UIColor.ud.textTitle
        mainTitle.snp.makeConstraints { (make) in
            make.height.equalTo(24)
        }
        vStack.addArrangedSubview(mainTitle)

        subTitle.font = UIFont.systemFont(ofSize: 14)
        subTitle.numberOfLines = 2
        subTitle.textColor = UIColor.ud.textTitle
        vStack.addArrangedSubview(subTitle)

        spacer.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 1, height: 2))
        }
        vStack.addArrangedSubview(spacer)

        bottomStackView.axis = .horizontal
        bottomStackView.spacing = 5
        vStack.addArrangedSubview(bottomStackView)

        dateLabel.textColor = UIColor.ud.textPlaceholder
        dateLabel.font = UIFont.systemFont(ofSize: 12)
        bottomStackView.addArrangedSubview(dateLabel)

        sourceLabel.textColor = UIColor.ud.textPlaceholder
        sourceLabel.font = UIFont.systemFont(ofSize: 12)
        bottomStackView.addArrangedSubview(sourceLabel)

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
        updateCellStyle(animated: animated)
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        updateCellStyle(animated: animated)
    }

    func set(viewModel: SearchCellViewModel, currentAccount: User?, searchText: String?) {
        set(viewModel: viewModel)
    }

    func set(viewModel: SearchCellViewModel) {
        self.viewModel = viewModel
        guard case let .external(meta) = viewModel.searchResult.meta else { return }
        let searchResult = viewModel.searchResult
        if searchResult.imageURL.isEmpty {
            avatarView.isHidden = true
        } else {
            avatarView.isHidden = false
            avatarView.kf.setImage(with: URL(string: searchResult.imageURL))
        }

        mainTitle.attributedText = searchResult.title

        let summary = searchResult.summary
        if summary.length > 0 {
            subTitle.attributedText = summary
            subTitle.isHidden = false
        } else {
            subTitle.isHidden = true
        }

        if !meta.source.isEmpty || (meta.hasUpdateTime && meta.updateTime != 0) {
            bottomStackView.isHidden = false
            spacer.isHidden = false
            if meta.hasUpdateTime, meta.updateTime != 0 {
                dateLabel.text = Date.lf.getNiceDateString(TimeInterval(meta.updateTime))
                dateLabel.isHidden = false
            } else {
                dateLabel.isHidden = true
            }

            if !meta.source.isEmpty {
                sourceLabel.text = meta.source
                sourceLabel.isHidden = false
            } else {
                sourceLabel.isHidden = true
            }
        } else {
            spacer.isHidden = true
            bottomStackView.isHidden = true
        }
    }
}
