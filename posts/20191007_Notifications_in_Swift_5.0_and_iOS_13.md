Today I decided to start learning iOS programming. I've had a great experience with React Native, but some things are just nicer done native. This article covers local notifications, using `UNUserNotificationCenter`. I'm using Swift 5, Xcode 11 and iOS 13.

This article was published on 07/10/2019.

## Setup

Create a new Single Page app! That's it.

## Creating the Interface

This app will use a very simple interface built using the new `SwiftUI`. In `ContentView.swift`, add the following:

```swift
import SwiftUI

struct ContentView: View {
    
    func setNotification() -> Void {
        
    }
    
    var body: some View {
        VStack {
            Text("Notification Demo")
            Button(action: { self.setNotification() }) {
                Text("Set Notification")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
```

This will let us set a notification by pressing a button. Let's move onto the main topic: `UNUserNotificationCenter`. Create a new file, `LocalNotificationManager.swift`, with some boilerplate code:

```swift
struct Notification {
    var id: String
    var title: String
}

class LocalNotificationManager {
    var notifications = [Notification]()
}
```

Now we will build four functions to handle the notification flow. We need to request permission to show notifications, then schedule some notifications.

## Requesting Permission

Add a `requestAuthorization` method. This will request permission to show notifications, and if permission is granted, then schedule any existing notifications the application has created.

```swift
import UserNotifications

struct Notification {
    var id: String
    var title: String
}

class LocalNotificationManager {
    var notifications = [Notification]()
    
    func requestPermission() -> Void {
        UNUserNotificationCenter
            .current()
            .requestAuthorization(options: [.alert, .badge, .alert]) { granted, error in
                if granted == true && error == nil {
                    // We have permission!
                }
        }
    }
}
```

## Adding Notifications

Next, let's make a method to add notifications. This will **not** schedule them - that comes later.

```
func addNotification(title: String) -> Void {
    notifications.append(Notification(id: UUID().uuidString, title: title))
}
```

Simple stuff. We use a `UUID` to ensure the `id` is unique.

## Scheduling Notifications

Now we have a way to request permission and to add some notifications - let's schedule them with a `scheduleNotifications` function.

```swift
func scheduleNotifications() -> Void {
    for notification in notifications {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: notification.id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            guard error == nil else { return }
            print("Scheduling notification with id: \(notification.id)")
        }
    }
}
```

There are few interesting things here. Firstly, we use `UNMutableNotificationContent`. The rest of the code is modelled after the example from the [Apple Developer docs](https://developer.apple.com/documentation/usernotifications/unmutablenotificationcontent?changes=_11). The name `Mutable` suggests there is an `Immutable` type - ther isn't. From what I gathered, the mutable here refers to the part of a `UNNotification` that **is** mutable - that is, the content the developer is free to modify.

This example sets a notification to appear in 5 seconds. Other types of notifications include [`UNCalendarNotificationTriggger`](https://developer.apple.com/documentation/usernotifications/uncalendarnotificationtrigger). [`UNLocationNotificationTrigger`](https://developer.apple.com/documentation/usernotifications/unlocationnotificationtrigger) and [`UNPushNotificationTrigger`](https://developer.apple.com/documentation/usernotifications/unpushnotificationtrigger).

If you have a device, or use the simulator, you can try this out by updating the `setNotification` function in `ContentView.swift`:

```swift
func setNotification() -> Void {
    let notification = Notification(
        id: UUID().uuidString,
        title: "This is a test reminder"
    )
    
    let manager = LocalNotificationManager()
    manager.requestPermission()
    manager.addNotification(notification: notification)
    manager.scheduleNotification()
}
```

Click on "Set Notification" and minimize the test app. After 5 seconds pass, you should see the notification! If you did **not** minimize the app, you will notice the notification does not show. We will address this later. Until iOS 12, notifications would not show if the app was in the foreground, however from iOS 12 you are able to show notifications in both the foreground and background. To do this, you need to add a bit of extra code in `AppDelegate.swift`. When you extend a class using a delegate, you enable the class to hand off some behaviour to an instance of another type. 

According to the [docs](https://developer.apple.com/documentation/usernotifications/unusernotificationcenterdelegate), the `UNUserNotificationCenterDelegate` is used to handle incoming notifications. We can use the [`userNotificationCenter(_:willPresent:withCompletionHandler:)`](https://developer.apple.com/documentation/usernotifications/unusernotificationcenterdelegate/1649518-usernotificationcenter) to "ask the delegate how to handle a notification that arrived while the app was running in the foreground". This is exactly what we need.

Update `AppDelegate.swift`:

```swift
import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions)
        -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // ... omitted
}
```

There are several changes:

- Add `UNUserNotificationCenterDelegate` to the class declaration
- Add a `userNotificationCenter` function that calls the `completionHandler`
- Assign `UNUserNotificationCenter.current().delegate` to `self` in `application`
