cur_device_score = bytebench.get("overall_score", -1)

# https://bytedance.feishu.cn/docx/doxcnZoI3HKQgN9MSaKvSHsubGb
# iPhone Xs 对应设备分 约为 9.3
ios_high_score = 9.5
ios_mid_score = 7.8

# https://gist.github.com/adamawolf/3048717
# iPhone 11 ~
iphone_high_model = (12, 1)
# iPhone 8 ~ iPhoneXsMax
iphone_mid_model = (10, 1)

# A12X iPad Pro 11 inch 3rd Gen 
ipad_high_model = (8, 1)

# A10 iPad Pro 2nd Gen
ipad_mid_model = (7, 1)

# 小米 9 设备分 约 8.7
android_high_score = 8.3
android_mid_score = 7.3
android_low_score = 5.9

# 5.13及以下版本在缩略图和25宫格视图订阅90p会偶现crash，因此将5.14版本以下的缩略图和25宫格订阅改为180p
pc_pin_small_and_25gallery_res = 90
if version_code < 5014000:
  pc_pin_small_and_25gallery_res = 180

pc_view_debounce_time = 1.0
if version_code >= 5020000 and version_code < 5021000:
    pc_view_debounce_time = 0.4

def ios_model_number(device_model):
  try:
    number_list = []
    if device_model.lower().startswith("iphone"):
      number_list = device_model[6:].split(",")
    elif device_model.lower().startswith("ipad"):
      number_list = device_model[4:].split(",")
    if len(number_list) == 2:
      return (int(number_list[0]), int(number_list[1]))
  except:
    return (0, 0)
  return (0, 0)

if cur_device_score == -1 or cur_device_score == 0:
  if device_platform == "iphone":
    model_number = ios_model_number(device_model)
    if model_number >= iphone_high_model:
      cur_device_score = ios_high_score
    elif model_number >= iphone_mid_model:
      cur_device_score = ios_mid_score
  elif device_platform == "ipad":
    model_number = ios_model_number(device_model)
    if model_number >= ipad_high_model:
      cur_device_score = ios_high_score
    elif model_number >= ipad_mid_model:
      cur_device_score = ios_mid_score
  elif device_platform == "android":
    # unrelease devices
    model_list = ["23046rp50c", "23043rp34c"]
    for m in model_list:
        if (device_model.lower().find(m) != -1):
            cur_device_score = android_high_score
            break


# PC 下发匹配规则，自行区分高端、低端机型
pc_low_end_rule = {
    "cpu_frequency": 0,
    "memory": 0,
    "cpu_cores": 0,
    "cpu_threads": 0
}

pc_high_end_rule = {
    "cpu_frequency": 1.6,
    "memory": 8,
    "cpu_cores": 4,
    "cpu_threads": 8
}

pc_super_high_end_rule = {
    "cpu_frequency": 1.6,
    "memory": 8,
    "cpu_cores": 4,
    "cpu_threads": 8
}


def reset_fps_to_0(subconfigs):
  for (k, v) in subconfigs.items():
    if k in ["gallery", "grid", "stage_share_guest", "stage_guest"]:
      for item in v:
        item["conf"]["fps"] = 0
    else:
      v["fps"] = 0


# =================== 码率帧率优化灰度 BEGIN  ========================
publish_table = {
  "1080@24" : {"res" : 1080, "fps" : 24, "max_bitrate" : 2400},
    "720@24" : {"res" :  720, "fps" : 24, "max_bitrate" : 1600},
    "720@20" : {"res" :  720, "fps" : 20, "max_bitrate" : 1600},
    "630@24" : {"res" :  630, "fps" : 24, "max_bitrate" :  900},
    "540@24" : {"res" :  540, "fps" : 24, "max_bitrate" :  830},
    "480@24" : {"res" :  480, "fps" : 24, "max_bitrate" :  740},
    "450@24" : {"res" :  450, "fps" : 24, "max_bitrate" :  740},
    "360@24" : {"res" :  360, "fps" : 24, "max_bitrate" :  460},
    "360@20" : {"res" :  360, "fps" : 20, "max_bitrate" :  460},    
    "360@15" : {"res" :  360, "fps" : 15, "max_bitrate" :  375},
    "270@15" : {"res" :  270, "fps" : 15, "max_bitrate" :  300},
    "180@15" : {"res" :  180, "fps" : 15, "max_bitrate" :  250},
    "180@12" : {"res" :  180, "fps" : 12, "max_bitrate" :  250},
    "144@15" : {"res" :  144, "fps" : 15, "max_bitrate" :  180},
    "90@12" : {"res" :   90, "fps" : 12, "max_bitrate" :  120},
}

if not (device_platform == "windows" or device_platform == "mac" or device_platform == "linux"):
  for key in publish_table:
    publish_table[key]["max_bitrate_1_to_1"] = publish_table[key]["max_bitrate"]

weak_network_mobile = {
    "1080@0": {"good_res": 540, "good_fps": 9, "bad_res": 270, "bad_fps": 20},
    "1080@24": {"good_res": 540, "good_fps": 9, "bad_res": 270, "bad_fps": 20},
    "720@0": {"good_res": 360, "good_fps": 9, "bad_res": 180, "bad_fps": 10},
    "720@24": {"good_res": 360, "good_fps": 9, "bad_res": 180, "bad_fps": 10},
    "540@0": {"good_res": 360, "good_fps": 9, "bad_res": 180, "bad_fps": 10},
    "540@24": {"good_res": 360, "good_fps": 9, "bad_res": 180, "bad_fps": 10},
    "540@18": {"good_res": 360, "good_fps": 9, "bad_res": 180, "bad_fps": 10},
    "480@24": {"good_res": 270, "good_fps": 10, "bad_res": 180, "bad_fps": 10},
    "360@24": {"good_res": 180, "good_fps": 10, "bad_res": 90, "bad_fps": 6},
    "360@24-room": {"good_res": 180, "good_fps": 10, "bad_res": 180, "bad_fps": 1},
    "360@15": {"good_res": 180, "good_fps": 10, "bad_res": 90, "bad_fps": 6},
    "360@15-room": {"good_res": 180, "good_fps": 10, "bad_res": 180, "bad_fps": 1},
    "270@15": {"good_res": 180, "good_fps": 10, "bad_res": 90, "bad_fps": 6},
    "270@15-room": {"good_res": 180, "good_fps": 10, "bad_res": 180, "bad_fps": 1},
    "180@15": {"good_res": 90, "good_fps": 5, "bad_res": 90, "bad_fps": 1},
    "180@15-room": {"good_res": 180, "good_fps": 5, "bad_res": 180, "bad_fps": 1},
    "180@12": {"good_res": 90, "good_fps": 5, "bad_res": 90, "bad_fps": 1},
    "180@12-room": {"good_res": 180, "good_fps": 5, "bad_res": 180, "bad_fps": 1},
    "144@15": {"good_res": 90, "good_fps": 5, "bad_res": 90, "bad_fps": 1},
    "90@12": {"good_res": 90, "good_fps": 5, "bad_res": 90, "bad_fps": 1},
}

weak_network_pad = dict(weak_network_mobile)
weak_network_pad.update(
    {
      "720@24": {"good_res": 540, "good_fps": 9, "bad_res": 270, "bad_fps": 20},
    }
)

weak_network_pc = dict(weak_network_mobile)
weak_network_pc.update(
    {
      "720@24": {"good_res": 540, "good_fps": 9, "bad_res": 270, "bad_fps": 20},
      "180@15": {"good_res": 180, "good_fps": 5, "bad_res": 90, "bad_fps": 1},
      "180@15-room": {"good_res": 180, "good_fps": 5, "bad_res": 180, "bad_fps": 1},
      "720@20": {"good_res": 540, "good_fps": 9, "bad_res": 270, "bad_fps": 20},
      "540@20": {"good_res": 360, "good_fps": 9, "bad_res": 180, "bad_fps": 10},
      "360@20": {"good_res": 180, "good_fps": 10, "bad_res": 90, "bad_fps": 6},
    }
)

