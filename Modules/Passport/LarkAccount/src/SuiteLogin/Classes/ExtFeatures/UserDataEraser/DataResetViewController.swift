//
//  DataResetViewController.swift
//  LarkAccount
//
//  Created by ByteDance on 2023/7/4.
//

import Foundation
import LarkUIKit
import SnapKit

class DataResetViewController: PassportBaseViewController {

    private let loadingView = LoadingPlaceholderView()

    private let viewModel =  DataResetViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        makeSubViews()

        //开始重置数据
        viewModel.startResetData { _ in
            let resetFinishVC = PassportEmptyViewController(viewModel: DataResetFinishViewModel())
            if let navVC = self.navigationController {
                navVC.pushViewController(resetFinishVC, animated: true)
            } else {
                resetFinishVC.modalPresentationStyle = .fullScreen
                self.present(resetFinishVC, animated: true)
            }
        }
    }

    private func makeSubViews() {
        view.addSubview(loadingView)
        loadingView.snp.remakeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        loadingView.text = I18N.Lark_ClearLocalCacheAtLogOut_DataRecoveringPH
        loadingView.isHidden = false
        loadingView.backgroundColor = UIColor.clear
    }

}
