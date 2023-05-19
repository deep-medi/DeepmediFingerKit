//
//  RGB.swift
//  DeepmediFingerKit
//
//  Created by 딥메디 on 2023/04/03.
//

import UIKit
import CoreMotion

class DataModel {
    enum RGB {
        case R, G, B
    }
    
    enum DataType {
        case rgb, acc, gyro
    }
    
    static let shared = DataModel()
    
    // MARK: Data Path
    var rgbDataPath: URL?,
        accDataPath: URL?,
        gyroDataPath: URL?
    
    // MARK: RGB
    var rData = [Float](),
        gData = [Float](),
        bData = [Float]()
    
    var gTempData = [Float]()
    
    var rgbData = [(Double(),Float(),Float(),Float())],
        rgbDataToArr = [String](),
        rgbSubStr = String()
    
    // MARK: Accelerometer
    var accXdata = [Float](),
        accYdata = [Float](),
        accZdata = [Float]()
    
    var accData = [(Double(),Float(),Float(),Float())],
        accDataToArr = [String](),
        accSubStr = String()
    
    // MARK: Gyroscope
    var gyroXdata = [Float](),
        gyroYdata = [Float](),
        gyroZdata = [Float]()
    
    var gyroData = [(Double(),Float(),Float(),Float())],
        gyroDataToArr = [String](),
        gyroSubStr = String()
    
    // MARK: Data Init
    func initRGBData() {
        self.rData.removeAll()
        self.gData.removeAll()
        self.gTempData.removeAll()
        self.bData.removeAll()
        
        self.rgbData.removeAll()
        self.rgbDataToArr.removeAll()
        self.rgbSubStr.removeAll()
    }
    
    func initAccData() {
        self.accXdata.removeAll()
        self.accYdata.removeAll()
        self.accZdata.removeAll()
        
        self.accData.removeAll()
        self.accDataToArr.removeAll()
        self.accSubStr.removeAll()
    }
    
    func initGyroData() {
        self.gyroXdata.removeAll()
        self.gyroYdata.removeAll()
        self.gyroZdata.removeAll()
       
        self.gyroData.removeAll()
        self.gyroDataToArr.removeAll()
        self.gyroSubStr.removeAll()
    }
    
    // MARK: RGB값 수집
    func collectRGB(
        r: Float,
        g: Float,
        b: Float
    ) {
        let timeStamp = (Date().timeIntervalSince1970 * 1000000).rounded()
        guard timeStamp > 100 else { return print("rgb timeStamp error") }
        let dataFormat = (timeStamp, r, g, b)
        
        self.gTempData.append(g)
        self.rData.append(r)
        self.gData.append(g)
        self.bData.append(b)
        self.rgbData.append(dataFormat)
    }
    
    func collectAccelemeterData(
        _ acc: CMAccelerometerData?,
        _ err: Error?
    ) -> Float {
        if err != nil {
            print("error")
            return Float()
        } else {
            guard let accMeasureData = acc?.acceleration else {
                print("accelerometer measured data return")
                return Float()
            }
            var x: Float = 0, y: Float = 0, z: Float = 0
            x = Float(accMeasureData.x)
            y = Float(accMeasureData.y)
            z = Float(accMeasureData.z)
            
            let timeStamp = (Date().timeIntervalSince1970 * 1000000).rounded()
            guard timeStamp > 100 else { return z }
            let dataFormat = (timeStamp, x, y, z)
            
            self.accXdata.append(x)
            self.accYdata.append(y)
            self.accZdata.append(z)
            self.accData.append(dataFormat)
            
            return z
        }
    }
    
    func collectGyroscopeData(
        _ gyro: CMGyroData?,
        _ err: Error?
    ) {
        
        if err != nil {
            print("error")
        } else {
            guard let gyroMeasureData = gyro?.rotationRate else {
                print("gyro measured data return")
                return
            }
            var x: Float = 0, y: Float = 0, z: Float = 0
            x = Float(gyroMeasureData.x)
            y = Float(gyroMeasureData.y)
            z = Float(gyroMeasureData.z)
            
            let timeStamp = (Date().timeIntervalSince1970 * 1000000).rounded()
            guard timeStamp > 100 else { return print("gyro timeStamp error") }
            let dataFormat = (timeStamp, x, y, z)
            
            self.gyroXdata.append(x)
            self.gyroYdata.append(y)
            self.gyroZdata.append(z)
            self.gyroData.append(dataFormat)
        }
    }
    
}

