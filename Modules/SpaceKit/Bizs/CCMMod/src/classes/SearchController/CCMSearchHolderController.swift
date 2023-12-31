//
//  CCMSearchHolderController.swift
//  CCMMod
//
//  Created by ZhangYuanping on 2023/7/13.
//  


#if MessengerMod
import Foundation
import SKFoundation
import SKCommon
import RxSwift
import RxCocoa
import RxRelay
import LarkSearchCore
import LarkModel
import EENavigator

class CCMSearchHolderController: BaseViewController {

    let viewModel: CCMSimpleSearchBaseViewModel
    let searchVC: SearchPickerViewController

    private let disposeBag = DisposeBag()

    init(searchVC: SearchPickerViewController, viewModel: CCMSimpleSearchBaseViewModel) {
        self.searchVC = searchVC
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(searchVC)
        view.addSubview(searchVC.view)
        searchVC.didMove(toParent: self)
        searchVC.view.snp.makeConstraints { (make) in
            make.top.equalTo(navigationBar.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }

        viewModel.actionSignal.emit(onNext: { [weak self] action in
            guard let self else { return }
            if case .push(let vc) = action {
                Navigator.shared.push(vc, from: self)
            }
        })
        .disposed(by: disposeBag)
    }
}

#endif