def fill_weak_network(subconfigs, weak_network_table):
  for (k, v) in subconfigs.items():
    if k.endswith("share_screen"):
      v.update({"good_res": 0, "good_fps": 0, "bad_res": 0, "bad_fps": 0})
    elif k in ["gallery", "grid", "stage_share_guest", "stage_guest"]:
      for item in v:
        if "good_res" in item["conf"]:
          continue
        res = item["conf"]["res"]
        fps = item["conf"]["fps"]
        if item.get("room_or_sip", 0) == 1:
          key = "{}@{}-room".format(res, fps)
          if key in weak_network_table:
            item["conf"].update(weak_network_table[key])
          else:
            key = "{}@{}".format(res, fps)
            item["conf"].update(weak_network_table[key])
        else:
          key = "{}@{}".format(res, fps)
          item["conf"].update(weak_network_table[key])
    else:
      if "good_res" in v:
        continue
      res = v["res"]
      fps = v["fps"]
      if k.endswith("_sip"):
        key = "{}@{}-room".format(res, fps)
        if key in weak_network_table:
          v.update(weak_network_table[key])
        else:
          key = "{}@{}".format(res, fps)
          v.update(weak_network_table[key])
      else:
        key = "{}@{}".format(res, fps)
        v.update(weak_network_table[key])


pc_high_end_pub = {
    "channel": [
        publish_table["720@24"],
        publish_table["540@24"],
        publish_table["270@15"],
        publish_table["90@12"],
    ],
    "main": [
        publish_table["720@24"],
        publish_table["360@24"],
        publish_table["180@15"],
        publish_table["90@12"],
    ]
}

pc_super_high_end_pub = {
    "channel_high": [
        publish_table["1080@24"],
        publish_table["540@24"],
        publish_table["270@15"],
        publish_table["90@12"],
    ],
    "main_high": [
        publish_table["1080@24"],
        publish_table["360@24"],
        publish_table["180@15"],
        publish_table["90@12"],
    ]
}

pc_super_high_end_pub.update(pc_high_end_pub)

pc_low_end_pub = {
    "channel": [
        publish_table["720@24"],
        publish_table["360@24"],
        publish_table["180@15"],
        publish_table["90@12"],
    ],
    "main": [
        publish_table["720@24"],
        publish_table["360@24"],
        publish_table["180@15"],
        publish_table["90@12"],
    ]
}

pad_high_end_pub = {
    "channel": [
        publish_table["720@24"],
        publish_table["540@24"],
        publish_table["270@15"],
        publish_table["90@12"],
    ],
    "main": [
        publish_table["720@24"],
        publish_table["360@24"],
        publish_table["180@15"],
        publish_table["90@12"],
        ],
    "channel_high": [
        publish_table["1080@24"],
        publish_table["540@24"],
        publish_table["270@15"],
        publish_table["90@12"],
    ],
    "main_high": [
        publish_table["1080@24"],
        publish_table["360@24"],
        publish_table["180@15"],
        publish_table["90@12"],
      ]
}

mobile_high_end_pub = {
    "channel": [
        publish_table["540@24"],
        publish_table["360@15"],
        publish_table["180@15"],
        publish_table["90@12"],
    ],
    "main": [
        publish_table["540@24"],
        publish_table["360@15"],
        publish_table["180@15"],
        publish_table["90@12"],
    ],
    "channel_high": [
        publish_table["720@24"],
        publish_table["360@15"],
        publish_table["180@15"],
        publish_table["90@12"],
    ],
    "main_high": [
        publish_table["720@24"],
        publish_table["360@15"],
        publish_table["180@15"],
        publish_table["90@12"],
    ]
}

mobile_mid_end_pub = {
    "channel": [
        publish_table["540@24"],
        publish_table["360@15"],
        publish_table["180@15"],
        publish_table["90@12"],
    ],
    "main": [
        publish_table["540@24"],
        publish_table["360@15"],
        publish_table["180@15"],
        publish_table["90@12"],
    ]
}

mobile_low_end_pub = {
    "channel": [
        publish_table["360@15"],
        publish_table["180@15"],
        publish_table["90@12"],
    ],
    "main": [
        publish_table["360@15"],
        publish_table["180@15"],
        publish_table["90@12"],
    ]
}

mobile_super_low_end_pub = {
    "channel": [
        publish_table["180@12"],
        publish_table["90@12"],
    ],
    "main": [
        publish_table["180@12"],
        publish_table["90@12"],
    ]
}

pc_end_effect_fps = {
  # 开启虚拟背景时的帧率上限
  "virtual_background_fps": 20, 
  # 开启虚拟形象时的帧率上限
  "animoji_fps": 20,
  # 开启滤镜时的帧率上限
  "filter_fps": 20,
  # 开启美颜时的帧率上限
  "beauty_fps": 20,
  # 同时开启滤镜&美颜时的帧率上限
  "mix_filter_beauty_fps": 20,
  # 其他组合情况时的帧率上限
  "mix_other_fps": 15
}

if version_code >= 5024000 and version_code < 5027000:
    # 兜底线上5.24采集帧率异常问题https://bytedance.feishu.cn/docx/IBCTdlaxmodChTxg2yCcrD9BnQg
    # 先对5.25进行配置，线上验证OK再开5.24
    for key in pc_end_effect_fps:
        pc_end_effect_fps[key] = 21

mobile_end_effect_fps = {
  # 开启虚拟背景时的帧率上限
  "virtual_background_fps": 20, 
  # 开启虚拟形象时的帧率上限
  "animoji_fps": 20,
  # 开启滤镜时的帧率上限
  "filter_fps": 20,
  # 开启美颜时的帧率上限
  "beauty_fps": 20,
  # 同时开启滤镜&美颜时的帧率上限
  "mix_filter_beauty_fps": 15,
  # 其他组合情况时的帧率上限
  "mix_other_fps": 15
}

pc_low_end_stage_guest_sub = [
    {"max": 1, "conf": {"res": 720, "fps": 24}},
    {"max": 2, "conf": {"res": 540, "fps": 24}},
    {"max": 4, "conf": {"res": 360, "fps": 24}},
]

pc_high_end_stage_guest_sub = [
    {"max": 1, "conf": {"res": 1080, "fps": 24}},
    {"max": 2, "conf": {"res": 720, "fps": 24}},
    {"max": 4, "conf": {"res": 720, "fps": 24}},
]

pc_low_end_stage_share_guest_sub = [
    { "max": 2, "conf": {"res": 360, "fps": 15}},
    { "max": 4, "conf": {"res": 180, "fps": 15}},
]

pc_high_end_stage_share_guest_sub = [
    { "max": 1, "conf": {"res": 540, "fps": 24}},
    { "max": 2, "conf": {"res": 360, "fps": 15}},
    { "max": 4, "conf": {"res": 180, "fps": 15}},
]

phone_low_end_stage_guest_sub = [
    { "max": 1, "conf": {"res": 360, "fps": 15}},
    { "max": 2, "conf": {"res": 360, "fps": 15}},
    { "max": 4, "conf": {"res": 180, "fps": 15}},
    { "max": 4, "room_or_sip": 1, "conf": {"res": 180, "fps": 15}},
]

phone_high_end_stage_guest_sub = [
    { "max": 1, "conf": {"res": 1080, "fps": 24}},
    { "max": 2, "conf": {"res": 360, "fps": 15}},
    { "max": 4, "conf": {"res": 180, "fps": 15}},
    { "max": 4, "room_or_sip": 1, "conf": {"res": 180, "fps": 15}},
]

pad_low_end_stage_guest_sub = [
    { "max": 1, "conf": {"res": 540, "fps": 24}},
    { "max": 2, "conf": {"res": 360, "fps": 24}},
    { "max": 4, "conf": {"res": 180, "fps": 15}},
]

pad_mid_end_stage_guest_sub = [
    { "max": 1, "conf": {"res": 540, "fps": 24}},
    { "max": 2, "conf": {"res": 360, "fps": 24}},
    { "max": 4, "conf": {"res": 180, "fps": 15}},
]

pad_high_end_stage_guest_sub = [
    {"max": 1, "conf": {"res": 1080, "fps": 24}},
    {"max": 2, "conf": {"res": 720, "fps": 24}},
    {"max": 4, "conf": {"res": 540, "fps": 24}},
]

phone_low_end_stage_share_guest_sub = [
    { "max": 1, "conf": {"res": 360, "fps": 15}},
    { "max": 2, "conf": {"res": 180, "fps": 15}},
    { "max": 4, "conf": {"res": 90, "fps": 12}},
    { "max": 4, "room_or_sip": 1, "conf": {"res": 180, "fps": 15}},
]

