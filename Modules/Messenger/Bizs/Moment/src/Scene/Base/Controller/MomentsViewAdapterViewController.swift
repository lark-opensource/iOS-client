//
//  BaseMomentsFeedViewController.swift
//  Moment
//
//  Created by bytedance on 1/17/22.
//

import Foundation
import LarkUIKit
import UIKit
import LarkContainer
import RxSwift
import RxCocoa

class MomentsViewAdapterViewController: BaseUIViewController, UserResolverWrapper, PageAPI {
    let userResolver: UserResolver

    @ScopedInjectedLazy var momentsAccountService: MomentsAccountService?
    private var disposeBag = DisposeBag()
    ///为了使tableView的可滑动区域比cell的展示区域更宽，要重写cell的frame。originFrame是cell默认的（由tableView系统方法布局的）frame，返回值是重新计算后的frame。
    static func computeCellFrame(originFrame: CGRect) -> CGRect {
        if Display.pad && originFrame.width >= contentViewMaxWidth + 16 * 2 {
            return CGRect(x: (originFrame.width - contentViewMaxWidth) / 2, y: originFrame.minY, width: contentViewMaxWidth, height: originFrame.height)
        } else {
            return originFrame
        }
    }

    //ipad从profile页跳转到子页面时，要用largeModalView，对应这个size
    static let largeModalViewSize = CGSize(width: 712, height: 746)

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var viewDidAppear: Bool = false

    var hostSize: CGSize = .zero {
        didSet {
            if hostSize.width == oldValue.width && hostSize.height == oldValue.height {
                return
            }
            onResize(widthChanged: hostSize.width != oldValue.width, heightChanged: hostSize.height != oldValue.height)
        }
    }

    var scene: MomentContextScene {
        return .unknown
    }

    var childVCMustBeModalView: Bool {
        return false
    }

    private var _isRegularStyle: Bool? {
        didSet {
            if let _isRegularStyle = _isRegularStyle,
               _isRegularStyle != oldValue {
                if _isRegularStyle {
                    setDisplayStyleRegular()
                } else {
                    setDisplayStyleCompact()
                }
            }
        }
    }
    var isRegularStyle: Bool {
        return _isRegularStyle ?? false
    }

    static let contentViewMaxWidth: CGFloat = 700
    let contentView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ud.bgBase
        view.addSubview(contentView)
        observeNoti()
    }

    private func observeNoti() {
        self.momentsAccountService?.rxCurrentAccount
            .observeOn(MainScheduler.instance)
            .filter { account in
                account != nil
            }.subscribe { [weak self] _ in
                self?.loadFirstScreenData()
            }.disposed(by: disposeBag)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateDisplayStyle(size: self.view.bounds.size)
    }

    private func updateDisplayStyle(size: CGSize) {
        _isRegularStyle = Display.pad && size.width >= Self.contentViewMaxWidth + 16 * 2
        hostSize = CGSize(width: isRegularStyle ? Self.contentViewMaxWidth : size.width, height: size.height)
    }

    func setDisplayStyleRegular() {
        contentView.snp.remakeConstraints { make in
            make.width.equalTo(Self.contentViewMaxWidth)
            make.centerX.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }
    }

    func setDisplayStyleCompact() {
        contentView.snp.remakeConstraints { make in
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }
    }

    func onResize(widthChanged: Bool, heightChanged: Bool) {}

    func reply(by commentData: RawData.CommentEntity, fromMenu: Bool) {}
    func reply(by postData: RawData.PostEntity) {}
    /// 刷线一下tableView的数据
    func refreshTableView() {}

    func loadFirstScreenData() {
    }
}
