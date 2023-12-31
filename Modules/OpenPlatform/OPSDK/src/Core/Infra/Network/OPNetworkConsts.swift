//
//  OPNetworkConsts.swift
//  OPSDK
//
//  Created by lixiaorui on 2020/11/17.
//

import UIKit

// 此处存放网络相关的全局常量，建议区分对应的子域
// 如果后续遇到要换oc再修改
public extension String {
    enum OPNetwork {
        public enum OPPath {
            public static let minaPath = "open-apis/mina"
            public static let appInterface = "lark/app_interface"
        }

        public enum OPInterface {

            /// meta接口
            public static let meta = "AppExtensionMetas"

            /// 止血配置
            public static let silenceUpdateInfo = "app_setting"
        }
    }
}
