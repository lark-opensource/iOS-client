//  RegularManager.swift
//  Moment
//
//  Created by liluobin on 2021/5/20.
//

import Foundation
import UIKit

final class RegularManager {
    static func linkRegular() -> NSRegularExpression? {
        var reguar: NSRegularExpression?
        do {
            reguar = try NSRegularExpression(pattern: "((http|https|ftp|ftps)://"
                                                + "([A-Za-z0-9_][-[A-Za-z0-9_]~.]{0,30}(:[A-Za-z0-9_][-[A-Za-z0-9_]~.!$*+]{0,50})?@)?"
                                                + "(([-[A-Za-z0-9_]~]){1,30}\\.){1,5}[a-z]{2,15}|(([-[A-Za-z0-9_]~])+\\.){1,5}"
                                                + "(zw|zm|za|yt|ye|xyz|xxx|xin|wtf|ws|work|wf|wang|vu|vn|vip|vi|vg|ve|vc|va|uz|uy|us|um|uk|ug|ua"
                                                + "|tz|tw|tv|tt|tr|tp|top|to|tn|tm|tl|tk|tj|th|tg|tf|td|tc|sz|sy|sx|sv|su|st|ss|sr|so|sn|sm|sl|sk|sj|site|si|shop|sh|sg|se|sd|sc|sb|sa"
                                                + "|rw|ru|rs|ro|red|re|qa|py|pw|pt|ps|pro|pr|pn|pm|pl|pk|ph|pg|pf|pe|pa|org|one|om|nz|nu|nr|np|no|nl|ni|ng|nf|net|ne|nc|name|na"
                                                + "|mz|my|mx|mw|mv|mu|mt|ms|mr|mq|mp|mobi|mo|mn|mm|ml|mk|mil|mh|mg|mf|me|md|mc|ma|ly|lv|lu|ltd|lt|ls|lr|lk|link|li|lc|lb|land|la"
                                                + "|kz|ky|kw|kr|kp|kn|km|kim|ki|kh|kg|ke|jp|jo|jm|it|is|ir|iq|io|int|ink|info|in|im|il|ie|id|hu|ht|hr|hn|hm|hk|help"
                                                + "|gy|gw|gu|gt|gs|group|gr|gp|gov|gn|gm|gl|gi|gh|gf|ge|gd|gb|ga|fr|fo|fm|fk|fj|fi|eu|et|es|er|engineering|eh|eg|ee|edu|ec"
                                                + "|dz|do|dm|dk|dj|de|cz|cy|cx|cw|cv|cu|cr|com|co|cn|cm|club|cloud|cl|ck|ci|ch|cg|cf|cc|ca|bz|by|bw|bv|bt|bs|br|bo|bn|bm|bj|biz|bi"
                                                + "|bh|bg|bf|be|bd|bb|ba|az|ax|aw|au|at|as|ar|aq|ao|an|am|al|ai|ag|af|ae|ad|ac)"
                                                +
                                                ")(:[1-9]\\d{1,4})?(/[-[A-Za-z0-9_].~:\\[\\]@!%$()*+,;=]{1,500})*/?"
                                                + "(\\?([[A-Za-z0-9_]%]{1,100}(=[[A-Za-z0-9_]\\-_.~:/\\[\\]()'*+,;%]{0,1000})?&?)*)?" + "(#([-[A-Za-z0-9_].~:@$()+=&]{0,100}))?", options: [])
        } catch { }
        return reguar
    }
}
