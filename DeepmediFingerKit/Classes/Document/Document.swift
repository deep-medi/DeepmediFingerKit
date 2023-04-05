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
    func madeMeasureData() {
        
        let docuURL = self.fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = docuURL.appendingPathComponent("PPG_DATA_ios.txt")
        
        self.dataModel.rgbDataPath = fileURL
        self.transrateDataToTxtFile(fileURL)
    }
    
    private func transrateDataToTxtFile(
        _ file: URL
    ) {
        self.dataModel.rgbDatas.forEach { dataMass in
            self.dataModel.rgbDataToArr.append(
                "\(dataMass.0 as Float64)\t"
                + "\(dataMass.1)\t"
                + "\(dataMass.2)\t"
                + "\(dataMass.3)\n"
            )
        }
        
        for i in self.dataModel.rgbDataToArr.indices {
            self.dataModel.rgbSubStr += "\(self.dataModel.rgbDataToArr[i])"
        }
        
        try? self.dataModel.rgbSubStr.write(to: file, atomically: true, encoding: String.Encoding.utf8)
    }
}
