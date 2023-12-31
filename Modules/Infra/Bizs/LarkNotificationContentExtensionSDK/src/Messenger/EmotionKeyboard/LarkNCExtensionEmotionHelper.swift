//
//  LarkNCExtensionEmotionHelper.swift
//  LarkNotificationContentExtension
//
//  Created by yaoqihao on 2022/4/20.
//

import Foundation
import UIKit
import LarkExtensionServices
import LarkStorageCore

struct LarkNCExtensionEmotionEntity {
    public let key: String
    // emoji 原图的尺寸, 单位pt
    public let size: CGSize
    public let image: UIImage

    public init(key: String,
                size: CGSize = .zero,
                image: UIImage) {
        self.key = key
        self.size = size
        self.image = image
    }
}

struct LarkNCExtensionEmotionGroup {
    // 分类的 title, 返回国际化
    public let title: String
    public var entities: [LarkNCExtensionEmotionEntity]

    public init(title: String,
                entities: [LarkNCExtensionEmotionEntity] = []) {
        self.title = title
        self.entities = entities
    }
}

/// EmotionHelper
final class LarkNCExtensionEmotionHelper {

    static func image(named: String) -> UIImage? {
        return UIImage(named: named, in: BundleConfig.LarkNotificationContentExtensionSDKBundle, compatibleWith: nil)
    }

    static func getAllLocalReactions() -> [LarkNCExtensionEmotionGroup] {
        var groups: [LarkNCExtensionEmotionGroup] = []

        var allGroup = LarkNCExtensionEmotionGroup(title: BundleI18n.LarkNotificationContentExtensionSDK.Lark_Legacy_All)

        if let keys = KVPublic.EmotionKeyboard.defaultEmojiKeys.value(),
           let dic = KVPublic.EmotionKeyboard.defaultEmojiDataMap.value() {
            for key in keys {
              if let imageData = dic[key], let image = UIImage.init(data: imageData) {
                  allGroup.entities.append(LarkNCExtensionEmotionEntity(key: key, image: image))
              }
            }
        }

        if let recentKeys = KVPublic.EmotionKeyboard.recentEmojiKeys.value() {
            LarkNCESDKLogger.logger.info("Get EmotionKeyboard Recent Emoji Keys Count: \(recentKeys.count)")
            var recentGroup = LarkNCExtensionEmotionGroup(title: BundleI18n.LarkNotificationContentExtensionSDK.Lark_Chat_EmojiRecentlyUsed)
            for key in recentKeys {
                if let entitie = allGroup.entities.first(where: {
                    $0.key == key
                }) {
                    recentGroup.entities.append(entitie)
                }
            }

            if !recentGroup.entities.isEmpty {
                groups.append(recentGroup)
            } else {
                LarkNCESDKLogger.logger.info("Recent Emojis Is Empty")
            }
        } else {
            LarkNCESDKLogger.logger.info("Get EmotionKeyboard Recent Emoji Keys Error")
        }

        if !allGroup.entities.isEmpty {
            groups.append(allGroup)
        } else {
            LarkNCESDKLogger.logger.info("Default Emojis Is Empty")
        }

        return groups
    }

