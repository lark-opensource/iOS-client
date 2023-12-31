//
//  UIImageView+DocsIcon.swift
//  LarkDocsIcon
//
//  Created by huangzhikai on 2023/6/13.
//

import Foundation
import RxSwift
import UniverseDesignIcon
import LarkContainer

///扩展UIImageView 可以通过 imageView.di.xxx，进行调用设置docs icon

extension DIImageWrapper where Base: UIImageView {
    
    //自定义设置头像icon
    public func setCustomDocsIcon(model: DocsIconCustomModelProtocol,
                                  container: ContainerInfo? = nil,
                                  errorImage: UIImage? = nil) {
        
        //处理复用问题
        base.reuseBag = DisposeBag()
        base.image = nil
        
        //获取binder
        let binder = DocsIconCustomBinder.shared.getBinder(model: model)
        
        guard let binder = binder else {
            base.image = errorImage ?? DocsIconInfo.defultUnknowIcon(docsType: .unknownDefaultType, shape: .SQUARE, container: nil)
            assertionFailure("Custom DocsIcon has not regist")
            return
        }
        
        binder.binder(model: model).map({ image -> UIImage in
            return DocsIconCreateUtil.creatImage(image: image,
                                                 isShortCut: container?.isShortCut ?? false)
        })
        .asDriver(onErrorJustReturn: DocsIconInfo.defultUnknowIcon(docsType: .unknownDefaultType, shape: .SQUARE, container: nil))
        .drive(onNext: { [weak base] image in
            base?.image = image
        })
        .disposed(by: base.reuseBag ?? DisposeBag())
        
    }
    
    //解决复用问题，可清空图片
    public func clearDocsImage() {
        base.reuseBag = DisposeBag()
        base.image = nil
    }
    
    ///设置显示icon图片
    ///支持通过token 和 type进行兜底显示
    public func setDocsImage(iconInfo: String,
                             token: String,
                             type: CCMDocsType,
                             shape: IconShpe = .CIRCLE,
                             container: ContainerInfo? = nil,
                             userResolver: UserResolver) {
        //处理复用问题
        base.reuseBag = DisposeBag()
        base.image = nil
        
        userResolver.resolve(DocsIconManager.self)?
            .getDocsIconImageAsync(iconInfo: iconInfo, token: token,
                                   docsType: type, shape: shape, container: container)
        .asDriver(onErrorJustReturn: DocsIconInfo.defultUnknowIcon(docsType: type, shape: shape, container: container))
        .drive(onNext: { (image) in
            self.base.image = image
        })
        .disposed(by: base.reuseBag ?? DisposeBag())
    }
    
    ///设置显示icon图片
    ///支持通过url进行兜底显示
    public func setDocsImage(iconInfo: String,
                             url: String,
                             shape: IconShpe = .CIRCLE,
                             container: ContainerInfo? = nil,
                             userResolver: UserResolver) {
        
        //处理复用问题
        base.reuseBag = DisposeBag()
        base.image = nil
        userResolver.resolve(DocsIconManager.self)?
            .getDocsIconImageAsync(iconInfo: iconInfo, url: url,
                                   shape: shape, container: container)
        .asDriver(onErrorJustReturn: DocsIconInfo.defultUnknowIcon(shape: shape, container: container))
        .drive(onNext: { (image) in
            self.base.image = image
        })
        .disposed(by: base.reuseBag ?? DisposeBag())
    }
    
    
    /// 支持自定义icon API
    // 新api设计
    // 使用例子：
    // 文档业务使用：
    // imageView.di.setIconImage(iconBuild: IconBuilder(bizIconType: .docsWithUrl(iconInfo: xxx, url: xxx, container: xxx)))
    //
    // 标准图标接入，例如TODO业务
    // imageView.di.setIconImage(iconBuild: IconBuilder(bizIconType: .iconInfo(iconType: xxx, iconKey: "xxx"), iconExtend: IconExtend(placeHolderImage: xxxx))
    public func setIconImage(iconBuild: IconBuilder,
                             userResolver: UserResolver) {
        
        //处理复用问题
        base.reuseBag = DisposeBag()
        base.image = nil
        guard let manager = try? userResolver.resolve(assert: DocsIconManager.self) else {
            return
        }
        manager.loadIconImageAsync(iconBuild: iconBuild)
            .asDriver(onErrorJustReturn: manager.getDefultIcon(defultIcon: iconBuild.iconExtend.placeHolderImage ?? UDIcon.getIconByKeyNoLimitSize(.fileUnknowColorful), iconExtend: iconBuild.iconExtend))
        .drive(onNext: { (image) in
            self.base.image = image
        })
        .disposed(by: base.reuseBag ?? DisposeBag())
    }
    
}


