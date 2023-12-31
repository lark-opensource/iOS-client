//
//  LarkIconManager+Word.swift
//  LarkIcon
//
//  Created by huangzhikai on 2023/12/15.
//

import Foundation
import RxSwift

extension LarkIconManager {
    func createWordIcon() -> LIResult {
        
        let image = LarkIconBuilder.createImageWith(word: self.iconKey,
                                                    iconLayer: self.iconExtend.layer,
                                                    iconShape: self.iconExtend.shape,
                                                    foreground: self.iconExtend.foreground)
        return (image: image, error: nil)
        
    }
}
