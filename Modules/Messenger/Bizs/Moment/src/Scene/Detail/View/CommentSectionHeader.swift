//
//  CommentSectionHeader.swift
//  Moment
//
//  Created by zc09v on 2021/1/12.
//

import Foundation
import UIKit
import LarkUIKit

protocol CommentSectionHeaderDelegate: AnyObject {
    func noDataTipClick()
}

final class CommentSectionHeader: UITableViewHeaderFooterView {
    enum Cons {
        static var titleFont: UIFont { return UIFont.ud.title3 }
        static var titleColor: UIColor { return UIColor.ud.textTitle }
        static var headerHeight: CGFloat { return titleFont.pointSize + 33 }
    }

    weak var delegate: CommentSectionHeaderDelegate?
    private let noDataTipBack: UIView = UIView(frame: .zero)
    private let tipLabel: UILabel = UILabel(frame: .zero)

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        let backgroudView = UIView(frame: .zero)
        backgroudView.backgroundColor = UIColor.ud.bgBase
        self.addSubview(backgroudView)
        backgroudView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        let whiteBack = UIView(frame: .zero)
        whiteBack.backgroundColor = UIColor.ud.bgBody
        self.addSubview(whiteBack)
        whiteBack.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(8)
            make.height.equalTo(48)
        }

        tipLabel.font = Cons.titleFont
        tipLabel.textColor = Cons.titleColor
        whiteBack.addSubview(tipLabel)
        tipLabel.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.centerY.equalToSuperview()
        }

        noDataTipBack.backgroundColor = UIColor.ud.bgBody
        noDataTipBack.isHidden = true
        self.addSubview(noDataTipBack)
        noDataTipBack.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(whiteBack.snp.bottom)
            make.height.equalTo(120)
        }

        let noDataTipLabel = UILabel(frame: .zero)
        noDataTipLabel.text = BundleI18n.Moment.Lark_Community_NoCommentClickToReply
        noDataTipLabel.font = UIFont.systemFont(ofSize: 16)
        noDataTipLabel.textColor = UIColor.ud.textPlaceholder
        noDataTipLabel.numberOfLines = 0
        noDataTipLabel.textAlignment = .center
        noDataTipBack.addSubview(noDataTipLabel)
        noDataTipLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(40)
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(noDataTipLabelTap))
        noDataTipBack.addGestureRecognizer(tap)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateRepliesTip(_ repliesCount: Int, text: String, showNoDataTip: Bool) {
        self.tipLabel.text = text
        noDataTipBack.isHidden = !showNoDataTip
    }

    @objc
    func noDataTipLabelTap() {
        self.delegate?.noDataTipClick()
    }

    override var frame: CGRect {
        didSet {
            if Display.pad {
                super.frame = MomentsViewAdapterViewController.computeCellFrame(originFrame: frame)
            }
        }
    }
}
