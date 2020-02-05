//
//  CCWColor.swift
//  VB
//
//  Created by AlienLi on 2018/12/1.
//  Copyright © 2018 MarcoLi. All rights reserved.
//

import UIKit

// MARK: - 颜色扩展
extension UIColor {
    static var ccw: CCWColorDSL {
        return CCWColorDSL.init()
    }
}

class CCWColorDSL {
    func hex(_ hex: Int, alpha: CGFloat = 1.0) -> UIColor {
        return UIColor.init(hex: hex, alpha: alpha)
    }

    func hexString(_ hexStr: String, alpha: CGFloat = 1.0) -> UIColor {
        return UIColor.init(hexNSString: hexStr, alpha: alpha)
    }
}
