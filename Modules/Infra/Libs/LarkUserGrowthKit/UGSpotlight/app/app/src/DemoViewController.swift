//
//  DemoViewController.swift
//  UGContainerDev
//
//  Created by zhenning on 2021/3/25.
//

import UIKit
import Foundation
import UGContainer
import UGSpotlight
import ServerPB
import LarkGuideUI

class Dependency: PluginContainerDependency {
    func reportEvent(event: ReachPointEvent) {
        print("UGSportlight Mock Dependency reportEvent \(event)")
    }
}

// 使用ipad Pro 横屏查看
class DemoViewController: UIViewController {
    var counter: Int = 0
    let service = PluginContainerServiceImpl(dependency: Dependency())
    var reachPoint: SpotlightReachPoint?

    @IBOutlet weak var showBtn: UIButton!
    @IBOutlet weak var secondBtn: UIButton!
    @IBOutlet weak var thirdBtn: UIButton!
    @IBOutlet weak var isMultSwitch: UISwitch!
    @IBOutlet weak var hasImgSwitch: UISwitch!
    @IBOutlet weak var maskAlphaSlider: UISlider!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupReachPoint()
    }

    func setupReachPoint() {
        guard let reachPoint: SpotlightReachPoint = service.obtainReachPoint(reachPointId: "mockSpotlight") else {
            return
        }
        reachPoint.datasource = self
        reachPoint.singleDelegate = self
        reachPoint.multiDelegate = self
        self.reachPoint = reachPoint
    }

    @IBAction func showClick(_ sender: Any) {
        let spotlightMaterials = createSpotlightMaterialCollection()
        do {
            let data = try spotlightMaterials.serializedData()
            service.showReachPoint(reachPointId: "mockSpotlight",
                                   reachPointType: SpotlightReachPoint.reachPointType,
                                   data: data)
        } catch {
            print("UGSportlight DemoViewController prase data error: \(error)")
        }
    }
    @IBAction func changeAlpha(_ sender: Any) {
        showClick(sender)
    }

    private func createSpotlightMaterialCollection() -> SpotlightMaterials {
        var spotlightMaterial = ServerPB_Ug_reach_SpotlightMaterial()

        // Mask
        var spotlightMaskConfig = ServerPB_Ug_reach_SpotlightMaterialCollection.MaskConfig()
        spotlightMaskConfig.alpha = Double(self.maskAlphaSlider.value)
//        spotlightMaskConfig.maskInteractionForceOpen = true

        // Target
        var targetAnchorConfig = SpotlightMaterial.TargetAnchor()
        if let arrowDirection = SpotlightMaterial.ArrowDirection(rawValue: 0) {
            targetAnchorConfig.arrowDirection = arrowDirection
        }
        targetAnchorConfig.offset = 8.0
        spotlightMaterial.targetAnchorConfig = targetAnchorConfig

        // 文案
        var title = ServerPB_Ug_reach_TextElement()
        title.content = "测试气泡bubble，测试气泡bubble"
        var subTitle = ServerPB_Ug_reach_TextElement()
        subTitle.content = "Hello, 这里是一些测试描述"
        var rightTitle = ServerPB_Ug_reach_TextElement()
        rightTitle.content = "好的"

        // 按钮
        var button1 = ServerPB_Ug_reach_ButtonElement()
        button1.text = "我知道了"
        var button2 = ServerPB_Ug_reach_ButtonElement()
        button2.text = "右边按钮"
        spotlightMaterial.content.buttons = [button2]

        // 图片
        if hasImgSwitch.isOn,
           let path = Bundle.main.path(forResource: "imageBase64", ofType: "json") {
            do {
                var jsonString = try String(contentsOfFile: path)
                jsonString.removeLast(1)
                print("mzn jsonSting = \(jsonString.suffix(10))")
                if let rawData = Data(base64Encoded: jsonString) {
                    var image = ServerPB_Ug_reach_ImageElement()
                    var rawImage = ServerPB_Ug_reach_RawImageElement()
                    rawImage.rawData = rawData
                    image.rawImage =  rawImage
                    spotlightMaterial.content.image = image
                }
            } catch {
                print("mzn jsonSting encoded error!")
            }
        }

        // update data
        spotlightMaterial.content.title = title
        spotlightMaterial.content.description_p = subTitle

        var spotlightMaterial2 = spotlightMaterial
        var title2 = ServerPB_Ug_reach_TextElement()
        title2.content = "测试气泡bubble，第二步"
        spotlightMaterial2.content.title = title2

        var spotlightMaterialCollection = SpotlightMaterials()
        let spotlights = isMultSwitch.isOn ? [spotlightMaterial, spotlightMaterial2, spotlightMaterial]: [spotlightMaterial]
        spotlightMaterialCollection.spotlights = spotlights
        spotlightMaterialCollection.spotlightMaskConfig = spotlightMaskConfig
        return spotlightMaterialCollection
    }
}

// 视图代理- 数据回调
extension DemoViewController: SpotlightReachPointDataSource {
    func onShow(spotlightData: UGSpotlightData, isMult: Bool) -> SpotlightBizProvider {
        let provider = SpotlightBizProvider(hostProvider: {
            return self
        }, targetSourceTypes: {
            let targets: [TargetSourceType] = isMult
                ? [.targetView(self.showBtn), .targetView(self.secondBtn), .targetView(self.thirdBtn)]
                : [.targetView(self.showBtn)]
            return targets
        })
        print("DemoViewController onShow spotlightData: \(spotlightData)，isMult: \(isMult)")
        return provider
    }
}

// 视图代理- 单个气泡
extension DemoViewController: UGSingleSpotlightDelegate {
    // 点击左边按钮
    func didClickLeftButton(bubbleConfig: BubbleItemConfig) {
        print("UGSportlight DemoViewController didClickLeftButton: \(bubbleConfig)")
    }

    // 点击右边按钮
    func didClickRightButton(bubbleConfig: BubbleItemConfig) {
        print("UGSportlight DemoViewController didClickRightButton: \(bubbleConfig)")
        GuideUITool.closeGuideIfNeeded(hostProvider: self)
    }

    // 点击气泡事件
    func didTapBubbleView(bubbleConfig: BubbleItemConfig) {
        print("UGSportlight DemoViewController didTapBubbleView: \(bubbleConfig)")
    }
}

// 视图代理- 多个气泡
extension DemoViewController: UGMultiSpotlightDelegate {
    func didClickNext(bubbleConfig: BubbleItemConfig, for step: Int) {
        print("UGSportlight DemoViewController didClickNext: \(bubbleConfig), step: \(step)")
    }

    func didClickPrevious(bubbleConfig: BubbleItemConfig, for step: Int) {
        print("UGSportlight DemoViewController didClickPrevious: \(bubbleConfig), step: \(step)")
    }

    // 在bottomConfig中指定skipTitle后，点击了skipTitle后回调
    func didClickSkip(bubbleConfig: BubbleItemConfig, for step: Int) {
        print("UGSportlight DemoViewController didClickSkip: \(bubbleConfig), step: \(step)")
    }

    func didClickEnd(bubbleConfig: BubbleItemConfig) {
        print("UGSportlight DemoViewController didClickEnd: \(bubbleConfig)")
    }
}
