//: [<< Previous](@previous) - [Index](Index)

import RxSwift
import XCPlayground

/*:
## Connectable Observable Operators

A Connectable Observable resembles an ordinary Observable, except that it does not begin emitting items when it is subscribed to, but only when its connect() method is called. In this way you can wait for all intended Subscribers to subscribe to the Observable before the Observable begins emitting items.

Specialty Observables that have more precisely-controlled subscription dynamics.
*/

func sampleWithoutConnectableOperators() {

    let int1 = interval(1, MainScheduler.sharedInstance)

    int1
        .subscribe {
            print("first subscription \($0)")
        }

    delay(5) {
        int1
            .subscribe {
                print("second subscription \($0)")
            }
    }

}

//sampleWithoutConnectableOperators()



/*:
### `multicast`

![](https://raw.githubusercontent.com/kzaher/rxswiftcontent/master/MarbleDiagrams/png/publishconnect.png)

[More info in reactive.io website]( http://reactivex.io/documentation/operators/publish.html )
*/
func sampleWithMulticast() {

    let subject1 = PublishSubject<Int64>()

    subject1
        .subscribe {
            print("Subject \($0)")
        }

    let int1 = interval(1, MainScheduler.sharedInstance)
        .multicast(subject1)

    int1
        .subscribe {
            print("first subscription \($0)")
        }

    delay(2) {
        int1.connect()
    }

    delay(4) {
        int1
            .subscribe {
                print("second subscription \($0)")
            }
    }

    delay(6) {
        int1
            .subscribe {
                print("third subscription \($0)")
            }
    }

}

// sampleWithMulticast()


/*:
### `replay`
Ensure that all observers see the same sequence of emitted items, even if they subscribe after the Observable has begun emitting items.

publish = multicast + replay subject

![](https://raw.githubusercontent.com/kzaher/rxswiftcontent/master/MarbleDiagrams/png/replay.png)

[More info in reactive.io website]( http://reactivex.io/documentation/operators/replay.html )
*/
func sampleWithReplayBuffer0() {

    let int1 = interval(1, MainScheduler.sharedInstance)
        .replay(0)

    int1
        .subscribe {
            print("first subscription \($0)")
        }

    delay(2) {
        int1.connect()
    }

    delay(4) {
        int1
            .subscribe {
                print("second subscription \($0)")
            }
    }

    delay(6) {
        int1
            .subscribe {
                print("third subscription \($0)")
            }
    }

}

// sampleWithReplayBuffer0()


func sampleWithReplayBuffer2() {

    print("--- sampleWithReplayBuffer2 ---\n")

    let int1 = interval(1, MainScheduler.sharedInstance)
        .replay(2)

    int1
        .subscribe {
            print("first subscription \($0)")
        }

    delay(2) {
        int1.connect()
    }

    delay(4) {
        int1
            .subscribe {
                print("second subscription \($0)")
            }
    }

    delay(6) {
        int1
            .subscribe {
                print("third subscription \($0)")
            }
    }

}

// sampleWithReplayBuffer2()


/*:
### `publish`
Convert an ordinary Observable into a connectable Observable.

publish = multicast + publish subject

so publish is basically replay(0)

[More info in reactive.io website]( http://reactivex.io/documentation/operators/publish.html )
*/
func sampleWithPublish() {

    let int1 = interval(1, MainScheduler.sharedInstance)
        .publish()

    int1
        .subscribe {
            print("first subscription \($0)")
        }

    delay(2) {
        int1.connect()
    }

    delay(4) {
        int1
            .subscribe {
                print("second subscription \($0)")
            }
    }

    delay(6) {
        int1
            .subscribe {
                print("third subscription \($0)")
            }
    }

}

// sampleWithPublish()

XCPSetExecutionShouldContinueIndefinitely(true)

//: [Index](Index)
