//
//  VBDateFormatter.swift
//  VB
//
//  Created by AlienLi on 2018/10/20.
//  Copyright © 2018 MarcoLi. All rights reserved.
//

import UIKit

class VBDateFormatter: DateFormatter {
    static let shared = VBDateFormatter()
    private override init() {
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func format(_ str: String) -> VBDateFormatter {
        self.dateFormat = str
        return self
    }

    func format(_ dateStr: String?, _ from: String, _ to: String) -> String {
        guard let dateStr = dateStr else {return ""}
        self.dateFormat = from
        guard let date = self.date(from: dateStr) else {return ""}
        self.dateFormat = to
        return self.string(from: date)
    }
}
