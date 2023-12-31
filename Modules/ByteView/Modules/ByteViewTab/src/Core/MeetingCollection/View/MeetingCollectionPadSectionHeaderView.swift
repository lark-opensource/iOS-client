//
//  MeetingCollectionPadSectionHeaderView.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2022/6/9.
//

import Foundation

class MeetingCollectionPadSectionHeaderView: MeetTabPadSectionHeaderView {
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        backgroundView = UIView()
        backgroundView?.backgroundColor = .clear
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        paddingView.backgroundColor = .clear
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        paddingView.snp.remakeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.left.right.equalToSuperview().inset(48.0)
        }
    }
}
