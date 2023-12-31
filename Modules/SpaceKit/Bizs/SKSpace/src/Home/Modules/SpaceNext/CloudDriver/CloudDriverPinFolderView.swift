//
//  CloudDriverPinFolderView.swift
//  SKSpace
//
//  Created by majie.7 on 2023/12/6.
//

import Foundation
import SKFoundation
import RxSwift
import RxRelay
import RxCocoa
import UniverseDesignColor
import UniverseDesignIcon
import SKCommon
import SKResource

// layout相关
extension CloudDriverPinFolderView {
    private var maxItemsCount: Int {
        let ipadCount = 3
        let phoneCount = 2
        return isShowInDetail ? ipadCount : phoneCount
    }
    
    private var pinFolderViewInset: CGFloat {
        let ipadInset: CGFloat = 24
        let phoneInset: CGFloat = 16
        return isShowInDetail ? ipadInset : phoneInset
    }
    
    private var pinFolderViewHeight: CGFloat {
        let ipadHeight: CGFloat = 86
        let phoneHeight: CGFloat = 64
        return isShowInDetail ? ipadHeight : phoneHeight
    }
    
    public var viewHeight: CGFloat {
        let ipadHeight: CGFloat = 134
        let phoneHeight: CGFloat = 118
        return isShowInDetail ? ipadHeight : phoneHeight
    }
}

class CloudDriverPinFolderView: UIView {
    let viewModel: QuickAccessViewModel
    
    // UI相关
    private lazy var pinFolderGridView: PinFolderGridView = {
        let view = PinFolderGridView(isShowInDetail: isShowInDetail)
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.SKResource.Doc_List_Quick_Access
        label.font = .systemFont(ofSize: isShowInDetail ? 16 : 14, weight: .medium)
        return label
    }()
    
    public lazy var viewAllButton: UIControl = {
        let view = UIControl()
        view.docs.addStandardHighlight()
        view.hitTestEdgeInsets = UIEdgeInsets(top: -6, left: -6, bottom: -6, right: -6)
        return view
    }()
    
    private lazy var moreImageView: UIImageView = {
        let arrowImageView = UIImageView()
        arrowImageView.image = UDIcon.rightOutlined.withRenderingMode(.alwaysTemplate)
        arrowImageView.tintColor = UDColor.primaryContentDefault
        arrowImageView.contentMode = .scaleAspectFit
        return arrowImageView
    }()

    private lazy var moreLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = UDColor.primaryContentDefault
        label.text = BundleI18n.SKResource.Doc_List_All
        return label
    }()
    
    private lazy var indicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.bgBase
        return view
    }()
    
    private var items: [SpaceListItem] = []
    
    // 通知信号
    private var updateShowStatusRelay = PublishRelay<Bool>()
    var updateShowStatusSignal: Signal<Bool> {
        updateShowStatusRelay.asSignal()
    }
    
    private let disposeBag = DisposeBag()
    private let isShowInDetail: Bool
    
    init(viewModel: QuickAccessViewModel, isShowInDetail: Bool = false) {
        self.viewModel = viewModel
        self.isShowInDetail = isShowInDetail
        super.init(frame: .zero)
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(titleLabel)
        addSubview(pinFolderGridView)
        addSubview(moreLabel)
        addSubview(moreImageView)
        addSubview(viewAllButton)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(12)
            make.left.equalToSuperview().inset(pinFolderViewInset)
            make.right.equalToSuperview()
            make.height.equalTo(22)
        }
        
        pinFolderGridView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(pinFolderViewInset)
            make.height.equalTo(pinFolderViewHeight)
        }
        
        moreImageView.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.right.equalToSuperview().inset(pinFolderViewInset)
            make.height.equalTo(16)
        }
        
        moreLabel.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.right.equalTo(moreImageView.snp.left).offset(-2)
        }
        
        viewAllButton.snp.makeConstraints { make in
            make.left.equalTo(moreLabel)
            make.right.equalTo(moreImageView)
            make.top.equalTo(moreLabel)
            make.bottom.equalTo(moreImageView)
        }
        
        if !isShowInDetail {
            addSubview(indicatorView)
            indicatorView.snp.makeConstraints { make in
                make.top.equalTo(pinFolderGridView.snp.bottom)
                make.left.right.equalToSuperview()
                make.height.equalTo(8)
            }
        }
    }
    
    func prepare() {
        pinFolderGridView.clickHandler = { [weak self] index in
            guard let self else { return }
            guard index < self.items.count else {
                assertionFailure()
                return
            }
            let item = items[index]
            self.viewModel.select(at: index, item: .spaceItem(item: item))
        }
        
        pinFolderGridView.moreHandler = { [weak self] item, view in
            let handler = self?.viewModel.handleMoreAction(for: item.entry)
            handler?(view)
        }
        
        viewModel.itemsUpdated
            .observeOn(SerialDispatchQueueScheduler(internalSerialQueueName: "space.pin.folder.view"))
            .subscribe(onNext: { [weak self] items in
                guard let self = self else { return }
                let folderItems: [SpaceListItem] = items.compactMap { itemType in
                    guard case let .spaceItem(item) = itemType else {
                        return nil
                    }
                    return item
                }
                self.items = Array(folderItems.prefix(self.maxItemsCount))
                
                self.updateShowStatusRelay.accept(!folderItems.isEmpty)
                DispatchQueue.main.async {
                    self.pinFolderGridView.update(items: self.items)
                    self.pinFolderGridView.layoutIfNeeded()
                    
                    if items.count > self.maxItemsCount {
                        self.changeViewAllButtonStatus(show: true)
                    } else {
                        self.changeViewAllButtonStatus(show: false)
                    }
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.prepare()
    }
    
    private func changeViewAllButtonStatus(show: Bool) {
        self.viewAllButton.isHidden = !show
        self.moreImageView.isHidden = !show
        self.moreLabel.isHidden = !show
    }
}
