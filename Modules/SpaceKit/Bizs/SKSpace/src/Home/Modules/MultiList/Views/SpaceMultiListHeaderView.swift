//
//  SpaceMultiListHeaderView.swift
//  SKECM
//
//  Created by Weston Wu on 2020/11/25.
//

import UIKit
import UniverseDesignColor
import SnapKit
import SKResource
import RxSwift
import RxRelay
import RxCocoa
import SKUIKit

public class SpaceMultiListHeaderView: UICollectionReusableView, SpaceMultiSectionHeaderView {

    public static let height: CGFloat = 36
    private lazy var toolBar: SpaceListToolBar = {
        let toolBar = SpaceListToolBar()
        return toolBar
    }()

    private lazy var pickerView: SpaceMultiListPickerView = {
        let pickerView = SpaceMultiListPickerView()
        return pickerView
    }()

    private lazy var bottomSeperator: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()

    private var sectionChangedRelay = PublishRelay<Int>()
    public var sectionChangedSignal: Signal<Int> { sectionChangedRelay.asSignal() }

    public let listToolConfigInput = PublishRelay<[SpaceListTool]>()
    public var ipadListHeaderConfigInput = PublishRelay<IpadListHeaderSortConfig?>()

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
        backgroundColor = UDColor.bgBody

        addSubview(bottomSeperator)
        bottomSeperator.snp.makeConstraints { make in
            make.bottom.left.right.equalToSuperview()
            make.height.equalTo(0.5)
        }

        addSubview(toolBar)
        toolBar.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.height.equalTo(Self.height)
            make.right.equalToSuperview()
        }

        addSubview(pickerView)
        pickerView.snp.makeConstraints { make in
            make.bottom.left.equalToSuperview()
            make.height.equalTo(Self.height)
            make.right.equalTo(toolBar.snp.left)
        }

        toolBar.setContentHuggingPriority(.required, for: .horizontal)
        pickerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        pickerView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        toolBar.setContentCompressionResistancePriority(.required, for: .horizontal)

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
        pickerView.cleanUp()
        toolBar.reset()
        // 重用时，需要换一个新的 relay 对象，否则旧的订阅还会受到事件
        sectionChangedRelay = PublishRelay<Int>()
    }

    public func update(items: [SpaceMultiListPickerItem], currentIndex: Int, shouldUseNewestStyle: Bool = false) {
        pickerView.update(items: items, currentIndex: currentIndex, shouldUseNewestStyle: shouldUseNewestStyle)
        self.bottomSeperator.isHidden = shouldUseNewestStyle
        pickerView.clickHandler = { [weak self] index in
            self?.sectionChangedRelay.accept(index)
        }
    }
    
    public static func height(mode: SpaceListDisplayMode) -> CGFloat {
        height
    }
}
