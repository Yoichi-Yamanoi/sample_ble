//
//  ScanViewController.swift
//  BLESample
//
//  Created by Yoichi_Yamanoi on 2020/04/13.
//  Copyright © 2020 Sample. All rights reserved.
//

import UIKit
import CoreBluetooth
import RxSwift
import RxCocoa
import Toast_Swift

struct PeripheralData {
    var peripheral: CBPeripheral
    var rssi: NSNumber
}

class BLEManager: NSObject {
    let scanTime: Double = 5 // seconds
    var centralManager: CBCentralManager?
    var peripherals = BehaviorRelay<[CBPeripheral]>(value: [])
}

extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        NSLog("%@, state: %d", #function, central.state.rawValue)
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
//        if peripherals.value.filter({ $0 == peripheral }).isEmpty {
//            peripherals.value.append(peripheral)
//        }
    }
}

/// スマホ(Central)とBLE受信器(Peripheral)を接続させる
class ScanViewController: UIViewController {
    let disposeBag = DisposeBag()

    @IBOutlet weak var tableView: UITableView!

    let scanTime: Double = 5 // seconds
    var centralManager: CBCentralManager?
    fileprivate var peripherals = BehaviorRelay<[CBPeripheral]>(value: [])

    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(scan), for: .valueChanged)
        return refreshControl
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "BLEスキャン"
        centralManager = CBCentralManager(delegate: self, queue: nil)

        peripherals.asObservable()
            .bind(to: tableView.rx.items(cellIdentifier: "Cell")) { (_, item: CBPeripheral, cell) in
                cell.textLabel?.text = (item.name ?? "No name") + "\(item.state.rawValue)"
                cell.detailTextLabel?.text = item.identifier.uuidString                
            }
            .disposed(by: disposeBag)

        tableView.addSubview(refreshControl)
        tableView.rx
            .modelSelected(CBPeripheral.self)
            .subscribe(onNext: { (peripheral) in
                self.performSegue(withIdentifier: "scanCentral", sender: peripheral.identifier)
            })
            .disposed(by: disposeBag)
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        /// Clear old peripherals
        peripherals.accept([])

        /// Start scan
        refreshControl.beginRefreshing()
        tableView.setContentOffset(
            CGPoint(x: 0, y: tableView.contentOffset.y - refreshControl.frame.height), animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.refreshControl.sendActions(for: .valueChanged)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard let manager = centralManager else { return }
        if manager.isScanning {
            view.makeToast("BLEスキャン終了")
            manager.stopScan()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @objc func scan() {
        guard let manager = centralManager else { return }
        if !manager.isScanning {
            view.makeToast("BLEスキャン開始")
            
            manager.scanForPeripherals(withServices: nil, options: nil)

            DispatchQueue.main.asyncAfter(deadline: .now() + scanTime) { [weak self] in
                self?.view.makeToast("BLEスキャン終了")
                manager.stopScan()
                self?.refreshControl.endRefreshing()
            }
        } else {
            refreshControl.endRefreshing()
        }
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination as? SmartphoneViewController != nil,
            let uuid = sender as? UUID {            
            UserDefaults.setValue(uuid.uuidString, forKey: .bleReceiverId)
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension ScanViewController: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        NSLog("%@, state: %d", #function, central.state.rawValue)
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
//        if let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String, name.lowercased().contains("ble") {
            if peripherals.value.filter({ $0 == peripheral }).isEmpty {
                var array = peripherals.value
                array.append(peripheral)
                peripherals.accept(array)
            }
//        }
    }
}
