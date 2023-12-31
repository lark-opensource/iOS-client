//
//  MentionViewModel.swift
//  LarkMention
//
//  Created by Yuri on 2022/6/1.
//

import Foundation
import RxSwift
import UIKit

public final class MentionViewModel {
    public struct State: CustomStringConvertible {
        public var isShowSkeleton = true
        public var isMultiSelected = false
        public var isGlobalCheckBoxSelected: Bool?
        public var searchText: String = ""
        public var isLoading: Bool = false
        public var hasMore: Bool = false
        
        // 是否重新加载数据,输入变化数据刷新此值为true，上拉刷新时此值应为false
        public var isReloading: Bool = true
        
        public var error: VMError?
        
        public var description: String {
            return "isShowSkeleton: \(isShowSkeleton), isLoading: \(isLoading) \(searchText), hasMore: \(hasMore), error: \(error.debugDescription ?? "")"
        }

        public init() { }
    }

    public init() { }
    
    public enum VMError: Error {
        case noResult
        case network(Error)
    }
    
    public var recommendItems: [PickerOptionType]?
    
    public var state = BehaviorSubject(value: State())
    public var currentState = State()
    
    var items = PublishSubject<[PickerOptionType]>()
    public var currentItems: [PickerOptionType] = []
    
    public var didStartLoadHandler: (([PickerOptionType], State) -> Void)?
    public var didEndLoadHandler: (([PickerOptionType], State) -> Void)?
    public var didSwitchMultiSelectHandler: (([PickerOptionType], State) -> Void)?
    public var didReloadItemAtRowHandler: (([PickerOptionType], [Int]) -> Void)?
    public var didCompleteHandler: (() -> Void)?
        
    func updateItemsCheck(items: [PickerOptionType]) {
        
        if currentState.isReloading {
            currentItems = items
        } else {
            let newitems = items.suffix(from: currentItems.count)
            currentItems.append(contentsOf: newitems)
        }
        
        guard currentState.isMultiSelected else { return }
        currentItems = currentItems.map {
            var i = $0
            i.isEnableMultipleSelect = true
            return i
        }
    }
    
    public func update(event: MentionLoadEvent) {
        switch event {
        case .empty:
            currentState.isLoading = false
            currentState.hasMore = false
            currentState.error = nil
            setEmptyView()
            didStartLoadHandler?(currentItems, currentState)
        case .reloading(let content):
            let hasCache = !currentItems.isEmpty && !currentState.isShowSkeleton
            if !hasCache { // 没有缓存需要展示骨架
                currentItems = Array(repeatElement(PickerOption(), count: 20))
                currentState.isShowSkeleton = true
            }
            currentState.isLoading = hasCache
            currentState.hasMore = false
            currentState.searchText = content
            currentState.error = nil
            currentState.isReloading = true
            didStartLoadHandler?(currentItems, currentState)
        case .load(let mentionResult):
            if currentState.searchText.isEmpty {
                setEmptyView()
            } else {
                currentState.isShowSkeleton = false
                currentState.hasMore = mentionResult.hasMore
                currentState.error = mentionResult.items.isEmpty ? VMError.noResult : nil
                updateItemsCheck(items: mentionResult.items)
            }
            currentState.isLoading = false
            currentState.isReloading = false
            didEndLoadHandler?(currentItems, currentState)
        case .fail(let err):
            currentState.isLoading = false
            currentState.isShowSkeleton = false
            currentState.error = VMError.network(err)
            currentItems = []
        default: break
        }
        state.onNext(currentState)
        items.onNext(currentItems)
    }
    
    func switchMultiSelect(isOn: Bool) {
        currentItems = currentItems.map {
            var item = $0
            item.isEnableMultipleSelect = true
            return item
        }
        currentState.isMultiSelected = isOn
        if isOn {
            didSwitchMultiSelectHandler?(currentItems, currentState)
        } else {
            didCompleteHandler?()
        }
        state.onNext(currentState)
        items.onNext(currentItems)
    }
    
    public func selectItem(at row: Int) {
        var item = currentItems[row]
        item.isMultipleSelected.toggle()
        currentItems[row] = item
        items.onNext(currentItems)
        if currentState.isMultiSelected {
            didReloadItemAtRowHandler?(currentItems, [row])
        } else {
            didCompleteHandler?()
        }
    }
    
    func switchGlobalCheckBox(isSelected: Bool) {
        currentState.isGlobalCheckBoxSelected = isSelected
        state.onNext(currentState)
    }
    
    // MARK: - Private
    private func setEmptyView() {
        if let items = recommendItems, !items.isEmpty {
            currentItems = items
            currentState.isShowSkeleton = false
        } else {
            currentItems = Array(repeatElement(PickerOption(), count: 20))
            currentState.isShowSkeleton = true
        }
    }
}
