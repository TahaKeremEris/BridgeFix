// BridgeFix — keeps the iOS 15 Watch app (Bridge) from crashing on
// server-driven setup pages (RemoteUI XML) built for newer iOS versions.
//
// Crash being fixed (iOS 15.1.1, Bridge):
//   -[UIResponder doesNotRecognizeSelector:]
//   -[BPSRemoteUISetupStyle applyToObjectModel:]
//   -[RUIObjectModel parseDidFinish]
//   -[RUIParser initWithXML:baseURL:style:delegate:]
//
// The page Apple serves today makes the old style code call a method that
// does not exist on iOS 15. The exception is uncaught and kills Bridge
// mid-setup, so the pairing gets rolled back ("Apple Watch is being unpaired").
// Here we catch it, log which selector was missing, and let the page show with
// the styling it got before the failure.
//
// BUILD NOTE: do not use @"..." string literals in this file. The Linux Theos
// toolchain (clang 13) does not sign a constant CFString's isa the way iOS 15
// arm64e objc_msgSend expects (PAC discriminator 0x6AE1), so touching any
// literal crashes the process at load. Use C strings, objc_getClass and os_log.

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <os/log.h>
#import <mach-o/dyld.h>

@interface BPSRemoteUISetupStyle : NSObject
- (void)applyToObjectModel:(id)objectModel;
@end

%group BridgeFix
%hook BPSRemoteUISetupStyle
- (void)applyToObjectModel:(id)objectModel {
	@try {
		%orig;
	} @catch (NSException *exception) {
		os_log_error(OS_LOG_DEFAULT,
		             "[BridgeFix] caught in -[BPSRemoteUISetupStyle applyToObjectModel:]: %{public}@: %{public}@",
		             exception.name, exception.reason);
	}
}
%end
%end

static BOOL gHooked = NO;

static void TryInstallHooks(void) {
	if (gHooked) return;
	if (!objc_getClass("BPSRemoteUISetupStyle")) return;
	gHooked = YES;
	%init(BridgeFix);
	os_log(OS_LOG_DEFAULT, "[BridgeFix] hooks installed");
}

// BridgePreferences is normally loaded before we run; if not, wait for it.
static void ImageAdded(const struct mach_header *mh, intptr_t slide) {
	TryInstallHooks();
}

%ctor {
	@autoreleasepool {
		TryInstallHooks();
		if (!gHooked) {
			_dyld_register_func_for_add_image(ImageAdded);
		}
	}
}