phone_high_end_stage_share_guest_sub = [
    { "max": 1, "conf": {"res": 360, "fps": 15}},
    { "max": 4, "conf": {"res": 180, "fps": 15}},
    { "max": 4, "room_or_sip": 1, "conf": {"res": 180, "fps": 15}},
]

pad_low_end_stage_share_guest_sub = [
    { "max": 2, "conf": {"res": 360, "fps": 15}},
    { "max": 4, "conf": {"res": 180, "fps": 15}},
]

pad_mid_end_stage_share_guest_sub = [
    { "max": 2, "conf": {"res": 360, "fps": 15}},
    { "max": 4, "conf": {"res": 180, "fps": 15}},
]

pad_high_end_stage_share_guest_sub = [
    { "max": 1, "conf": {"res": 540, "fps": 24}},
    { "max": 2, "conf": {"res": 360, "fps": 15}},
    { "max": 4, "conf": {"res": 180, "fps": 15}},
]

phone_super_low_end_sub = {
    "stage_guest": phone_low_end_stage_guest_sub,
    "stage_share_guest": phone_low_end_stage_share_guest_sub,
    # 全屏查看，放大 & pin
    "grid_full": {"res": 360, "fps": 15},

    # 2 宫格平分
    "grid_half": {"res": 360, "fps": 15},

    # 520 宫格平分 sip/rooms
    "grid_half_sip": {"res": 360, "fps": 15}, # 520 弱网新增

    "grid_quarter": {"res": 180, "fps": 15},

    # 4 宫格平分 sip/rooms
    "grid_quarter_sip": {"res": 180, "fps": 15}, # 520 弱网新增

    # 最小化悬浮窗
    "grid_float": {"res": 180, "fps": 15},

    # 最小化悬浮窗 sip/rooms
    "grid_float_sip": {"res": 180, "fps": 15}, # 520 弱网新增

    # 共享屏幕，大图
    "grid_share_screen": {"res": 720, "fps": 24},

    # 共享屏幕，小图
    "grid_share_row": {"res": 90, "fps": 12}, 

    # 共享屏幕，小图 sip/rooms
    "grid_share_row_sip": {"res": 180, "fps": 12}, # 520 弱网新增

    # 新布局
    # 全屏查看，放大 & pin
    "new_grid_full": {"res": 360, "fps": 15},
    # 二宫格
    "new_grid_half": {"res": 360, "fps": 15},
    # 二宫格 sip/rooms
    "new_grid_half_sip": {"res": 360, "fps": 15}, # 520 弱网新增

    # 3 ~ 6 宫格
    "new_grid_6": {"res": 180, "fps": 12},

    # 3 ~ 6 宫格 sip/room
    "new_grid_6_sip": {"res": 360, "fps": 15},
}

phone_low_end_sub = {
    "stage_guest": phone_low_end_stage_guest_sub,
    "stage_share_guest": phone_low_end_stage_share_guest_sub,
    # 全屏查看，放大 & pin
    "grid_full": {"res": 360, "fps": 15},

    # 2 宫格平分
    "grid_half": {"res": 360, "fps": 15},

    # 520 宫格平分 sip/rooms
    "grid_half_sip": {"res": 360, "fps": 15}, # 520 弱网新增

    "grid_quarter": {"res": 180, "fps": 15},

    # 4 宫格平分 sip/rooms
    "grid_quarter_sip": {"res": 180, "fps": 15}, # 520 弱网新增

    # 最小化悬浮窗
    "grid_float": {"res": 180, "fps": 15},

    # 最小化悬浮窗 sip/rooms
    "grid_float_sip": {"res": 180, "fps": 15}, # 520 弱网新增

    # 共享屏幕，大图
    "grid_share_screen": {"res": 720, "fps": 24},

    # 共享屏幕，小图
    "grid_share_row": {"res": 90, "fps": 12}, 

    # 共享屏幕，小图 sip/rooms
    "grid_share_row_sip": {"res": 180, "fps": 15}, # 520 弱网新增

    # 新布局
    # 全屏查看，放大 & pin
    "new_grid_full": {"res": 360, "fps": 15},
    # 二宫格
    "new_grid_half": {"res": 360, "fps": 15},
    # 二宫格 sip/rooms
    "new_grid_half_sip": {"res": 360, "fps": 15}, # 520 弱网新增

    # 3 ~ 6 宫格
    "new_grid_6": {"res": 180, "fps": 15},

    # 3 ~ 6 宫格 sip/room
    "new_grid_6_sip": {"res": 360, "fps": 24},
}

phone_high_end_sub = {
    "stage_guest": phone_high_end_stage_guest_sub,
    "stage_share_guest": phone_high_end_stage_share_guest_sub,
    # 全屏查看，放大 & pin
    "grid_full": {"res": 1080, "fps": 24},

    # 2 宫格平分
    "grid_half": {"res": 360, "fps": 15},
    # 2 宫格平分 sip/rooms
    "grid_half_sip": {"res": 360, "fps": 15}, # 520 弱网新增

    # 4 宫格
    "grid_quarter": {"res": 180, "fps": 15},
    # 4 宫格平分 sip/rooms
    "grid_quarter_sip": {"res": 180, "fps": 15}, # 520 弱网新增

    # 最小化悬浮窗
    "grid_float": {"res": 180, "fps": 15},
    # 最小化悬浮窗 sip/rooms
    "grid_float_sip": {"res": 180, "fps": 15}, # 520 弱网新增

    # 共享屏幕，大图
    "grid_share_screen": {"res": 1080, "fps": 24},

    # 共享屏幕，小图
    "grid_share_row": {"res": 90, "fps": 12},
    # 共享屏幕，小图 sip/rooms
    "grid_share_row_sip": {"res": 180, "fps": 15}, # 520 弱网新增

    # 新布局
    # 全屏查看，放大 & pin
    "new_grid_full": {"res": 1080, "fps": 24},

    # 二宫格
    "new_grid_half": {"res": 360, "fps": 15},
    # 二宫格 sip/rooms
    "new_grid_half_sip": {"res": 360, "fps": 15}, # 520 弱网新增

    # 3 ~ 6 宫格
    "new_grid_6": {"res": 180, "fps": 15},

    # 3 ~ 6 宫格 sip/room
    "new_grid_6_sip": {"res": 360, "fps": 15},
}

pad_super_low_end_gallery_sub = [
    {"max": 1, "conf": {"res": 540, "fps": 18}},
    {"max": 2, "conf": {"res": 360, "fps": 15}},
    {"max": 4, "conf": {"res": 180, "fps": 12}},
    {"max": 4, "room_or_sip": 1, "conf": {"res": 180, "fps": 12}},
]

pad_low_end_gallery_sub = [
    {"max": 1, "conf": {"res": 540, "fps": 24}},
    {"max": 2, "conf": {"res": 360, "fps": 24}},
    {"max": 4, "conf": {"res": 180, "fps": 15}},
    {"max": 4, "room_or_sip": 1, "conf": {"res": 180, "fps": 15}},
]

pad_mid_end_gallery_sub = [
    {"max": 1, "conf": {"res": 540, "fps": 24}},
    {"max": 2, "conf": {"res": 360, "fps": 24}},
    {"max": 4, "conf": {"res": 180, "fps": 15}},
    {"max": 4, "room_or_sip": 1, "conf": {"res": 180, "fps": 15}},
    {"max": 9, "conf": {"res": 180, "fps": 15}},
    {"max": 9, "room_or_sip": 1, "conf": {"res": 180, "fps": 15}},
]

pad_high_end_gallery_sub = [
    {"max": 1, "conf": {"res": 1080, "fps": 24}},
    {"max": 2, "conf": {"res": 720, "fps": 24}},
    {"max": 4, "conf": {"res": 540, "fps": 24}},
    {"max": 6, "conf": {"res": 360, "fps": 24}},
    {"max": 9, "conf": {"res": 270, "fps": 15}},
    {"max": 16, "conf": {"res": 180, "fps": 15}},
    {"max": 16, "room_or_sip": 1, "conf": {"res": 180, "fps": 15}},
    {"max": 25, "conf": {"res": 90, "fps": 12}},
    {"max": 25, "room_or_sip": 1, "conf": {"res": 180, "fps": 15}},
]

