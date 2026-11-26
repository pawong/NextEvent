# NextEvent ![](NextEvent/Assets.xcassets/AppIcon.appiconset/icon_32x32@2x.png)

NextEvent is a countdown widget for your Mac menu bar. It displays the time until the next event in your calendar or reminders.

 - Choose the number of events to display, 1, 3, 5, 10, today only events or for the next 24 hours.
 - Flash menubar icon on 15 minute warning for next event due.
 - Blocking alerts, so you don't miss an appointment.
 - Visual and audio notification.

## Screenshots
![](Screenshot1.png)

## Versions
>[2.2.4](builds/NextEvent_v2.2.4/NextEvent.zip)
>    Changes:
>    - Refresh bug fix

>[2.2.3](builds/NextEvent_v2.2.3/NextEvent.zip)
>    Changes:
>    - Ventura bug fixes

>[2.2.1](builds/NextEvent_v2.2.1/NextEvent.zip)
>    Changes:
>    - First Open Source Release

## Installing

NextEvent is signed to run locally but is not notarized by Apple, so macOS will block it the first time you open it.

1. Download and unzip `NextEvent.zip`, then move `NextEvent.app` to your Applications folder.
2. Open the app. When macOS says it can't verify the developer, click **Done**.
3. Go to **System Settings > Privacy & Security**, scroll down, and click **Open Anyway** next to the NextEvent message.
4. Confirm with your password. After this, NextEvent opens normally.

Or, from Terminal:

```sh
xattr -cr /Applications/NextEvent.app
```

On first launch, allow NextEvent access to your calendars and reminders.

## Building

Open `NextEvent.xcodeproj` in Xcode and build. No Apple developer account or team is required; the app is signed to run locally.


## Support

**Bugs and requests?**  Please use the project's [issue tracker].

[![Issues](http://img.shields.io/github/issues/pawong/NextEvent.svg)](https://github.com/pawong/NextEvent/issues)

**Want to contribute?**  Please fork this repository and open a pull request with your new changes.

[![Pull requests](http://img.shields.io/github/issues-pr/pawong/NextEvent.svg?maxAge=3600)](https://github.com/pawong/NextEvent/pulls)

**Do you like it?**  Support the project by starring the repository or [tweet] about it.

## Thanks for looking!
*If you like what you see* [!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/pawong)

**NextEvent** © 2022, Mazookie, LLC. Released under the [MIT License](LICENSE).

[tweet]: https://twitter.com/intent/tweet?
[issue tracker]: https://github.com/pawong/NextEvent/issues/new

![](https://www.mazookie.com/img/Mazookie_full_logo_sticker_small.png)

Q: What is Mazookie?

A: Mazookie is a company that used to put apps on the MacOS App Store. This doesn't happen any more because Apple charges money to be a developer and there's no money in these apps, so the projects have been opensourced. Yeah, free stuff!
