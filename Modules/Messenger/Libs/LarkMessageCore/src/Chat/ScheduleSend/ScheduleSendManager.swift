//
//  ScheduleSendManager.swift
//  LarkMessageCore
//
//  Created by JackZhao on 2022/9/7.
//

import Foundation
import UIKit
import RustPB
import RxSwift
import LarkCore
import LarkModel
import LarkContainer
import LarkSDKInterface
import LKCommonsLogging
import UniverseDesignToast
import LarkTimeFormatUtils
import LarkAlertController
import ThreadSafeDataStructure
import LarkMessengerInterface
import LarkSendMessage
import UniverseDesignDatePicker
import UniverseDesignActionPanel

// 收敛定时发送功能的通用业务
// figma: https://www.figma.com/file/LNdUQBZ6wmXuMQ07z3YXAJ/%E5%8D%95%E8%81%8A%E6%97%B6%E5%8C%BA%E6%8F%90%E7%A4%BA%2B%E5%AE%9A%E6%97%B6%E5%8F%91%E9%80%81?node-id=653%3A424457

final public class ScheduleSendManager: ScheduleSendService, UserResolverWrapper {
    public let userResolver: UserResolver

    private static let logger = Logger.log(ScheduleSendManager.self, category: "LarkMessageCore")

    // 当前选择的时间
    private var currentSelectDate: Date?
    private var stashDate: Date?
    private var minDate: Date?
    private var maxDate: Date?
    private let disposeBag = DisposeBag()

