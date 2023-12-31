require_relative '.orbit_enable_user'

def current_user_in_white_list
    if is_force_orbit_use
        puts "用户在强制lint xcode版本名单中，开启remote cache"
        return true 
    end
    
    remote_cache_enable_users = [
        'dongwei.1615@bytedance.com',
        'aslan.hu@bytedance.com',
        'huoyunjie@bytedance.com',
        'zhaodong.23@bytedance.com',
        'liyong.520@bytedance.com',
        #'xiexufeng@bytedance.com',
        'lizijie.lizj@bytedance.com',
        'sunyihe@bytedance.com',
        'goupengyu@bytedance.com',
        'wuwenjian.weston@bytedance.com',
        'wangwanxin.sam@bytedance.com',
        'guochengwang@bytedance.com',
        'supeng.charlie@bytedance.com',
        'qihongye@bytedance.com',
        'liuwanlin@bytedance.com',
        'lihaozhe.12@bytedance.com'
    ]

    user_email = `git config user.email`[0...-1]    
    if remote_cache_enable_users.include? user_email
        puts "用户email #{user_email} 在remote cache白名单中，默认开启remote cache"
        return true
    else        
        return false
    end
end
