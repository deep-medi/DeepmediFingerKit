//
//  Model.swift
//  DeepmediFingerKit
//
//  Created by 딥메디 on 2023/04/03.
//

import UIKit

class Model {
    static let shared = Model()
    
    var limitTapTime: Int
    var measurementTime: Double
    
    init() {
        self.limitTapTime = 3
        self.measurementTime = 30.0
    }
}
