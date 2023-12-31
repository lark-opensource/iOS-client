//
//  SearchTableViewCell.swift
//  Lark
//
//  Created by 刘晚林 on 2017/3/24.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkModel
import LarkCore
import SnapKit
import LarkUIKit
import LarkTag
import LarkAccountInterface
import EETroubleKiller
import LarkListItem
import LarkInteraction
import LarkSDKInterface
import LarkSearchCore
import RustPB

class SearchNewDefaultTableViewCell: UITableViewCell, SearchTableViewCellProtocol {

    private(set) var viewModel: SearchCellViewModel?
    let infoView = SearchResultDefaultView()
    let bgView = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectedBackgroundView = SearchCellSelectedView()
        self.backgroundColor = UIColor.ud.bgBody

        let containerGuide = UILayoutGuide()
        contentView.addLayoutGuide(containerGuide)
        containerGuide.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        contentView.addSubview(bgView)
        bgView.backgroundColor = UIColor.clear
        bgView.layer.cornerRadius = 8
        bgView.clipsToBounds = true
        bgView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        bgView.addSubview(infoView)
        infoView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(13)
            make.right.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-12)
        }

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

    private func updateCellState(animated: Bool) {
        updateCellStyle(animated: animated)
        if needShowDividerStyle() {
            self.selectedBackgroundView?.backgroundColor = UIColor.clear
            updateCellStyleForPad(animated: animated, view: bgView)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        infoView.restoreViewsContent()
    }

    func set(viewModel: SearchCellViewModel, currentAccount: User?, searchText: String?) {
        infoView.restoreViewsContent()
        self.viewModel = viewModel
        let searchResult = viewModel.searchResult
        //默认头像 + 默认title + 默认描述
        infoView.avatarView.setAvatarByIdentifier(viewModel.avatarID, avatarKey: searchResult.avatarKey, avatarViewParams: .init(sizeType: .size(SearchResultDefaultView.searchAvatarImageDefaultSize)))
        infoView.avatarView.isHidden = false

        infoView.nameStatusView.nameLabel.attributedText = searchResult.title

        if searchResult.summary.length > 0 {
            infoView.firstDescriptionLabel.attributedText = searchResult.summary
            infoView.firstDescriptionLabel.isHidden = false
        }
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

    override func layoutSubviews() {
        var bottom = 1
        if needShowDividerStyle() {
            bottom = 13
        }
        let frame = self.contentView.frame.inset(by: UIEdgeInsets(top: 1, left: 6, bottom: CGFloat(bottom), right: 6))
        self.selectedBackgroundView?.frame = frame
        self.selectedBackgroundView?.layer.cornerRadius = 8
    }

    func cellWillDisplay() { }
}

// MARK: - EETroubleKiller
extension SearchNewDefaultTableViewCell: CaptureProtocol & DomainProtocol {

    public var isLeaf: Bool {
        return true
    }

    public var domainKey: [String: String] {
        var tkDescription: [String: String] = [:]
        tkDescription["type"] = "\(self.viewModel?.searchResult.type ?? .unknown)"
        tkDescription["cid"] = "\(self.viewModel?.searchResult.contextID ?? "")"
        return tkDescription
    }
}
