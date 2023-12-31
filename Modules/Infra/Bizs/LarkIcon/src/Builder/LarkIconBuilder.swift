//
//  LarkIconBuilder.swift
//  LarkIcon
//
//  Created by huangzhikai on 2023/12/13.
//

import Foundation


public class BuilderExtend {
    //输出图片大小
    public let canvasSize: CGSize
    public init(canvasSize: CGSize) {
        self.canvasSize = canvasSize
    }
}

public class LarkIconBuilder {
    
    public static let defultSize: CGSize = CGSize(width: 44, height: 44)
    
    private var context: CGContext?
    
    private var builderExtend: BuilderExtend
    
    private var transformArr = [LarkIconTransformProtocol]()
    
    public init(canvasSize: CGSize = defultSize) {
        self.builderExtend = BuilderExtend(canvasSize: canvasSize)
        
    }
    
    public func addTransform(_ transform: LarkIconTransformProtocol) -> Self {
        self.transformArr.append(transform)
        return self
    }
    
    public func build() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.builderExtend.canvasSize, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        
        for transform in self.transformArr {
            transform.beginTransform(with: context, builderExtend: self.builderExtend)
        }
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
        
    }
}
