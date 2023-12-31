//
//  SearchPickerNavigationController.swift
//  LarkSearchCore
//
//  Created by Yuri on 2023/2/23.
//

import UIKit
import LarkUIKit
import LarkModel
import LarkContainer

public final class SearchPickerNavigationController: LKBaseNavigationController, SearchPickerControllerType {

    public weak var pickerDelegate: SearchPickerDelegate? {
        didSet {
            self.pickerVc.pickerDelegate = pickerDelegate
        }
    }

    public var defaultView: PickerDefaultViewType? {
        didSet {
            self.pickerVc.defaultView = defaultView
        }
    }

    /// 自定义头部视图, 展示在多选列表上方, 需要在PickerVC调起前设置
    public var headerView: UIView? {
        didSet {
            self.pickerVc.headerView = headerView
        }
    }

    /// 自定义顶部视图, 展示在多选列表下方, 需要在PickerVC调起前设置
    public var topView: UIView? {
        didSet {
            self.pickerVc.topView = topView
        }
    }

    public var featureConfig = PickerFeatureConfig() {
        didSet {
            self.pickerVc.featureConfig = featureConfig
        }
    }

    public var searchConfig = PickerSearchConfig() {
        didSet {
            self.pickerVc.searchConfig = searchConfig
        }
    }

    var context = PickerContext()

    private var userResolver: UserResolver
    private let pickerVc: SearchPickerViewController
    public init(resolver: UserResolver) {
        self.userResolver = resolver

        self.context.style = .picker
        self.context.featureConfig = featureConfig
        self.pickerVc = SearchPickerViewController(resolver: resolver, context: self.context)
        if #available(iOS 13, *) {
            super.init(rootViewController: pickerVc)
        } else {
            /*
             Crash: https://slardar.bytedance.net/node/app_detail/?aid=462391&os=iOS&region=cn&lang=zh#/abnormal/detail/crash/a9a3abb1f51c3193333e7c02cd4309a9?params=%7B%22end_time%22%3A1687321655%2C%22start_time%22%3A1686716855%2C%22token%22%3A%22%22%2C%22token_type%22%3A0%2C%22crash_time_type%22%3A%22insert_time%22%2C%22granularity%22%3A86400%2C%22filters_conditions%22%3A%7B%22type%22%3A%22and%22%2C%22sub_conditions%22%3A%5B%5D%7D%2C%22event_index%22%3A1%7D
             参考链接: https://stackoverflow.com/questions/38334776/fatal-error-use-of-unimplemented-initializer-in-custom-navigationcontroller
             iOS 12 系统crash, 兼容代码
             */
            super.init(nibName: nil, bundle: nil)
            self.viewControllers = [pickerVc]
        }
        self.pickerVc.ownerVc = self
    }

    public convenience init(userId: String) throws {
        let userResolver = try Container.shared.getUserResolver(userID: userId)
        self.init(resolver: userResolver)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        PickerLogger.shared.info(module: PickerLogger.Module.view, event: "SearchPickerNavigationController deinit")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationBar.tintColor = UIColor.ud.iconN1
    }

    public func reload(search: Bool, recommend: Bool) {
        self.pickerVc.reload(search: search, recommend: recommend)
    }
    public func reload() {
        self.reload(search: true, recommend: true)
    }
}
