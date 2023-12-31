//
//  SideBarFilterListViewController.swift
//  LarkNavigation
//
//  Created by liuxianyu on 2022/3/8.
//

import UIKit
import Foundation
import LarkStorage
import LarkFoundation
import LarkSetting
import LarkUIKit
import LKCommonsLogging
import UniverseDesignDrawer
import LarkAccountInterface

public final class SideBarFilterListViewController: UIViewController, SideBarAbility {

    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
    private static let logger = Logger.log(SideBarFilterListViewController.self, category: "LarkNavigation.SideBarFilterListViewController")
    private lazy var cachedHeightConfig = KVConfig(
        key: KVKeys.Navigation.filterCachedHeight,
        store: KVStores.Navigation.build(
            forUser: AccountServiceAdapter.shared.currentChatterId
        )
    )

    private(set) var cachedHeight: CGFloat? {
        get {
            let cached = cachedHeightConfig.value
            return cached == 0 ? nil : cached
        }
        set {
            cachedHeightConfig.value = newValue
        }
    }

    // Dependencies
    private let filterViewController: UIViewController
    private let topOffset: CGFloat = Display.iPhoneXSeries ? 60 : 36
    private lazy var disposeBag = KVODisposeBag()

    init(filterViewController: UIViewController) {
        self.filterViewController = filterViewController
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.ud.bgBody
        self.view.clipsToBounds = true

        addChild(filterViewController)
        filterViewController.didMove(toParent: self)
        view.addSubview(filterViewController.view)
        filterViewController.view.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(self.view.snp.bottom)
            make.top.equalTo(view.safeAreaLayoutGuide)
        }

        observePopoverSize()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupPopoverSize()
    }

    private func setupPopoverSize() {
        guard Display.pad else { return }
        // setup
        if let cachedHeight = cachedHeight {
            self.preferredContentSize = CGSize(width: 400, height: cachedHeight)
        } else {
            self.preferredContentSize = CGSize(width: 400, height: 642)
        }
    }

    private func observePopoverSize() {
        // observe change
        if Display.pad {
            filterViewController.observe(\.preferredContentSize, options: .new, changeHandler: { [weak self] _, change in
                if let newValue = change.newValue, let self = self {
                    let newHeight = newValue.height
                    let topOffset = self.topOffset
                    let safeAreaInsetTop = self.view.safeAreaInsets.top
                    let preferredHeight = newHeight + topOffset - safeAreaInsetTop
                    self.adjustPopoverWithDebounce(height: preferredHeight)
                }
            }).disposed(by: disposeBag)
        }
    }

    private func adjustPopoverWithDebounce(height: CGFloat) {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        self.perform(#selector(adjustPopover(height:)), with: NSNumber(value: Float(height)), afterDelay: 0.2)
    }

    @objc
    private func adjustPopover(height: NSNumber) {
        let height = CGFloat(height.floatValue)
        self.preferredContentSize = CGSize(width: 400, height: height)
        self.cachedHeight = height
        Self.logger.debug("FilterPopover SideBarVC preferred height: \(height)")
    }
}
