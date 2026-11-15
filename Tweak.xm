#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

static NSString * const kKeyURL =
    @"https://raw.githubusercontent.com/bogiadatindo-dot/key/refs/heads/main/key";

static BOOL gPromptVisible = NO;
static BOOL gRequestInProgress = NO;

static UIViewController *GKTopViewController(void) {
    UIApplication *app = UIApplication.sharedApplication;
    for (UIScene *scene in app.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class]) continue;
        UIWindowScene *windowScene = (UIWindowScene *)scene;
        for (UIWindow *window in windowScene.windows) {
            if (window.isKeyWindow && window.rootViewController) {
                UIViewController *vc = window.rootViewController;
                while (vc.presentedViewController) {
                    vc = vc.presentedViewController;
                }
                return vc;
            }
        }
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    UIWindow *window = app.keyWindow;
#pragma clang diagnostic pop
    UIViewController *vc = window.rootViewController;
    while (vc.presentedViewController) vc = vc.presentedViewController;
    return vc;
}

static void GKValidateKey(NSString *enteredKey,
                          void (^completion)(BOOL, NSString *)) {
    NSString *trimmed = [enteredKey stringByTrimmingCharactersInSet:
                         NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (trimmed.length == 0) {
        completion(NO, @"Vui lòng nhập KEY.");
        return;
    }

    NSURL *url = [NSURL URLWithString:kKeyURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";
    request.timeoutInterval = 15;
    [request setValue:@"no-cache" forHTTPHeaderField:@"Cache-Control"];

    [[[NSURLSession sharedSession] dataTaskWithRequest:request
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error || !data || ![(NSHTTPURLResponse *)response statusCode] ||
            [(NSHTTPURLResponse *)response statusCode] != 200) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, @"Không thể kết nối GitHub. Hãy thử lại.");
            });
            return;
        }

        NSString *body = [[NSString alloc] initWithData:data
                                               encoding:NSUTF8StringEncoding];
        if (!body) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, @"Dữ liệu KEY trên GitHub không hợp lệ.");
            });
            return;
        }

        BOOL valid = NO;
        for (NSString *rawLine in [body componentsSeparatedByCharactersInSet:
                                   NSCharacterSet.newlineCharacterSet]) {
            NSString *line = [rawLine stringByTrimmingCharactersInSet:
                              NSCharacterSet.whitespaceAndNewlineCharacterSet];
            if (![line hasPrefix:@"key:"]) continue;
            NSString *candidate = [[line substringFromIndex:4]
                stringByTrimmingCharactersInSet:
                NSCharacterSet.whitespaceAndNewlineCharacterSet];
            if (candidate.length && [candidate isEqualToString:trimmed]) {
                valid = YES;
                break;
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            completion(valid, valid ? @"Xác thực thành công." : @"KEY không hợp lệ.");
        });
    }] resume];
}

static void GKShowKeyPrompt(void) {
    if (gPromptVisible || gRequestInProgress) return;

    UIViewController *root = GKTopViewController();
    if (!root || root.isBeingPresented || root.view.window == nil) return;

    gPromptVisible = YES;
    UIAlertController *alert =
      [UIAlertController alertControllerWithTitle:@"GITHUB KEY SYSTEM"
                                          message:@"Nhập KEY để xác thực"
                                   preferredStyle:UIAlertControllerStyleAlert];

    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.placeholder = @"Nhập KEY...";
        field.autocapitalizationType = UITextAutocapitalizationTypeNone;
        field.autocorrectionType = UITextAutocorrectionTypeNo;
        field.clearButtonMode = UITextFieldViewModeWhileEditing;
        field.secureTextEntry = YES;
    }];

    __weak UIAlertController *weakAlert = alert;
    [alert addAction:[UIAlertAction actionWithTitle:@"XÁC NHẬN"
                                              style:UIAlertActionStyleDefault
                                            handler:^(__unused UIAlertAction *action) {
        NSString *key = weakAlert.textFields.firstObject.text ?: @"";
        gRequestInProgress = YES;

        GKValidateKey(key, ^(BOOL valid, NSString *message) {
            gRequestInProgress = NO;

            UIViewController *presenter = GKTopViewController();
            UIAlertController *result =
              [UIAlertController alertControllerWithTitle:(valid ? @"KEY HỢP LỆ" : @"THÔNG BÁO")
                                                  message:message
                                           preferredStyle:UIAlertControllerStyleAlert];
            [result addAction:[UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(__unused UIAlertAction *a) {
                gPromptVisible = NO;
                if (!valid) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        GKShowKeyPrompt();
                    });
                }
            }]];
            [presenter presentViewController:result animated:YES completion:nil];
        });
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"ĐÓNG"
                                              style:UIAlertActionStyleCancel
                                            handler:^(__unused UIAlertAction *action) {
        gPromptVisible = NO;
    }]];

    [root presentViewController:alert animated:YES completion:nil];
}

%ctor {
    @autoreleasepool {
        // Chỉ hiển thị UI trong ứng dụng có trong GitHubKey.plist.
        // Không áp dụng cho SpringBoard hoặc tiến trình hệ thống.
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter]
             addObserverForName:UIApplicationDidBecomeActiveNotification
                         object:nil
                          queue:NSOperationQueue.mainQueue
                     usingBlock:^(__unused NSNotification *note) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                    (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    GKShowKeyPrompt();
                });
            }];

            if (UIApplication.sharedApplication.applicationState ==
                UIApplicationStateActive) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                    (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    GKShowKeyPrompt();
                });
            }
        });
    }
}
