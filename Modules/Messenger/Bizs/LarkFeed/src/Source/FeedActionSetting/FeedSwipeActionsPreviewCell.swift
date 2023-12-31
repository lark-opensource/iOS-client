//
//  FeedSwipeActionsPreviewCell.swift
//  LarkFeed
//
//  Created by ByteDance on 2023/11/7.
//

import Foundation
import RxSwift
import UniverseDesignIcon
import UniverseDesignFont

class FeedSwipeActionsPreviewCell: UITableViewCell {
    private struct Layout {
        static let titleFont = 16.0
        static let detailFont = 14.0
        static let horizontalMargin = 16.0
        static let verticalMargin = 4.0
        static let arrowSize = 12.0
        static let arrowTop = 28.0
        static let tipsViewheight = 74.0
        static let detailHeight = 18.0
        static let detailBottom = 10.0
        static let titleTop = 10.0
        static let titleHeight = 22.0
    }
    var didClick: ((FeedSwipeOrientationViewModel) -> Void)?
    private var viewModel: FeedSwipeOrientationViewModel?
    private let disposeBag = DisposeBag()
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UDFont.systemFont(ofSize: Layout.titleFont, weight: .regular)
        return label
    }()
    private lazy var detailLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.font = UDFont.systemFont(ofSize: Layout.detailFont, weight: .regular)
        label.numberOfLines = 0
        return label

    }()
    private lazy var arrowImageView: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.rightBoldOutlined.withRenderingMode(.alwaysTemplate)
        view.tintColor = UIColor.ud.iconN3
        return view
    }()
    private var tipsView = FeedSwipeActionPreviewView()

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        setupViews()
    }

    func configCell(_ viewModel: FeedSwipeOrientationViewModel) {
        self.viewModel = viewModel
        titleLabel.text = viewModel.title
        detailLabel.text = viewModel.detailText
        if viewModel.notSet {
            detailLabel.snp.remakeConstraints { (make) in
                make.leading.equalToSuperview().offset(Layout.horizontalMargin)
                make.trailing.equalTo(arrowImageView.snp.leading).offset(-Layout.verticalMargin)
                make.top.equalTo(titleLabel.snp.bottom).offset(Layout.verticalMargin)
                make.height.equalTo(Layout.detailHeight)
                make.bottom.equalTo(-Layout.detailBottom)
            }
            arrowImageView.snp.remakeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.size.equalTo(CGSize(width: Layout.arrowSize, height: Layout.arrowSize))
                make.right.equalTo(-Layout.horizontalMargin)
            }
            tipsView.isHidden = true
        } else {
            detailLabel.snp.remakeConstraints { (make) in
                make.leading.equalToSuperview().offset(Layout.horizontalMargin)
                make.trailing.equalTo(arrowImageView.snp.leading).offset(-Layout.verticalMargin)
                make.top.equalTo(titleLabel.snp.bottom).offset(Layout.verticalMargin)
            }
            tipsView.snp.remakeConstraints { (make) in
                make.leading.trailing.equalToSuperview().inset(Layout.horizontalMargin)
                make.top.equalTo(detailLabel.snp.bottom).offset(Layout.detailBottom)
                make.height.equalTo(Layout.tipsViewheight)
                make.bottom.equalTo(-Layout.horizontalMargin)
            }
            arrowImageView.snp.remakeConstraints { (make) in
                make.top.equalTo(Layout.arrowTop)
                make.size.equalTo(CGSize(width: Layout.arrowSize, height: Layout.arrowSize))
                make.right.equalTo(-Layout.horizontalMargin)
            }
            tipsView.isHidden = false
            tipsView.setActionsAndLayoutView(orientation: viewModel.orientation, actions: viewModel.actions)
        }
    }
    private func setupViews() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(detailLabel)
        contentView.addSubview(arrowImageView)
        contentView.addSubview(tipsView)

        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(Layout.horizontalMargin)
            make.top.equalTo(Layout.titleTop)
            make.right.lessThanOrEqualToSuperview()
            make.height.equalTo(Layout.titleHeight)
        }

        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didClickCell)))
        contentView.backgroundColor = UIColor.ud.bgFloat
    }

    @objc
    private func didClickCell() {
        guard let vm = viewModel else { return }
        didClick?(vm)
    }
}
