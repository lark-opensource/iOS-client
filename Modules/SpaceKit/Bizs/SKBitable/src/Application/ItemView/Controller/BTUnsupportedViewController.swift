//
// Created by duanxiaochen.7 on 2021/6/11.
// Affiliated with SKBitable.
//
// Description: 私有化部署下不支持 bitable 打开，当点击链接时会 push 进来


import SKUIKit
import SKFoundation
import SKResource
import SKCommon
import UniverseDesignEmpty

final class BTUnsupportedViewController: BaseViewController {

    private lazy var emptyView = UDEmptyView(config: .init(
        title: .init(titleText: ""),
        description: .init(descriptionText: BundleI18n.SKResource.Doc_Document_WillTransferToSheets),
        imageSize: 100,
        type: .noPreview,
        labelHandler: nil,
        primaryButtonConfig: nil,
        secondaryButtonConfig: nil
    )).construct { it in
        it.useCenterConstraints = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

}
