//
//  ViewAdapter.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2022/4/21.
//

import Foundation
import RxSwift
import RxCocoa
import LarkUIKit
import SnapKit
import UniverseDesignToast
import UniverseDesignEmpty
import UIKit

final class ViewAdapter: NSObject, AdapterInterface {
    private let disposeBag = DisposeBag()
    private weak var page: LabelMainListViewController?
    private let vm: LabelMainListViewModel
    private weak var emptyView: UIView?
    private weak var feedEmptyView: UIView?

    init(vm: LabelMainListViewModel) {
        self.vm = vm
    }

    func setup(page: LabelMainListViewController) {
        self.page = page
        page.isNavigationBarHidden = true
        let backgroundColor = UIColor.ud.bgBody
        page.view.backgroundColor = backgroundColor
        let wrapperScrollView = UIScrollView()
        wrapperScrollView.backgroundColor = backgroundColor
        page.view.addSubview(wrapperScrollView)
        wrapperScrollView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        let tableView = page.tableView
        wrapperScrollView.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.size.edges.equalToSuperview()
        }
        bind()
    }

    private func bind() {
        vm.viewDataStateModule.stateObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] state in
                self?.handleState(state)
        }).disposed(by: disposeBag)

        let page = self.page
        vm.viewDataStateModule.emptyObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] emptyType in
                guard let self = self else { return }
                switch emptyType {
                case .main:
                    if case .threeBarMode(_) = self.vm.switchModeModule.mode {
                        self.page?.delegate?.backFirstList()
                    }
                    self.showEmptyView()
                    self.removeFeedEmptyView()
                case .subLevel:
                    self.removeEmptyView()
                    self.showFeedEmptyView()
                case .none:
                    self.removeEmptyView()
                    self.removeFeedEmptyView()
                }
        }).disposed(by: disposeBag)
    }

    private func handleState(_ state: LabelMainListViewDataStateModule.State) {
        switch state {
        case .loading:
            showLoading(true)
        case .loaded:
            showLoading(false)
        case .error:
            break
        }
    }

    private func showEmptyView() {
        guard let page = self.page else { return }
        guard emptyView == nil else { return }
        let desc = UDEmptyConfig.Description(descriptionText: BundleI18n.LarkFeed.Lark_Core_CreateLabelAndManageChatsInCategories_EmptyState_Mobile)
        let config = UDEmptyConfig(description: desc,
                                   type: .imDefault,
                                   primaryButtonConfig: ( BundleI18n.LarkFeed.Lark_Core_CreateLabel_Button_Mobile, { [weak page] _ in
            FeedTracker.Label.Click.CreatLabelInEmpty()
            page?.actionHandlerAdapter.creatLabel()
        }))
        let emptyView = UDEmptyView(config: config)
        emptyView.useCenterConstraints = true
        self.emptyView = emptyView
        page.tableView.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.leading.trailing.height.width.equalToSuperview()
            make.top.equalToSuperview().offset(-100)
        }
    }

    private func removeEmptyView() {
        emptyView?.removeFromSuperview()
        emptyView = nil
    }

    func showLoading(_ show: Bool) {
        guard let page = self.page else { return }
        guard page.loadingPlaceholderView.isHidden == show else { return }
        page.loadingPlaceholderView.isHidden = !show
    }

    private func showFeedEmptyView() {
        guard let page = self.page else { return }
        guard feedEmptyView == nil else { return }

        let descTextView = UITextView()
        descTextView.backgroundColor = UIColor.clear
        descTextView.delegate = self
        descTextView.isEditable = false
        descTextView.attributedText = createAttributedText()
        self.feedEmptyView = descTextView
        page.tableView.addSubview(descTextView)
        descTextView.snp.makeConstraints { make in
            make.leading.trailing.width.equalToSuperview()
            make.height.equalTo(40)
            make.centerY.equalToSuperview().offset(-60)
        }
    }

    private func removeFeedEmptyView() {
        feedEmptyView?.removeFromSuperview()
        feedEmptyView = nil
    }

    private func createAttributedText() -> NSAttributedString {
        let linkText = BundleI18n.LarkFeed.Lark_IM_Labels_AddChatsToLabelToOrganizeMessage_Variable
        let descText = BundleI18n.LarkFeed.Lark_IM_Labels_AddChatsToLabelToOrganizeMessage_EmptyState(linkText)
        let attributedText = NSMutableAttributedString(string: descText)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14),
                                                         NSAttributedString.Key.foregroundColor: UIColor.ud.textCaption,
                                                         NSAttributedString.Key.paragraphStyle: paragraphStyle]
        attributedText.addAttributes(attributes, range: NSRange(location: 0, length: descText.utf16.count))
        let range = (descText as NSString).range(of: linkText)
        if range.location != NSNotFound {
            attributedText.addAttributes([NSAttributedString.Key.link: ""],
                                         range: NSRange(location: range.location, length: linkText.utf16.count))
        }
        return attributedText
    }
}

extension ViewAdapter: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if interaction == .invokeDefaultAction,
           case .threeBarMode(let labelId) = vm.switchModeModule.mode {
            self.page?.actionHandlerAdapter.createLabelFeed(labelId: labelId)
            return false
        }
        return true
    }
}
