//
//  Document.swift
//  DeepmediFingerKit
//
//  Created by 딥메디 on 2023/04/03.
//

import Foundation
import UIKit

public class Document {
    private let fileManager = FileManager()
    private let dataModel = DataModel.shared
    
    // MARK: 측정데이터 파일생성
    func madeMeasureData(
        data type: DataModel.DataType
    ) {
        
        let docuURL = self.fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        var fileURL: URL
        
        switch type {
            
        case .rgb:
            fileURL = docuURL.appendingPathComponent("PPG_DATA_ios.txt")
            self.dataModel.rgbDataPath = fileURL
        case .acc:
            fileURL = docuURL.appendingPathComponent("ACC_DATA_ios.txt")
            self.dataModel.accDataPath = fileURL
        case .gyro:
            fileURL = docuURL.appendingPathComponent("GYRO_DATA_ios.txt")
            self.dataModel.gyroDataPath = fileURL
        }
        
        self.transrateDataToTxtFile(fileURL, data: type)
    }
    
    private func transrateDataToTxtFile(
        _ file: URL,
        data type: DataModel.DataType
    ) {
        var data: [(Double, Float, Float, Float)],
            dataToArr: [String],
            dataSubStr: String
        
        switch type {
            
        case .rgb:
            data = self.dataModel.rgbData
            dataToArr = self.dataModel.rgbDataToArr
            dataSubStr = self.dataModel.rgbSubStr
            
        case .acc:
            data = self.dataModel.accData
            dataToArr = self.dataModel.accDataToArr
            dataSubStr = self.dataModel.accSubStr
            
        case .gyro:
            data = self.dataModel.gyroData
            dataToArr = self.dataModel.gyroDataToArr
            dataSubStr = self.dataModel.gyroSubStr
        }
        
        data.forEach { dataMass in
            dataToArr.append(
                "\(dataMass.0 as Float64)\t"
                + "\(dataMass.1)\t"
                + "\(dataMass.2)\t"
                + "\(dataMass.3)\n"
            )
        }
        
        for i in dataToArr.indices {
            dataSubStr += "\(dataToArr[i])"
        }
        
        try? dataSubStr.write(to: file, atomically: true, encoding: String.Encoding.utf8)
    }
}
