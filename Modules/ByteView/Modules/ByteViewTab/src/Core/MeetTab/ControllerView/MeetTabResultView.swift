//
//  MeetTabResultView.swift
//  ByteView
//
//  Created by fakegourmet on 2021/7/4.
//

import Foundation
import RxSwift
import RxCocoa
import RichLabel
import UniverseDesignEmpty
import Lottie
import UniverseDesignTheme
import ByteViewCommon
import ByteViewUI

enum MeetTabResultStatus {
    case result, loadError, noResult, loading
}

class MeetTabResultView: UIView {

    enum Layout {
        static let reloadHeight: CGFloat = 181.0
        static let emptyViewWidth: CGFloat = 240
        static let emptyViewHeight: CGFloat = 153
    }

    var linkHandler: (() -> Void)?

    var currentStatus: MeetTabResultStatus = .loading

    lazy var tableView: EmbeddedTableView = {
        let tableView = EmbeddedTableView(frame: CGRect.zero, style: .plain)
        tableView.backgroundColor = UIColor.clear
        tableView.separatorStyle = .none
        tableView.delaysContentTouches = false
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.keyboardDismissMode = .onDrag
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 66.0
        tableView.estimatedSectionFooterHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.contentInsetAdjustmentBehavior = .never
        if #available(iOS 13.0, *) {
            tableView.automaticallyAdjustsScrollIndicatorInsets = false
        }
        tableView.showsHorizontalScrollIndicator = false
        tableView.isHidden = false
        return tableView
    }()

    lazy var loadingView: LoadingPlaceholderView = {
        let loadingView = LoadingPlaceholderView(style: .center)
        loadingView.backgroundColor = .clear
        loadingView.label.attributedText = .init(string: I18n.View_VM_Loading, config: .bodyAssist, alignment: .center,
                                                 textColor: UIColor.ud.textCaption)
        return loadingView
    }()

    lazy var noResultEmptyView: UDEmptyView = {
        let emptyView = UDEmptyView(config: UDEmptyConfig(description: UDEmptyConfig.Description(descriptionText: NSAttributedString(string: I18n.View_MV_CollaborativeExp, config: .bodyAssist)), imageSize: 100, spaceBelowImage: 16, spaceBelowTitle: 0, spaceBelowDescription: 0, type: .vcNoMeetings))
        emptyView.backgroundColor = .clear
        return emptyView
    }()

    lazy var extensionView: UIView = {
        let extensionView = UIView(frame: CGRect.zero)
        extensionView.backgroundColor = .clear

        extensionView.addSubview(loadingView)
        loadingView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(16.0)
            make.center.equalToSuperview()
            make.height.equalTo(Layout.reloadHeight)
        }

        extensionView.addSubview(reloadResultView)
        reloadResultView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(16.0)
            make.center.equalToSuperview()
            make.height.equalTo(Layout.reloadHeight)
        }

        extensionView.addSubview(noResultView)
        noResultView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(16.0)
            make.center.equalToSuperview()
            make.height.equalTo(Layout.reloadHeight)
        }

        return extensionView
    }()

    lazy var noResultView: UIView = {
        let noResultView = UIView(frame: CGRect.zero)
        noResultView.addSubview(noResultEmptyView)
        noResultEmptyView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.equalTo(Layout.emptyViewWidth)
            make.height.equalTo(Layout.emptyViewHeight)
        }
        noResultView.backgroundColor = .clear
        noResultView.isHidden = true
        return noResultView
    }()

    lazy var reloadResultEmptyView: UDEmptyView = {
        let msg = I18n.View_MV_CouldntLoadContentHere
        let text = LinkTextParser.parsedLinkText(from: msg)

        let linkTextComponent = text.components.first
        let labelHandler = { [weak self] in
            self?.statusObserver.onNext(.loading)
            self?.linkHandler?()
        }
        let emptyView = UDEmptyView(config: UDEmptyConfig(description: UDEmptyConfig.Description(descriptionText: NSAttributedString(string: text.result, config: .bodyAssist), operableRange: linkTextComponent?.range), imageSize: 100, spaceBelowImage: 16, spaceBelowTitle: 0, spaceBelowDescription: 0, type: .loadingFailure, labelHandler: labelHandler))
        emptyView.backgroundColor = .clear
        return emptyView
    }()

    lazy var reloadResultView: UIView = {
        let reloadResultView = UIView(frame: CGRect.zero)
        reloadResultView.addSubview(reloadResultEmptyView)
        reloadResultEmptyView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.equalTo(Layout.emptyViewWidth)
            make.height.equalTo(Layout.emptyViewHeight)
        }
        reloadResultView.isHidden = true
        return reloadResultView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Display.pad ? .ud.bgContentBase : .ud.bgBody

        addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        addSubview(extensionView)
        extensionView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        tableView.isHidden = true
        tableView.isScrollEnabled = false
        extensionView.isHidden = false
        loadingView.isHidden = false
    }

    func update(_ status: MeetTabResultStatus) {
        if currentStatus != status {
            currentStatus = status
            switch status {
            case .result:
                tableView.isHidden = false
                tableView.isScrollEnabled = true
                extensionView.isHidden = true
            case .loading:
                tableView.isHidden = true
                tableView.isScrollEnabled = false
                extensionView.isHidden = false
                noResultView.isHidden = true
                loadingView.isHidden = false
                reloadResultView.isHidden = true
            case .loadError:
                tableView.isHidden = true
                tableView.isScrollEnabled = false
                extensionView.isHidden = false
                noResultView.isHidden = true
                loadingView.isHidden = true
                reloadResultView.isHidden = false
            case .noResult:
                tableView.isHidden = true
                tableView.isScrollEnabled = false
                extensionView.isHidden = false
                noResultView.isHidden = false
                loadingView.isHidden = true
                reloadResultView.isHidden = true
            }
        }
    }

    var statusObserver: AnyObserver<MeetTabResultStatus> {
        return AnyObserver<MeetTabResultStatus>(eventHandler: { [weak self] element in
            if case let .next(status) = element {
                self?.update(status)
            }
        })
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
