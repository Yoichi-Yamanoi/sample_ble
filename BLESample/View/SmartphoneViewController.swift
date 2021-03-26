//
//  SmartphoneViewController.swift
//  BLESample
//
//  Created by Yoichi_Yamanoi on 2020/04/16.
//  Copyright © 2020 Sample. All rights reserved.
//

import UIKit
import CoreBluetooth
import Intents
import Toast_Swift

/// Central(スマートフォン)
final class SmartphoneViewController: UIViewController {    
    @IBOutlet weak var sendButton: UIButton!

    fileprivate var bleReceiverUUID: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Central（スマートフォン）の設定"
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateUUID()
        // 取得したデータを表示する
        if !bleReceiverUUID.isEmpty {
            BLEHelper.shared.connect(identifier: bleReceiverUUID) { [weak self] (bleData) in
                self?.view.makeToast(bleData.message)
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        BLEHelper.shared.cancel()
        UserDefaults.remove(.bleReceiverId)
    }
    
    private func updateUUID() {
        guard let uuid = UserDefaults.getValue(.bleReceiverId) as? String else {
            return
        }
        bleReceiverUUID = uuid       
    }
    
    @IBAction func tapOpenDoor(_ sender: UIButton) {
        BLEHelper.shared.write(command: .openDoor)
    }
    
    @IBAction func tapCloseDoor(_ sender: UIButton) {
        BLEHelper.shared.write(command: .closeDoor)
    }
}
