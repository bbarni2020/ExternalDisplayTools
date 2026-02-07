import Foundation

// Bridge: If the modern BatteryActivityManager isn't available in this target,
// fall back to the legacy implementation so existing code compiles.
#if !canImport(NonExistentMarker) // always true, used to keep structure simple
// If you already have a `BatteryActivityManager` type in this target, this alias
// will cause a redeclaration error; in that case, remove this file.
public typealias BatteryActivityManager = LegacyBatteryActivityManager
#endif
