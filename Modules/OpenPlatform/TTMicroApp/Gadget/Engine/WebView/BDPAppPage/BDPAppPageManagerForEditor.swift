//
//  BDPAppPageManagerForEditor.swift
//  Timor
//
//  Created by 新竹路车神 on 2020/9/10.
//

import Foundation

@objcMembers
public final class BDPAppPageManagerForEditor: NSObject {
    private override init() {}
    public static let shared = BDPAppPageManagerForEditor()
    public var bdpAppPageInitBlock: ((BDPAppPage) -> Void)?
    public var bdpAppPageDeallocBlock: ((BDPAppPage) -> Void)?
}
