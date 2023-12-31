//
//  BitableMultiSectionHeader.swift
//  SKSpace
//
//  Created by qiyongka on 2023/11/9.
//

import Foundation
import UIKit
import SKUIKit
import RxSwift
import RxCocoa
import RxRelay
import UniverseDesignColor
import SKFoundation

public protocol BitableMultiSectionHeaderView: UICollectionReusableView {
    static var height: CGFloat { get }
    var sectionChangedSignal: Signal<Int> { get }
    func update(items: [BitableMultiListPickerItem], currentIndex: Int)
    static func height(mode: SpaceListDisplayMode) -> CGFloat
}

public class BitableMultiSectionHeader: UICollectionReusableView, BitableMultiSectionHeaderView {
    public static let height: CGFloat = 60
    private lazy var pickerView: BitableMultiListPickerView = {
        let pickerView = BitableMultiListPickerView()
        return pickerView
    }()

    private var sectionChangedRelay = PublishRelay<Int>()
    public var sectionChangedSignal: Signal<Int> { sectionChangedRelay.asSignal() }

    private var disposeBag = DisposeBag()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
     private func setupUI() {
        backgroundColor = UDColor.rgb("#FCFCFD") & UDColor.rgb("#202020")
        addSubview(pickerView)
        pickerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        //重用时，需要换一个新的 relay 对象，否则旧的订阅还会受到事件
        sectionChangedRelay = PublishRelay<Int>()
        pickerView.cleanUp()
    }

    public func update(items: [BitableMultiListPickerItem], currentIndex: Int) {
        pickerView.update(items: items, currentIndex: currentIndex)
        pickerView.clickHandler = { [weak self] index in
            self?.sectionChangedRelay.accept(index)
        }
    }
    
    public static func height(mode: SpaceListDisplayMode) -> CGFloat {
        height
    }
}
