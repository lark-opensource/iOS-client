//
//  CCMSearchSegmentPlaceHolderView.swift
//  CCMMod
//
//  Created by Weston Wu on 2023/6/5.
//

#if MessengerMod
import LarkSearchCore
import LarkModel
import EENavigator
import RxSwift
import RxCocoa
import RxRelay
import LarkUIKit

protocol CCMSearchSegmentPlaceHolderViewModelType: SearchPickerDelegate {
    var actionSignal: Signal<CCMSearchAction> { get }
    func generateSearchConfig() -> PickerSearchConfig
}

// 没有内容、占位用，适合没有额外内容的 segmentView
class CCMSearchSegmentPlaceHolderView: UIView, CCMSearchFilterViewType {

    weak var hostController: SearchPickerControllerType?
    let viewModel: CCMSearchSegmentPlaceHolderViewModelType

    var pickerDelegate: SearchPickerDelegate {
        viewModel
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 0)
    }

    private let disposeBag = DisposeBag()

    init(viewModel: CCMSearchSegmentPlaceHolderViewModelType) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        viewModel.actionSignal.emit(onNext: { [weak self] action in
            self?.handle(action: action)
        })
        .disposed(by: disposeBag)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func didActive() {
        let config = viewModel.generateSearchConfig()
        handle(action: .update(searchConfig: config))
    }

    private func handle(action: CCMSearchAction) {
        guard var hostController else { return }
        switch action {
        case let .update(searchConfig):
            hostController.searchConfig = searchConfig
            hostController.reload()
        case let .present(controller):
            Navigator.shared.present(controller, from: hostController)
        case let .presentBody(body):
            Navigator.shared.present(body: body,
                                     wrap: LkNavigationController.self,
                                     from: hostController,
                                     prepare: { $0.modalPresentationStyle = .formSheet })
        case let .push(controller):
            Navigator.shared.push(controller, from: hostController)
        case let .showDetail(controller):
            Navigator.shared.docs.showDetailOrPush(controller, from: hostController)
        case let .openURL(url):
            Navigator.shared.docs.showDetailOrPush(url, from: hostController)
        }
    }
}

#endif
