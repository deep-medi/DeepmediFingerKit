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
        useCornerRadius: Bool
    ) {
        self.layer.addSublayer(layer)
        layer.videoGravity = .resizeAspectFill
        layer.frame = frame
        
        guard useCornerRadius else { return }
        layer.cornerRadius = frame.width / 2
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
