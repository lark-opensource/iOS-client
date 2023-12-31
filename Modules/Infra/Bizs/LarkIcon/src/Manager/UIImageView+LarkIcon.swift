//
//  UIImageView+LarkIcon.swift
//  LarkIcon
//
//  Created by huangzhikai on 2023/12/15.
//

import Foundation
import RxSwift
import UniverseDesignIcon
import LarkContainer

///扩展UIImageView 可以通过 imageView.di.xxx，进行调用设置docs icon

extension LIImageWrapper where Base: UIImageView {
    
    //解决复用问题，可清空图片
    public func clearLarkIconImage() {
        base.reuseBag = DisposeBag()
        base.image = nil
    }
    
    
    /// 支持自定义icon API
    // 新api设计
    // 使用例子：
    // let iconLayer = IconLayer(backgroundColor: UDColor.bgFloat,
    //                           border: IconLayer.Border(borderWidth: 1.0, borderColor: UDColor.lineDividerDefault))
    // let iconExtend = LarkIconExtend(shape: .CORNERRADIUS(value: 11.0),
    //                                 layer: iconLayer,
    //                                 placeHolderImage: UDIcon.wikibookCircleColorful)
    // typeIcon.li.setLarkIconImage(iconType: iconInfo.type,
    //                              iconKey: iconKey,
    //                              iconExtend: iconExtend,
    //                              userResolver: Container.shared.getCurrentUserResolver())
    //
    public func setLarkIconImage(iconType: IconType,
                                 iconKey: String?,
                                 iconExtend: LarkIconExtend = LarkIconExtend(shape: .SQUARE),
                                 userResolver: UserResolver) {
        
        //处理复用问题
        base.reuseBag = DisposeBag()
        base.image = nil
        guard let manager = try? userResolver.resolve(assert: LarkIconManager.self) else {
            return
        }
        
        manager.builder(iconType: iconType, iconKey: iconKey, iconExtend: iconExtend)
            .asDriver(onErrorJustReturn: (image: iconExtend.placeHolderImage, error: nil))
            .drive(onNext: { (image, _) in
                self.base.image = image ?? iconExtend.placeHolderImage
            })
            .disposed(by: base.reuseBag ?? DisposeBag())
    }
    
}
