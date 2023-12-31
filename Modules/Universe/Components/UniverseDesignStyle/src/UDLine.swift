//
//  UDLine.swift
//  Pods-UniverseDesignStyleDev
//
//  Created by 强淑婷 on 2020/8/11.
//

import UIKit
import Foundation
import UniverseDesignColor

/// 标准化分割线
public final class UDLine {
    /// 分割线
    public class var split: UIView {
        let splitLine = UIView()
        splitLine.layer.borderWidth = 1
        splitLine.backgroundColor = UIColor.ud.N400
        return splitLine
    }
}
