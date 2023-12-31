//
//  OrientationUtil.swift
//  SKFoundation
//
//  Created by zengsenyuan on 2022/3/26.
//  


import Foundation

/// 屏幕方向工具，提供其他在非主线程获取屏幕方向使用
public final class OrientationUtil {
    
    public static let shared = OrientationUtil()
    
    public var orientation = UIApplication.shared.statusBarOrientation
    
    init() {
        _ = NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification,
                                               object: nil,
                                               queue: .main) { [weak self] _ in
            self?.orientation = UIApplication.shared.statusBarOrientation
        }
    }
}
