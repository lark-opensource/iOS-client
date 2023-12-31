//
//  MeetingRoomFormViewModel.swift
//  Calendar
//
//  Created by 王仕杰 on 2021/4/11.
//

import Foundation
import LarkContainer
import RxSwift
import RxRelay
import RustPB
import LKCommonsLogging

final class MeetingRoomFormViewModel: UserResolverWrapper {

    @ScopedInjectedLazy var calendarApi: CalendarRustAPI?

    let logger = Logger.log(MeetingRoomFormViewModel.self, category: "Calendar.MeetingRoom")

    let userResolver: UserResolver

    // 持有原始包含全量问题的表单 不随选择变动
    let originalForm: Rust.CustomizationForm

    let updateFormRelay = BehaviorRelay<(Rust.CustomizationForm, Rust.CustomizationFormSelections, Rust.CustomizationFormUserInputs)>(value: ([], [:], [:]))
    let allRequiredQuestionHasAnswer = BehaviorRelay<Bool>(value: false)
    let contactUpdateRelay = BehaviorRelay<[(String, String)]>(value: [])

    // 用户当前的选择
    let selectionsChangeRelay: BehaviorRelay<Rust.CustomizationFormSelections>
    // 用户的输入
    let inputChangeRelay: BehaviorRelay<Rust.CustomizationFormUserInputs>
    // 当前组合出来的表单
    let currentFormRelay: BehaviorRelay<Rust.CustomizationForm>

    private let bag = DisposeBag()

