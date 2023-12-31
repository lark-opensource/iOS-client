//
//  SubscribeCalendarBase
//  Calendar
//
//  Created by heng zhu on 2019/1/14.
//  Copyright © 2019 EE. All rights reserved.
//

import Foundation
import CalendarFoundation
import UIKit
import SnapKit
import RxSwift
import RustPB

class SubscribeCalendarBase: UIViewController {
    let disposeBag = DisposeBag()
    let emptyView: EmptyStatusView = EmptyStatusView()
    let loadingView = IndicatorLoadingView()
    var searchText: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        layout(loadingView: loadingView, in: view)
        view.addSubview(emptyView)
        emptyView.snp.remakeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        loadingView.hide()
    }

    private func layout(loadingView: UIView, in superView: UIView) {
        superView.addSubview(loadingView)
        loadingView.snp.makeConstraints({ make in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview()
            make.height.equalTo(30)
        })
    }
}
