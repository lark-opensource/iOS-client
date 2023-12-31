//
//  CountDownRemindPickerViewModel.swift
//  ByteView
//
//  Created by wulv on 2022/8/12.
//

import Foundation
import UIKit

enum CountDownRemindPickTime: Equatable {
    case text(String?)
    case minute(Int)
}

extension CountDownRemindPickTime {

    static let placeholder: CountDownRemindPickTime = .text(nil)
    static let firstMinute: CountDownRemindPickTime = .text(I18n.View_VM_None)

    var title: String {
        switch self {
        case .text(let string):
            return string ?? ""
        case .minute(let m):
            return "\(m) " + I18n.View_G_MinuteUnit
        }
    }

    var value: Int? {
        switch self {
        case .text:
            return nil
        case .minute(let m):
            return m
        }
    }
}

struct PickerRemindCellModel {
    let title: NSAttributedString
    let time: CountDownRemindPickTime

    init(time: CountDownRemindPickTime) {
        self.time = time
        self.title = NSAttributedString(string: time.title, config: .h4, textColor: UIColor.ud.textTitle)
    }
}

typealias SelectCountDownRemindTime = ((CountDownRemindPickTime?) -> Void)

class CountDownRemindPickerViewModel {

    /// 默认1min
    static let defaultMinute: Int = 1

    private static let placeholdCount: Int = 3

    private(set) lazy var selectRealIndex: Int = realIndex(0)

    var afterBack: (() -> Void)?

    /// 可选最大值，必须大于1
    private let range: Int
    let defaultTime: CountDownRemindPickTime?
    private let selectComplete: SelectCountDownRemindTime
    init(range: Int, defaultTime: CountDownRemindPickTime?, selectComplete: @escaping SelectCountDownRemindTime) {
        self.range = range
        self.defaultTime = defaultTime
        self.selectComplete = selectComplete
    }

    private(set) lazy var pickerDataSource: [PickerRemindCellModel] = {
        var minutes = (1...range).map { PickerRemindCellModel(time: CountDownRemindPickTime.minute($0)) }
        minutes.insert(PickerRemindCellModel(time: CountDownRemindPickTime.firstMinute), at: 0)
        [CountDownRemindPickTime](repeatElement(CountDownRemindPickTime.placeholder, count: CountDownRemindPickerViewModel.placeholdCount)).forEach {
            let placeholder = PickerRemindCellModel(time: $0)
            minutes.insert(placeholder, at: 0)
            minutes.append(placeholder)
        }
        return minutes
    }()

    func updateSelectRow(_ row: Int) {
        selectRealIndex = realIndex(row)
    }

    func callbackSelectTime() {
        selectComplete(selectMinute())
    }
}

extension CountDownRemindPickerViewModel {

    /// picker回调的index是可选范围的row，需加上占位得到真实的index
    private func realIndex(_ row: Int) -> Int {
        return row + CountDownRemindPickerViewModel.placeholdCount
    }

    private func selectMinute() -> CountDownRemindPickTime? {
        guard let model = pickerDataSource[safeAccess: selectRealIndex] else {
            Logger.countDown.debug("incorrect select index: \(selectRealIndex)")
            return nil
        }
        return model.time
    }
}
