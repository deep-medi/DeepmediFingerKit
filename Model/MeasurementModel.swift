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
        inputPercentage = BehaviorSubject(value: 0.0),
        inputFilteringGvalue = PublishSubject<Double>()
    
    let inputDeviceForward = PublishSubject<Bool>(),
        inputDeviceBack = PublishSubject<Bool>(),
        inputTap = PublishSubject<Bool>()
    
    //output
    let outputFingerStatus = PublishSubject<MeasurementViewModel.status>(),
        outputDeviceStatus = PublishSubject<MeasurementViewModel.status>(),
    
    let secondRemaining = PublishSubject<Double>()
    let measurementCompleteRatio = PublishSubject<String>()
    
    //bind
    func bindFingerTap() {
        _ = Observable
            .combineLatest(self.inputAccZforward,
                           self.inputAccZback,
                           self.inputFingerTap)
            .observe(on: MainScheduler.instance)
            .asObservable()
            .map { self.measurePossible(forward: $0,
                                        back: $1,
                                        tap: $2) }
            .bind(to: self.outputFingerStatus)
    }
    
    func bindDevicePosition() {
        _ = Observable
            .combineLatest(self.inputDeviceForward,
                           self.inputDeviceBack,
                           self.inputTap)
            .observe(on: MainScheduler.instance)
            .asObservable()
            .map { self.measurePossible(forward: $0,
                                        back: $1,
                                        tap: $2) }
            .bind(to: self.outputDeviceStatus)
    }
    
    func measurePossible(
        forward: Bool,
        back: Bool,
        tap: Bool
    ) -> MeasurementViewModel.status {
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
}

