//
//  MailGroupMemberBaseTableView.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/10/27.
//

import UIKit
import Foundation
import LarkUIKit
import SnapKit
import UniverseDesignEmpty

private final class LoadingView: UIView {

    fileprivate var indicator: UIActivityIndicatorView!

    public init() {
        super.init(frame: CGRect.zero)

        // 容器
        let loadingWrapper = UIView()
        self.addSubview(loadingWrapper)
        loadingWrapper.snp.makeConstraints({ make in
            make.centerX.equalToSuperview()
            make.top.bottom.equalToSuperview()
        })

        // indicator
        let indicator = UIActivityIndicatorView()
        indicator.style = .white
        indicator.color = UIColor.ud.iconN3
        loadingWrapper.addSubview(indicator)
        indicator.snp.makeConstraints({ make in
            make.left.equalToSuperview()
            make.top.bottom.equalTo(6)
        })
        self.indicator = indicator

        // label
        let infoLabel = UILabel()
        infoLabel.text = BundleI18n.LarkContact.Lark_Legacy_InLoading
        infoLabel.font = UIFont.systemFont(ofSize: 14)
        infoLabel.textColor = UIColor.ud.textTitle
        loadingWrapper.addSubview(infoLabel)
        infoLabel.snp.makeConstraints({ make in
            make.left.equalTo(indicator.snp.right).offset(4)
            make.right.equalToSuperview()
            make.centerY.equalTo(indicator)
        })
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func show() {
        self.isHidden = false
        self.indicator.startAnimating()
    }

    public func hide() {
        self.indicator.stopAnimating()
        self.isHidden = true
    }
}

open class MailGroupMemberBaseTable: UITableView {
    public lazy var emptyPlaceholder = BundleI18n.LarkContact.Lark_Legacy_ContentEmpty
    public lazy var emptyPlaceholderImage = EmptyDataView.defaultEmptyImage

    public enum Status {
        case display
        case loading
        case empty
        case searchNoResult(String)

        var isSearchNoResult: Bool {
            switch self {
            case .display, .loading, .empty:
                return false
            case .searchNoResult:
                return true
            }
        }
    }

    public var status: Status = .display {
        didSet {
            updateViewStatus()
        }
    }

    // 避免设置isHidden访问loadingView导致初始化
    private var _loadingView: LoadingView?
    private lazy var loadingView: LoadingView = {
        let view = LoadingView()
        self.addSubview(view)
        view.snp.makeConstraints({ (make) in
            make.top.centerX.equalToSuperview()
        })
        _loadingView = view
        return view
    }()

    // 避免设置isHidden访问noResultView导致初始化
    private var _noResultView: EmptyDataView?
    static var noResultImage: UIImage { UDEmptyType.noSearchResult.defaultImage() }
    private lazy var noResultView: EmptyDataView = {
        let view = EmptyDataView(placeholderImage: Self.noResultImage)
        view.label.numberOfLines = 1
        view.label.lineBreakMode = .byTruncatingMiddle
        self.addSubview(view)
        if Display.pad {
            view.useCustomConstraints = true
            view.contentView.snp.remakeConstraints({ (make) in
                make.center.equalToSuperview()
                make.left.greaterThanOrEqualToSuperview().inset(16)
                make.right.lessThanOrEqualToSuperview().inset(16)
            })
        }
        view.snp.makeConstraints({ (maker) in
            maker.left.top.width.height.equalToSuperview()
        })
        _noResultView = view
        return view
    }()

    private func update(text: String) {
        let wholeText = BundleI18n.LarkContact.Lark_UserGrowth_SearchNoResult

        let attributedString = NSMutableAttributedString(string: wholeText)
        attributedString.addAttribute(.foregroundColor,
                                      value: UIColor.ud.N500,
                                      range: NSRange(location: 0, length: attributedString.length))

        noResultView.label.attributedText = attributedString
    }

    private func updateViewStatus() {
        self.backgroundColor = UIColor.ud.bgBody
        switch status {
        case .display:
            _noResultView?.isHidden = true
            _loadingView?.hide()

        case .loading:
            _noResultView?.isHidden = true
            bringSubviewToFront(loadingView)
            loadingView.show()

        case .empty:
            _loadingView?.hide()
            bringSubviewToFront(noResultView)
            noResultView.isHidden = false
            noResultView.placeholderImage = emptyPlaceholderImage
            noResultView.label.attributedText = NSAttributedString(string: emptyPlaceholder)

        case .searchNoResult(let text):
            _loadingView?.hide()
            bringSubviewToFront(noResultView)
            noResultView.isHidden = false
            noResultView.placeholderImage = Self.noResultImage
            self.update(text: text)
        }
    }
}
