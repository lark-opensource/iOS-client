// 
// Created by duanxiaochen.7 on 2020/4/14.
// Affiliated with SpaceKit.
// 
// Description:

import Foundation

protocol BrowserViewControllerLifeCycle: AnyObject {
    func browserViewControllerViewDidLoad(_ browser: BrowserViewController)
    func browserViewController(_ browser: BrowserViewController, viewWillAppearAnimated: Bool)
    func browserViewController(_ browser: BrowserViewController, viewDidAppearAnimated: Bool)
    func browserViewController(_ browser: BrowserViewController, viewWillDisappearAnimated: Bool)
    func browserViewController(_ browser: BrowserViewController, viewDidDisappearAnimated: Bool)
}

extension BrowserViewControllerLifeCycle {
    func browserViewControllerViewDidLoad(_ browser: BrowserViewController) { }
    func browserViewController(_ browser: BrowserViewController, viewWillAppearAnimated: Bool) { }
    func browserViewController(_ browser: BrowserViewController, viewDidAppearAnimated: Bool) { }
    func browserViewController(_ browser: BrowserViewController, viewWillDisappearAnimated: Bool) { }
    func browserViewController(_ browser: BrowserViewController, viewDidDisappearAnimated: Bool) { }
}
