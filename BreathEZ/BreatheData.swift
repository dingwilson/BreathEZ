//
//  BreatheData.swift
//  BreathEZ
//
//  Created by Wilson Ding on 10/15/16.
//  Copyright © 2016 Wilson Ding. All rights reserved.
//

import Foundation

class BreatheData {
    var date: Date!
    var interval : Double!
    
    init(date: Date, interval: Double) {
        self.date = date
        self.interval = interval
    }
}
