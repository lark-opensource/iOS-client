//
//  SearchResultView.swift
//  Lark
//
//  Created by 刘晚林 on 2017/3/25.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkKeyboardKit
import RxSwift
import UniverseDesignEmpty
import UniverseDesignLoading
import RustPB
import TangramService

public protocol SearchFromColdDataDelegate: AnyObject {
    func requestColdData()
}

public protocol SearchErrorClickDelegate: AnyObject {
    func requestForQuota(isNeedLoadingPage: Bool)
}

open class SearchResultView: UIView {

    public enum Status {
        case empty(String, UIImage), loading, result, noResult(String), failed(String), noResultForAYear(String)
        case spotlightStatus(SpotlightStatus)
        case quotaExceed(Search_V2_SearchCommonResponseHeader.ErrorInfo)
        //spotlight搜索出现错误或空，在业务下层处理，状态不会抛到这里
        public enum SpotlightStatus {
            case spotlightFinishLoading     // spotlight搜索结束到网络搜索结束前到loading态
            case spotlightFinishSearchError //  spotlight搜索结束后网络搜索出现错误
        }
    }

    public fileprivate(set) var tableview: UITableView

    public let noResultView: UIView
    public let emptyView: UIView
    public let failedView: UIView
    public let loadingView = UDLoading.presetSpin(loadingText: BundleI18n.LarkCore.Lark_Legacy_InLoading, textDistribution: .horizonal)
    public let quotaExceedView: UIView
    public var defaultNoResultTip = BundleI18n.LarkCore.Lark_Legacy_SearchNoAnyResult

    public var status: Status = .loading {
        didSet {
            didSetStatus()
        }
    }
    public weak var containerVC: SearchFromColdDataDelegate?
    func didSetStatus() {
        emptyView.isHidden = true
        noResultView.isHidden = true
        failedView.isHidden = true
        loadingView.isHidden = true
        tableview.isHidden = true
        quotaExceedView.isHidden = true
        loadingView.reset()
        switch status {
        case .empty(let title, let image):
            emptyView.isHidden = false
            self.noResultView.isHidden = true
            updateEmptyView(withImage: image, text: title)
        case .loading:
            self.loadingView.isHidden = false
        case .result:
            self.tableview.isHidden = false
        case .noResult(let text):
            self.noResultView.isHidden = false
            self.updateNoResultView(text: text)
        case .failed(let text):
            failedView.isHidden = false
            updateFailedView(withText: text)
        case .noResultForAYear(let text):
            self.noResultView.isHidden = false
            self.updateNoResultForYear(withQuery: text)
        case .spotlightStatus:
            self.tableview.isHidden = false
        case .quotaExceed(let errorInfo):
            self.quotaExceedView.isHidden = false
            guard let quotaExceedView = quotaExceedView as? SearchErrorInfoView else { return }
            quotaExceedView.updateView(errorInfo: errorInfo, isNeedShowIcon: true) {
                if let containerVC = self.containerVC as? SearchErrorClickDelegate {
                    containerVC.requestForQuota(isNeedLoadingPage: true)
                }
            }
        }
    }

    public var loadingViewTopOffset: CGFloat = 32 {
        didSet {
            self.loadingView.snp.updateConstraints { (make) in
                make.top.equalToSuperview().offset(loadingViewTopOffset)
            }
        }
    }

