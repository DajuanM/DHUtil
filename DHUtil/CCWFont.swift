//
//  CCWFont.swift
//  VB
//
//  Created by AlienLi on 2018/12/1.
//  Copyright © 2018 MarcoLi. All rights reserved.
//

extension UIFont {
    static var ccw: CCWFontDSL {
        return CCWFontDSL.init()
    }
}

class CCWFontDSL {

    func size(_ size: CGFloat = 14.0) -> UIFont {
        return UIFont.systemFont(ofSize: size)
    }

    func boldSize(_ size: CGFloat = 14.0) -> UIFont {
        return UIFont.boldSystemFont(ofSize: size)
    }
}
