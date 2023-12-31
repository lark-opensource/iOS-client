//
//  Router.swift
//  SuiteLogin
//
//  Created by Miaoqi Wang on 2019/8/6.
//

import UIKit
import EENavigator

class Router {

    static let shared = Router()

    private var navigation: UINavigationController? {
        PassportNavigator.topMostVC?.nearestNavigation
    }
    
}