    public init(tableStyle: UITableView.Style = .grouped, noResultView: UIView? = nil, emptyView: UIView? = nil, failedView: UIView? = nil) {
        self.noResultView = noResultView ?? TitledView()
        self.emptyView = emptyView ?? TitledView()
        self.failedView = failedView ?? TitledView()
        self.quotaExceedView = SearchErrorInfoView()
        self.tableview = UITableView(frame: .zero, style: tableStyle)
        super.init(frame: CGRect.zero)

        // ensure resultView opaque. if who needs translucent, should clear the backgroundColor
        // if hide completely, should use hidden or alpha=0
        self.backgroundColor = UIColor.ud.bgBody
        self.initTable(tableStyle: tableStyle)
        self.initLoadingView()

        self.addSubview(self.emptyView)
        self.addSubview(self.noResultView)
        self.addSubview(self.failedView)
        self.addSubview(self.quotaExceedView)
        self.noResultView.isHidden = true
        self.emptyView.isHidden = true
        self.failedView.isHidden = true
        self.quotaExceedView.isHidden = true
        if emptyView == nil {
            initEmptyView()
        }
        if noResultView == nil {
            initNoResultView()
        }
        if failedView == nil {
            initFailedView()
        }

        initQuotaExceedView()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func didMoveToWindow() {
        super.didMoveToWindow()
        guard let window = self.window else { return }
        let top = UIScreen.main.bounds.height / 3
        self.noResultView.snp.remakeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview()
            make.top.equalTo(window).offset(top).priority(780)
            make.width.equalToSuperview()
        }
        emptyView.snp.remakeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview()
            make.top.equalTo(window).offset(top).priority(780)
            make.width.equalToSuperview()
        }
        failedView.snp.remakeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview()
            make.top.equalTo(window).offset(top).priority(780)
            make.width.equalToSuperview()
        }
        quotaExceedView.snp.remakeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview()
            make.top.equalTo(window).offset(top).priority(780)
            make.width.equalToSuperview()
        }
    }

    fileprivate func initTable(tableStyle: UITableView.Style) {
        tableview.isHidden = true
        tableview.backgroundColor = UIColor.clear
        tableview.separatorColor = UIColor.clear
        tableview.rowHeight = UITableView.automaticDimension
        tableview.estimatedRowHeight = 64
        tableview.keyboardDismissMode = .onDrag
        self.addSubview(tableview)
        tableview.snp.makeConstraints({ make in
            make.edges.equalToSuperview()
        })

        tableview.contentInsetAdjustmentBehavior = .never
    }

    fileprivate func initLoadingView() {
        self.addSubview(loadingView)
        loadingView.snp.makeConstraints({ make in
            make.top.equalToSuperview().offset(loadingViewTopOffset)
            make.centerX.equalToSuperview()
        })
        loadingView.isHidden = false
    }

    private func initEmptyView() {
        guard let emptyView = emptyView as? TitledView else { return }
        emptyView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
            make.width.equalToSuperview()
        }
    }

    private func initNoResultView() {
        guard let noResultView = noResultView as? TitledView else { return }
        noResultView.icon.image = UDEmptyType.noSearchResult.defaultImage()
        noResultView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
            make.width.equalToSuperview()
        }
    }

    private func initFailedView() {
        guard let failedView = failedView as? TitledView else { return }
        failedView.icon.image = UDEmptyType.searchFailed.defaultImage()
        failedView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
            make.width.equalToSuperview()
        }
    }

    private func initQuotaExceedView() {
        guard let quotaExceedView = quotaExceedView as? SearchErrorInfoView else { return }
        quotaExceedView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
            make.width.equalToSuperview()
        }
    }

    final class TitledView: UIView {
        let textLabel = UILabel()
        let icon = UIImageView()

        override init(frame: CGRect) {
            super.init(frame: frame)
            setupView()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func setupView() {
            addSubview(icon)
            icon.snp.makeConstraints({ make in
                make.centerX.equalToSuperview()
                make.top.equalToSuperview()
                make.width.height.equalTo(100)
            })

            addSubview(textLabel)
            textLabel.textAlignment = .center
            textLabel.font = UIFont.systemFont(ofSize: 14)
            textLabel.textColor = .ud.textCaption
            textLabel.lineBreakMode = .byTruncatingMiddle
            textLabel.snp.makeConstraints({ make in
                make.top.equalTo(icon.snp.bottom).offset(12)
                make.centerX.equalToSuperview()
                make.left.right.equalToSuperview().inset(16)
                make.bottom.equalToSuperview()
            })
        }
    }

    private func updateNoResultView(text: String) {
        guard let noResultView = noResultView as? TitledView else { return }
        noResultView.textLabel.attributedText = noResultMessage(withText: text)
    }
    private func updateNoResultForYear(withQuery query: String) {
        guard let noResultView = noResultView as? TitledView else { return }

        var text: String
        var wholeText: String
        var template: NSString
        if query.isEmpty {
            /// 若是空query, 展示“无一年内的记录，加载更早记录”
            text = BundleI18n.LarkCore.Lark_Search_InChatSearch_FilesTabCommon_NoRecordsInPastYear_LoadEarlierButton
            wholeText = BundleI18n.LarkCore.Lark_Search_InChatSearch_FilesTabCommon_NoRecordsInPastYear_Text(text)
            template = BundleI18n.LarkCore.__Lark_Search_InChatSearch_FilesTabCommon_NoRecordsInPastYear_Text as NSString
        } else {
            /// 若是有query， 展示“无一年内的搜索结果，查看更早的消息”
            text = BundleI18n.LarkCore.Lark_Search_NoResultsFromPast1YearViewEarlier_Variable
            wholeText = BundleI18n.LarkCore.Lark_Search_NoResultsFromPast1YearViewEarlier_EmptyState(text)
            template = BundleI18n.LarkCore.__Lark_Search_NoResultsFromPast1YearViewEarlier_EmptyState as NSString
        }

        let attributedString = NSMutableAttributedString(string: wholeText,
                                                         attributes: [
                                                            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14.0),
                                                            NSAttributedString.Key.foregroundColor: UIColor.ud.textCaption
                                                         ])

        let start = template.range(of: "{{").location
        if start != NSNotFound {
            let range = NSRange(location: start, length: (text as NSString).length)
            attributedString.addAttribute(NSAttributedString.Key("link"),
                                          value: "SearchMore",
                                          range: range)
            attributedString.addAttribute(NSAttributedString.Key.foregroundColor,
                                          value: UIColor.ud.primaryContentDefault,
                                          range: range)
        }
        noResultView.textLabel.attributedText = attributedString
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(labelTapped(_:)))
        noResultView.textLabel.isUserInteractionEnabled = true
        noResultView.textLabel.numberOfLines = 0
        noResultView.textLabel.addGestureRecognizer(tapGesture)
    }
    @objc
    func labelTapped(_ sender: UITapGestureRecognizer) {
        guard let noResultView = noResultView as? TitledView,
              let attributedString = noResultView.textLabel.attributedText else { return }

        /// 创建一个 NSLayoutManager 对象 layoutManager，用于在 UILabel 中布置文本，并设置文本容器的大小
        let layoutManager = NSLayoutManager()
        /// 创建一个 NSTextContainer 对象 textContainer，将其添加到 layoutManager 中，使文本布置在此容器中
        let textContainer = NSTextContainer(size: .zero)
        /// 创建一个 NSTextStorage 对象 textStorage，将其初始化为 attributedString 的值，用于存储 UILabel 中的富文本。
        let textStorage = NSTextStorage(attributedString: attributedString)

        /// 将 textStorage 添加到 layoutManager 中，以便布置富文本。
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        /// 计算在 UILabel 中点击位置的坐标。
        let locationOfTouchInLabel = sender.location(in: noResultView.textLabel)
        /// 计算UILabel的大小
        let labelSize = noResultView.textLabel.bounds.size
        /// 计算文本容器的矩形大小，
        let textBoundingBox = layoutManager.usedRect(for: textContainer)
        /// 确定文本容器的偏移量，使其位于 UILabel 的中心位置。
        let textContainerOffset = CGPoint(x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x,
                                          y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y)
        /// 计算文本容器中的点击位置
        let locationOfTouchInTextContainer = CGPoint(x: locationOfTouchInLabel.x - textContainerOffset.x,
                                                     y: locationOfTouchInLabel.y - textContainerOffset.y)
        /// 查找在点击位置处的字符索引。
        let indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)

        /// 如果在此字符位置处有链接，则执行相关代码。
        if let link = attributedString.attribute(NSAttributedString.Key("link"), at: indexOfCharacter, effectiveRange: nil) as? String {
            // 点击了链接
            if link == "SearchMore" {
                // 执行自定义函数
                containerVC?.requestColdData()
            }
        }
    }

    private func updateEmptyView(withImage image: UIImage, text: String) {
        guard let emptyView = emptyView as? TitledView else { return }
        emptyView.icon.image = image
        emptyView.textLabel.text = text
    }

    private func updateFailedView(withText text: String) {
        guard let failedView = failedView as? TitledView else { return }
        failedView.textLabel.attributedText = noResultMessage(withText: text)
    }

    private func noResultMessage(withText text: String) -> NSAttributedString {
        let attributedString: NSMutableAttributedString
        if !text.isEmpty {
            let wholeText = BundleI18n.LarkCore.Lark_Legacy_SearchNoResult(text)
            let template = BundleI18n.LarkCore.__Lark_Legacy_SearchNoResult as NSString

            attributedString = NSMutableAttributedString(string: wholeText)
            attributedString.addAttribute(.foregroundColor,
                                          value: UIColor.ud.textCaption,
                                          range: NSRange(location: 0, length: attributedString.length))

            let start = template.range(of: "{{").location
            if start != NSNotFound {
                attributedString.addAttribute(.foregroundColor,
                                              value: UIColor.ud.textLinkNormal,
                                              range: NSRange(location: start, length: (text as NSString).length))
            }
        } else {
            let wholeText = defaultNoResultTip
            attributedString = NSMutableAttributedString(string: wholeText)
            attributedString.addAttribute(.foregroundColor,
                                          value: UIColor.ud.textCaption,
                                          range: NSRange(location: 0, length: attributedString.length))

        }
        return attributedString
    }

}

extension Resources {
    public static var empty_search: UIImage { UDEmptyType.noSearchResult.defaultImage() }
}