    init(originalForm: Rust.CustomizationForm, contactUserIDs: [String], userResolver: UserResolver) {
        // 修正原始表单中的默认值从 nil 变为对应类型的默认值, isSelected: nil -> false, inputContent: nil -> ""，用于 currentFormRelay 与 originalForm 判等操作
        self.originalForm = originalForm.map { question in
            var question = question
            question.options = question.options.map { option in
                var option = option
                option.isSelected = option.isSelected
                return option
            }
            if question.customizationType == .input {
                question.inputContent = question.inputContent
            }
            return question
        }
        currentFormRelay = .init(value: self.originalForm)
        self.userResolver = userResolver

        // 从原始表单中提取选项和输入
        let selectionKeyValues = originalForm.compactMap { question -> (String, [String])? in
            let selectedOptionKeys = question.options.filter(\.isSelected).map(\.optionKey)
            if selectedOptionKeys.isEmpty {
                return nil
            } else {
                return (question.indexKey, selectedOptionKeys)
            }
        }
        .map { (key, selectionKeys) -> (String, Calendar_V1_ParseCustomizedConfigurationRequest.SelectedKeys) in
            var selections = Calendar_V1_ParseCustomizedConfigurationRequest.SelectedKeys()
            selections.selectedOptionKeys = selectionKeys
            return (key, selections)
        }
        selectionsChangeRelay = .init(value: Dictionary(uniqueKeysWithValues: selectionKeyValues))

        let inputKeyValues = originalForm.compactMap { question -> (String, String)? in
            switch question.customizationType {
            case .singleSelect:
                fallthrough
            case .multipleSelect:
                if let content = question.options.first(where: \.isOthers)?.othersContent, !content.isEmpty {
                    return (question.indexKey, content)
                } else {
                    return nil
                }
            case .input:
                if !question.inputContent.isEmpty {
                    return (question.indexKey, question.inputContent)
                } else {
                    return nil
                }
            @unknown default:
                return nil
            }
        }
        inputChangeRelay = .init(value: Dictionary(uniqueKeysWithValues: inputKeyValues))

        guard let rustAPI = self.calendarApi else {
            logger.error("failed to get rustapi from larkcontainer")
            return
        }

        // 选择有变动的时候通过rustsdk更新表单
        let rustParseResult = selectionsChangeRelay
            .debug("rust parse input")
            .flatMapLatest { inputs -> Observable<Rust.CustomizationForm> in
                return rustAPI
                    .parseForm(inputs: inputs, originalForm: self.originalForm)
                    .debug("rust parse")
                    .catchError { _ in .empty() }
            }
            .share(replay: 1)

        // 表单变化时修改UI
        rustParseResult
            .compactMap { [weak self] in
                guard let self = self else { return nil }
                return ($0, self.selectionsChangeRelay.value, self.inputChangeRelay.value)
            }
            .bind(to: updateFormRelay)
            .disposed(by: bag)

        // 确保所有必填问题都有答案
        Observable.combineLatest(rustParseResult, inputChangeRelay)
            .compactMap { [weak self] form, inputs in
                guard let self = self else { return nil }
                let selections = self.selectionsChangeRelay.value
                return form.filter(\.isRequired)
                    .map { question in
                        switch question.customizationType {
                        case .input:
                            // 开放性问题要有输入
                            guard let input = inputs[question.indexKey] else { return false }
                            return !input.isEmpty
                        case .singleSelect:
                            // 单选必须要有选择
                            guard let selectedOptionKey = selections[question.indexKey],
                                  let option = question.options.first(where: { $0.optionKey == selectedOptionKey.selectedOptionKeys.first }) else { return false }
                            if option.isOthers {
                                // 开放性选项 必须要有输入
                                guard let input = inputs[question.indexKey] else { return false }
                                return !input.isEmpty
                            } else {
                                // 普通选项 有选择即可
                                return true
                            }
                        case .multipleSelect:
                            // 多选必须要选择或填写一个
                            guard let selectedOptionKeys = selections[question.indexKey] else { return false }
                            let selectedOptions = question.options.filter { selectedOptionKeys.selectedOptionKeys.contains($0.optionKey) }

                            if let otherOption = selectedOptions.filter(\.isOthers).first {
                                // 如果“其他”选项被选中 必须要有输入 否则不满足条件
                                guard let input = inputs[question.indexKey] else { return false }
                                return !input.isEmpty
                            } else {
                                // 如果“其他”选项未被选中 保证至少要有一个选项
                                return !selections.isEmpty
                            }
                        @unknown default:
                            return false
                        }
                    }
                    .reduce(true) { $0 && $1 }
            }
            .bind(to: allRequiredQuestionHasAnswer)
            .disposed(by: bag)

        Observable.combineLatest(selectionsChangeRelay, inputChangeRelay)
            .compactMap { [weak self] selection, inputs in
                guard let self = self else { return nil }
                var form = self.originalForm
                form = form.map { question in
                    var question = question
                    switch question.customizationType {
                    case .input:
                        question.inputContent = inputs[question.indexKey] ?? ""
                    case .singleSelect:
                        fallthrough
                    case .multipleSelect:
                        question.options = question.options.map { option in
                            var option = option
                            option.isSelected = selection[question.indexKey]?.selectedOptionKeys.contains(option.optionKey) ?? false
                            if option.isOthers && option.isSelected {
                                option.othersContent = inputs[question.indexKey] ?? ""
                            }
                            return option
                        }
                    @unknown default:
                        break
                    }
                    return question
                }
                return form
            }
            .bind(to: currentFormRelay)
            .disposed(by: bag)

        // 更新联系人信息
        Observable.just(contactUserIDs)
            .flatMapLatest {
                return rustAPI.parseUserIDToName(IDs: $0)
            }
            .map { dict in contactUserIDs.compactMap { dict[$0] == nil ? nil : ($0, dict[$0]!) } }
            .bind(to: contactUpdateRelay)
            .disposed(by: bag)

    }

    func update(questionKey: String, selections: [String]) {
        var currentSelections = selectionsChangeRelay.value
        if selections.isEmpty {
            currentSelections[questionKey] = nil
        } else {
            var keys = Calendar_V1_ParseCustomizedConfigurationRequest.SelectedKeys()
            keys.selectedOptionKeys = selections
            currentSelections[questionKey] = keys
        }
        selectionsChangeRelay.accept(currentSelections)
    }

    func update(questionKey: String, userInput: String) {
        var currentUserInputs = inputChangeRelay.value
        if userInput.isEmpty {
            currentUserInputs[questionKey] = nil
        } else {
            currentUserInputs[questionKey] = userInput
        }
        inputChangeRelay.accept(currentUserInputs)
    }

}
