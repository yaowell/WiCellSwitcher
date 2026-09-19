#import <Cephei/HBPreferences.h>

@interface SBWiFiManager
+ (id)sharedInstance;
- (BOOL)isPowered;
- (void)_powerStateDidChange;
- (void)_linkDidChange;
- (id)currentNetworkName;
- (BOOL)isAssociated;
- (void)setWiFiEnabled:(BOOL)arg1;
- (void)mobileDataStatusHasChanged;
- (BOOL)isMobileDataEnabled;
- (void)setMobileDataEnabled:(BOOL)enabled;
@end

@interface WiFiUtils
+ (id)sharedInstance;
- (long)setAutoJoinState:(BOOL)arg1;
@end

@interface SBStatusBarStateAggregator
+ (id)sharedInstance;
- (void)_updateDataNetworkItem;
@end

HBPreferences *preferences;

BOOL enabled = YES;
BOOL cellularActive;
BOOL wiFiActive;
BOOL cellularActivePreviousState;
BOOL wiFiActivePreviousState;
BOOL justChangedStatus;

extern "C" Boolean CTCellularDataPlanGetIsEnabled();
extern "C" void CTCellularDataPlanSetIsEnabled(Boolean enabled);

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application
{
  %orig;
  if (!enabled) return;

  wiFiActive = [[%c(SBWiFiManager) sharedInstance] currentNetworkName] != nil;
  cellularActive = [[%c(SBWiFiManager) sharedInstance] isMobileDataEnabled];

  if (wiFiActive && cellularActive) {
    justChangedStatus = YES;
    [[%c(SBWiFiManager) sharedInstance] setMobileDataEnabled:NO];
    cellularActivePreviousState = !cellularActive;
    wiFiActivePreviousState = wiFiActive;
  }
}

%end

%hook SBStatusBarStateAggregator

- (void)_updateDataNetworkItem
{
  %orig;
  if (!enabled) return;
  [[%c(SBWiFiManager) sharedInstance] mobileDataStatusHasChanged];
}

%end

%hook SBWiFiManager

- (void)_linkDidChange
{
  %orig;
  if (!enabled) return;

  if (!justChangedStatus) {
    cellularActive = [self isMobileDataEnabled];
    wiFiActive = [self isAssociated];

    if (wiFiActive != wiFiActivePreviousState) {
      justChangedStatus = YES;
      [self setMobileDataEnabled:!wiFiActive];
      cellularActivePreviousState = [self isMobileDataEnabled];
      wiFiActivePreviousState = wiFiActive;
    }
  } else {
    justChangedStatus = NO;
  }
}

%new
- (void)mobileDataStatusHasChanged
{
  if (!enabled) return;

  if (!justChangedStatus) {
    cellularActive = [self isMobileDataEnabled];
    wiFiActive = [self isPowered];

    if (cellularActive != cellularActivePreviousState) {
      justChangedStatus = YES;

      if (cellularActive) {
        [self setWiFiEnabled:NO];
      } else {
        [self setWiFiEnabled:YES];
        [[%c(WiFiUtils) sharedInstance] setAutoJoinState:YES];
      }

      cellularActivePreviousState = cellularActive;
      wiFiActivePreviousState = [self isPowered];
    }
  } else {
    justChangedStatus = NO;
  }
}

%new
- (BOOL)isMobileDataEnabled
{
  return CTCellularDataPlanGetIsEnabled();
}

%new
- (void)setMobileDataEnabled:(BOOL)enabled
{
  CTCellularDataPlanSetIsEnabled(enabled);
}

%end

%ctor
{
  preferences = [[HBPreferences alloc] initWithIdentifier:@"com.brunonfl.wicellswitcher"];
  [preferences registerBool:&enabled default:YES forKey:@"enabled"];
}