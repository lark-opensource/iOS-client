//
//  SearchFilterView.swift
//  LarkSearch
//
//  Created by SuPeng on 4/18/19.
//

import UIKit
import Foundation
import LarkModel
import LarkSDKInterface

public protocol SearchFilterViewDelegate: AnyObject {
    func filterViewDidClick(_ filterView: SearchFilterView)
}

public final class SearchFilterView: UIView {
    public struct AvatarInfo: Equatable {
        public let avatarKey: String
        public let avatarID: String
    }
    public weak var delegate: SearchFilterViewDelegate?
    public private(set) var filter: SearchFilter

    private let stackView = UIStackView()
    private let label = UILabel()
    private let avatarStackView = RoundAvatarStackView(avatarViews: [])

    public init(filter: SearchFilter) {
        self.filter = filter
        super.init(frame: .zero)

        defer {
            set(filter: filter)
        }

        clipsToBounds = true
        layer.cornerRadius = 4

        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 2
        addSubview(stackView)
        stackView.snp.makeConstraints { (make) in
            make.left.equalTo(12)
            make.right.equalTo(-12)
            make.top.equalTo(6)
            make.bottom.equalTo(-6)
        }

        label.font = UIFont.systemFont(ofSize: 16)
        stackView.addArrangedSubview(label)

        stackView.addArrangedSubview(avatarStackView)

        lu.addTapGestureRecognizer(action: #selector(filterDidClick), target: self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func set(filter: SearchFilter) {
        self.filter = filter

        label.text = filter.title

        if let avatarViews = filter.getAvatarViews() {
            avatarStackView.set(avatarViews)
        }
        avatarStackView.isHidden = avatarStackView.avatarViews.isEmpty
        if filter.isEmpty {
            label.textColor = UIColor.ud.textTitle
            backgroundColor = UIColor.ud.bgFloatOverlay
            layer.borderWidth = 1
            layer.ud.setBorderColor(UIColor.ud.lineDividerDefault)
        } else {
            label.textColor = UIColor.ud.primaryContentDefault
            backgroundColor = UIColor.ud.functionInfoFillSolid02
            layer.borderWidth = 0
            layer.borderColor = UIColor.clear.cgColor
        }
    }

    @objc
    private func filterDidClick() {
        delegate?.filterViewDidClick(self)
    }
}
