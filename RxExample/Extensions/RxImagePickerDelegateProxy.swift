//
//  RxImagePickerDelegateProxy.swift
//  RxExample
//
//  Created by Segii Shulga on 1/4/16.
//  Copyright © 2016 Krunoslav Zaher. All rights reserved.
//

#if os(iOS)
   
   #if !RX_NO_MODULE
    import RxSwift
    import RxCocoa
#endif
   import UIKit

open class RxImagePickerDelegateProxy<P: UIImagePickerController>
    : RxNavigationControllerDelegateProxy<P>, UIImagePickerControllerDelegate {
    
}

#endif
