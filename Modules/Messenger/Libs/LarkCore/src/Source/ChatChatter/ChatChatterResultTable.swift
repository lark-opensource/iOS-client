//
//  File.swift
//  LarkCore
//
//  Created by kongkaikai on 2019/3/5.
//

import UIKit
import Foundation
import LarkUIKit
import SnapKit
import UniverseDesignEmpty

open class ChatChatterBaseTable: UITableView {
    public lazy var emptyPlaceholder = BundleI18n.LarkCore.Lark_Legacy_CurrentPageEmpty
    public lazy var emptyPlaceholderImage = EmptyDataView.defaultEmptyImage

    public enum Status: Equatable {
        case display
        case update
        case loading
        case empty
        case searchNoResult(String)

        var isSearchNoResult: Bool {
            switch self {
            case .display, .loading, .empty, .update:
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
    private var _loadingView: CoreLoadingView?
    private lazy var loadingView: CoreLoadingView = {
        let view = CoreLoadingView()
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
        let wholeText = BundleI18n.LarkCore.Lark_Legacy_SearchNoResult(text)
        let template = BundleI18n.LarkCore.__Lark_Legacy_SearchNoResult as NSString

        let attributedString = NSMutableAttributedString(string: wholeText)
        attributedString.addAttribute(.foregroundColor,
                                      value: UIColor.ud.N500,
                                      range: NSRange(location: 0, length: attributedString.length))

        let start = template.range(of: "{{").location
        if start != NSNotFound {
            attributedString.addAttribute(.foregroundColor,
                                          value: UIColor.ud.colorfulBlue,
                                          range: NSRange(location: start, length: (text as NSString).length))
        }

        noResultView.label.attributedText = attributedString
    }

    private func updateViewStatus() {
        self.backgroundColor = UIColor.ud.bgBody
        switch status {
        case .display, .update:
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
