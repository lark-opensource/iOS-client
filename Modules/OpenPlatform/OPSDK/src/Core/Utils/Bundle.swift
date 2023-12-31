//
//  Bundle.swift
//  OPSDK
//
//  Created by Limboy on 2020/11/11.
//

import Foundation

public final class OPBundle {
    public static var timor: Bundle{
        get {
            if let bundleUrl = Bundle(for: self).url(forResource: "TimorAssetBundle", withExtension: "bundle") {
                return Bundle.init(url: bundleUrl)!
            }

            return Bundle.main
        }
    }
}

