//
//  LarkSettingViewDependency.swift
//  ByteViewMod
//
//  Created by kiri on 2023/4/11.
//

import Foundation
import ByteViewSetting
import LarkContainer
#if MessengerMod
import LarkSearchCore
import LarkSDKInterface
#endif

final class SettingUIDependencyImpl: SettingUIDependency {
    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    func push(url: URL, from: UIViewController) {
        userResolver.navigator.push(url, from: from)
    }

    func createChatterPicker(selectedIds: [String], disabledIds: [String], isMultiple: Bool, includeOuterTenant: Bool, selectHandler: ((String) -> Void)?, deselectHandler: ((String) -> Void)?, shouldSelectHandler: (() -> Bool)?) -> UIView {
        #if MessengerMod
        let params = ChatterPicker.InitParam()
        params.isMultiple = isMultiple
        params.default = selectedIds.map { id in
            return OptionIdentifier.chatter(id: id)
        }
        params.disabled = disabledIds.map { id in
            return OptionIdentifier.chatter(id: id)
        }
        let impl = SettingPickerDelegate(selectHandler: selectHandler, deselectHandler: deselectHandler, shouldSelectHandler: shouldSelectHandler)
        params.delegate = impl

        let defaultView = UIView()
        let chatterPicker = ChatterPicker(resolver: self.userResolver, frame: .zero, params: params)
        chatterPicker.includeBot = false
        chatterPicker.includeOuterTenant = includeOuterTenant
        // 背景色与主端保持一致，VC不异化
        defaultView.backgroundColor = chatterPicker.defaultView.backgroundColor
        chatterPicker.defaultView = defaultView
        objc_setAssociatedObject(chatterPicker, &SettingPickerDelegate.associatedKey, impl, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return chatterPicker
        #else
        let label = UILabel()
        label.text = "Picker is not supported"
        label.textAlignment = .center
        return label
        #endif
    }
}

#if MessengerMod
private class SettingPickerDelegate: PickerDelegate {
    static var associatedKey: UInt8 = 0

    let selectHandler: ((String) -> Void)?
    let deselectHandler: ((String) -> Void)?
    let shouldSelectHandler: (() -> Bool)?
    init(selectHandler: ((String) -> Void)?, deselectHandler: ((String) -> Void)?, shouldSelectHandler: (() -> Bool)?) {
        self.selectHandler = selectHandler
        self.deselectHandler = deselectHandler
        self.shouldSelectHandler = shouldSelectHandler
    }
    func picker(_ picker: Picker, willSelected option: Option, from: Any?) -> Bool {
        return shouldSelectHandler?() ?? true
    }

    func picker(_ picker: Picker, didSelected option: Option, from: Any?) {
        selectHandler?(option.optionIdentifier.id)
    }

    func picker(_ picker: Picker, didDeselected option: Option, from: Any?) {
        deselectHandler?(option.optionIdentifier.id)
    }
}
#endif
