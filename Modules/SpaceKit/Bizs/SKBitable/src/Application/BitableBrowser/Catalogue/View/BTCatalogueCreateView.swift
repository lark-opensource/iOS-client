//
//  BitableCatalogueBottomView.swift
//  SKSheet
//
//  Created by huayufan on 2021/3/22.
//  


import UIKit
import SnapKit
import RxCocoa
import RxSwift
import UniverseDesignColor
import SKResource

protocol CatalogueCreateViewData {
    var title: String { get }
    var image: UIImage? { get }
    var id: CatalogueOprationId? { get }
    var style: BTCatalogueModel.BottomFixedStyle { get }
    var showBadge: Bool { get }
}

final class BTCatalogueCreateView: BTPanelBottomView {

    init() {
        super.init(layoutMode: .multi)
        setup()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        backgroundColor = UDColor.bgFloat
    }
    
    func update(_ data: CatalogueCreateViewData?) {
        buttonTitleLabel.text = data?.title
        if data?.style == .disable {
            buttonTitleLabel.textColor = .ud.textDisabled
            buttonIconView.image = data?.image?.ud.withTintColor(UDColor.iconDisabled)
        } else {
            buttonTitleLabel.textColor = .ud.textTitle
            buttonIconView.image = data?.image?.ud.withTintColor(UDColor.iconN1)
        }
        rightBadge.config.text = data?.showBadge == true ? BundleI18n.SKResource.Bitable_Common_NewStatus : ""  // UDBadge 无法通过控制 isHidden 来控制显示隐藏，因此这里通过 text 来控制
    }
}

extension Reactive where Base: BTCatalogueCreateView {
    
    var data: Binder<CatalogueCreateViewData?> {
        return Binder(base) { (target, data) in
            target.update(data)
        }
    }
    
    var action: Observable<Void> {
        return base.button
                   .rx
                   .controlEvent(.touchUpInside)
                   .asObservable()
    }
}

final class BTCatalogueCreateStackView: UIView {
    
    private struct Layout {
        static let buttonHeight: CGFloat = 48
        static let spacing: CGFloat = 16
    }
    
    static func height(_ count: Int) -> CGFloat {
        if count <= 0 {
            return 0
        }
        return Layout.buttonHeight * CGFloat(count) + Layout.spacing * CGFloat(count + 1)
    }
    
    private lazy var topSeperatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()
    
    private lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.alignment = .fill
        view.spacing = Layout.spacing
        return view
    }()
    
    var actionSubject = PublishSubject<(CatalogueCreateViewData, BTCatalogueCreateView)>()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        backgroundColor = .ud.bgFloat
        
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Layout.spacing)
        }
        
        addSubview(topSeperatorView)
        topSeperatorView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }
    
    private let disposeBag = DisposeBag()
    
    func update(_ data: [CatalogueCreateViewData]?) {
        let count = data?.count ?? 0
        for i in 0..<count {
            if let iData = data?[i] {
                if i < stackView.arrangedSubviews.count, let iView = stackView.arrangedSubviews[i] as? BTCatalogueCreateView {
                    iView.isHidden = false
                    iView.update(iData)
                } else {
                    let iView = BTCatalogueCreateView()
                    stackView.addArrangedSubview(iView)
                    iView.update(iData)
                    iView.snp.makeConstraints { make in
                        make.height.equalTo(Layout.buttonHeight)
                    }
                    
                    iView.rx.action.subscribe { [weak self] _ in
                        self?.actionSubject.onNext((iData, iView))
                    }.disposed(by: disposeBag)
                }
            }
        }
        for i in count..<stackView.arrangedSubviews.count {
            stackView.arrangedSubviews[i].isHidden = true
        }
    }
}

extension Reactive where Base: BTCatalogueCreateStackView {
    
    var data: Binder<[CatalogueCreateViewData]?> {
        return Binder(base) { (target, data) in
            target.update(data)
        }
    }
    
    var action: Observable<(CatalogueCreateViewData, BTCatalogueCreateView)> {
        return base.actionSubject.asObservable()
    }
}
