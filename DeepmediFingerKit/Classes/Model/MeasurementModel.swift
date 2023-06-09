//
//  MeasurementModel.swift
//  DeepmediFingerKit
//
//  Created by 딥메디 on 2023/04/03.
//

import Foundation
import RxSwift

class MeasurementModel {
    public enum status {
        case flip, back, noTap, tap
    }
    
    //input
    let inputAccZforward = PublishSubject<Bool>(),
        inputAccZback = PublishSubject<Bool>(),
        inputFingerTap = PublishSubject<Bool>(),
        inputFilteringGvalue = PublishSubject<Double>()
    
    //output
    let outputFingerStatus = PublishSubject<MeasurementModel.status>()
    let secondRemaining = PublishSubject<Int>()
    let measurementCompleteRatio = PublishSubject<String>()
    let measurementComplete = BehaviorSubject(value: (false, URL(string: ""), URL(string: ""), URL(string: "")))
    let measurementStop = PublishSubject<Bool>()
    
    var stoppedByNotTap = false
    var stoppedByFlipingDevice = false
    
    //bind
    func bindFingerTap() {
        _ = Observable
            .combineLatest(self.inputAccZforward,
                           self.inputAccZback,
                           self.inputFingerTap)
            .observe(on: MainScheduler.instance)
            .asObservable()
            .map {
                self.measurePossible(
                    forward: $0,
                    back: $1,
                    tap: $2
                )
            }
            .bind(to: self.outputFingerStatus)
    }
    
    func measurePossible(
        forward: Bool,
        back: Bool,
        tap: Bool
    ) -> MeasurementModel.status {
        var result = status.noTap
        if forward, !back, tap {
            result = .tap
        } else if forward, !back, !tap {
            result = .noTap
        } else if !forward, back, tap {
            result = .back
        } else if !forward, back, !tap {
            result = .flip
        }
        return result
    }
    
    func checkStopStatus(
        _ status: MeasurementModel.status
    ) {        
        switch status {
        case .tap:
            self.stoppedByNotTap = false
            self.stoppedByFlipingDevice = false
        case .noTap:
            self.stoppedByNotTap = true
            self.stoppedByFlipingDevice = false
        default:
            self.stoppedByNotTap = false
            self.stoppedByFlipingDevice = true
        }
        
    }
}

