#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

// Приватный класс CoreAnimation для цветовых фильтров слоя
@interface CAFilter : NSObject
+ (instancetype)filterWithType:(NSString *)type;
- (void)setValue:(id)value forKey:(NSString *)key;
@end

@interface SBIconImageView : UIView
@end

// Файл настроек (rootless: /var/jb/..., rootful: /var/...)
static NSString *const kPrefsPathRootless = @"/var/jb/var/mobile/Library/Preferences/com.vibe.icontint.plist";
static NSString *const kPrefsPathRootful  = @"/var/mobile/Library/Preferences/com.vibe.icontint.plist";

static BOOL gEnabled = YES;
static CGFloat gAmount = 1.0;
static UIColor *gTint = nil;

static UIColor *ColorFromHex(NSString *hex) {
    if (![hex isKindOfClass:[NSString class]]) return nil;
    NSString *s = [hex stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"# "]];
    if (s.length != 6) return nil;
    unsigned int rgb = 0;
    if (![[NSScanner scannerWithString:s] scanHexInt:&rgb]) return nil;
    return [UIColor colorWithRed:((rgb >> 16) & 0xFF) / 255.0
                           green:((rgb >> 8) & 0xFF) / 255.0
                            blue:(rgb & 0xFF) / 255.0
                           alpha:1.0];
}

static void LoadPrefs(void) {
    NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:kPrefsPathRootless];
    if (!d) d = [NSDictionary dictionaryWithContentsOfFile:kPrefsPathRootful];

    gEnabled = d[@"enabled"] ? [d[@"enabled"] boolValue] : YES;
    gAmount = d[@"amount"] ? [d[@"amount"] doubleValue] : 1.0;
    if (gAmount < 0) gAmount = 0;
    if (gAmount > 1) gAmount = 1;

    UIColor *c = ColorFromHex(d[@"hex"]);
    gTint = c ?: [UIColor colorWithRed:1.0 green:0.42 blue:0.21 alpha:1.0]; // по умолчанию оранжевый
}

static void ApplyTint(UIView *view) {
    CALayer *layer = view.layer;

    if (!gEnabled) {
        if (layer.filters.count) layer.filters = nil;
        return;
    }

    CAFilter *filter = [CAFilter filterWithType:@"colorMonochrome"];
    [filter setValue:(id)gTint.CGColor forKey:@"inputColor"];
    [filter setValue:@(gAmount) forKey:@"inputAmount"];
    [filter setValue:@(0.0) forKey:@"inputBias"];
    layer.filters = @[filter];
}

%hook SBIconImageView
- (void)layoutSubviews {
    %orig;
    ApplyTint(self);
}
%end

%ctor {
    LoadPrefs();
}
