//
//  FeedCardTimeComponent.swift
//  LarkFeedBase
//
//  Created by liuxianyu on 2023/5/10.
//

import Foundation
import LarkOpenFeed
import LarkModel
import RustPB

// MARK: - Factory
public class FeedCardTimeFactory: FeedCardBaseComponentFactory {
    // 组件类别
    public var type: FeedCardComponentType {
        return .time
    }
    public init() {}

    public func creatVM(feedPreview: FeedPreview) -> FeedCardBaseComponentVM {
        return FeedCardTimeComponentVM(feedPreview: feedPreview)
    }

    public func creatView() -> FeedCardBaseComponentView {
        return FeedCardTimeComponentView()
    }
}

// MARK: - ViewModel
final class FeedCardTimeComponentVM: FeedCardBaseComponentVM, FeedCardStatusVisible {

    // 组件类别
    var type: FeedCardComponentType {
        return .time
    }

    var isVisible: Bool {
        return self.time > 0
    }

    // VM 数据
    let time: Int

    // 在子线程生成view data
    required init(feedPreview: FeedPreview) {
        self.time = feedPreview.uiMeta.displayTime
    }
}

// MARK: - View
class FeedCardTimeComponentView: FeedCardBaseComponentView {
    // 提供布局信息，比如：width、height、padding等（cell初始化进行布局时获取）
    var layoutInfo: LarkOpenFeed.FeedCardComponentLayoutInfo? {
        return nil
    }

    // 组件类别
    var type: FeedCardComponentType {
        return .time
    }

    func creatView() -> UIView {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.ud.body2
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }

    func updateView(view: UIView, vm: FeedCardBaseComponentVM) {
        guard let view = view as? UILabel,
              let vm = vm as? FeedCardTimeComponentVM else { return }
        view.text = Date.lf.getNiceDateString(TimeInterval(vm.time))
    }
}
