//
//  SettingViewManager.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/4/7.
//

import Foundation
import ByteViewCommon

public protocol SettingUIDependency {
    func push(url: URL, from: UIViewController)

    func createChatterPicker(selectedIds: [String], disabledIds: [String], isMultiple: Bool, includeOuterTenant: Bool,
                             selectHandler: ((String) -> Void)?, deselectHandler: ((String) -> Void)?, shouldSelectHandler: (() -> Bool)?) -> UIView
}

public class UserSettingUI {
    private let service: UserSettingManager
    fileprivate init(_ service: UserSettingManager) {
        self.service = service
    }

    /// 会前设置
    public func createGeneralSettingViewController(source: String?) -> UIViewController {
        let viewModel = GeneralSettingViewModel(service: service, context: GeneralSettingContext(source: source))
        return SettingViewController(viewModel: viewModel)
    }

    /// 会前日历设置
    public func createCalendarSettingViewController(context: CalendarSettingContext) -> UIViewController {
        let viewModel = CalendarSettingViewModel(service: service, context: context)
        return CalendarSettingViewController(viewModel: viewModel)
    }

    public func createWebinarSettingViewController(context: WebinarSettingContext) -> WebinarSettingViewController {
        let viewModel = WebinarSettingViewModel(service: service, context: context)
        return WebinarSettingViewControllerImpl(viewModel: viewModel)
    }
}

public final class MeetingSettingUI: UserSettingUI {
    private let setting: MeetingSettingManager
    fileprivate init(_ setting: MeetingSettingManager) {
        self.setting = setting
        super.init(setting.service)
    }

    /// 会中设置
    public func createInMeetSettingViewController(context: InMeetSettingContext, handler: InMeetSettingHandler) -> UIViewController {
        let viewModel = InMeetSettingViewModel(setting: setting, context: context, handler: handler)
        return SettingViewController(viewModel: viewModel)
    }

    public func createSubtitleSettingViewController(context: SubtitleSettingContext) -> UIViewController {
        let viewModel = SubtitleSettingViewModel(setting: setting, context: context)
        return SettingViewController(viewModel: viewModel)
    }

    /// 会中“安全”设置
    public func createInMeetSecurityViewController(context: InMeetSecurityContext) -> UIViewController {
        let viewModel = InMeetSecurityViewModel(setting: setting, context: context)
        return SettingViewController(viewModel: viewModel)
    }

    public func createTranscriptLanguageViewController(context: TranscriptLanguageContext) -> UIViewController {
        let viewModel = TranscriptLanguageViewModel(setting: setting, context: context)
        return LanguageSettingViewController(viewModel: viewModel)
    }
}

protocol InMeetSettingChangedListener: AnyObject {
    func didChangeInMeetSettingInstance(_ setting: MeetingSettingManager?, oldSetting: MeetingSettingManager?)
}

public final class InMeetSettingHolder {
    public static let shared = InMeetSettingHolder()

    private let listeners = Listeners<InMeetSettingChangedListener>()
    @RwAtomic private(set) var currentInMeetSetting: MeetingSettingManager?

    public func setCurrent(_ setting: MeetingSettingManager?) {
        if currentInMeetSetting !== setting {
            let oldSetting = self.currentInMeetSetting
            self.currentInMeetSetting = setting
            listeners.forEach { $0.didChangeInMeetSettingInstance(setting, oldSetting: oldSetting) }
        }
    }

    func addListener(_ listener: InMeetSettingChangedListener) {
        listeners.addListener(listener)
    }

    func removeListener(_ listener: InMeetSettingChangedListener) {
        listeners.removeListener(listener)
    }

}

extension UserSettingManager {
}

extension MeetingSettingManager {
    public var ui: MeetingSettingUI {
        MeetingSettingUI(self)
    }
}

extension UserSettingManager {
    public var ui: UserSettingUI {
        UserSettingUI(self)
    }

    fileprivate static var uiDependencyKey: Int8 = 0
    public func setViewDependency(_ dependency: SettingUIDependency) {
        objc_setAssociatedObject(self, &Self.uiDependencyKey, dependency, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

extension UserSettingUI {
    private var dependency: SettingUIDependency? {
        objc_getAssociatedObject(service, &UserSettingManager.uiDependencyKey) as? SettingUIDependency
    }

    func push(url: URL, from: UIViewController) {
        dependency?.push(url: url, from: from)
    }

    func createChatterPicker(selectedIds: [String], disabledIds: [String], isMultiple: Bool, includeOuterTenant: Bool,
                             selectHandler: ((String) -> Void)?, deselectHandler: ((String) -> Void)?, shouldSelectHandler: (() -> Bool)?) -> UIView {
        if let dependency = dependency {
            return dependency.createChatterPicker(selectedIds: selectedIds, disabledIds: disabledIds, isMultiple: isMultiple, includeOuterTenant: includeOuterTenant, selectHandler: selectHandler, deselectHandler: deselectHandler, shouldSelectHandler: shouldSelectHandler)
        } else {
            return UIView()
        }
    }
}
