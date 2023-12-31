def is_force_orbit_use
  force_orbit_uses = %w[
    kongkaikai@bytedance.com
    qihongye@bytedance.com
    wangxiaohua@bytedance.com
    zhangwei.wy@bytedance.com
    huanghaoting@bytedance.com
    lihaozhe.12@bytedance.com
    aslan.hu@bytedance.com
    xiaruzhen@bytedance.com
    liyong.520@bytedance.com
    yuanping.0@bytedance.com
    liluobin@bytedance.com
    yaoqihao@bytedance.com
    fengzigeng@bytedance.com
    wangwanxin.sam@bytedance.com
    guhaowei@bytedance.com
    fengkebang@bytedance.com
    zhaoxiangyu.love@bytedance.com
    panzaofeng@bytedance.com
    tanxiaoxian@bytedance.com
    chenlehui.alex@bytedance.com
    yangyao.wildyao@bytedance.com
    chentao.00@bytedance.com
    liurundong.henry@bytedance.com
    huangtao.ht@bytedance.com
    wulv.lvlv@bytedance.com
    chenyizhuo.yizhuoc@bytedance.com
    wangpeiran@bytedance.com
    zhoufeng.ford@bytedance.co
    liujianlong@bytedance.com
    zhangji.vincent@bytedance.com
    dengqiang.001@bytedance.com
    helijian.666@bytedance.com
    lutingting.ltt@bytedance.com
    zhangxin.shin@bytedance.com
    shaoshengjie@bytedance.com
    qujieye@bytedance.com
    hupingwu@bytedance.com
    fangjun.001@bytedance.com
    xiexufeng@bytedance.com
    gucongrong@bytedance.com
    huangjiayun@bytedance.com
    jinjian.au@bytedance.com
    caiweiwei.liam@bytedance.com
    zhaokejie@bytedance.com
    zhuyuankai.0329@bytedance.com
  ]
  user_email = `git config user.email`.strip

  force_orbit_uses.include? user_email
end