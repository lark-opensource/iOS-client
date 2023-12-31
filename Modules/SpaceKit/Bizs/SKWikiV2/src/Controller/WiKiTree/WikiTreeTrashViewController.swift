//
//  WikiTreeTrashViewController.swift
//  SKWikiV2
//
//  Created by 邱沛 on 2021/5/17.
//
import SKUIKit
import SKCommon
import SKResource

public final class WikiTreeTrashViewController: BaseViewController {

    private let emptyView = EmptyListPlaceholderView()

    public override func viewDidLoad() {
        super.viewDidLoad()
        emptyView.config(error: ErrorInfoStruct(type: .noSupport, title: BundleI18n.SKResource.CreationMobile_Wiki_Toast_Unable_To_View, domainAndCode: nil))
        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { (make) in
            make.bottom.left.right.equalToSuperview()
            make.top.equalTo(self.navigationBar.snp.bottom)
        }
        self.title = BundleI18n.SKResource.CreationMobile_Wiki_MenuTrash_Tab
    }
}
