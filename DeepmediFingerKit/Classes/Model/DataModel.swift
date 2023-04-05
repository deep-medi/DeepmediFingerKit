//
//  RGB.swift
//  DeepmediFingerKit
//
//  Created by 딥메디 on 2023/04/03.
//

import UIKit

class DataModel {
    enum RGB {
        case R, G, B
    }
    
    static let shared = DataModel()
    
    var rgbDataPath: URL?
    var gTempData = [Float]()
    var timeStamp = [Double](),
        rData = [Float](),
        gData = [Float](),
        bData = [Float]()
        
    var rgbDatas = [(Double(),Float(),Float(),Float())]
    var rgbDataToArr = [String]()
    var rgbSubStr = String()
    
    func initRGBData() {
        self.rData.removeAll()
        self.gData.removeAll()
        self.bData.removeAll()
        self.timeStamp.removeAll()
        
        self.rgbDatas.removeAll()
        self.rgbDataToArr.removeAll()
        self.rgbSubStr.removeAll()
    }
    
    // MARK: RGB값 수집
    func collectRGB(
        timeStamp: Double,
        r: Float,
        g: Float,
        b: Float
    ) {
        let dataFormat = (timeStamp, r, g, b)
        self.gTempData.append(g)
        self.rData.append(r)
        self.gData.append(g)
        self.bData.append(b)
        self.timeStamp.append(timeStamp)
        self.rgbDatas.append(dataFormat)
    }
}