pad_super_low_end_sub = {
    "stage_guest": pad_low_end_stage_guest_sub,
    "stage_share_guest": pad_low_end_stage_share_guest_sub,
    "gallery": pad_super_low_end_gallery_sub,
    "grid_full": {"res": 540, "fps": 18},

    "grid_half": {"res": 360, "fps": 15},
    # 2 宫格平分 sip/rooms
    "grid_half_sip": {"res": 360, "fps": 15}, # 520 弱网新增

    "grid_quarter": {"res": 180, "fps": 12},
    # 4 宫格平分 sip/rooms
    "grid_quarter_sip": {"res": 180, "fps": 12}, # 520 弱网新增

    # 最小化悬浮窗
    "grid_float": {"res": 180, "fps": 15},
    # 最小化悬浮窗 sip/rooms
    "grid_float_sip": {"res": 180, "fps": 15},

    "grid_share_screen": {"res": 720, "fps": 24},

    "grid_share_row": {"res": 90, "fps": 12},
    # 共享屏幕，小图 sip/rooms
    "grid_share_row_sip": {"res": 180, "fps": 12}, # 520 弱网新增
}

pad_low_end_sub = {
    "stage_guest": pad_low_end_stage_guest_sub,
    "stage_share_guest": pad_low_end_stage_share_guest_sub,
    "gallery": pad_low_end_gallery_sub,
    "grid_full": {"res": 540, "fps": 24},

    "grid_half": {"res": 360, "fps": 24},
    # 2 宫格平分 sip/rooms
    "grid_half_sip": {"res": 360, "fps": 24}, # 520 弱网新增

    "grid_quarter": {"res": 180, "fps": 15},
    # 4 宫格平分 sip/rooms
    "grid_quarter_sip": {"res": 180, "fps": 15}, # 520 弱网新增

    # 最小化悬浮窗
    "grid_float": {"res": 180, "fps": 15},
    # 最小化悬浮窗 sip/rooms
    "grid_float_sip": {"res": 180, "fps": 15},

    "grid_share_screen": {"res": 720, "fps": 24},

    "grid_share_row": {"res": 90, "fps": 12},
    # 共享屏幕，小图 sip/rooms
    "grid_share_row_sip": {"res": 180, "fps": 15}, # 520 弱网新增
}

pad_mid_end_sub = {
    "stage_guest": pad_mid_end_stage_guest_sub,
    "stage_share_guest": pad_mid_end_stage_share_guest_sub,
    "gallery": pad_mid_end_gallery_sub,
    "grid_full": {"res": 1080, "fps": 24},

    "grid_half": {"res": 360, "fps": 24},
    "grid_half_sip": {"res": 360, "fps": 24}, # 520 弱网新增

    "grid_quarter": {"res": 360, "fps": 24},
    "grid_quarter_sip": {"res": 360, "fps": 24}, # 520 弱网新增

    # 最小化悬浮窗
    "grid_float": {"res": 180, "fps": 15},
    # 最小化悬浮窗 sip/rooms
    "grid_float_sip": {"res": 180, "fps": 15},

    "grid_share_screen": {"res": 1080, "fps": 24},

    "grid_share_row": {"res": 90, "fps": 12},
    # 共享屏幕，小图 sip/rooms
    "grid_share_row_sip": {"res": 180, "fps": 15}, # 520 弱网新增
}

pad_high_end_sub = dict(pad_mid_end_sub)
pad_high_end_sub["gallery"] = pad_high_end_gallery_sub
pad_high_end_sub["stage_share_guest"] = pad_high_end_stage_share_guest_sub
pad_high_end_sub["stage_guest"] = pad_high_end_stage_guest_sub

pc_low_end_sub = {
    "stage_guest": pc_low_end_stage_guest_sub,
    "stage_share_guest": pc_low_end_stage_share_guest_sub,
    "grid": [
      {"max": 1, "conf": {"res": 720, "fps": 24}},
      {"max": 2, "conf": {"res": 540, "fps": 24}},
      {"max": 4, "conf": {"res": 360, "fps": 24}},
      {"max": 16, "room_or_sip": 1, "conf": {"res": 180, "fps": 15}},
      {"max": 16, "room_or_sip": 0, "conf": {"res": 180, "fps": 15}},
      {"max": 25, "room_or_sip": 1, "conf": {"res": 180, "fps": 15}},
      {"max": 25, "room_or_sip": 0, "conf": {"res": pc_pin_small_and_25gallery_res, "fps": 12}},
    ],

    "floating": {"res": 180, "fps": 15},
    "floating_sip": {"res": 180, "fps": 15}, # 520 弱网新增

    # 缩略图视图或者 PIN，AS
    "pin_as": {"res": 720, "fps": 0, "min": 630},

    # 缩略图视图或者 PIN，小图
    "pin_small": {"res": pc_pin_small_and_25gallery_res, "fps": 12},
    "pin_small_sip": {"res": 180, "fps": 15}, # 520 弱网新增

    # 演讲者视图或焦点视频，AS
    "speech_as": {"res": 720, "fps": 0, "min": 630},
    # 演讲者视图或焦点视频，小图
    "speech_small": {"res": pc_pin_small_and_25gallery_res, "fps": 12},
    # 演讲者视图或焦点视频，小图 sip/rooms
    "speech_small_sip": {"res": 180, "fps": 15}, # 520 弱网新增

    "share_screen": {"res": 1080, "fps": 24},
    "share_screen_row": {"res": pc_pin_small_and_25gallery_res, "fps": 12},
    "share_screen_row_sip": {"res": 180, "fps": 15}, # 520 弱网新增
}

pc_high_end_sub = {
    "stage_guest": pc_high_end_stage_guest_sub,
    "stage_share_guest": pc_high_end_stage_share_guest_sub,
    "grid": [
      {"max": 1, "conf": {"res": 1080, "fps": 24}},
      {"max": 2, "conf": {"res": 720, "fps": 24}},
      {"max": 4, "conf": {"res": 720, "fps": 24}},
      {"max": 9, "room_or_sip": 1, "conf": {"res": 360, "fps": 24}},
      {"max": 9, "room_or_sip": 0, "conf": {"res": 360, "fps": 24}},
      {"max": 16, "room_or_sip": 1, "conf": {"res": 360, "fps": 24}},
      {"max": 16, "room_or_sip": 0, "conf": {"res": 360, "fps": 24}},
      {"max": 25, "room_or_sip": 1, "conf": {"res": 180, "fps": 15}},
      {"max": 25, "room_or_sip": 0, "conf": {"res": 180, "fps": 15}},
    ],

    "floating": {"res": 180, "fps": 15},
    "floating_sip": {"res": 180, "fps": 15}, # 520 弱网新增

    # 缩略图视图或者 PIN，AS
    "pin_as": {"res": 1080, "fps": 24, "min": 630},
    # 缩略图视图或者 PIN，小图
    "pin_small": {"res": pc_pin_small_and_25gallery_res, "fps": 12},
    "pin_small_sip": {"res": 180, "fps": 15}, # 520 弱网新增

    # 演讲者视图或焦点视频，AS
    "speech_as": {"res": 1080, "fps": 24, "min": 630},
    # 演讲者视图或焦点视频，小图
    "speech_small": {"res": 180, "fps": 15},
    # 演讲者视图或焦点视频，小图 sip/rooms
    "speech_small_sip": {"res": 180, "fps": 15}, # 520 弱网新增

    "share_screen": {"res": 1080, "fps": 24},
    "share_screen_row": {"res": pc_pin_small_and_25gallery_res, "fps": 12},
    "share_screen_row_sip": {"res": 180, "fps": 15}, # 520 弱网新增
}

pc_super_high_end_sub = pc_high_end_sub
# =================== 码率帧率优化灰度 END ========================