    /// 如果是3个，配置为：(EmotionKey, 国内ImageName, ReactionKey)
    /// 如果是5个，配置为：(EmotionKey, 国内ImageName, ReactionKey, 英文/海外ImageName, 英文/海外ImageKey)
    /// 启动耗时优化，去掉plist文件读取，直接写数据
    static let emotionInfos: [[String]] = [
        ["Lark_Emoji_Smile_0","1","SMILE"],
        ["Lark_Emoji_Drool_0","2","DROOL"],
        ["Lark_Emoji_Scowl_0","3","SCOWL"],
        ["Lark_Emoji_haughty_0","4","HAUGHTY"],
        ["Lark_Emoji_NosePick_0","5","NOSEPICK"],
        ["Lark_Emoji_Sob_0","6","SOB"],
        ["Lark_Emoji_Angry_0","7","ANGRY"],
        ["Lark_Emoji_Grin_0","8","BLUSH"],
        ["Lark_Emoji_Sleep_0","9","SLEEP"],
        ["Lark_Emoji_Shy_0","10","SHY"],
        ["Lark_Emoji_Wink_0","11","WINK"],
        ["Lark_Emoji_Dizzy_0","12","DIZZY"],
        ["Lark_Emoji_Toasted_0","13","TOASTED"],
        ["Lark_Emoji_Silent_0","14","SILENT"],
        ["Lark_Emoji_Smart_0","15","SMART"],
        ["Lark_Emoji_Attention_0","16","ATTENTION"],
        ["Lark_Emoji_Witty_0","17","WITTY"],
        ["Lark_Emoji_Yeah_0","18","YEAH"],
        ["Lark_Emoji_Facepalm_0","19","FACEPALM"],
        ["Lark_Emoji_Slap_0","20","SLAP"],
        ["Lark_Emoji_Laugh_0","21","LAUGH"],
        ["Lark_Emoji_Yawn_0","22","YAWN"],
        ["Lark_Emoji_Shocked_0","23","SHOCKED"],
        ["Lark_Emoji_Love_0","24","LOVE"],
        ["Lark_Emoji_Drowsy_0","25","DROWSY"],
        ["Lark_Emoji_What_0","26","WHAT"],
        ["Lark_Emoji_Cry_0","27","CRY"],
        ["Lark_Emoji_Clap_0","28","CLAP"],
        ["Lark_Emoji_ShowOff_0","29","SHOWOFF"],
        ["Lark_Emoji_Chuckle_0","30","CHUCKLE"],
        ["Lark_Emoji_Petrified_0","31","PETRIFIED"],
        ["Lark_Emoji_Thinking_0","32","THINKING"],
        ["Lark_Emoji_SpitBlood_0","33","SPITBLOOD"],
        ["Lark_Emoji_Whimper_0","34","WHIMPER"],
        ["Lark_Emoji_Shhh_0","35","SHHH"],
        ["Lark_Emoji_Smug_0","36","SMUG"],
        ["Lark_Emoji_Errr_0","37","ERROR"],
        ["Lark_Emoji_Lol_0","38","LOL"],
        ["Lark_Emoji_Sick_0","39","SICK"],
        ["Lark_Emoji_Smirk_0","40","SMIRK"],
        ["Lark_Emoji_Proud_0","41","PROUD"],
        ["Lark_Emoji_Trick_0","42","TRICK"],
        ["Lark_Emoji_Crazy_0","43","CRAZY"],
        ["Lark_Emoji_Tears_0","44","TEARS"],
        ["Lark_Emoji_Money_0","45","MONEY","45_lark","emoji_dollar.png"],
        ["Lark_Emoji_Kiss_0","46","KISS"],
        ["Lark_Emoji_Terror_0","47","TERROR"],
        ["Lark_Emoji_Joyful_0","48","JOYFUL"],
        ["Lark_Emoji_Blubber_0","49","BLUBBER"],
        ["Lark_Emoji_Husky_0","50","HUSKY"],
        ["Lark_Emoji_FollowMe_0","51","FOLLOWME"],
        ["Lark_Emoji_OK_0","99","OK","99_lark","emoji_ok_v2.png"],
        ["Lark_Emoji_Heart_0","107","HEART"],
        ["Lark_Emoji_Lips_0","55","LIPS"],
        ["Lark_Emoji_Detergent_0","56","DETERGENT"],
        ["Lark_Emoji_Awesome_0","57","AWESOME"],
        ["Lark_Emoji_Rose_0","58","ROSE"],
        ["Lark_Emoji_Cucumber_0","59","CUCUMBER"],
        ["Lark_Emoji_Beer_0","60","BEER"],
        ["Lark_Emoji_Enough_0","61","ENOUGH"],
        ["Lark_Emoji_Wronged_0","62","WRONGED"],
        ["Lark_Emoji_Obsessed_0","63","OBSESSED"],
        ["Lark_Emoji_LookDown_0","64","LOOKDOWN"],
        ["Lark_Emoji_Smooch_0","65","SMOOCH"],
        ["Lark_Emoji_Wave_0","66","WAVE"],
        ["Lark_Emoji_DonnotGo_0","67","DONNOTGO"],
        ["Lark_Emoji_Headset_0","68","HEADSET"],
        ["Lark_Emoji_Hug_0","69","HUG"],
        ["Lark_Emoji_DullStare_0","70","DULLSTARE"],
        ["Lark_Emoji_InnocentSmile_0","71","INNOCENTSMILE"],
        ["Lark_Emoji_Tongue_0","72","TONGUE"],
        ["Lark_Emoji_Dull_0","73","DULL"],
        ["Lark_Emoji_Glance_0","74","GLANCE"],
        ["Lark_Emoji_Slight_0","75","SLIGHT"],
        ["Lark_Emoji_Bear_0","76","BEAR"],
        ["Lark_Emoji_Skull_0","77","SKULL"],
        ["Lark_Emoji_BlackFace_0","78","BLACKFACE"],
        ["Lark_Emoji_Eating_0","79","EATING"],
        ["Lark_Emoji_Betrayed_0","80","BETRAYED","80_lark","emoji_mad.png"],
        ["Lark_Emoji_Sweat_0","81","SWEAT"],
        ["Lark_Emoji_Comfort_0","82","COMFORT"],
        ["Lark_Emoji_Frown_0","83","FROWN"],
        ["Lark_Emoji_Speechless_0","84","SPEECHLESS"],
        ["Lark_Emoji_Blush_0","85","XBLUSH"],
        ["Lark_Emoji_Embarrassed_0","86","EMBARRASSED"],
        ["Lark_Emoji_Tease_0","87","TEASE"],
        ["Lark_Emoji_Praise_0","88","PRAISE"],
        ["Lark_Emoji_BigKiss_0","89","BIGKISS"],
        ["Lark_Emoji_Puke_0","90","PUKE"],
        ["Lark_Emoji_Wow_0","91","WOW"],
        ["Lark_Emoji_Hammer_0","92","HAMMER"],
        ["Lark_Emoji_Strive_0","93","STRIVE"],
        ["Lark_Emoji_RainbowPuke_0","94","RAINBOWPUKE"],
        ["Lark_Emoji_Wail_0","95","WAIL"],
        ["Done","117","DONE"],
        ["Lark_Emoji_18x_0","103","18X"],
        ["Lark_Emoji_Cleaver_0","104","CLEAVER"],
        ["+1","116","JIAYI"],
        ["Lark_Emoji_WellDone_0","105","WELLDONE"],
        ["Lark_Emoji_GoodJob_0","106","GOODJOB"],
        ["Lark_Emoji_HeartBroken_0","108","HEARTBROKEN"],
        ["Lark_Emoji_Poop_0","109","POOP"],
        ["Lark_Emoji_Gift_0","110","GIFT"],
        ["Lark_Emoji_Cake_0","111","CAKE"],
        ["Lark_Emoji_Party_0","112","PARTY"],
        ["Lark_Emoji_EyesClosed_0","113","EYESCLOSED"],
        ["Lark_Emoji_Bomb_0","114","BOMB"],
        ["Fireworks","118","FIREWORKS"],
        ["Bull","119","BULL"],
        ["Calf","120","CALF"],
        ["Awesomen","121","AWESOMEN","121_lark","emoji_socool_v2.png"],
        ["2021","122","2021","122_lark","emoji_balloon_v2.png"],
        ["Candiedhaws","123","CANDIEDHAWS"],
        ["Redpacket","124","REDPACKET"],
        ["Fortune","125","FORTUNE","125_lark","emoji_gold.png"],
        ["Luck","126","LUCK"],
        ["Firecracker","127","FIRECRACKER"],
        ["EatingFood","128","EatingFood"],
        ["Typing","129","Typing"],
        ["Lemon","130","Lemon"],
        ["Get","131","Get","131_lark","emoji_gotit_v1.png"],
        ["LGTM","132","LGTM"],
        ["Drumstick","134","Drumstick"],
        ["Pepper","135","Pepper"],
        ["BubbleTea","136","BubbleTea"],
        ["Coffee","137","Coffee"],
        ["Yes","138","Yes"],
        ["No","139","No"],
        ["OKR","140","OKR"],
        ["CheckMark","141","CheckMark"],
        ["CrossMark","142","CrossMark"],
        ["MinusOne","143","MinusOne"],
        ["Hundred","144","Hundred"],
        ["Pin","145","Pin"],
        ["Alarm","146","Alarm"],
        ["Loudspeaker","147","Loudspeaker"],
        ["Trophy","148","Trophy"],
        ["Fire","149","Fire"],
        ["Music","150","Music"],
        ["Basketball","151","Basketball"],
        ["Soccer","152","Soccer"],
        ["GeneralDoNotDisturb","153","GeneralDoNotDisturb"],
        ["GeneralInMeetingBusy","154","GeneralInMeetingBusy"],
        ["Coffee","155","Coffee"],
        ["GeneralBusinessTrip","156","GeneralBusinessTrip"],
        ["GeneralWorkFromHome","157","GeneralWorkFromHome"],
        ["StatusEnjoyLife","158","StatusEnjoyLife"],
        ["GeneralTravellingCar","159","GeneralTravellingCar"],
        ["StatusBus","160","StatusBus"],
        ["StatusInFlight","161","StatusInFlight"],
        ["GeneralSun","162","GeneralSun"],
        ["GeneralMoonRest","163","GeneralMoonRest"],
        ["StatusReading","164","StatusReading"],
        ["Status_PrivateMessage","165","Status_PrivateMessage"],
        ["StatusFlashOfInspiration","166","StatusFlashOfInspiration"],
        ["2022","167","2022"],
        ["MediumLightThumbsup","168","MediumLightThumbsup"],
        ["LightThumbsup","169","LightThumbsup"],
        ["MediumThumbsup","170","MediumThumbsup"],
        ["MediumDarkThumbsup","171","MediumDarkThumbsup"],
        ["DarkThumbsup","172","DarkThumbsup"],
        ["Lark_Emoji_Thumbsup_0","52","THUMBSUP"],
        ["MediumLightThanks","173","MediumLightThanks"],
        ["LightThanks","174","LightThanks"],
        ["MediumThanks","175","MediumThanks"],
        ["MediumDarkThanks","176","MediumDarkThanks"],
        ["DarkThanks","177","DarkThanks"],
        ["Lark_Emoji_Thanks_0","54","THANKS"],
        ["MediumLightFightOn","178","MediumLightFightOn"],
        ["LightFightOn","179","LightFightOn"],
        ["MediumFightOn","180","MediumFightOn"],
        ["MediumDarkFightOn","181","MediumDarkFightOn"],
        ["DarkFightOn","182","DarkFightOn"],
        ["Lark_Emoji_Fighting_0","97","MUSCLE"],
        ["MediumLightFingerHeart","183","MediumLightFingerHeart"],
        ["LightFingerHeart","184","LightFingerHeart"],
        ["MediumFingerHeart","185","MediumFingerHeart"],
        ["MediumDarkFingerHeart","186","MediumDarkFingerHeart"],
        ["DarkFingerHeart","187","DarkFingerHeart"],
        ["Lark_Emoji_FingerHeart_0","96","FINGERHEART"],
        ["MediumLightApplaud","188","MediumLightApplaud"],
        ["LightApplaud","189","LightApplaud"],
        ["MediumApplaud","190","MediumApplaud"],
        ["MediumDarkApplaud","191","MediumDarkApplaud"],
        ["DarkApplaud","192","DarkApplaud"],
        ["Lark_Emoji_Applaud_0","53","APPLAUSE"],
        ["MediumLightFistBump","193","MediumLightFistBump"],
        ["LightFistBump","194","LightFistBump"],
        ["MediumFistBump","195","MediumFistBump"],
        ["MediumDarkFistBump","196","MediumDarkFistBump"],
        ["DarkFistBump","197","DarkFistBump"],
        ["Lark_Emoji_FistBump_0","98","FISTBUMP"],
        ["MediumLightHighFive","198","MediumLightHighFive"],
        ["LightHighFive","199","LightHighFive"],
        ["MediumHighFive","200","MediumHighFive"],
        ["MediumDarkHighFive","201","MediumDarkHighFive"],
        ["DarkHighFive","202","DarkHighFive"],
        ["Lark_Emoji_HighFive_0","100","HIGHFIVE"],
        ["MediumLightClick","203","MediumLightClick"],
        ["LightClick","204","LightClick"],
        ["MediumClick","205","MediumClick"],
        ["MediumDarkClick","206","MediumDarkClick"],
        ["DarkClick","207","DarkClick"],
        ["Lark_Emoji_UpperLeft_0","101","UPPERLEFT"],
        ["MediumLightThumbsDown","208","MediumLightThumbsDown"],
        ["LightThumbsDown","209","LightThumbsDown"],
        ["MediumThumbsDown","210","MediumThumbsDown"],
        ["MediumDarkThumbsDown","211","MediumDarkThumbsDown"],
        ["DarkThumbsDown","212","DarkThumbsDown"],
        ["ThumbsDown","133","ThumbsDown"],
        ["MediumLightSalute","213","MediumLightSalute"],
        ["LightSalute","214","LightSalute"],
        ["MediumSalute","215","MediumSalute"],
        ["MediumDarkSalute","216","MediumDarkSalute"],
        ["DarkSalute","217","DarkSalute"],
        ["Salute","115","SALUTE"],
        ["MediumLightShake","218","MediumLightShake"],
        ["LightShake","219","LightShake"],
        ["MediumShake","220","MediumShake"],
        ["MediumDarkShake","221","MediumDarkShake"],
        ["DarkShake","222","DarkShake"],
        ["Lark_Emoji_Shake_0","102","SHAKE"],
        ["XmasTree","223","XmasTree"],
        ["Snowman","224","Snowman"],
        ["XmasHat","225","XmasHat"],
        ["OnIt","226","OnIt"],
        ["OneSecond","227","OneSecond"],
        ["Sigh","228","Sigh"],
        ["RoarForYou","229","RoarForYou"],
        ["StickyRiceBalls","230","StickyRiceBalls"],
        ["MeMeMe","231","MeMeMe"],
        ["YouAreTheBest","232","YouAreTheBest"],
        ["GeneralVacation","233","GeneralVacation"],
        ["Mooncake", "242", "Mooncake"],
        ["MoonRabbit", "243", "MoonRabbit"],
        ["Partying", "244", "Partying"],
        ["GoGoGo", "245", "GoGoGo"],
        ["TV", "246", "TV"],
        ["Movie", "247", "Movie"],
        ["Pumpkin", "248", "Pumpkin"],
        ["2023", "249", "2023"],
        ["JubilantRabbit", "250", "JubilantRabbit"],
        ["VRHeadset", "251", "VRHeadset"],
        ["FullMoonFace", "252", "FullMoonFace"],
        ["ColdSweat", "253", "ColdSweat"],
        ["PursueUltimate","234","PursueUltimate", "235", "emoji_pursueultimate_en.png"],
        ["CustomerSuccess","236","CustomerSuccess", "237", "emoji_customersuccess_en.png"],
        ["Responsible","238","Responsible", "239", "emoji_bereliableandtakeownership_en.png"],
        ["Patient","240","Patient", "241", "emoji_bepatientandthinklongterm_en.png"]
    ]
}
