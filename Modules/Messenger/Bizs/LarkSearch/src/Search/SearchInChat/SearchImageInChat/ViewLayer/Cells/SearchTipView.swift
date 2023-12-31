//
//  SearchTipView.swift
//  LarkSearch
//
//  Created by ByteDance on 2023/2/20.
//
import UIKit
import Foundation
import SnapKit
import LarkCore
import UniverseDesignIcon
import UniverseDesignEmpty
/// 提示“已经展示全部数据”
class ShowAllColdDataTipView: UICollectionReusableView {
    private lazy var showAllDataTip: UILabel = {
        var label = UILabel()

        label.attributedText = NSAttributedString(
            string: BundleI18n.LarkSearch.Lark_ASLSearch_ComprehensiveSearch_MsgTab_AllSearchResultsAreShown,
            attributes: [
                .foregroundColor: UIColor.ud.textCaption,
                .font: UIFont.systemFont(ofSize: 12)
            ]
        )
        return label
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)
        let layoutGuide = UILayoutGuide()
        self.addLayoutGuide(layoutGuide)
        layoutGuide.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.height.equalTo(67).priority(.high)
        }
        self.addSubview(showAllDataTip)
        showAllDataTip.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.centerX.equalToSuperview()
            $0.right.lessThanOrEqualToSuperview().offset(40)
            $0.left.greaterThanOrEqualToSuperview().offset(40)
            $0.bottom.lessThanOrEqualToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
/// 提示“已展示一年内消息，点击查看更多”
class ShowAllHotDataTipView: UICollectionReusableView {
    var buttonTappedHandler: (() -> Void)?
    private let showHotDataTipView = UIView()
    private let showMoreIcon = UIImageView()
    private let showMoreText = {
        var showMore = UITextView()
        showMore.backgroundColor = UIColor.clear
        showMore.attributedText = NSAttributedString(
            string: BundleI18n.LarkSearch.Lark_ASLSearch_SearchInChat_MsgTab_ViewMoreMsgFromOverAYearAgo,
            attributes: [
                .foregroundColor: UIColor.ud.primaryContentDefault,
                .font: UIFont.systemFont(ofSize: 12)
            ]
        )
        showMore.isScrollEnabled = false
        showMore.isEditable = false
        showMore.isUserInteractionEnabled = false
        showMore.textAlignment = .center
        showMore.textContainerInset = .zero
        showMore.textContainer.lineFragmentPadding = 0.0
        return showMore
    }()

    func startAnimation() {
        let activityIndicator = UIActivityIndicatorView(style: .gray)
        activityIndicator.startAnimating()
        self.addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        let layoutGuide = UILayoutGuide()
        self.addLayoutGuide(layoutGuide)
        layoutGuide.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.height.equalTo(67).priority(.high)
        }
        showHotDataTipView.isUserInteractionEnabled = false
        self.addSubview(showHotDataTipView)
        showHotDataTipView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.centerX.equalToSuperview()
            $0.right.lessThanOrEqualToSuperview().offset(-40)
            $0.left.greaterThanOrEqualToSuperview().offset(40)
            $0.bottom.lessThanOrEqualToSuperview()
        }
        showMoreIcon.image = UDIcon.getIconByKey(.downExpandOutlined, size: CGSize(width: 14, height: 14)).ud.withTintColor(.ud.primaryContentDefault)
        showHotDataTipView.addSubview(showMoreIcon)
        showHotDataTipView.addSubview(showMoreText)
        showMoreIcon.setContentHuggingPriority(.required, for: .horizontal)
        showMoreIcon.setContentCompressionResistancePriority(.required, for: .horizontal)
        showMoreText.setContentHuggingPriority(.defaultLow, for: .horizontal)
        showMoreText.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        showMoreIcon.snp.makeConstraints {
            $0.left.equalToSuperview()
            $0.bottom.lessThanOrEqualToSuperview()
            $0.top.greaterThanOrEqualToSuperview()
            $0.centerY.equalTo(showMoreText.snp.centerY)
        }
        showMoreText.snp.makeConstraints {
            $0.top.greaterThanOrEqualToSuperview()
            $0.right.equalToSuperview()
            $0.left.equalTo(showMoreIcon.snp.right).offset(4)
            $0.bottom.lessThanOrEqualToSuperview()
        }
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.addGestureRecognizer(tapGesture)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func handleTap() {
        buttonTappedHandler?()
    }
}
/// 加载更多的动画

final class LoadingMoreView: UICollectionReusableView {
    var activityIndicatorView: UIActivityIndicatorView?
    override init(frame: CGRect) {
        if #available(iOS 13.0, *) {
            activityIndicatorView = UIActivityIndicatorView(style: .medium)
        }
        super.init(frame: frame)
        if let activityIndicatorView = activityIndicatorView {
            addSubview(activityIndicatorView)
            activityIndicatorView.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
        }
    }
    deinit {
        self.stopLoading()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func startLoading() {
        activityIndicatorView?.startAnimating()
    }
    func stopLoading() {
        activityIndicatorView?.stopAnimating()
    }
}

/// 空view兜底
final class EmptyResuableView: UICollectionReusableView {
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