pc_sub_720_360_180_180 = {
    "grid": [
        {"max": 1, "conf": {"res": 720, "fps": 30, "good_res": 720, "good_fps": 10, "bad_res": 270, "bad_fps": 20}},
        {"max": 2, "conf": {"res": 720, "fps": 30, "good_res": 360, "good_fps": 10, "bad_res": 180, "bad_fps": 7}},
        {"max": 4, "conf": {"res": 360, "fps": 30, "good_res": 360, "good_fps": 10, "bad_res": 180, "bad_fps": 7}},
        {"max": 9, "room_or_sip": 1, "conf": {"res": 180, "fps": 15, "good_res": 180, "good_fps": 10, "bad_res": 180, "bad_fps": 1}},
        {"max": 9, "room_or_sip": 0, "conf": {"res": 180, "fps": 15, "good_res": 180, "good_fps": 10, "bad_res": 90, "bad_fps": 7}},
        {"max": 16, "room_or_sip": 1, "conf": {"res": 180, "fps": 15, "good_res": 180, "good_fps": 10, "bad_res": 180, "bad_fps": 1}},
        {"max": 16, "room_or_sip": 0, "conf": {"res": 180, "fps": 15, "good_res": 180, "good_fps": 10, "bad_res": 90, "bad_fps": 7}},
        {"max": 25, "room_or_sip": 1, "conf": {"res": 180, "fps": 15, "good_res": 180, "good_fps": 5, "bad_res": 180, "bad_fps": 1}},
        {"max": 25, "room_or_sip": 0, "conf": {"res": pc_pin_small_and_25gallery_res, "fps": 12, "good_res": 90, "good_fps": 5, "bad_res": 90, "bad_fps": 1}},
    ],

    "floating": {"res": 180, "fps": 15, "good_res": 90, "good_fps": 2, "bad_res": 90, "bad_fps": 1},
    "floating_sip": {"res": 180, "fps": 15, "good_res": 180, "good_fps": 2, "bad_res": 180, "bad_fps": 1}, # 520 弱网新增

    # 缩略图视图或者 PIN，AS
    "pin_as": {"res": 720, "fps": 30, "good_res": 720, "good_fps": 10, "bad_res": 270, "bad_fps": 15},
    # 缩略图视图或者 PIN，小图
    "pin_small": {"res": pc_pin_small_and_25gallery_res, "fps": 15, "good_res": 90, "good_fps": 2, "bad_res": 90, "bad_fps": 1},
    "pin_small_sip": {"res": 180, "fps": 15, "good_res": 180, "good_fps": 2, "bad_res": 180, "bad_fps": 1}, # 520 弱网新增

    # 演讲者视图或焦点视频，AS
    "speech_as": {"res": 720, "fps": 30, "good_res": 720, "good_fps": 10, "bad_res": 270, "bad_fps": 15},
    # 演讲者视图或焦点视频，小图
    "speech_small": {"res": 180, "fps": 15, "good_res": 90, "good_fps": 2, "bad_res": 90, "bad_fps": 1},
    # 演讲者视图或焦点视频，小图 sip/rooms
    "speech_small_sip": {"res": 180, "fps": 15, "good_res": 180, "good_fps": 2, "bad_res": 180, "bad_fps": 1}, # 520 弱网新增

    "share_screen": {"res": 1080, "fps": 30, "good_res": 0, "good_fps": 0, "bad_res": 0, "bad_fps": 0},
    "share_screen_row": {"res": 180, "fps": 15, "good_res": 90, "good_fps": 2, "bad_res": 90, "bad_fps": 1},
    "share_screen_row_sip": {"res": 180, "fps": 15, "good_res": 180, "good_fps": 2, "bad_res": 180, "bad_fps": 1}, # 520 弱网新增
}

# 兼容PC xx 版本前宫格订阅配置 # 520 弱网新增
if version_code < 5020000:
    pc_low_end_sub["grid"] = [
        {"max": 1, "conf": {"res": 720, "fps": 30}},
        {"max": 2, "conf": {"res": 540, "fps": 30}},
        {"max": 4, "conf": {"res": 360, "fps": 30}},
        {"max": 9, "conf": {"res": 180, "fps": 15}},
        {"max": 16, "conf": {"res": 180, "fps": 15}},
        {"max": 25, "conf": {"res": pc_pin_small_and_25gallery_res, "fps": 15}},
        {"max": 25, "room_or_sip": 1, "conf": {"res": 180, "fps": 15}},
    ]
    pc_high_end_sub["grid"] = [
        {"max": 3, "conf": {"res": 720, "fps": 30}},
        {"max": 4, "conf": {"res": 540, "fps": 30}},
        {"max": 6, "conf": {"res": 360, "fps": 30}},
        {"max": 9, "conf": {"res": 270, "fps": 30}},
        {"max": 16, "conf": {"res": 180, "fps": 15}},
        {"max": 25, "conf": {"res": pc_pin_small_and_25gallery_res, "fps": 15}},
        {"max": 25, "room_or_sip": 1, "conf": {"res": 180, "fps": 15}},
    ]
    pc_sub_720_360_180_180["grid"] = [
        {"max": 2, "conf": {"res": 720, "fps": 30}},
        {"max": 4, "conf": {"res": 360, "fps": 30}},
        {"max": 9, "conf": {"res": 180, "fps": 15}},
        {"max": 16, "conf": {"res": 180, "fps": 15}},
        {"max": 25, "conf": {"res": pc_pin_small_and_25gallery_res, "fps": 15}},
    ]

pc_super_high_end = {
    "rule": pc_super_high_end_rule,
    "publish": pc_super_high_end_pub,
    "subscribe": pc_super_high_end_sub,
    "effect_fps": pc_end_effect_fps,
}

pc_high_end = {
    "rule": pc_high_end_rule,
    "publish": pc_high_end_pub,
    "subscribe": pc_high_end_sub,
    "effect_fps": pc_end_effect_fps,
}

pc_low_end = {
    "rule": pc_low_end_rule,
    "publish": pc_low_end_pub,
    "subscribe": pc_low_end_sub,
    "effect_fps": pc_end_effect_fps,
}


# 多分辨率需求前 simulcast 兼容逻辑
phone_sub_720_480_240_240 = {
    # 全屏查看，放大 & pin
    "grid_full": {"res": 720, "fps": 30, "good_res": 360, "good_fps": 10, "bad_res": 180, "bad_fps": 10},

    # 2 宫格平分
    "grid_half": {"res": 480, "fps": 30, "good_res": 180, "good_fps": 10, "bad_res": 90, "bad_fps": 1},
    # 2 宫格平分 sip/rooms
    "grid_half_sip": {"res": 480, "fps": 30, "good_res": 180, "good_fps": 10, "bad_res": 180, "bad_fps": 1}, # 520 弱网新增

    "grid_quarter": {"res": 240, "fps": 15, "good_res": 90, "good_fps": 10, "bad_res": 90, "bad_fps": 1},
    # 4 宫格平分 sip/rooms
    "grid_quarter_sip": {"res": 240, "fps": 15, "good_res": 180, "good_fps": 10, "bad_res": 180, "bad_fps": 1}, # 520 弱网新增

    # 最小化悬浮窗
    "grid_float": {"res": 240, "fps": 15, "good_res": 90, "good_fps": 5, "bad_res": 90, "bad_fps": 1},
    # 最小化悬浮窗 sip/rooms
    "grid_float_sip": {"res": 240, "fps": 15, "good_res": 180, "good_fps": 5, "bad_res": 180, "bad_fps": 1}, # 520 弱网新增

    # 共享屏幕，大图
    "grid_share_screen": {"res": 720, "fps": 30, "good_res": 0, "good_fps": 0, "bad_res": 0, "bad_fps": 0},

    # 共享屏幕，小图
    "grid_share_row": {"res": 240, "fps": 15, "good_res": 90, "good_fps": 10, "bad_res": 90, "bad_fps": 1},
    # 共享屏幕，小图 sip/rooms
    "grid_share_row_sip": {"res": 240, "fps": 15, "good_res": 180, "good_fps": 5, "bad_res": 180, "bad_fps": 1}, # 520 弱网新增

    # 新布局
    # 全屏查看，放大 & pin
    "new_grid_full": {"res": 720, "fps": 30, "good_res": 360, "good_fps": 10, "bad_res": 180, "bad_fps": 10},
    # 二宫格
    "new_grid_half": {"res": 480, "fps": 30, "good_res": 180, "good_fps": 10, "bad_res": 90, "bad_fps": 1},
    # 二宫格 sip/rooms
    "new_grid_half_sip": {"res": 480, "fps": 30, "good_res": 180, "good_fps": 10, "bad_res": 180, "bad_fps": 1}, # 520 弱网新增

    # 3 ~ 6 宫格
    "new_grid_6": {"res": 240, "fps": 30, "good_res": 90, "good_fps": 15, "bad_res": 90, "bad_fps": 1},
    "new_grid_6_sip": {"res": 240, "fps": 30, "good_res": 180, "good_fps": 10, "bad_res": 180, "bad_fps": 1}, 
}

