//
//  HQPickImageStyle.swift
//  HQPickImage
//
//  Created by Qing's on 2017/11/11.
//  Copyright © 2017年 Qing's. All rights reserved.
//

import UIKit

class HQPickImageStyle {
    /// 导航栏颜色
    var narBarColor: UIColor = UIColor.white
    /// 取消按钮的文字描述
    var cancelBtnTitle: String = "取消"
    /// 取消按钮的文字颜色
    var cancelBtnColor: UIColor = UIColor(red: 34 / 255.0, green: 114 / 255.0, blue: 254 / 255.0, alpha: 1.0)
    /// 取消按钮的文字大小
    var cancelBtnFont: UIFont = UIFont.systemFont(ofSize: 16)
    
    /// 最多可选择的照片数量
    var maxSelected: Int = 9
    
    /// 完成按钮的文字颜色
    var completeBtnColor: UIColor = UIColor.white
    /// 完成按钮背景色
    var completeBtnBgColoe: UIColor = UIColor(red: 0x09/255, green: 0xbb/255, blue: 0x07/255, alpha: 1)
}
