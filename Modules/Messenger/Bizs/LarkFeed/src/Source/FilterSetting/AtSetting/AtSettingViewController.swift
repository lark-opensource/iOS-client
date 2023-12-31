//
//  AtSettingViewController.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/10/10.
//

import Foundation
import UIKit
import LarkUIKit
import RxSwift
import RxCocoa
import UniverseDesignToast
import LarkModel
import EENavigator
import RustPB
import FigmaKit
import SnapKit
import LarkContainer
import LarkSDKInterface

/// 新消息通知设置
final class AtSettingViewController: BaseUIViewController {
    let userResolver: UserResolver
    private let disposeBag = DisposeBag()

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    let feedAPI: FeedAPI
    private let view2 = AtSettingItemView()

    init(resolver: UserResolver) throws {
        self.userResolver = resolver
        self.feedAPI = try resolver.resolve(assert: FeedAPI.self)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    private func setup() {
        self.title = BundleI18n.LarkFeed.Lark_Messenger_AtMeMessageGrouping_Subtitle
        self.view.backgroundColor = UIColor.ud.bgBase

        let firstItemModel = AtSettingItemModel(title: BundleI18n.LarkFeed.Lark_Messenger_GroupingAtMeMessages_Option, isEnabled: false, selected: true)
        var secondItemModel = AtSettingItemModel(title: BundleI18n.LarkFeed.Lark_Messenger_GroupingAtAllMessages_Option, isEnabled: true, selected: false)

        let contentView = UIView()
        self.view.addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
        }

        let topLineView = UIView()
        contentView.addSubview(topLineView)
        let lineHeight = 1 / UIScreen.main.scale
        topLineView.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(lineHeight)
        }
        topLineView.backgroundColor = UIColor.ud.lineDividerDefault

        let bottomLineView = UIView()
        contentView.addSubview(bottomLineView)
        bottomLineView.snp.makeConstraints { (make) in
            make.bottom.leading.trailing.equalToSuperview()
            make.height.equalTo(lineHeight)
        }
        bottomLineView.backgroundColor = UIColor.ud.lineDividerDefault

        let view1 = AtSettingItemView()
        contentView.addSubview(view1)
        view1.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(lineHeight)
        }

        contentView.addSubview(view2)
        view2.setBottomLineShowState(false)
        view2.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(view1)
            make.top.equalTo(view1.snp.bottom)
            make.bottom.equalToSuperview().offset(-lineHeight)
        }

        view2.selectedCallback = { [weak self] in
            guard let self = self else { return }
            secondItemModel.selected.toggle()
            self.view2.setModel(secondItemModel)
            self.upload(secondItemModel.selected)
        }

        view1.setModel(firstItemModel)
        view2.setModel(secondItemModel)

        feedAPI.getFeedFilterSettings(needAll: false, tryLocal: true).map({ [userResolver] response in
            return FiltersModel.transform(userResolver: userResolver, response)
        })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] filter in
                guard let self = self else { return }
                secondItemModel.selected = filter.showAtAllInAtFilter
                self.view2.setModel(secondItemModel)
            }, onError: { _ in
            }).disposed(by: disposeBag)
    }

    private func upload(_ showAtAllInAtFilter: Bool) {
        feedAPI.updateAtFilterSettings(showAtAllInAtFilter: showAtAllInAtFilter)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
            }, onError: { [weak self] _ in
                guard let self = self else { return }
                UDToast.showFailure(with: BundleI18n.LarkFeed.Lark_Legacy_FailedtoLoadTryLater, on: self.view)
            }).disposed(by: disposeBag)
    }
}
