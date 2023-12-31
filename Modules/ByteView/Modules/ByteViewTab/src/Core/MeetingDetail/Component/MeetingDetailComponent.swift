//
//  MeetingDetailComponent.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2022/11/21.
//

import Foundation

class MeetingDetailComponent: UIView {

    /// 控制是否展示
    var shouldShow: Bool { false }

    var viewModel: MeetingDetailViewModel?

    required override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bindViewModel(viewModel: MeetingDetailViewModel) {
        self.viewModel = viewModel
    }

    func setupViews() {
        isHidden = true
    }

    /// 跟随 ViewController 布局变化
    func updateLayout() {}

    /// 收到推送时更新数据
    func updateViews() {
        isHidden = !shouldShow
    }
}
