# BridgeFix

Stops the iOS 15 Watch app (Bridge) from crashing during Apple Watch setup when
pairing a watch that runs a newer watchOS (for example watchOS 11.x) through a
pairing tweak such as Legizmo.

## Install

Add this source in Sileo / Zebra and install **BridgeFix**:

```
https://repo.tahakerem.dev/
```

Then reset the watch, pair again with your pairing tweak, and keep internet on
during setup.

## The crash

After pairing, tapping Continue closes the Watch app, and reopening it shows
"Apple Watch is being unpaired". The crash log shows:

```
-[UIResponder doesNotRecognizeSelector:]
-[BPSRemoteUISetupStyle applyToObjectModel:]
-[RUIObjectModel parseDidFinish]
-[RUIParser initWithXML:baseURL:style:delegate:]
```

Some setup pages (Activation Lock / Apple ID and others) are RemoteUI XML that
Apple's servers send. The current pages make iOS 15's style code call a method
that does not exist on iOS 15. The exception is uncaught, so Bridge dies and the
half-done pairing is rolled back.

## The fix

BridgeFix hooks `-[BPSRemoteUISetupStyle applyToObjectModel:]` in Bridge only.
It catches the exception and logs it (`[BridgeFix] caught ...` in the syslog),
so setup keeps going. A page may look a little unstyled.

BridgeFix does **not** bypass any pairing checks by itself. You still need a
pairing tweak (tested with Legizmo Moonstone 6.3).

## Tested

- iPhone 13, iOS 15.1.1, Dopamine (rootless)
- Apple Watch Series 10, watchOS 11.5
- Legizmo Moonstone 6.3

## Building

Theos, rootless scheme:

```
make package FINALPACKAGE=1
```

Do not use `@"..."` string literals in `Tweak.xm` when building with the Linux
Theos toolchain (clang 13). It does not sign a constant CFString's isa the way
iOS 15 arm64e `objc_msgSend` expects, and the dylib then crashes Bridge at load
(PAC failure, `EXC_BAD_ACCESS` code 0x105).

## License

MIT