pad_sub_720_480_480_240 = {
    # 全屏查看，放大 & pin
    "grid_full": {"res": 720, "fps": 30, "good_res": 360, "good_fps": 10, "bad_res": 180, "bad_fps": 10},

    # 2 宫格平分
    "grid_half": {"res": 480, "fps": 30, "good_res": 180, "good_fps": 10, "bad_res": 90, "bad_fps": 1},
    # 2 宫格平分 sip/rooms
    "grid_half_sip": {"res": 480, "fps": 30, "good_res": 180, "good_fps": 10, "bad_res": 180, "bad_fps": 1}, # 520 弱网新增

    "grid_quarter": {"res": 480, "fps": 15, "good_res": 90, "good_fps": 10, "bad_res": 90, "bad_fps": 1},
    # 4 宫格平分 sip/rooms
    "grid_quarter_sip": {"res": 480, "fps": 15, "good_res": 180, "good_fps": 10, "bad_res": 180, "bad_fps": 1}, # 520 弱网新增

    # 最小化悬浮窗
    "grid_float": {"res": 240, "fps": 15, "good_res": 90, "good_fps": 5, "bad_res": 90, "bad_fps": 1},
    # 最小化悬浮窗 sip/rooms
    "grid_float_sip": {"res": 240, "fps": 15, "good_res": 180, "good_fps": 5, "bad_res": 180, "bad_fps": 1}, # 520 弱网新增

    # 共享屏幕，大图
    "grid_share_screen": {"res": 720, "fps": 30, "good_res": 0, "good_fps": 0, "bad_res": 0, "bad_fps": 0},

    # 共享屏幕，小图
    "grid_share_row": {"res": 240, "fps": 15, "good_res": 90, "good_fps": 5, "bad_res": 90, "bad_fps": 1},
     # 共享屏幕，小图 sip/rooms
    "grid_share_row_sip": {"res": 240, "fps": 15, "good_res": 180, "good_fps": 5, "bad_res": 180, "bad_fps": 1}, # 520 弱网新增

    # 新布局
    # 全屏查看，放大 & pin
    "new_grid_full": {"res": 720, "fps": 30, "good_res": 360, "good_fps": 10, "bad_res": 180, "bad_fps": 10},
    # 二宫格
    "new_grid_half": {"res": 480, "fps": 30, "good_res": 180, "good_fps": 10, "bad_res": 90, "bad_fps": 1},
    # 二宫格 sip/rooms
    "new_grid_half_sip": {"res": 480, "fps": 30, "good_res": 180, "good_fps": 10, "bad_res": 180, "bad_fps": 1}, # 520 弱网新增

    # 3 ~ 6 宫格
    "new_grid_6": {"res": 240, "fps": 30, "good_res": 90, "good_fps": 15, "bad_res": 90, "bad_fps": 1},
    "new_grid_6_sip": {"res": 240, "fps": 30, "good_res": 180, "good_fps": 10, "bad_res": 180, "bad_fps": 1},
}

pad_sub_720_480_480_240["gallery"] = pad_mid_end_gallery_sub

phone_sub_480_480_240_240 = {
    # 全屏查看，放大 & pin
    "grid_full": {"res": 480, "fps": 30, "good_res": 360, "good_fps": 10, "bad_res": 180, "bad_fps": 10},

    # 2 宫格平分
    "grid_half": {"res": 480, "fps": 15, "good_res": 180, "good_fps": 10, "bad_res": 90, "bad_fps": 1},
    # 2 宫格平分 sip/rooms
    "grid_half_sip": {"res": 480, "fps": 15, "good_res": 180, "good_fps": 10, "bad_res": 180, "bad_fps": 1}, # 520 弱网新增

    "grid_quarter": {"res": 240, "fps": 15, "good_res": 90, "good_fps": 10, "bad_res": 90, "bad_fps": 1},
    # 4 宫格平分 sip/rooms
    "grid_quarter_sip": {"res": 240, "fps": 15, "good_res": 180, "good_fps": 10, "bad_res": 180, "bad_fps": 1}, # 520 弱网新增

    # 最小化悬浮窗
    "grid_float": {"res": 240, "fps": 15, "good_res": 90, "good_fps": 5, "bad_res": 90, "bad_fps": 1},
    # 最小化悬浮窗 sip/rooms
    "grid_float_sip": {"res": 240, "fps": 15, "good_res": 180, "good_fps": 5, "bad_res": 180, "bad_fps": 1}, # 520 弱网新增

    # 共享屏幕，大图
    "grid_share_screen": {"res": 480, "fps": 30, "good_res": 0, "good_fps": 0, "bad_res": 0, "bad_fps": 0},

    # 共享屏幕，小图
    "grid_share_row": {"res": 240, "fps": 15, "good_res": 90, "good_fps": 10, "bad_res": 90, "bad_fps": 1},
    # 共享屏幕，小图 sip/rooms
    "grid_share_row_sip": {"res": 240, "fps": 15, "good_res": 180, "good_fps": 5, "bad_res": 180, "bad_fps": 1}, # 520 弱网新增

    # 新布局
    # 全屏查看，放大 & pin
    "new_grid_full": {"res": 480, "fps": 30, "good_res": 360, "good_fps": 10, "bad_res": 180, "bad_fps": 10},

    # 二宫格
    "new_grid_half": {"res": 480, "fps": 15, "good_res": 180, "good_fps": 10, "bad_res": 90, "bad_fps": 1},
    # 二宫格 sip/rooms
    "new_grid_half_sip": {"res": 480, "fps": 15, "good_res": 180, "good_fps": 10, "bad_res": 180, "bad_fps": 1}, # 520 弱网新增

    # 3 ~ 6 宫格
    "new_grid_6": {"res": 240, "fps": 30, "good_res": 90, "good_fps": 15, "bad_res": 90, "bad_fps": 1},
    "new_grid_6_sip": {"res": 240, "fps": 30, "good_res": 180, "good_fps": 10, "bad_res": 180, "bad_fps": 1},
}

pad_sub_480_480_240_240 = dict(phone_sub_480_480_240_240)
pad_sub_480_480_240_240["gallery"] = pad_low_end_gallery_sub

mobile_high_end = {
    "phone": {
        "publish": mobile_high_end_pub,
        "subscribe": phone_high_end_sub,
        "effect_fps": mobile_end_effect_fps,
      },
    "pad": {
        "publish": pad_high_end_pub,
        "subscribe": pad_high_end_sub,
        "effect_fps": mobile_end_effect_fps,
    },
    "view_size_debounce" : 1.0,
    "simulcast_deprecate": {
      "phone": phone_sub_720_480_240_240,
      "pad": pad_sub_720_480_480_240,
    }
}


mobile_mid_end = {
    "phone": {
        "publish": mobile_mid_end_pub,
        "subscribe": phone_high_end_sub,
        "effect_fps": mobile_end_effect_fps,
      },
    "pad": {
        "publish": mobile_mid_end_pub,
        "subscribe": pad_mid_end_sub,
        "effect_fps": mobile_end_effect_fps,
    },
    "view_size_debounce" : 1.0,
    "simulcast_deprecate": {
      "phone": phone_sub_720_480_240_240,
      "pad": pad_sub_720_480_480_240,
    }
}

mobile_low_end = {
    "phone": {
        "publish": mobile_low_end_pub,
        "subscribe": phone_low_end_sub,
        "effect_fps": mobile_end_effect_fps,
    },
    "pad": {
        "publish": mobile_low_end_pub,
        "subscribe": pad_low_end_sub,
        "effect_fps": mobile_end_effect_fps,
    },
    "view_size_debounce" : 1.0,
    # 不在多分辨率 FG 中
    "simulcast_deprecate": {
      "phone": phone_sub_480_480_240_240,
      "pad": pad_sub_480_480_240_240,
    }
}

# 根据设备id倒数第二位是否命中ab
def enable_abtest(device_id):
    deviceId = str(device_id)
    ab = '-1'
    did = ['0', '1', '2', '3', '4']
    if len(deviceId) > 1:
        ab = deviceId[-2]
    if (ab in did):
        return True
    return False

