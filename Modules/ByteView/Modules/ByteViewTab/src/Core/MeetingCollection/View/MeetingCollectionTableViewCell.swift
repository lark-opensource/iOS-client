//
//  MeetingCollectionTableViewCell.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2022/6/8.
//

import Foundation
import ByteViewCommon

class MeetingCollectionTableViewCell: MeetTabHistoryTableViewCell {

    static let cellIdentifier = String(describing: MeetingCollectionTableViewCell.self)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        previewView.snp.remakeConstraints {
            if traitCollection.isRegular {
                $0.width.equalTo(108.0)
                $0.height.equalTo(60.0)
                $0.top.bottom.equalToSuperview().inset(14.0)
            } else {
                $0.width.equalTo(100.0)
                $0.height.equalTo(56.0)
                $0.top.bottom.equalToSuperview().inset(10.0)
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func bindTo(viewModel: MeetTabCellViewModel) {
        super.bindTo(viewModel: viewModel)
        collectionTagView.isHidden = true
        collectionPadTagView.isHidden = true
        tagLinedView?.isHidden = true
        previewView.iconDimension = 28.0
    }

    override func updateCompactLayout() {
        super.updateCompactLayout()
        containerView.snp.remakeConstraints {
            $0.top.bottom.equalToSuperview().inset(13.0)
        }
        descStackViewTopConstaint?.update(offset: 8.0)
    }

    override func updateRegularLayout() {
        super.updateRegularLayout()
        paddingContainerView.snp.remakeConstraints {
            $0.top.equalToSuperview()
            $0.left.right.equalToSuperview().inset(48.0)
            $0.bottom.lessThanOrEqualToSuperview()
        }
    }
}
