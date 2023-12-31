//
//  SpaceMultiSectionNewTabHeaderView.swift
//  SKSpace
//
//  Created by majie.7 on 2023/9/12.
//

import Foundation
import UIKit
import SKUIKit
import RxSwift
import RxCocoa
import RxRelay
import UniverseDesignColor
import SKFoundation
import SKCommon

public protocol SpaceMultiSectionHeaderView: UICollectionReusableView {
    static var height: CGFloat { get }
    var sectionChangedSignal: Signal<Int> { get }
    var listToolConfigInput: PublishRelay<[SpaceListTool]> { get }
    
    var ipadListHeaderConfigInput: PublishRelay<IpadListHeaderSortConfig?> { get }
    
    func update(items: [SpaceMultiListPickerItem], currentIndex: Int, shouldUseNewestStyle: Bool)
    static func height(mode: SpaceListDisplayMode) -> CGFloat
}

public class SpaceMultiSectionNewTabHeaderView: UICollectionReusableView {
    
    private lazy var toolBar: SpaceListToolBar = {
        let toolBar = SpaceListToolBar()
        return toolBar
    }()
    
    private lazy var pickerView: SpaceNewTabPickerView = {
        let view = SpaceNewTabPickerView()
        return view
    }()
    
    private var disposeBag = DisposeBag()
    
    private var sectionChangedRelay = PublishRelay<Int>()
    public var sectionChangedSignal: Signal<Int> { sectionChangedRelay.asSignal() }
    
    public let listToolConfigInput = PublishRelay<[SpaceListTool]>()
    public var ipadListHeaderConfigInput = PublishRelay<IpadListHeaderSortConfig?>()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = UDColor.bgBody
        
        addSubview(pickerView)
        pickerView.addSubview(toolBar)
        
        pickerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        toolBar.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.height.equalTo(24)
            make.right.equalToSuperview()
        }
        
        listToolConfigInput.asSignal()
            .emit(onNext: { [weak self] newTools in
                self?.toolBar.reset()
                self?.toolBar.update(tools: newTools)
            })
            .disposed(by: disposeBag)
        
        
        toolBar.layoutAnimationSignal
            .emit(onNext: { [weak self] in
                guard let self = self else { return }
                UIView.animate(withDuration: 0.3) {
                    self.layoutIfNeeded()
                }
            })
            .disposed(by: disposeBag)
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        pickerView.cleanUP()
        toolBar.reset()
        sectionChangedRelay = PublishRelay<Int>()
    }
    
    public func update(items: [SpaceMultiListPickerItem], currentIndex: Int, shouldUseNewestStyle: Bool = false) {
        pickerView.update(items: items, currentIndex: currentIndex)
        pickerView.clickHandler = { [weak self] index in
            self?.sectionChangedRelay.accept(index)
        }
    }
}

extension SpaceMultiSectionNewTabHeaderView: SpaceMultiSectionHeaderView {
    public static var height: CGFloat {
        54
    }
    
    public static func height(mode: SpaceListDisplayMode) -> CGFloat {
        height
    }
}
