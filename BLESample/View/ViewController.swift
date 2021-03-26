//
//  ViewController.swift
//  BLESample
//
//  Created by Yoichi_Yamanoi on 2020/04/13.
//  Copyright © 2020 Sample. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ViewController: UIViewController {
    let disposeBag = DisposeBag()

    @IBOutlet weak var tableView: UITableView!

    struct Item {
        let title: String
        let subtitle: String
        let identifier: Identifier
        
        enum Identifier: String {
            case scan            
            case peripheral            
        }
    }

    let items: [Item] = [
        Item(
            title: "01. Central（受信器）",
            subtitle: "Peripheral（発信器）の検出と取得した加速度の値を表示します",
            identifier: .scan
        ),
        Item(
            title: "02. Peripheral（発信器）",
            subtitle: "Advertisingの開始とCentral（受信器）に加速度の値を送信します",
            identifier: .peripheral
        )
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "機器設定"
        
        // 以前設定した状態にする
        if let bleReceiverId = UserDefaults.getValue(.bleReceiverId) as? String {
            performSegue(withIdentifier: "central", sender: bleReceiverId)
        } else if let deviceMode = UserDefaults.getValue(.deviceMode) as? String {
            performSegue(withIdentifier: deviceMode, sender: nil)
        }
        
        Observable.just(items)
            .bind(to: tableView.rx.items(cellIdentifier: "Cell")) { (_, item: Item, cell) in
                cell.textLabel?.text = item.title
                cell.detailTextLabel?.text = item.subtitle
            }
            .disposed(by: disposeBag)

        tableView.rx
            .modelSelected(Item.self)
            .subscribe(onNext: { [weak self] (item) in
                UserDefaults.setValue(item.identifier.rawValue, forKey: .deviceMode)
                self?.performSegue(withIdentifier: item.identifier.rawValue, sender: nil)
            })
            .disposed(by: disposeBag)
    }
}
