//
//  TemplateSpecialViewProvider.swift
//  SKCommon
//
//  Created by 邱沛 on 2020/9/23.
//

import SKResource
import RxSwift
import SKUIKit
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignEmpty
import SnapKit

class TemplateSpecialViewProvider {
    static func makeFilteredStateView(type: String,
                                      handler: @escaping (() -> Void),
                                      bag: DisposeBag) -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 65, height: 28))
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 6
        view.backgroundColor = UDColor.B100

        let imageView = UIImageView(frame: CGRect(x: 8, y: 6, width: 16, height: 16))
        imageView.image = UDIcon.getIconByKey(.filterOutlined, renderingMode: .alwaysTemplate, iconColor: UDColor.primaryContentDefault, size: CGSize(width: 16, height: 16))
        view.addSubview(imageView)

        let label = UILabel(frame: CGRect(x: 26, y: 4, width: 42, height: 20))
        label.text = type
        label.textColor = UDColor.colorfulBlue
        label.font = .systemFont(ofSize: 12)
        label.textAlignment = .center
        label.sizeToFit()
        label.frame.size.height = 20
        view.addSubview(label)
        view.frame.size.width = label.frame.width + 34

        let ges = UITapGestureRecognizer()
        ges.rx
            .event
            .subscribe(onNext: { _ in
                handler()
            }).disposed(by: bag)
        view.addGestureRecognizer(ges)
        return view
    }

    static func makeCustomBlankView(targetViewWidth: CGFloat) -> TemplateListBlankView {
        let view = TemplateListBlankView(title: BundleI18n.SKResource.Doc_List_CustomTemplateGuideTitle,
                                         desc: BundleI18n.SKResource.Doc_List_CustomTemplateGuideDescription)
        view.button.setTitle(BundleI18n.SKResource.CreationMobile_Operation_ClicktoKnowMore, for: .normal)
        view.button.isHidden = false
        return view
    }

    static func makeBusinessBlankView(targetViewWidth: CGFloat) -> TemplateListBlankView {
        TemplateListBlankView(title: BundleI18n.SKResource.Doc_List_EnterpriseTemplateGuideTitle,
                              desc: BundleI18n.SKResource.Doc_List_EnterpriseTemplateGuideDescription())
    }
    
    static func makeTemplateThemeBlankView(targetViewWidth: CGFloat) -> TemplateListBlankView {
        TemplateListBlankView(title: BundleI18n.SKResource.Doc_List_EmptyTemplateCategory,
                              desc: "")
    }
    
    static func makeTemplateCategoryBlankView(targetViewWidth: CGFloat) -> TemplateListBlankView {
        TemplateListBlankView(title: BundleI18n.SKResource.Doc_List_EmptyTemplateCategory,
                              desc: "")
    }

    static func makeNoNetworkView(handler: (() -> Void)?, bag: DisposeBag) -> EmptyListPlaceholderView {
        let errorView = EmptyListPlaceholderView()
        errorView.backgroundColor = UDColor.bgBase
        errorView.config(error: ErrorInfoStruct(type: .noNet, title: BundleI18n.SKResource.Doc_Space_EmptyPageNoNetDefaultTip, domainAndCode: nil))
        let ges = UITapGestureRecognizer()
        ges.rx
            .event
            .subscribe(onNext: { _ in
                handler?()
            }).disposed(by: bag)
        errorView.addGestureRecognizer(ges)
        return errorView
    }

    // 创建列表里的无网提示布局需要调整
    static func makeFailViewForSuggestion() -> UIView {
        let emptyConfig = UDEmptyConfig(type: .noContent)
        let emptyView = UDEmptyView(config: emptyConfig)
        return emptyView
    }
    
    static func makeNoNetForSuggestion() -> UIView {
        let description = UniverseDesignEmpty.UDEmptyConfig.Description(descriptionText: NSAttributedString(string: BundleI18n.SKResource.Doc_Space_EmptyPageNoNetDefaultTip))
        let emptyConfig = UDEmptyConfig(description: description, imageSize: 90, spaceBelowImage: 10, type: .noWifi)
        let emptyView = UDEmptyView(config: emptyConfig)
        return emptyView
    }
}