# 超低端机配置默认和低端机一致
mobile_super_low_end = mobile_low_end

# 设备版本>=6.1
if device_platform == "android" and version_code >= 6001000:
  mobile_low_end_effect_fps = dict(mobile_end_effect_fps)
  #（超）低端机fps统一修改为12
  for key in mobile_low_end_effect_fps:
    mobile_low_end_effect_fps[key] = 12

  # 静态策略适配，（超）低端机帧率调整12
  mobile_low_end["phone"]["effect_fps"] = mobile_low_end_effect_fps
  mobile_low_end["pad"]["effect_fps"] = mobile_low_end_effect_fps

  # 定义超低端机发布、订阅配置  
  mobile_super_low_end = {
    "phone": {
        "publish": mobile_super_low_end_pub,
        "subscribe": phone_super_low_end_sub,
        "effect_fps": mobile_low_end_effect_fps,
    },
    "pad": {
        "publish": mobile_super_low_end_pub,
        "subscribe": pad_super_low_end_sub,
        "effect_fps": mobile_low_end_effect_fps,
    },
    "view_size_debounce" : 1.0,
    # 不在多分辨率 FG 中
    "simulcast_deprecate": {
      "phone": phone_sub_480_480_240_240,
      "pad": pad_sub_480_480_240_240,
    }
  }


#pc 6.1 静态配置策略
# 静态配置：高端
pc_score_high_end_pub = {
    "channel_high": [
        publish_table["1080@24"],
        publish_table["540@24"],
        publish_table["270@15"],
        publish_table["90@12"],
    ],
    "main_high": [
        publish_table["1080@24"],
        publish_table["360@24"],
        publish_table["180@15"],
        publish_table["90@12"],
    ],
    "channel": [
        publish_table["720@24"],
        publish_table["540@24"],
        publish_table["270@15"],
        publish_table["90@12"],
    ],
    "main": [
        publish_table["720@24"],
        publish_table["360@24"],
        publish_table["180@15"],
        publish_table["90@12"],
    ]
}
# 静态配置：中端
pc_score_mid_end_pub = {
    "channel": [
        publish_table["720@24"],
        publish_table["540@24"],
        publish_table["270@15"],
        publish_table["90@12"],
    ],
    "main": [
        publish_table["720@24"],
        publish_table["360@24"],
        publish_table["180@15"],
        publish_table["90@12"],
    ]
}      
# 静态配置：低端机720p 360p fps 24 ->20
pc_score_low_end_pub = {
    "channel": [
        publish_table["720@20"],
        publish_table["360@20"],
        publish_table["180@15"],
        publish_table["90@12"],
    ],
    "main": [
        publish_table["720@20"],
        publish_table["360@20"],
        publish_table["180@15"],
        publish_table["90@12"],
    ]
}
# 静态配置：添加超低端机
pc_score_ultra_low_end_pub = {
    "channel": [
        publish_table["720@20"],
        publish_table["360@15"],
        publish_table["180@15"],
        publish_table["90@12"],
    ],
    "main": [
        publish_table["720@20"],
        publish_table["360@15"],
        publish_table["180@15"],
        publish_table["90@12"],
    ]
}

# 订阅
pc_score_high_end_sub = {
    "stage_guest": pc_high_end_stage_guest_sub,
    "stage_share_guest": pc_high_end_stage_share_guest_sub,
    "grid": [
        {"max": 1, "conf": {"res": 1080, "fps": 24}},
        {"max": 2, "conf": {"res": 720, "fps": 24}},
        {"max": 4, "conf": {"res": 720, "fps": 24}},
        {"max": 9, "room_or_sip": 1, "conf": {"res": 360, "fps": 24}},
        {"max": 9, "room_or_sip": 0, "conf": {"res": 360, "fps": 24}},
        {"max": 16, "room_or_sip": 1, "conf": {"res": 360, "fps": 24}},
        {"max": 16, "room_or_sip": 0, "conf": {"res": 360, "fps": 24}},
        {"max": 25, "room_or_sip": 1, "conf": {"res": 180, "fps": 15}},
        {"max": 25, "room_or_sip": 0, "conf": {"res": 180, "fps": 15}},
    ],

    "floating": {"res": 180, "fps": 15},
    "floating_sip": {"res": 180, "fps": 15}, # 520 弱网新增

    # 缩略图视图或者 PIN，AS
    "pin_as": {"res": 1080, "fps": 0, "min": 630},
    # 缩略图视图或者 PIN，小图
    "pin_small": {"res": 90, "fps": 12},
    "pin_small_sip": {"res": 180, "fps": 15}, # 520 弱网新增

    # 演讲者视图或焦点视频，AS
    "speech_as": {"res": 1080, "fps": 0, "min": 630},
    # 演讲者视图或焦点视频，小图
    "speech_small": {"res": 180, "fps": 15},
    # 演讲者视图或焦点视频，小图 sip/rooms
    "speech_small_sip": {"res": 180, "fps": 15}, # 520 弱网新增

    "share_screen": {"res": 1080, "fps": 0}, # 高端机屏幕不限制
    "share_screen_row": {"res": 90, "fps": 12},
    "share_screen_row_sip": {"res": 180, "fps": 15}, # 520 弱网新增
}

pc_score_mid_end_sub = {
    "stage_guest": pc_high_end_stage_guest_sub,
    "stage_share_guest": pc_high_end_stage_share_guest_sub,
    "grid": [
        {"max": 1, "conf": {"res": 1080, "fps": 24}},
        {"max": 2, "conf": {"res": 720, "fps": 24}},
        {"max": 4, "conf": {"res": 720, "fps": 24}},
        {"max": 9, "room_or_sip": 1, "conf": {"res": 360, "fps": 24}},
        {"max": 9, "room_or_sip": 0, "conf": {"res": 360, "fps": 24}},
        {"max": 16, "room_or_sip": 1, "conf": {"res": 360, "fps": 24}},
        {"max": 16, "room_or_sip": 0, "conf": {"res": 360, "fps": 24}},
        {"max": 25, "room_or_sip": 1, "conf": {"res": 180, "fps": 15}},
        {"max": 25, "room_or_sip": 0, "conf": {"res": 180, "fps": 15}},
    ],

    "floating": {"res": 180, "fps": 15},
    "floating_sip": {"res": 180, "fps": 15}, # 520 弱网新增

    # 缩略图视图或者 PIN，AS
    "pin_as": {"res": 1080, "fps": 0, "min": 630},
    # 缩略图视图或者 PIN，小图
    "pin_small": {"res": 90, "fps": 12},
    "pin_small_sip": {"res": 90, "fps": 12}, # 520 弱网新增

    # 演讲者视图或焦点视频，AS
    "speech_as": {"res": 1080, "fps": 0, "min": 630},
    # 演讲者视图或焦点视频，小图
    "speech_small": {"res": 180, "fps": 15},
    # 演讲者视图或焦点视频，小图 sip/rooms
    "speech_small_sip": {"res": 180, "fps": 15}, # 520 弱网新增

    "share_screen": {"res": 1080, "fps": 0},# 中端机屏幕不限制
    "share_screen_row": {"res": 90, "fps": 12},
    "share_screen_row_sip": {"res": 180, "fps": 15}, # 520 弱网新增
}

pc_score_low_end_sub = {
    "stage_guest": pc_low_end_stage_guest_sub,
    "stage_share_guest": pc_low_end_stage_share_guest_sub,
    "grid": [
        {"max": 1, "conf": {"res": 720, "fps": 24}},
        {"max": 2, "conf": {"res": 540, "fps": 24}},
        {"max": 4, "conf": {"res": 360, "fps": 24}},
        {"max": 16, "room_or_sip": 1, "conf": {"res": 180, "fps": 15}},
        {"max": 16, "room_or_sip": 0, "conf": {"res": 180, "fps": 15}},
        {"max": 25, "room_or_sip": 1, "conf": {"res": 180, "fps": 15}},
        {"max": 25, "room_or_sip": 0, "conf": {"res": 90, "fps": 12}},
    ],

    "floating": {"res": 180, "fps": 15},
    "floating_sip": {"res": 180, "fps": 15}, # 520 弱网新增

    # 缩略图视图或者 PIN，AS
    "pin_as": {"res": 720, "fps": 0, "min": 630},

    # 缩略图视图或者 PIN，小图
    "pin_small": {"res": 90, "fps": 12},
    "pin_small_sip": {"res": 180, "fps": 15}, # 520 弱网新增

    # 演讲者视图或焦点视频，AS
    "speech_as": {"res": 720, "fps": 0, "min": 630},
    # 演讲者视图或焦点视频，小图
    "speech_small": {"res": 90, "fps": 12},
    # 演讲者视图或焦点视频，小图 sip/rooms
    "speech_small_sip": {"res": 180, "fps": 15}, # 520 弱网新增

    "share_screen": {"res": 1080, "fps": 15},
    "share_screen_row": {"res": 90, "fps": 12},
    "share_screen_row_sip": {"res": 180, "fps": 15}, # 520 弱网新增
}

