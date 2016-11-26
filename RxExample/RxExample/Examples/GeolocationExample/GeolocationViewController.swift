//
//  GeolocationViewController.swift
//  RxExample
//
//  Created by Carlos García on 19/01/16.
//  Copyright © 2016 Krunoslav Zaher. All rights reserved.
//

import UIKit
import CoreLocation
#if !RX_NO_MODULE
    import RxSwift
    import RxCocoa
#endif

private extension Reactive where Base: UILabel {
    var coordinates: UIBindingObserver<Base, CLLocationCoordinate2D> {
        return UIBindingObserver(UIElement: base) { label, location in
            label.text = "Lat: \(location.latitude)\nLon: \(location.longitude)"
        }
    }
}

private extension Reactive where Base: UIView {
    func subviewPresence(_ subview: UIView) -> UIBindingObserver<Base, Bool> {
        return UIBindingObserver(UIElement: base) { view, show in
            if !show {
                subview.removeFromSuperview()
            }
            else {
                view.addSubview(subview)
            }
        }
    }
}

class GeolocationViewController: ViewController {
    
    @IBOutlet weak private var noGeolocationView: UIView!
    @IBOutlet weak private var button: UIButton!
    @IBOutlet weak private var button2: UIButton!
    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let geolocationService = GeolocationService.instance
        
        geolocationService.authorized
            .map(!)
            .drive(view.rx.subviewPresence(noGeolocationView))
            .addDisposableTo(disposeBag)
        
        geolocationService.location
            .drive(label.rx.coordinates)
            .addDisposableTo(disposeBag)
        
        button.rx.tap
            .bindNext { [weak self] in
                self?.openAppPreferences()
            }
            .addDisposableTo(disposeBag)
        
        button2.rx.tap
            .bindNext { [weak self] in
                self?.openAppPreferences()
            }
            .addDisposableTo(disposeBag)
    }
    
    private func openAppPreferences() {
        UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
    }
    
}
