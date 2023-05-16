//
//  FingerMeasureKitModel.swift
//  DeepmediFingerKit
//
//  Created by 딥메디 on 2023/04/05.
//

import UIKit

public class FingerMeasureKitModel: NSObject {
    let model = Model.shared

    public func setMeasurementTime(
        _ time: Double?
    ) {
        self.model.measurementTime = time ?? 30.0
    }
    
    public func doMeasurementBreath(
        _ measurement: Bool
    ) {
        self.model.breathMeasurement = measurement
    }
}
