//
//  TodoTopStructureSelectViewController.swift
//  LarkContact
//
//  Created by wangwanxin on 2023/1/4.
//

import UIKit
import Foundation
import LarkContainer
import LarkSearchCore
import LarkSDKInterface
import LarkMessengerInterface
import RxSwift
import LarkUIKit

final class TodoTopStructureSelectViewController: TopStructureSelectViewController {
    weak var selectionDataSource: SelectionDataSource?
    var hideRightNaviBarItem: Bool = false
    private var willShowObserver: NSObjectProtocol?
    private var willHideObserver: NSObjectProtocol?
    private let disposeBag = DisposeBag()

    // todo业务下底部场景距离的大小
    static let batchBottomHeight: CGFloat = 56
    static let shareBottomHeight: CGFloat = 52

    private lazy var batchBottomView: TodoBatchAddView = {
        if case .todo(let info) = self.source, info.isBatchAdd, !info.isShare {
            let bottomView = TodoBatchAddView(isDisableBatch: info.isDisableBatch)
            bottomView.batchAdd = { [weak self] in
                guard let self = self else { return }
                info.onTapBatch?(self)
            }
            return bottomView
        } else {
            return TodoBatchAddView(isDisableBatch: false)
        }
    }()
    private lazy var shareBottomView: TodoShareBottomView = {
        let shareBottomView = TodoShareBottomView()
        shareBottomView.doShare = { [weak self] in
            guard let self = self else { return }
            self.sureDidClick()
        }
        return shareBottomView
    }()
    // 用于shareBottomView第一次初始化UI，之后动画更改由监听keyBoard实现
    private var isInitBottomView: Bool = true

    override func configNaviBar() {
        super.configNaviBar()
        if hideRightNaviBarItem {
            customNavigationItem.rightBarButtonItem = nil
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if case .todo(let info) = self.source, info.isBatchAdd, !info.isShare {
            view.addSubview(batchBottomView)
        } else if case .todo(let info) = self.source, info.isShare {
            if !Display.pad {
                addObserver()
            }
            view.addSubview(shareBottomView)
            selectionDataSource?.selectedChangeObservable
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext: { [weak self] dataSource in
                            guard let self = self else { return }
                            self.shareBottomView.updateState(num: dataSource.selected.count)
                        }).disposed(by: disposeBag)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 因为需要安全距离，在此处进行布局，并且只在第一次初始化布局，之后布局更替由监听函数进行
        if isInitBottomView {
            if case .todo(let info) = self.source, info.isBatchAdd, !info.isShare {
                batchBottomView.snp.makeConstraints { (make) in
                    make.bottom.equalToSuperview()
                    make.left.right.equalToSuperview()
                    make.height.equalTo(view.safeAreaInsets.bottom + 56)
                }
            } else if case .todo(let info) = self.source, info.isShare {
                shareBottomView.snp.makeConstraints { (make) in
                    make.bottom.equalToSuperview()
                    make.left.right.equalToSuperview()
                    make.height.equalTo(view.safeAreaInsets.bottom + 52)
                }
            }
        }
    }

    private func addObserver() {
        willShowObserver = handelKeyboard(name: UIResponder.keyboardWillShowNotification, action: { [weak self] (keyboardRect, duration) in
            guard let self = self else { return }
            self.isInitBottomView = false
            let animation = {
                if case .todo(let info) = self.source, info.isBatchAdd, !info.isShare {
                    self.batchBottomView.snp.remakeConstraints { (make) in
                        make.left.right.equalToSuperview()
                        make.bottom.equalToSuperview().offset(-keyboardRect.height)
                        make.height.equalTo(56)
                    }
                } else if case .todo(let info) = self.source, info.isShare {
                    self.shareBottomView.snp.remakeConstraints { (make) in
                        make.left.right.equalToSuperview()
                        make.bottom.equalToSuperview().offset(-keyboardRect.height)
                        make.height.equalTo(52)
                    }
                }
            }
            UIView.animate(withDuration: duration,
                           delay: 0,
                           animations: {
                animation()
                self.view.layoutIfNeeded()
            },
            completion: nil)
        })
        willHideObserver = handelKeyboard(name: UIResponder.keyboardWillHideNotification, action: { [weak self] (_, duration) in
            guard let self = self else { return }
            self.isInitBottomView = false
            let animation = {
                if case .todo(let info) = self.source, info.isBatchAdd, !info.isShare {
                    self.batchBottomView.snp.remakeConstraints { (make) in
                        make.left.right.equalToSuperview()
                        make.bottom.equalToSuperview()
                        make.height.equalTo(self.view.safeAreaInsets.bottom + 56)
                    }
                } else if case .todo(let info) = self.source, info.isShare {
                    self.shareBottomView.snp.remakeConstraints { (make) in
                        make.left.right.equalToSuperview()
                        make.bottom.equalToSuperview()
                        make.height.equalTo(self.view.safeAreaInsets.bottom + 52)
                    }
                }
            }
            UIView.animate(withDuration: duration,
                           delay: 0,
                           animations: {
                animation()
                self.view.layoutIfNeeded()
            },
            completion: nil)
        })
    }

    private func handelKeyboard(name: NSNotification.Name, action: @escaping (CGRect, TimeInterval) -> Void) -> NSObjectProtocol {
        return NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil) { (notification) in
            guard let userinfo = notification.userInfo else {
                assertionFailure()
                return
            }
            let duration = userinfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
            guard let toFrame = userinfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                assertionFailure()
                return
            }
            action(toFrame, duration ?? 0)
        }
    }
}
