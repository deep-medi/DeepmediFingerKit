//
//  Extension.swift
//  DeepmediFingerKit
//
//  Created by 딥메디 on 2023/04/03.
//

extension UIDevice {
    var identifier: String {
        var sysinfo = utsname()
        uname(&sysinfo)
        let data = Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN))
        let identifier = String(bytes: data, encoding: .ascii)!
        return identifier.trimmingCharacters(in: .controlCharacters)
    }
    
    var modelName: String {
        return modelNameMappingList[identifier] ?? "Unknown"
    }
    
    private var modelNameMappingList: [String: String] {
        return [
            /***************************************************
             iPhone
             ***************************************************/
            "iPhone8,4" : "iPhone SE (GSM)",
            "iPhone9,1" : "iPhone 7",
            "iPhone9,2" : "iPhone 7 Plus",
            "iPhone9,3" : "iPhone 7",
            "iPhone9,4" : "iPhone 7 Plus",
            "iPhone10,1" : "iPhone 8",
            "iPhone10,2" : "iPhone 8 Plus",
            "iPhone10,3" : "iPhone X Global",
            "iPhone10,4" : "iPhone 8",
            "iPhone10,5" : "iPhone 8 Plus",
            "iPhone10,6" : "iPhone X GSM",
            "iPhone11,2" : "iPhone XS",
            "iPhone11,4" : "iPhone XS Max",
            "iPhone11,6" : "iPhone XS Max Global",
            "iPhone11,8" : "iPhone XR",
            "iPhone12,1" : "iPhone 11",
            "iPhone12,3" : "iPhone 11 Pro",
            "iPhone12,5" : "iPhone 11 Pro Max",
            "iPhone12,8" : "iPhone SE 2nd Gen",
            "iPhone13,1" : "iPhone 12 Mini",
            "iPhone13,2" : "iPhone 12",
            "iPhone13,3" : "iPhone 12 Pro",
            "iPhone13,4" : "iPhone 12 Pro Max",
            "iPhone14,2" : "iPhone 13 Pro",
            "iPhone14,3" : "iPhone 13 Pro Max",
            "iPhone14,4" : "iPhone 13 Mini",
            "iPhone14,5" : "iPhone 13",
            "iPhone14,6" : "iPhone SE 3rd Gen",
            "iPhone14,7" : "iPhone 14",
            "iPhone14,8" : "iPhone 14 Plus",
            "iPhone15,2" : "iPhone 14 Pro",
            "iPhone15,3" : "iPhone 14 Pro Max",
            "iPad11,1" : "iPad mini 5th Gen (WiFi)",
            "iPad14,1" : "iPad mini 6th Gen (WiFi)",
            "iPad13,4" : "iPad Pro 11 inch 5th Gen",
            "iPad13,5" : "iPad Pro 11 inch 5th Gen",
            "iPad13,6" : "iPad Pro 11 inch 5th Gen",
            "iPad13,7" : "iPad Pro 11 inch 5th Gen",
        ]
    }
}