pc_score_ultra_low_end_sub = {
    "stage_guest": pc_low_end_stage_guest_sub,
    "stage_share_guest": pc_low_end_stage_share_guest_sub,
    "grid": [
        {"max": 1, "conf": {"res": 540, "fps": 24}},
        {"max": 2, "conf": {"res": 360, "fps": 24}},
        {"max": 4, "conf": {"res": 360, "fps": 24}},
        {"max": 6, "conf": {"res": 180, "fps": 15}},
        {"max": 9, "conf": {"res": 180, "fps": 15}}
    ],

    "floating": {"res": 180, "fps": 15},
    "floating_sip": {"res": 180, "fps": 15}, # 520 弱网新增

    # 缩略图视图或者 PIN，AS
    "pin_as": {"res": 540, "fps": 0, "min": 480},

    # 缩略图视图或者 PIN，小图
    "pin_small": {"res": 90, "fps": 12},
    "pin_small_sip": {"res": 180, "fps": 15}, # 520 弱网新增

    # 演讲者视图或焦点视频，AS
    "speech_as": {"res": 540, "fps": 0, "min": 480},
    # 演讲者视图或焦点视频，小图
    "speech_small": {"res": 90, "fps": 12},
    # 演讲者视图或焦点视频，小图 sip/rooms
    "speech_small_sip": {"res": 180, "fps": 15}, # 520 弱网新增

    "share_screen": {"res": 1080, "fps": 15},
    "share_screen_row": {"res": 90, "fps": 12},
    "share_screen_row_sip": {"res": 180, "fps": 15}, # 520 弱网新增
}

#特效
pc_score_high_mid_end_effect_fps = {
    # 开启虚拟背景时的帧率上限
    "virtual_background_fps": 20, 
    # 开启虚拟形象时的帧率上限
    "animoji_fps": 20,
    # 开启滤镜时的帧率上限
    "filter_fps": 20,
    # 开启美颜时的帧率上限
    "beauty_fps": 20,
    # 同时开启滤镜&美颜时的帧率上限
    "mix_filter_beauty_fps": 20,
    # 其他组合情况时的帧率上限
    "mix_other_fps": 15
}

pc_score_low_end_effect_fps = {
    # 开启虚拟背景时的帧率上限
    "virtual_background_fps": 15, 
    # 开启虚拟形象时的帧率上限
    "animoji_fps": 15,
    # 开启滤镜时的帧率上限
    "filter_fps": 15,
    # 开启美颜时的帧率上限
    "beauty_fps": 15,
    # 同时开启滤镜&美颜时的帧率上限
    "mix_filter_beauty_fps": 15,
    # 其他组合情况时的帧率上限
    "mix_other_fps": 12
}

pc_score_ultra_low_end_effect_fps = {
    # 开启虚拟背景时的帧率上限
    "virtual_background_fps": 12, 
    # 开启虚拟形象时的帧率上限
    "animoji_fps": 12,
    # 开启滤镜时的帧率上限
    "filter_fps": 12,
    # 开启美颜时的帧率上限
    "beauty_fps": 12,
    # 同时开启滤镜&美颜时的帧率上限
    "mix_filter_beauty_fps": 12,
    # 其他组合情况时的帧率上限
    "mix_other_fps": 12
}

pc_score_high_end = {
    "rule": {},
    "publish": pc_score_high_end_pub,
    "subscribe": pc_score_high_end_sub,
    "effect_fps": pc_score_high_mid_end_effect_fps
}
pc_score_mid_end = {
    "rule": {},
    "publish": pc_score_mid_end_pub,
    "subscribe": pc_score_mid_end_sub,
    "effect_fps": pc_score_high_mid_end_effect_fps
}
pc_score_low_end = {
    "rule": {},
    "publish": pc_score_low_end_pub,
    "subscribe": pc_score_low_end_sub,
    "effect_fps": pc_score_low_end_effect_fps
}
pc_score_ultra_low_end = {
    "rule": {},
    "publish": pc_score_ultra_low_end_pub,
    "subscribe": pc_score_ultra_low_end_sub,
    "effect_fps": pc_score_ultra_low_end_effect_fps
}  
#pc 6.1 静态配置策略定义结束

if version_code >= 6001000:
    #6.1 使用4挡
    pc_res_config = {
        "super_high_end": pc_super_high_end,
        "configs": [
            pc_score_high_end,
            pc_score_mid_end,
            pc_score_low_end,
            pc_score_ultra_low_end
        ],
        "view_size_debounce" : pc_view_debounce_time,
        "simulcast_deprecate": pc_sub_720_360_180_180
    }
else:
    pc_res_config = {
        "super_high_end": pc_super_high_end,
        "configs": [
            pc_super_high_end,
            pc_high_end,
            pc_low_end,
        ],
        "view_size_debounce" : pc_view_debounce_time,
        "simulcast_deprecate": pc_sub_720_360_180_180
    }

# ab test
if (device_platform == "mac" or device_platform == "windows" or device_platform == "linux") and (not enable_abtest(device_id)) and version_code >= 6001000:
    pc_res_config["configs"][3] = pc_low_end

def main():
  if device_platform == "iphone" or device_platform == "ipad":
    if cur_device_score >= ios_high_score:
      return mobile_high_end
    elif cur_device_score >= ios_mid_score:
      return mobile_mid_end
    else:
      return mobile_low_end

  if device_platform == "android":
    if cur_device_score >= android_high_score:
      return mobile_high_end
    elif cur_device_score >= android_mid_score:
      return mobile_mid_end
    elif cur_device_score >= android_low_score:
      return mobile_low_end
    elif cur_device_score > 0:
      return mobile_super_low_end  
    else:
      return mobile_mid_end

  if device_platform == "mac" or device_platform == "windows" or device_platform == "linux":
    return pc_res_config
  return {}


res = main()

# 订阅视图优化
res["view_size_scale"] = 1.049

is_pc = device_platform == "mac" or device_platform == "windows" or device_platform == "linux"
if is_pc and version_code >= 6001000 and user_in_lark_suite:
    res["view_size_scale"] = 1.263

if True:
  if version_code >= 5020000:
    # 灰度弱网基线查找表
    if device_platform == "iphone" or device_platform == "ipad" or device_platform == "android":
      fill_weak_network(res["phone"]["subscribe"], weak_network_mobile)
      fill_weak_network(res["pad"]["subscribe"], weak_network_pad)
      fill_weak_network(res["simulcast_deprecate"]["phone"], weak_network_mobile)
      fill_weak_network(res["simulcast_deprecate"]["pad"], weak_network_pad)
    elif device_platform == "mac" or device_platform == "windows" or device_platform == "linux":
      for item in res["configs"]:
        fill_weak_network(item["subscribe"], weak_network_pc)
      fill_weak_network(res["super_high_end"]["subscribe"], weak_network_pc)
      fill_weak_network(res["simulcast_deprecate"], weak_network_pc)


if ((device_platform == "iphone" or device_platform == "ipad") and (cur_device_score >= ios_mid_score)) or (device_platform == "android" and cur_device_score >= android_mid_score):
  # 对高中端机订阅帧率参数先设置为 0，对端发多少就接收多少
  reset_fps_to_0(res["phone"]["subscribe"])
  reset_fps_to_0(res["pad"]["subscribe"])
  reset_fps_to_0(res["simulcast_deprecate"]["phone"])
  reset_fps_to_0(res["simulcast_deprecate"]["pad"])

return res
