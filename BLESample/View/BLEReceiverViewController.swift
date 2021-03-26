//
//  BLEReceiverViewController.swift
//  BLESample
//
//  Created by Yoichi_Yamanoi on 2020/04/13.
//  Copyright © 2020 Sample. All rights reserved.
//

import UIKit
import CoreBluetooth
import RxSwift
import RxCocoa

class BLEReceiverViewController: UIViewController {
    let disposeBag = DisposeBag()

    @IBOutlet weak var textField: UITextField?
    @IBOutlet weak var switchButton: UISwitch?
    @IBOutlet weak var logTextView: UITextView!
    @IBOutlet weak var registerKeyControl: UISegmentedControl!
    @IBOutlet weak var openOrCloseControl: UISegmentedControl!
    @IBOutlet weak var dateField: UITextField!

    //UIDatePickerを定義するための変数
    private var datePicker: UIDatePicker = UIDatePicker()
    fileprivate var peripheralManager: CBPeripheralManager?    

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Peripheral（BLE受信器）の設定"
        setDatePicker()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        textField?.text = Constants.BLE.peripheralName
        switchButton?.rx.value
            .bind(onNext: { (active) in
                if active {
                    let bytes: [UInt8] = [0xf, 0xf, 0x8]
                    let manufactureData = Data(bytes: bytes, count: bytes.count)
                    let data: [String: Any] = [
                        CBAdvertisementDataLocalNameKey: "\(Constants.BLE.peripheralName)",
                        CBAdvertisementDataServiceUUIDsKey: [Constants.BLE.serviceUUID],
                        CBAdvertisementDataManufacturerDataKey: manufactureData
                    ]
                    self.peripheralManager?.startAdvertising(data)
                } else {
                    self.peripheralManager?.stopAdvertising()
                }
            })
            .disposed(by: disposeBag)
    }

    func setDatePicker() {
        // ピッカー設定
        datePicker.datePickerMode = .dateAndTime
        datePicker.timeZone =
            TimeZone.current
        datePicker.locale = Locale.current        
        dateField.inputView = datePicker

        // 決定バーの生成
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 35))
        let spacelItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        toolbar.setItems([spacelItem, doneItem], animated: true)

        // インプットビュー設定(紐づいているUITextfieldへ代入)
        dateField.inputView = datePicker
        dateField.inputAccessoryView = toolbar
        // 仮入力
        dateField.text = "00000000000000"
    }

    // UIDatePickerのDoneを押したら発火
    @objc func done() {
        dateField.endEditing(true)
        //datePickerで指定した日付が表示される
        dateField.text = "\(Constants.BLE.dateFormatter.string(from: datePicker.date))"
    }
}

extension BLEReceiverViewController: CBPeripheralManagerDelegate {
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        logTextView.appendLog(text: "Update State: \(peripheral.state)")
        guard peripheral.state == .poweredOn else { return }
        // サービスを登録
        let service = CBMutableService(type: Constants.BLE.serviceUUID, primary: true)
        let charactaristics = Constants.BLE.Characteristic.characteristics
        service.characteristics = charactaristics
//        self.characteristic = Constants.BLE.Characteristic.registerKey.characteristic
        self.peripheralManager?.add(service)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        logTextView.appendLog(text: "Add: \(service.description)")
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            logTextView.appendLog(text: "\(error.localizedDescription)")
        }
        logTextView.appendLog(text: "Start Advertising")
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        logTextView.appendLog(text: "Subscription: \(central.description)")
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        logTextView?.appendLog(text: "Unsubscription")
    }

    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        logTextView?.appendLog(text: "IsReady")
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String : Any]) {
        print(#function, dict)
        logTextView?.appendLog(text: "Restore State: \(dict)")
    }    
    
    /// Writeリクエスト受信時に呼ばれる
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        logTextView?.appendLog(text: "\(requests.count)件のWriteリクエストを受信！")
        logTextView?.appendLog(text: "Receive write: \(requests.description)")
        for request in requests {
            logTextView?.appendLog(text: "Requested value:\(String(describing: request.value)) service uuid:\(request.characteristic.service.uuid) characteristic uuid:\(request.characteristic.uuid)")

            // リクエストに応答
            if Constants.BLE.Characteristic.uuids.contains(request.characteristic.uuid) {
                peripheral.respond(to: request, withResult: .success)
            } else {
                peripheral.respond(to: request, withResult: .invalidHandle)
            }
        }

    }

    /// Readリクエスト受信時に呼ばれる
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        logTextView?.appendLog(text: "Readリクエスト受信！ requested service uuid:\(request.characteristic.service.uuid) characteristic uuid:\(request.characteristic.uuid) value:\(String(describing: request.characteristic.value))")
        // プロパティで保持しているキャラクタリスティックへのReadリクエストかどうかを判定
        guard let characteristic = Constants.BLE.Characteristic(rawValue: request.characteristic.uuid.uuidString.lowercased()) else {
            peripheral.respond(to: request, withResult: .invalidHandle)
            return
        }
        // リクエストに応答
        switch characteristic {
        /// キー登録結果要求
        case .registerKeyResult:
            // CBMutableCharacteristicのvalueをCBATTRequestのvalueにセット
            let selectedIndex = registerKeyControl.selectedSegmentIndex
            if let string = registerKeyControl.titleForSegment(at: selectedIndex) {
                if string.isEmpty {
                    // 何もしない
                } else {
                    let data = string.data(using: .utf8)!
                    request.value = data
                    peripheral.respond(to: request, withResult: .success)
                }
            } else {
                peripheral.respond(to: request, withResult: .invalidHandle)
            }
        /// 施錠/解錠結果要求
        case .openOrCloseResult:
            // CBMutableCharacteristicのvalueをCBATTRequestのvalueにセット
            let selectedIndex = openOrCloseControl.selectedSegmentIndex
            if let string = openOrCloseControl.titleForSegment(at: selectedIndex) {
                if string.isEmpty {
                    // 何もしない
                } else {
                    let data = string.data(using: .utf8)!
                    request.value = data
                    peripheral.respond(to: request, withResult: .success)
                }                
            } else {
                peripheral.respond(to: request, withResult: .invalidHandle)
            }
        /// 新規登録キー確認
        case .confirmNewKey:
            // CBMutableCharacteristicのvalueをCBATTRequestのvalueにセット
            if let string = dateField.text {
                let data = string.data(using: .utf8)!
                request.value = data
                peripheral.respond(to: request, withResult: .success)
            } else {
                peripheral.respond(to: request, withResult: .invalidHandle)
            }
        default:
            peripheral.respond(to: request, withResult: .success)
        }
    }
}

// MARK: - UITextView

extension UITextView {

    func appendLog(text: String) {
        DispatchQueue.main.async {
            let formatter: DateFormatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let now = formatter.string(from: Date())
            self.text = String(format: "%@[%@] %@\n", self.text, now, text)
            self.setContentOffset(CGPoint(x: 0, y: self.contentSize.height - self.bounds.size.height), animated: true)
        }
    }
}
