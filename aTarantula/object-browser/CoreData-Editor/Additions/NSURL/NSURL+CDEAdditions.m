#import "NSURL+CDEAdditions.h"

@implementation NSURL (CDEAdditions)

#pragma mark - App Specific URLs
+ (instancetype)URLForWebsite_cde {
    return [self URLWithString:[NSBundle mainBundle].infoDictionary[@"CDEWebsiteURL"]];
}

+ (instancetype)URLForCreateProjectTutorial_cde {
    return [self URLWithString:[NSBundle mainBundle].infoDictionary[@"CDECreateProjectTutorialURL"]];
}

+ (instancetype)URLForSupportWebsite_cde {
    return [self URLWithString:[NSBundle mainBundle].infoDictionary[@"CDECustomerSupportURL"]];
}

@end

