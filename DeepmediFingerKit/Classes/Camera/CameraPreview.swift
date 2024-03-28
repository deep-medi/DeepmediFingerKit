//
//  CameraPreview.swift
//  DeepmediFingerKit
//
//  Created by 딥메디 on 2023/04/05.
//

import Foundation
import AVKit

public class CameraPreview: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public func setup(
        layer: AVCaptureVideoPreviewLayer,
        frame: CGRect,
        useCornerRadius: Bool? = nil
    ) {
        self.layer.addSublayer(layer)
        layer.videoGravity = .resizeAspectFill
        layer.frame = CGRect(x: 0, y: 0,
                             width: frame.width,
                             height: frame.height)
        
        guard useCornerRadius ?? false else { return }
        layer.cornerRadius = frame.width / 2
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
