import json

# 优先判断 device_map 中是否存在对应 model 的配置
# 然后使用 rules range 匹配

device_platform = "ipad"
device_model = "iPad11,1"
version_code = 4004000


ios_conf = {
  "rules": [
    # iPhone5s ~ iPhoneX
    {
      "device_type": "iPhone",
      "range": [
        {"major": 1, "minor": 1},
        {"major": 10, "minor": 99}
      ],
      "resolution": {"floating": 240, "full": 480, "half": 480, "quater": 240}
    },
    # iPhoneXs ~ ...
    {
      "device_type": "iPhone",
      "range": [
        {"major": 11, "minor": 1},
        {"major": 99, "minor": 99}
      ],
      "resolution": {"floating": 240, "full": 720, "half": 480, "quater": 240}
    },

    # iPad 1:  2010
    # iPad 2:  2011 - 2012
    # iPad 3:  2012 - 2013
    # iPad 4:  2013 - 2014
    # iPad 5:  2014 - 2015
    # iPad 6:  2015 - 2017
    # iPad 7:  2017 - 2019
    # iPad 8:  2018 - 2020
    # iPad 11: 2019

    {
      "device_type": "iPad",
      "range": [
        {"major": 1, "minor": 1},
        {"major": 6, "minor": 99}
      ],
      "resolution": {"floating": 240, "full": 480, "half": 480, "quater": 240}
    },
    {
      "device_type": "iPad",
      "range": [
        {"major": 7, "minor": 1},
        {"major": 99, "minor": 99}
      ],
      "regular_resolution": {"floating": 240, "full": 720, "half": 480, "quater": 240},
      "compact_resolution": {"floating": 240, "full": 480, "half": 480, "quater": 240}
    }
  ],
  "device_map": {
    # iPhoneSE 2
    "iPhone13,1": {
      "regular_resolution": { "floating": 240, "full": 480, "half": 480, "quater": 240 },
      "compact_resolution": { "floating": 240, "full": 480, "half": 480, "quater": 240 }
    },
    # iPhone12 Mini
    "iPhone12,8": {
      "resolution": { "floating": 240, "full": 480, "half": 480, "quater": 240 }
    }
  }
}

# 高性能 iPhone (>= iPhoneXs)
# 高性能 iPad regular (>= iPad7)
cfg_720_480_240_240 = {
    "full": { "resolution": 720, "fps": 30 },
    "half": { "resolution": 480, "fps": 30 },
    "quater": { "resolution": 240, "fps": 15 },
    "floating": { "resolution": 240, "fps": 15 },
}

# 中低性能 iPhone (<= iPhoneX)
# 高性能 iPad compact
# 低性能 iPad regular & compact
cfg_480_480_240_240 = {
    "full": { "resolution": 480, "fps": 30 },
    "half": { "resolution": 480, "fps": 15 },
    "quater": { "resolution": 240, "fps": 15 },
    "floating": { "resolution": 240, "fps": 15 },
}


ios_perf_conf = {
  "rules": [
    # iPhone5s ~ iPhoneX
    {
      "device_type": "iPhone",
      "range": [
        {"major": 1, "minor": 1},
        {"major": 10, "minor": 99}
      ],
      "resolution": cfg_480_480_240_240,
    },
    # iPhoneXs ~ ...
    {
      "device_type": "iPhone",
      "range": [
        {"major": 11, "minor": 1},
        {"major": 99, "minor": 99}
      ],
      "resolution": cfg_720_480_240_240
    },

    # iPad 1:  2010
    # iPad 2:  2011 - 2012
    # iPad 3:  2012 - 2013
    # iPad 4:  2013 - 2014
    # iPad 5:  2014 - 2015
    # iPad 6:  2015 - 2017
    # iPad 7:  2017 - 2019
    # iPad 8:  2018 - 2020
    # iPad 11: 2019

    {
      "device_type": "iPad",
      "range": [
        {"major": 1, "minor": 1},
        {"major": 6, "minor": 99}
      ],
      "resolution": cfg_480_480_240_240,
    },
    {
      "device_type": "iPad",
      "range": [
        {"major": 7, "minor": 1},
        {"major": 99, "minor": 99}
      ],
      "regular_resolution": cfg_720_480_240_240,
      "compact_resolution": cfg_480_480_240_240
    }
  ],
  "device_map": {
    # iPhoneSE 2
    "iPhone13,1": {
      "regular_resolution": cfg_480_480_240_240,
      "compact_resolution": cfg_480_480_240_240
    },
    # iPhone12 Mini
    "iPhone12,8": {
      "resolution": cfg_480_480_240_240
    }
  }
}

def parse_device_model(modelstr):
    # type: (str) -> Tuple[str, int, int]
    if modelstr.startswith("iPhone"):
        versionstr = modelstr[5:]
        device_type = "iPhone"
    elif modelstr.startswith("iPad"):
        versionstr = modelstr[4:]
        device_type = "iPad"
    else:
        return None
    versions = versionstr.split(",")
    if len(versions) != 2:
        return None
    try:
        major = int(versions[0])
        minor = int(versions[1])
    except:
        return None
    return device_type, major, minor

def compare_version_less(lhs, rhs):
    # type: (Tuple[int, int], Tuple[int, int]) -> bool
    if lhs[0] != rhs[0]:
        return lhs[0] < rhs[0]
    return lhs[1] < rhs[1]

def compare_version_lesseq(lhs, rhs):
    # type: (Tuple[int, int], Tuple[int, int]) -> bool
    return not compare_version_less(rhs, lhs)


def resolution_from_rule(rule):
    r_res = rule.get("regular_resolution")
    c_res = rule.get("compact_resolution")
    if r_res and c_res:
        return {
                "regular_resolution": r_res,
                "compact_resolution": c_res,
                }
    res = rule.get("resolution")
    return res

def get_resolution(device_model):
    specified_resolution = ios_perf_conf["device_map"].get(device_model)
    if specified_resolution:
        return specified_resolution

    result = parse_device_model(device_model)
    if not result:
        return cfg_480_480_240_240

    device_type, major, minor = result
    rules = ios_perf_conf["rules"]
    for rule in rules:
        rule_device = rule["device_type"]
        rule_min_major = rule["range"][0]["major"]
        rule_min_minor = rule["range"][0]["minor"]
        rule_max_major = rule["range"][1]["major"]
        rule_max_minor = rule["range"][1]["minor"]
        if (
                device_type == rule_device
                and compare_version_lesseq((rule_min_major, rule_min_minor), (major, minor))
                and compare_version_lesseq((major, minor), (rule_max_major, rule_max_minor))
            ):
            return resolution_from_rule(rule)

    return cfg_480_480_240_240


# SettingsV3 暂时不支持 DeviceModel 变量
def config_entry(device_platform, version_code):
    if (device_platform == "iphone" or device_platform == "ipad") and version_code >= 4004000:
        return ios_perf_conf
    elif (device_platform == "iphone" or device_platform == "ipad") and version_code >= 4003000:
        return ios_conf
    else:
        return None


if __name__ == "__main__":
    print(json.dumps(ios_perf_conf, indent=2))
    test_cases = [
            ("ipad", "iPad11,1", 4003000),
            ("ipad", "iPadxxx", 4004000),
            ]
    for test_case in test_cases:
        resolution = config_entry(*test_case)
        jstr = json.dumps(resolution, indent=2)
        print(jstr)