    @ScopedInjectedLazy var messageAPI: MessageAPI?
    @ScopedInjectedLazy var postSendService: PostSendService?
    @ScopedInjectedLazy private var userGeneralSettings: UserGeneralSettings?
    private var is12HourTime: Bool {
        !(self.userGeneralSettings?.is24HourTime.value ?? false)
    }
    // 定时发送fg
    public let scheduleSendEnable: Bool

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        self.scheduleSendEnable = userResolver.fg.staticFeatureGatingValue(with: "im.chat.bytedance_schedule_message") || userResolver.fg.staticFeatureGatingValue(with: "im.chat.schedule_message")
    }

    // 在编辑状态打开时间选择器
    public func showDatePickerInEdit(currentSelectDate: Date,
                                     chatName: String,
                                     from: UIViewController,
                                     isShowSendNow: Bool,
                                     sendNowCallback: @escaping () -> Void,
                                     confirmTask: @escaping (Date) -> Void) {
        let config = UDWheelsStyleConfig(mode: .dayHourMinute(),
                                         maxDisplayRows: 5,
                                         is12Hour: is12HourTime,
                                         minInterval: 1,
                                         textFont: UIFont.systemFont(ofSize: 17))
        // 大于当前时间5分钟
        self.minDate = Date().addingTimeInterval(5 * 60)
        self.maxDate = Date().addingTimeInterval(3600 * 24 * 32)
        self.currentSelectDate = currentSelectDate
        self.stashDate = currentSelectDate
        let sendTimeIdentify = "sendTime"
        let bottomButtons = [
            // 保存
            getSaveButton(),
            // 立即发送
            isShowSendNow ? getSendNowButton() : nil].compactMap { $0 }
        let pickerConfig = ScheduleSendPickerConfig(title: BundleI18n.LarkMessageCore.Lark_IM_ScheduleMessage_CustomTime_Title2,
                                                    date: self.currentSelectDate ?? Date(),
                                                    timeZone: .current,
                                                    dateWheelConfig: config,
                                                    bottomButtons: bottomButtons)
        let datePicker = ScheduleSendPickerViewController(config: pickerConfig)

        // 选择时间后的回调
        datePicker.dateChanged = { [weak self, weak datePicker] date in
            guard let self = self, let minDate = self.minDate, let maxDate = self.maxDate, let currentSelectDate = self.currentSelectDate else { return }
            // 当选择时间小于minDate 或者 大于maxDate，不进行选择
            if date < minDate {
                datePicker?.select(date: minDate, animated: true)
            } else if date > maxDate {
                datePicker?.select(date: maxDate, animated: true)
            } else {
                self.stashDate = date
            }
        }
        let actionPanel = UDActionPanel(
            customViewController: datePicker,
            config: UDActionPanelUIConfig(
                originY: UIScreen.main.bounds.height - datePicker.intrinsicHeight,
                canBeDragged: false
            )
        )
        from.present(actionPanel, animated: true, completion: nil)

        // 获取“保存”按钮
        func getSaveButton() -> ScheduleSendPickerButtonItem {
            ScheduleSendPickerButtonItem(identify: sendTimeIdentify,
                                         title: NSAttributedString(string: BundleI18n.LarkMessageCore.Lark_IM_ScheduleMessage_Reschedule_Save_Button,
                                                                   attributes: [.foregroundColor: UIColor.ud.primaryOnPrimaryFill, .font: UIFont.systemFont(ofSize: 17)]),
                                         cornerRadius: 6,
                                         borderWidth: 0.5,
                                         borderColor: UIColor.ud.N500.cgColor,
                                         backgroundColor: UIColor.ud.primaryContentDefault,
                                         handler: { [weak self] vc in
                                             // 保存选择的时间，并刷新picker上的按钮的时间显示
                                             self?.currentSelectDate = self?.stashDate
                                             if let date = self?.currentSelectDate {
                                                 confirmTask(date)
                                             }
                                             vc.dismiss(animated: true)
                                         })
        }

        // 获取“立即发送”按钮
        func getSendNowButton() -> ScheduleSendPickerButtonItem {
            let task: (UIViewController) -> Void = { vc in
                vc.dismiss(animated: true)
                let sheet = UDActionSheet(config: UDActionSheetUIConfig(isShowTitle: true))
                sheet.setTitle(BundleI18n.LarkMessageCore.Lark_IM_ScheduleMessage_SendToGroupNow_Title(chatName))
                sheet.addDefaultItem(text: BundleI18n.LarkMessageCore.Lark_IM_ScheduleMessage_SendNow_Button) {
                    sendNowCallback()
                }
                // 继续编辑
                sheet.setCancelItem(text: BundleI18n.LarkMessageCore.Lark_IM_ScheduleMessage_DeleteDateAndTimeScheduleCanceled_ContinueEditing_Button)
                from.present(sheet, animated: true)
            }
            return ScheduleSendPickerButtonItem(identify: "send",
                                         title: NSAttributedString(string: BundleI18n.LarkMessageCore.Lark_IM_ScheduleMessage_SendNow_Button,
                                                                   attributes: [.foregroundColor: UIColor.ud.textTitle, .font: UIFont.systemFont(ofSize: 17)]),
                                         cornerRadius: 6,
                                         borderWidth: 0.5,
                                         borderColor: UIColor.ud.lineBorderComponent.cgColor,
                                         backgroundColor: UIColor.ud.udtokenComponentOutlinedBg,
                                         handler: { vc in
                                            task(vc)
                                         })
        }
    }

    // 打开时间选择器
    public func showDatePicker(currentInitDate: Date,
                               currentSelectDate: Date,
                               from: UIViewController,
                               confirmTask: @escaping (Int64) -> Void) {
        let config = UDWheelsStyleConfig(mode: .dayHourMinute(),
                                         maxDisplayRows: 5,
                                         is12Hour: is12HourTime,
                                         minInterval: 1,
                                         textFont: UIFont.systemFont(ofSize: 17))
        self.minDate = currentInitDate
        self.maxDate = Date().addingTimeInterval(3600 * 24 * 32)
        self.currentSelectDate = currentSelectDate
        let sendTimeIdentify = "sendTime"
        let timeDesc = formatTimeDescWithDate(currentSelectDate,
                                              is12HourStyle: self.is12HourTime,
                                              isRelativeDate: true)
        let bottomButtons = [
            // 定时发送
            ScheduleSendPickerButtonItem(identify: sendTimeIdentify,
                                         title: NSAttributedString(string: BundleI18n.LarkMessageCore.Lark_IM_ScheduleMessage_CustomTime_SendAtTime_Text(" \(timeDesc)"),
                                                                   attributes: [.foregroundColor: UIColor.ud.primaryOnPrimaryFill, .font: UIFont.systemFont(ofSize: 17)]),
                                         cornerRadius: 6,
                                         borderWidth: 0.5,
                                         borderColor: UIColor.ud.N500.cgColor,
                                         backgroundColor: UIColor.ud.primaryContentDefault,
                                         handler: { vc in
                                             vc.dismiss(animated: true)
                                             let time = Int64(self.currentSelectDate?.timeIntervalSince1970 ?? 0) ?? 0
                                             confirmTask(time)
                                         })]
        let pickerConfig = ScheduleSendPickerConfig(title: BundleI18n.LarkMessageCore.Lark_IM_ScheduleMessage_CustomTime_Title2,
                                                    date: self.currentSelectDate ?? Date(),
                                                    timeZone: .current,
                                                    dateWheelConfig: config,
                                                    bottomButtons: bottomButtons)
        let datePicker = ScheduleSendPickerViewController(config: pickerConfig)

        datePicker.dateChanged = { [weak self, weak datePicker] date in
            guard let self = self, let minDate = self.minDate, let maxDate = self.maxDate, let currentSelectDate = self.currentSelectDate else { return }
            // 当选择时间小于minDate 或者 大于maxDate，不进行选择
            if date < minDate {
                datePicker?.select(date: minDate, animated: true)
            } else if date > maxDate {
                datePicker?.select(date: maxDate, animated: true)
            } else {
                // 保存选择的时间，并刷新picker上的按钮的时间显示
                self.currentSelectDate = date
                let timeDesc = self.formatTimeDescWithDate(self.currentSelectDate,
                                                           is12HourStyle: self.is12HourTime,
                                                           isRelativeDate: date.day <= currentInitDate.day + 1)
                let attr = NSAttributedString(string: BundleI18n.LarkMessageCore.Lark_IM_ScheduleMessage_CustomTime_SendAtTime_Text(timeDesc),
                                              attributes: [.foregroundColor: UIColor.ud.primaryOnPrimaryFill, .font: UIFont.systemFont(ofSize: 17)])
                datePicker?.updateBottomButtonWith(identify: sendTimeIdentify, title: attr)
            }
        }
        let actionPanel = UDActionPanel(
            customViewController: datePicker,
            config: UDActionPanelUIConfig(
                originY: UIScreen.main.bounds.height - datePicker.intrinsicHeight,
                canBeDragged: false
            )
        )
        from.present(actionPanel, animated: true, completion: nil)
    }

    static public func formatSendScheduleTime(_ time: Int64) -> Int64 {
        let formatTime = TimeInterval(time)
        let date = Date(timeIntervalSince1970: formatTime)
        return Int64(formatSendScheduleDate(date).timeIntervalSince1970) ?? time
    }

    ///  若当前时间离最近的整点差5分钟以上时就展示最近的整点；
    ///  若当前时间离最近的整点差五分钟以下就展示最近的整点+1
    ///   - 举例：当前时间为今天13：46-->自定义预设的时间为今天14：00;
    ///          当前时间为今天13：56-->自定义预设的时间为今天15：00
    static public func getFutureHour(_ date: Date) -> Date {
        var components = date.calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second, .nanosecond],
            from: date)
        guard let hour = components.hour, let min = components.minute else {
            return date
        }
        components.hour = min < 55 ? hour + 1 : hour + 2
        components.minute = 0
        components.second = 0
        components.nanosecond = 0
        return date.calendar.date(from: components) ?? date
    }

    // 返回整点整分钟
    static public func formatSendScheduleDate(_ date: Date) -> Date {
        var components = date.calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second, .nanosecond],
            from: date)
        guard let hour = components.hour, let min = components.minute else {
            return date
        }
        components.hour = hour
        components.minute = min
        components.second = 0
        components.nanosecond = 0
        return date.calendar.date(from: components) ?? date
    }

    // isShowYear = false 将日期格式化为： 5月28日（周二）下午 3:00
    // isShowYear = true 将日期格式化为：2022年5月28日（周二）下午 3:00
    static func formatScheduleTimeWithDate(_ date: Date?,
                                           is12HourStyle: Bool,
                                           isShowYear: Bool) -> String {
        guard let date = date else { return "" }
        var option = Options(
            timeZone: TimeZone.current,
            is12HourStyle: is12HourStyle,
            shouldRemoveTrailingZeros: false)
        option.timeFormatType = .short
        option.timePrecisionType = .minute
        let timeDesc = TimeFormatUtils.formatTime(from: date, with: option)
        option.dateStatusType = .absolute
        option.datePrecisionType = .day
        option.timeFormatType = isShowYear ? .long : .short
        let dateDesc = TimeFormatUtils.formatFullDate(from: date, with: option)

        return dateDesc + " " + timeDesc
    }

    // 将日期格式化为： 2020/2/5 下午 3:00
    private func formatTimeDescWithDate(_ date: Date?,
                                        is12HourStyle: Bool,
                                        isRelativeDate: Bool) -> String {
        guard let date = date else { return "" }
        var option = Options(
            timeZone: TimeZone.current,
            is12HourStyle: is12HourStyle,
            timePrecisionType: .minute,
            shouldRemoveTrailingZeros: false)
        let timeDesc = TimeFormatUtils.formatTime(from: date, with: option)
        option.dateStatusType = .relative
        let dateDesc = isRelativeDate ? TimeFormatUtils.formatDate(from: date, with: option) : "\(date.year)/\(date.month)/\(date.day)"
        return BundleI18n.LarkMessageCore.Calendar_StandardTime_RelativeDateTimeCombineFormat(dateDesc, timeDesc)
    }

    // 初次编辑定时消息选择关闭
    public func showAlertWhenSchuduleExitButtonTap(from: UIViewController,
                                                   chatID: Int64,
                                                   closeTask: @escaping () -> Void,
                                                   continueTask: @escaping () -> Void) {
        let sheet = UDActionSheet(config: UDActionSheetUIConfig(isShowTitle: true))
        sheet.setTitle(BundleI18n.LarkMessageCore.Lark_IM_ScheduleMessage_DiscardUnsavedChanges_Title)
        sheet.addDefaultItem(text: BundleI18n.LarkMessageCore.Lark_IM_ScheduleMessage_DeleteDateAndTimeScheduleCanceled_Cancel_Button) {
            closeTask()
        }
        // 继续编辑
        sheet.setCancelItem(text: BundleI18n.LarkMessageCore.Lark_IM_ScheduleMessage_DiscardUnsavedChanges_BackToEditing_Button) {
            continueTask()
        }
        from.present(sheet, animated: true)
    }

    //swiftlint:disable all
    public func patchScheduleMessage(chatID: Int64,
                                     messageId: String,
                                     messageType: Basic_V1_Message.TypeEnum?,
                                     itemType: Basic_V1_ScheduleMessageItem.ItemType,
                                     cid: String,
                                     content: QuasiContent,
                                     scheduleTime: Int64?,
                                     isSendImmediately: Bool,
                                     needSuspend: Bool,
                                     callback: @escaping (Result<PatchScheduleMessageResponse, Error>) -> Void) {
        var item = ScheduleMessageItem()
        item.itemID = messageId
        item.itemType = itemType
        self.postSendService?
            .patchScheduleMessage(chatID: chatID,
                                  cid: cid,
                                  item: item,
                                  messageType: messageType,
                                  content: content,
                                  scheduleTime: scheduleTime,
                                  isSendImmediately: isSendImmediately,
                                  needSuspend: needSuspend,
                                  callback: callback)
    }
    //swiftlint:enable all

    // 二次编辑定时消息选择关闭
    public func showAlertWhenSchuduleCloseButtonTap(from: UIViewController,
                                                    chatID: Int64,
                                                    itemId: String,
                                                    itemType: RustPB.Basic_V1_ScheduleMessageItem.ItemType,
                                                    cancelTask: @escaping () -> Void,
                                                    closeTask: @escaping () -> Void,
                                                    continueTask: @escaping () -> Void) {
        let sheet = UDActionSheet(config: UDActionSheetUIConfig())
        // 放弃修改
        sheet.addDefaultItem(text: BundleI18n.LarkMessageCore.Lark_IM_ScheduleMessage_DiscardChanges_Button) {
            cancelTask()
        }
        // 关闭定时发送
        sheet.addItem(.init(
            title: BundleI18n.LarkMessageCore.Lark_IM_ScheduleMessage_DeleteScheduledMessage_Button,
            titleColor: UIColor.ud.colorfulRed,
            action: { [weak self] in
                guard let self = self else { return }
                closeTask()
                var item = ScheduleMessageItem()
                item.itemID = itemId
                item.itemType = itemType
                // 删除定时消息
                self.deleteScheduleMsg(chatID: chatID,
                                       messageType: nil,
                                       item: item,
                                       patchType: .delete,
                                       scheduleTime: nil,
                                       isSendImmediately: false,
                                       content: nil,
                                       deleteSuccessTask: { },
                                       from: from)
            })
        )
        // 继续编辑
        sheet.setCancelItem(text: BundleI18n.LarkMessageCore.Lark_IM_ScheduleMessage_DeleteDateAndTimeScheduleCanceled_ContinueEditing_Button) {
            continueTask()
        }
        from.present(sheet, animated: true)
    }

    private func deleteScheduleMsg(chatID: Int64,
                                   messageType: Basic_V1_Message.TypeEnum?,
                                   item: ScheduleMessageItem,
                                   patchType: PatchScheduleMessageType,
                                   scheduleTime: Int64?,
                                   isSendImmediately: Bool,
                                   content: QuasiContent?,
                                   deleteSuccessTask: @escaping () -> Void,
                                   from: UIViewController) {
        guard let messageAPI = self.messageAPI else {
            return
        }
        // 先调用暂停，同步sdk本地updating状态，然后调用删除
        messageAPI
            .patchScheduleMessageRequest(chatID: chatID,
                                         messageType: nil,
                                         patchObject: item,
                                         patchType: .updating,
                                         scheduleTime: nil,
                                         isSendImmediately: false,
                                         needSuspend: false,
                                         content: nil)
            .flatMap { _ in
                messageAPI
                    .patchScheduleMessageRequest(chatID: chatID,
                                                 messageType: nil,
                                                 patchObject: item,
                                                 patchType: .delete,
                                                 scheduleTime: nil,
                                                 isSendImmediately: false,
                                                 needSuspend: false,
                                                 content: nil)
            }
            .subscribe(onNext: { (_) in
                deleteSuccessTask()
            }, onError: { error in
                Self.logger.error("patchScheduleMessageRequest error", error: error)
            }).disposed(by: self.disposeBag)

    }

    // 定时消息为空
    public func showAlertWhenContentNil(from: UIViewController,
                                        chatID: Int64,
                                        itemId: String,
                                        itemType: RustPB.Basic_V1_ScheduleMessageItem.ItemType,
                                        deleteConfirmTask: @escaping () -> Void,
                                        deleteSuccessTask: @escaping () -> Void) {
        let sheet = UDActionSheet(config: UDActionSheetUIConfig(isShowTitle: true))
        sheet.setTitle(BundleI18n.LarkMessageCore.Lark_IM_ScheduleMessage_DeleteScheduledMessage_Desc)
        sheet.addItem(.init(
            title: BundleI18n.LarkMessageCore.Lark_IM_ScheduleMessage_DeleteMessage_Button,
            titleColor: UIColor.ud.colorfulRed,
            action: { [weak self] in
                guard let self = self else { return }
                deleteConfirmTask()
                var item = ScheduleMessageItem()
                item.itemID = itemId
                item.itemType = itemType
                self.deleteScheduleMsg(chatID: chatID,
                                       messageType: nil,
                                       item: item,
                                       patchType: .delete,
                                       scheduleTime: nil,
                                       isSendImmediately: false,
                                       content: nil,
                                       deleteSuccessTask: deleteSuccessTask,
                                       from: from)
            })
        )
        // 继续编辑
        sheet.setCancelItem(text: BundleI18n.LarkMessageCore.Lark_IM_ScheduleMessage_DeleteDateAndTimeScheduleCanceled_ContinueEditing_Button)
        from.present(sheet, animated: true)
    }

    public func getSummerize(message: Message) -> NSAttributedString {
        let iconColor = UIColor.ud.textCaption
        let defautAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.ud.body2,
            .foregroundColor: UIColor.ud.textCaption
        ]
        var contentStr = NSMutableAttributedString(string: "")

        var richText: Basic_V1_RichText?
        var docEntity: RustPB.Basic_V1_DocEntity?
        if message.type == .text, let content = message.content as? TextContent {
            richText = content.richText
            docEntity = content.docEntity
        } else if message.type == .post, let content = message.content as? PostContent {
            richText = content.richText
            docEntity = content.docEntity
        }
        if let richText = richText {
            let fixRichText = richText.lc.convertText(tags: [.img, .media])
            let textDocsVM = TextDocsViewModel(userResolver: self.userResolver, richText: fixRichText, docEntity: docEntity, hangPoint: message.urlPreviewHangPointMap)
            let parseResult = textDocsVM.parseRichText(
                isShowReadStatus: false,
                checkIsMe: { _ in false },
                maxLines: 1,
                needNewLine: false,
                iconColor: iconColor,
                customAttributes: defautAttributes,
                urlPreviewProvider: nil
            )
            contentStr = NSMutableAttributedString(attributedString: parseResult.attriubuteText)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            contentStr.addAttributes([.paragraphStyle: paragraphStyle], range: NSRange(location: 0, length: contentStr.length))
        }
        return contentStr
    }

    public func showFailAlert(from: UIViewController,
                              message: Message,
                              itemType: Basic_V1_ScheduleMessageItem.ItemType,
                              title: String,
                              chat: Chat,
                              pasteboardToken: String) {
        let alertController = LarkAlertController()
        alertController.setTitle(text: title)
        alertController.setContent(attributedText: self.getSummerize(message: message),
                                   numberOfLines: 3)
        // 添加”复制消息“
        alertController.addSecondaryButton(text: BundleI18n.LarkMessageCore.Lark_IM_ScheduleMessage_Failed_CopyMessage_Button,
                                           dismissCompletion: { [weak self] in
            guard let self = self else { return }
            let handler = CopyMenuActionHandler(userResolver: self.userResolver,
                                                targetVC: from,
                                                pasteboardToken: pasteboardToken)
            handler.handle(message: message, chat: chat, params: [:])
        })
        alertController.addCancelButton()
        // 添加”删除消息“
        alertController.addDestructiveButton(text: BundleI18n.LarkMessageCore.Lark_IM_ScheduleMessage_DeleteMessage_Button,
                                             dismissCompletion: { [weak self] in
            guard let self = self else { return }
            var item = ScheduleMessageItem()
            item.itemID = message.id
            item.itemType = itemType
            // 删除定时消息
            self.deleteScheduleMsg(chatID: Int64(chat.id) ?? 0,
                                   messageType: nil,
                                   item: item,
                                   patchType: .delete,
                                   scheduleTime: nil,
                                   isSendImmediately: false,
                                   content: nil,
                                   deleteSuccessTask: { },
                                   from: from)
        })
        from.present(alertController, animated: true)
    }

    // 检查当前时区对应的时间是否能展示引导
    public func checkTimezoneCanShowGuide(timezone: String) -> Bool {
        guard let chatterTimeZone = TimeZone(identifier: timezone) else { return false }
        guard let hourDesc = Date().lf.formatedOnlyTime(accurateToSecond: false, timeZone: chatterTimeZone).split(separator: ":").first, let hour = Int(hourDesc) else { return false }
        // 只有在晚上10点到早上8点之间才显示引导
        return hour < 8 || hour >= 22
    }

    // chat是否能定时发送
    public static func chatCanScheduleSend(_ chat: Chat) -> Bool {
        // 密盾聊和密聊不支持
        if chat.isPrivateMode || chat.isCrypto { return false }
        // 临时入会用户不支持
        if chat.isInMeetingTemporary { return false }
        // 话题模式不支持创建
        if chat.displayInThreadMode { return false }
        return true
    }
}
