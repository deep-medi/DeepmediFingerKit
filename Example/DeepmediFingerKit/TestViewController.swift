//
//  TestViewController.swift
//  DeepmediFingerKit_Example
//
//  Created by 딥메디 on 2023/04/26.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit

class TestViewController : UIViewController {
    
    let startButton = UIButton().then { b in
        b.setTitle("Start", for: .normal)
        b.setTitleColor(.black, for: .normal)
        b.backgroundColor = .white
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    @objc func start() {
        let vc = ViewController()
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: false)
    }
    
    func setupUI() {
        let width = UIScreen.main.bounds.width * 0.8,
            height = UIScreen.main.bounds.height * 0.8

        self.view.addSubview(startButton)

        startButton.snp.makeConstraints { make in
            make.width.height.equalTo(width * 0.3)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-80)
        }

        startButton.layer.cornerRadius = (width * 0.3) / 2
        startButton.addTarget(
            self,
            action: #selector(start),
            for: .touchUpInside
        )
    }
}
